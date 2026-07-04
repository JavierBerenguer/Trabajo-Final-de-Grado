classdef DesignWorkspaceHelper
% DesignWorkspaceHelper - Backend for the Design & Optimization workspace.
%
% V1 scope:
%   - isothermal, steady-state, liquid-phase equivalent non-ideal analysis
%   - RTD construction and normalization
%   - heuristic diagnosis and hydrodynamic fitting
%   - reactive performance under Segregation / Max Mixedness
%   - optimization on equivalent hydrodynamic parameters
%   - pilot vs industrial scenario comparison

    methods (Static)

        function state = defaultState()
            state = struct( ...
                'rtdInput', struct(), ...
                'fitResult', [], ...
                'reactionSpec', struct( ...
                    'rs', [], ...
                    'feedStream', [], ...
                    'keyComponentIndex', 1, ...
                    'desiredProductIndex', 2, ...
                    'byproductIndex', 3), ...
                'optimizationSpec', struct(), ...
                'lastSolutions', struct()) ;
        end

        function hydroResult = solveHydrodynamics(hydroSpec)
            sourceType = char(string(DesignWorkspaceHelper.getStructField( ...
                hydroSpec, 'sourceType', 'Pulse workspace'))) ;

            switch sourceType
                case 'Pulse workspace'
                    t = DesignWorkspaceHelper.ensureRowVector( ...
                        DesignWorkspaceHelper.getStructField(hydroSpec, 'tData', [])) ;
                    signal = DesignWorkspaceHelper.ensureRowVector( ...
                        DesignWorkspaceHelper.getStructField(hydroSpec, 'signalData', [])) ;
                    tScale = DesignWorkspaceHelper.timeScaleFromUnit( ...
                        DesignWorkspaceHelper.getStructField(hydroSpec, 'timeUnit', 's')) ;
                    rtdObj = RTD.from_pulse(tScale * t, signal) ;

                case 'Step workspace'
                    t = DesignWorkspaceHelper.ensureRowVector( ...
                        DesignWorkspaceHelper.getStructField(hydroSpec, 'tData', [])) ;
                    signal = DesignWorkspaceHelper.ensureRowVector( ...
                        DesignWorkspaceHelper.getStructField(hydroSpec, 'signalData', [])) ;
                    c0 = DesignWorkspaceHelper.getStructField(hydroSpec, 'stepC0', []) ;
                    tScale = DesignWorkspaceHelper.timeScaleFromUnit( ...
                        DesignWorkspaceHelper.getStructField(hydroSpec, 'timeUnit', 's')) ;
                    if isempty(c0)
                        rtdObj = RTD.from_step(tScale * t, signal) ;
                    else
                        rtdObj = RTD.from_step(tScale * t, signal, c0) ;
                    end

                case 'RTD object'
                    rtdObj = DesignWorkspaceHelper.getStructField(hydroSpec, 'rtdObject', []) ;
                    if isempty(rtdObj) || ~isa(rtdObj, 'RTD')
                        error('A valid RTD object is required.') ;
                    end

                case 'From RTD Analysis'
                    rtdObj = DesignWorkspaceHelper.getStructField(hydroSpec, 'rtdObject', []) ;
                    if isempty(rtdObj) || ~isa(rtdObj, 'RTD')
                        error('Tab 1 does not currently hold a valid RTD object.') ;
                    end

                otherwise
                    error('Unknown hydrodynamic source: %s', sourceType) ;
            end

            hydroResult = struct() ;
            hydroResult.sourceType = sourceType ;
            hydroResult.rtd = rtdObj ;
            hydroResult.t = rtdObj.t ;
            hydroResult.Et = rtdObj.Et ;
            hydroResult.Ft = rtdObj.Ft ;
            hydroResult.It = 1 - rtdObj.Ft ;
            hydroResult.theta = rtdObj.theta ;
            hydroResult.Etheta = rtdObj.Etheta ;
            hydroResult.tau = rtdObj.tau ;
            hydroResult.sigma2 = rtdObj.sigma2 ;
            hydroResult.sigma2_theta = rtdObj.sigma2_theta ;
            hydroResult.s3 = rtdObj.s3 ;
            hydroResult.momentsTable = { ...
                't_m', DesignWorkspaceHelper.formatNumber(rtdObj.tau), 's' ; ...
                'sigma^2', DesignWorkspaceHelper.formatNumber(rtdObj.sigma2), 's^2' ; ...
                'sigma_theta^2', DesignWorkspaceHelper.formatNumber(rtdObj.sigma2_theta), '-' ; ...
                's^3', DesignWorkspaceHelper.formatNumber(rtdObj.s3), '-' ; ...
                'Area(E)', DesignWorkspaceHelper.formatNumber(trapz(rtdObj.t, rtdObj.Et)), '-'} ;
        end

        function fitResult = solveHydroFit(fitSpec)
            family = char(string(DesignWorkspaceHelper.getStructField( ...
                fitSpec, 'family', 'Tanks-in-Series'))) ;
            if strcmp(family, 'Search best family')
                fitResult = DesignWorkspaceHelper.solveHydroFitSearch(fitSpec) ;
                return
            end

            fitResult = DesignWorkspaceHelper.solveSingleHydroFit(fitSpec) ;
        end

        function fitResult = solveHydroFitSearch(fitSpec)
            rtdObj = DesignWorkspaceHelper.getRequiredRTD(fitSpec) ;
            candidates = { ...
                struct('family', 'Tanks-in-Series', 'displayName', 'Tanks-in-Series', 'boundaryType', 'closed-closed') ; ...
                struct('family', 'Axial Dispersion', 'displayName', 'Axial Dispersion closed-closed', 'boundaryType', 'closed-closed') ; ...
                struct('family', 'Axial Dispersion', 'displayName', 'Axial Dispersion open-open', 'boundaryType', 'open-open') ; ...
                struct('family', 'CSTR + Dead Volume', 'displayName', 'CSTR + Dead Volume', 'boundaryType', 'closed-closed') ; ...
                struct('family', 'CSTR + Bypass', 'displayName', 'CSTR + Bypass', 'boundaryType', 'closed-closed') ; ...
                struct('family', 'CSTR + Dead Volume + Bypass', 'displayName', 'CSTR + Dead Volume + Bypass', 'boundaryType', 'closed-closed') ...
                } ;
            referenceTau = DesignWorkspaceHelper.getStructField( ...
                fitSpec, 'referenceTau', []) ;

            entries = repmat(struct( ...
                'family', '', ...
                'displayName', '', ...
                'status', '', ...
                'message', '', ...
                'rmse', NaN, ...
                'score', NaN, ...
                'result', []), numel(candidates), 1) ;
            validResults = cell(0, 1) ;

            for i = 1:numel(candidates)
                candidate = candidates{i} ;
                family = candidate.family ;
                entry = struct('family', family, 'displayName', candidate.displayName, 'status', 'Skipped', ...
                    'message', '', 'rmse', NaN, 'score', NaN, 'result', []) ;
                if DesignWorkspaceHelper.familyNeedsReferenceTau(family) && ...
                        (isempty(referenceTau) || ~isscalar(referenceTau) || referenceTau <= 0)
                    entry.message = 'Reference tau_total not available.' ;
                    entries(i) = entry ;
                    continue
                end

                try
                    singleSpec = fitSpec ;
                    singleSpec.family = family ;
                    singleSpec.boundaryType = candidate.boundaryType ;
                    singleSpec.referenceTau = referenceTau ;
                    result = DesignWorkspaceHelper.solveSingleHydroFit(singleSpec) ;
                    result.family = candidate.displayName ;
                    entry.status = 'OK' ;
                    entry.rmse = result.rmse ;
                    entry.score = result.score ;
                    entry.result = result ;
                    validResults{end + 1, 1} = result ; %#ok<AGROW>
                catch ME
                    entry.status = 'Skipped' ;
                    entry.message = ME.message ;
                end
                entries(i) = entry ;
            end

            if isempty(validResults)
                error('No family could be fitted with the current context.') ;
            end

            [sortedResults, sortedEntries, bestIdx] = DesignWorkspaceHelper.rankFitSearchEntries(validResults, entries) ;
            bestResult = sortedResults(1) ;
            summaryTable = cell(numel(sortedEntries), 3) ;
            for i = 1:numel(sortedEntries)
                summaryTable{i, 1} = sortedEntries(i).displayName ;
                summaryTable{i, 2} = DesignWorkspaceHelper.formatNumber(sortedEntries(i).rmse) ;
                summaryTable{i, 3} = DesignWorkspaceHelper.formatNumber(sortedEntries(i).score) ;
            end

            fitResult = bestResult ;
            fitResult.mode = 'search' ;
            fitResult.requestedFamily = 'Search best family' ;
            fitResult.summaryTable = summaryTable ;
            fitResult.searchEntries = sortedEntries ;
            fitResult.searchFamilies = {sortedEntries.displayName} ;
            fitResult.searchBestFamily = bestResult.family ;
            fitResult.searchSelection = bestIdx ;
            fitResult.searchResults = sortedResults ;
            fitResult.searchDiagnostics = DesignWorkspaceHelper.buildSearchDiagnostics(sortedEntries) ;
        end

        function fitResult = solveSingleHydroFit(fitSpec)
            rtdObj = DesignWorkspaceHelper.getRequiredRTD(fitSpec) ;
            rtdObj.t = DesignWorkspaceHelper.ensureRowVector(rtdObj.t) ;
            rtdObj.Et = DesignWorkspaceHelper.ensureRowVector(rtdObj.Et) ;
            family = char(string(DesignWorkspaceHelper.getStructField( ...
                fitSpec, 'family', 'Tanks-in-Series'))) ;
            boundary = char(string(DesignWorkspaceHelper.getStructField( ...
                fitSpec, 'boundaryType', 'closed-closed'))) ;
            referenceTau = DesignWorkspaceHelper.getStructField( ...
                fitSpec, 'referenceTau', []) ;

            t = rtdObj.t ;
            fitMeta = struct() ;
            fitMeta.family = family ;
            fitMeta.boundaryType = boundary ;
            fitMeta.referenceTau = referenceTau ;

            switch family
                case 'Tanks-in-Series'
                    n0 = max(1, min(50, rtdObj.tau^2 / max(rtdObj.sigma2, 1e-12))) ;
                    objFun = @(x) DesignWorkspaceHelper.curveScore( ...
                        rtdObj, RTD.tanks_in_series(max(x(1), 1e-3), rtdObj.tau, t)) ;
                    x = DesignWorkspaceHelper.penalizedFminsearch(objFun, n0, 1, 200) ;
                    nFit = max(x(1), 1e-3) ;
                    modelRTD = RTD.tanks_in_series(nFit, rtdObj.tau, t) ;
                    params = struct('tau', rtdObj.tau, 'N', nFit) ;

                case 'Axial Dispersion'
                    sigmaTheta = max(rtdObj.sigma2_theta, 1e-8) ;
                    bo0 = max(1e-5, min(5, sigmaTheta / 2)) ;
                    objFun = @(x) DesignWorkspaceHelper.curveScore( ...
                        rtdObj, DesignWorkspaceHelper.buildDispersionRTD(max(x(1), 1e-5), rtdObj.tau, boundary, t)) ;
                    x = DesignWorkspaceHelper.penalizedFminsearch(objFun, bo0, 1e-5, 5) ;
                    boFit = max(x(1), 1e-5) ;
                    modelRTD = DesignWorkspaceHelper.buildDispersionRTD(boFit, rtdObj.tau, boundary, t) ;
                    params = struct('tau', rtdObj.tau, 'Bo', boFit, 'Pe', 1 / boFit) ;

                case 'CSTR + Dead Volume'
                    if isempty(referenceTau) || ~isscalar(referenceTau) || referenceTau <= 0
                        error('Reference tau_total is required for CSTR + Dead Volume fitting.') ;
                    end
                    alphaFit = min(max(rtdObj.tau / referenceTau, 1e-4), 1) ;
                    modelRTD = RTD.cstr_with_dead_volume(referenceTau, alphaFit, t) ;
                    params = struct('tau_nominal', referenceTau, 'activeFraction', alphaFit, ...
                        'deadFraction', 1 - alphaFit, 'tau_active', modelRTD.tau) ;

                case 'CSTR + Bypass'
                    beta0 = min(max(DesignWorkspaceHelper.estimateEarlyMassFraction(rtdObj), 1e-4), 0.95) ;
                    objFun = @(x) DesignWorkspaceHelper.curveScore( ...
                        rtdObj, RTD.cstr_with_bypass(rtdObj.tau, min(max(x(1), 0), 0.95), t)) ;
                    x = DesignWorkspaceHelper.penalizedFminsearch(objFun, beta0, 0, 0.95) ;
                    betaFit = min(max(x(1), 0), 0.95) ;
                    modelRTD = RTD.cstr_with_bypass(rtdObj.tau, betaFit, t) ;
                    params = struct('tau', rtdObj.tau, 'bypassFraction', betaFit) ;

                case 'CSTR + Dead Volume + Bypass'
                    if isempty(referenceTau) || ~isscalar(referenceTau) || referenceTau <= 0
                        error('Reference tau_total is required for CSTR + Dead Volume + Bypass fitting.') ;
                    end
                    alphaFix = min(max(rtdObj.tau / referenceTau, 1e-4), 1) ;
                    beta0 = min(max(DesignWorkspaceHelper.estimateEarlyMassFraction(rtdObj), 1e-4), 0.95) ;
                    objFun = @(x) DesignWorkspaceHelper.curveScore( ...
                        rtdObj, RTD.cstr_with_bypass_and_dead(referenceTau, alphaFix, ...
                        min(max(x(1), 0), 0.95), t)) ;
                    x = DesignWorkspaceHelper.penalizedFminsearch(objFun, beta0, 0, 0.95) ;
                    betaFit = min(max(x(1), 0), 0.95) ;
                    modelRTD = RTD.cstr_with_bypass_and_dead(referenceTau, alphaFix, betaFit, t) ;
                    params = struct('tau_nominal', referenceTau, 'activeFraction', alphaFix, ...
                        'deadFraction', 1 - alphaFix, 'bypassFraction', betaFit) ;

                otherwise
                    error('Unknown fit family: %s', family) ;
            end

            rmse = sqrt(mean((rtdObj.Et - modelRTD.Et).^2)) ;
            sse = trapz(rtdObj.t, (rtdObj.Et - modelRTD.Et).^2) ;
            diagnostics = DesignWorkspaceHelper.diagnoseRTD(rtdObj, fitMeta) ;

            fitResult = struct() ;
            fitResult.mode = 'single' ;
            fitResult.family = family ;
            fitResult.parameters = params ;
            fitResult.boundaryType = boundary ;
            fitResult.referenceTau = referenceTau ;
            fitResult.inputRTD = rtdObj ;
            fitResult.fittedRTD = modelRTD ;
            fitResult.sse = sse ;
            fitResult.rmse = rmse ;
            fitResult.score = 1 / (1 + sse) ;
            fitResult.summaryTable = DesignWorkspaceHelper.parametersToTable(params) ;
            fitResult.diagnostics = diagnostics ;
            fitResult.compareTable = { ...
                'tau input', DesignWorkspaceHelper.formatNumber(rtdObj.tau), DesignWorkspaceHelper.formatNumber(modelRTD.tau) ; ...
                'sigma2 input', DesignWorkspaceHelper.formatNumber(rtdObj.sigma2), DesignWorkspaceHelper.formatNumber(modelRTD.sigma2) ; ...
                'RMSE', DesignWorkspaceHelper.formatNumber(rmse), '-' ; ...
                'Curve SSE', DesignWorkspaceHelper.formatNumber(sse), '-'} ;
        end

        function diagnostics = diagnoseRTD(rtdObj, fitMeta)
            if nargin < 2
                fitMeta = struct() ;
            end

            rtdObj.t = DesignWorkspaceHelper.ensureRowVector(rtdObj.t) ;
            rtdObj.Et = DesignWorkspaceHelper.ensureRowVector(rtdObj.Et) ;

            tau = max(rtdObj.tau, 1e-12) ;
            earlyMass = DesignWorkspaceHelper.estimateEarlyMassFraction(rtdObj) ;
            lateHoldUp = interp1(rtdObj.t, 1 - rtdObj.Ft, 3 * tau, 'linear', 0) ;
            peakCount = DesignWorkspaceHelper.countPeaks(rtdObj.Et) ;
            referenceTau = DesignWorkspaceHelper.getStructField(fitMeta, 'referenceTau', []) ;

            deadFlag = false ;
            if ~isempty(referenceTau) && referenceTau > 0
                deadFlag = rtdObj.tau < 0.95 * referenceTau ;
            end
            deadFlag = deadFlag || (rtdObj.sigma2_theta > 1.1 && lateHoldUp > 0.02) ;
            bypassFlag = earlyMass > 0.08 ;
            channelFlag = peakCount >= 2 && earlyMass > 0.03 ;
            recircFlag = peakCount >= 2 && lateHoldUp > 0.08 ;

            messages = strings(0, 1) ;
            if deadFlag
                messages(end+1, 1) = "Dead-volume indicator: mean residence time is reduced and/or the tail is long."; %#ok<AGROW>
            end
            if bypassFlag
                messages(end+1, 1) = "Bypass indicator: a significant fraction of tracer leaves very early."; %#ok<AGROW>
            end
            if channelFlag
                messages(end+1, 1) = "Channeling indicator: the RTD shows more than one relevant peak with an early contribution."; %#ok<AGROW>
            end
            if recircFlag
                messages(end+1, 1) = "Internal recirculation indicator: multimodality plus a sustained tail suggests recirculation or internal loops."; %#ok<AGROW>
            end
            if isempty(messages)
                messages = "No strong anomaly flag was triggered by the current heuristics." ;
            end

            diagnostics = struct() ;
            diagnostics.deadVolumeFlag = deadFlag ;
            diagnostics.bypassFlag = bypassFlag ;
            diagnostics.channelingFlag = channelFlag ;
            diagnostics.recirculationFlag = recircFlag ;
            diagnostics.earlyMassFraction = earlyMass ;
            diagnostics.tailHoldUpAt3Tau = lateHoldUp ;
            diagnostics.peakCount = peakCount ;
            diagnostics.summaryText = cellstr(messages) ;
            diagnostics.summaryTable = { ...
                'Dead volume', DesignWorkspaceHelper.flagText(deadFlag), DesignWorkspaceHelper.formatNumber(rtdObj.tau) ; ...
                'Bypass', DesignWorkspaceHelper.flagText(bypassFlag), DesignWorkspaceHelper.formatNumber(earlyMass) ; ...
                'Channeling', DesignWorkspaceHelper.flagText(channelFlag), DesignWorkspaceHelper.formatNumber(peakCount) ; ...
                'Recirculation', DesignWorkspaceHelper.flagText(recircFlag), DesignWorkspaceHelper.formatNumber(lateHoldUp)} ;
        end

        function reactiveResult = solveReactivePerformance(reactiveSpec)
            rtdObj = DesignWorkspaceHelper.getRequiredRTD(reactiveSpec) ;
            RS = DesignWorkspaceHelper.getRequiredField(reactiveSpec, 'RS') ;
            C0 = DesignWorkspaceHelper.ensureRowVector( ...
                DesignWorkspaceHelper.getRequiredField(reactiveSpec, 'C0')) ;

            keyIdx = DesignWorkspaceHelper.getStructField(reactiveSpec, 'keyComponentIndex', 1) ;
            desiredIdx = DesignWorkspaceHelper.getStructField(reactiveSpec, 'desiredProductIndex', []) ;
            byproductIdx = DesignWorkspaceHelper.getStructField(reactiveSpec, 'byproductIndex', []) ;

            seg = SegregationModel(rtdObj) ;
            seg.keyComponentIndex = keyIdx ;
            seg = seg.compute_isothermal(RS, C0) ;

            mm = MaxMixednessModel(rtdObj) ;
            mm.keyComponentIndex = keyIdx ;
            mm = mm.compute_isothermal(RS, C0) ;

            [C_cstr, X_cstr] = TanksInSeries.solve_sequential(1, RS, C0, rtdObj.tau) ;
            [C_pfr, X_pfr] = TanksInSeries.solve_PFR(RS, C0, rtdObj.tau) ;

            metricsSeg = DesignWorkspaceHelper.computeScenarioMetrics(C0, seg.C_exit, keyIdx, desiredIdx, byproductIdx) ;
            metricsMM = DesignWorkspaceHelper.computeScenarioMetrics(C0, mm.C_exit, keyIdx, desiredIdx, byproductIdx) ;
            metricsCSTR = DesignWorkspaceHelper.computeScenarioMetrics(C0, C_cstr, keyIdx, desiredIdx, byproductIdx) ;
            metricsPFR = DesignWorkspaceHelper.computeScenarioMetrics(C0, C_pfr, keyIdx, desiredIdx, byproductIdx) ;

            firstOrder = DesignWorkspaceHelper.computeFirstOrderDirect(rtdObj, RS, C0, keyIdx) ;

            reactiveResult = struct() ;
            reactiveResult.rtd = rtdObj ;
            reactiveResult.segregation = seg ;
            reactiveResult.maxMixedness = mm ;
            reactiveResult.cstr = struct('C_out', C_cstr, 'X', X_cstr) ;
            reactiveResult.pfr = struct('C_out', C_pfr, 'X', X_pfr) ;
            reactiveResult.firstOrder = firstOrder ;
            reactiveResult.summaryTable = { ...
                'Ideal CSTR', DesignWorkspaceHelper.formatNumber(metricsCSTR.conversion), ...
                DesignWorkspaceHelper.formatNumber(metricsCSTR.selectivity), ...
                DesignWorkspaceHelper.formatNumber(metricsCSTR.yield) ; ...
                'Segregation', DesignWorkspaceHelper.formatNumber(metricsSeg.conversion), ...
                DesignWorkspaceHelper.formatNumber(metricsSeg.selectivity), ...
                DesignWorkspaceHelper.formatNumber(metricsSeg.yield) ; ...
                'Max Mixedness', DesignWorkspaceHelper.formatNumber(metricsMM.conversion), ...
                DesignWorkspaceHelper.formatNumber(metricsMM.selectivity), ...
                DesignWorkspaceHelper.formatNumber(metricsMM.yield) ; ...
                'Ideal PFR', DesignWorkspaceHelper.formatNumber(metricsPFR.conversion), ...
                DesignWorkspaceHelper.formatNumber(metricsPFR.selectivity), ...
                DesignWorkspaceHelper.formatNumber(metricsPFR.yield)} ;
            reactiveResult.coutTable = DesignWorkspaceHelper.buildOutletTable( ...
                RS, C0, seg.C_exit, mm.C_exit, C_cstr, C_pfr) ;
            reactiveResult.metrics = struct( ...
                'cstr', metricsCSTR, ...
                'segregation', metricsSeg, ...
                'maxMixedness', metricsMM, ...
                'pfr', metricsPFR) ;
            reactiveResult.summaryText = DesignWorkspaceHelper.buildReactiveSummary( ...
                metricsCSTR, metricsSeg, metricsMM, metricsPFR, firstOrder) ;
        end

        function optimizationResult = solveOptimization(optSpec)
            RS = DesignWorkspaceHelper.getRequiredField(optSpec, 'RS') ;
            C0 = DesignWorkspaceHelper.ensureRowVector( ...
                DesignWorkspaceHelper.getRequiredField(optSpec, 'C0')) ;

            decisionVariables = DesignWorkspaceHelper.getStructField(optSpec, 'decisionVariables', struct([])) ;
            constraints = DesignWorkspaceHelper.getStructField(optSpec, 'constraints', struct([])) ;
            objective = char(string(DesignWorkspaceHelper.getStructField( ...
                optSpec, 'objective', 'Max conversion'))) ;

            [x0, lb, ub, names, fixedParams] = DesignWorkspaceHelper.unpackDecisionVariables(decisionVariables) ;
            if isempty(x0)
                error('At least one active decision variable is required.') ;
            end

            objFun = @(x) DesignWorkspaceHelper.optimizationPenaltyObjective( ...
                x, lb, ub, names, fixedParams, constraints, objective, optSpec, RS, C0) ;
            xOpt = DesignWorkspaceHelper.penalizedFminsearch(objFun, x0, lb, ub) ;

            baselineParams = DesignWorkspaceHelper.combineParams(names, x0, fixedParams) ;
            optimumParams = DesignWorkspaceHelper.combineParams(names, xOpt, fixedParams) ;

            baseline = DesignWorkspaceHelper.evaluateHydroScenario(struct( ...
                'family', DesignWorkspaceHelper.getStructField(optSpec, 'family', 'Tanks-in-Series'), ...
                'boundaryType', DesignWorkspaceHelper.getStructField(optSpec, 'boundaryType', 'closed-closed'), ...
                'reactionMode', DesignWorkspaceHelper.getStructField(optSpec, 'reactionMode', 'Segregation'), ...
                'RS', RS, ...
                'C0', C0, ...
                'keyComponentIndex', DesignWorkspaceHelper.getStructField(optSpec, 'keyComponentIndex', 1), ...
                'desiredProductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'desiredProductIndex', []), ...
                'byproductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'byproductIndex', []), ...
                'params', baselineParams)) ;
            optimum = DesignWorkspaceHelper.evaluateHydroScenario(struct( ...
                'family', DesignWorkspaceHelper.getStructField(optSpec, 'family', 'Tanks-in-Series'), ...
                'boundaryType', DesignWorkspaceHelper.getStructField(optSpec, 'boundaryType', 'closed-closed'), ...
                'reactionMode', DesignWorkspaceHelper.getStructField(optSpec, 'reactionMode', 'Segregation'), ...
                'RS', RS, ...
                'C0', C0, ...
                'keyComponentIndex', DesignWorkspaceHelper.getStructField(optSpec, 'keyComponentIndex', 1), ...
                'desiredProductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'desiredProductIndex', []), ...
                'byproductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'byproductIndex', []), ...
                'params', optimumParams)) ;

            constraintTable = DesignWorkspaceHelper.evaluateConstraints(constraints, optimum) ;
            sensitivityTable = DesignWorkspaceHelper.computeSensitivity(names, optimumParams, optSpec, RS, C0, objective) ;

            optimizationResult = struct() ;
            optimizationResult.family = DesignWorkspaceHelper.getStructField(optSpec, 'family', 'Tanks-in-Series') ;
            optimizationResult.objective = objective ;
            optimizationResult.baseline = baseline ;
            optimizationResult.optimum = optimum ;
            optimizationResult.optimalParameters = optimumParams ;
            optimizationResult.comparisonTable = { ...
                'Conversion', DesignWorkspaceHelper.formatNumber(baseline.metrics.conversion), DesignWorkspaceHelper.formatNumber(optimum.metrics.conversion) ; ...
                'Selectivity', DesignWorkspaceHelper.formatNumber(baseline.metrics.selectivity), DesignWorkspaceHelper.formatNumber(optimum.metrics.selectivity) ; ...
                'Yield', DesignWorkspaceHelper.formatNumber(baseline.metrics.yield), DesignWorkspaceHelper.formatNumber(optimum.metrics.yield) ; ...
                'tau', DesignWorkspaceHelper.formatNumber(DesignWorkspaceHelper.getStructField(baselineParams, 'tau', NaN)), DesignWorkspaceHelper.formatNumber(DesignWorkspaceHelper.getStructField(optimumParams, 'tau', NaN)) ; ...
                'Recycle ratio', DesignWorkspaceHelper.formatNumber(DesignWorkspaceHelper.getStructField(baselineParams, 'recycleRatio', 0)), DesignWorkspaceHelper.formatNumber(DesignWorkspaceHelper.getStructField(optimumParams, 'recycleRatio', 0))} ;
            optimizationResult.constraintTable = constraintTable ;
            optimizationResult.sensitivityTable = sensitivityTable ;
            optimizationResult.summaryText = sprintf([ ...
                'Objective: %s. Baseline conversion = %.6g, optimum conversion = %.6g, ' ...
                'baseline selectivity = %.6g, optimum selectivity = %.6g.'], ...
                objective, baseline.metrics.conversion, optimum.metrics.conversion, ...
                baseline.metrics.selectivity, optimum.metrics.selectivity) ;
        end

        function scaleUpResult = compareScaleUp(scaleSpec)
            pilotSpec = scaleSpec ;
            pilotSpec.params = DesignWorkspaceHelper.getRequiredField(scaleSpec, 'pilotParams') ;
            industrialSpec = scaleSpec ;
            industrialSpec.params = DesignWorkspaceHelper.getRequiredField(scaleSpec, 'industrialParams') ;

            pilot = DesignWorkspaceHelper.evaluateHydroScenario(pilotSpec) ;
            industrial = DesignWorkspaceHelper.evaluateHydroScenario(industrialSpec) ;

            scaleUpResult = struct() ;
            scaleUpResult.pilot = pilot ;
            scaleUpResult.industrial = industrial ;
            scaleUpResult.comparisonTable = { ...
                'Conversion', DesignWorkspaceHelper.formatNumber(pilot.metrics.conversion), DesignWorkspaceHelper.formatNumber(industrial.metrics.conversion) ; ...
                'Selectivity', DesignWorkspaceHelper.formatNumber(pilot.metrics.selectivity), DesignWorkspaceHelper.formatNumber(industrial.metrics.selectivity) ; ...
                'Yield', DesignWorkspaceHelper.formatNumber(pilot.metrics.yield), DesignWorkspaceHelper.formatNumber(industrial.metrics.yield) ; ...
                'tau', DesignWorkspaceHelper.formatNumber(DesignWorkspaceHelper.getStructField(pilot.params, 'tau', NaN)), DesignWorkspaceHelper.formatNumber(DesignWorkspaceHelper.getStructField(industrial.params, 'tau', NaN)) ; ...
                'Recycle ratio', DesignWorkspaceHelper.formatNumber(DesignWorkspaceHelper.getStructField(pilot.params, 'recycleRatio', 0)), DesignWorkspaceHelper.formatNumber(DesignWorkspaceHelper.getStructField(industrial.params, 'recycleRatio', 0))} ;
            scaleUpResult.summaryText = sprintf([ ...
                'Pilot conversion = %.6g and industrial conversion = %.6g. ' ...
                'Pilot selectivity = %.6g and industrial selectivity = %.6g.'], ...
                pilot.metrics.conversion, industrial.metrics.conversion, ...
                pilot.metrics.selectivity, industrial.metrics.selectivity) ;
            %#ok<NASGU>
        end

        function scenario = evaluateHydroScenario(spec)
            family = char(string(DesignWorkspaceHelper.getStructField(spec, 'family', 'Tanks-in-Series'))) ;
            boundary = char(string(DesignWorkspaceHelper.getStructField(spec, 'boundaryType', 'closed-closed'))) ;
            reactionMode = char(string(DesignWorkspaceHelper.getStructField(spec, 'reactionMode', 'Segregation'))) ;
            RS = DesignWorkspaceHelper.getRequiredField(spec, 'RS') ;
            C0Fresh = DesignWorkspaceHelper.ensureRowVector( ...
                DesignWorkspaceHelper.getRequiredField(spec, 'C0')) ;
            params = DesignWorkspaceHelper.getRequiredField(spec, 'params') ;
            keyIdx = DesignWorkspaceHelper.getStructField(spec, 'keyComponentIndex', 1) ;
            desiredIdx = DesignWorkspaceHelper.getStructField(spec, 'desiredProductIndex', []) ;
            byproductIdx = DesignWorkspaceHelper.getStructField(spec, 'byproductIndex', []) ;

            recycleRatio = DesignWorkspaceHelper.getStructField(params, 'recycleRatio', 0) ;
            recycleRatio = max(recycleRatio, 0) ;

            C_in = C0Fresh ;
            tauNominal = DesignWorkspaceHelper.getStructField(params, 'tau', 1) ;
            tauInternal = tauNominal / (1 + recycleRatio) ;

            if recycleRatio > 0
                for k = 1:60
                    [C_out_trial, rtdObj] = DesignWorkspaceHelper.solveSinglePass( ...
                        family, boundary, reactionMode, RS, C_in, tauInternal, params, keyIdx) ;
                    C_new = (C0Fresh + recycleRatio * C_out_trial) / (1 + recycleRatio) ;
                    if norm(C_new - C_in, Inf) < 1e-8
                        C_in = C_new ;
                        break
                    end
                    C_in = 0.7 * C_in + 0.3 * C_new ;
                end
            end

            [C_out, rtdObj, modeInfo] = DesignWorkspaceHelper.solveSinglePass( ...
                family, boundary, reactionMode, RS, C_in, tauInternal, params, keyIdx) ;
            metrics = DesignWorkspaceHelper.computeScenarioMetrics(C_in, C_out, keyIdx, desiredIdx, byproductIdx) ;

            scenario = struct() ;
            scenario.family = family ;
            scenario.boundaryType = boundary ;
            scenario.reactionMode = reactionMode ;
            scenario.params = params ;
            scenario.C_in = C_in ;
            scenario.C_out = C_out ;
            scenario.rtd = rtdObj ;
            scenario.modeInfo = modeInfo ;
            scenario.metrics = metrics ;
        end

    end

    methods (Static, Access = private)

        function [C_out, rtdObj, modeInfo] = solveSinglePass(family, boundary, reactionMode, RS, C0, tau, params, keyIdx)
            rtdObj = DesignWorkspaceHelper.buildEquivalentRTD(family, boundary, tau, params) ;
            modeInfo = struct('directFirstOrder', false, 'kFirstOrder', NaN) ;

            switch char(string(reactionMode))
                case 'Segregation'
                    seg = SegregationModel(rtdObj) ;
                    seg.keyComponentIndex = keyIdx ;
                    seg = seg.compute_isothermal(RS, C0) ;
                    C_out = seg.C_exit ;

                case 'Max Mixedness'
                    mm = MaxMixednessModel(rtdObj) ;
                    mm.keyComponentIndex = keyIdx ;
                    mm = mm.compute_isothermal(RS, C0) ;
                    C_out = mm.C_exit ;

                otherwise
                    seg = SegregationModel(rtdObj) ;
                    seg.keyComponentIndex = keyIdx ;
                    seg = seg.compute_isothermal(RS, C0) ;
                    C_out = seg.C_exit ;
            end
        end

        function rtdObj = buildEquivalentRTD(family, boundary, tau, params)
            switch char(string(family))
                case 'Tanks-in-Series'
                    N = max(DesignWorkspaceHelper.getStructField(params, 'N', 1), 1e-3) ;
                    rtdObj = RTD.tanks_in_series(N, tau) ;

                case 'Axial Dispersion'
                    Bo = max(DesignWorkspaceHelper.getStructField(params, 'Bo', 0.05), 1e-5) ;
                    rtdObj = DesignWorkspaceHelper.buildDispersionRTD(Bo, tau, boundary) ;

                case 'CSTR + Dead Volume'
                    alpha = min(max(DesignWorkspaceHelper.getStructField(params, 'activeFraction', 1), 1e-6), 1) ;
                    tauNominal = tau / alpha ;
                    rtdObj = RTD.cstr_with_dead_volume(tauNominal, alpha) ;

                case 'CSTR + Bypass'
                    beta = min(max(DesignWorkspaceHelper.getStructField(params, 'bypass', ...
                        DesignWorkspaceHelper.getStructField(params, 'bypassFraction', 0)), 0), 0.95) ;
                    rtdObj = RTD.cstr_with_bypass(tau, beta) ;

                case 'CSTR + Dead Volume + Bypass'
                    alpha = min(max(DesignWorkspaceHelper.getStructField(params, 'activeFraction', 1), 1e-6), 1) ;
                    beta = min(max(DesignWorkspaceHelper.getStructField(params, 'bypass', ...
                        DesignWorkspaceHelper.getStructField(params, 'bypassFraction', 0)), 0), 0.95) ;
                    tauNominal = tau / alpha ;
                    rtdObj = RTD.cstr_with_bypass_and_dead(tauNominal, alpha, beta) ;

                otherwise
                    error('Unknown hydrodynamic family: %s', family) ;
            end
        end

        function rtdObj = buildDispersionRTD(Bo, tau, boundary, tspan)
            if nargin < 4
                tspan = [] ;
            end

            switch char(string(boundary))
                case 'open-open'
                    if isempty(tspan)
                        rtdObj = RTD.dispersion_open(Bo, tau) ;
                    else
                        rtdObj = RTD.dispersion_open(Bo, tau, tspan) ;
                    end
                otherwise
                    if isempty(tspan)
                        rtdObj = RTD.dispersion_closed(Bo, tau) ;
                    else
                        rtdObj = RTD.dispersion_closed(Bo, tau, tspan) ;
                    end
            end
        end

        function firstOrder = computeFirstOrderDirect(rtdObj, RS, C0, keyIdx)
            firstOrder = struct('isAvailable', false, 'k', NaN, 'X_direct', NaN) ;

            if isempty(RS) || ~isempty(RS.userDefinedKinetics)
                return
            end
            if RS.nReactions ~= 1 || keyIdx > RS.nComponents
                return
            end

            partials = RS.partialOrders ;
            if size(partials, 1) ~= 1
                return
            end
            mask = false(1, RS.nComponents) ;
            mask(keyIdx) = true ;
            if abs(partials(1, keyIdx) - 1) > 1e-12
                return
            end
            if any(abs(partials(1, ~mask)) > 1e-12)
                return
            end

            k = RS.k0(1) * exp(-RS.Ea(1) / 8.314 / 298.15) ;
            survival = trapz(rtdObj.t, exp(-k * rtdObj.t) .* rtdObj.Et) ;
            Xdirect = 1 - survival ;

            firstOrder.isAvailable = true ;
            firstOrder.k = k ;
            firstOrder.X_direct = max(min(Xdirect, 1), 0) ;
            firstOrder.C_exit_key = C0(keyIdx) * (1 - firstOrder.X_direct) ;
        end

        function metrics = computeScenarioMetrics(Cin, Cout, keyIdx, desiredIdx, byproductIdx)
            metrics = struct('conversion', NaN, 'selectivity', NaN, 'yield', NaN) ;

            CinKey = max(Cin(keyIdx), 1e-12) ;
            metrics.conversion = max(min((CinKey - Cout(keyIdx)) / CinKey, 1), 0) ;

            if ~isempty(desiredIdx) && desiredIdx >= 1 && desiredIdx <= numel(Cout)
                desiredC = max(Cout(desiredIdx), 0) ;
                if ~isempty(byproductIdx) && byproductIdx >= 1 && byproductIdx <= numel(Cout) && byproductIdx ~= desiredIdx
                    byproductC = max(Cout(byproductIdx), 0) ;
                    denom = desiredC + byproductC ;
                    if denom > 0
                        metrics.selectivity = desiredC / denom ;
                    end
                end

                reacted = max(CinKey - Cout(keyIdx), 0) ;
                if reacted > 0
                    metrics.yield = desiredC / reacted ;
                end
            end
        end

        function tableData = buildOutletTable(RS, C0, Cseg, Cmm, Ccstr, Cpfr)
            nComp = numel(C0) ;
            tableData = cell(nComp, 6) ;
            for i = 1:nComp
                tableData{i, 1} = DesignWorkspaceHelper.componentLabel(RS, i) ;
                tableData{i, 2} = DesignWorkspaceHelper.formatNumber(C0(i)) ;
                tableData{i, 3} = DesignWorkspaceHelper.formatNumber(Cseg(i)) ;
                tableData{i, 4} = DesignWorkspaceHelper.formatNumber(Cmm(i)) ;
                tableData{i, 5} = DesignWorkspaceHelper.formatNumber(Ccstr(i)) ;
                tableData{i, 6} = DesignWorkspaceHelper.formatNumber(Cpfr(i)) ;
            end
        end

        function txt = buildReactiveSummary(metricsCSTR, metricsSeg, metricsMM, metricsPFR, firstOrder)
            txt = sprintf(['Ideal CSTR X = %.6g, Segregation X = %.6g, ' ...
                'Max Mixedness X = %.6g, Ideal PFR X = %.6g.'], ...
                metricsCSTR.conversion, metricsSeg.conversion, ...
                metricsMM.conversion, metricsPFR.conversion) ;
            if firstOrder.isAvailable
                txt = sprintf('%s First-order direct RTD conversion = %.6g (k = %.6g 1/s).', ...
                    txt, firstOrder.X_direct, firstOrder.k) ;
            end
        end

        function tableData = parametersToTable(params)
            fields = fieldnames(params) ;
            tableData = cell(numel(fields), 2) ;
            for i = 1:numel(fields)
                tableData{i, 1} = fields{i} ;
                tableData{i, 2} = DesignWorkspaceHelper.formatNumber(params.(fields{i})) ;
            end
        end

        function score = curveScore(rtdRef, rtdModel)
            score = trapz(rtdRef.t, (rtdRef.Et - rtdModel.Et).^2) ;
            score = score + 0.1 * abs(rtdRef.tau - rtdModel.tau) / max(rtdRef.tau, 1e-12) ;
        end

        function frac = estimateEarlyMassFraction(rtdObj)
            tau = max(rtdObj.tau, 1e-12) ;
            idx = rtdObj.t <= 0.1 * tau ;
            if nnz(idx) < 2
                frac = 0 ;
                return
            end
            tEarly = DesignWorkspaceHelper.ensureRowVector(rtdObj.t(idx)) ;
            eEarly = DesignWorkspaceHelper.ensureRowVector(rtdObj.Et(idx)) ;
            frac = trapz(tEarly, eEarly) ;
        end

        function nPeaks = countPeaks(y)
            y = DesignWorkspaceHelper.ensureRowVector(y) ;
            if isempty(y) || ~isnumeric(y)
                nPeaks = 0 ;
                return
            end
            y = y(isfinite(y)) ;
            if numel(y) < 5
                nPeaks = 0 ;
                return
            end
            dy = diff(y) ;
            candidates = find(dy(1:end-1) > 0 & dy(2:end) <= 0) + 1 ;
            if isempty(candidates)
                nPeaks = 0 ;
                return
            end
            threshold = 0.05 * max(y) ;
            nPeaks = sum(y(candidates) >= threshold) ;
        end

        function out = flagText(flag)
            if flag
                out = 'Yes' ;
            else
                out = 'No' ;
            end
        end

        function scale = timeScaleFromUnit(unitLabel)
            switch char(string(unitLabel))
                case 'h'
                    scale = 3600 ;
                case 'min'
                    scale = 60 ;
                otherwise
                    scale = 1 ;
            end
        end

        function [x0, lb, ub, names, fixedParams] = unpackDecisionVariables(decisionVariables)
            x0 = [] ; lb = [] ; ub = [] ; names = {} ; fixedParams = struct() ;
            for i = 1:numel(decisionVariables)
                row = decisionVariables(i) ;
                name = char(string(row.variable)) ;
                if isfield(row, 'use') && row.use
                    x0(end+1) = row.initialValue ; %#ok<AGROW>
                    lb(end+1) = row.lowerBound ; %#ok<AGROW>
                    ub(end+1) = row.upperBound ; %#ok<AGROW>
                    names{end+1} = name ; %#ok<AGROW>
                else
                    fixedParams.(name) = row.initialValue ;
                end
            end
        end

        function params = combineParams(names, x, fixedParams)
            params = fixedParams ;
            for i = 1:numel(names)
                params.(names{i}) = x(i) ;
            end
            if ~isfield(params, 'tau')
                params.tau = 1 ;
            end
            if ~isfield(params, 'N')
                params.N = 2 ;
            end
            if ~isfield(params, 'Bo')
                params.Bo = 0.05 ;
            end
            if ~isfield(params, 'bypass')
                params.bypass = 0 ;
            end
            if ~isfield(params, 'activeFraction')
                params.activeFraction = 1 ;
            end
            if ~isfield(params, 'recycleRatio')
                params.recycleRatio = 0 ;
            end
        end

        function f = optimizationPenaltyObjective(x, lb, ub, names, fixedParams, constraints, objective, optSpec, RS, C0)
            penalty = 1e5 * sum(max(lb - x, 0).^2 + max(x - ub, 0).^2) ;
            xClamped = min(max(x, lb), ub) ;
            params = DesignWorkspaceHelper.combineParams(names, xClamped, fixedParams) ;

            scenario = DesignWorkspaceHelper.evaluateHydroScenario(struct( ...
                'family', DesignWorkspaceHelper.getStructField(optSpec, 'family', 'Tanks-in-Series'), ...
                'boundaryType', DesignWorkspaceHelper.getStructField(optSpec, 'boundaryType', 'closed-closed'), ...
                'reactionMode', DesignWorkspaceHelper.getStructField(optSpec, 'reactionMode', 'Segregation'), ...
                'RS', RS, ...
                'C0', C0, ...
                'keyComponentIndex', DesignWorkspaceHelper.getStructField(optSpec, 'keyComponentIndex', 1), ...
                'desiredProductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'desiredProductIndex', []), ...
                'byproductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'byproductIndex', []), ...
                'params', params)) ;

            metricValue = DesignWorkspaceHelper.objectiveMetricValue(objective, scenario, params) ;
            penalty = penalty + DesignWorkspaceHelper.constraintPenalty(constraints, scenario, params) ;
            f = metricValue + penalty ;
        end

        function value = objectiveMetricValue(objective, scenario, params)
            switch char(string(objective))
                case 'Max conversion'
                    value = -scenario.metrics.conversion ;
                case 'Max selectivity'
                    value = -DesignWorkspaceHelper.safeMetric(scenario.metrics.selectivity) ;
                case 'Max yield'
                    value = -DesignWorkspaceHelper.safeMetric(scenario.metrics.yield) ;
                case 'Min residence time'
                    value = DesignWorkspaceHelper.getStructField(params, 'tau', Inf) ;
                case 'Min recycle ratio'
                    value = DesignWorkspaceHelper.getStructField(params, 'recycleRatio', Inf) ;
                otherwise
                    value = DesignWorkspaceHelper.getStructField(params, 'tau', Inf) ;
            end
        end

        function penalty = constraintPenalty(constraints, scenario, params)
            penalty = 0 ;
            for i = 1:numel(constraints)
                row = constraints(i) ;
                if ~isfield(row, 'use') || ~row.use
                    continue
                end
                value = DesignWorkspaceHelper.constraintMetricValue(row.metric, row.speciesIndex, scenario, params) ;
                target = row.value ;
                switch char(string(row.type))
                    case 'Lower bound'
                        penalty = penalty + 1e5 * max(target - value, 0)^2 ;
                    case 'Upper bound'
                        penalty = penalty + 1e5 * max(value - target, 0)^2 ;
                    otherwise
                        penalty = penalty + 1e5 * (value - target)^2 ;
                end
            end
        end

        function tableData = evaluateConstraints(constraints, scenario)
            rows = {} ;
            params = scenario.params ;
            for i = 1:numel(constraints)
                row = constraints(i) ;
                if ~isfield(row, 'use') || ~row.use
                    continue
                end
                value = DesignWorkspaceHelper.constraintMetricValue(row.metric, row.speciesIndex, scenario, params) ;
                satisfied = DesignWorkspaceHelper.constraintSatisfied(row.type, value, row.value) ;
                rows(end+1, :) = {char(string(row.metric)), DesignWorkspaceHelper.formatNumber(value), ... %#ok<AGROW>
                    DesignWorkspaceHelper.formatNumber(row.value), DesignWorkspaceHelper.flagText(satisfied)} ;
            end
            if isempty(rows)
                rows = cell(0, 4) ;
            end
            tableData = rows ;
        end

        function tf = constraintSatisfied(type, value, target)
            switch char(string(type))
                case 'Lower bound'
                    tf = value >= target ;
                case 'Upper bound'
                    tf = value <= target ;
                otherwise
                    tf = abs(value - target) <= max(1e-9, 0.01 * abs(target)) ;
            end
        end

        function value = constraintMetricValue(metric, speciesIndex, scenario, params)
            switch char(string(metric))
                case 'Conversion'
                    value = scenario.metrics.conversion ;
                case 'Selectivity'
                    value = DesignWorkspaceHelper.safeMetric(scenario.metrics.selectivity) ;
                case 'Yield'
                    value = DesignWorkspaceHelper.safeMetric(scenario.metrics.yield) ;
                case 'Residence Time'
                    value = DesignWorkspaceHelper.getStructField(params, 'tau', NaN) ;
                case 'Recycle Ratio'
                    value = DesignWorkspaceHelper.getStructField(params, 'recycleRatio', 0) ;
                case 'C_out'
                    idx = max(1, min(numel(scenario.C_out), speciesIndex)) ;
                    value = scenario.C_out(idx) ;
                otherwise
                    value = NaN ;
            end
        end

        function tableData = computeSensitivity(names, optimumParams, optSpec, RS, C0, objective)
            tableData = cell(numel(names), 3) ;
            for i = 1:numel(names)
                pMinus = optimumParams ;
                pPlus = optimumParams ;
                baseValue = max(abs(optimumParams.(names{i})), 1e-6) ;
                pMinus.(names{i}) = max(1e-8, optimumParams.(names{i}) * 0.9) ;
                pPlus.(names{i}) = optimumParams.(names{i}) * 1.1 ;

                scMinus = DesignWorkspaceHelper.evaluateHydroScenario(struct( ...
                    'family', DesignWorkspaceHelper.getStructField(optSpec, 'family', 'Tanks-in-Series'), ...
                    'boundaryType', DesignWorkspaceHelper.getStructField(optSpec, 'boundaryType', 'closed-closed'), ...
                    'reactionMode', DesignWorkspaceHelper.getStructField(optSpec, 'reactionMode', 'Segregation'), ...
                    'RS', RS, ...
                    'C0', C0, ...
                    'keyComponentIndex', DesignWorkspaceHelper.getStructField(optSpec, 'keyComponentIndex', 1), ...
                    'desiredProductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'desiredProductIndex', []), ...
                    'byproductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'byproductIndex', []), ...
                    'params', pMinus)) ;
                scPlus = DesignWorkspaceHelper.evaluateHydroScenario(struct( ...
                    'family', DesignWorkspaceHelper.getStructField(optSpec, 'family', 'Tanks-in-Series'), ...
                    'boundaryType', DesignWorkspaceHelper.getStructField(optSpec, 'boundaryType', 'closed-closed'), ...
                    'reactionMode', DesignWorkspaceHelper.getStructField(optSpec, 'reactionMode', 'Segregation'), ...
                    'RS', RS, ...
                    'C0', C0, ...
                    'keyComponentIndex', DesignWorkspaceHelper.getStructField(optSpec, 'keyComponentIndex', 1), ...
                    'desiredProductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'desiredProductIndex', []), ...
                    'byproductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'byproductIndex', []), ...
                    'params', pPlus)) ;

                objMinus = DesignWorkspaceHelper.objectiveMetricValue(objective, scMinus, pMinus) ;
                objPlus = DesignWorkspaceHelper.objectiveMetricValue(objective, scPlus, pPlus) ;
                slope = (objPlus - objMinus) / (0.2 * baseValue) ;
                tableData{i, 1} = names{i} ;
                tableData{i, 2} = DesignWorkspaceHelper.formatNumber(baseValue) ;
                tableData{i, 3} = DesignWorkspaceHelper.formatNumber(slope) ;
            end
        end

        function xOpt = penalizedFminsearch(objFun, x0, lb, ub)
            x0 = DesignWorkspaceHelper.ensureRowVector(x0) ;
            lb = DesignWorkspaceHelper.ensureRowVector(lb) ;
            ub = DesignWorkspaceHelper.ensureRowVector(ub) ;
            options = optimset('Display', 'off', 'MaxIter', 200, 'MaxFunEvals', 800) ;
            wrapped = @(x) objFun(min(max(x, lb), ub)) + 1e4 * sum(max(lb - x, 0).^2 + max(x - ub, 0).^2) ;
            xOpt = fminsearch(wrapped, x0, options) ;
            xOpt = min(max(xOpt, lb), ub) ;
        end

        function value = safeMetric(value)
            if isempty(value) || ~isfinite(value)
                value = 0 ;
            end
        end

        function label = componentLabel(RS, idx)
            label = sprintf('C%d', idx) ;
            try
                if ~isempty(RS.componentNames) && numel(RS.componentNames) >= idx
                    label = char(string(RS.componentNames{idx})) ;
                end
            catch
            end
        end

        function rtdObj = getRequiredRTD(spec)
            rtdObj = DesignWorkspaceHelper.getStructField(spec, 'rtd', []) ;
            if isempty(rtdObj)
                rtdObj = DesignWorkspaceHelper.getStructField(spec, 'rtdObject', []) ;
            end
            if isempty(rtdObj) || ~isa(rtdObj, 'RTD')
                error('A valid RTD object is required.') ;
            end
        end

        function value = getRequiredField(S, fieldName)
            value = DesignWorkspaceHelper.getStructField(S, fieldName, []) ;
            if isempty(value)
                error('Required field missing or empty: %s', fieldName) ;
            end
        end

        function value = getStructField(S, fieldName, defaultValue)
            value = defaultValue ;
            if isstruct(S) && isfield(S, fieldName)
                value = S.(fieldName) ;
            end
        end

        function out = ensureRowVector(x)
            out = x ;
            if isempty(x)
                return
            end
            if ~isnumeric(x) && ~islogical(x)
                out = reshape(x, 1, []) ;
                return
            end
            out = double(x(:)).' ;
        end

        function txt = formatNumber(value)
            if isempty(value) || any(~isfinite(value))
                txt = '-' ;
            else
                txt = sprintf('%.6g', value) ;
            end
        end

        function tf = familyNeedsReferenceTau(family)
            family = char(string(family)) ;
            tf = any(strcmp(family, {'CSTR + Dead Volume', 'CSTR + Dead Volume + Bypass'})) ;
        end

        function [sortedResults, sortedEntries, bestIdx] = rankFitSearchEntries(validResults, entries)
            validMask = strcmp({entries.status}, 'OK') ;
            okEntries = entries(validMask) ;
            skippedEntries = entries(~validMask) ;
            rmse = [okEntries.rmse] ;
            score = [okEntries.score] ;
            order = [(1:numel(okEntries))', rmse(:), -score(:)] ;
            order = sortrows(order, [2 3 1]) ;
            okEntries = okEntries(order(:, 1)) ;
            sortedResults = [validResults{order(:, 1)}] ;
            sortedEntries = [okEntries ; skippedEntries] ;
            bestIdx = 1 ;
        end

        function diagnostics = buildSearchDiagnostics(entries)
            lines = strings(0, 1) ;
            okMask = strcmp({entries.status}, 'OK') ;
            if any(okMask)
                bestFamily = entries(find(okMask, 1, 'first')).displayName ;
                lines(end + 1, 1) = "Best family found: " + string(bestFamily) + "."; %#ok<AGROW>
            end
            for i = 1:numel(entries)
                if strcmp(entries(i).status, 'Skipped') && ~isempty(entries(i).message)
                    lines(end + 1, 1) = string(entries(i).displayName) + ": " + string(entries(i).message); %#ok<AGROW>
                end
            end
            if isempty(lines)
                lines = "Search completed." ;
            end
            diagnostics = struct('summaryText', cellstr(lines)) ;
        end

    end
end
