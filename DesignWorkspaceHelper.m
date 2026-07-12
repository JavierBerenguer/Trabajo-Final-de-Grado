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
                struct('family', 'CSTR (dead volume)', 'displayName', 'CSTR (dead volume)', 'boundaryType', 'closed-closed') ; ...
                struct('family', 'PFR (dead volume)', 'displayName', 'PFR (dead volume)', 'boundaryType', 'closed-closed') ; ...
                struct('family', 'PFR + CSTR (series, dead volume)', 'displayName', 'PFR + CSTR (series, dead volume)', 'boundaryType', 'closed-closed') ; ...
                struct('family', 'PFR + CSTR (parallel, dead volume)', 'displayName', 'PFR + CSTR (parallel, dead volume)', 'boundaryType', 'closed-closed') ; ...
                struct('family', 'CSTR + Bypass (dead volume)', 'displayName', 'CSTR + Bypass (dead volume)', 'boundaryType', 'closed-closed') ...
                } ;

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

                try
                    singleSpec = fitSpec ;
                    singleSpec.family = family ;
                    singleSpec.boundaryType = candidate.boundaryType ;
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
            totalVolume = DesignWorkspaceHelper.getStructField( ...
                fitSpec, 'totalVolume', []) ;
            flowRate = DesignWorkspaceHelper.getStructField( ...
                fitSpec, 'flowRate', []) ;
            fitConstraints = DesignWorkspaceHelper.getStructField( ...
                fitSpec, 'fitConstraints', struct('variable', {}, 'lowerBound', {}, 'upperBound', {})) ;

            family = DesignWorkspaceHelper.normalizeFitFamilyName(family) ;

            t = rtdObj.t ;
            fitMeta = struct() ;
            fitMeta.family = family ;
            fitMeta.boundaryType = boundary ;
            fitMeta.referenceTau = DesignWorkspaceHelper.resolveNominalTau(referenceTau, totalVolume, flowRate) ;

            switch family
                case 'Tanks-in-Series'
                    n0 = max(1, min(50, rtdObj.tau^2 / max(rtdObj.sigma2, 1e-12))) ;
                    [lbN, ubN] = DesignWorkspaceHelper.getFitConstraintBounds(fitConstraints, 'N', 1, 200) ;
                    n0 = min(max(n0, lbN), ubN) ;
                    objFun = @(x) DesignWorkspaceHelper.curveScore( ...
                        rtdObj, RTD.tanks_in_series(max(x(1), 1e-3), rtdObj.tau, t)) ;
                    x = DesignWorkspaceHelper.penalizedFminsearch(objFun, n0, lbN, ubN) ;
                    nFit = max(x(1), 1e-3) ;
                    modelRTD = RTD.tanks_in_series(nFit, rtdObj.tau, t) ;
                    params = struct('tau', rtdObj.tau, 'N', nFit) ;

                case 'Axial Dispersion'
                    sigmaTheta = max(rtdObj.sigma2_theta, 1e-8) ;
                    bo0 = max(1e-5, min(5, sigmaTheta / 2)) ;
                    [lbBo, ubBo] = DesignWorkspaceHelper.getFitConstraintBounds(fitConstraints, 'Bo', 1e-5, 5) ;
                    bo0 = min(max(bo0, lbBo), ubBo) ;
                    objFun = @(x) DesignWorkspaceHelper.curveScore( ...
                        rtdObj, DesignWorkspaceHelper.buildDispersionRTD(max(x(1), 1e-5), rtdObj.tau, boundary, t)) ;
                    x = DesignWorkspaceHelper.penalizedFminsearch(objFun, bo0, lbBo, ubBo) ;
                    boFit = max(x(1), 1e-5) ;
                    modelRTD = DesignWorkspaceHelper.buildDispersionRTD(boFit, rtdObj.tau, boundary, t) ;
                    params = struct('tau', rtdObj.tau, 'Bo', boFit, 'Pe', 1 / boFit) ;

                case 'CSTR (dead volume)'
                    modelRTD = RTD.ideal_cstr(rtdObj.tau, t) ;
                    params = struct('tau_active', modelRTD.tau) ;

                case 'PFR (dead volume)'
                    modelRTD = RTD.ideal_pfr(rtdObj.tau, t) ;
                    params = struct('tau_active', modelRTD.tau) ;

                case 'PFR + CSTR (series, dead volume)'
                    tauActive = max(rtdObj.tau, 1e-8) ;
                    tauCstr0 = min(max(sqrt(max(rtdObj.sigma2, 0)), 1e-6), 0.999 * tauActive) ;
                    [lbTauCstr, ubTauCstr] = DesignWorkspaceHelper.deriveSeriesTauCstrBounds(fitConstraints, tauActive) ;
                    tauCstr0 = min(max(tauCstr0, lbTauCstr), ubTauCstr) ;
                    objFun = @(x) DesignWorkspaceHelper.curveScore( ...
                        rtdObj, RTD.from_cstr_series_with_pfr( ...
                        min(max(x(1), 1e-6), 0.999 * tauActive), ...
                        max(tauActive - min(max(x(1), 1e-6), 0.999 * tauActive), 0), t)) ;
                    x = DesignWorkspaceHelper.penalizedFminsearch(objFun, tauCstr0, lbTauCstr, ubTauCstr) ;
                    tauCstrFit = min(max(x(1), 1e-6), 0.999 * tauActive) ;
                    tauPfrFit = max(tauActive - tauCstrFit, 0) ;
                    modelRTD = RTD.from_cstr_series_with_pfr(tauCstrFit, tauPfrFit, t) ;
                    params = struct( ...
                        'tau_active', tauActive, ...
                        'tau_pfr_active', tauPfrFit, ...
                        'tau_cstr_active', tauCstrFit, ...
                        'pfrResidenceFraction', tauPfrFit / tauActive, ...
                        'cstrResidenceFraction', tauCstrFit / tauActive) ;

                case 'PFR + CSTR (parallel, dead volume)'
                    split0 = 0.5 ;
                    tauPfr0 = max(0.5 * rtdObj.tau, 1e-6) ;
                    tauCstr0 = max(max(rtdObj.sigma2 / max(rtdObj.tau, 1e-8), 1e-6), 0.5 * rtdObj.tau) ;
                    [lbSplit, ubSplit] = DesignWorkspaceHelper.getFitConstraintBounds(fitConstraints, 'splitToPFR', 0, 1) ;
                    [lbTauPfr, ubTauPfr] = DesignWorkspaceHelper.getFitConstraintBounds(fitConstraints, 'tau_pfr_active', 1e-6, max(10 * rtdObj.tau, 1)) ;
                    [lbTauCstr, ubTauCstr] = DesignWorkspaceHelper.getFitConstraintBounds(fitConstraints, 'tau_cstr_active', 1e-6, max(10 * rtdObj.tau, 1)) ;
                    x0 = [min(max(split0, lbSplit), ubSplit), min(max(tauPfr0, lbTauPfr), ubTauPfr), min(max(tauCstr0, lbTauCstr), ubTauCstr)] ;
                    lb = [lbSplit, lbTauPfr, lbTauCstr] ;
                    ub = [ubSplit, ubTauPfr, ubTauCstr] ;
                    objFun = @(x) DesignWorkspaceHelper.curveScore( ...
                        rtdObj, DesignWorkspaceHelper.buildParallelPfrCstrRTD( ...
                        min(max(x(1), 0), 1), ...
                        max(x(2), 1e-6), ...
                        max(x(3), 1e-6), t)) ;
                    x = DesignWorkspaceHelper.penalizedFminsearch(objFun, x0, lb, ub) ;
                    splitToPfr = min(max(x(1), 0), 1) ;
                    tauPfrFit = max(x(2), 1e-6) ;
                    tauCstrFit = max(x(3), 1e-6) ;
                    modelRTD = DesignWorkspaceHelper.buildParallelPfrCstrRTD(splitToPfr, tauPfrFit, tauCstrFit, t) ;
                    splitToCstr = 1 - splitToPfr ;
                    params = struct( ...
                        'tau_active', splitToPfr * tauPfrFit + splitToCstr * tauCstrFit, ...
                        'tau_pfr_active', tauPfrFit, ...
                        'tau_cstr_active', tauCstrFit, ...
                        'splitToPFR', splitToPfr, ...
                        'splitToCSTR', splitToCstr) ;

                case 'CSTR + Bypass (dead volume)'
                    beta0 = min(max(DesignWorkspaceHelper.estimateEarlyMassFraction(rtdObj), 1e-4), 0.95) ;
                    [lbBeta, ubBeta] = DesignWorkspaceHelper.getFitConstraintBounds(fitConstraints, 'bypassFraction', 0, 0.95) ;
                    beta0 = min(max(beta0, lbBeta), ubBeta) ;
                    objFun = @(x) DesignWorkspaceHelper.curveScore( ...
                        rtdObj, RTD.cstr_with_bypass(rtdObj.tau, min(max(x(1), 0), 0.95), t)) ;
                    x = DesignWorkspaceHelper.penalizedFminsearch(objFun, beta0, lbBeta, ubBeta) ;
                    betaFit = min(max(x(1), 0), 0.95) ;
                    modelRTD = RTD.cstr_with_bypass(rtdObj.tau, betaFit, t) ;
                    params = struct('tau_active', rtdObj.tau, 'bypassFraction', betaFit) ;

                otherwise
                    error('Unknown fit family: %s', family) ;
            end

            params = DesignWorkspaceHelper.appendDeadVolumeParameters(params, modelRTD.tau, referenceTau, totalVolume, flowRate) ;

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
            rtdObj = DesignWorkspaceHelper.getRequiredRTD(optSpec) ;
            RS = DesignWorkspaceHelper.getRequiredField(optSpec, 'RS') ;
            feedStream = DesignWorkspaceHelper.getRequiredField(optSpec, 'feedStream') ;
            baseFeed = DesignWorkspaceHelper.extractOptimizationFeedState(feedStream) ;

            decisionVariables = DesignWorkspaceHelper.getStructField(optSpec, 'decisionVariables', struct([])) ;
            constraints = DesignWorkspaceHelper.getStructField(optSpec, 'constraints', struct([])) ;
            objective = char(string(DesignWorkspaceHelper.getStructField( ...
                optSpec, 'objective', 'Max conversion'))) ;
            basisMode = DesignWorkspaceHelper.resolveOptimizationBasis(decisionVariables) ;

            [x0, lb, ub, names, fixedParams, definitions] = DesignWorkspaceHelper.unpackDecisionVariables(decisionVariables, baseFeed) ;
            if isempty(x0)
                error('At least one active decision variable is required.') ;
            end

            objFun = @(x) DesignWorkspaceHelper.optimizationPenaltyObjective( ...
                x, lb, ub, names, fixedParams, definitions, basisMode, constraints, objective, ...
                optSpec, RS, rtdObj, baseFeed) ;
            xOpt = DesignWorkspaceHelper.penalizedFminsearch(objFun, x0, lb, ub) ;

            baselineParams = DesignWorkspaceHelper.combineParams(names, x0, fixedParams) ;
            optimumParams = DesignWorkspaceHelper.combineParams(names, xOpt, fixedParams) ;
            reactionMode = DesignWorkspaceHelper.getStructField(optSpec, 'reactionMode', 'Segregation') ;
            keyIdx = DesignWorkspaceHelper.getStructField(optSpec, 'keyComponentIndex', 1) ;
            desiredIdx = DesignWorkspaceHelper.getStructField(optSpec, 'desiredProductIndex', []) ;
            byproductIdx = DesignWorkspaceHelper.getStructField(optSpec, 'byproductIndex', []) ;

            baseline = DesignWorkspaceHelper.evaluateProcessScenario(struct( ...
                'rtd', rtdObj, ...
                'reactionMode', reactionMode, ...
                'objective', objective, ...
                'computeFullModelSet', true, ...
                'RS', RS, ...
                'baseFeed', baseFeed, ...
                'keyComponentIndex', keyIdx, ...
                'desiredProductIndex', desiredIdx, ...
                'byproductIndex', byproductIdx, ...
                'params', baselineParams, ...
                'decisionDefinitions', definitions, ...
                'basisMode', basisMode)) ;
            optimum = DesignWorkspaceHelper.evaluateProcessScenario(struct( ...
                'rtd', rtdObj, ...
                'reactionMode', reactionMode, ...
                'objective', objective, ...
                'computeFullModelSet', true, ...
                'RS', RS, ...
                'baseFeed', baseFeed, ...
                'keyComponentIndex', keyIdx, ...
                'desiredProductIndex', desiredIdx, ...
                'byproductIndex', byproductIdx, ...
                'params', optimumParams, ...
                'decisionDefinitions', definitions, ...
                'basisMode', basisMode)) ;
            baseline = DesignWorkspaceHelper.slimOptimizationScenario(baseline) ;
            optimum = DesignWorkspaceHelper.slimOptimizationScenario(optimum) ;

            optimizationResult = struct() ;
            optimizationResult.rtdSource = DesignWorkspaceHelper.getStructField(optSpec, 'rtdSource', 'Tab 1 RTD') ;
            optimizationResult.objective = objective ;
            optimizationResult.reactionMode = reactionMode ;
            optimizationResult.baseline = baseline ;
            optimizationResult.optimum = optimum ;
            optimizationResult.optimalParameters = optimumParams ;
            optimizationResult.decisionVariables = decisionVariables ;
            optimizationResult.activeDecisionVariables = decisionVariables(arrayfun(@(row) isfield(row, 'use') && row.use, decisionVariables)) ;
            optimizationResult.comparisonRows = DesignWorkspaceHelper.buildOptimizationComparisonRows( ...
                objective, optimizationResult.activeDecisionVariables, constraints, baseline, optimum) ;
            optimizationResult.modelComparisonRows = DesignWorkspaceHelper.buildOptimizationModelComparisonRows( ...
                RS, baseline.modelResults, optimum.modelResults) ;
            optimizationResult.constraintStatus = DesignWorkspaceHelper.evaluateOptimizationConstraintStatus(constraints, optimum) ;
            optimizationResult.summaryText = DesignWorkspaceHelper.buildOptimizationSummary( ...
                optimizationResult.rtdSource, reactionMode, objective, baseline, optimum, optimizationResult.constraintStatus) ;
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

        function scenario = evaluateProcessScenario(spec)
            rtdObj = DesignWorkspaceHelper.getRequiredRTD(spec) ;
            reactionMode = char(string(DesignWorkspaceHelper.getStructField(spec, 'reactionMode', 'Segregation'))) ;
            RS = DesignWorkspaceHelper.getRequiredField(spec, 'RS') ;
            baseFeed = DesignWorkspaceHelper.getRequiredField(spec, 'baseFeed') ;
            params = DesignWorkspaceHelper.getRequiredField(spec, 'params') ;
            decisionDefinitions = DesignWorkspaceHelper.getStructField(spec, 'decisionDefinitions', struct([])) ;
            basisMode = DesignWorkspaceHelper.getStructField(spec, 'basisMode', 'concentration') ;
            keyIdx = DesignWorkspaceHelper.getStructField(spec, 'keyComponentIndex', 1) ;
            desiredIdx = DesignWorkspaceHelper.getStructField(spec, 'desiredProductIndex', []) ;
            byproductIdx = DesignWorkspaceHelper.getStructField(spec, 'byproductIndex', []) ;
            computeFullModelSet = logical(DesignWorkspaceHelper.getStructField(spec, 'computeFullModelSet', false)) ;

            feedState = DesignWorkspaceHelper.reconstructOptimizationFeed(baseFeed, params, decisionDefinitions, basisMode) ;
            [activeModelKey, activeModelLabel] = DesignWorkspaceHelper.resolveOptimizationModelKey(reactionMode) ;
            if computeFullModelSet
                reactiveResult = DesignWorkspaceHelper.solveReactivePerformance(struct( ...
                    'rtd', rtdObj, ...
                    'RS', RS, ...
                    'C0', feedState.concentration, ...
                    'keyComponentIndex', keyIdx, ...
                    'desiredProductIndex', desiredIdx, ...
                    'byproductIndex', byproductIdx)) ;
                modelResults = DesignWorkspaceHelper.packOptimizationModelResults(feedState.concentration, reactiveResult) ;
                activeModel = modelResults.(activeModelKey) ;
                modeInfo = struct('directFirstOrder', false, 'kFirstOrder', NaN) ;
            else
                [C_out, modeInfo] = DesignWorkspaceHelper.solveFixedRTDPass( ...
                    rtdObj, reactionMode, RS, feedState.concentration, keyIdx) ;
                metrics = DesignWorkspaceHelper.computeScenarioMetrics( ...
                    feedState.concentration, C_out, keyIdx, desiredIdx, byproductIdx) ;
                activeModel = struct( ...
                    'label', activeModelLabel, ...
                    'C_in', feedState.concentration, ...
                    'C_out', C_out, ...
                    'metrics', metrics) ;
                modelResults = struct() ;
            end

            scenario = struct() ;
            scenario.reactionMode = reactionMode ;
            scenario.params = params ;
            scenario.Qv = feedState.Qv ;
            scenario.molarFlow = feedState.molarFlow ;
            scenario.C_in = feedState.concentration ;
            scenario.C_out = activeModel.C_out ;
            scenario.rtd = rtdObj ;
            scenario.modeInfo = modeInfo ;
            scenario.metrics = activeModel.metrics ;
            scenario.feedState = feedState ;
            scenario.modelResults = modelResults ;
            scenario.activeModel = activeModel ;
            scenario.activeModelKey = activeModelKey ;
            scenario.activeModelLabel = activeModelLabel ;
            scenario.keyComponentIndex = keyIdx ;
            scenario.desiredProductIndex = desiredIdx ;
            scenario.byproductIndex = byproductIdx ;
            scenario.componentLabels = DesignWorkspaceHelper.componentLabels(RS, numel(feedState.concentration)) ;
            scenario.objectiveValue = DesignWorkspaceHelper.objectiveMetricValue( ...
                DesignWorkspaceHelper.getStructField(spec, 'objective', 'Max conversion'), scenario) ;
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
                    tauSpace = tau / (1 + 2 * Bo) ;
                    if isempty(tspan)
                        rtdObj = RTD.dispersion_open(Bo, tauSpace) ;
                    else
                        rtdObj = RTD.dispersion_open(Bo, tauSpace, tspan) ;
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

        function metrics = computeScenarioMetrics(Cin, Cout, keyIdx, desiredIdx, ~)
            metrics = struct('conversion', NaN, 'selectivity', NaN, 'yield', NaN) ;

            metrics.conversion = DesignWorkspaceHelper.computeConversionValue(Cin, Cout, keyIdx) ;
            metrics.selectivity = DesignWorkspaceHelper.computeSelectivityValue(Cin, Cout, keyIdx, desiredIdx) ;
            metrics.yield = DesignWorkspaceHelper.computeYieldValue(Cin, Cout, keyIdx, desiredIdx) ;
        end

        function value = computeConversionValue(Cin, Cout, speciesIdx)
            if isempty(speciesIdx) || speciesIdx < 1 || speciesIdx > numel(Cout) || speciesIdx > numel(Cin)
                value = NaN ;
                return
            end
            CinSpecies = Cin(speciesIdx) ;
            if ~isfinite(CinSpecies) || CinSpecies <= 0
                value = NaN ;
                return
            end
            value = (CinSpecies - Cout(speciesIdx)) / CinSpecies ;
        end

        function value = computeSelectivityValue(Cin, Cout, keyIdx, desiredIdx)
            value = NaN ;
            if isempty(desiredIdx) || desiredIdx < 1 || desiredIdx > numel(Cout)
                return
            end
            reacted = max(Cin(keyIdx) - Cout(keyIdx), 0) ;
            if reacted <= 0
                return
            end
            value = max(Cout(desiredIdx), 0) / reacted ;
        end

        function value = computeYieldValue(Cin, Cout, keyIdx, desiredIdx)
            value = NaN ;
            if isempty(desiredIdx) || desiredIdx < 1 || desiredIdx > numel(Cout)
                return
            end
            CinKey = max(Cin(keyIdx), 1e-12) ;
            value = max(Cout(desiredIdx), 0) / CinKey ;
        end

        function value = computeOutletConcentrationValue(Cout, speciesIdx)
            value = NaN ;
            if isempty(speciesIdx) || speciesIdx < 1 || speciesIdx > numel(Cout)
                return
            end
            value = Cout(speciesIdx) ;
        end

        function modelResults = packOptimizationModelResults(Cin, reactiveResult)
            modelResults = struct() ;
            modelResults.cstr = struct( ...
                'label', 'Ideal CSTR', ...
                'C_in', Cin, ...
                'C_out', reactiveResult.cstr.C_out, ...
                'metrics', reactiveResult.metrics.cstr) ;
            modelResults.segregation = struct( ...
                'label', 'Segregation', ...
                'C_in', Cin, ...
                'C_out', reactiveResult.segregation.C_exit, ...
                'metrics', reactiveResult.metrics.segregation) ;
            modelResults.maxMixedness = struct( ...
                'label', 'Max Mixedness', ...
                'C_in', Cin, ...
                'C_out', reactiveResult.maxMixedness.C_exit, ...
                'metrics', reactiveResult.metrics.maxMixedness) ;
            modelResults.pfr = struct( ...
                'label', 'Ideal PFR', ...
                'C_in', Cin, ...
                'C_out', reactiveResult.pfr.C_out, ...
                'metrics', reactiveResult.metrics.pfr) ;
        end

        function [modelKey, modelLabel] = resolveOptimizationModelKey(reactionMode)
            switch char(string(reactionMode))
                case 'Max Mixedness'
                    modelKey = 'maxMixedness' ;
                    modelLabel = 'Max Mixedness' ;
                otherwise
                    modelKey = 'segregation' ;
                    modelLabel = 'Segregation' ;
            end
        end

        function rows = buildOptimizationComparisonRows(objective, activeDecisionVariables, constraints, baseline, optimum)
            rows = struct('label', {}, 'valueType', {}, 'baseValue', {}, 'optimumValue', {}) ;
            row = DesignWorkspaceHelper.buildOptimizationObjectiveRow(objective, baseline, optimum) ;
            rows(end + 1) = row ; %#ok<AGROW>

            baselineParams = baseline.params ;
            optimumParams = optimum.params ;
            for i = 1:numel(activeDecisionVariables)
                def = activeDecisionVariables(i) ;
                variableName = char(string(def.variable)) ;
                displayLabel = char(string(DesignWorkspaceHelper.getStructField(def, 'displayName', variableName))) ;
                rows(end + 1) = struct( ... %#ok<AGROW>
                    'label', displayLabel, ...
                    'valueType', DesignWorkspaceHelper.optimizationValueTypeFromGroup(def.group), ...
                    'baseValue', baselineParams.(variableName), ...
                    'optimumValue', optimumParams.(variableName)) ;
            end

            for i = 1:numel(constraints)
                rowDef = constraints(i) ;
                if ~isfield(rowDef, 'use') || ~rowDef.use
                    continue
                end
                rows(end + 1) = struct( ... %#ok<AGROW>
                    'label', ['Constraint: ' DesignWorkspaceHelper.constraintDisplayLabel(rowDef)], ...
                    'valueType', DesignWorkspaceHelper.constraintValueType(rowDef.metric), ...
                    'baseValue', DesignWorkspaceHelper.constraintMetricValue(rowDef.metric, rowDef.speciesIndex, baseline), ...
                    'optimumValue', DesignWorkspaceHelper.constraintMetricValue(rowDef.metric, rowDef.speciesIndex, optimum)) ;
            end
        end

        function row = buildOptimizationObjectiveRow(objective, baseline, optimum)
            componentLabels = DesignWorkspaceHelper.getStructField(baseline, 'componentLabels', {}) ;
            switch char(string(objective))
                case 'Max conversion'
                    label = sprintf('Objective: Conversion of %s', ...
                        DesignWorkspaceHelper.componentLabelFromList(componentLabels, baseline.keyComponentIndex)) ;
                    valueType = 'dimensionless' ;
                    baseValue = DesignWorkspaceHelper.computeConversionValue( ...
                        baseline.C_in, baseline.C_out, baseline.keyComponentIndex) ;
                    optimumValue = DesignWorkspaceHelper.computeConversionValue( ...
                        optimum.C_in, optimum.C_out, optimum.keyComponentIndex) ;
                case 'Max selectivity'
                    label = sprintf('Objective: Selectivity to %s', ...
                        DesignWorkspaceHelper.componentLabelFromList(componentLabels, baseline.desiredProductIndex)) ;
                    valueType = 'dimensionless' ;
                    baseValue = DesignWorkspaceHelper.computeSelectivityValue( ...
                        baseline.C_in, baseline.C_out, baseline.keyComponentIndex, baseline.desiredProductIndex) ;
                    optimumValue = DesignWorkspaceHelper.computeSelectivityValue( ...
                        optimum.C_in, optimum.C_out, optimum.keyComponentIndex, optimum.desiredProductIndex) ;
                case 'Max yield'
                    label = sprintf('Objective: Yield to %s', ...
                        DesignWorkspaceHelper.componentLabelFromList(componentLabels, baseline.desiredProductIndex)) ;
                    valueType = 'dimensionless' ;
                    baseValue = DesignWorkspaceHelper.computeYieldValue( ...
                        baseline.C_in, baseline.C_out, baseline.keyComponentIndex, baseline.desiredProductIndex) ;
                    optimumValue = DesignWorkspaceHelper.computeYieldValue( ...
                        optimum.C_in, optimum.C_out, optimum.keyComponentIndex, optimum.desiredProductIndex) ;
                case 'Max outlet concentration'
                    label = sprintf('Objective: C_out of %s', ...
                        DesignWorkspaceHelper.componentLabelFromList(componentLabels, baseline.desiredProductIndex)) ;
                    valueType = 'concentration' ;
                    baseValue = DesignWorkspaceHelper.computeOutletConcentrationValue( ...
                        baseline.C_out, baseline.desiredProductIndex) ;
                    optimumValue = DesignWorkspaceHelper.computeOutletConcentrationValue( ...
                        optimum.C_out, optimum.desiredProductIndex) ;
                case 'Min outlet concentration'
                    label = sprintf('Objective: C_out of %s', ...
                        DesignWorkspaceHelper.componentLabelFromList(componentLabels, baseline.byproductIndex)) ;
                    valueType = 'concentration' ;
                    baseValue = DesignWorkspaceHelper.computeOutletConcentrationValue( ...
                        baseline.C_out, baseline.byproductIndex) ;
                    optimumValue = DesignWorkspaceHelper.computeOutletConcentrationValue( ...
                        optimum.C_out, optimum.byproductIndex) ;
                otherwise
                    label = 'Objective' ;
                    valueType = 'dimensionless' ;
                    baseValue = NaN ;
                    optimumValue = NaN ;
            end
            row = struct('label', label, 'valueType', valueType, ...
                'baseValue', baseValue, 'optimumValue', optimumValue) ;
        end

        function rows = buildOptimizationModelComparisonRows(RS, baselineModels, optimumModels)
            nComp = numel(baselineModels.cstr.C_in) ;
            reactantIdx = DesignWorkspaceHelper.getFunctionalReactantIndices(RS, baselineModels.cstr.C_in) ;
            rows = struct('label', {}, 'valueType', {}, ...
                'cstrBase', {}, 'cstrOptimum', {}, ...
                'segBase', {}, 'segOptimum', {}, ...
                'mmBase', {}, 'mmOptimum', {}, ...
                'pfrBase', {}, 'pfrOptimum', {}) ;
            for i = 1:nComp
                compLabel = DesignWorkspaceHelper.componentLabel(RS, i) ;
                rows(end + 1) = DesignWorkspaceHelper.buildOptimizationModelRow( ... %#ok<AGROW>
                    sprintf('%s - C_in', compLabel), 'concentration', ...
                    baselineModels.cstr.C_in(i), optimumModels.cstr.C_in(i), ...
                    baselineModels.segregation.C_in(i), optimumModels.segregation.C_in(i), ...
                    baselineModels.maxMixedness.C_in(i), optimumModels.maxMixedness.C_in(i), ...
                    baselineModels.pfr.C_in(i), optimumModels.pfr.C_in(i)) ;
                if any(reactantIdx == i)
                    rows(end + 1) = DesignWorkspaceHelper.buildOptimizationModelRow( ... %#ok<AGROW>
                        sprintf('%s - X', compLabel), 'dimensionless', ...
                        DesignWorkspaceHelper.computeConversionValue(baselineModels.cstr.C_in, baselineModels.cstr.C_out, i), ...
                        DesignWorkspaceHelper.computeConversionValue(optimumModels.cstr.C_in, optimumModels.cstr.C_out, i), ...
                        DesignWorkspaceHelper.computeConversionValue(baselineModels.segregation.C_in, baselineModels.segregation.C_out, i), ...
                        DesignWorkspaceHelper.computeConversionValue(optimumModels.segregation.C_in, optimumModels.segregation.C_out, i), ...
                        DesignWorkspaceHelper.computeConversionValue(baselineModels.maxMixedness.C_in, baselineModels.maxMixedness.C_out, i), ...
                        DesignWorkspaceHelper.computeConversionValue(optimumModels.maxMixedness.C_in, optimumModels.maxMixedness.C_out, i), ...
                        DesignWorkspaceHelper.computeConversionValue(baselineModels.pfr.C_in, baselineModels.pfr.C_out, i), ...
                        DesignWorkspaceHelper.computeConversionValue(optimumModels.pfr.C_in, optimumModels.pfr.C_out, i)) ;
                end
                rows(end + 1) = DesignWorkspaceHelper.buildOptimizationModelRow( ... %#ok<AGROW>
                    sprintf('%s - C_out', compLabel), 'concentration', ...
                    baselineModels.cstr.C_out(i), optimumModels.cstr.C_out(i), ...
                    baselineModels.segregation.C_out(i), optimumModels.segregation.C_out(i), ...
                    baselineModels.maxMixedness.C_out(i), optimumModels.maxMixedness.C_out(i), ...
                    baselineModels.pfr.C_out(i), optimumModels.pfr.C_out(i)) ;
            end
        end

        function row = buildOptimizationModelRow(label, valueType, cstrBase, cstrOptimum, segBase, segOptimum, mmBase, mmOptimum, pfrBase, pfrOptimum)
            row = struct( ...
                'label', label, ...
                'valueType', valueType, ...
                'cstrBase', cstrBase, ...
                'cstrOptimum', cstrOptimum, ...
                'segBase', segBase, ...
                'segOptimum', segOptimum, ...
                'mmBase', mmBase, ...
                'mmOptimum', mmOptimum, ...
                'pfrBase', pfrBase, ...
                'pfrOptimum', pfrOptimum) ;
        end

        function status = evaluateOptimizationConstraintStatus(constraints, scenario)
            status = struct('used', 0, 'satisfied', 0) ;
            for i = 1:numel(constraints)
                row = constraints(i) ;
                if ~isfield(row, 'use') || ~row.use
                    continue
                end
                status.used = status.used + 1 ;
                value = DesignWorkspaceHelper.constraintMetricValue(row.metric, row.speciesIndex, scenario) ;
                if DesignWorkspaceHelper.constraintSatisfied(row.type, value, row.value)
                    status.satisfied = status.satisfied + 1 ;
                end
            end
        end

        function txt = buildOptimizationSummary(rtdSource, reactionMode, objective, baseline, optimum, constraintStatus)
            targetBase = DesignWorkspaceHelper.objectiveMetricValue(objective, baseline) ;
            targetOptimum = DesignWorkspaceHelper.objectiveMetricValue(objective, optimum) ;
            if startsWith(char(string(objective)), 'Max ')
                targetBase = -targetBase ;
                targetOptimum = -targetOptimum ;
            end
            txt = sprintf([ ...
                'Fixed RTD source: %s. Reaction mode: %s. Objective: %s. ' ...
                'Objective value improved from %.6g to %.6g. Active constraints satisfied: %d/%d.'], ...
                rtdSource, reactionMode, objective, targetBase, targetOptimum, ...
                constraintStatus.satisfied, constraintStatus.used) ;
        end

        function label = constraintDisplayLabel(rowDef)
            metric = char(string(rowDef.metric)) ;
            speciesLabel = char(string(DesignWorkspaceHelper.getStructField(rowDef, 'speciesLabel', ''))) ;
            if isempty(speciesLabel)
                speciesLabel = DesignWorkspaceHelper.componentLabel([], rowDef.speciesIndex) ;
            end
            switch metric
                case 'Conversion'
                    label = sprintf('Conversion of %s', speciesLabel) ;
                case 'Selectivity'
                    label = sprintf('Selectivity to %s', speciesLabel) ;
                case 'Yield'
                    label = sprintf('Yield to %s', speciesLabel) ;
                otherwise
                    label = sprintf('C_out of %s', speciesLabel) ;
            end
        end

        function valueType = constraintValueType(metric)
            switch char(string(metric))
                case {'Outlet concentration', 'C_out'}
                    valueType = 'concentration' ;
                otherwise
                    valueType = 'dimensionless' ;
            end
        end

        function valueType = optimizationValueTypeFromGroup(group)
            switch char(string(group))
                case 'concentration'
                    valueType = 'concentration' ;
                otherwise
                    valueType = 'dimensionless' ;
            end
        end

        function suffix = componentLetterSuffix(idx)
            alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' ;
            suffix = '' ;
            idx = round(double(idx)) ;
            if ~isfinite(idx) || idx < 1
                idx = 1 ;
            end
            while idx > 0
                remIdx = mod(idx - 1, numel(alphabet)) + 1 ;
                suffix = [alphabet(remIdx) suffix] ; %#ok<AGROW>
                idx = floor((idx - 1) / numel(alphabet)) ;
            end
        end

        function labels = componentLabels(RS, nComp)
            labels = cell(1, nComp) ;
            for i = 1:nComp
                labels{i} = DesignWorkspaceHelper.componentLabel(RS, i) ;
            end
        end

        function label = componentLabelFromList(labels, idx)
            if isempty(labels) || idx < 1 || idx > numel(labels)
                label = DesignWorkspaceHelper.componentLabel([], idx) ;
                return
            end
            label = labels{idx} ;
        end

        function reactantIdx = getFunctionalReactantIndices(RS, C0)
            reactantIdx = [] ;
            if isempty(RS) || ~isa(RS, 'ReactionSys') || isempty(C0)
                return
            end
            reactantMask = any(RS.stochiometricMatrix < 0, 1) ;
            reactantIdx = find(reactantMask & (C0(:)' > 1e-12)) ;
        end

        function scenarioSlim = slimOptimizationScenario(scenario)
            scenarioSlim = struct() ;
            scenarioSlim.reactionMode = DesignWorkspaceHelper.getStructField(scenario, 'reactionMode', 'Segregation') ;
            scenarioSlim.params = DesignWorkspaceHelper.getStructField(scenario, 'params', struct()) ;
            scenarioSlim.Qv = DesignWorkspaceHelper.getStructField(scenario, 'Qv', NaN) ;
            scenarioSlim.molarFlow = DesignWorkspaceHelper.getStructField(scenario, 'molarFlow', []) ;
            scenarioSlim.C_in = DesignWorkspaceHelper.getStructField(scenario, 'C_in', []) ;
            scenarioSlim.C_out = DesignWorkspaceHelper.getStructField(scenario, 'C_out', []) ;
            scenarioSlim.metrics = DesignWorkspaceHelper.getStructField(scenario, 'metrics', struct()) ;
            scenarioSlim.modelResults = DesignWorkspaceHelper.getStructField(scenario, 'modelResults', struct()) ;
            scenarioSlim.activeModel = DesignWorkspaceHelper.getStructField(scenario, 'activeModel', struct()) ;
            scenarioSlim.activeModelKey = DesignWorkspaceHelper.getStructField(scenario, 'activeModelKey', '') ;
            scenarioSlim.activeModelLabel = DesignWorkspaceHelper.getStructField(scenario, 'activeModelLabel', '') ;
            scenarioSlim.keyComponentIndex = DesignWorkspaceHelper.getStructField(scenario, 'keyComponentIndex', 1) ;
            scenarioSlim.desiredProductIndex = DesignWorkspaceHelper.getStructField(scenario, 'desiredProductIndex', []) ;
            scenarioSlim.byproductIndex = DesignWorkspaceHelper.getStructField(scenario, 'byproductIndex', []) ;
            scenarioSlim.componentLabels = DesignWorkspaceHelper.getStructField(scenario, 'componentLabels', {}) ;
            scenarioSlim.objectiveValue = DesignWorkspaceHelper.getStructField(scenario, 'objectiveValue', NaN) ;
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

        function [x0, lb, ub, names, fixedParams, definitions] = unpackDecisionVariables(decisionVariables, baseFeed)
            x0 = [] ; lb = [] ; ub = [] ; names = {} ; fixedParams = struct() ;
            definitions = decisionVariables ;
            for i = 1:numel(decisionVariables)
                row = decisionVariables(i) ;
                name = char(string(row.variable)) ;
                initialValue = DesignWorkspaceHelper.getStructField(row, 'initialValue', NaN) ;
                if ~(isscalar(initialValue) && isfinite(initialValue))
                    initialValue = DesignWorkspaceHelper.getStructField(row, 'defaultValue', NaN) ;
                end
                if ~(isscalar(initialValue) && isfinite(initialValue)) && nargin >= 2 && isstruct(baseFeed)
                    group = char(string(DesignWorkspaceHelper.getStructField(row, 'group', ''))) ;
                    speciesIdx = DesignWorkspaceHelper.getStructField(row, 'speciesIndex', NaN) ;
                    if strcmp(group, 'concentration') && isfinite(speciesIdx) ...
                            && speciesIdx >= 1 && speciesIdx <= numel(baseFeed.concentration)
                        initialValue = baseFeed.concentration(speciesIdx) ;
                    end
                end
                if ~(isscalar(initialValue) && isfinite(initialValue))
                    error('Decision variable "%s" is missing a valid base value.', name) ;
                end
                lowerBound = DesignWorkspaceHelper.getStructField(row, 'lowerBound', ...
                    DesignWorkspaceHelper.getStructField(row, 'lower', NaN)) ;
                upperBound = DesignWorkspaceHelper.getStructField(row, 'upperBound', ...
                    DesignWorkspaceHelper.getStructField(row, 'upper', NaN)) ;
                if ~(isscalar(lowerBound) && isfinite(lowerBound) && isscalar(upperBound) && isfinite(upperBound))
                    error('Decision variable "%s" requires finite lower/upper bounds.', name) ;
                end
                if isfield(row, 'use') && row.use
                    x0(end+1) = initialValue ; %#ok<AGROW>
                    lb(end+1) = lowerBound ; %#ok<AGROW>
                    ub(end+1) = upperBound ; %#ok<AGROW>
                    names{end+1} = name ; %#ok<AGROW>
                else
                    fixedParams.(name) = initialValue ;
                end
            end
        end

        function params = combineParams(names, x, fixedParams)
            params = fixedParams ;
            for i = 1:numel(names)
                params.(names{i}) = x(i) ;
            end
        end

        function f = optimizationPenaltyObjective(x, lb, ub, names, fixedParams, definitions, basisMode, constraints, objective, optSpec, RS, rtdObj, baseFeed)
            penalty = 1e5 * sum(max(lb - x, 0).^2 + max(x - ub, 0).^2) ;
            xClamped = min(max(x, lb), ub) ;
            params = DesignWorkspaceHelper.combineParams(names, xClamped, fixedParams) ;
            try
                scenario = DesignWorkspaceHelper.evaluateProcessScenario(struct( ...
                    'rtd', rtdObj, ...
                    'reactionMode', DesignWorkspaceHelper.getStructField(optSpec, 'reactionMode', 'Segregation'), ...
                    'objective', objective, ...
                    'computeFullModelSet', false, ...
                    'RS', RS, ...
                    'baseFeed', baseFeed, ...
                    'keyComponentIndex', DesignWorkspaceHelper.getStructField(optSpec, 'keyComponentIndex', 1), ...
                    'desiredProductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'desiredProductIndex', []), ...
                    'byproductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'byproductIndex', []), ...
                    'params', params, ...
                    'decisionDefinitions', definitions, ...
                    'basisMode', basisMode)) ;

                metricValue = DesignWorkspaceHelper.objectiveMetricValue(objective, scenario) ;
                penalty = penalty + DesignWorkspaceHelper.constraintPenalty(constraints, scenario) ;
                f = metricValue + penalty ;
            catch
                f = 1e9 + penalty ;
            end
        end

        function value = objectiveMetricValue(objective, scenario)
            switch char(string(objective))
                case 'Max conversion'
                    value = -DesignWorkspaceHelper.computeConversionValue( ...
                        scenario.C_in, scenario.C_out, scenario.keyComponentIndex) ;
                case 'Max selectivity'
                    value = -DesignWorkspaceHelper.safeMetric(DesignWorkspaceHelper.computeSelectivityValue( ...
                        scenario.C_in, scenario.C_out, scenario.keyComponentIndex, scenario.desiredProductIndex)) ;
                case 'Max yield'
                    value = -DesignWorkspaceHelper.safeMetric(DesignWorkspaceHelper.computeYieldValue( ...
                        scenario.C_in, scenario.C_out, scenario.keyComponentIndex, scenario.desiredProductIndex)) ;
                case 'Max outlet concentration'
                    value = -DesignWorkspaceHelper.computeOutletConcentrationValue( ...
                        scenario.C_out, scenario.desiredProductIndex) ;
                case 'Min outlet concentration'
                    value = DesignWorkspaceHelper.computeOutletConcentrationValue( ...
                        scenario.C_out, scenario.byproductIndex) ;
                otherwise
                    value = -DesignWorkspaceHelper.computeConversionValue( ...
                        scenario.C_in, scenario.C_out, scenario.keyComponentIndex) ;
            end
        end

        function penalty = constraintPenalty(constraints, scenario)
            penalty = 0 ;
            for i = 1:numel(constraints)
                row = constraints(i) ;
                if ~isfield(row, 'use') || ~row.use
                    continue
                end
                value = DesignWorkspaceHelper.constraintMetricValue(row.metric, row.speciesIndex, scenario) ;
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
            for i = 1:numel(constraints)
                row = constraints(i) ;
                if ~isfield(row, 'use') || ~row.use
                    continue
                end
                value = DesignWorkspaceHelper.constraintMetricValue(row.metric, row.speciesIndex, scenario) ;
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

        function value = constraintMetricValue(metric, speciesIndex, scenario)
            switch char(string(metric))
                case 'Conversion'
                    value = DesignWorkspaceHelper.computeConversionValue( ...
                        scenario.C_in, scenario.C_out, speciesIndex) ;
                case 'Selectivity'
                    value = DesignWorkspaceHelper.safeMetric(DesignWorkspaceHelper.computeSelectivityValue( ...
                        scenario.C_in, scenario.C_out, scenario.keyComponentIndex, speciesIndex)) ;
                case 'Yield'
                    value = DesignWorkspaceHelper.safeMetric(DesignWorkspaceHelper.computeYieldValue( ...
                        scenario.C_in, scenario.C_out, scenario.keyComponentIndex, speciesIndex)) ;
                case {'C_out', 'Outlet concentration'}
                    value = DesignWorkspaceHelper.computeOutletConcentrationValue( ...
                        scenario.C_out, speciesIndex) ;
                otherwise
                    value = NaN ;
            end
        end

        function tableData = computeSensitivity(names, optimumParams, optSpec, RS, rtdObj, baseFeed, objective, definitions, basisMode)
            tableData = cell(numel(names), 3) ;
            for i = 1:numel(names)
                pMinus = optimumParams ;
                pPlus = optimumParams ;
                baseValue = max(abs(optimumParams.(names{i})), 1e-6) ;
                pMinus.(names{i}) = max(1e-8, optimumParams.(names{i}) * 0.9) ;
                pPlus.(names{i}) = optimumParams.(names{i}) * 1.1 ;

                scMinus = DesignWorkspaceHelper.evaluateProcessScenario(struct( ...
                    'rtd', rtdObj, ...
                    'reactionMode', DesignWorkspaceHelper.getStructField(optSpec, 'reactionMode', 'Segregation'), ...
                    'RS', RS, ...
                    'baseFeed', baseFeed, ...
                    'keyComponentIndex', DesignWorkspaceHelper.getStructField(optSpec, 'keyComponentIndex', 1), ...
                    'desiredProductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'desiredProductIndex', []), ...
                    'byproductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'byproductIndex', []), ...
                    'params', pMinus, ...
                    'decisionDefinitions', definitions, ...
                    'basisMode', basisMode)) ;
                scPlus = DesignWorkspaceHelper.evaluateProcessScenario(struct( ...
                    'rtd', rtdObj, ...
                    'reactionMode', DesignWorkspaceHelper.getStructField(optSpec, 'reactionMode', 'Segregation'), ...
                    'RS', RS, ...
                    'baseFeed', baseFeed, ...
                    'keyComponentIndex', DesignWorkspaceHelper.getStructField(optSpec, 'keyComponentIndex', 1), ...
                    'desiredProductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'desiredProductIndex', []), ...
                    'byproductIndex', DesignWorkspaceHelper.getStructField(optSpec, 'byproductIndex', []), ...
                    'params', pPlus, ...
                    'decisionDefinitions', definitions, ...
                    'basisMode', basisMode)) ;

                objMinus = DesignWorkspaceHelper.objectiveMetricValue(objective, scMinus) ;
                objPlus = DesignWorkspaceHelper.objectiveMetricValue(objective, scPlus) ;
                slope = (objPlus - objMinus) / (0.2 * baseValue) ;
                tableData{i, 1} = names{i} ;
                tableData{i, 2} = DesignWorkspaceHelper.formatNumber(baseValue) ;
                tableData{i, 3} = DesignWorkspaceHelper.formatNumber(slope) ;
            end
        end

        function basisMode = resolveOptimizationBasis(~)
            basisMode = 'concentration' ;
        end

        function feedState = extractOptimizationFeedState(feedStream)
            if ~isa(feedStream, 'Stream')
                error('Optimization requires a valid Stream object.') ;
            end
            Qv = feedStream.volumetricFlow ;
            molarFlow = DesignWorkspaceHelper.ensureRowVector(feedStream.molarFlow) ;
            concentration = DesignWorkspaceHelper.ensureRowVector(feedStream.concentration) ;
            if isempty(Qv) || ~isscalar(Qv) || ~isfinite(Qv) || Qv <= 0
                error('Feed Stream must define a positive volumetric flow for process optimization.') ;
            end
            if isempty(molarFlow) || isempty(concentration)
                error('Feed Stream must define molar flow and concentration consistently.') ;
            end
            if numel(molarFlow) ~= numel(concentration)
                error('Feed Stream molar flow and concentration sizes are inconsistent.') ;
            end
            if any(~isfinite(molarFlow)) || any(~isfinite(concentration))
                error('Feed Stream contains non-finite molar-flow or concentration values.') ;
            end
            feedState = struct() ;
            feedState.stream = feedStream ;
            feedState.Qv = double(Qv) ;
            feedState.molarFlow = double(molarFlow(:)).' ;
            feedState.concentration = double(concentration(:)).' ;
        end

        function feedState = reconstructOptimizationFeed(baseFeed, params, decisionDefinitions, ~)
            streamCopy = baseFeed.stream ;
            concentration = baseFeed.concentration ;
            for i = 1:numel(decisionDefinitions)
                row = decisionDefinitions(i) ;
                if ~strcmp(char(string(DesignWorkspaceHelper.getStructField(row, 'group', ''))), 'concentration')
                    continue
                end
                idx = DesignWorkspaceHelper.getStructField(row, 'speciesIndex', NaN) ;
                if ~isfinite(idx) || idx < 1 || idx > numel(baseFeed.concentration)
                    continue
                end
                concentration(idx) = DesignWorkspaceHelper.getStructField(params, row.variable, baseFeed.concentration(idx)) ;
            end
            if any(~isfinite(concentration)) || any(concentration < 0)
                error('All inlet concentrations must be finite and non-negative.') ;
            end
            streamCopy.molarFlow = [] ;
            streamCopy.concentration = concentration ;
            feedState = struct() ;
            feedState.stream = streamCopy ;
            feedState.Qv = double(streamCopy.volumetricFlow) ;
            feedState.molarFlow = DesignWorkspaceHelper.ensureRowVector(streamCopy.molarFlow) ;
            feedState.concentration = DesignWorkspaceHelper.ensureRowVector(streamCopy.concentration) ;
        end

        function xOpt = penalizedFminsearch(objFun, x0, lb, ub)
            x0 = DesignWorkspaceHelper.ensureRowVector(x0) ;
            lb = DesignWorkspaceHelper.ensureRowVector(lb) ;
            ub = DesignWorkspaceHelper.ensureRowVector(ub) ;
            maxIter = max(80, 30 * numel(x0)) ;
            maxFun = max(160, 60 * numel(x0)) ;
            maxTimeSeconds = 20 ;
            startTime = tic ;
            options = optimset( ...
                'Display', 'off', ...
                'MaxIter', maxIter, ...
                'MaxFunEvals', maxFun, ...
                'TolX', 1e-4, ...
                'TolFun', 1e-5, ...
                'OutputFcn', @(x, optimValues, state) ...
                    DesignWorkspaceHelper.stopOptimizationSearch(startTime, maxTimeSeconds, x, optimValues, state)) ;
            wrapped = @(x) objFun(min(max(x, lb), ub)) + 1e4 * sum(max(lb - x, 0).^2 + max(x - ub, 0).^2) ;
            xOpt = fminsearch(wrapped, x0, options) ;
            xOpt = min(max(xOpt, lb), ub) ;
        end

        function stop = stopOptimizationSearch(startTime, maxTimeSeconds, ~, ~, ~)
            stop = toc(startTime) >= maxTimeSeconds ;
        end

        function value = safeMetric(value)
            if isempty(value) || ~isfinite(value)
                value = 0 ;
            end
        end

        function label = componentLabel(RS, idx)
            label = ['C' DesignWorkspaceHelper.componentLetterSuffix(idx)] ;
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

        function [C_out, modeInfo] = solveFixedRTDPass(rtdObj, reactionMode, RS, C0, keyIdx)
            modeInfo = struct('directFirstOrder', false, 'kFirstOrder', NaN) ;
            switch char(string(reactionMode))
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

        function family = normalizeFitFamilyName(family)
            family = char(string(family)) ;
            switch family
                case 'PFR + CSTR'
                    family = 'PFR + CSTR (series, dead volume)' ;
                case 'CSTR + Dead Volume'
                    family = 'CSTR (dead volume)' ;
                case 'CSTR + Bypass'
                    family = 'CSTR + Bypass (dead volume)' ;
                case 'CSTR + Dead Volume + Bypass'
                    family = 'CSTR + Bypass (dead volume)' ;
            end
        end

        function [lb, ub] = getFitConstraintBounds(fitConstraints, variableName, defaultLb, defaultUb)
            lb = defaultLb ;
            ub = defaultUb ;
            if isempty(fitConstraints)
                return
            end
            for i = 1:numel(fitConstraints)
                row = fitConstraints(i) ;
                if strcmp(char(string(DesignWorkspaceHelper.getStructField(row, 'variable', ''))), variableName)
                    lb = DesignWorkspaceHelper.getStructField(row, 'lowerBound', defaultLb) ;
                    ub = DesignWorkspaceHelper.getStructField(row, 'upperBound', defaultUb) ;
                    return
                end
            end
        end

        function [lbTauCstr, ubTauCstr] = deriveSeriesTauCstrBounds(fitConstraints, tauActive)
            baseLb = 1e-6 ;
            baseUb = 0.999 * tauActive ;
            [lbTauCstr, ubTauCstr] = DesignWorkspaceHelper.getFitConstraintBounds( ...
                fitConstraints, 'tau_cstr_active', baseLb, baseUb) ;
            [lbTauPfr, ubTauPfr] = DesignWorkspaceHelper.getFitConstraintBounds( ...
                fitConstraints, 'tau_pfr_active', 1e-6, max(tauActive - baseLb, 1e-6)) ;
            lbTauCstr = max(lbTauCstr, tauActive - ubTauPfr) ;
            ubTauCstr = min(ubTauCstr, tauActive - lbTauPfr) ;
            lbTauCstr = max(lbTauCstr, baseLb) ;
            ubTauCstr = min(ubTauCstr, baseUb) ;
            if ~(isfinite(lbTauCstr) && isfinite(ubTauCstr) && lbTauCstr < ubTauCstr)
                error(['The bounds selected for tau_pfr_active and tau_cstr_active are incompatible ' ...
                    'with tau_active fixed by the input RTD.']) ;
            end
        end

        function tauTotal = resolveNominalTau(referenceTau, totalVolume, flowRate)
            tauTotal = [] ;
            if ~isempty(totalVolume) && isscalar(totalVolume) && isfinite(totalVolume) && totalVolume > 0 && ...
                    ~isempty(flowRate) && isscalar(flowRate) && isfinite(flowRate) && flowRate > 0
                tauTotal = totalVolume / flowRate ;
                return
            end
            if ~isempty(referenceTau) && isscalar(referenceTau) && isfinite(referenceTau) && referenceTau > 0
                tauTotal = referenceTau ;
            end
        end

        function params = appendDeadVolumeParameters(params, tauActive, referenceTau, totalVolume, flowRate)
            tauTotal = DesignWorkspaceHelper.resolveNominalTau(referenceTau, totalVolume, flowRate) ;
            if isempty(tauTotal) || ~isfinite(tauTotal) || tauTotal <= 0
                return
            end

            params.tau_total = tauTotal ;
            if tauTotal + 1e-12 < tauActive
                params.deadVolumeNote = 'Inconsistent dead-volume inputs: tau_total < tau_active.' ;
                return
            end

            activeFraction = min(max(tauActive / tauTotal, 0), 1) ;
            params.activeFraction = activeFraction ;
            params.deadFraction = max(0, 1 - activeFraction) ;
            if ~isempty(totalVolume) && isscalar(totalVolume) && isfinite(totalVolume) && totalVolume > 0
                params.V_total = totalVolume ;
                params.V_active = activeFraction * totalVolume ;
                params.V_dead = params.deadFraction * totalVolume ;
            end
        end

        function rtdObj = buildParallelPfrCstrRTD(splitToPfr, tauPfr, tauCstr, tspan)
            splitToPfr = min(max(splitToPfr, 0), 1) ;
            tauPfr = max(tauPfr, 1e-8) ;
            tauCstr = max(tauCstr, 1e-8) ;
            pfrObj = RTD.ideal_pfr(tauPfr, tspan) ;
            cstrObj = RTD.ideal_cstr(tauCstr, tspan) ;
            Et = splitToPfr * pfrObj.Et + (1 - splitToPfr) * cstrObj.Et ;
            rtdObj = RTD(tspan, Et) ;
            rtdObj.source = 'custom' ;
        end

        function tf = familyNeedsReferenceTau(family)
            family = char(string(family)) ;
            tf = false ;
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
