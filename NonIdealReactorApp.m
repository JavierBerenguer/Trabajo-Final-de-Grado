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
        RTD_ResultTau
        RTD_ResultSigma2
        RTD_ResultSigma2Theta
        RTD_ResultS3
        RTD_ResultN
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
            leftGrid = uigridlayout(leftPanel, [17 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 17) ;
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

            % Row 3: N field (for Tanks-in-Series) — shares row with Bo
            app.RTD_NLabel = uilabel(leftGrid, 'Text', 'N (tanks):') ;
            app.RTD_NLabel.Layout.Row = 3 ; app.RTD_NLabel.Layout.Column = 1 ;
            app.RTD_NField = uieditfield(leftGrid, 'numeric', ...
                'Value', 3, 'Limits', [0.1 Inf]) ;
            app.RTD_NField.Layout.Row = 3 ; app.RTD_NField.Layout.Column = 2 ;
            app.RTD_NLabel.Visible = 'off' ;
            app.RTD_NField.Visible = 'off' ;

            % Row 3: Bo field (for Dispersion) — overlaps with N (only one visible)
            app.RTD_BoLabel = uilabel(leftGrid, 'Text', 'Bo (De/uL):') ;
            app.RTD_BoLabel.Layout.Row = 3 ; app.RTD_BoLabel.Layout.Column = 1 ;
            app.RTD_BoField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.01, 'Limits', [1e-6 Inf]) ;
            app.RTD_BoField.Layout.Row = 3 ; app.RTD_BoField.Layout.Column = 2 ;
            app.RTD_BoLabel.Visible = 'off' ;
            app.RTD_BoField.Visible = 'off' ;

            % Row 4: Experimental t variable
            app.RTD_ExpTVarLabel = uilabel(leftGrid, 'Text', 't variable (workspace):') ;
            app.RTD_ExpTVarLabel.Layout.Row = 4 ; app.RTD_ExpTVarLabel.Layout.Column = 1 ;
            app.RTD_ExpTVarField = uieditfield(leftGrid, 'text', ...
                'Value', 't_exp') ;
            app.RTD_ExpTVarField.Layout.Row = 4 ; app.RTD_ExpTVarField.Layout.Column = 2 ;
            app.RTD_ExpTVarLabel.Visible = 'off' ;
            app.RTD_ExpTVarField.Visible = 'off' ;

            % Row 5: Experimental C variable
            app.RTD_ExpCVarLabel = uilabel(leftGrid, 'Text', 'C variable (workspace):') ;
            app.RTD_ExpCVarLabel.Layout.Row = 5 ; app.RTD_ExpCVarLabel.Layout.Column = 1 ;
            app.RTD_ExpCVarField = uieditfield(leftGrid, 'text', ...
                'Value', 'C_exp') ;
            app.RTD_ExpCVarField.Layout.Row = 5 ; app.RTD_ExpCVarField.Layout.Column = 2 ;
            app.RTD_ExpCVarLabel.Visible = 'off' ;
            app.RTD_ExpCVarField.Visible = 'off' ;

            % Row 6: C0 (step only)
            app.RTD_ExpC0Label = uilabel(leftGrid, 'Text', 'C0 (step only):') ;
            app.RTD_ExpC0Label.Layout.Row = 6 ; app.RTD_ExpC0Label.Layout.Column = 1 ;
            app.RTD_ExpC0Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 1, 'Limits', [0 Inf]) ;
            app.RTD_ExpC0Field.Layout.Row = 6 ; app.RTD_ExpC0Field.Layout.Column = 2 ;
            app.RTD_ExpC0Label.Visible = 'off' ;
            app.RTD_ExpC0Field.Visible = 'off' ;

            % Row 7: Import from file button (for experimental data)
            app.RTD_ImportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Import experimental data', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [1 1 1], ...
                'FontColor', [0.8 0 0], ...
                'ButtonPushedFcn', @(~,~) app.RTD_importFromFile()) ;
            app.RTD_ImportButton.Layout.Row = 7 ;
            app.RTD_ImportButton.Layout.Column = [1 2] ;
            app.RTD_ImportButton.Visible = 'off' ;

            % Row 8: Import status label
            app.RTD_ImportLabel = uilabel(leftGrid, 'Text', '') ;
            app.RTD_ImportLabel.Layout.Row = 8 ;
            app.RTD_ImportLabel.Layout.Column = [1 2] ;
            app.RTD_ImportLabel.FontColor = [0 0.5 0] ;
            app.RTD_ImportLabel.Visible = 'off' ;

            % Rows 3-6: Custom equation fields (for C(t) Equation)
            % These share rows with N/Bo and Exp fields (never visible at same time)
            app.RTD_EqLabel = uilabel(leftGrid, 'Text', 'C(t) =') ;
            app.RTD_EqLabel.Layout.Row = 3 ; app.RTD_EqLabel.Layout.Column = 1 ;
            app.RTD_EqLabel.FontWeight = 'bold' ;
            app.RTD_EqLabel.Visible = 'off' ;

            app.RTD_EqField = uieditfield(leftGrid, 'text', ...
                'Value', '5*exp(-2.5*t)', ...
                'Tooltip', 'Use "t" as variable. Example: 5*exp(-2.5*t)') ;
            app.RTD_EqField.Layout.Row = 3 ; app.RTD_EqField.Layout.Column = 2 ;
            app.RTD_EqField.Visible = 'off' ;

            app.RTD_EqTStartLabel = uilabel(leftGrid, 'Text', 't start:') ;
            app.RTD_EqTStartLabel.Layout.Row = 4 ; app.RTD_EqTStartLabel.Layout.Column = 1 ;
            app.RTD_EqTStartLabel.Visible = 'off' ;
            app.RTD_EqTStartField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0, 'Limits', [0 Inf]) ;
            app.RTD_EqTStartField.Layout.Row = 4 ; app.RTD_EqTStartField.Layout.Column = 2 ;
            app.RTD_EqTStartField.Visible = 'off' ;

            app.RTD_EqTEndLabel = uilabel(leftGrid, 'Text', 't end:') ;
            app.RTD_EqTEndLabel.Layout.Row = 5 ; app.RTD_EqTEndLabel.Layout.Column = 1 ;
            app.RTD_EqTEndLabel.Visible = 'off' ;
            app.RTD_EqTEndField = uieditfield(leftGrid, 'numeric', ...
                'Value', 10, 'Limits', [0.001 Inf]) ;
            app.RTD_EqTEndField.Layout.Row = 5 ; app.RTD_EqTEndField.Layout.Column = 2 ;
            app.RTD_EqTEndField.Visible = 'off' ;

            app.RTD_EqNptsLabel = uilabel(leftGrid, 'Text', 'N points:') ;
            app.RTD_EqNptsLabel.Layout.Row = 6 ; app.RTD_EqNptsLabel.Layout.Column = 1 ;
            app.RTD_EqNptsLabel.Visible = 'off' ;
            app.RTD_EqNptsField = uieditfield(leftGrid, 'numeric', ...
                'Value', 500, 'Limits', [10 10000]) ;
            app.RTD_EqNptsField.Layout.Row = 6 ; app.RTD_EqNptsField.Layout.Column = 2 ;
            app.RTD_EqNptsField.Visible = 'off' ;

            % Row 9: Generate button
            app.RTD_GenerateButton = uibutton(leftGrid, 'push', ...
                'Text', 'Generate RTD', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.RTD_generate()) ;
            app.RTD_GenerateButton.Layout.Row = 9 ;
            app.RTD_GenerateButton.Layout.Column = [1 2] ;

            % Row 10: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 10 ; lbl.Layout.Column = [1 2] ;

            % Row 11: tau_m
            lbl = uilabel(leftGrid, 'Text', 'tau_m (s):') ;
            lbl.Layout.Row = 11 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultTau = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultTau.Layout.Row = 11 ;
            app.RTD_ResultTau.Layout.Column = 2 ;

            % Row 12: sigma^2
            lbl = uilabel(leftGrid, 'Text', 'sigma^2 (s^2):') ;
            lbl.Layout.Row = 12 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultSigma2 = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultSigma2.Layout.Row = 12 ;
            app.RTD_ResultSigma2.Layout.Column = 2 ;

            % Row 13: sigma^2_theta
            lbl = uilabel(leftGrid, 'Text', 'sigma^2_theta:') ;
            lbl.Layout.Row = 13 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultSigma2Theta = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultSigma2Theta.Layout.Row = 13 ;
            app.RTD_ResultSigma2Theta.Layout.Column = 2 ;

            % Row 14: s^3
            lbl = uilabel(leftGrid, 'Text', 's^3 (skewness):') ;
            lbl.Layout.Row = 14 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultS3 = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultS3.Layout.Row = 14 ;
            app.RTD_ResultS3.Layout.Column = 2 ;

            % Row 15: N_est
            lbl = uilabel(leftGrid, 'Text', 'N_est (= tau^2/sigma^2):') ;
            lbl.Layout.Row = 15 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultN = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultN.Layout.Row = 15 ;
            app.RTD_ResultN.Layout.Column = 2 ;

            % Row 16: Export name
            lbl = uilabel(leftGrid, 'Text', 'Export name:') ;
            lbl.Layout.Row = 16 ; lbl.Layout.Column = 1 ;
            app.RTD_ExportNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'RTD_1') ;
            app.RTD_ExportNameField.Layout.Row = 16 ;
            app.RTD_ExportNameField.Layout.Column = 2 ;

            % Row 17: Export button
            app.RTD_ExportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Export RTD to Workspace', ...
                'BackgroundColor', [0.2 0.7 0.3], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.RTD_export()) ;
            app.RTD_ExportButton.Layout.Row = 17 ;
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
            grid(app.RTD_AxesEt, 'on') ;

            % F(t) plot
            app.RTD_AxesFt = uiaxes(plotGrid) ;
            title(app.RTD_AxesFt, 'F(t)') ;
            xlabel(app.RTD_AxesFt, 't (s)') ;
            ylabel(app.RTD_AxesFt, 'F(t)') ;
            grid(app.RTD_AxesFt, 'on') ;

            % E(theta) plot
            app.RTD_AxesEtheta = uiaxes(plotGrid) ;
            title(app.RTD_AxesEtheta, 'E(\Theta)') ;
            xlabel(app.RTD_AxesEtheta, '\Theta = t/\tau') ;
            ylabel(app.RTD_AxesEtheta, 'E(\Theta)') ;
            grid(app.RTD_AxesEtheta, 'on') ;

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
        end

        function RTD_updatePlots(app)
            % Update all three RTD plots

            if isempty(app.rtd)
                return
            end

            % E(t) plot
            cla(app.RTD_AxesEt) ;
            plot(app.RTD_AxesEt, app.rtd.t, app.rtd.Et, 'b-', 'LineWidth', 1.5) ;
            title(app.RTD_AxesEt, 'E(t)') ;
            xlabel(app.RTD_AxesEt, 't (s)') ;
            ylabel(app.RTD_AxesEt, 'E(t) (1/s)') ;
            grid(app.RTD_AxesEt, 'on') ;

            % F(t) plot
            cla(app.RTD_AxesFt) ;
            plot(app.RTD_AxesFt, app.rtd.t, app.rtd.Ft, 'r-', 'LineWidth', 1.5) ;
            title(app.RTD_AxesFt, 'F(t)') ;
            xlabel(app.RTD_AxesFt, 't (s)') ;
            ylabel(app.RTD_AxesFt, 'F(t)') ;
            grid(app.RTD_AxesFt, 'on') ;
            ylim(app.RTD_AxesFt, [0 1.05]) ;

            % E(theta) plot
            cla(app.RTD_AxesEtheta) ;
            if ~isempty(app.rtd.theta) && ~isempty(app.rtd.Etheta)
                plot(app.RTD_AxesEtheta, app.rtd.theta, app.rtd.Etheta, ...
                     'Color', [0 0.6 0], 'LineWidth', 1.5) ;
            end
            title(app.RTD_AxesEtheta, 'E(\Theta)') ;
            xlabel(app.RTD_AxesEtheta, '\Theta = t/\tau') ;
            ylabel(app.RTD_AxesEtheta, 'E(\Theta)') ;
            grid(app.RTD_AxesEtheta, 'on') ;
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
                'Items', {'Manual', 'From RTD (Tab 1)'}, ...
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
            if contains(source, 'From RTD')
                % Auto-compute N from RTD variance
                app.TIS_NField.Enable = 'off' ;
                app.TIS_RTDStatusLabel.Visible = 'on' ;
                if ~isempty(app.rtd) && app.rtd.sigma2 > 0
                    N_from_rtd = app.rtd.tau^2 / app.rtd.sigma2 ;
                    app.TIS_NField.Value = N_from_rtd ;
                    app.TIS_RTDStatusLabel.Text = sprintf( ...
                        'RTD: tau=%.2f, sigma2=%.2f -> N=%.2f', ...
                        app.rtd.tau, app.rtd.sigma2, N_from_rtd) ;
                    app.TIS_RTDStatusLabel.FontColor = [0 0.5 0] ;
                    app.TIS_tauField.Value = app.rtd.tau ;
                else
                    app.TIS_RTDStatusLabel.Text = 'RTD: not loaded (generate in Tab 1)' ;
                    app.TIS_RTDStatusLabel.FontColor = [0.8 0 0] ;
                end
            else
                app.TIS_NField.Enable = 'on' ;
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

    end
end
