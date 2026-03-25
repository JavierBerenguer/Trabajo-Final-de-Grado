classdef NonIdealReactorApp < handle
% NonIdealReactorApp - GUI for non-ideal reactor analysis
% This app provides tools for RTD analysis, conversion prediction using
% segregation and maximum mixedness models, tanks-in-series, dispersion,
% convolution/deconvolution, and combined reactor models.
%
% Launch: app = NonIdealReactorApp ;
%
% =========================================================================
% Javier Berenguer Sabater
% Created: March 21, 2026. Last update: March 22, 2026
% =========================================================================

    properties (Access = private)
        % Main UI
        UIFigure
        TabGroup

        % Shared state
        rtd                 % Current RTD object (shared across tabs)

        % ---- Tab 1: RTD Analysis ----
        RTDTab
        RTD_SourceDropdown
        RTD_TauField
        RTD_NField
        RTD_NLabel
        RTD_BoField
        RTD_BoLabel
        RTD_BoundaryDropdown
        RTD_BoundaryLabel
        RTD_ExpTVarField
        RTD_ExpTVarLabel
        RTD_ExpCVarField
        RTD_ExpCVarLabel
        RTD_ExpC0Field
        RTD_ExpC0Label
        RTD_ImportButton
        RTD_ImportLabel
        RTD_EqLabel
        RTD_EqField
        RTD_EqTStartLabel
        RTD_EqTStartField
        RTD_EqTEndLabel
        RTD_EqTEndField
        RTD_EqNptsLabel
        RTD_EqNptsField
        RTD_GenerateButton
        RTD_ExportButton
        RTD_ExportNameField
        RTD_ExportCounter = 1    % Auto-increment counter for export names
        RTD_QvLabel
        RTD_QvField
        RTD_ResultTau
        RTD_ResultSigma2
        RTD_ResultSigma2Theta
        RTD_ResultS3
        RTD_ResultN
        RTD_ResultVeff
        RTD_AxesEt
        RTD_AxesFt
        RTD_AxesEtheta

        % ---- Tab 2: Prediction Models ----
        PredTab
        Pred_RTDStatusLabel
        Pred_KineticsDropdown
        Pred_kField
        Pred_kLabel
        Pred_CA0Field
        Pred_CA0Label
        Pred_ComputeButton
        Pred_ResultSegLabel
        Pred_ResultMMLabel
        Pred_ResultBoundsLabel
        Pred_AxesXbatch
        Pred_AxesIntegrand
        Pred_AxesXlambda
        Pred_AxesComparison

        % Stored model objects
        seg_model               % SegregationModel object
        mm_model                % MaxMixednessModel object

        % ---- Tab 3: Tanks-in-Series ----
        TISTab
        TIS_NMethodDropdown
        TIS_NField
        TIS_NLabel
        TIS_RTDStatusLabel
        TIS_tauField
        TIS_tauLabel
        TIS_kField
        TIS_kLabel
        TIS_CA0Field
        TIS_CA0Label
        TIS_KineticsDropdown
        TIS_ComputeButton
        TIS_ResultXtis
        TIS_ResultXcstr
        TIS_ResultXpfr
        TIS_ResultNused
        TIS_AxesEt
        TIS_AxesXvsN
        TIS_AxesComparison

        % ---- Tab 4: Dispersion Model ----
        DispTab
        Disp_InputMethodDropdown
        Disp_RTDStatusLabel
        Disp_BoField
        Disp_BoLabel
        Disp_PeLabel
        Disp_BCDropdown
        Disp_BCLabel
        Disp_tauField
        Disp_tauLabel
        Disp_KineticsDropdown
        Disp_KineticsLabel
        Disp_kField
        Disp_kLabel
        Disp_CA0Field
        Disp_CA0Label
        Disp_ComputeButton
        Disp_ResultX
        Disp_ResultXcstr
        Disp_ResultXpfr
        Disp_ResultBo
        Disp_AxesEt
        Disp_AxesXvsBo
        Disp_AxesComparison

        % Stored dispersion model
        disp_reactor            % DispersionReactor object
    end

    methods (Access = public)

        %% ============== CONSTRUCTOR ==============
        function app = NonIdealReactorApp()

            % Create main figure
            app.UIFigure = uifigure('Name', 'Non-Ideal Reactor Analysis', ...
                'Position', [100 100 1200 750], ...
                'Resize', 'on') ;

            % Create tab group
            app.TabGroup = uitabgroup(app.UIFigure, ...
                'Position', [0 0 1200 750]) ;

            % Build tabs
            app.createRTDTab() ;
            app.createPredictionTab() ;
            app.createTISTab() ;
            app.createDispersionTab() ;

            % Show figure
            app.UIFigure.Visible = 'on' ;
        end

    end

    methods (Access = private)

        %% ============== TAB 1: RTD ANALYSIS ==============
        function createRTDTab(app)

            app.RTDTab = uitab(app.TabGroup, 'Title', 'RTD Analysis') ;

            % Main grid: left panel (controls) + right panel (plots)
            mainGrid = uigridlayout(app.RTDTab, [1 2]) ;
            mainGrid.ColumnWidth = {320, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'RTD Configuration') ;
            leftGrid = uigridlayout(leftPanel, [20 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 20) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: RTD Source dropdown
            lbl = uilabel(leftGrid, 'Text', 'RTD Source:', ...
                'FontWeight', 'bold') ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = 1 ;
            app.RTD_SourceDropdown = uidropdown(leftGrid, ...
                'Items', {'Ideal CSTR', 'Ideal PFR', 'Tanks-in-Series', ...
                          'Dispersion (open)', 'Dispersion (closed)', ...
                          'Experimental Pulse', 'Experimental Step', ...
                          'C(t) Equation'}, ...
                'Value', 'Ideal CSTR', ...
                'ValueChangedFcn', @(~,~) app.RTD_sourceChanged()) ;
            app.RTD_SourceDropdown.Layout.Row = 1 ;
            app.RTD_SourceDropdown.Layout.Column = 2 ;

            % Row 2: Tau field
            lbl = uilabel(leftGrid, 'Text', 'tau (s):') ;
            lbl.Layout.Row = 2 ; lbl.Layout.Column = 1 ;
            app.RTD_TauField = uieditfield(leftGrid, 'numeric', ...
                'Value', 10, 'Limits', [0.001 Inf]) ;
            app.RTD_TauField.Layout.Row = 2 ;
            app.RTD_TauField.Layout.Column = 2 ;

            % Row 3: Qv (volumetric flow rate) — always visible
            app.RTD_QvLabel = uilabel(leftGrid, 'Text', 'Qv (m^3/s):') ;
            app.RTD_QvLabel.Layout.Row = 3 ; app.RTD_QvLabel.Layout.Column = 1 ;
            app.RTD_QvField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.001, 'Limits', [1e-12 Inf]) ;
            app.RTD_QvField.Layout.Row = 3 ; app.RTD_QvField.Layout.Column = 2 ;

            % Row 4: N field (for Tanks-in-Series) — shares row with Bo
            app.RTD_NLabel = uilabel(leftGrid, 'Text', 'N (tanks):') ;
            app.RTD_NLabel.Layout.Row = 4 ; app.RTD_NLabel.Layout.Column = 1 ;
            app.RTD_NField = uieditfield(leftGrid, 'numeric', ...
                'Value', 3, 'Limits', [0.1 Inf]) ;
            app.RTD_NField.Layout.Row = 4 ; app.RTD_NField.Layout.Column = 2 ;
            app.RTD_NLabel.Visible = 'off' ;
            app.RTD_NField.Visible = 'off' ;

            % Row 4: Bo field (for Dispersion) — overlaps with N (only one visible)
            app.RTD_BoLabel = uilabel(leftGrid, 'Text', 'Bo (De/uL):') ;
            app.RTD_BoLabel.Layout.Row = 4 ; app.RTD_BoLabel.Layout.Column = 1 ;
            app.RTD_BoField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.01, 'Limits', [1e-6 Inf]) ;
            app.RTD_BoField.Layout.Row = 4 ; app.RTD_BoField.Layout.Column = 2 ;
            app.RTD_BoLabel.Visible = 'off' ;
            app.RTD_BoField.Visible = 'off' ;

            % Row 5: Experimental t variable
            app.RTD_ExpTVarLabel = uilabel(leftGrid, 'Text', 't variable (workspace):') ;
            app.RTD_ExpTVarLabel.Layout.Row = 5 ; app.RTD_ExpTVarLabel.Layout.Column = 1 ;
            app.RTD_ExpTVarField = uieditfield(leftGrid, 'text', ...
                'Value', 't_exp') ;
            app.RTD_ExpTVarField.Layout.Row = 5 ; app.RTD_ExpTVarField.Layout.Column = 2 ;
            app.RTD_ExpTVarLabel.Visible = 'off' ;
            app.RTD_ExpTVarField.Visible = 'off' ;

            % Row 6: Experimental C variable
            app.RTD_ExpCVarLabel = uilabel(leftGrid, 'Text', 'C variable (workspace):') ;
            app.RTD_ExpCVarLabel.Layout.Row = 6 ; app.RTD_ExpCVarLabel.Layout.Column = 1 ;
            app.RTD_ExpCVarField = uieditfield(leftGrid, 'text', ...
                'Value', 'C_exp') ;
            app.RTD_ExpCVarField.Layout.Row = 6 ; app.RTD_ExpCVarField.Layout.Column = 2 ;
            app.RTD_ExpCVarLabel.Visible = 'off' ;
            app.RTD_ExpCVarField.Visible = 'off' ;

            % Row 7: C0 (step only)
            app.RTD_ExpC0Label = uilabel(leftGrid, 'Text', 'C0 (step only):') ;
            app.RTD_ExpC0Label.Layout.Row = 7 ; app.RTD_ExpC0Label.Layout.Column = 1 ;
            app.RTD_ExpC0Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 1, 'Limits', [0 Inf]) ;
            app.RTD_ExpC0Field.Layout.Row = 7 ; app.RTD_ExpC0Field.Layout.Column = 2 ;
            app.RTD_ExpC0Label.Visible = 'off' ;
            app.RTD_ExpC0Field.Visible = 'off' ;

            % Row 8: Import from file button (for experimental data)
            app.RTD_ImportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Import experimental data', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [1 1 1], ...
                'FontColor', [0.8 0 0], ...
                'ButtonPushedFcn', @(~,~) app.RTD_importFromFile()) ;
            app.RTD_ImportButton.Layout.Row = 8 ;
            app.RTD_ImportButton.Layout.Column = [1 2] ;
            app.RTD_ImportButton.Visible = 'off' ;

            % Row 9: Import status label
            app.RTD_ImportLabel = uilabel(leftGrid, 'Text', '') ;
            app.RTD_ImportLabel.Layout.Row = 9 ;
            app.RTD_ImportLabel.Layout.Column = [1 2] ;
            app.RTD_ImportLabel.FontColor = [0 0.5 0] ;
            app.RTD_ImportLabel.Visible = 'off' ;

            % Rows 4-7: Custom equation fields (for C(t) Equation)
            % These share rows with N/Bo and Exp fields (never visible at same time)
            app.RTD_EqLabel = uilabel(leftGrid, 'Text', 'C(t) =') ;
            app.RTD_EqLabel.Layout.Row = 4 ; app.RTD_EqLabel.Layout.Column = 1 ;
            app.RTD_EqLabel.FontWeight = 'bold' ;
            app.RTD_EqLabel.Visible = 'off' ;

            app.RTD_EqField = uieditfield(leftGrid, 'text', ...
                'Value', '5*exp(-2.5*t)', ...
                'Tooltip', 'Use "t" as variable. Example: 5*exp(-2.5*t)') ;
            app.RTD_EqField.Layout.Row = 4 ; app.RTD_EqField.Layout.Column = 2 ;
            app.RTD_EqField.Visible = 'off' ;

            app.RTD_EqTStartLabel = uilabel(leftGrid, 'Text', 't start:') ;
            app.RTD_EqTStartLabel.Layout.Row = 5 ; app.RTD_EqTStartLabel.Layout.Column = 1 ;
            app.RTD_EqTStartLabel.Visible = 'off' ;
            app.RTD_EqTStartField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0, 'Limits', [0 Inf]) ;
            app.RTD_EqTStartField.Layout.Row = 5 ; app.RTD_EqTStartField.Layout.Column = 2 ;
            app.RTD_EqTStartField.Visible = 'off' ;

            app.RTD_EqTEndLabel = uilabel(leftGrid, 'Text', 't end:') ;
            app.RTD_EqTEndLabel.Layout.Row = 6 ; app.RTD_EqTEndLabel.Layout.Column = 1 ;
            app.RTD_EqTEndLabel.Visible = 'off' ;
            app.RTD_EqTEndField = uieditfield(leftGrid, 'numeric', ...
                'Value', 10, 'Limits', [0.001 Inf]) ;
            app.RTD_EqTEndField.Layout.Row = 6 ; app.RTD_EqTEndField.Layout.Column = 2 ;
            app.RTD_EqTEndField.Visible = 'off' ;

            app.RTD_EqNptsLabel = uilabel(leftGrid, 'Text', 'N points:') ;
            app.RTD_EqNptsLabel.Layout.Row = 7 ; app.RTD_EqNptsLabel.Layout.Column = 1 ;
            app.RTD_EqNptsLabel.Visible = 'off' ;
            app.RTD_EqNptsField = uieditfield(leftGrid, 'numeric', ...
                'Value', 500, 'Limits', [10 10000]) ;
            app.RTD_EqNptsField.Layout.Row = 7 ; app.RTD_EqNptsField.Layout.Column = 2 ;
            app.RTD_EqNptsField.Visible = 'off' ;

            % Row 10: Generate button
            app.RTD_GenerateButton = uibutton(leftGrid, 'push', ...
                'Text', 'Generate RTD', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.RTD_generate()) ;
            app.RTD_GenerateButton.Layout.Row = 10 ;
            app.RTD_GenerateButton.Layout.Column = [1 2] ;

            % Row 11: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 11 ; lbl.Layout.Column = [1 2] ;

            % Row 12: tau_m
            lbl = uilabel(leftGrid, 'Text', 'tau_m (s):') ;
            lbl.Layout.Row = 12 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultTau = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultTau.Layout.Row = 12 ;
            app.RTD_ResultTau.Layout.Column = 2 ;

            % Row 13: sigma^2
            lbl = uilabel(leftGrid, 'Text', 'sigma^2 (s^2):') ;
            lbl.Layout.Row = 13 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultSigma2 = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultSigma2.Layout.Row = 13 ;
            app.RTD_ResultSigma2.Layout.Column = 2 ;

            % Row 14: sigma^2_theta
            lbl = uilabel(leftGrid, 'Text', 'sigma^2_theta:') ;
            lbl.Layout.Row = 14 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultSigma2Theta = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultSigma2Theta.Layout.Row = 14 ;
            app.RTD_ResultSigma2Theta.Layout.Column = 2 ;

            % Row 15: s^3
            lbl = uilabel(leftGrid, 'Text', 's^3 (skewness):') ;
            lbl.Layout.Row = 15 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultS3 = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultS3.Layout.Row = 15 ;
            app.RTD_ResultS3.Layout.Column = 2 ;

            % Row 16: N_est
            lbl = uilabel(leftGrid, 'Text', 'N_est (= tau^2/sigma^2):') ;
            lbl.Layout.Row = 16 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultN = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultN.Layout.Row = 16 ;
            app.RTD_ResultN.Layout.Column = 2 ;

            % Row 17: V_eff
            lbl = uilabel(leftGrid, 'Text', 'V_eff (m^3):') ;
            lbl.Layout.Row = 17 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultVeff = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultVeff.Layout.Row = 17 ;
            app.RTD_ResultVeff.Layout.Column = 2 ;

            % Row 18: Export name
            lbl = uilabel(leftGrid, 'Text', 'Export name:') ;
            lbl.Layout.Row = 18 ; lbl.Layout.Column = 1 ;
            app.RTD_ExportNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'RTD_1') ;
            app.RTD_ExportNameField.Layout.Row = 18 ;
            app.RTD_ExportNameField.Layout.Column = 2 ;

            % Row 19: Export button
            app.RTD_ExportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Export RTD to Workspace', ...
                'BackgroundColor', [0.2 0.7 0.3], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.RTD_export()) ;
            app.RTD_ExportButton.Layout.Row = 19 ;
            app.RTD_ExportButton.Layout.Column = [1 2] ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'RTD Plots') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % E(t) plot
            app.RTD_AxesEt = uiaxes(plotGrid) ;
            title(app.RTD_AxesEt, 'E(t)') ;
            xlabel(app.RTD_AxesEt, 't (s)') ;
            ylabel(app.RTD_AxesEt, 'E(t) (1/s)') ;

            % F(t) plot
            app.RTD_AxesFt = uiaxes(plotGrid) ;
            title(app.RTD_AxesFt, 'F(t)') ;
            xlabel(app.RTD_AxesFt, 't (s)') ;
            ylabel(app.RTD_AxesFt, 'F(t)') ;

            % E(theta) plot
            app.RTD_AxesEtheta = uiaxes(plotGrid) ;
            title(app.RTD_AxesEtheta, 'E(\Theta)') ;
            xlabel(app.RTD_AxesEtheta, '\Theta = t/\tau') ;
            ylabel(app.RTD_AxesEtheta, 'E(\Theta)') ;

        end

        %% ============== RTD CALLBACKS ==============

        function RTD_sourceChanged(app)
            % Show/hide fields based on selected RTD source

            source = app.RTD_SourceDropdown.Value ;

            % Hide all optional fields first
            app.RTD_NLabel.Visible = 'off' ;
            app.RTD_NField.Visible = 'off' ;
            app.RTD_BoLabel.Visible = 'off' ;
            app.RTD_BoField.Visible = 'off' ;
            app.RTD_ExpTVarLabel.Visible = 'off' ;
            app.RTD_ExpTVarField.Visible = 'off' ;
            app.RTD_ExpCVarLabel.Visible = 'off' ;
            app.RTD_ExpCVarField.Visible = 'off' ;
            app.RTD_ExpC0Label.Visible = 'off' ;
            app.RTD_ExpC0Field.Visible = 'off' ;
            app.RTD_ImportButton.Visible = 'off' ;
            app.RTD_ImportLabel.Visible = 'off' ;
            app.RTD_EqLabel.Visible = 'off' ;
            app.RTD_EqField.Visible = 'off' ;
            app.RTD_EqTStartLabel.Visible = 'off' ;
            app.RTD_EqTStartField.Visible = 'off' ;
            app.RTD_EqTEndLabel.Visible = 'off' ;
            app.RTD_EqTEndField.Visible = 'off' ;
            app.RTD_EqNptsLabel.Visible = 'off' ;
            app.RTD_EqNptsField.Visible = 'off' ;

            % Show tau for all analytical models
            tauVisible = 'on' ;

            switch source
                case 'Tanks-in-Series'
                    app.RTD_NLabel.Visible = 'on' ;
                    app.RTD_NField.Visible = 'on' ;

                case {'Dispersion (open)', 'Dispersion (closed)'}
                    app.RTD_BoLabel.Visible = 'on' ;
                    app.RTD_BoField.Visible = 'on' ;

                case 'Experimental Pulse'
                    app.RTD_ExpTVarLabel.Visible = 'on' ;
                    app.RTD_ExpTVarField.Visible = 'on' ;
                    app.RTD_ExpCVarLabel.Visible = 'on' ;
                    app.RTD_ExpCVarField.Visible = 'on' ;
                    app.RTD_ImportButton.Visible = 'on' ;
                    app.RTD_ImportLabel.Visible = 'on' ;
                    tauVisible = 'off' ;

                case 'Experimental Step'
                    app.RTD_ExpTVarLabel.Visible = 'on' ;
                    app.RTD_ExpTVarField.Visible = 'on' ;
                    app.RTD_ExpCVarLabel.Visible = 'on' ;
                    app.RTD_ExpCVarField.Visible = 'on' ;
                    app.RTD_ExpC0Label.Visible = 'on' ;
                    app.RTD_ExpC0Field.Visible = 'on' ;
                    app.RTD_ImportButton.Visible = 'on' ;
                    app.RTD_ImportLabel.Visible = 'on' ;
                    tauVisible = 'off' ;

                case 'C(t) Equation'
                    app.RTD_EqLabel.Visible = 'on' ;
                    app.RTD_EqField.Visible = 'on' ;
                    app.RTD_EqTStartLabel.Visible = 'on' ;
                    app.RTD_EqTStartField.Visible = 'on' ;
                    app.RTD_EqTEndLabel.Visible = 'on' ;
                    app.RTD_EqTEndField.Visible = 'on' ;
                    app.RTD_EqNptsLabel.Visible = 'on' ;
                    app.RTD_EqNptsField.Visible = 'on' ;
                    tauVisible = 'off' ;
            end

            app.RTD_TauField.Visible = tauVisible ;
        end

        function RTD_generate(app)
            % Generate RTD based on selected source and parameters

            try
                source = app.RTD_SourceDropdown.Value ;
                tau_val = app.RTD_TauField.Value ;

                switch source
                    case 'Ideal CSTR'
                        app.rtd = RTD.ideal_cstr(tau_val) ;

                    case 'Ideal PFR'
                        app.rtd = RTD.ideal_pfr(tau_val) ;

                    case 'Tanks-in-Series'
                        n = app.RTD_NField.Value ;
                        app.rtd = RTD.tanks_in_series(n, tau_val) ;

                    case 'Dispersion (open)'
                        Bo = app.RTD_BoField.Value ;
                        app.rtd = RTD.dispersion_open(Bo, tau_val) ;

                    case 'Dispersion (closed)'
                        Bo = app.RTD_BoField.Value ;
                        app.rtd = RTD.dispersion_closed(Bo, tau_val) ;

                    case 'Experimental Pulse'
                        t_var = app.RTD_ExpTVarField.Value ;
                        C_var = app.RTD_ExpCVarField.Value ;
                        t_data = evalin('base', t_var) ;
                        C_data = evalin('base', C_var) ;
                        app.rtd = RTD.from_pulse(t_data, C_data) ;

                    case 'Experimental Step'
                        t_var = app.RTD_ExpTVarField.Value ;
                        C_var = app.RTD_ExpCVarField.Value ;
                        t_data = evalin('base', t_var) ;
                        C_data = evalin('base', C_var) ;
                        C0 = app.RTD_ExpC0Field.Value ;
                        app.rtd = RTD.from_step(t_data, C_data, C0) ;

                    case 'C(t) Equation'
                        eq_str = app.RTD_EqField.Value ;
                        t_start = app.RTD_EqTStartField.Value ;
                        t_end = app.RTD_EqTEndField.Value ;
                        n_pts = round(app.RTD_EqNptsField.Value) ;

                        % Generate t vector and evaluate C(t)
                        t = linspace(t_start, t_end, n_pts) ;
                        try
                            C_data = eval(eq_str) ;
                        catch evalErr
                            error('Error evaluating equation "%s": %s', ...
                                eq_str, evalErr.message) ;
                        end

                        % Validate result
                        if ~isnumeric(C_data) || length(C_data) ~= length(t)
                            error('Equation must return a numeric vector of same size as t. Check that you use element-wise operators (.*  ./  .^)') ;
                        end

                        % Ensure non-negative
                        C_data = max(C_data, 0) ;

                        % Build RTD from pulse response
                        app.rtd = RTD.from_pulse(t, C_data) ;
                end

                % Update results
                app.RTD_updateResults() ;

                % Update plots
                app.RTD_updatePlots() ;

                % Enable export button
                app.RTD_ExportButton.Enable = 'on' ;

                % Update Tab 2 RTD status if tab exists
                if ~isempty(app.Pred_RTDStatusLabel)
                    app.Pred_RTDStatusLabel.Text = sprintf('%s | tau=%.2f, sigma2=%.2f', ...
                        source, app.rtd.tau, app.rtd.sigma2) ;
                    app.Pred_RTDStatusLabel.FontColor = [0 0.5 0] ;
                end

            catch ME
                uialert(app.UIFigure, ME.message, 'Error generating RTD') ;
            end
        end

        function RTD_updateResults(app)
            % Update the results labels with RTD moments

            if isempty(app.rtd)
                return
            end

            app.RTD_ResultTau.Text = sprintf('%.4f', app.rtd.tau) ;
            app.RTD_ResultSigma2.Text = sprintf('%.4f', app.rtd.sigma2) ;

            if ~isempty(app.rtd.sigma2_theta)
                app.RTD_ResultSigma2Theta.Text = sprintf('%.6f', app.rtd.sigma2_theta) ;
            end

            if ~isempty(app.rtd.s3)
                app.RTD_ResultS3.Text = sprintf('%.4f', app.rtd.s3) ;
            end

            if app.rtd.sigma2 > 0
                N_est = app.rtd.tau^2 / app.rtd.sigma2 ;
                app.RTD_ResultN.Text = sprintf('%.2f', N_est) ;
            end

            % V_eff = tau * Qv
            Qv = app.RTD_QvField.Value ;
            V_eff = app.rtd.tau * Qv ;
            app.RTD_ResultVeff.Text = sprintf('%.6g', V_eff) ;
        end

        function RTD_updatePlots(app)
            % Update all three RTD plots

            if isempty(app.rtd)
                return
            end

            % Build equation strings based on RTD source
            [eq_Et, eq_Ft, eq_Etheta] = app.RTD_getEquationStrings() ;

            % E(t) plot
            cla(app.RTD_AxesEt) ;
            plot(app.RTD_AxesEt, app.rtd.t, app.rtd.Et, 'b-', 'LineWidth', 1.5) ;
            title(app.RTD_AxesEt, 'E(t)') ;
            xlabel(app.RTD_AxesEt, 't (s)') ;
            ylabel(app.RTD_AxesEt, 'E(t) (1/s)') ;
            if ~isempty(eq_Et)
                text(app.RTD_AxesEt, 0.95, 0.90, eq_Et, ...
                    'Units', 'normalized', 'HorizontalAlignment', 'right', ...
                    'VerticalAlignment', 'top', 'FontSize', 9, ...
                    'Interpreter', 'tex', ...
                    'BackgroundColor', [1 1 1 0.8], 'EdgeColor', [0.7 0.7 0.7]) ;
            end

            % F(t) plot
            cla(app.RTD_AxesFt) ;
            plot(app.RTD_AxesFt, app.rtd.t, app.rtd.Ft, 'r-', 'LineWidth', 1.5) ;
            title(app.RTD_AxesFt, 'F(t)') ;
            xlabel(app.RTD_AxesFt, 't (s)') ;
            ylabel(app.RTD_AxesFt, 'F(t)') ;
            ylim(app.RTD_AxesFt, [0 1.05]) ;
            if ~isempty(eq_Ft)
                text(app.RTD_AxesFt, 0.95, 0.50, eq_Ft, ...
                    'Units', 'normalized', 'HorizontalAlignment', 'right', ...
                    'VerticalAlignment', 'top', 'FontSize', 9, ...
                    'Interpreter', 'tex', ...
                    'BackgroundColor', [1 1 1 0.8], 'EdgeColor', [0.7 0.7 0.7]) ;
            end

            % E(theta) plot
            cla(app.RTD_AxesEtheta) ;
            if ~isempty(app.rtd.theta) && ~isempty(app.rtd.Etheta)
                plot(app.RTD_AxesEtheta, app.rtd.theta, app.rtd.Etheta, ...
                     'Color', [0 0.6 0], 'LineWidth', 1.5) ;
            end
            title(app.RTD_AxesEtheta, 'E(\Theta)') ;
            xlabel(app.RTD_AxesEtheta, '\Theta = t/\tau') ;
            ylabel(app.RTD_AxesEtheta, 'E(\Theta)') ;
            if ~isempty(eq_Etheta)
                text(app.RTD_AxesEtheta, 0.95, 0.90, eq_Etheta, ...
                    'Units', 'normalized', 'HorizontalAlignment', 'right', ...
                    'VerticalAlignment', 'top', 'FontSize', 9, ...
                    'Interpreter', 'tex', ...
                    'BackgroundColor', [1 1 1 0.8], 'EdgeColor', [0.7 0.7 0.7]) ;
            end
        end

        function [eq_Et, eq_Ft, eq_Etheta] = RTD_getEquationStrings(app)
            % Return LaTeX-like equation strings for each RTD plot
            % based on the current RTD source type

            eq_Et = '' ;
            eq_Ft = '' ;
            eq_Etheta = '' ;

            source = app.RTD_SourceDropdown.Value ;
            tau = app.rtd.tau ;

            switch source
                case 'Ideal CSTR'
                    eq_Et = sprintf('E(t) = (1/\\tau) e^{-t/\\tau},  \\tau = %.4g', tau) ;
                    eq_Ft = sprintf('F(t) = 1 - e^{-t/\\tau}') ;
                    eq_Etheta = 'E(\Theta) = e^{-\Theta}' ;

                case 'Ideal PFR'
                    eq_Et = sprintf('E(t) = \\delta(t - \\tau),  \\tau = %.4g', tau) ;
                    eq_Ft = sprintf('F(t) = H(t - \\tau)') ;
                    eq_Etheta = 'E(\Theta) = \delta(\Theta - 1)' ;

                case 'Tanks-in-Series'
                    N = app.RTD_NField.Value ;
                    eq_Et = sprintf('E(t) = \\frac{t^{N-1}}{(N-1)! \\tau_i^N} e^{-t/\\tau_i},  N=%.4g', N) ;
                    eq_Ft = 'F(t) = 1 - e^{-t/\tau_i} \Sigma' ;
                    eq_Etheta = sprintf('E(\\Theta) = \\frac{N(N\\Theta)^{N-1}}{(N-1)!} e^{-N\\Theta},  N=%.4g', N) ;

                case 'Dispersion (open)'
                    Bo = app.RTD_BoField.Value ;
                    eq_Et = sprintf('E(t) = \\frac{1}{\\tau\\sqrt{4\\pi Bo}} e^{-(1-t/\\tau)^2/4Bo},  Bo=%.4g', Bo) ;
                    eq_Ft = 'F(t) = \int_0^t E(t'') dt''' ;
                    eq_Etheta = sprintf('\\sigma^2_\\Theta = 2Bo + 8Bo^2,  Bo=%.4g', Bo) ;

                case 'Dispersion (closed)'
                    Bo = app.RTD_BoField.Value ;
                    eq_Et = sprintf('Danckwerts closed-closed,  Bo=%.4g', Bo) ;
                    eq_Ft = 'F(t) = \int_0^t E(t'') dt''' ;
                    eq_Etheta = sprintf('\\sigma^2_\\Theta = 2Bo - 2Bo^2(1-e^{-1/Bo}),  Bo=%.4g', Bo) ;

                case 'C(t) Equation'
                    eq_str = app.RTD_EqField.Value ;
                    eq_Et = sprintf('C(t) = %s', eq_str) ;
                    eq_Ft = sprintf('\\tau_m = %.4g s', tau) ;
                    eq_Etheta = sprintf('\\sigma^2_\\Theta = %.4g', app.rtd.sigma2_theta) ;

                case {'Experimental Pulse', 'Experimental Step'}
                    eq_Et = sprintf('Experimental data,  \\tau_m = %.4g s', tau) ;
                    eq_Ft = sprintf('\\sigma^2 = %.4g s^2', app.rtd.sigma2) ;
                    eq_Etheta = sprintf('\\sigma^2_\\Theta = %.4g', app.rtd.sigma2_theta) ;
            end
        end

        function RTD_export(app)
            % Export RTD object to base workspace with user-defined name
            % Auto-increments the name for subsequent exports

            if isempty(app.rtd)
                uialert(app.UIFigure, 'No RTD to export. Generate one first.', 'Warning') ;
                return
            end

            varName = app.RTD_ExportNameField.Value ;

            % Validate variable name
            if ~isvarname(varName)
                uialert(app.UIFigure, ...
                    sprintf('"%s" is not a valid MATLAB variable name.', varName), ...
                    'Invalid Name') ;
                return
            end

            assignin('base', varName, app.rtd) ;
            uialert(app.UIFigure, ...
                sprintf('RTD exported to workspace as "%s"', varName), ...
                'Export Successful', 'Icon', 'success') ;

            % Auto-increment for next export
            app.RTD_ExportCounter = app.RTD_ExportCounter + 1 ;
            app.RTD_ExportNameField.Value = sprintf('RTD_%d', app.RTD_ExportCounter) ;
        end

        function RTD_importFromFile(app)
            % Import experimental data (t, C) from Excel or CSV file
            % Reads the first two columns as t and C vectors and assigns
            % them to the workspace with the names specified in the fields.

            [file, path] = uigetfile( ...
                {'*.xlsx;*.xls;*.csv;*.tsv', 'Data files (*.xlsx, *.xls, *.csv, *.tsv)' ; ...
                 '*.*', 'All files (*.*)'}, ...
                'Select experimental data file') ;

            if isequal(file, 0)
                return  % User cancelled
            end

            try
                fullPath = fullfile(path, file) ;

                % Read data depending on extension
                [~, ~, ext] = fileparts(file) ;

                switch lower(ext)
                    case {'.xlsx', '.xls'}
                        data = readmatrix(fullPath) ;
                    case '.csv'
                        data = readmatrix(fullPath, 'Delimiter', ',') ;
                    case '.tsv'
                        data = readmatrix(fullPath, 'Delimiter', '\t') ;
                    otherwise
                        data = readmatrix(fullPath) ;
                end

                if size(data, 2) < 2
                    uialert(app.UIFigure, ...
                        'File must have at least 2 columns (t and C).', ...
                        'Import Error') ;
                    return
                end

                % Remove rows with NaN (common with headers)
                data = data(~any(isnan(data(:,1:2)), 2), :) ;

                t_data = data(:, 1)' ;
                C_data = data(:, 2)' ;

                % Assign to workspace with user-specified names
                t_varName = app.RTD_ExpTVarField.Value ;
                C_varName = app.RTD_ExpCVarField.Value ;

                assignin('base', t_varName, t_data) ;
                assignin('base', C_varName, C_data) ;

                % Update status label
                app.RTD_ImportLabel.Text = sprintf('Loaded: %s (%d pts)', file, length(t_data)) ;
                app.RTD_ImportLabel.Visible = 'on' ;

            catch ME
                uialert(app.UIFigure, ME.message, 'Import Error') ;
            end
        end

        %% ============== TAB 2: PREDICTION MODELS ==============
        function createPredictionTab(app)

            app.PredTab = uitab(app.TabGroup, 'Title', 'Prediction Models') ;

            % Main grid: left panel (controls) + right panel (plots)
            mainGrid = uigridlayout(app.PredTab, [1 2]) ;
            mainGrid.ColumnWidth = {320, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'Conversion Bounds') ;
            leftGrid = uigridlayout(leftPanel, [18 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 18) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % RTD status
            uilabel(leftGrid, 'Text', 'Current RTD:', ...
                'FontWeight', 'bold') ;
            app.Pred_RTDStatusLabel = uilabel(leftGrid, ...
                'Text', 'None (generate in Tab 1)', ...
                'FontColor', [0.8 0 0]) ;

            % Kinetics dropdown
            uilabel(leftGrid, 'Text', 'Kinetics:', ...
                'FontWeight', 'bold') ;
            app.Pred_KineticsDropdown = uidropdown(leftGrid, ...
                'Items', {'1st Order (-rA = k*CA)', ...
                          '2nd Order (-rA = k*CA^2)'}, ...
                'Value', '1st Order (-rA = k*CA)', ...
                'ValueChangedFcn', @(~,~) app.Pred_kineticsChanged()) ;

            % k field
            app.Pred_kLabel = uilabel(leftGrid, 'Text', 'k (1/time):') ;
            app.Pred_kField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.1, 'Limits', [0 Inf]) ;

            % CA0 field (only for 2nd order)
            app.Pred_CA0Label = uilabel(leftGrid, 'Text', 'CA0 (mol/m^3):') ;
            app.Pred_CA0Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 1000, 'Limits', [0.001 Inf]) ;
            app.Pred_CA0Label.Visible = 'off' ;
            app.Pred_CA0Field.Visible = 'off' ;

            % Spacer
            uilabel(leftGrid, 'Text', '') ;
            uilabel(leftGrid, 'Text', '') ;

            % Compute button
            app.Pred_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Compute Bounds', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Pred_compute()) ;
            app.Pred_ComputeButton.Layout.Column = [1 2] ;

            % Spacer
            uilabel(leftGrid, 'Text', '') ;
            uilabel(leftGrid, 'Text', '') ;

            % Results panel
            uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            uilabel(leftGrid, 'Text', '') ;

            uilabel(leftGrid, 'Text', 'Segregation X_mean:') ;
            app.Pred_ResultSegLabel = uilabel(leftGrid, 'Text', '--') ;

            uilabel(leftGrid, 'Text', 'Max Mixedness X_exit:') ;
            app.Pred_ResultMMLabel = uilabel(leftGrid, 'Text', '--') ;

            % Spacer
            uilabel(leftGrid, 'Text', '') ;
            uilabel(leftGrid, 'Text', '') ;

            uilabel(leftGrid, 'Text', 'Interpretation:') ;
            uilabel(leftGrid, 'Text', '') ;

            app.Pred_ResultBoundsLabel = uilabel(leftGrid, 'Text', '--') ;
            app.Pred_ResultBoundsLabel.Layout.Column = [1 2] ;
            app.Pred_ResultBoundsLabel.WordWrap = 'on' ;

            % Spacer rows
            uilabel(leftGrid, 'Text', '') ;
            uilabel(leftGrid, 'Text', '') ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Model Results') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % X_batch(t) plot (Segregation)
            app.Pred_AxesXbatch = uiaxes(plotGrid) ;
            title(app.Pred_AxesXbatch, 'Batch Conversion X(t)') ;
            xlabel(app.Pred_AxesXbatch, 't') ;
            ylabel(app.Pred_AxesXbatch, 'X_{batch}(t)') ;
            grid(app.Pred_AxesXbatch, 'on') ;

            % Integrand plot (Segregation)
            app.Pred_AxesIntegrand = uiaxes(plotGrid) ;
            title(app.Pred_AxesIntegrand, 'Integrand X(t)*E(t)') ;
            xlabel(app.Pred_AxesIntegrand, 't') ;
            ylabel(app.Pred_AxesIntegrand, 'X(t)*E(t)') ;
            grid(app.Pred_AxesIntegrand, 'on') ;

            % X(lambda) plot (Max Mixedness)
            app.Pred_AxesXlambda = uiaxes(plotGrid) ;
            title(app.Pred_AxesXlambda, 'X(lambda) - Max Mixedness') ;
            xlabel(app.Pred_AxesXlambda, 'lambda') ;
            ylabel(app.Pred_AxesXlambda, 'X(lambda)') ;
            grid(app.Pred_AxesXlambda, 'on') ;

            % Comparison bar chart
            app.Pred_AxesComparison = uiaxes(plotGrid) ;
            title(app.Pred_AxesComparison, 'Conversion Bounds') ;
            ylabel(app.Pred_AxesComparison, 'Conversion X') ;
            grid(app.Pred_AxesComparison, 'on') ;
        end

        %% ============== PREDICTION CALLBACKS ==============

        function Pred_kineticsChanged(app)
            % Show/hide CA0 field based on kinetics selection

            kinetics = app.Pred_KineticsDropdown.Value ;

            if contains(kinetics, '2nd')
                app.Pred_CA0Label.Visible = 'on' ;
                app.Pred_CA0Field.Visible = 'on' ;
                app.Pred_kLabel.Text = 'k (m^3/(mol*time)):' ;
            else
                app.Pred_CA0Label.Visible = 'off' ;
                app.Pred_CA0Field.Visible = 'off' ;
                app.Pred_kLabel.Text = 'k (1/time):' ;
            end
        end

        function Pred_compute(app)
            % Compute segregation and max mixedness bounds

            try
                % Check RTD is available
                if isempty(app.rtd)
                    uialert(app.UIFigure, ...
                        'No RTD available. Go to Tab 1 and generate an RTD first.', ...
                        'RTD Required') ;
                    return
                end

                kinetics = app.Pred_KineticsDropdown.Value ;
                k_val = app.Pred_kField.Value ;

                % Create model objects
                app.seg_model = SegregationModel ;
                app.seg_model.rtd = app.rtd ;

                app.mm_model = MaxMixednessModel ;
                app.mm_model.rtd = app.rtd ;

                if contains(kinetics, '1st')
                    % First order
                    app.seg_model = app.seg_model.compute_firstOrder(k_val) ;
                    app.mm_model = app.mm_model.compute_firstOrder(k_val) ;
                    order = 1 ;
                else
                    % Second order
                    CA0_val = app.Pred_CA0Field.Value ;
                    app.seg_model = app.seg_model.compute_secondOrder(k_val, CA0_val) ;
                    app.mm_model = app.mm_model.compute_secondOrder(k_val, CA0_val) ;
                    order = 2 ;
                end

                % Update results labels
                X_seg = app.seg_model.X_mean ;
                X_mm = app.mm_model.X_exit ;

                app.Pred_ResultSegLabel.Text = sprintf('%.4f', X_seg) ;
                app.Pred_ResultMMLabel.Text = sprintf('%.4f', X_mm) ;

                % Interpretation
                if order == 1
                    app.Pred_ResultBoundsLabel.Text = ...
                        sprintf('1st order: Seg = MM = exact = %.4f', X_seg) ;
                    app.Pred_ResultBoundsLabel.FontColor = [0 0.5 0] ;
                elseif order == 2
                    app.Pred_ResultBoundsLabel.Text = ...
                        sprintf('n>1: Seg=%.4f (upper) >= MM=%.4f (lower)', X_seg, X_mm) ;
                    app.Pred_ResultBoundsLabel.FontColor = [0 0 0.7] ;
                end

                % Update plots
                app.Pred_updatePlots() ;

                % Update RTD status label
                app.Pred_RTDStatusLabel.Text = sprintf('tau=%.2f, sigma2=%.2f', ...
                    app.rtd.tau, app.rtd.sigma2) ;
                app.Pred_RTDStatusLabel.FontColor = [0 0.5 0] ;

            catch ME
                uialert(app.UIFigure, ME.message, 'Error computing bounds') ;
            end
        end

        function Pred_updatePlots(app)
            % Update all prediction model plots

            if isempty(app.seg_model) || isempty(app.mm_model)
                return
            end

            % Segregation plots (X_batch and integrand)
            app.seg_model.plot_on_axes(app.Pred_AxesXbatch, app.Pred_AxesIntegrand) ;

            % Max mixedness plot (X(lambda))
            app.mm_model.plot_on_axes(app.Pred_AxesXlambda) ;

            % Comparison bar chart
            cla(app.Pred_AxesComparison) ;
            X_seg = app.seg_model.X_mean ;
            X_mm = app.mm_model.X_exit ;

            bar_data = [X_seg ; X_mm] ;
            b = bar(app.Pred_AxesComparison, bar_data) ;
            b.FaceColor = 'flat' ;
            b.CData = [0.3 0.6 0.9 ; 0.8 0.3 0.8] ;
            set(app.Pred_AxesComparison, 'XTickLabel', {'Segregation', 'Max Mixedness'}) ;
            ylabel(app.Pred_AxesComparison, 'Conversion X') ;
            title(app.Pred_AxesComparison, 'Conversion Bounds') ;
            ylim(app.Pred_AxesComparison, [0 1.12]) ;
            grid(app.Pred_AxesComparison, 'on') ;

            % Add value labels on bars - inside bar if value > 0.85
            hold(app.Pred_AxesComparison, 'on') ;
            vals = [X_seg, X_mm] ;
            for idx = 1:2
                if vals(idx) > 0.85
                    ypos = vals(idx) - 0.06 ;
                    txtColor = [1 1 1] ;
                else
                    ypos = vals(idx) + 0.03 ;
                    txtColor = [0 0 0] ;
                end
                text(app.Pred_AxesComparison, idx, ypos, ...
                    sprintf('%.4f', vals(idx)), ...
                    'HorizontalAlignment', 'center', ...
                    'FontWeight', 'bold', 'FontSize', 10, ...
                    'Color', txtColor) ;
            end
            hold(app.Pred_AxesComparison, 'off') ;
        end

        %% ============== TAB 3: TANKS-IN-SERIES ==============
        function createTISTab(app)

            app.TISTab = uitab(app.TabGroup, 'Title', 'Tanks-in-Series') ;

            % Main grid: left panel (controls) + right panel (plots)
            mainGrid = uigridlayout(app.TISTab, [1 2]) ;
            mainGrid.ColumnWidth = {320, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'TIS Configuration') ;
            leftGrid = uigridlayout(leftPanel, [16 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 16) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: N method
            lbl = uilabel(leftGrid, 'Text', 'N method:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = 1 ;
            app.TIS_NMethodDropdown = uidropdown(leftGrid, ...
                'Items', {'Manual', 'From calculated data'}, ...
                'Value', 'Manual', ...
                'ValueChangedFcn', @(~,~) app.TIS_NMethodChanged()) ;
            app.TIS_NMethodDropdown.Layout.Row = 1 ;
            app.TIS_NMethodDropdown.Layout.Column = 2 ;

            % Row 2: N tanks
            app.TIS_NLabel = uilabel(leftGrid, 'Text', 'N (tanks):') ;
            app.TIS_NLabel.Layout.Row = 2 ; app.TIS_NLabel.Layout.Column = 1 ;
            app.TIS_NField = uieditfield(leftGrid, 'numeric', ...
                'Value', 3, 'Limits', [0.1 Inf]) ;
            app.TIS_NField.Layout.Row = 2 ; app.TIS_NField.Layout.Column = 2 ;

            % Row 3: RTD status (shown when "From RTD")
            app.TIS_RTDStatusLabel = uilabel(leftGrid, ...
                'Text', 'RTD: not loaded', 'FontColor', [0.6 0 0]) ;
            app.TIS_RTDStatusLabel.Layout.Row = 3 ;
            app.TIS_RTDStatusLabel.Layout.Column = [1 2] ;
            app.TIS_RTDStatusLabel.Visible = 'off' ;

            % Row 4: tau
            app.TIS_tauLabel = uilabel(leftGrid, 'Text', 'tau total (s):') ;
            app.TIS_tauLabel.Layout.Row = 4 ; app.TIS_tauLabel.Layout.Column = 1 ;
            app.TIS_tauField = uieditfield(leftGrid, 'numeric', ...
                'Value', 10, 'Limits', [0.001 Inf]) ;
            app.TIS_tauField.Layout.Row = 4 ; app.TIS_tauField.Layout.Column = 2 ;

            % Row 5: Kinetics dropdown
            lbl = uilabel(leftGrid, 'Text', 'Kinetics:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 5 ; lbl.Layout.Column = 1 ;
            app.TIS_KineticsDropdown = uidropdown(leftGrid, ...
                'Items', {'1st Order (-rA = k*CA)', ...
                          '2nd Order (-rA = k*CA^2)'}, ...
                'Value', '1st Order (-rA = k*CA)', ...
                'ValueChangedFcn', @(~,~) app.TIS_kineticsChanged()) ;
            app.TIS_KineticsDropdown.Layout.Row = 5 ;
            app.TIS_KineticsDropdown.Layout.Column = 2 ;

            % Row 6: k
            app.TIS_kLabel = uilabel(leftGrid, 'Text', 'k (1/time):') ;
            app.TIS_kLabel.Layout.Row = 6 ; app.TIS_kLabel.Layout.Column = 1 ;
            app.TIS_kField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.1, 'Limits', [0 Inf]) ;
            app.TIS_kField.Layout.Row = 6 ; app.TIS_kField.Layout.Column = 2 ;

            % Row 7: CA0 (only for 2nd order)
            app.TIS_CA0Label = uilabel(leftGrid, 'Text', 'CA0 (mol/m^3):') ;
            app.TIS_CA0Label.Layout.Row = 7 ; app.TIS_CA0Label.Layout.Column = 1 ;
            app.TIS_CA0Label.Visible = 'off' ;
            app.TIS_CA0Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 1000, 'Limits', [0.001 Inf]) ;
            app.TIS_CA0Field.Layout.Row = 7 ; app.TIS_CA0Field.Layout.Column = 2 ;
            app.TIS_CA0Field.Visible = 'off' ;

            % Row 8: Compute button
            app.TIS_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Compute', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.TIS_compute()) ;
            app.TIS_ComputeButton.Layout.Row = 8 ;
            app.TIS_ComputeButton.Layout.Column = [1 2] ;

            % Row 9: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 9 ; lbl.Layout.Column = [1 2] ;

            % Row 10: N used
            lbl = uilabel(leftGrid, 'Text', 'N used:') ;
            lbl.Layout.Row = 10 ; lbl.Layout.Column = 1 ;
            app.TIS_ResultNused = uilabel(leftGrid, 'Text', '--') ;
            app.TIS_ResultNused.Layout.Row = 10 ;
            app.TIS_ResultNused.Layout.Column = 2 ;

            % Row 11: X_TIS
            lbl = uilabel(leftGrid, 'Text', 'X_TIS:') ;
            lbl.Layout.Row = 11 ; lbl.Layout.Column = 1 ;
            app.TIS_ResultXtis = uilabel(leftGrid, 'Text', '--') ;
            app.TIS_ResultXtis.Layout.Row = 11 ;
            app.TIS_ResultXtis.Layout.Column = 2 ;
            app.TIS_ResultXtis.FontWeight = 'bold' ;

            % Row 12: X_CSTR (N=1 reference)
            lbl = uilabel(leftGrid, 'Text', 'X_CSTR (N=1):') ;
            lbl.Layout.Row = 12 ; lbl.Layout.Column = 1 ;
            app.TIS_ResultXcstr = uilabel(leftGrid, 'Text', '--') ;
            app.TIS_ResultXcstr.Layout.Row = 12 ;
            app.TIS_ResultXcstr.Layout.Column = 2 ;

            % Row 13: X_PFR (N→inf reference)
            lbl = uilabel(leftGrid, 'Text', 'X_PFR (N->inf):') ;
            lbl.Layout.Row = 13 ; lbl.Layout.Column = 1 ;
            app.TIS_ResultXpfr = uilabel(leftGrid, 'Text', '--') ;
            app.TIS_ResultXpfr.Layout.Row = 13 ;
            app.TIS_ResultXpfr.Layout.Column = 2 ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'TIS Results') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % E(t) plot for TIS model
            app.TIS_AxesEt = uiaxes(plotGrid) ;
            title(app.TIS_AxesEt, 'E(t) - TIS Model') ;
            xlabel(app.TIS_AxesEt, 't (s)') ;
            ylabel(app.TIS_AxesEt, 'E(t) (1/s)') ;
            grid(app.TIS_AxesEt, 'on') ;

            % X vs N sweep plot
            app.TIS_AxesXvsN = uiaxes(plotGrid) ;
            title(app.TIS_AxesXvsN, 'Conversion vs N') ;
            xlabel(app.TIS_AxesXvsN, 'N (number of tanks)') ;
            ylabel(app.TIS_AxesXvsN, 'X_A') ;
            grid(app.TIS_AxesXvsN, 'on') ;

            % Comparison bar chart
            app.TIS_AxesComparison = uiaxes(plotGrid) ;
            app.TIS_AxesComparison.Layout.Column = [1 2] ;
            title(app.TIS_AxesComparison, 'Comparison: CSTR vs TIS vs PFR') ;
            ylabel(app.TIS_AxesComparison, 'Conversion X') ;
            grid(app.TIS_AxesComparison, 'on') ;
        end

        %% ============== TIS CALLBACKS ==============

        function TIS_NMethodChanged(app)
            source = app.TIS_NMethodDropdown.Value ;
            if contains(source, 'From calculated')
                % Auto-compute N from RTD variance + import k from Prediction
                app.TIS_NField.Enable = 'off' ;
                app.TIS_tauField.Enable = 'off' ;
                app.TIS_kField.Enable = 'off' ;
                app.TIS_KineticsDropdown.Enable = 'off' ;
                app.TIS_CA0Field.Enable = 'off' ;
                app.TIS_RTDStatusLabel.Visible = 'on' ;

                infoLines = {} ;

                % Import RTD data (tau, sigma2 -> N)
                if ~isempty(app.rtd) && app.rtd.sigma2 > 0
                    N_from_rtd = app.rtd.tau^2 / app.rtd.sigma2 ;
                    app.TIS_NField.Value = N_from_rtd ;
                    app.TIS_tauField.Value = app.rtd.tau ;
                    infoLines{end+1} = sprintf('RTD: tau=%.2f, N=%.2f', ...
                        app.rtd.tau, N_from_rtd) ;
                else
                    infoLines{end+1} = 'RTD: not loaded' ;
                end

                % Import kinetics from Prediction Models tab
                if ~isempty(app.Pred_kField) && app.Pred_kField.Value > 0
                    app.TIS_kField.Value = app.Pred_kField.Value ;
                    app.TIS_KineticsDropdown.Value = app.Pred_KineticsDropdown.Value ;
                    app.TIS_kineticsChanged() ;  % update CA0 visibility
                    if ~isempty(app.Pred_CA0Field)
                        app.TIS_CA0Field.Value = app.Pred_CA0Field.Value ;
                    end
                    infoLines{end+1} = sprintf('k=%.4g', app.Pred_kField.Value) ;
                end

                if any(contains(infoLines, 'not loaded'))
                    app.TIS_RTDStatusLabel.FontColor = [0.8 0 0] ;
                else
                    app.TIS_RTDStatusLabel.FontColor = [0 0.5 0] ;
                end
                app.TIS_RTDStatusLabel.Text = strjoin(infoLines, ' | ') ;
            else
                app.TIS_NField.Enable = 'on' ;
                app.TIS_tauField.Enable = 'on' ;
                app.TIS_kField.Enable = 'on' ;
                app.TIS_KineticsDropdown.Enable = 'on' ;
                app.TIS_CA0Field.Enable = 'on' ;
                app.TIS_RTDStatusLabel.Visible = 'off' ;
            end
        end

        function TIS_kineticsChanged(app)
            kinetics = app.TIS_KineticsDropdown.Value ;
            if contains(kinetics, '2nd')
                app.TIS_CA0Label.Visible = 'on' ;
                app.TIS_CA0Field.Visible = 'on' ;
                app.TIS_kLabel.Text = 'k (m^3/(mol*time)):' ;
            else
                app.TIS_CA0Label.Visible = 'off' ;
                app.TIS_CA0Field.Visible = 'off' ;
                app.TIS_kLabel.Text = 'k (1/time):' ;
            end
        end

        function TIS_compute(app)
            try
                N_val = app.TIS_NField.Value ;
                tau_val = app.TIS_tauField.Value ;
                k_val = app.TIS_kField.Value ;
                kinetics = app.TIS_KineticsDropdown.Value ;
                is2nd = contains(kinetics, '2nd') ;

                if is2nd
                    CA0_val = app.TIS_CA0Field.Value ;
                end

                % --- Compute X_TIS for selected N ---
                if ~is2nd
                    % 1st order analytical: X = 1 - 1/(1+tau_i*k)^N
                    tau_i = tau_val / N_val ;
                    X_tis = 1 - 1 / (1 + tau_i * k_val)^N_val ;
                else
                    % 2nd order: solve N sequential CSTRs via mass balance
                    % For each tank: CA_out = (-1 + sqrt(1+4*k*tau_i*CA_in)) / (2*k*tau_i)
                    tau_i = tau_val / round(N_val) ;
                    CA_in = CA0_val ;
                    for j = 1:round(N_val)
                        CA_out = (-1 + sqrt(1 + 4*k_val*tau_i*CA_in)) / (2*k_val*tau_i) ;
                        CA_in = CA_out ;
                    end
                    X_tis = 1 - CA_out / CA0_val ;
                end

                % --- Reference: CSTR (N=1) ---
                if ~is2nd
                    X_cstr = 1 - 1 / (1 + tau_val * k_val) ;
                else
                    CA_cstr = (-1 + sqrt(1 + 4*k_val*tau_val*CA0_val)) / (2*k_val*tau_val) ;
                    X_cstr = 1 - CA_cstr / CA0_val ;
                end

                % --- Reference: PFR (N→inf) ---
                if ~is2nd
                    X_pfr = 1 - exp(-k_val * tau_val) ;
                else
                    X_pfr = 1 - 1 / (1 + k_val*CA0_val*tau_val) ;
                end

                % --- Update results ---
                app.TIS_ResultNused.Text = sprintf('%.2f', N_val) ;
                app.TIS_ResultXtis.Text = sprintf('%.4f', X_tis) ;
                app.TIS_ResultXcstr.Text = sprintf('%.4f', X_cstr) ;
                app.TIS_ResultXpfr.Text = sprintf('%.4f', X_pfr) ;

                % --- Update plots ---
                app.TIS_updatePlots(N_val, tau_val, k_val, is2nd, ...
                    X_tis, X_cstr, X_pfr) ;

            catch ME
                uialert(app.UIFigure, ME.message, 'Error computing TIS') ;
            end
        end

        function TIS_updatePlots(app, N_val, tau_val, k_val, is2nd, ...
                                 X_tis, X_cstr, X_pfr)

            % ---- Plot 1: E(t) for current N ----
            cla(app.TIS_AxesEt) ;
            rtd_tis = RTD.tanks_in_series(N_val, tau_val) ;
            plot(app.TIS_AxesEt, rtd_tis.t, rtd_tis.Et, 'b-', 'LineWidth', 1.5) ;
            title(app.TIS_AxesEt, sprintf('E(t) - TIS  N=%.1f', N_val)) ;
            xlabel(app.TIS_AxesEt, 't (s)') ;
            ylabel(app.TIS_AxesEt, 'E(t) (1/s)') ;
            grid(app.TIS_AxesEt, 'on') ;

            % ---- Plot 2: X vs N sweep ----
            cla(app.TIS_AxesXvsN) ;
            N_sweep = [1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 50, 100] ;
            X_sweep = zeros(size(N_sweep)) ;

            if ~is2nd
                for idx = 1:length(N_sweep)
                    tau_i = tau_val / N_sweep(idx) ;
                    X_sweep(idx) = 1 - 1 / (1 + tau_i * k_val)^N_sweep(idx) ;
                end
            else
                CA0_val = app.TIS_CA0Field.Value ;
                for idx = 1:length(N_sweep)
                    tau_i = tau_val / N_sweep(idx) ;
                    CA_in = CA0_val ;
                    for j = 1:N_sweep(idx)
                        CA_out = (-1 + sqrt(1 + 4*k_val*tau_i*CA_in)) / (2*k_val*tau_i) ;
                        CA_in = CA_out ;
                    end
                    X_sweep(idx) = 1 - CA_out / CA0_val ;
                end
            end

            plot(app.TIS_AxesXvsN, N_sweep, X_sweep, 'bo-', ...
                 'LineWidth', 1.5, 'MarkerFaceColor', [0.3 0.6 0.9]) ;
            hold(app.TIS_AxesXvsN, 'on') ;

            % Mark current N
            plot(app.TIS_AxesXvsN, N_val, X_tis, 'r*', 'MarkerSize', 15, ...
                 'LineWidth', 2) ;

            % Reference lines
            yline(app.TIS_AxesXvsN, X_cstr, '--r', 'CSTR', ...
                  'LineWidth', 1, 'LabelHorizontalAlignment', 'left') ;
            yline(app.TIS_AxesXvsN, X_pfr, '--g', 'PFR', ...
                  'LineWidth', 1, 'LabelHorizontalAlignment', 'left') ;
            hold(app.TIS_AxesXvsN, 'off') ;

            title(app.TIS_AxesXvsN, 'Conversion vs N') ;
            xlabel(app.TIS_AxesXvsN, 'N (number of tanks)') ;
            ylabel(app.TIS_AxesXvsN, 'X_A') ;
            ylim(app.TIS_AxesXvsN, [0 1]) ;
            grid(app.TIS_AxesXvsN, 'on') ;
            legend(app.TIS_AxesXvsN, 'TIS', sprintf('N=%.1f', N_val), ...
                   'Location', 'southeast') ;

            % ---- Plot 3: Comparison bar chart (spanning both columns) ----
            cla(app.TIS_AxesComparison) ;
            bar_data = [X_cstr ; X_tis ; X_pfr] ;
            b = bar(app.TIS_AxesComparison, bar_data) ;
            b.FaceColor = 'flat' ;
            b.CData = [0.9 0.3 0.3 ; 0.3 0.6 0.9 ; 0.3 0.8 0.3] ;
            set(app.TIS_AxesComparison, 'XTickLabel', ...
                {'CSTR (N=1)', sprintf('TIS (N=%.1f)', N_val), 'PFR (N->inf)'}) ;
            ylabel(app.TIS_AxesComparison, 'Conversion X') ;
            title(app.TIS_AxesComparison, 'CSTR vs TIS vs PFR') ;
            ylim(app.TIS_AxesComparison, [0 1.12]) ;
            grid(app.TIS_AxesComparison, 'on') ;

            % Value labels
            hold(app.TIS_AxesComparison, 'on') ;
            vals = [X_cstr, X_tis, X_pfr] ;
            for idx = 1:3
                if vals(idx) > 0.85
                    ypos = vals(idx) - 0.06 ;
                    txtColor = [1 1 1] ;
                else
                    ypos = vals(idx) + 0.03 ;
                    txtColor = [0 0 0] ;
                end
                text(app.TIS_AxesComparison, idx, ypos, ...
                    sprintf('%.4f', vals(idx)), ...
                    'HorizontalAlignment', 'center', ...
                    'FontWeight', 'bold', 'FontSize', 10, ...
                    'Color', txtColor) ;
            end
            hold(app.TIS_AxesComparison, 'off') ;
        end

        %% ============== TAB 4: DISPERSION MODEL ==============

        function createDispersionTab(app)

            app.DispTab = uitab(app.TabGroup, 'Title', 'Dispersion Model') ;

            mainGrid = uigridlayout(app.DispTab, [1 2]) ;
            mainGrid.ColumnWidth = {320, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'Dispersion Configuration') ;
            leftGrid = uigridlayout(leftPanel, [17 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 17) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: Input method
            lbl = uilabel(leftGrid, 'Text', 'Input:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = 1 ;
            app.Disp_InputMethodDropdown = uidropdown(leftGrid, ...
                'Items', {'Manual', 'From calculated data'}, ...
                'Value', 'Manual', ...
                'ValueChangedFcn', @(~,~) app.Disp_inputMethodChanged()) ;
            app.Disp_InputMethodDropdown.Layout.Row = 1 ;
            app.Disp_InputMethodDropdown.Layout.Column = 2 ;

            % Row 2: Import status (hidden by default)
            app.Disp_RTDStatusLabel = uilabel(leftGrid, ...
                'Text', '', 'FontColor', [0 0.5 0]) ;
            app.Disp_RTDStatusLabel.Layout.Row = 2 ;
            app.Disp_RTDStatusLabel.Layout.Column = [1 2] ;
            app.Disp_RTDStatusLabel.Visible = 'off' ;

            % Row 3: Bo
            app.Disp_BoLabel = uilabel(leftGrid, 'Text', 'Bo (= De/uL):') ;
            app.Disp_BoLabel.Layout.Row = 3 ; app.Disp_BoLabel.Layout.Column = 1 ;
            app.Disp_BoLabel.FontWeight = 'bold' ;
            app.Disp_BoField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.025, 'Limits', [1e-6 100], ...
                'ValueChangedFcn', @(~,~) app.Disp_updatePe()) ;
            app.Disp_BoField.Layout.Row = 3 ; app.Disp_BoField.Layout.Column = 2 ;

            % Row 4: Pe display (read-only)
            lbl = uilabel(leftGrid, 'Text', 'Pe (= 1/Bo):') ;
            lbl.Layout.Row = 4 ; lbl.Layout.Column = 1 ;
            app.Disp_PeLabel = uilabel(leftGrid, 'Text', sprintf('%.2f', 1/0.025)) ;
            app.Disp_PeLabel.Layout.Row = 4 ; app.Disp_PeLabel.Layout.Column = 2 ;

            % Row 5: Boundary conditions
            app.Disp_BCLabel = uilabel(leftGrid, 'Text', 'Boundary:') ;
            app.Disp_BCLabel.Layout.Row = 5 ; app.Disp_BCLabel.Layout.Column = 1 ;
            app.Disp_BCDropdown = uidropdown(leftGrid, ...
                'Items', {'closed-closed', 'open-open'}, ...
                'Value', 'closed-closed') ;
            app.Disp_BCDropdown.Layout.Row = 5 ; app.Disp_BCDropdown.Layout.Column = 2 ;

            % Row 6: tau
            app.Disp_tauLabel = uilabel(leftGrid, 'Text', 'tau (s):') ;
            app.Disp_tauLabel.Layout.Row = 6 ; app.Disp_tauLabel.Layout.Column = 1 ;
            app.Disp_tauField = uieditfield(leftGrid, 'numeric', ...
                'Value', 10, 'Limits', [0.001 Inf]) ;
            app.Disp_tauField.Layout.Row = 6 ; app.Disp_tauField.Layout.Column = 2 ;

            % Row 7: Kinetics
            app.Disp_KineticsLabel = uilabel(leftGrid, 'Text', 'Kinetics:') ;
            app.Disp_KineticsLabel.Layout.Row = 7 ; app.Disp_KineticsLabel.Layout.Column = 1 ;
            app.Disp_KineticsLabel.FontWeight = 'bold' ;
            app.Disp_KineticsDropdown = uidropdown(leftGrid, ...
                'Items', {'1st Order (-rA = k*CA)', ...
                          '2nd Order (-rA = k*CA^2)'}, ...
                'Value', '1st Order (-rA = k*CA)', ...
                'ValueChangedFcn', @(~,~) app.Disp_kineticsChanged()) ;
            app.Disp_KineticsDropdown.Layout.Row = 7 ;
            app.Disp_KineticsDropdown.Layout.Column = 2 ;

            % Row 8: k
            app.Disp_kLabel = uilabel(leftGrid, 'Text', 'k (1/s):') ;
            app.Disp_kLabel.Layout.Row = 8 ; app.Disp_kLabel.Layout.Column = 1 ;
            app.Disp_kField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.1, 'Limits', [0 Inf]) ;
            app.Disp_kField.Layout.Row = 8 ; app.Disp_kField.Layout.Column = 2 ;

            % Row 9: CA0 (2nd order only)
            app.Disp_CA0Label = uilabel(leftGrid, 'Text', 'CA0 (mol/m^3):') ;
            app.Disp_CA0Label.Layout.Row = 9 ; app.Disp_CA0Label.Layout.Column = 1 ;
            app.Disp_CA0Label.Visible = 'off' ;
            app.Disp_CA0Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 1000, 'Limits', [0.001 Inf]) ;
            app.Disp_CA0Field.Layout.Row = 9 ; app.Disp_CA0Field.Layout.Column = 2 ;
            app.Disp_CA0Field.Visible = 'off' ;

            % Row 10: Compute button
            app.Disp_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Compute', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Disp_compute()) ;
            app.Disp_ComputeButton.Layout.Row = 10 ;
            app.Disp_ComputeButton.Layout.Column = [1 2] ;

            % Row 11: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 11 ; lbl.Layout.Column = [1 2] ;

            % Row 12: Da and Bo info
            lbl = uilabel(leftGrid, 'Text', 'Da / Bo:') ;
            lbl.Layout.Row = 12 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultBo = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultBo.Layout.Row = 12 ; app.Disp_ResultBo.Layout.Column = 2 ;

            % Row 13: X_dispersion
            lbl = uilabel(leftGrid, 'Text', 'X_dispersion:') ;
            lbl.Layout.Row = 13 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultX = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultX.Layout.Row = 13 ; app.Disp_ResultX.Layout.Column = 2 ;
            app.Disp_ResultX.FontWeight = 'bold' ;

            % Row 14: X_CSTR
            lbl = uilabel(leftGrid, 'Text', 'X_CSTR (Bo->inf):') ;
            lbl.Layout.Row = 14 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultXcstr = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultXcstr.Layout.Row = 14 ; app.Disp_ResultXcstr.Layout.Column = 2 ;

            % Row 15: X_PFR
            lbl = uilabel(leftGrid, 'Text', 'X_PFR (Bo->0):') ;
            lbl.Layout.Row = 15 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultXpfr = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultXpfr.Layout.Row = 15 ; app.Disp_ResultXpfr.Layout.Column = 2 ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Dispersion Results') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % E(t) plot
            app.Disp_AxesEt = uiaxes(plotGrid) ;
            title(app.Disp_AxesEt, 'E(t) - Dispersion') ;
            xlabel(app.Disp_AxesEt, 't (s)') ;
            ylabel(app.Disp_AxesEt, 'E(t) (1/s)') ;

            % X vs Bo sweep
            app.Disp_AxesXvsBo = uiaxes(plotGrid) ;
            title(app.Disp_AxesXvsBo, 'X vs Bo') ;
            xlabel(app.Disp_AxesXvsBo, 'Bo (dispersion number)') ;
            ylabel(app.Disp_AxesXvsBo, 'X_A') ;

            % Comparison bar chart (spans 2 columns)
            app.Disp_AxesComparison = uiaxes(plotGrid) ;
            app.Disp_AxesComparison.Layout.Column = [1 2] ;
            title(app.Disp_AxesComparison, 'PFR vs Dispersion vs CSTR') ;
            ylabel(app.Disp_AxesComparison, 'Conversion X') ;
        end

        %% ============== DISPERSION CALLBACKS ==============

        function Disp_updatePe(app)
            Bo = app.Disp_BoField.Value ;
            Pe = 1 / Bo ;
            app.Disp_PeLabel.Text = sprintf('%.2f', Pe) ;
        end

        function Disp_kineticsChanged(app)
            kinetics = app.Disp_KineticsDropdown.Value ;
            if contains(kinetics, '2nd')
                app.Disp_CA0Label.Visible = 'on' ;
                app.Disp_CA0Field.Visible = 'on' ;
                app.Disp_kLabel.Text = 'k (m^3/(mol*s)):' ;
            else
                app.Disp_CA0Label.Visible = 'off' ;
                app.Disp_CA0Field.Visible = 'off' ;
                app.Disp_kLabel.Text = 'k (1/s):' ;
            end
        end

        function Disp_inputMethodChanged(app)
            source = app.Disp_InputMethodDropdown.Value ;

            if contains(source, 'From calculated')
                % Disable manual fields and import data
                app.Disp_BoField.Enable = 'off' ;
                app.Disp_tauField.Enable = 'off' ;
                app.Disp_kField.Enable = 'off' ;
                app.Disp_KineticsDropdown.Enable = 'off' ;
                app.Disp_CA0Field.Enable = 'off' ;
                app.Disp_RTDStatusLabel.Visible = 'on' ;

                infoLines = {} ;

                % Import RTD data (tau, sigma2_theta -> Bo)
                if ~isempty(app.rtd) && app.rtd.sigma2 > 0
                    app.Disp_tauField.Value = app.rtd.tau ;
                    sigma2_theta = app.rtd.sigma2 / app.rtd.tau^2 ;
                    bcType = app.Disp_BCDropdown.Value ;

                    % Compute Bo from sigma2_theta
                    Bo_calc = app.compute_Bo_from_variance(sigma2_theta, bcType) ;
                    app.Disp_BoField.Value = Bo_calc ;
                    app.Disp_updatePe() ;

                    infoLines{end+1} = sprintf('RTD: tau=%.2f, sigma2_theta=%.4f, Bo=%.4g', ...
                        app.rtd.tau, sigma2_theta, Bo_calc) ;
                else
                    infoLines{end+1} = 'RTD: not loaded' ;
                end

                % Import kinetics from Prediction Models tab
                if ~isempty(app.Pred_kField) && app.Pred_kField.Value > 0
                    app.Disp_kField.Value = app.Pred_kField.Value ;
                    app.Disp_KineticsDropdown.Value = app.Pred_KineticsDropdown.Value ;
                    app.Disp_kineticsChanged() ;
                    if ~isempty(app.Pred_CA0Field)
                        app.Disp_CA0Field.Value = app.Pred_CA0Field.Value ;
                    end
                    infoLines{end+1} = sprintf('k=%.4g', app.Pred_kField.Value) ;
                end

                if any(contains(infoLines, 'not loaded'))
                    app.Disp_RTDStatusLabel.FontColor = [0.8 0 0] ;
                else
                    app.Disp_RTDStatusLabel.FontColor = [0 0.5 0] ;
                end
                app.Disp_RTDStatusLabel.Text = strjoin(infoLines, ' | ') ;
            else
                % Manual mode: re-enable all fields
                app.Disp_BoField.Enable = 'on' ;
                app.Disp_tauField.Enable = 'on' ;
                app.Disp_kField.Enable = 'on' ;
                app.Disp_KineticsDropdown.Enable = 'on' ;
                app.Disp_CA0Field.Enable = 'on' ;
                app.Disp_RTDStatusLabel.Visible = 'off' ;
            end
        end

        function Disp_compute(app)

            try
                Bo_val = app.Disp_BoField.Value ;
                bcType = app.Disp_BCDropdown.Value ;
                tau_val = app.Disp_tauField.Value ;
                k_val = app.Disp_kField.Value ;
                kinetics = app.Disp_KineticsDropdown.Value ;
                is2nd = contains(kinetics, '2nd') ;

                Da = k_val * tau_val ;

                % Create DispersionReactor
                app.disp_reactor = DispersionReactor(Bo_val, bcType) ;

                % Compute conversion
                if is2nd
                    CA0_val = app.Disp_CA0Field.Value ;
                    X_disp = app.disp_reactor.compute_conversion_secondOrder(k_val, CA0_val, tau_val) ;
                    order = 2 ;
                else
                    X_disp = app.disp_reactor.compute_conversion_firstOrder(k_val, tau_val) ;
                    CA0_val = 0 ;
                    order = 1 ;
                end

                % Reference: CSTR and PFR
                if order == 1
                    X_cstr = Da / (1 + Da) ;
                    X_pfr = 1 - exp(-Da) ;
                else
                    X_cstr = (-1 + sqrt(1 + 4*Da*CA0_val*k_val*tau_val)) / ...
                             (2 * k_val * CA0_val * tau_val) ;
                    % Simplified: for 2nd order CSTR: X = (-1+sqrt(1+4*Da))/(2*Da) with Da=k*CA0*tau
                    Da2 = k_val * CA0_val * tau_val ;
                    X_cstr = (-1 + sqrt(1 + 4*Da2)) / (2 * Da2) ;
                    X_pfr = Da2 / (1 + Da2) ;  % batch at t=tau
                end

                X_cstr = max(0, min(1, X_cstr)) ;
                X_pfr = max(0, min(1, X_pfr)) ;

                % Update results
                app.Disp_ResultBo.Text = sprintf('Da=%.4g, Bo=%.4g', Da, Bo_val) ;
                app.Disp_ResultX.Text = sprintf('%.4f', X_disp) ;
                app.Disp_ResultXcstr.Text = sprintf('%.4f', X_cstr) ;
                app.Disp_ResultXpfr.Text = sprintf('%.4f', X_pfr) ;

                % Update plots
                app.Disp_updatePlots(Bo_val, tau_val, k_val, CA0_val, ...
                                     order, X_disp, X_cstr, X_pfr) ;

            catch ME
                uialert(app.UIFigure, ME.message, 'Error in Dispersion Model') ;
            end
        end

        function Disp_updatePlots(app, Bo_val, tau_val, k_val, CA0_val, ...
                                  order, X_disp, X_cstr, X_pfr)

            % ---- Plot 1: E(t) ----
            cla(app.Disp_AxesEt) ;
            rtd_obj = app.disp_reactor.generate_RTD(tau_val) ;
            plot(app.Disp_AxesEt, rtd_obj.t, rtd_obj.Et, 'b-', 'LineWidth', 1.5) ;
            title(app.Disp_AxesEt, sprintf('E(t) - %s, Bo=%.4g', ...
                  app.Disp_BCDropdown.Value, Bo_val)) ;
            xlabel(app.Disp_AxesEt, 't (s)') ;
            ylabel(app.Disp_AxesEt, 'E(t) (1/s)') ;

            % Add equation annotation
            text(app.Disp_AxesEt, 0.95, 0.90, ...
                sprintf('Bo = %.4g\nPe = %.4g\n\\tau = %.4g s', ...
                        Bo_val, 1/Bo_val, tau_val), ...
                'Units', 'normalized', 'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'top', 'FontSize', 9, ...
                'Interpreter', 'tex', ...
                'BackgroundColor', [1 1 1 0.8], 'EdgeColor', [0.7 0.7 0.7]) ;

            % ---- Plot 2: X vs Bo sweep ----
            cla(app.Disp_AxesXvsBo) ;
            [Bo_sweep, X_sweep] = app.disp_reactor.sweep_Bo(k_val, tau_val, CA0_val, order) ;
            semilogx(app.Disp_AxesXvsBo, Bo_sweep, X_sweep, 'b-', 'LineWidth', 1.5) ;
            hold(app.Disp_AxesXvsBo, 'on') ;

            % Mark current Bo
            semilogx(app.Disp_AxesXvsBo, Bo_val, X_disp, 'rp', ...
                     'MarkerSize', 12, 'MarkerFaceColor', 'r') ;

            % Reference lines
            yline(app.Disp_AxesXvsBo, X_pfr, '--', 'PFR', ...
                  'Color', [0 0.6 0], 'LineWidth', 1, 'LabelHorizontalAlignment', 'left') ;
            yline(app.Disp_AxesXvsBo, X_cstr, '--', 'CSTR', ...
                  'Color', [0.8 0 0], 'LineWidth', 1, 'LabelHorizontalAlignment', 'left') ;
            hold(app.Disp_AxesXvsBo, 'off') ;

            title(app.Disp_AxesXvsBo, 'Conversion vs Bo') ;
            xlabel(app.Disp_AxesXvsBo, 'Bo (dispersion number)') ;
            ylabel(app.Disp_AxesXvsBo, 'X_A') ;
            ylim(app.Disp_AxesXvsBo, [0 1]) ;
            legend(app.Disp_AxesXvsBo, 'X(Bo)', sprintf('Bo=%.4g', Bo_val), ...
                   'Location', 'best') ;

            % ---- Plot 3: Comparison bar chart ----
            cla(app.Disp_AxesComparison) ;
            bar_data = [X_pfr ; X_disp ; X_cstr] ;
            b = bar(app.Disp_AxesComparison, bar_data) ;
            b.FaceColor = 'flat' ;
            b.CData = [0.3 0.8 0.3 ; 0.3 0.6 0.9 ; 0.9 0.3 0.3] ;
            set(app.Disp_AxesComparison, 'XTickLabel', ...
                {'PFR (Bo->0)', sprintf('Disp (Bo=%.3g)', Bo_val), 'CSTR (Bo->inf)'}) ;
            ylabel(app.Disp_AxesComparison, 'Conversion X') ;
            title(app.Disp_AxesComparison, 'PFR vs Dispersion vs CSTR') ;
            ylim(app.Disp_AxesComparison, [0 1.12]) ;

            % Value labels
            hold(app.Disp_AxesComparison, 'on') ;
            vals = [X_pfr, X_disp, X_cstr] ;
            for idx = 1:3
                if vals(idx) > 0.85
                    ypos = vals(idx) - 0.06 ;
                    txtColor = [1 1 1] ;
                else
                    ypos = vals(idx) + 0.03 ;
                    txtColor = [0 0 0] ;
                end
                text(app.Disp_AxesComparison, idx, ypos, ...
                    sprintf('%.4f', vals(idx)), ...
                    'HorizontalAlignment', 'center', ...
                    'FontWeight', 'bold', 'FontSize', 10, ...
                    'Color', txtColor) ;
            end
            hold(app.Disp_AxesComparison, 'off') ;
        end

    end

    methods (Static, Access = private)

        function Bo = compute_Bo_from_variance(sigma2_theta, bcType)
            % Compute Bodenstein number (Bo) from dimensionless variance
            %
            % For open-open BCs:
            %   sigma2_theta = 2*Bo  =>  Bo = sigma2_theta / 2
            %
            % For closed-closed BCs:
            %   sigma2_theta = 2*Bo - 2*Bo^2 * (1 - exp(-1/Bo))
            %   This cannot be solved analytically, so we use fzero
            %   with initial guess Bo0 = sigma2_theta / 2

            switch bcType
                case 'open-open'
                    Bo = sigma2_theta / 2 ;

                case 'closed-closed'
                    % Define f(Bo) = 2*Bo - 2*Bo^2*(1-exp(-1/Bo)) - sigma2_theta
                    f = @(Bo_val) 2*Bo_val - 2*Bo_val^2*(1 - exp(-1/Bo_val)) - sigma2_theta ;

                    % Initial guess from open-open approximation
                    Bo0 = sigma2_theta / 2 ;
                    if Bo0 < 1e-6
                        Bo0 = 1e-6 ;
                    end

                    try
                        Bo = fzero(f, Bo0) ;
                    catch
                        % Fallback: use approximation
                        Bo = Bo0 ;
                        warning('Could not solve for Bo. Using approximation Bo = sigma2_theta/2') ;
                    end

                    % Ensure positive
                    Bo = max(Bo, 1e-8) ;

                otherwise
                    Bo = sigma2_theta / 2 ;
            end
        end

    end
end
