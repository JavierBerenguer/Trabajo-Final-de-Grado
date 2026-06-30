classdef DesignTemplateHelper
% DesignTemplateHelper - Autonomous design-template solver backend.
%
% V1 focuses on educational non-ideal templates. The first implemented
% template is Exercise 56: an equivalent CSTR with dead volume.

    methods (Static)

        function labels = getTemplateLabels()
            labels = {'CSTR + Dead Volume (Ex. 56)'} ;
        end

        function templateId = defaultTemplateId()
            templateId = 'cstr_dead_volume_ex56' ;
        end

        function templateId = templateIdFromLabel(label)
            switch char(string(label))
                case 'CSTR + Dead Volume (Ex. 56)'
                    templateId = 'cstr_dead_volume_ex56' ;
                otherwise
                    error('Unknown design template label: %s', char(string(label))) ;
            end
        end

        function label = labelFromTemplateId(templateId)
            switch char(string(templateId))
                case 'cstr_dead_volume_ex56'
                    label = 'CSTR + Dead Volume (Ex. 56)' ;
                otherwise
                    error('Unknown design template id: %s', char(string(templateId))) ;
            end
        end

        function description = getTemplateDescription(templateId)
            switch char(string(templateId))
                case 'cstr_dead_volume_ex56'
                    description = ['Continuous stirred tank reactor with dead volume. ' ...
                        'This autonomous template reconstructs Exercise 56 and compares ' ...
                        'the current reactor with the fully mixed case and its macrofluid interpretation.'] ;
                otherwise
                    error('Unknown design template id: %s', char(string(templateId))) ;
            end
        end

        function note = getTemplateNote(templateId)
            switch char(string(templateId))
                case 'cstr_dead_volume_ex56'
                    note = ['This template is autonomous and does not require ' ...
                        'ReactionSys or Feed Stream objects.'] ;
                otherwise
                    error('Unknown design template id: %s', char(string(templateId))) ;
            end
        end

        function defaults = defaultTemplateInputs(templateId)
            switch char(string(templateId))
                case 'cstr_dead_volume_ex56'
                    defaults = struct( ...
                        'V_total', 6.0, ...
                        'V_dead', 4.0, ...
                        'X_observed', 0.75) ;
                otherwise
                    error('Unknown design template id: %s', char(string(templateId))) ;
            end
        end

        function templateSpec = buildTemplateSpec(templateId, uiState)
            if nargin < 2 || ~isstruct(uiState)
                error('A struct uiState is required to build the template specification.') ;
            end

            templateSpec = struct() ;
            templateSpec.templateId = char(string(templateId)) ;
            templateSpec.V_total = uiState.V_total ;
            templateSpec.V_dead = uiState.V_dead ;
            templateSpec.X_observed = uiState.X_observed ;
        end

        function result = solveTemplate(templateSpec)
            templateId = char(string(templateSpec.templateId)) ;

            switch templateId
                case 'cstr_dead_volume_ex56'
                    result = DesignTemplateHelper.solveCSTRDeadVolumeEx56(templateSpec) ;
                otherwise
                    error('Unknown design template id: %s', templateId) ;
            end
        end

        function tableData = buildSummaryTable(result)
            tableData = { ...
                'Current reactor', 'Observed / active CSTR', ...
                DesignTemplateHelper.formatNumber(result.V_active), ...
                DesignTemplateHelper.formatNumber(result.X_current_cstr) ; ...
                'Current reactor', 'Macrofluid (Segregation)', ...
                DesignTemplateHelper.formatNumber(result.V_active), ...
                DesignTemplateHelper.formatNumber(result.X_current_macrofluid) ; ...
                'Improved mixing', 'Ideal CSTR, full volume', ...
                DesignTemplateHelper.formatNumber(result.V_total), ...
                DesignTemplateHelper.formatNumber(result.X_fullmix_cstr) ; ...
                'Improved mixing', 'Macrofluid (Segregation)', ...
                DesignTemplateHelper.formatNumber(result.V_total), ...
                DesignTemplateHelper.formatNumber(result.X_fullmix_macrofluid)} ;
        end

    end

    methods (Static, Access = private)

        function result = solveCSTRDeadVolumeEx56(templateSpec)
            V_total = templateSpec.V_total ;
            V_dead = templateSpec.V_dead ;
            X_observed = templateSpec.X_observed ;

            DesignTemplateHelper.validatePositiveScalar(V_total, ...
                'Total reactor volume must be a positive scalar.') ;
            DesignTemplateHelper.validatePositiveScalar(V_dead, ...
                'Dead volume must be a positive scalar.') ;
            DesignTemplateHelper.validatePositiveScalar(X_observed, ...
                'Observed conversion must be a positive scalar.') ;

            if V_dead >= V_total
                error('Dead volume must be smaller than the total reactor volume.') ;
            end
            if X_observed >= 1
                error('Observed conversion must be strictly smaller than 1.') ;
            end

            V_active = V_total - V_dead ;
            active_fraction = V_active / V_total ;
            dead_fraction = V_dead / V_total ;
            k_tau_active = X_observed / (1 - X_observed) ;
            k_tau_full = k_tau_active * (V_total / V_active) ;

            X_current_cstr = X_observed ;
            X_fullmix_cstr = k_tau_full / (1 + k_tau_full) ;
            X_current_macrofluid = DesignTemplateHelper.computeMacrofluidConversion(k_tau_active) ;
            X_fullmix_macrofluid = DesignTemplateHelper.computeMacrofluidConversion(k_tau_full) ;

            workedSteps = { ...
                'Exercise 56 solved with the equivalent template CSTR + Dead Volume.', ...
                '', ...
                sprintf('1. Active reactor volume: V_active = V_total - V_dead = %s - %s = %s m^3.', ...
                    DesignTemplateHelper.formatNumber(V_total), ...
                    DesignTemplateHelper.formatNumber(V_dead), ...
                    DesignTemplateHelper.formatNumber(V_active)), ...
                sprintf('2. Active and dead fractions: alpha_active = V_active / V_total = %s, dead fraction = %s.', ...
                    DesignTemplateHelper.formatNumber(active_fraction), ...
                    DesignTemplateHelper.formatNumber(dead_fraction)), ...
                sprintf('3. Current reactor behaves like an active CSTR. From X = k*tau / (1 + k*tau) and X_observed = %s,', ...
                    DesignTemplateHelper.formatNumber(X_observed)), ...
                sprintf('   we obtain k*tau_active = X / (1 - X) = %s.', ...
                    DesignTemplateHelper.formatNumber(k_tau_active)), ...
                sprintf('4. If a high-powered stirrer activates the whole volume, k*tau scales with V_total / V_active = %s.', ...
                    DesignTemplateHelper.formatNumber(V_total / V_active)), ...
                sprintf('   Therefore k*tau_full = %s and the improved ideal CSTR conversion is X = %s.', ...
                    DesignTemplateHelper.formatNumber(k_tau_full), ...
                    DesignTemplateHelper.formatNumber(X_fullmix_cstr)), ...
                '5. Macrofluid case is evaluated internally with SegregationModel using an ideal CSTR RTD.', ...
                '   For this first-order problem, the segregation result coincides with the ideal CSTR result for these equivalent cases.', ...
                sprintf('   Hence X_current_macrofluid = %s and X_fullmix_macrofluid = %s.', ...
                    DesignTemplateHelper.formatNumber(X_current_macrofluid), ...
                    DesignTemplateHelper.formatNumber(X_fullmix_macrofluid)), ...
                '', ...
                sprintf('Final answer: current reactor X = %s, improved mixing X = %s, macrofluid current X = %s, macrofluid improved X = %s.', ...
                    DesignTemplateHelper.formatNumber(X_current_cstr), ...
                    DesignTemplateHelper.formatNumber(X_fullmix_cstr), ...
                    DesignTemplateHelper.formatNumber(X_current_macrofluid), ...
                    DesignTemplateHelper.formatNumber(X_fullmix_macrofluid))} ;

            result = struct() ;
            result.templateId = templateSpec.templateId ;
            result.templateLabel = DesignTemplateHelper.labelFromTemplateId(templateSpec.templateId) ;
            result.V_total = V_total ;
            result.V_dead = V_dead ;
            result.V_active = V_active ;
            result.active_fraction = active_fraction ;
            result.dead_fraction = dead_fraction ;
            result.k_tau_active = k_tau_active ;
            result.k_tau_full = k_tau_full ;
            result.X_current_cstr = X_current_cstr ;
            result.X_fullmix_cstr = X_fullmix_cstr ;
            result.X_current_macrofluid = X_current_macrofluid ;
            result.X_fullmix_macrofluid = X_fullmix_macrofluid ;
            result.summaryTable = DesignTemplateHelper.buildSummaryTable(result) ;
            result.workedSteps = workedSteps ;
        end

        function X = computeMacrofluidConversion(kTau)
            rtd = RTD.ideal_cstr(kTau) ;
            RS = DesignTemplateHelper.buildFirstOrderReactionSystem() ;
            seg = SegregationModel(rtd) ;
            seg = seg.compute_isothermal(RS, [1 0]) ;

            X_formula = kTau / (1 + kTau) ;
            if abs(seg.X_mean - X_formula) < 1e-4
                X = X_formula ;
            else
                X = seg.X_mean ;
            end
        end

        function RS = buildFirstOrderReactionSystem()
            RS = ReactionSys() ;
            RS.componentNames = {'A', 'R'} ;
            RS.componentFormula = {'A', 'R'} ;
            RS.stochiometricMatrix = [-1 1] ;
            RS.k0 = 1 ;
            RS.Ea = 0 ;
            RS.componentCp = [1 1] ;
        end

        function validatePositiveScalar(value, messageText)
            if ~isscalar(value) || ~isfinite(value) || value <= 0
                error(messageText) ;
            end
        end

        function txt = formatNumber(value)
            txt = sprintf('%.6g', value) ;
        end

    end
end
