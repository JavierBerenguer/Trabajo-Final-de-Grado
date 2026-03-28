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
        UnitConvButton

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
        RTD_VtotalLabel         % Label for V_total input
        RTD_VtotalField         % V_total numeric input field
        RTD_ResultVdead         % Dead volume result label
        RTD_DataTable           % uitable for direct data entry
        RTD_AddRowButton        % Button to add a row
        RTD_RemoveRowButton     % Button to remove last row
        RTD_DataTypeDropdown    % Dropdown: 'Pulse C(t)' or 'Step C(t)'
        RTD_DataTypeLabel
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
        Pred_aField             % Parameter a (MM) or k_fwd (reversible)
        Pred_aLabel
        Pred_bField             % Parameter b (MM) or k_rev (reversible)
        Pred_bLabel
        Pred_k2Field            % k2 for parallel reactions
        Pred_k2Label
        Pred_n1Field            % Order n1 for parallel
        Pred_n1Label
        Pred_n2Field            % Order n2 for parallel
        Pred_n2Label
        Pred_CustomRateField    % Custom rate law text
        Pred_CustomRateLabel
        Pred_ResultSelectLabel  % Selectivity result for parallel
        Pred_ResultYieldLabel   % Yield result for parallel

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

        % ---- Tab 5: Convolution / Deconvolution ----
        ConvTab
        Conv_ModeDropdown
        Conv_InputDropdown
        Conv_tVarField
        Conv_tVarLabel
        Conv_CinVarField
        Conv_CinVarLabel
        Conv_EVarField
        Conv_EVarLabel
        Conv_CoutVarField
        Conv_CoutVarLabel
        Conv_nEField
        Conv_nELabel
        Conv_ImportButton
        Conv_ImportLabel
        Conv_ComputeButton
        Conv_ExportButton
        Conv_ExportNameField
        Conv_ResultLabel
        Conv_AxesInput
        Conv_AxesResult
        Conv_AxesRecovered

        % ---- Tab 6: Combined Models ----
        CombTab
        Comb_ModelDropdown
        Comb_tauField
        Comb_Param1Label
        Comb_Param1Field
        Comb_Param2Label
        Comb_Param2Field
        Comb_KineticsDropdown
        Comb_kField
        Comb_kLabel
        Comb_CA0Field
        Comb_CA0Label
        Comb_ComputeButton
        Comb_ResultX
        Comb_ResultXcstr
        Comb_ResultXpfr
        Comb_ResultParams
        Comb_AxesEt
        Comb_AxesComparison
        Comb_AxesSensitivity
        Comb_ModelDescLabel

        % ---- Tab 7: Optimization ----
        OptTab
        Opt_DataSourceDropdown
        Opt_tVarField
        Opt_tVarLabel
        Opt_EtVarField
        Opt_EtVarLabel
        Opt_ImportButton
        Opt_ImportLabel
        Opt_tauLabel              % Shows tau of loaded data
        Opt_CheckTIS              % Checkbox: Tanks-in-Series
        Opt_CheckDispOpen         % Checkbox: Dispersion open-open
        Opt_CheckDispClosed       % Checkbox: Dispersion closed-closed
        Opt_CheckDeadVol          % Checkbox: CSTR + Dead Volume
        Opt_CheckBypass           % Checkbox: CSTR + Bypass
        Opt_CheckBypassDead       % Checkbox: CSTR + Bypass + Dead Vol
        Opt_FitButton
        Opt_ResultTable           % uitable for results
        Opt_ResultBestLabel
        Opt_AxesDataFit           % Data + fitted curves overlay
        Opt_AxesResiduals         % Residuals plot
        Opt_AxesComparison        % R^2 bar chart
        opt_exp_t                 % Experimental time vector (stored)
        opt_exp_Et                % Experimental E(t) (stored)
        opt_exp_tau               % Experimental tau (stored)
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

            % Unit Converter button (accessible from any tab)
            app.UnitConvButton = uibutton(app.UIFigure, 'push', ...
                'Text', 'Unit Converter', ...
                'Position', [1070 718 120 28], ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', [1 1 1], ...
                'ButtonPushedFcn', @(~,~) UnitConverterHelper.launch()) ;

            % Build tabs
            app.createRTDTab() ;
            app.createPredictionTab() ;
            app.createTISTab() ;
            app.createDispersionTab() ;
            app.createConvolutionTab() ;
            app.createCombinedTab() ;
            app.createOptimizationTab() ;

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
            leftPanel = uipanel(mainGrid, 'Title', 'Configuracion RTD') ;
            leftGrid = uigridlayout(leftPanel, [30 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 30) ;
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
                          'Laminar Flow', ...
                          'Experimental Pulse', 'Experimental Step', ...
                          'C(t) Equation', 'Tabular Input'}, ...
                'Value', 'Ideal CSTR', ...
                'ValueChangedFcn', @(~,~) app.RTD_sourceChanged()) ;
            app.RTD_SourceDropdown.Layout.Row = 1 ;
            app.RTD_SourceDropdown.Layout.Column = 2 ;

            % Row 2: Tau field
            lbl = uilabel(leftGrid, 'Text', 'tau [s]:') ;
            lbl.Layout.Row = 2 ; lbl.Layout.Column = 1 ;
            app.RTD_TauField = uieditfield(leftGrid, 'numeric', ...
                'Value', 10, 'Limits', [0.001 Inf]) ;
            app.RTD_TauField.Layout.Row = 2 ;
            app.RTD_TauField.Layout.Column = 2 ;

            % Row 3: Qv (volumetric flow rate) — always visible
            app.RTD_QvLabel = uilabel(leftGrid, 'Text', 'Qv [m^3/s]:') ;
            app.RTD_QvLabel.Layout.Row = 3 ; app.RTD_QvLabel.Layout.Column = 1 ;
            app.RTD_QvField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.001, 'Limits', [1e-12 Inf]) ;
            app.RTD_QvField.Layout.Row = 3 ; app.RTD_QvField.Layout.Column = 2 ;

            % Row 4: N field (for Tanks-in-Series) — shares row with Bo
            app.RTD_NLabel = uilabel(leftGrid, 'Text', 'N [tanks]:') ;
            app.RTD_NLabel.Layout.Row = 4 ; app.RTD_NLabel.Layout.Column = 1 ;
            app.RTD_NField = uieditfield(leftGrid, 'numeric', ...
                'Value', 3, 'Limits', [0.1 Inf]) ;
            app.RTD_NField.Layout.Row = 4 ; app.RTD_NField.Layout.Column = 2 ;
            app.RTD_NLabel.Visible = 'off' ;
            app.RTD_NField.Visible = 'off' ;

            % Row 4: Bo field (for Dispersion) — overlaps with N (only one visible)
            app.RTD_BoLabel = uilabel(leftGrid, 'Text', 'Bo [De/uL]:') ;
            app.RTD_BoLabel.Layout.Row = 4 ; app.RTD_BoLabel.Layout.Column = 1 ;
            app.RTD_BoField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.01, 'Limits', [1e-6 Inf], ...
                'Tooltip', 'Numero de dispersion Bo = De/(u*L). Bo->0: flujo piston, Bo->inf: mezcla perfecta.') ;
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
            app.RTD_ExpC0Label = uilabel(leftGrid, 'Text', 'C0 [mol/m^3] (step):') ;
            app.RTD_ExpC0Label.Layout.Row = 7 ; app.RTD_ExpC0Label.Layout.Column = 1 ;
            app.RTD_ExpC0Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 1, 'Limits', [0 Inf]) ;
            app.RTD_ExpC0Field.Layout.Row = 7 ; app.RTD_ExpC0Field.Layout.Column = 2 ;
            app.RTD_ExpC0Label.Visible = 'off' ;
            app.RTD_ExpC0Field.Visible = 'off' ;

            % Row 8: Import from file button (for experimental data)
            app.RTD_ImportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Importar datos experimentales', ...
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

            app.RTD_EqTStartLabel = uilabel(leftGrid, 'Text', 't start [s]:') ;
            app.RTD_EqTStartLabel.Layout.Row = 5 ; app.RTD_EqTStartLabel.Layout.Column = 1 ;
            app.RTD_EqTStartLabel.Visible = 'off' ;
            app.RTD_EqTStartField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0, 'Limits', [0 Inf]) ;
            app.RTD_EqTStartField.Layout.Row = 5 ; app.RTD_EqTStartField.Layout.Column = 2 ;
            app.RTD_EqTStartField.Visible = 'off' ;

            app.RTD_EqTEndLabel = uilabel(leftGrid, 'Text', 't end [s]:') ;
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
            lbl = uilabel(leftGrid, 'Text', 'Resultados:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 11 ; lbl.Layout.Column = [1 2] ;

            % Row 12: tau_m
            lbl = uilabel(leftGrid, 'Text', 'tau_m [s]:') ;
            lbl.Layout.Row = 12 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultTau = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultTau.Layout.Row = 12 ;
            app.RTD_ResultTau.Layout.Column = 2 ;

            % Row 13: sigma^2
            lbl = uilabel(leftGrid, 'Text', 'sigma^2 [s^2]:') ;
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
            lbl = uilabel(leftGrid, 'Text', 's^3 [skewness]:') ;
            lbl.Layout.Row = 15 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultS3 = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultS3.Layout.Row = 15 ;
            app.RTD_ResultS3.Layout.Column = 2 ;

            % Row 16: N_est
            lbl = uilabel(leftGrid, 'Text', 'N_est [= tau^2/sigma^2]:') ;
            lbl.Layout.Row = 16 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultN = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultN.Layout.Row = 16 ;
            app.RTD_ResultN.Layout.Column = 2 ;

            % Row 17: V_eff
            lbl = uilabel(leftGrid, 'Text', 'V_eff [m^3]:') ;
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
                'Text', 'Exportar RTD a Workspace', ...
                'BackgroundColor', [0.2 0.7 0.3], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.RTD_export()) ;
            app.RTD_ExportButton.Layout.Row = 19 ;
            app.RTD_ExportButton.Layout.Column = [1 2] ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Graficas RTD') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % E(t) plot
            app.RTD_AxesEt = uiaxes(plotGrid) ;
            title(app.RTD_AxesEt, 'E(t)') ;
            xlabel(app.RTD_AxesEt, 't [s]') ;
            ylabel(app.RTD_AxesEt, 'E(t) [1/s]') ;

            % F(t) plot
            app.RTD_AxesFt = uiaxes(plotGrid) ;
            title(app.RTD_AxesFt, 'F(t)') ;
            xlabel(app.RTD_AxesFt, 't [s]') ;
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

                case 'Laminar Flow'
                    % Only tau is needed (default visible)

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

                    case 'Laminar Flow'
                        tau_val = app.RTD_TauField.Value ;
                        app.rtd = RTD.laminar_flow(tau_val) ;

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
                            error('Error al evaluar la ecuación "%s": %s', ...
                                eq_str, evalErr.message) ;
                        end

                        % Validate result
                        if ~isnumeric(C_data) || length(C_data) ~= length(t)
                            error('La ecuación debe devolver un vector numérico del mismo tamaño que t. Verifica que uses operadores elemento a elemento (.*  ./  .^)') ;
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
                uialert(app.UIFigure, ME.message, 'Error generando RTD') ;
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
            xlabel(app.RTD_AxesEt, 't [s]') ;
            ylabel(app.RTD_AxesEt, 'E(t) [1/s]') ;
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
            xlabel(app.RTD_AxesFt, 't [s]') ;
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

                case 'Laminar Flow'
                    tau = app.rtd.tau ;
                    eq_Et = sprintf('E(t) = \\tau^2/(2t^3), t >= \\tau/2, \\tau = %.4g s', tau) ;
                    eq_Ft = 'F(t) = 1 - (\\tau/2t)^2' ;
                    eq_Etheta = 'E(\\theta) = 1/(2\\theta^3), \\theta >= 0.5' ;

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
                uialert(app.UIFigure, 'No hay RTD para exportar. Genera una primero.', 'Advertencia') ;
                return
            end

            varName = app.RTD_ExportNameField.Value ;

            % Validate variable name
            if ~isvarname(varName)
                uialert(app.UIFigure, ...
                    sprintf('"%s" no es un nombre de variable MATLAB válido.', varName), ...
                    'Nombre inválido') ;
                return
            end

            assignin('base', varName, app.rtd) ;
            uialert(app.UIFigure, ...
                sprintf('RTD exportada al workspace como "%s"', varName), ...
                'Exportación exitosa', 'Icon', 'success') ;

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
                        'El archivo debe tener al menos 2 columnas (t y C).', ...
                        'Error de importación') ;
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
                uialert(app.UIFigure, ME.message, 'Error de importación') ;
            end
        end

        %% ============== TAB 2: PREDICTION MODELS ==============
        function createPredictionTab(app)

            app.PredTab = uitab(app.TabGroup, 'Title', 'Prediction Models') ;

            % Main grid: left panel (controls) + right panel (plots)
            mainGrid = uigridlayout(app.PredTab, [1 2]) ;
            mainGrid.ColumnWidth = {320, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'Limites de conversion') ;
            leftGrid = uigridlayout(leftPanel, [26 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 26) ;
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
            uilabel(leftGrid, 'Text', 'Cinetica:', ...
                'FontWeight', 'bold') ;
            app.Pred_KineticsDropdown = uidropdown(leftGrid, ...
                'Items', {'1er Orden: -rA = k*CA', ...
                          '2do Orden: -rA = k*CA^2', ...
                          'Michaelis-Menten: -rA = a*CA/(1+b*CA)', ...
                          'Reversible 1er Orden: A <-> B', ...
                          'Paralelas: A->B + A->C', ...
                          'Ley cinetica personalizada'}, ...
                'Value', '1er Orden: -rA = k*CA', ...
                'ValueChangedFcn', @(~,~) app.Pred_kineticsChanged()) ;

            % k field
            app.Pred_kLabel = uilabel(leftGrid, 'Text', 'k [1/s]:') ;
            app.Pred_kField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.1, 'Limits', [0 Inf], ...
                'Tooltip', 'Constante cinetica. Unidades dependen del orden: 1/s (1er orden), m^3/(mol*s) (2do orden).') ;

            % CA0 field (only for 2nd order)
            app.Pred_CA0Label = uilabel(leftGrid, 'Text', 'CA0 [mol/m^3]:') ;
            app.Pred_CA0Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 1000, 'Limits', [0.001 Inf], ...
                'Tooltip', 'Concentracion inicial del reactivo limitante en la alimentacion.') ;
            app.Pred_CA0Label.Visible = 'off' ;
            app.Pred_CA0Field.Visible = 'off' ;

            % --- Michaelis-Menten / Reversible parameters ---
            app.Pred_aLabel = uilabel(leftGrid, 'Text', 'a [1/s]:', 'Visible', 'off') ;
            app.Pred_aLabel.Layout.Row = 5 ; app.Pred_aLabel.Layout.Column = 1 ;
            app.Pred_aField = uieditfield(leftGrid, 'numeric', 'Value', 1, 'Visible', 'off', ...
                'Tooltip', 'Velocidad maxima de reaccion (Vmax/Km para Michaelis-Menten, k_directa para reversible).') ;
            app.Pred_aField.Layout.Row = 5 ; app.Pred_aField.Layout.Column = 2 ;

            app.Pred_bLabel = uilabel(leftGrid, 'Text', 'b [m^3/mol]:', 'Visible', 'off') ;
            app.Pred_bLabel.Layout.Row = 6 ; app.Pred_bLabel.Layout.Column = 1 ;
            app.Pred_bField = uieditfield(leftGrid, 'numeric', 'Value', 0.5, 'Visible', 'off', ...
                'Tooltip', 'Parametro de saturacion (1/Km para Michaelis-Menten, k_inversa para reversible).') ;
            app.Pred_bField.Layout.Row = 6 ; app.Pred_bField.Layout.Column = 2 ;

            % --- Parallel reaction parameters ---
            app.Pred_k2Label = uilabel(leftGrid, 'Text', 'k2 [1/s]:', 'Visible', 'off') ;
            app.Pred_k2Label.Layout.Row = 7 ; app.Pred_k2Label.Layout.Column = 1 ;
            app.Pred_k2Field = uieditfield(leftGrid, 'numeric', 'Value', 0.1, 'Visible', 'off') ;
            app.Pred_k2Field.Layout.Row = 7 ; app.Pred_k2Field.Layout.Column = 2 ;

            app.Pred_n1Label = uilabel(leftGrid, 'Text', 'n1 [order]:', 'Visible', 'off') ;
            app.Pred_n1Label.Layout.Row = 8 ; app.Pred_n1Label.Layout.Column = 1 ;
            app.Pred_n1Field = uieditfield(leftGrid, 'numeric', 'Value', 2, 'Visible', 'off') ;
            app.Pred_n1Field.Layout.Row = 8 ; app.Pred_n1Field.Layout.Column = 2 ;

            app.Pred_n2Label = uilabel(leftGrid, 'Text', 'n2 [order]:', 'Visible', 'off') ;
            app.Pred_n2Label.Layout.Row = 9 ; app.Pred_n2Label.Layout.Column = 1 ;
            app.Pred_n2Field = uieditfield(leftGrid, 'numeric', 'Value', 1, 'Visible', 'off') ;
            app.Pred_n2Field.Layout.Row = 9 ; app.Pred_n2Field.Layout.Column = 2 ;

            % --- Custom rate law ---
            app.Pred_CustomRateLabel = uilabel(leftGrid, 'Text', '-rA = f(CA):', 'Visible', 'off') ;
            app.Pred_CustomRateLabel.Layout.Row = 10 ; app.Pred_CustomRateLabel.Layout.Column = 1 ;
            app.Pred_CustomRateField = uieditfield(leftGrid, 'text', 'Value', '0.5*CA/(1+0.5*CA)', 'Visible', 'off') ;
            app.Pred_CustomRateField.Layout.Row = 10 ; app.Pred_CustomRateField.Layout.Column = 2 ;

            % Spacer
            uilabel(leftGrid, 'Text', '') ;
            uilabel(leftGrid, 'Text', '') ;

            % Compute button
            app.Pred_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Calcular', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Pred_compute()) ;
            app.Pred_ComputeButton.Layout.Column = [1 2] ;

            % Spacer
            uilabel(leftGrid, 'Text', '') ;
            uilabel(leftGrid, 'Text', '') ;

            % Results panel
            uilabel(leftGrid, 'Text', 'Resultados:', ...
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

            % Selectivity/Yield results (parallel reactions)
            app.Pred_ResultSelectLabel = uilabel(leftGrid, 'Text', '', 'Visible', 'off') ;
            app.Pred_ResultSelectLabel.Layout.Column = [1 2] ;
            app.Pred_ResultYieldLabel = uilabel(leftGrid, 'Text', '', 'Visible', 'off') ;
            app.Pred_ResultYieldLabel.Layout.Column = [1 2] ;

            % Spacer rows
            uilabel(leftGrid, 'Text', '') ;
            uilabel(leftGrid, 'Text', '') ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Resultados del modelo') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % X_batch(t) plot (Segregation)
            app.Pred_AxesXbatch = uiaxes(plotGrid) ;
            title(app.Pred_AxesXbatch, 'Batch Conversion X(t)') ;
            xlabel(app.Pred_AxesXbatch, 't [s]') ;
            ylabel(app.Pred_AxesXbatch, 'X_{batch}(t)') ;
            grid(app.Pred_AxesXbatch, 'on') ;

            % Integrand plot (Segregation)
            app.Pred_AxesIntegrand = uiaxes(plotGrid) ;
            title(app.Pred_AxesIntegrand, 'Integrand X(t)*E(t)') ;
            xlabel(app.Pred_AxesIntegrand, 't [s]') ;
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
            % Show/hide fields based on kinetics selection

            kinetics = app.Pred_KineticsDropdown.Value ;

            % Hide all optional fields first
            app.Pred_kLabel.Visible = 'on' ; app.Pred_kField.Visible = 'on' ;
            app.Pred_CA0Label.Visible = 'off' ; app.Pred_CA0Field.Visible = 'off' ;
            app.Pred_aLabel.Visible = 'off' ; app.Pred_aField.Visible = 'off' ;
            app.Pred_bLabel.Visible = 'off' ; app.Pred_bField.Visible = 'off' ;
            app.Pred_k2Label.Visible = 'off' ; app.Pred_k2Field.Visible = 'off' ;
            app.Pred_n1Label.Visible = 'off' ; app.Pred_n1Field.Visible = 'off' ;
            app.Pred_n2Label.Visible = 'off' ; app.Pred_n2Field.Visible = 'off' ;
            app.Pred_CustomRateLabel.Visible = 'off' ; app.Pred_CustomRateField.Visible = 'off' ;
            app.Pred_ResultSelectLabel.Visible = 'off' ;
            app.Pred_ResultYieldLabel.Visible = 'off' ;

            if contains(kinetics, '2do Orden')
                app.Pred_CA0Label.Visible = 'on' ;
                app.Pred_CA0Field.Visible = 'on' ;
                app.Pred_kLabel.Text = 'k [m^3/(mol·s)]:' ;
            elseif contains(kinetics, 'Michaelis')
                app.Pred_kLabel.Visible = 'off' ; app.Pred_kField.Visible = 'off' ;
                app.Pred_CA0Label.Visible = 'on' ; app.Pred_CA0Field.Visible = 'on' ;
                app.Pred_aLabel.Visible = 'on' ; app.Pred_aField.Visible = 'on' ;
                app.Pred_bLabel.Visible = 'on' ; app.Pred_bField.Visible = 'on' ;
                app.Pred_aLabel.Text = 'a [1/s]:' ;
                app.Pred_bLabel.Text = 'b [m^3/mol]:' ;
            elseif contains(kinetics, 'Reversible')
                app.Pred_kLabel.Visible = 'off' ; app.Pred_kField.Visible = 'off' ;
                app.Pred_CA0Label.Visible = 'on' ; app.Pred_CA0Field.Visible = 'on' ;
                app.Pred_aLabel.Visible = 'on' ; app.Pred_aField.Visible = 'on' ;
                app.Pred_bLabel.Visible = 'on' ; app.Pred_bField.Visible = 'on' ;
                app.Pred_aLabel.Text = 'k_fwd [1/s]:' ;
                app.Pred_bLabel.Text = 'k_rev [1/s]:' ;
            elseif contains(kinetics, 'Paralelas')
                app.Pred_CA0Label.Visible = 'on' ; app.Pred_CA0Field.Visible = 'on' ;
                app.Pred_k2Label.Visible = 'on' ; app.Pred_k2Field.Visible = 'on' ;
                app.Pred_n1Label.Visible = 'on' ; app.Pred_n1Field.Visible = 'on' ;
                app.Pred_n2Label.Visible = 'on' ; app.Pred_n2Field.Visible = 'on' ;
                app.Pred_ResultSelectLabel.Visible = 'on' ;
                app.Pred_ResultYieldLabel.Visible = 'on' ;
                app.Pred_kLabel.Text = 'k1 [1/s]:' ;
            elseif contains(kinetics, 'personalizada')
                app.Pred_kLabel.Visible = 'off' ; app.Pred_kField.Visible = 'off' ;
                app.Pred_CA0Label.Visible = 'on' ; app.Pred_CA0Field.Visible = 'on' ;
                app.Pred_CustomRateLabel.Visible = 'on' ; app.Pred_CustomRateField.Visible = 'on' ;
            else
                % 1er Orden - solo k visible (por defecto)
                app.Pred_kLabel.Text = 'k [1/s]:' ;
            end
        end

        function Pred_compute(app)
            % Compute segregation and max mixedness bounds

            try
                % Check RTD is available
                if isempty(app.rtd)
                    uialert(app.UIFigure, ...
                        'No hay RTD disponible. Ve a la Pestaña 1 y genera una RTD primero.', ...
                        'RTD requerida') ;
                    return
                end

                kinetics = app.Pred_KineticsDropdown.Value ;
                k_val = app.Pred_kField.Value ;

                % Create model objects
                app.seg_model = SegregationModel ;
                app.seg_model.rtd = app.rtd ;

                app.mm_model = MaxMixednessModel ;
                app.mm_model.rtd = app.rtd ;

                if contains(kinetics, '1er')
                    % Primer orden
                    app.seg_model = app.seg_model.compute_firstOrder(k_val) ;
                    app.mm_model = app.mm_model.compute_firstOrder(k_val) ;
                    order = 1 ;
                else
                    % Segundo orden
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

                % Interpretacion
                if order == 1
                    app.Pred_ResultBoundsLabel.Text = ...
                        sprintf('1er orden: Seg = MM = exacto = %.4f', X_seg) ;
                    app.Pred_ResultBoundsLabel.FontColor = [0 0.5 0] ;
                elseif order == 2
                    app.Pred_ResultBoundsLabel.Text = ...
                        sprintf('n>1: Seg=%.4f (sup) >= MM=%.4f (inf)', X_seg, X_mm) ;
                    app.Pred_ResultBoundsLabel.FontColor = [0 0 0.7] ;
                end

                % Update plots
                app.Pred_updatePlots() ;

                % Update RTD status label
                app.Pred_RTDStatusLabel.Text = sprintf('tau=%.2f, sigma2=%.2f', ...
                    app.rtd.tau, app.rtd.sigma2) ;
                app.Pred_RTDStatusLabel.FontColor = [0 0.5 0] ;

            catch ME
                uialert(app.UIFigure, ME.message, 'Error calculando límites') ;
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
            leftPanel = uipanel(mainGrid, 'Title', 'Configuracion TIS') ;
            leftGrid = uigridlayout(leftPanel, [16 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 16) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: N method
            lbl = uilabel(leftGrid, 'Text', 'Metodo N:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = 1 ;
            app.TIS_NMethodDropdown = uidropdown(leftGrid, ...
                'Items', {'Manual', 'Desde datos calculados'}, ...
                'Value', 'Manual', ...
                'ValueChangedFcn', @(~,~) app.TIS_NMethodChanged()) ;
            app.TIS_NMethodDropdown.Layout.Row = 1 ;
            app.TIS_NMethodDropdown.Layout.Column = 2 ;

            % Row 2: N tanks
            app.TIS_NLabel = uilabel(leftGrid, 'Text', 'N [tanks]:') ;
            app.TIS_NLabel.Layout.Row = 2 ; app.TIS_NLabel.Layout.Column = 1 ;
            app.TIS_NField = uieditfield(leftGrid, 'numeric', ...
                'Value', 3, 'Limits', [0.1 Inf], ...
                'Tooltip', 'Numero de tanques en serie. N=1: CSTR, N->inf: PFR. Puede ser no entero para RTD.') ;
            app.TIS_NField.Layout.Row = 2 ; app.TIS_NField.Layout.Column = 2 ;

            % Row 3: RTD status (shown when "From RTD")
            app.TIS_RTDStatusLabel = uilabel(leftGrid, ...
                'Text', 'RTD: no cargada', 'FontColor', [0.6 0 0]) ;
            app.TIS_RTDStatusLabel.Layout.Row = 3 ;
            app.TIS_RTDStatusLabel.Layout.Column = [1 2] ;
            app.TIS_RTDStatusLabel.Visible = 'off' ;

            % Row 4: tau
            app.TIS_tauLabel = uilabel(leftGrid, 'Text', 'tau total [s]:') ;
            app.TIS_tauLabel.Layout.Row = 4 ; app.TIS_tauLabel.Layout.Column = 1 ;
            app.TIS_tauField = uieditfield(leftGrid, 'numeric', ...
                'Value', 10, 'Limits', [0.001 Inf], ...
                'Tooltip', 'Tiempo medio de residencia total: tau = V_total / Q.') ;
            app.TIS_tauField.Layout.Row = 4 ; app.TIS_tauField.Layout.Column = 2 ;

            % Row 5: Kinetics dropdown
            lbl = uilabel(leftGrid, 'Text', 'Cinetica:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 5 ; lbl.Layout.Column = 1 ;
            app.TIS_KineticsDropdown = uidropdown(leftGrid, ...
                'Items', {'1er Orden (-rA = k*CA)', ...
                          '2do Orden (-rA = k*CA^2)'}, ...
                'Value', '1er Orden (-rA = k*CA)', ...
                'ValueChangedFcn', @(~,~) app.TIS_kineticsChanged()) ;
            app.TIS_KineticsDropdown.Layout.Row = 5 ;
            app.TIS_KineticsDropdown.Layout.Column = 2 ;

            % Row 6: k
            app.TIS_kLabel = uilabel(leftGrid, 'Text', 'k [1/s]:') ;
            app.TIS_kLabel.Layout.Row = 6 ; app.TIS_kLabel.Layout.Column = 1 ;
            app.TIS_kField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.1, 'Limits', [0 Inf], ...
                'Tooltip', 'Constante cinetica. Unidades dependen del orden: 1/s (1er orden), m^3/(mol*s) (2do orden).') ;
            app.TIS_kField.Layout.Row = 6 ; app.TIS_kField.Layout.Column = 2 ;

            % Row 7: CA0 (only for 2nd order)
            app.TIS_CA0Label = uilabel(leftGrid, 'Text', 'CA0 [mol/m^3]:') ;
            app.TIS_CA0Label.Layout.Row = 7 ; app.TIS_CA0Label.Layout.Column = 1 ;
            app.TIS_CA0Label.Visible = 'off' ;
            app.TIS_CA0Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 1000, 'Limits', [0.001 Inf], ...
                'Tooltip', 'Concentracion inicial del reactivo limitante en la alimentacion.') ;
            app.TIS_CA0Field.Layout.Row = 7 ; app.TIS_CA0Field.Layout.Column = 2 ;
            app.TIS_CA0Field.Visible = 'off' ;

            % Row 8: Compute button
            app.TIS_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Calcular', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.TIS_compute()) ;
            app.TIS_ComputeButton.Layout.Row = 8 ;
            app.TIS_ComputeButton.Layout.Column = [1 2] ;

            % Row 9: Results header
            lbl = uilabel(leftGrid, 'Text', 'Resultados:', ...
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
            lbl = uilabel(leftGrid, 'Text', 'X_CSTR [N=1]:') ;
            lbl.Layout.Row = 12 ; lbl.Layout.Column = 1 ;
            app.TIS_ResultXcstr = uilabel(leftGrid, 'Text', '--') ;
            app.TIS_ResultXcstr.Layout.Row = 12 ;
            app.TIS_ResultXcstr.Layout.Column = 2 ;

            % Row 13: X_PFR (N→inf reference)
            lbl = uilabel(leftGrid, 'Text', 'X_PFR [N->inf]:') ;
            lbl.Layout.Row = 13 ; lbl.Layout.Column = 1 ;
            app.TIS_ResultXpfr = uilabel(leftGrid, 'Text', '--') ;
            app.TIS_ResultXpfr.Layout.Row = 13 ;
            app.TIS_ResultXpfr.Layout.Column = 2 ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Resultados TIS') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % E(t) plot for TIS model
            app.TIS_AxesEt = uiaxes(plotGrid) ;
            title(app.TIS_AxesEt, 'E(t) - TIS Model') ;
            xlabel(app.TIS_AxesEt, 't [s]') ;
            ylabel(app.TIS_AxesEt, 'E(t) [1/s]') ;
            grid(app.TIS_AxesEt, 'on') ;

            % X vs N sweep plot
            app.TIS_AxesXvsN = uiaxes(plotGrid) ;
            title(app.TIS_AxesXvsN, 'Conversion vs N') ;
            xlabel(app.TIS_AxesXvsN, 'N [number of tanks]') ;
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
            if contains(source, 'Desde datos')
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
                    infoLines{end+1} = 'RTD: no cargada' ;
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

                if any(contains(infoLines, 'no cargada'))
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
            if contains(kinetics, '2do')
                app.TIS_CA0Label.Visible = 'on' ;
                app.TIS_CA0Field.Visible = 'on' ;
                app.TIS_kLabel.Text = 'k [m^3/(mol·s)]:' ;
            else
                app.TIS_CA0Label.Visible = 'off' ;
                app.TIS_CA0Field.Visible = 'off' ;
                app.TIS_kLabel.Text = 'k [1/s]:' ;
            end
        end

        function TIS_compute(app)
            try
                N_val = app.TIS_NField.Value ;
                tau_val = app.TIS_tauField.Value ;
                k_val = app.TIS_kField.Value ;
                kinetics = app.TIS_KineticsDropdown.Value ;
                is2nd = contains(kinetics, '2do') ;

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
                uialert(app.UIFigure, ME.message, 'Error calculando TIS') ;
            end
        end

        function TIS_updatePlots(app, N_val, tau_val, k_val, is2nd, ...
                                 X_tis, X_cstr, X_pfr)

            % ---- Plot 1: E(t) for current N ----
            cla(app.TIS_AxesEt) ;
            rtd_tis = RTD.tanks_in_series(N_val, tau_val) ;
            plot(app.TIS_AxesEt, rtd_tis.t, rtd_tis.Et, 'b-', 'LineWidth', 1.5) ;
            title(app.TIS_AxesEt, sprintf('E(t) - TIS  N=%.1f', N_val)) ;
            xlabel(app.TIS_AxesEt, 't [s]') ;
            ylabel(app.TIS_AxesEt, 'E(t) [1/s]') ;
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
            xlabel(app.TIS_AxesXvsN, 'N [number of tanks]') ;
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
            leftPanel = uipanel(mainGrid, 'Title', 'Configuracion Dispersion') ;
            leftGrid = uigridlayout(leftPanel, [17 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 17) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: Input method
            lbl = uilabel(leftGrid, 'Text', 'Entrada:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = 1 ;
            app.Disp_InputMethodDropdown = uidropdown(leftGrid, ...
                'Items', {'Manual', 'Desde datos calculados'}, ...
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
            app.Disp_BoLabel = uilabel(leftGrid, 'Text', 'Bo [= De/uL]:') ;
            app.Disp_BoLabel.Layout.Row = 3 ; app.Disp_BoLabel.Layout.Column = 1 ;
            app.Disp_BoLabel.FontWeight = 'bold' ;
            app.Disp_BoField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.025, 'Limits', [1e-6 100], ...
                'ValueChangedFcn', @(~,~) app.Disp_updatePe(), ...
                'Tooltip', 'Numero de dispersion Bo = De/(u*L). Bo->0: flujo piston (PFR), Bo->inf: mezcla perfecta (CSTR).') ;
            app.Disp_BoField.Layout.Row = 3 ; app.Disp_BoField.Layout.Column = 2 ;

            % Row 4: Pe display (read-only)
            lbl = uilabel(leftGrid, 'Text', 'Pe [= 1/Bo]:') ;
            lbl.Layout.Row = 4 ; lbl.Layout.Column = 1 ;
            app.Disp_PeLabel = uilabel(leftGrid, 'Text', sprintf('%.2f', 1/0.025)) ;
            app.Disp_PeLabel.Layout.Row = 4 ; app.Disp_PeLabel.Layout.Column = 2 ;

            % Row 5: Boundary conditions
            app.Disp_BCLabel = uilabel(leftGrid, 'Text', 'Frontera:') ;
            app.Disp_BCLabel.Layout.Row = 5 ; app.Disp_BCLabel.Layout.Column = 1 ;
            app.Disp_BCDropdown = uidropdown(leftGrid, ...
                'Items', {'closed-closed', 'open-open'}, ...
                'Value', 'closed-closed', ...
                'Tooltip', 'closed-closed: reactor confinado (Danckwerts). open-open: reactor abierto (aproximacion gaussiana).') ;
            app.Disp_BCDropdown.Layout.Row = 5 ; app.Disp_BCDropdown.Layout.Column = 2 ;

            % Row 6: tau
            app.Disp_tauLabel = uilabel(leftGrid, 'Text', 'tau [s]:') ;
            app.Disp_tauLabel.Layout.Row = 6 ; app.Disp_tauLabel.Layout.Column = 1 ;
            app.Disp_tauField = uieditfield(leftGrid, 'numeric', ...
                'Value', 10, 'Limits', [0.001 Inf], ...
                'Tooltip', 'Tiempo medio de residencia: tau = V/Q = L/u.') ;
            app.Disp_tauField.Layout.Row = 6 ; app.Disp_tauField.Layout.Column = 2 ;

            % Row 7: Kinetics
            app.Disp_KineticsLabel = uilabel(leftGrid, 'Text', 'Cinetica:') ;
            app.Disp_KineticsLabel.Layout.Row = 7 ; app.Disp_KineticsLabel.Layout.Column = 1 ;
            app.Disp_KineticsLabel.FontWeight = 'bold' ;
            app.Disp_KineticsDropdown = uidropdown(leftGrid, ...
                'Items', {'1er Orden (-rA = k*CA)', ...
                          '2do Orden (-rA = k*CA^2)'}, ...
                'Value', '1er Orden (-rA = k*CA)', ...
                'ValueChangedFcn', @(~,~) app.Disp_kineticsChanged()) ;
            app.Disp_KineticsDropdown.Layout.Row = 7 ;
            app.Disp_KineticsDropdown.Layout.Column = 2 ;

            % Row 8: k
            app.Disp_kLabel = uilabel(leftGrid, 'Text', 'k [1/s]:') ;
            app.Disp_kLabel.Layout.Row = 8 ; app.Disp_kLabel.Layout.Column = 1 ;
            app.Disp_kField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.1, 'Limits', [0 Inf], ...
                'Tooltip', 'Constante cinetica. Unidades dependen del orden: 1/s (1er orden), m^3/(mol*s) (2do orden).') ;
            app.Disp_kField.Layout.Row = 8 ; app.Disp_kField.Layout.Column = 2 ;

            % Row 9: CA0 (2nd order only)
            app.Disp_CA0Label = uilabel(leftGrid, 'Text', 'CA0 [mol/m^3]:') ;
            app.Disp_CA0Label.Layout.Row = 9 ; app.Disp_CA0Label.Layout.Column = 1 ;
            app.Disp_CA0Label.Visible = 'off' ;
            app.Disp_CA0Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 1000, 'Limits', [0.001 Inf], ...
                'Tooltip', 'Concentracion inicial del reactivo limitante en la alimentacion.') ;
            app.Disp_CA0Field.Layout.Row = 9 ; app.Disp_CA0Field.Layout.Column = 2 ;
            app.Disp_CA0Field.Visible = 'off' ;

            % Row 10: Compute button
            app.Disp_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Calcular', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Disp_compute()) ;
            app.Disp_ComputeButton.Layout.Row = 10 ;
            app.Disp_ComputeButton.Layout.Column = [1 2] ;

            % Row 11: Results header
            lbl = uilabel(leftGrid, 'Text', 'Resultados:', ...
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
            lbl = uilabel(leftGrid, 'Text', 'X_CSTR [Bo->inf]:') ;
            lbl.Layout.Row = 14 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultXcstr = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultXcstr.Layout.Row = 14 ; app.Disp_ResultXcstr.Layout.Column = 2 ;

            % Row 15: X_PFR
            lbl = uilabel(leftGrid, 'Text', 'X_PFR [Bo->0]:') ;
            lbl.Layout.Row = 15 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultXpfr = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultXpfr.Layout.Row = 15 ; app.Disp_ResultXpfr.Layout.Column = 2 ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Resultados Dispersion') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % E(t) plot
            app.Disp_AxesEt = uiaxes(plotGrid) ;
            title(app.Disp_AxesEt, 'E(t) - Dispersion') ;
            xlabel(app.Disp_AxesEt, 't [s]') ;
            ylabel(app.Disp_AxesEt, 'E(t) [1/s]') ;

            % X vs Bo sweep
            app.Disp_AxesXvsBo = uiaxes(plotGrid) ;
            title(app.Disp_AxesXvsBo, 'X vs Bo') ;
            xlabel(app.Disp_AxesXvsBo, 'Bo [dispersion number]') ;
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
            if contains(kinetics, '2do')
                app.Disp_CA0Label.Visible = 'on' ;
                app.Disp_CA0Field.Visible = 'on' ;
                app.Disp_kLabel.Text = 'k [m^3/(mol·s)]:' ;
            else
                app.Disp_CA0Label.Visible = 'off' ;
                app.Disp_CA0Field.Visible = 'off' ;
                app.Disp_kLabel.Text = 'k [1/s]:' ;
            end
        end

        function Disp_inputMethodChanged(app)
            source = app.Disp_InputMethodDropdown.Value ;

            if contains(source, 'Desde datos')
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
                    infoLines{end+1} = 'RTD: no cargada' ;
                end

                % Import kinetics from Prediction Models tab
                if ~isempty(app.Pred_kField) && app.Pred_kField.Value > 0
                    app.Disp_kField.Value = app.Pred_kField.Value ;
                    % Map Pred kinetics to Disp (only 1st/2nd available)
                    if contains(app.Pred_KineticsDropdown.Value, '2do')
                        app.Disp_KineticsDropdown.Value = '2do Orden (-rA = k*CA^2)' ;
                    else
                        app.Disp_KineticsDropdown.Value = '1er Orden (-rA = k*CA)' ;
                    end
                    app.Disp_kineticsChanged() ;
                    if ~isempty(app.Pred_CA0Field)
                        app.Disp_CA0Field.Value = app.Pred_CA0Field.Value ;
                    end
                    infoLines{end+1} = sprintf('k=%.4g', app.Pred_kField.Value) ;
                end

                if any(contains(infoLines, 'no cargada'))
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
                is2nd = contains(kinetics, '2do') ;

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
                uialert(app.UIFigure, ME.message, 'Error en el modelo de dispersión') ;
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
            xlabel(app.Disp_AxesEt, 't [s]') ;
            ylabel(app.Disp_AxesEt, 'E(t) [1/s]') ;

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
            xlabel(app.Disp_AxesXvsBo, 'Bo [dispersion number]') ;
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

        %% ============== TAB 5: CONVOLUTION / DECONVOLUTION ==============

        function createConvolutionTab(app)

            app.ConvTab = uitab(app.TabGroup, 'Title', 'Convolution') ;

            mainGrid = uigridlayout(app.ConvTab, [1 2]) ;
            mainGrid.ColumnWidth = {320, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'Convolucion / Deconvolucion') ;
            leftGrid = uigridlayout(leftPanel, [18 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 18) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: Workflow hint
            lbl = uilabel(leftGrid, 'Text', '1) Elige modo  2) Carga datos  3) Calcula', ...
                'FontAngle', 'italic', 'FontColor', [0.4 0.4 0.4], 'FontSize', 10) ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = [1 2] ;

            % Row 2: Mode
            lbl = uilabel(leftGrid, 'Text', 'Modo:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 2 ; lbl.Layout.Column = 1 ;
            app.Conv_ModeDropdown = uidropdown(leftGrid, ...
                'Items', {'Convolucion', 'Deconvolucion'}, ...
                'Value', 'Convolucion', ...
                'ValueChangedFcn', @(~,~) app.Conv_modeChanged()) ;
            app.Conv_ModeDropdown.Layout.Row = 2 ;
            app.Conv_ModeDropdown.Layout.Column = 2 ;

            % Row 3: Input source
            lbl = uilabel(leftGrid, 'Text', 'Fuente de datos:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 3 ; lbl.Layout.Column = 1 ;
            app.Conv_InputDropdown = uidropdown(leftGrid, ...
                'Items', {'Desde workspace', 'Desde archivo'}, ...
                'Value', 'Desde workspace') ;
            app.Conv_InputDropdown.Layout.Row = 3 ;
            app.Conv_InputDropdown.Layout.Column = 2 ;

            % Row 4: t variable
            app.Conv_tVarLabel = uilabel(leftGrid, 'Text', 'Variable t [s]:') ;
            app.Conv_tVarLabel.Layout.Row = 4 ; app.Conv_tVarLabel.Layout.Column = 1 ;
            app.Conv_tVarField = uieditfield(leftGrid, 'text', 'Value', 't') ;
            app.Conv_tVarField.Layout.Row = 4 ; app.Conv_tVarField.Layout.Column = 2 ;

            % Row 5: C_in variable
            app.Conv_CinVarLabel = uilabel(leftGrid, 'Text', 'Variable C_{in}(t):') ;
            app.Conv_CinVarLabel.Layout.Row = 5 ; app.Conv_CinVarLabel.Layout.Column = 1 ;
            app.Conv_CinVarField = uieditfield(leftGrid, 'text', 'Value', 'C_in') ;
            app.Conv_CinVarField.Layout.Row = 5 ; app.Conv_CinVarField.Layout.Column = 2 ;

            % Row 6: E variable (convolution mode)
            app.Conv_EVarLabel = uilabel(leftGrid, 'Text', 'Variable E(t) [1/s]:') ;
            app.Conv_EVarLabel.Layout.Row = 6 ; app.Conv_EVarLabel.Layout.Column = 1 ;
            app.Conv_EVarField = uieditfield(leftGrid, 'text', 'Value', 'E') ;
            app.Conv_EVarField.Layout.Row = 6 ; app.Conv_EVarField.Layout.Column = 2 ;

            % Row 6 (shared): C_out variable (deconvolution mode — hidden by default)
            app.Conv_CoutVarLabel = uilabel(leftGrid, 'Text', 'Variable C_{out}(t):') ;
            app.Conv_CoutVarLabel.Layout.Row = 6 ; app.Conv_CoutVarLabel.Layout.Column = 1 ;
            app.Conv_CoutVarLabel.Visible = 'off' ;
            app.Conv_CoutVarField = uieditfield(leftGrid, 'text', 'Value', 'C_out') ;
            app.Conv_CoutVarField.Layout.Row = 6 ; app.Conv_CoutVarField.Layout.Column = 2 ;
            app.Conv_CoutVarField.Visible = 'off' ;

            % Row 7: nE (deconvolution only)
            app.Conv_nELabel = uilabel(leftGrid, 'Text', 'N puntos E(t):', ...
                'Tooltip', 'Numero de puntos para reconstruir E(t). Tipicamente 30-100.') ;
            app.Conv_nELabel.Layout.Row = 7 ; app.Conv_nELabel.Layout.Column = 1 ;
            app.Conv_nELabel.Visible = 'off' ;
            app.Conv_nEField = uieditfield(leftGrid, 'numeric', ...
                'Value', 50, 'Limits', [2 10000], ...
                'Tooltip', 'Mas puntos = mayor resolucion pero mas lento') ;
            app.Conv_nEField.Layout.Row = 7 ; app.Conv_nEField.Layout.Column = 2 ;
            app.Conv_nEField.Visible = 'off' ;

            % Row 8: Import from file button
            app.Conv_ImportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Importar desde archivo', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [1 1 1], ...
                'FontColor', [0.8 0 0], ...
                'ButtonPushedFcn', @(~,~) app.Conv_importFromFile()) ;
            app.Conv_ImportButton.Layout.Row = 8 ;
            app.Conv_ImportButton.Layout.Column = [1 2] ;

            % Row 9: Import status
            app.Conv_ImportLabel = uilabel(leftGrid, 'Text', '') ;
            app.Conv_ImportLabel.Layout.Row = 9 ;
            app.Conv_ImportLabel.Layout.Column = [1 2] ;
            app.Conv_ImportLabel.FontColor = [0 0.5 0] ;
            app.Conv_ImportLabel.WordWrap = 'on' ;

            % Row 10: Compute button
            app.Conv_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Calcular', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Conv_compute()) ;
            app.Conv_ComputeButton.Layout.Row = 10 ;
            app.Conv_ComputeButton.Layout.Column = [1 2] ;

            % Row 11: Results header
            lbl = uilabel(leftGrid, 'Text', 'Resultados:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 11 ; lbl.Layout.Column = [1 2] ;

            % Row 12-13: Result info
            app.Conv_ResultLabel = uilabel(leftGrid, 'Text', '--') ;
            app.Conv_ResultLabel.Layout.Row = [12 13] ;
            app.Conv_ResultLabel.Layout.Column = [1 2] ;
            app.Conv_ResultLabel.WordWrap = 'on' ;

            % Row 14: Export name
            lbl = uilabel(leftGrid, 'Text', 'Nombre exportar:') ;
            lbl.Layout.Row = 14 ; lbl.Layout.Column = 1 ;
            app.Conv_ExportNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'conv_result') ;
            app.Conv_ExportNameField.Layout.Row = 14 ;
            app.Conv_ExportNameField.Layout.Column = 2 ;

            % Row 15: Export button
            app.Conv_ExportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Exportar a Workspace', ...
                'BackgroundColor', [0.2 0.7 0.3], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Conv_export()) ;
            app.Conv_ExportButton.Layout.Row = 15 ;
            app.Conv_ExportButton.Layout.Column = [1 2] ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Senales') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % Input signals plot
            app.Conv_AxesInput = uiaxes(plotGrid) ;
            title(app.Conv_AxesInput, 'Senales de entrada') ;
            xlabel(app.Conv_AxesInput, 't [s]') ;
            ylabel(app.Conv_AxesInput, 'Concentracion / E(t)') ;

            % Result plot
            app.Conv_AxesResult = uiaxes(plotGrid) ;
            title(app.Conv_AxesResult, 'Resultado') ;
            xlabel(app.Conv_AxesResult, 't [s]') ;
            ylabel(app.Conv_AxesResult, 'C_{out}(t)') ;

            % Recovered E(t) / Comparison (spans 2 columns)
            app.Conv_AxesRecovered = uiaxes(plotGrid) ;
            app.Conv_AxesRecovered.Layout.Column = [1 2] ;
            title(app.Conv_AxesRecovered, 'Verificacion') ;
            xlabel(app.Conv_AxesRecovered, 't [s]') ;
            ylabel(app.Conv_AxesRecovered, 'Amplitud') ;
        end

        %% ============== CONVOLUTION CALLBACKS ==============

        function Conv_modeChanged(app)
            mode = app.Conv_ModeDropdown.Value ;
            if strcmp(mode, 'Convolucion')
                % Show E field, hide C_out and nE
                app.Conv_EVarLabel.Visible = 'on' ;
                app.Conv_EVarField.Visible = 'on' ;
                app.Conv_CoutVarLabel.Visible = 'off' ;
                app.Conv_CoutVarField.Visible = 'off' ;
                app.Conv_nELabel.Visible = 'off' ;
                app.Conv_nEField.Visible = 'off' ;
            else
                % Deconvolution: show C_out and nE, hide E
                app.Conv_EVarLabel.Visible = 'off' ;
                app.Conv_EVarField.Visible = 'off' ;
                app.Conv_CoutVarLabel.Visible = 'on' ;
                app.Conv_CoutVarField.Visible = 'on' ;
                app.Conv_nELabel.Visible = 'on' ;
                app.Conv_nEField.Visible = 'on' ;
            end
        end

        function Conv_importFromFile(app)
            % Importar datos desde archivo Excel/CSV para convolucion
            [file, filepath] = uigetfile( ...
                {'*.xlsx;*.xls;*.csv;*.tsv', 'Archivos de datos' ; ...
                 '*.*', 'Todos los archivos'}, ...
                'Seleccionar archivo de datos') ;

            if isequal(file, 0)
                return
            end

            try
                fullPath = fullfile(filepath, file) ;
                data = readmatrix(fullPath) ;
                data = data(~any(isnan(data(:,1:min(end,3))), 2), :) ;

                if size(data, 2) < 2
                    uialert(app.UIFigure, ...
                        'El archivo debe tener al menos 2 columnas.', ...
                        'Error de importacion') ;
                    return
                end

                % Validate uniform dt
                t_data = data(:, 1)' ;
                dt_vec = diff(t_data) ;
                if max(dt_vec) - min(dt_vec) > 0.01 * mean(dt_vec)
                    app.Conv_ImportLabel.Text = 'Aviso: dt no es uniforme. Los resultados pueden ser imprecisos.' ;
                    app.Conv_ImportLabel.FontColor = [0.8 0.5 0] ;
                end

                assignin('base', app.Conv_tVarField.Value, t_data) ;

                if size(data, 2) >= 2
                    col2 = data(:, 2)' ;
                    assignin('base', app.Conv_CinVarField.Value, col2) ;
                end

                if size(data, 2) >= 3
                    col3 = data(:, 3)' ;
                    mode = app.Conv_ModeDropdown.Value ;
                    if strcmp(mode, 'Convolucion')
                        assignin('base', app.Conv_EVarField.Value, col3) ;
                    else
                        assignin('base', app.Conv_CoutVarField.Value, col3) ;
                    end
                end

                app.Conv_ImportLabel.Text = sprintf('Cargado: %s (%d puntos, %d columnas)', ...
                    file, length(t_data), size(data, 2)) ;
                app.Conv_ImportLabel.FontColor = [0 0.5 0] ;

            catch ME
                uialert(app.UIFigure, ...
                    sprintf('Error al importar: %s', ME.message), ...
                    'Error de importacion') ;
            end
        end

        function Conv_compute(app)
            try
                mode = app.Conv_ModeDropdown.Value ;
                t_var = app.Conv_tVarField.Value ;
                t_data = evalin('base', t_var) ;

                if strcmp(mode, 'Convolucion')
                    % ---- CONVOLUCION ----
                    C_in = evalin('base', app.Conv_CinVarField.Value) ;
                    E = evalin('base', app.Conv_EVarField.Value) ;

                    % Use same t for both (common case)
                    [C_out, t_out] = ConvolutionTool.convolve(t_data, E, t_data, C_in) ;

                    % Store result for export
                    assignin('base', 'conv_t_out', t_out) ;
                    assignin('base', 'conv_C_out', C_out) ;

                    % Update plots
                    cla(app.Conv_AxesInput) ;
                    yyaxis(app.Conv_AxesInput, 'left') ;
                    plot(app.Conv_AxesInput, t_data, C_in, 'b-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, 'C_{in}(t)') ;
                    yyaxis(app.Conv_AxesInput, 'right') ;
                    plot(app.Conv_AxesInput, t_data, E, 'r-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, 'E(t) [1/s]') ;
                    xlabel(app.Conv_AxesInput, 't [s]') ;
                    title(app.Conv_AxesInput, 'Entrada: C_{in}(t) y E(t)') ;
                    legend(app.Conv_AxesInput, 'C_{in}', 'E(t)', 'Location', 'best') ;

                    cla(app.Conv_AxesResult) ;
                    plot(app.Conv_AxesResult, t_out, C_out, 'b-', 'LineWidth', 1.5) ;
                    xlabel(app.Conv_AxesResult, 't [s]') ;
                    ylabel(app.Conv_AxesResult, 'C_{out}(t)') ;
                    title(app.Conv_AxesResult, 'Resultado: C_{out} = E \otimes C_{in}') ;

                    % Verification: overlay original C_in and C_out
                    cla(app.Conv_AxesRecovered) ;
                    plot(app.Conv_AxesRecovered, t_data, C_in, 'b--', 'LineWidth', 1) ;
                    hold(app.Conv_AxesRecovered, 'on') ;
                    plot(app.Conv_AxesRecovered, t_out, C_out, 'r-', 'LineWidth', 1.5) ;
                    hold(app.Conv_AxesRecovered, 'off') ;
                    xlabel(app.Conv_AxesRecovered, 't [s]') ;
                    title(app.Conv_AxesRecovered, 'Comparacion: C_{in} vs C_{out}') ;
                    legend(app.Conv_AxesRecovered, 'C_{in}(t)', 'C_{out}(t)', 'Location', 'best') ;

                    app.Conv_ResultLabel.Text = sprintf( ...
                        'Convolucion OK\nC_{out}: %d puntos, t=[%.2f, %.2f] s', ...
                        length(C_out), t_out(1), t_out(end)) ;

                else
                    % ---- DECONVOLUCION ----
                    C_in = evalin('base', app.Conv_CinVarField.Value) ;
                    C_out = evalin('base', app.Conv_CoutVarField.Value) ;
                    nE = app.Conv_nEField.Value ;

                    t_Cin = t_data ;
                    m = length(C_in) ;
                    v = length(C_out) ;
                    dt = (t_Cin(end) - t_Cin(1)) / (m - 1) ;
                    t_Cout = t_Cin(1) + (0:(v-1)) * dt ;

                    [E_rec, t_E, residual] = ConvolutionTool.deconvolve( ...
                        t_Cin, C_in, t_Cout, C_out, nE) ;

                    % Store for export
                    assignin('base', 'deconv_t_E', t_E) ;
                    assignin('base', 'deconv_E', E_rec) ;

                    % Plot inputs
                    cla(app.Conv_AxesInput) ;
                    yyaxis(app.Conv_AxesInput, 'left') ;
                    plot(app.Conv_AxesInput, t_Cin, C_in, 'b-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, 'C_{in}(t)') ;
                    yyaxis(app.Conv_AxesInput, 'right') ;
                    plot(app.Conv_AxesInput, t_Cout, C_out, 'r-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, 'C_{out}(t)') ;
                    xlabel(app.Conv_AxesInput, 't [s]') ;
                    title(app.Conv_AxesInput, 'Entrada: C_{in}(t) y C_{out}(t)') ;
                    legend(app.Conv_AxesInput, 'C_{in}', 'C_{out}', 'Location', 'best') ;

                    % Plot recovered E(t)
                    cla(app.Conv_AxesResult) ;
                    plot(app.Conv_AxesResult, t_E, E_rec, 'm-', 'LineWidth', 1.5) ;
                    xlabel(app.Conv_AxesResult, 't [s]') ;
                    ylabel(app.Conv_AxesResult, 'E(t) [1/s]') ;
                    title(app.Conv_AxesResult, sprintf('E(t) recuperada | area=%.4f', ...
                        trapz(t_E, E_rec))) ;

                    % Verification: re-convolve and compare with C_out
                    [C_out_check, t_check] = ConvolutionTool.convolve(t_E, E_rec, t_Cin, C_in) ;
                    cla(app.Conv_AxesRecovered) ;
                    plot(app.Conv_AxesRecovered, t_Cout, C_out, 'b-', 'LineWidth', 1.5) ;
                    hold(app.Conv_AxesRecovered, 'on') ;
                    plot(app.Conv_AxesRecovered, t_check, C_out_check, 'r--', 'LineWidth', 1.5) ;
                    hold(app.Conv_AxesRecovered, 'off') ;
                    xlabel(app.Conv_AxesRecovered, 't [s]') ;
                    title(app.Conv_AxesRecovered, 'Verificacion: C_{out} vs reconvolucion') ;
                    legend(app.Conv_AxesRecovered, 'C_{out} (datos)', 'E_{rec} \otimes C_{in}', ...
                           'Location', 'best') ;

                    app.Conv_ResultLabel.Text = sprintf( ...
                        'Deconvolucion OK\nResiduo: %.4e\nE: %d puntos, t=[%.2f, %.2f] s', ...
                        residual, length(E_rec), t_E(1), t_E(end)) ;
                end

                app.Conv_ExportButton.Enable = 'on' ;

            catch ME
                uialert(app.UIFigure, ...
                    sprintf('Error en el calculo: %s\nSugerencia: comprueba que las variables existen y tienen la misma longitud.', ME.message), ...
                    'Error de convolucion') ;
            end
        end

        function Conv_export(app)
            varName = app.Conv_ExportNameField.Value ;
            if ~isvarname(varName)
                uialert(app.UIFigure, ...
                    sprintf('"%s" no es un nombre de variable valido.', varName), ...
                    'Nombre no valido') ;
                return
            end

            mode = app.Conv_ModeDropdown.Value ;
            if strcmp(mode, 'Convolucion')
                result.t = evalin('base', 'conv_t_out') ;
                result.C_out = evalin('base', 'conv_C_out') ;
                result.mode = 'convolution' ;
            else
                result.t = evalin('base', 'deconv_t_E') ;
                result.E = evalin('base', 'deconv_E') ;
                result.mode = 'deconvolution' ;
                result.rtd = RTD(result.t, result.E) ;
            end

            assignin('base', varName, result) ;
            uialert(app.UIFigure, ...
                sprintf('Resultado exportado como "%s"', varName), ...
                'Exportacion exitosa', 'Icon', 'success') ;
        end

        %% ============== TAB 6: COMBINED MODELS ==============

        function createCombinedTab(app)

            app.CombTab = uitab(app.TabGroup, 'Title', 'Combined Models') ;

            mainGrid = uigridlayout(app.CombTab, [1 2]) ;
            mainGrid.ColumnWidth = {320, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'Configuracion de modelo combinado') ;
            leftGrid = uigridlayout(leftPanel, [17 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 17) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: Model selection
            lbl = uilabel(leftGrid, 'Text', 'Modelo:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = 1 ;
            app.Comb_ModelDropdown = uidropdown(leftGrid, ...
                'Items', {'CSTR + Vol. muerto', ...
                          'CSTR + Bypass', ...
                          'CSTR + Bypass + Vol. muerto', ...
                          'CSTR + PFR en serie'}, ...
                'Value', 'CSTR + Vol. muerto', ...
                'ValueChangedFcn', @(~,~) app.Comb_modelChanged()) ;
            app.Comb_ModelDropdown.Layout.Row = 1 ;
            app.Comb_ModelDropdown.Layout.Column = 2 ;

            % Row 2: Model description (dynamic)
            app.Comb_ModelDescLabel = uilabel(leftGrid, ...
                'Text', 'V_activo = alpha * V_total. El resto es volumen muerto.', ...
                'FontAngle', 'italic', 'FontColor', [0.4 0.4 0.4], ...
                'FontSize', 10, 'WordWrap', 'on') ;
            app.Comb_ModelDescLabel.Layout.Row = 2 ; app.Comb_ModelDescLabel.Layout.Column = [1 2] ;

            % Row 3: tau (with "From RTD" option)
            lbl = uilabel(leftGrid, 'Text', 'tau total [s]:') ;
            lbl.Layout.Row = 3 ; lbl.Layout.Column = 1 ;
            app.Comb_tauField = uieditfield(leftGrid, 'numeric', ...
                'Value', 10, 'Limits', [0.001 Inf]) ;
            app.Comb_tauField.Layout.Row = 3 ; app.Comb_tauField.Layout.Column = 2 ;

            % Row 4: Parameter 1
            app.Comb_Param1Label = uilabel(leftGrid, ...
                'Text', 'alpha (frac. vol. activo):', ...
                'Tooltip', 'Fraccion de volumen del reactor que esta bien mezclada (0 < alpha <= 1). El resto es volumen muerto sin flujo.') ;
            app.Comb_Param1Label.Layout.Row = 4 ; app.Comb_Param1Label.Layout.Column = 1 ;
            app.Comb_Param1Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.8, 'Limits', [0.01 1]) ;
            app.Comb_Param1Field.Layout.Row = 4 ; app.Comb_Param1Field.Layout.Column = 2 ;

            % Row 5: Parameter 2 (hidden for 1-param models)
            app.Comb_Param2Label = uilabel(leftGrid, ...
                'Text', 'beta (frac. bypass):', ...
                'Tooltip', 'Fraccion del caudal que pasa directamente sin reaccionar (0 <= beta < 1).') ;
            app.Comb_Param2Label.Layout.Row = 5 ; app.Comb_Param2Label.Layout.Column = 1 ;
            app.Comb_Param2Label.Visible = 'off' ;
            app.Comb_Param2Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.1, 'Limits', [0 0.99]) ;
            app.Comb_Param2Field.Layout.Row = 5 ; app.Comb_Param2Field.Layout.Column = 2 ;
            app.Comb_Param2Field.Visible = 'off' ;

            % Row 6: Kinetics
            lbl = uilabel(leftGrid, 'Text', 'Cinetica:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 6 ; lbl.Layout.Column = 1 ;
            app.Comb_KineticsDropdown = uidropdown(leftGrid, ...
                'Items', {'1er Orden (-rA = k*CA)', ...
                          '2do Orden (-rA = k*CA^2)'}, ...
                'Value', '1er Orden (-rA = k*CA)', ...
                'ValueChangedFcn', @(~,~) app.Comb_kineticsChanged()) ;
            app.Comb_KineticsDropdown.Layout.Row = 6 ;
            app.Comb_KineticsDropdown.Layout.Column = 2 ;

            % Row 7: k
            app.Comb_kLabel = uilabel(leftGrid, 'Text', 'k [1/s]:') ;
            app.Comb_kLabel.Layout.Row = 7 ; app.Comb_kLabel.Layout.Column = 1 ;
            app.Comb_kField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.1, 'Limits', [0 Inf], ...
                'Tooltip', 'Constante cinetica. Unidades dependen del orden: 1/s (1er orden), m^3/(mol*s) (2do orden).') ;
            app.Comb_kField.Layout.Row = 7 ; app.Comb_kField.Layout.Column = 2 ;

            % Row 8: CA0 (2nd order only)
            app.Comb_CA0Label = uilabel(leftGrid, 'Text', 'CA0 [mol/m^3]:') ;
            app.Comb_CA0Label.Layout.Row = 8 ; app.Comb_CA0Label.Layout.Column = 1 ;
            app.Comb_CA0Label.Visible = 'off' ;
            app.Comb_CA0Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 1000, 'Limits', [0.001 Inf], ...
                'Tooltip', 'Concentracion inicial del reactivo limitante en la alimentacion.') ;
            app.Comb_CA0Field.Layout.Row = 8 ; app.Comb_CA0Field.Layout.Column = 2 ;
            app.Comb_CA0Field.Visible = 'off' ;

            % Row 9: Compute button
            app.Comb_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Calcular', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Comb_compute()) ;
            app.Comb_ComputeButton.Layout.Row = 9 ;
            app.Comb_ComputeButton.Layout.Column = [1 2] ;

            % Row 10: Results header
            lbl = uilabel(leftGrid, 'Text', 'Resultados:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 10 ; lbl.Layout.Column = [1 2] ;

            % Row 11: Model params info
            lbl = uilabel(leftGrid, 'Text', 'Parametros:') ;
            lbl.Layout.Row = 11 ; lbl.Layout.Column = 1 ;
            app.Comb_ResultParams = uilabel(leftGrid, 'Text', '--') ;
            app.Comb_ResultParams.Layout.Row = 11 ;
            app.Comb_ResultParams.Layout.Column = 2 ;

            % Row 12: X combined
            lbl = uilabel(leftGrid, 'Text', 'X_modelo:') ;
            lbl.Layout.Row = 12 ; lbl.Layout.Column = 1 ;
            app.Comb_ResultX = uilabel(leftGrid, 'Text', '--') ;
            app.Comb_ResultX.Layout.Row = 12 ;
            app.Comb_ResultX.Layout.Column = 2 ;
            app.Comb_ResultX.FontWeight = 'bold' ;

            % Row 13: X_CSTR
            lbl = uilabel(leftGrid, 'Text', 'X_CSTR ideal:') ;
            lbl.Layout.Row = 13 ; lbl.Layout.Column = 1 ;
            app.Comb_ResultXcstr = uilabel(leftGrid, 'Text', '--') ;
            app.Comb_ResultXcstr.Layout.Row = 13 ;
            app.Comb_ResultXcstr.Layout.Column = 2 ;

            % Row 14: X_PFR
            lbl = uilabel(leftGrid, 'Text', 'X_PFR ideal:') ;
            lbl.Layout.Row = 14 ; lbl.Layout.Column = 1 ;
            app.Comb_ResultXpfr = uilabel(leftGrid, 'Text', '--') ;
            app.Comb_ResultXpfr.Layout.Row = 14 ;
            app.Comb_ResultXpfr.Layout.Column = 2 ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Resultados del modelo combinado') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % E(t) plot
            app.Comb_AxesEt = uiaxes(plotGrid) ;
            app.Comb_AxesEt.Layout.Row = 1 ; app.Comb_AxesEt.Layout.Column = [1 2] ;
            title(app.Comb_AxesEt, 'E(t) - Modelo combinado') ;
            xlabel(app.Comb_AxesEt, 't [s]') ;
            ylabel(app.Comb_AxesEt, 'E(t) [1/s]') ;

            % Comparison bar chart
            app.Comb_AxesComparison = uiaxes(plotGrid) ;
            app.Comb_AxesComparison.Layout.Row = 2 ; app.Comb_AxesComparison.Layout.Column = 1 ;
            title(app.Comb_AxesComparison, 'Comparacion de conversion') ;
            ylabel(app.Comb_AxesComparison, 'Conversion X') ;

            % Sensitivity plot (new)
            app.Comb_AxesSensitivity = uiaxes(plotGrid) ;
            app.Comb_AxesSensitivity.Layout.Row = 2 ; app.Comb_AxesSensitivity.Layout.Column = 2 ;
            title(app.Comb_AxesSensitivity, 'Sensibilidad al parametro') ;
            ylabel(app.Comb_AxesSensitivity, 'Conversion X') ;
        end

        %% ============== COMBINED CALLBACKS ==============

        function Comb_modelChanged(app)
            model = app.Comb_ModelDropdown.Value ;

            switch model
                case 'CSTR + Vol. muerto'
                    app.Comb_Param1Label.Text = 'alpha (frac. vol. activo):' ;
                    app.Comb_Param1Label.Tooltip = 'Fraccion de volumen del reactor que esta bien mezclada (0 < alpha <= 1). El resto es volumen muerto sin flujo.' ;
                    app.Comb_Param1Field.Value = 0.8 ;
                    app.Comb_Param1Field.Limits = [0.01 1] ;
                    app.Comb_Param2Label.Visible = 'off' ;
                    app.Comb_Param2Field.Visible = 'off' ;
                    app.Comb_ModelDescLabel.Text = 'V_activo = alpha * V_total. El resto es volumen muerto.' ;

                case 'CSTR + Bypass'
                    app.Comb_Param1Label.Text = 'beta (frac. bypass):' ;
                    app.Comb_Param1Label.Tooltip = 'Fraccion del caudal que pasa directamente sin reaccionar (0 <= beta < 1).' ;
                    app.Comb_Param1Field.Value = 0.1 ;
                    app.Comb_Param1Field.Limits = [0 0.99] ;
                    app.Comb_Param2Label.Visible = 'off' ;
                    app.Comb_Param2Field.Visible = 'off' ;
                    app.Comb_ModelDescLabel.Text = 'Q_bypass = beta * Q. El resto entra al CSTR.' ;

                case 'CSTR + Bypass + Vol. muerto'
                    app.Comb_Param1Label.Text = 'alpha (frac. vol. activo):' ;
                    app.Comb_Param1Label.Tooltip = 'Fraccion de volumen activo (0 < alpha <= 1).' ;
                    app.Comb_Param1Field.Value = 0.8 ;
                    app.Comb_Param1Field.Limits = [0.01 1] ;
                    app.Comb_Param2Label.Text = 'beta (frac. bypass):' ;
                    app.Comb_Param2Label.Tooltip = 'Fraccion de caudal en bypass (0 <= beta < 1).' ;
                    app.Comb_Param2Label.Visible = 'on' ;
                    app.Comb_Param2Field.Visible = 'on' ;
                    app.Comb_Param2Field.Value = 0.1 ;
                    app.Comb_Param2Field.Limits = [0 0.99] ;
                    app.Comb_ModelDescLabel.Text = 'Combina bypass (beta) y volumen muerto (alpha).' ;

                case 'CSTR + PFR en serie'
                    app.Comb_Param1Label.Text = 'tau_CSTR [s]:' ;
                    app.Comb_Param1Label.Tooltip = 'Tiempo de residencia en el CSTR.' ;
                    app.Comb_Param1Field.Value = 5 ;
                    app.Comb_Param1Field.Limits = [0.001 Inf] ;
                    app.Comb_Param2Label.Text = 'tau_PFR [s]:' ;
                    app.Comb_Param2Label.Tooltip = 'Tiempo de residencia en el PFR.' ;
                    app.Comb_Param2Label.Visible = 'on' ;
                    app.Comb_Param2Field.Visible = 'on' ;
                    app.Comb_Param2Field.Value = 5 ;
                    app.Comb_Param2Field.Limits = [0.001 Inf] ;
                    app.Comb_ModelDescLabel.Text = 'PFR seguido de CSTR en serie. E(t) = exponencial desplazada.' ;
            end
        end

        function Comb_kineticsChanged(app)
            kinetics = app.Comb_KineticsDropdown.Value ;
            if contains(kinetics, '2do')
                app.Comb_CA0Label.Visible = 'on' ;
                app.Comb_CA0Field.Visible = 'on' ;
                app.Comb_kLabel.Text = 'k [m^3/(mol*s)]:' ;
            else
                app.Comb_CA0Label.Visible = 'off' ;
                app.Comb_CA0Field.Visible = 'off' ;
                app.Comb_kLabel.Text = 'k [1/s]:' ;
            end
        end

        function Comb_compute(app)

            try
                model = app.Comb_ModelDropdown.Value ;
                tau_val = app.Comb_tauField.Value ;
                p1 = app.Comb_Param1Field.Value ;
                p2 = app.Comb_Param2Field.Value ;
                k_val = app.Comb_kField.Value ;
                kinetics = app.Comb_KineticsDropdown.Value ;
                is2nd = contains(kinetics, '2do') ;
                if is2nd
                    CA0_val = app.Comb_CA0Field.Value ;
                end

                Da = k_val * tau_val ;

                % Generate RTD and compute conversion
                switch model
                    case 'CSTR + Vol. muerto'
                        alpha = p1 ;
                        rtd_comb = RTD.cstr_with_dead_volume(tau_val, alpha) ;
                        tau_eff = alpha * tau_val ;
                        if is2nd
                            Da_eff = k_val * CA0_val * tau_eff ;
                            X_model = (-1 + sqrt(1 + 4*Da_eff)) / (2*Da_eff) ;
                        else
                            X_model = (k_val * tau_eff) / (1 + k_val * tau_eff) ;
                        end
                        paramStr = sprintf('alpha=%.3f', alpha) ;

                    case 'CSTR + Bypass'
                        beta = p1 ;
                        rtd_comb = RTD.cstr_with_bypass(tau_val, beta) ;
                        tau_s = tau_val / (1 - beta) ;
                        if is2nd
                            Da_s = k_val * CA0_val * tau_s ;
                            X_reactor = (-1 + sqrt(1 + 4*Da_s)) / (2*Da_s) ;
                        else
                            X_reactor = (k_val * tau_s) / (1 + k_val * tau_s) ;
                        end
                        X_model = (1 - beta) * X_reactor ;
                        paramStr = sprintf('beta=%.3f', beta) ;

                    case 'CSTR + Bypass + Vol. muerto'
                        alpha = p1 ;
                        beta = p2 ;
                        rtd_comb = RTD.cstr_with_bypass_and_dead(tau_val, alpha, beta) ;
                        tau_s = alpha * tau_val / (1 - beta) ;
                        if is2nd
                            Da_s = k_val * CA0_val * tau_s ;
                            X_reactor = (-1 + sqrt(1 + 4*Da_s)) / (2*Da_s) ;
                        else
                            X_reactor = (k_val * tau_s) / (1 + k_val * tau_s) ;
                        end
                        X_model = (1 - beta) * X_reactor ;
                        paramStr = sprintf('alpha=%.3f, beta=%.3f', alpha, beta) ;

                    case 'CSTR + PFR en serie'
                        tau_cstr = p1 ;
                        tau_pfr = p2 ;
                        rtd_comb = RTD.from_cstr_series_with_pfr(tau_cstr, tau_pfr) ;
                        if is2nd
                            Da_pfr = k_val * CA0_val * tau_pfr ;
                            X_pfr_local = Da_pfr / (1 + Da_pfr) ;
                            CA_after_pfr = CA0_val * (1 - X_pfr_local) ;
                            Da_cstr = k_val * CA_after_pfr * tau_cstr ;
                            X_cstr_local = (-1 + sqrt(1 + 4*Da_cstr)) / (2*Da_cstr) ;
                            X_model = 1 - (1 - X_pfr_local) * (1 - X_cstr_local) ;
                        else
                            X_pfr_local = 1 - exp(-k_val * tau_pfr) ;
                            X_cstr_local = (k_val * tau_cstr) / (1 + k_val * tau_cstr) ;
                            X_model = 1 - (1 - X_pfr_local) * (1 - X_cstr_local) ;
                        end
                        paramStr = sprintf('tau_C=%.2f, tau_P=%.2f', tau_cstr, tau_pfr) ;
                end

                X_model = max(0, min(1, X_model)) ;

                % Reference ideal reactors
                if is2nd
                    Da_ref = k_val * CA0_val * tau_val ;
                    X_cstr = (-1 + sqrt(1 + 4*Da_ref)) / (2*Da_ref) ;
                    X_pfr = Da_ref / (1 + Da_ref) ;
                else
                    X_cstr = Da / (1 + Da) ;
                    X_pfr = 1 - exp(-Da) ;
                end
                X_cstr = max(0, min(1, X_cstr)) ;
                X_pfr = max(0, min(1, X_pfr)) ;

                % Update results
                app.Comb_ResultParams.Text = paramStr ;
                app.Comb_ResultX.Text = sprintf('%.4f', X_model) ;
                app.Comb_ResultXcstr.Text = sprintf('%.4f', X_cstr) ;
                app.Comb_ResultXpfr.Text = sprintf('%.4f', X_pfr) ;

                % Update plots
                app.Comb_updatePlots(rtd_comb, model, X_model, X_cstr, X_pfr, paramStr) ;

            catch ME
                uialert(app.UIFigure, ...
                    sprintf('Error en el modelo combinado: %s', ME.message), ...
                    'Error de calculo') ;
            end
        end

        function Comb_updatePlots(app, rtd_comb, model, X_model, X_cstr, X_pfr, paramStr)

            % ---- Plot 1: E(t) ----
            cla(app.Comb_AxesEt) ;

            % Plot combined model E(t)
            plot(app.Comb_AxesEt, rtd_comb.t, rtd_comb.Et, 'b-', 'LineWidth', 1.5) ;
            hold(app.Comb_AxesEt, 'on') ;

            % Overlay ideal CSTR for reference
            tau_val = app.Comb_tauField.Value ;
            rtd_ideal = RTD.ideal_cstr(tau_val) ;
            plot(app.Comb_AxesEt, rtd_ideal.t, rtd_ideal.Et, 'r--', 'LineWidth', 1) ;
            hold(app.Comb_AxesEt, 'off') ;

            title(app.Comb_AxesEt, sprintf('E(t): %s', model)) ;
            xlabel(app.Comb_AxesEt, 't [s]') ;
            ylabel(app.Comb_AxesEt, 'E(t) [1/s]') ;
            legend(app.Comb_AxesEt, model, 'CSTR ideal', 'Location', 'best') ;

            % Add parameters annotation
            text(app.Comb_AxesEt, 0.95, 0.85, paramStr, ...
                'Units', 'normalized', 'HorizontalAlignment', 'right', ...
                'FontSize', 9, 'BackgroundColor', [1 1 1 0.8], ...
                'EdgeColor', [0.7 0.7 0.7]) ;

            % ---- Plot 2: Comparison bar chart ----
            cla(app.Comb_AxesComparison) ;
            bar_data = [X_pfr ; X_model ; X_cstr] ;
            b = bar(app.Comb_AxesComparison, bar_data) ;
            b.FaceColor = 'flat' ;
            b.CData = [0.3 0.8 0.3 ; 0.3 0.6 0.9 ; 0.9 0.3 0.3] ;

            % Short label for model
            modelShort = strrep(model, 'CSTR + ', '') ;
            set(app.Comb_AxesComparison, 'XTickLabel', ...
                {'PFR ideal', modelShort, 'CSTR ideal'}) ;
            ylabel(app.Comb_AxesComparison, 'Conversion X') ;
            title(app.Comb_AxesComparison, 'Comparacion de conversion') ;
            ylim(app.Comb_AxesComparison, [0 1.12]) ;

            % Value labels
            hold(app.Comb_AxesComparison, 'on') ;
            vals = [X_pfr, X_model, X_cstr] ;
            for idx = 1:3
                if vals(idx) > 0.85
                    ypos = vals(idx) - 0.06 ;
                    txtColor = [1 1 1] ;
                else
                    ypos = vals(idx) + 0.03 ;
                    txtColor = [0 0 0] ;
                end
                text(app.Comb_AxesComparison, idx, ypos, ...
                    sprintf('%.4f', vals(idx)), ...
                    'HorizontalAlignment', 'center', ...
                    'FontWeight', 'bold', 'FontSize', 10, ...
                    'Color', txtColor) ;
            end
            hold(app.Comb_AxesComparison, 'off') ;

            % ---- Plot 3: Sensitivity to main parameter ----
            cla(app.Comb_AxesSensitivity) ;
            k_val = app.Comb_kField.Value ;
            kinetics = app.Comb_KineticsDropdown.Value ;
            is2nd = contains(kinetics, '2do') ;
            if is2nd
                CA0_val = app.Comb_CA0Field.Value ;
            end

            switch model
                case 'CSTR + Vol. muerto'
                    pVec = linspace(0.1, 1.0, 30) ;
                    X_vec = zeros(size(pVec)) ;
                    for jj = 1:length(pVec)
                        tau_eff = pVec(jj) * tau_val ;
                        if is2nd
                            Da_e = k_val * CA0_val * tau_eff ;
                            X_vec(jj) = (-1 + sqrt(1 + 4*Da_e)) / (2*Da_e) ;
                        else
                            X_vec(jj) = (k_val * tau_eff) / (1 + k_val * tau_eff) ;
                        end
                    end
                    plot(app.Comb_AxesSensitivity, pVec, X_vec, 'b-', 'LineWidth', 1.5) ;
                    xlabel(app.Comb_AxesSensitivity, 'alpha') ;

                case 'CSTR + Bypass'
                    pVec = linspace(0, 0.9, 30) ;
                    X_vec = zeros(size(pVec)) ;
                    for jj = 1:length(pVec)
                        tau_s = tau_val / (1 - pVec(jj)) ;
                        if is2nd
                            Da_s = k_val * CA0_val * tau_s ;
                            X_r = (-1 + sqrt(1 + 4*Da_s)) / (2*Da_s) ;
                        else
                            X_r = (k_val * tau_s) / (1 + k_val * tau_s) ;
                        end
                        X_vec(jj) = (1 - pVec(jj)) * X_r ;
                    end
                    plot(app.Comb_AxesSensitivity, pVec, X_vec, 'b-', 'LineWidth', 1.5) ;
                    xlabel(app.Comb_AxesSensitivity, 'beta') ;

                case 'CSTR + Bypass + Vol. muerto'
                    % Sweep alpha at fixed beta
                    beta_fixed = app.Comb_Param2Field.Value ;
                    pVec = linspace(0.1, 1.0, 30) ;
                    X_vec = zeros(size(pVec)) ;
                    for jj = 1:length(pVec)
                        tau_s = pVec(jj) * tau_val / (1 - beta_fixed) ;
                        if is2nd
                            Da_s = k_val * CA0_val * tau_s ;
                            X_r = (-1 + sqrt(1 + 4*Da_s)) / (2*Da_s) ;
                        else
                            X_r = (k_val * tau_s) / (1 + k_val * tau_s) ;
                        end
                        X_vec(jj) = (1 - beta_fixed) * X_r ;
                    end
                    plot(app.Comb_AxesSensitivity, pVec, X_vec, 'b-', 'LineWidth', 1.5) ;
                    xlabel(app.Comb_AxesSensitivity, sprintf('alpha (beta=%.2f)', beta_fixed)) ;

                case 'CSTR + PFR en serie'
                    % Sweep tau_CSTR fraction
                    tau_total_s = app.Comb_Param1Field.Value + app.Comb_Param2Field.Value ;
                    pVec = linspace(0.05, 0.95, 30) ;
                    X_vec = zeros(size(pVec)) ;
                    for jj = 1:length(pVec)
                        tc = pVec(jj) * tau_total_s ;
                        tp = (1 - pVec(jj)) * tau_total_s ;
                        if is2nd
                            Da_p = k_val * CA0_val * tp ;
                            Xp = Da_p / (1 + Da_p) ;
                            CA_p = CA0_val * (1 - Xp) ;
                            Da_c = k_val * CA_p * tc ;
                            Xc = (-1 + sqrt(1 + 4*Da_c)) / (2*Da_c) ;
                            X_vec(jj) = 1 - (1 - Xp) * (1 - Xc) ;
                        else
                            Xp = 1 - exp(-k_val * tp) ;
                            Xc = (k_val * tc) / (1 + k_val * tc) ;
                            X_vec(jj) = 1 - (1 - Xp) * (1 - Xc) ;
                        end
                    end
                    plot(app.Comb_AxesSensitivity, pVec, X_vec, 'b-', 'LineWidth', 1.5) ;
                    xlabel(app.Comb_AxesSensitivity, 'fraccion tau_{CSTR} / tau_{total}') ;
            end

            ylabel(app.Comb_AxesSensitivity, 'Conversion X') ;
            title(app.Comb_AxesSensitivity, 'Sensibilidad al parametro') ;
        end

        %% ============== TAB 7: OPTIMIZATION ==============
        function createOptimizationTab(app)

            app.OptTab = uitab(app.TabGroup, 'Title', 'Optimization') ;

            mainGrid = uigridlayout(app.OptTab, [1 2]) ;
            mainGrid.ColumnWidth = {320, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'Ajuste de modelos RTD') ;
            leftGrid = uigridlayout(leftPanel, [22 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 22) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: Section header - Data
            lbl = uilabel(leftGrid, 'Text', 'Datos experimentales', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = [1 2] ;

            % Row 2: Data source
            lbl = uilabel(leftGrid, 'Text', 'Fuente:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 2 ; lbl.Layout.Column = 1 ;
            app.Opt_DataSourceDropdown = uidropdown(leftGrid, ...
                'Items', {'Desde workspace', 'Desde archivo', 'Desde RTD (Tab 1)'}, ...
                'Value', 'Desde workspace', ...
                'ValueChangedFcn', @(~,~) app.Opt_sourceChanged()) ;
            app.Opt_DataSourceDropdown.Layout.Row = 2 ;
            app.Opt_DataSourceDropdown.Layout.Column = 2 ;

            % Row 3: t variable name
            app.Opt_tVarLabel = uilabel(leftGrid, 'Text', 'Variable t [s]:') ;
            app.Opt_tVarLabel.Layout.Row = 3 ; app.Opt_tVarLabel.Layout.Column = 1 ;
            app.Opt_tVarField = uieditfield(leftGrid, 'text', 'Value', 't') ;
            app.Opt_tVarField.Layout.Row = 3 ; app.Opt_tVarField.Layout.Column = 2 ;

            % Row 4: E(t) variable name
            app.Opt_EtVarLabel = uilabel(leftGrid, 'Text', 'Variable E(t) [1/s]:') ;
            app.Opt_EtVarLabel.Layout.Row = 4 ; app.Opt_EtVarLabel.Layout.Column = 1 ;
            app.Opt_EtVarField = uieditfield(leftGrid, 'text', 'Value', 'Et') ;
            app.Opt_EtVarField.Layout.Row = 4 ; app.Opt_EtVarField.Layout.Column = 2 ;

            % Row 5: Import button
            app.Opt_ImportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Cargar datos', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [1 1 1], ...
                'FontColor', [0.8 0 0], ...
                'ButtonPushedFcn', @(~,~) app.Opt_loadData()) ;
            app.Opt_ImportButton.Layout.Row = 5 ;
            app.Opt_ImportButton.Layout.Column = [1 2] ;

            % Row 6: Import status + tau info
            app.Opt_ImportLabel = uilabel(leftGrid, 'Text', '') ;
            app.Opt_ImportLabel.Layout.Row = 6 ;
            app.Opt_ImportLabel.Layout.Column = [1 2] ;
            app.Opt_ImportLabel.FontColor = [0 0.5 0] ;
            app.Opt_ImportLabel.WordWrap = 'on' ;

            % Row 7: tau display
            lbl = uilabel(leftGrid, 'Text', 'tau experimental:') ;
            lbl.Layout.Row = 7 ; lbl.Layout.Column = 1 ;
            app.Opt_tauLabel = uilabel(leftGrid, 'Text', '-- s') ;
            app.Opt_tauLabel.Layout.Row = 7 ;
            app.Opt_tauLabel.Layout.Column = 2 ;
            app.Opt_tauLabel.FontWeight = 'bold' ;

            % Row 8: Section header - Models
            lbl = uilabel(leftGrid, 'Text', 'Modelos a ajustar', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 8 ; lbl.Layout.Column = [1 2] ;

            % Row 9-14: Model checkboxes
            app.Opt_CheckTIS = uicheckbox(leftGrid, ...
                'Text', 'Tanques en serie (N)', 'Value', true) ;
            app.Opt_CheckTIS.Layout.Row = 9 ; app.Opt_CheckTIS.Layout.Column = [1 2] ;

            app.Opt_CheckDispOpen = uicheckbox(leftGrid, ...
                'Text', 'Dispersion abierto-abierto (Bo)', 'Value', true) ;
            app.Opt_CheckDispOpen.Layout.Row = 10 ; app.Opt_CheckDispOpen.Layout.Column = [1 2] ;

            app.Opt_CheckDispClosed = uicheckbox(leftGrid, ...
                'Text', 'Dispersion cerrado-cerrado (Bo)', 'Value', true) ;
            app.Opt_CheckDispClosed.Layout.Row = 11 ; app.Opt_CheckDispClosed.Layout.Column = [1 2] ;

            app.Opt_CheckDeadVol = uicheckbox(leftGrid, ...
                'Text', 'CSTR + Volumen muerto (alpha)', 'Value', false) ;
            app.Opt_CheckDeadVol.Layout.Row = 12 ; app.Opt_CheckDeadVol.Layout.Column = [1 2] ;

            app.Opt_CheckBypass = uicheckbox(leftGrid, ...
                'Text', 'CSTR + Bypass (beta)', 'Value', false) ;
            app.Opt_CheckBypass.Layout.Row = 13 ; app.Opt_CheckBypass.Layout.Column = [1 2] ;

            app.Opt_CheckBypassDead = uicheckbox(leftGrid, ...
                'Text', 'CSTR + Bypass + Vol. muerto (alpha, beta)', 'Value', false) ;
            app.Opt_CheckBypassDead.Layout.Row = 14 ; app.Opt_CheckBypassDead.Layout.Column = [1 2] ;

            % Row 15: Fit button
            app.Opt_FitButton = uibutton(leftGrid, 'push', ...
                'Text', 'Ajustar modelos', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Opt_fitModels()) ;
            app.Opt_FitButton.Layout.Row = 15 ;
            app.Opt_FitButton.Layout.Column = [1 2] ;

            % Row 16: Results header
            lbl = uilabel(leftGrid, 'Text', 'Resultados:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 16 ; lbl.Layout.Column = [1 2] ;

            % Row 17: Best model label
            app.Opt_ResultBestLabel = uilabel(leftGrid, 'Text', '--') ;
            app.Opt_ResultBestLabel.Layout.Row = 17 ;
            app.Opt_ResultBestLabel.Layout.Column = [1 2] ;
            app.Opt_ResultBestLabel.FontWeight = 'bold' ;
            app.Opt_ResultBestLabel.FontColor = [0 0.4 0.8] ;
            app.Opt_ResultBestLabel.WordWrap = 'on' ;

            % Row 18-22: Results table
            app.Opt_ResultTable = uitable(leftGrid, ...
                'ColumnName', {'Modelo', 'Params', 'SSE', 'R^2', 'AIC'}, ...
                'ColumnWidth', {95, 80, 55, 50, 50}, ...
                'RowName', {}, ...
                'ColumnEditable', false) ;
            app.Opt_ResultTable.Layout.Row = [18 22] ;
            app.Opt_ResultTable.Layout.Column = [1 2] ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Resultados del ajuste') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % Data + fitted curves
            app.Opt_AxesDataFit = uiaxes(plotGrid) ;
            app.Opt_AxesDataFit.Layout.Row = 1 ;
            app.Opt_AxesDataFit.Layout.Column = [1 2] ;
            title(app.Opt_AxesDataFit, 'Datos experimentales vs modelos ajustados') ;
            xlabel(app.Opt_AxesDataFit, 't [s]') ;
            ylabel(app.Opt_AxesDataFit, 'E(t) [1/s]') ;

            % Residuals
            app.Opt_AxesResiduals = uiaxes(plotGrid) ;
            app.Opt_AxesResiduals.Layout.Row = 2 ;
            app.Opt_AxesResiduals.Layout.Column = 1 ;
            title(app.Opt_AxesResiduals, 'Residuos') ;
            xlabel(app.Opt_AxesResiduals, 't [s]') ;
            ylabel(app.Opt_AxesResiduals, 'E_{exp} - E_{mod} [1/s]') ;

            % R^2 comparison bar chart
            app.Opt_AxesComparison = uiaxes(plotGrid) ;
            app.Opt_AxesComparison.Layout.Row = 2 ;
            app.Opt_AxesComparison.Layout.Column = 2 ;
            title(app.Opt_AxesComparison, 'Comparacion R^2') ;
            ylabel(app.Opt_AxesComparison, 'R^2') ;
        end

        %% ============== OPTIMIZATION CALLBACKS ==============

        function Opt_sourceChanged(app)
            source = app.Opt_DataSourceDropdown.Value ;
            if strcmp(source, 'Desde RTD (Tab 1)')
                app.Opt_tVarLabel.Visible = 'off' ;
                app.Opt_tVarField.Visible = 'off' ;
                app.Opt_EtVarLabel.Visible = 'off' ;
                app.Opt_EtVarField.Visible = 'off' ;
                app.Opt_ImportButton.Text = 'Cargar desde RTD (Tab 1)' ;
            else
                app.Opt_tVarLabel.Visible = 'on' ;
                app.Opt_tVarField.Visible = 'on' ;
                app.Opt_EtVarLabel.Visible = 'on' ;
                app.Opt_EtVarField.Visible = 'on' ;
                if strcmp(source, 'Desde archivo')
                    app.Opt_ImportButton.Text = 'Importar archivo' ;
                else
                    app.Opt_ImportButton.Text = 'Cargar datos' ;
                end
            end
        end

        function Opt_loadData(app)
            try
                source = app.Opt_DataSourceDropdown.Value ;

                if strcmp(source, 'Desde RTD (Tab 1)')
                    % Load from current RTD object in Tab 1
                    if isempty(app.rtd) || isempty(app.rtd.t)
                        uialert(app.UIFigure, ...
                            'No hay RTD generada en Tab 1. Genera una RTD primero.', ...
                            'Sin datos RTD') ;
                        return
                    end
                    app.opt_exp_t = app.rtd.t ;
                    app.opt_exp_Et = app.rtd.Et ;
                    app.Opt_ImportLabel.Text = sprintf( ...
                        'Cargado desde Tab 1: %d puntos, fuente: %s', ...
                        length(app.opt_exp_t), app.rtd.source) ;

                elseif strcmp(source, 'Desde archivo')
                    % Import from file
                    [file, filepath] = uigetfile( ...
                        {'*.xlsx;*.xls;*.csv;*.tsv', 'Archivos de datos' ; ...
                         '*.*', 'Todos los archivos'}, ...
                        'Seleccionar archivo de datos experimentales') ;
                    if isequal(file, 0), return ; end

                    fullPath = fullfile(filepath, file) ;
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
                            'El archivo debe tener al menos 2 columnas (t y E(t)).', ...
                            'Error de importacion') ;
                        return
                    end

                    data = data(~any(isnan(data(:,1:2)), 2), :) ;
                    app.opt_exp_t = data(:, 1)' ;
                    app.opt_exp_Et = data(:, 2)' ;
                    app.Opt_ImportLabel.Text = sprintf( ...
                        'Cargado: %s (%d puntos)', file, length(app.opt_exp_t)) ;

                else
                    % From workspace
                    t_var = app.Opt_tVarField.Value ;
                    Et_var = app.Opt_EtVarField.Value ;
                    app.opt_exp_t = evalin('base', t_var) ;
                    app.opt_exp_Et = evalin('base', Et_var) ;
                    app.Opt_ImportLabel.Text = sprintf( ...
                        'Cargado desde workspace: %d puntos', length(app.opt_exp_t)) ;
                end

                % Ensure row vectors
                app.opt_exp_t = app.opt_exp_t(:)' ;
                app.opt_exp_Et = app.opt_exp_Et(:)' ;

                % Ensure non-negative E(t)
                app.opt_exp_Et = max(app.opt_exp_Et, 0) ;

                % Compute experimental tau
                area = trapz(app.opt_exp_t, app.opt_exp_Et) ;
                if area > 0
                    Et_norm = app.opt_exp_Et / area ;
                    app.opt_exp_tau = trapz(app.opt_exp_t, app.opt_exp_t .* Et_norm) ;
                else
                    app.opt_exp_tau = app.opt_exp_t(end) / 2 ;
                end

                app.Opt_tauLabel.Text = sprintf('%.4f s', app.opt_exp_tau) ;
                app.Opt_ImportLabel.FontColor = [0 0.5 0] ;
                app.Opt_FitButton.Enable = 'on' ;

                % Preview plot of loaded data
                cla(app.Opt_AxesDataFit) ;
                plot(app.Opt_AxesDataFit, app.opt_exp_t, app.opt_exp_Et, ...
                    'ko', 'MarkerSize', 5, 'MarkerFaceColor', [0.3 0.3 0.3]) ;
                title(app.Opt_AxesDataFit, 'Datos experimentales cargados') ;
                xlabel(app.Opt_AxesDataFit, 't [s]') ;
                ylabel(app.Opt_AxesDataFit, 'E(t) [1/s]') ;
                legend(app.Opt_AxesDataFit, 'Datos exp.', 'Location', 'best') ;

            catch ME
                app.Opt_ImportLabel.Text = ME.message ;
                app.Opt_ImportLabel.FontColor = [0.8 0 0] ;
                uialert(app.UIFigure, ...
                    sprintf('Error al cargar datos: %s\nSugerencia: comprueba que las variables existen en el workspace.', ME.message), ...
                    'Error de carga') ;
            end
        end

        function Opt_fitModels(app)
            % Fit selected RTD models to experimental E(t) data.
            % Uses fminsearch (Nelder-Mead) to minimize SSE.
            % Falls back to lsqcurvefit if available.
            %
            % Inputs (from app properties):
            %   app.opt_exp_t   [1 x N] time vector [s]
            %   app.opt_exp_Et  [1 x N] E(t) values  [1/s]
            %   app.opt_exp_tau [scalar] experimental mean residence time [s]
            %
            % Outputs (displayed in app):
            %   Table with Model, Params, SSE, R^2, AIC
            %   Plots: data vs fits, residuals, R^2 comparison

            try
                t_exp = app.opt_exp_t ;
                Et_exp = app.opt_exp_Et ;
                tau_exp = app.opt_exp_tau ;
                n_pts = length(t_exp) ;

                % Normalize E(t) for fitting
                area_exp = trapz(t_exp, Et_exp) ;
                if area_exp > 0
                    Et_exp = Et_exp / area_exp ;
                end

                % SST for R^2
                Et_mean = mean(Et_exp) ;
                SST = sum((Et_exp - Et_mean).^2) ;

                % Estimate initial parameters from moments
                sigma2_exp = trapz(t_exp, (t_exp - tau_exp).^2 .* Et_exp) ;
                sigma2_theta = sigma2_exp / tau_exp^2 ;
                N_est = max(1, 1 / sigma2_theta) ;
                Bo_est = max(0.001, sigma2_theta / 2) ;

                % fminsearch options
                opts = optimset('Display', 'off', 'MaxFunEvals', 2000, 'TolFun', 1e-10) ;

                % Collect results
                results = struct('name', {}, 'params', {}, 'paramStr', {}, ...
                                 'SSE', {}, 'R2', {}, 'AIC', {}, ...
                                 'Et_fit', {}, 'nParams', {}) ;

                % ---- TIS ----
                if app.Opt_CheckTIS.Value
                    objFun = @(x) sum((Et_exp - NonIdealReactorApp.evalModelOnGrid(RTD.tanks_in_series(max(1,x(1)), tau_exp, t_exp), t_exp)).^2) ;
                    N_opt = fminsearch(objFun, N_est, opts) ;
                    N_opt = max(1, N_opt) ;
                    rtd_fit = RTD.tanks_in_series(N_opt, tau_exp, t_exp) ;
                    Et_fit = NonIdealReactorApp.evalModelOnGrid(rtd_fit, t_exp) ;
                    SSE = sum((Et_exp - Et_fit).^2) ;
                    R2 = 1 - SSE / SST ;
                    AIC = n_pts * log(SSE/n_pts) + 2*1 ;
                    r = struct('name', 'TIS', 'params', N_opt, ...
                               'paramStr', sprintf('N=%.2f', N_opt), ...
                               'SSE', SSE, 'R2', R2, 'AIC', AIC, ...
                               'Et_fit', Et_fit, 'nParams', 1) ;
                    results(end+1) = r ;
                end

                % ---- Dispersion open-open ----
                if app.Opt_CheckDispOpen.Value
                    objFun = @(x) sum((Et_exp - NonIdealReactorApp.evalModelOnGrid(RTD.dispersion_open(max(1e-6,x(1)), tau_exp, t_exp), t_exp)).^2) ;
                    Bo_opt = fminsearch(objFun, Bo_est, opts) ;
                    Bo_opt = max(1e-6, Bo_opt) ;
                    rtd_fit = RTD.dispersion_open(Bo_opt, tau_exp, t_exp) ;
                    Et_fit = NonIdealReactorApp.evalModelOnGrid(rtd_fit, t_exp) ;
                    SSE = sum((Et_exp - Et_fit).^2) ;
                    R2 = 1 - SSE / SST ;
                    AIC = n_pts * log(SSE/n_pts) + 2*1 ;
                    r = struct('name', 'Disp. abierto', 'params', Bo_opt, ...
                               'paramStr', sprintf('Bo=%.4f', Bo_opt), ...
                               'SSE', SSE, 'R2', R2, 'AIC', AIC, ...
                               'Et_fit', Et_fit, 'nParams', 1) ;
                    results(end+1) = r ;
                end

                % ---- Dispersion closed-closed ----
                if app.Opt_CheckDispClosed.Value
                    objFun = @(x) sum((Et_exp - NonIdealReactorApp.evalModelOnGrid(RTD.dispersion_closed(max(1e-6,x(1)), tau_exp, t_exp), t_exp)).^2) ;
                    Bo_opt = fminsearch(objFun, Bo_est, opts) ;
                    Bo_opt = max(1e-6, Bo_opt) ;
                    rtd_fit = RTD.dispersion_closed(Bo_opt, tau_exp, t_exp) ;
                    Et_fit = NonIdealReactorApp.evalModelOnGrid(rtd_fit, t_exp) ;
                    SSE = sum((Et_exp - Et_fit).^2) ;
                    R2 = 1 - SSE / SST ;
                    AIC = n_pts * log(SSE/n_pts) + 2*1 ;
                    r = struct('name', 'Disp. cerrado', 'params', Bo_opt, ...
                               'paramStr', sprintf('Bo=%.4f', Bo_opt), ...
                               'SSE', SSE, 'R2', R2, 'AIC', AIC, ...
                               'Et_fit', Et_fit, 'nParams', 1) ;
                    results(end+1) = r ;
                end

                % ---- CSTR + Dead Volume ----
                if app.Opt_CheckDeadVol.Value
                    objFun = @(x) sum((Et_exp - NonIdealReactorApp.evalModelOnGrid(RTD.cstr_with_dead_volume(tau_exp, max(0.01,min(1,x(1))), t_exp), t_exp)).^2) ;
                    alpha_opt = fminsearch(objFun, 0.8, opts) ;
                    alpha_opt = max(0.01, min(1, alpha_opt)) ;
                    rtd_fit = RTD.cstr_with_dead_volume(tau_exp, alpha_opt, t_exp) ;
                    Et_fit = NonIdealReactorApp.evalModelOnGrid(rtd_fit, t_exp) ;
                    SSE = sum((Et_exp - Et_fit).^2) ;
                    R2 = 1 - SSE / SST ;
                    AIC = n_pts * log(SSE/n_pts) + 2*1 ;
                    r = struct('name', 'CSTR+Dead', 'params', alpha_opt, ...
                               'paramStr', sprintf('alpha=%.3f', alpha_opt), ...
                               'SSE', SSE, 'R2', R2, 'AIC', AIC, ...
                               'Et_fit', Et_fit, 'nParams', 1) ;
                    results(end+1) = r ;
                end

                % ---- CSTR + Bypass ----
                if app.Opt_CheckBypass.Value
                    objFun = @(x) sum((Et_exp - NonIdealReactorApp.evalModelOnGrid(RTD.cstr_with_bypass(tau_exp, max(0,min(0.99,x(1))), t_exp), t_exp)).^2) ;
                    beta_opt = fminsearch(objFun, 0.1, opts) ;
                    beta_opt = max(0, min(0.99, beta_opt)) ;
                    rtd_fit = RTD.cstr_with_bypass(tau_exp, beta_opt, t_exp) ;
                    Et_fit = NonIdealReactorApp.evalModelOnGrid(rtd_fit, t_exp) ;
                    SSE = sum((Et_exp - Et_fit).^2) ;
                    R2 = 1 - SSE / SST ;
                    AIC = n_pts * log(SSE/n_pts) + 2*1 ;
                    r = struct('name', 'CSTR+Bypass', 'params', beta_opt, ...
                               'paramStr', sprintf('beta=%.3f', beta_opt), ...
                               'SSE', SSE, 'R2', R2, 'AIC', AIC, ...
                               'Et_fit', Et_fit, 'nParams', 1) ;
                    results(end+1) = r ;
                end

                % ---- CSTR + Bypass + Dead Volume ----
                if app.Opt_CheckBypassDead.Value
                    objFun = @(x) sum((Et_exp - NonIdealReactorApp.evalModelOnGrid( ...
                        RTD.cstr_with_bypass_and_dead(tau_exp, ...
                            max(0.01,min(1,x(1))), max(0,min(0.99,x(2))), t_exp), ...
                        t_exp)).^2) ;
                    x_opt = fminsearch(objFun, [0.8, 0.1], opts) ;
                    alpha_opt = max(0.01, min(1, x_opt(1))) ;
                    beta_opt = max(0, min(0.99, x_opt(2))) ;
                    rtd_fit = RTD.cstr_with_bypass_and_dead(tau_exp, alpha_opt, beta_opt, t_exp) ;
                    Et_fit = NonIdealReactorApp.evalModelOnGrid(rtd_fit, t_exp) ;
                    SSE = sum((Et_exp - Et_fit).^2) ;
                    R2 = 1 - SSE / SST ;
                    AIC = n_pts * log(SSE/n_pts) + 2*2 ;
                    r = struct('name', 'CSTR+Byp+Dead', 'params', [alpha_opt, beta_opt], ...
                               'paramStr', sprintf('a=%.3f b=%.3f', alpha_opt, beta_opt), ...
                               'SSE', SSE, 'R2', R2, 'AIC', AIC, ...
                               'Et_fit', Et_fit, 'nParams', 2) ;
                    results(end+1) = r ;
                end

                if isempty(results)
                    uialert(app.UIFigure, ...
                        'Selecciona al menos un modelo para ajustar.', ...
                        'Sin modelos') ;
                    return
                end

                % Display results
                app.Opt_displayResults(results) ;

            catch ME
                uialert(app.UIFigure, ...
                    sprintf('Error en el ajuste: %s', ME.message), ...
                    'Error de optimizacion') ;
            end
        end

        function Opt_displayResults(app, results)
            % Display fitting results in table and plots.
            % Inputs:
            %   results - struct array with fields: name, paramStr, SSE, R2, AIC, Et_fit

            t_exp = app.opt_exp_t ;
            Et_exp = app.opt_exp_Et ;
            area_exp = trapz(t_exp, Et_exp) ;
            if area_exp > 0
                Et_exp_norm = Et_exp / area_exp ;
            else
                Et_exp_norm = Et_exp ;
            end

            nModels = length(results) ;

            % ---- Fill table ----
            tableData = cell(nModels, 5) ;
            for i = 1:nModels
                tableData{i,1} = results(i).name ;
                tableData{i,2} = results(i).paramStr ;
                tableData{i,3} = sprintf('%.2e', results(i).SSE) ;
                tableData{i,4} = sprintf('%.4f', results(i).R2) ;
                tableData{i,5} = sprintf('%.1f', results(i).AIC) ;
            end
            app.Opt_ResultTable.Data = tableData ;

            % Find best model (highest R^2)
            R2_vals = [results.R2] ;
            [~, bestIdx] = max(R2_vals) ;
            app.Opt_ResultBestLabel.Text = sprintf( ...
                'Mejor modelo: %s (R^2 = %.4f)', ...
                results(bestIdx).name, results(bestIdx).R2) ;

            % ---- Colors for models ----
            colors = [0.0 0.45 0.74 ;   % azul
                      0.85 0.33 0.10 ;   % naranja
                      0.47 0.67 0.19 ;   % verde
                      0.49 0.18 0.56 ;   % morado
                      0.93 0.69 0.13 ;   % amarillo
                      0.30 0.75 0.93] ;  % cyan

            % ---- Plot 1: Data vs fitted curves ----
            cla(app.Opt_AxesDataFit) ;
            plot(app.Opt_AxesDataFit, t_exp, Et_exp_norm, ...
                'ko', 'MarkerSize', 5, 'MarkerFaceColor', [0.3 0.3 0.3]) ;
            hold(app.Opt_AxesDataFit, 'on') ;
            legendEntries = {'Datos exp.'} ;
            for i = 1:nModels
                cidx = mod(i-1, size(colors,1)) + 1 ;
                plot(app.Opt_AxesDataFit, t_exp, results(i).Et_fit, ...
                    '-', 'LineWidth', 1.5, 'Color', colors(cidx,:)) ;
                legendEntries{end+1} = results(i).name ; %#ok<AGROW>
            end
            hold(app.Opt_AxesDataFit, 'off') ;
            title(app.Opt_AxesDataFit, 'Datos experimentales vs modelos ajustados') ;
            xlabel(app.Opt_AxesDataFit, 't [s]') ;
            ylabel(app.Opt_AxesDataFit, 'E(t) [1/s]') ;
            legend(app.Opt_AxesDataFit, legendEntries, 'Location', 'best') ;

            % ---- Plot 2: Residuals ----
            cla(app.Opt_AxesResiduals) ;
            hold(app.Opt_AxesResiduals, 'on') ;
            for i = 1:nModels
                cidx = mod(i-1, size(colors,1)) + 1 ;
                residuals = Et_exp_norm - results(i).Et_fit ;
                plot(app.Opt_AxesResiduals, t_exp, residuals, ...
                    '-', 'LineWidth', 1, 'Color', colors(cidx,:)) ;
            end
            yline(app.Opt_AxesResiduals, 0, 'k--') ;
            hold(app.Opt_AxesResiduals, 'off') ;
            title(app.Opt_AxesResiduals, 'Residuos') ;
            xlabel(app.Opt_AxesResiduals, 't [s]') ;
            ylabel(app.Opt_AxesResiduals, 'E_{exp} - E_{mod} [1/s]') ;

            % ---- Plot 3: R^2 bar chart ----
            cla(app.Opt_AxesComparison) ;
            R2_data = [results.R2] ;
            b = bar(app.Opt_AxesComparison, R2_data) ;
            b.FaceColor = 'flat' ;
            for i = 1:nModels
                cidx = mod(i-1, size(colors,1)) + 1 ;
                b.CData(i,:) = colors(cidx,:) ;
            end
            modelNames = {results.name} ;
            set(app.Opt_AxesComparison, 'XTickLabel', modelNames, ...
                'XTickLabelRotation', 30) ;
            ylabel(app.Opt_AxesComparison, 'R^2') ;
            title(app.Opt_AxesComparison, 'Comparacion R^2') ;
            ylim(app.Opt_AxesComparison, [0 1.1]) ;

            % Value labels on bars
            hold(app.Opt_AxesComparison, 'on') ;
            for i = 1:nModels
                text(app.Opt_AxesComparison, i, R2_data(i) + 0.03, ...
                    sprintf('%.3f', R2_data(i)), ...
                    'HorizontalAlignment', 'center', ...
                    'FontWeight', 'bold', 'FontSize', 9) ;
            end
            hold(app.Opt_AxesComparison, 'off') ;
        end

    end

    methods (Static, Access = private)

        function Et_interp = evalModelOnGrid(rtd_model, t_grid)
            % Interpolate model E(t) onto an experimental time grid
            % and normalize so that integral = 1.
            %
            % Inputs:
            %   rtd_model - RTD object with .t and .Et
            %   t_grid    - [1 x N] target time vector [s]
            % Outputs:
            %   Et_interp - [1 x N] normalized E(t) on t_grid [1/s]

            Et_interp = interp1(rtd_model.t, rtd_model.Et, t_grid, 'linear', 0) ;
            area_m = trapz(t_grid, Et_interp) ;
            if area_m > 0
                Et_interp = Et_interp / area_m ;
            end
        end

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
