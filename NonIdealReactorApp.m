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
% Created: March 21, 2026. Last update: March 28, 2026
% =========================================================================

    properties (Access = private)
        % Main UI
        UIFigure
        TabGroup
        StatusBar               % Status bar label at bottom of figure

        % Shared state
        rtd                 % Current RTD object (shared across tabs)
        DisplayControls = struct()
        DisplayCache = struct()

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
        RTD_ExpTUnitDropdown
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
        RTD_EqTimeUnitLabel
        RTD_EqTimeUnitDropdown
        RTD_EqNptsLabel
        RTD_EqNptsField
        RTD_GenerateButton
        RTD_ExportButton
        RTD_ExportNameField
        RTD_ExportCounter = 1    % Auto-increment counter for export names
        RTD_QvLabel
        RTD_QvField
        RTD_ResultTau
        RTD_ResultTauLabel
        RTD_ResultSigma2
        RTD_ResultSigma2Label
        RTD_ResultSigma2Theta
        RTD_ResultS3
        RTD_ResultN
        RTD_ResultVeff
        RTD_ResultVeffLabel
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
        Pred_CA0Field
        Pred_CA0Label
        Pred_RSNameField        % Name of ReactionSys in workspace
        Pred_RSDefineButton     % Launches defineReactionSysApp (new)
        Pred_RSEditButton       % Launches defineReactionSysApp with loaded RS
        Pred_RSLoadButton       % Loads RS from workspace
        Pred_RSStatusLabel      % Shows loaded RS info
        Pred_RS                 % Loaded ReactionSys object
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
        TIS_CA0Field
        TIS_CA0Label
        TIS_RSNameField         % Name of ReactionSys in workspace
        TIS_RSDefineButton      % Launches defineReactionSysApp (new)
        TIS_RSEditButton        % Launches defineReactionSysApp with loaded RS
        TIS_RSLoadButton        % Loads RS from workspace
        TIS_RSStatusLabel       % Shows loaded RS info
        TIS_RS                  % Loaded ReactionSys object
        TIS_ComputeButton
        TIS_ResultXtis
        TIS_ResultXcstr
        TIS_ResultXpfr
        TIS_ResultNused
        TIS_RefreshButton
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
        Disp_RSDefineButton     % Launches defineReactionSysApp (new)
        Disp_RSEditButton       % Launches defineReactionSysApp with loaded RS
        Disp_RSNameField        % Name of ReactionSys in workspace
        Disp_RSLoadButton       % Loads RS from workspace
        Disp_RSStatusLabel      % Shows loaded RS info
        Disp_RS                 % Loaded ReactionSys object
        Disp_CA0Field
        Disp_CA0Label
        Disp_ComputeButton
        Disp_ResultX
        Disp_ResultXcstr
        Disp_ResultXpfr
        Disp_ResultBo
        Disp_RefreshButton
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
        Conv_RTDStatusLabel         % RTD status for Tab 1 source mode
        Conv_CinEqLabel             % Label for C_in equation
        Conv_CinEqField             % Text field for C_in equation
        Conv_EEqLabel               % Label for E(t) equation
        Conv_EEqField               % Text field for E(t) equation
        Conv_CoutEqLabel            % Label for C_out equation
        Conv_CoutEqField            % Text field for C_out equation
        Conv_TstartLabel            % Label for t_start
        Conv_TstartField            % Numeric field for t_start
        Conv_TendLabel              % Label for t_end
        Conv_TendField              % Numeric field for t_end
        Conv_NptsLabel              % Label for N points
        Conv_NptsField              % Numeric field for N points
        Conv_UsePrevButton          % "Use Previous C_out as C_in" button
        Conv_lastCout               % Stored C_out from last convolution (for chaining)
        Conv_lastTout               % Stored t_out from last convolution (for chaining)

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
                'Resize', 'on', ...
                'AutoResizeChildren', 'off') ;

            % Menu bar
            mFile = uimenu(app.UIFigure, 'Text', 'File') ;
            uimenu(mFile, 'Text', 'Exit', ...
                'MenuSelectedFcn', @(~,~) delete(app.UIFigure)) ;
            mTools = uimenu(app.UIFigure, 'Text', 'Tools') ;
            uimenu(mTools, 'Text', 'Unit Converter', ...
                'MenuSelectedFcn', @(~,~) UnitConverterHelper.launch()) ;
            mHelp = uimenu(app.UIFigure, 'Text', 'Help') ;
            uimenu(mHelp, 'Text', 'User Guide', ...
                'MenuSelectedFcn', @(~,~) app.showHelp()) ;
            uimenu(mHelp, 'Text', 'About', ...
                'MenuSelectedFcn', @(~,~) app.showAbout()) ;

            % Status bar at bottom
            app.StatusBar = uilabel(app.UIFigure, ...
                'Text', '  Ready', ...
                'Position', [0 0 1200 22], ...
                'BackgroundColor', [0.94 0.94 0.94], ...
                'FontSize', 11, ...
                'FontColor', [0.3 0.3 0.3]) ;

            % Create tab group (above status bar)
            app.TabGroup = uitabgroup(app.UIFigure, ...
                'Position', [0 22 1200 728]) ;

            % Build tabs
            app.createRTDTab() ;
            app.createPredictionTab() ;
            app.createTISTab() ;
            app.createDispersionTab() ;
            app.createConvolutionTab() ;
            app.createCombinedTab() ;
            app.createOptimizationTab() ;

            % Assign resize callback AFTER all UI components exist
            app.UIFigure.SizeChangedFcn = @(~,~) app.onFigureResize() ;

            % Show figure
            app.UIFigure.Visible = 'on' ;
        end

    end

    methods (Access = private)

        %% ============== RESPONSIVE RESIZE (T6) ==============

        function onFigureResize(app)
            pos = app.UIFigure.Position ;
            w = pos(3) ; h = pos(4) ;

            % Tab group fills figure above status bar
            app.TabGroup.Position = [0 22 w h - 22] ;

            % Status bar stretches full width at bottom
            app.StatusBar.Position = [0 0 w 22] ;
        end

        %% ============== HELPER: NUMERIC FIELD + UNIT SELECTOR ==============

        function [field, subGrid, btn] = createNumericWithConv(app, parentGrid, row, col, defaultVal, unitCat, varargin)
            % createNumericWithConv  Create a text editfield with a unit dropdown.
            %
            %   [field, subGrid, btn] = app.createNumericWithConv(parentGrid, row, col, defaultVal, unitCat, ...)
            %
            %   The edit field accepts simple arithmetic expressions such as
            %   10/6 or 2*60. Values are converted to SI only when read.

            btn = [] ;

            subGrid = uigridlayout(parentGrid, [1 2], ...
                'ColumnWidth', {'1x', 78}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 2) ;
            subGrid.Layout.Row    = row ;
            subGrid.Layout.Column = col ;

            field = uieditfield(subGrid, 'text', ...
                'Value', InputLayerHelper.formatScalar(defaultVal), ...
                'Tooltip', 'Accepts simple arithmetic expressions. Converted to SI at runtime.') ;
            field.Layout.Row = 1 ; field.Layout.Column = 1 ;

            unitDropdown = uidropdown(subGrid, ...
                'Items', UnitConverterHelper.getUnits(unitCat), ...
                'Value', UnitConverterHelper.defaultUnit(unitCat)) ;
            unitDropdown.Layout.Row = 1 ; unitDropdown.Layout.Column = 2 ;

            field.UserData = struct( ...
                'unitCategory', unitCat, ...
                'unitDropdown', unitDropdown) ;
            app.updateInputFieldCategory(field, unitCat) ;
        end

        function value = readInputField(~, field)
            value = InputLayerHelper.readFieldToSI(field) ;
        end

        function setInputFieldValue(~, field, siValue)
            InputLayerHelper.setFieldFromSI(field, siValue) ;
        end

        function updateInputFieldCategory(~, field, unitCat)
            fieldData = field.UserData ;
            fieldData.unitCategory = unitCat ;
            field.UserData = fieldData ;

            unitDropdown = fieldData.unitDropdown ;
            if isempty(unitDropdown) || ~isvalid(unitDropdown)
                return
            end

            currentUnit = unitDropdown.Value ;
            unitDropdown.Items = UnitConverterHelper.getUnits(unitCat) ;
            if any(strcmp(unitDropdown.Items, currentUnit))
                unitDropdown.Value = currentUnit ;
            else
                unitDropdown.Value = UnitConverterHelper.defaultUnit(unitCat) ;
            end

        end

        function cat = getKCategory(~, dropdown)
            % getKCategory  Return the correct unit converter category for k
            %   based on the current kinetics selection in the given dropdown.
            if contains(dropdown.Value, '2nd')
                cat = 'k_2ndOrder' ;
            else
                cat = 'k_1stOrder' ;
            end
        end

        function dropdown = createDisplayUnitControl(~, parentGrid, row, col, ...
                labelText, category, defaultUnit, callbackFcn)
            subGrid = uigridlayout(parentGrid, [1 2], ...
                'ColumnWidth', {'fit', '1x'}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 4) ;
            subGrid.Layout.Row = row ;
            subGrid.Layout.Column = col ;

            uilabel(subGrid, 'Text', labelText, 'FontSize', 11) ;
            dropdown = uidropdown(subGrid, ...
                'Items', UnitConverterHelper.getUnits(category), ...
                'Value', defaultUnit, ...
                'FontSize', 11, ...
                'ValueChangedFcn', callbackFcn) ;
            dropdown.Layout.Row = 1 ;
            dropdown.Layout.Column = 2 ;
        end

        function value = convertOutputScalar(~, category, siValue, dropdown)
            if isempty(dropdown) || ~isvalid(dropdown)
                value = siValue ;
                return
            end
            value = UnitConverterHelper.convertFromSI(category, siValue, dropdown.Value) ;
        end

        function values = convertOutputVector(~, category, siValues, dropdown)
            if isempty(dropdown) || ~isvalid(dropdown)
                values = siValues ;
                return
            end
            values = UnitConverterHelper.convertFromSI(category, siValues, dropdown.Value) ;
        end

        function label = axisLabelWithUnit(~, baseText, dropdown)
            if isempty(dropdown) || ~isvalid(dropdown)
                label = baseText ;
                return
            end
            label = sprintf('%s [%s]', baseText, dropdown.Value) ;
        end

        function label = htmlLabelWithUnit(app, baseHtml, dropdown)
            unitText = app.unitToHtml(dropdown.Value) ;
            label = sprintf('%s [%s]:', baseHtml, unitText) ;
        end

        function label = axisLabelWithUnitName(~, baseText, unitName)
            label = sprintf('%s [%s]', baseText, unitName) ;
        end

        function unitName = timeSquaredUnitName(~, timeDropdown)
            switch timeDropdown.Value
                case 's'
                    unitName = 's^2' ;
                case 'min'
                    unitName = 'min^2' ;
                case 'h'
                    unitName = 'h^2' ;
                otherwise
                    unitName = 's^2' ;
            end
        end

        function unitName = timeInverseUnitName(~, timeDropdown)
            unitName = ['1/' timeDropdown.Value] ;
        end

        function value = convertOutputFromTime(app, mode, siValue, timeDropdown)
            switch mode
                case 'time'
                    value = app.convertOutputScalar('Time', siValue, timeDropdown) ;
                case 'timeSquared'
                    value = UnitConverterHelper.convertFromSI('TimeSquared', siValue, ...
                        app.timeSquaredUnitName(timeDropdown)) ;
                case 'timeInverse'
                    value = UnitConverterHelper.convertFromSI('TimeInverse', siValue, ...
                        app.timeInverseUnitName(timeDropdown)) ;
                otherwise
                    value = siValue ;
            end
        end

        function values = convertOutputVectorFromTime(app, mode, siValues, timeDropdown)
            switch mode
                case 'time'
                    values = app.convertOutputVector('Time', siValues, timeDropdown) ;
                case 'timeInverse'
                    values = UnitConverterHelper.convertFromSI('TimeInverse', siValues, ...
                        app.timeInverseUnitName(timeDropdown)) ;
                otherwise
                    values = siValues ;
            end
        end

        function refreshDisplayUnits(app, tabName)
            switch tabName
                case 'RTD'
                    app.RTD_updateResults() ;
                    app.RTD_updatePlots() ;
                case 'Prediction'
                    app.Pred_updatePlots() ;
                case 'TIS'
                    if isfield(app.DisplayCache, 'TIS') && ~isempty(app.DisplayCache.TIS)
                        c = app.DisplayCache.TIS ;
                        app.TIS_updatePlots(c.N_val, c.tau_val, c.RS, c.C0, ...
                            c.X_tis, c.X_cstr, c.X_pfr) ;
                    end
                case 'Dispersion'
                    if isfield(app.DisplayCache, 'Dispersion') && ~isempty(app.DisplayCache.Dispersion)
                        c = app.DisplayCache.Dispersion ;
                        app.Disp_updatePlots(c.Bo_val, c.tau_val, c.RS, c.C0, ...
                            c.X_disp, c.X_cstr, c.X_pfr) ;
                    end
                case 'Convolution'
                    app.Conv_refreshPlots() ;
                case 'Combined'
                    if isfield(app.DisplayCache, 'Combined') && ~isempty(app.DisplayCache.Combined)
                        c = app.DisplayCache.Combined ;
                        app.Comb_updatePlots(c.rtd_comb, c.model, c.X_model, ...
                            c.X_cstr, c.X_pfr, c.paramStr) ;
                    end
                case 'Optimization'
                    app.Opt_refreshDisplayUnits() ;
            end
        end

        function htmlText = unitToHtml(~, unitText)
            htmlText = strrep(unitText, '^2', '<sup>2</sup>') ;
            htmlText = strrep(htmlText, '^3', '<sup>3</sup>') ;
        end

        %% ============== ABOUT DIALOG (T7) ==============

        function showAbout(app) %#ok<INUSD>
            fig = uifigure('Name', 'About', ...
                'Position', [400 300 380 220], 'Resize', 'off') ;
            g = uigridlayout(fig, [6 1]) ;
            g.RowHeight = {'fit','fit','fit','fit','fit','fit'} ;
            g.Padding = [20 20 20 20] ;
            g.RowSpacing = 8 ;

            uilabel(g, 'Text', 'Non-Ideal Reactor Analysis', ...
                'FontSize', 18, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center') ;
            uilabel(g, 'Text', 'Version 1.0 — March 2026', ...
                'HorizontalAlignment', 'center') ;
            uilabel(g, 'Text', 'Javier Berenguer Sabater', ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold') ;
            uilabel(g, 'Text', 'TFG — Chemical Engineering', ...
                'HorizontalAlignment', 'center') ;
            uilabel(g, 'Text', sprintf('MATLAB %s', version), ...
                'HorizontalAlignment', 'center', ...
                'FontColor', [0.5 0.5 0.5]) ;
            uibutton(g, 'Text', 'Close', ...
                'ButtonPushedFcn', @(~,~) delete(fig)) ;
        end

        %% ============== STATUS BAR (T8) ==============

        function updateStatus(app, msg)
            app.StatusBar.Text = ['  ' msg] ;
            drawnow limitrate ;
        end

        %% ============== TAB 1: RTD ANALYSIS ==============
        function createRTDTab(app)

            app.RTDTab = uitab(app.TabGroup, 'Title', 'RTD Analysis') ;

            % Main grid: left panel (controls) + right panel (plots)
            mainGrid = uigridlayout(app.RTDTab, [1 2]) ;
            mainGrid.ColumnWidth = {320, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'RTD Configuration') ;
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
            lbl = uilabel(leftGrid, 'Text', '&tau;:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 2 ; lbl.Layout.Column = 1 ;
            [app.RTD_TauField, ~] = app.createNumericWithConv( ...
                leftGrid, 2, 2, 10, 'Time', 'Limits', [0.001 Inf]) ;

            % Row 3: Qv (volumetric flow rate) — always visible
            app.RTD_QvLabel = uilabel(leftGrid, 'Text', 'Q<sub>v</sub>:', 'Interpreter', 'html') ;
            app.RTD_QvLabel.Layout.Row = 3 ; app.RTD_QvLabel.Layout.Column = 1 ;
            [app.RTD_QvField, ~] = app.createNumericWithConv( ...
                leftGrid, 3, 2, 0.001, 'VolumetricFlow', 'Limits', [1e-12 Inf]) ;

            % Row 4: N field (for Tanks-in-Series) — shares row with Bo
            app.RTD_NLabel = uilabel(leftGrid, 'Text', 'N [tanks]:') ;
            app.RTD_NLabel.Layout.Row = 4 ; app.RTD_NLabel.Layout.Column = 1 ;
            app.RTD_NField = uieditfield(leftGrid, 'numeric', ...
                'Value', 3, 'Limits', [0.1 Inf]) ;
            app.RTD_NField.Layout.Row = 4 ; app.RTD_NField.Layout.Column = 2 ;
            app.RTD_NLabel.Visible = 'off' ;
            app.RTD_NField.Visible = 'off' ;

            % Row 4: Bo field (for Dispersion) — overlaps with N (only one visible)
            app.RTD_BoLabel = uilabel(leftGrid, 'Text', 'Bo [D<sub>e</sub>/uL]:', 'Interpreter', 'html') ;
            app.RTD_BoLabel.Layout.Row = 4 ; app.RTD_BoLabel.Layout.Column = 1 ;
            app.RTD_BoField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.01, 'Limits', [1e-6 Inf], ...
                'Tooltip', 'Dispersion number Bo = De/(u·L). Bo→0: plug flow, Bo→∞: perfect mixing.') ;
            app.RTD_BoField.Layout.Row = 4 ; app.RTD_BoField.Layout.Column = 2 ;
            app.RTD_BoLabel.Visible = 'off' ;
            app.RTD_BoField.Visible = 'off' ;

            % Row 5: Experimental t variable
            app.RTD_ExpTVarLabel = uilabel(leftGrid, 'Text', 't variable (workspace):') ;
            app.RTD_ExpTVarLabel.Layout.Row = 5 ; app.RTD_ExpTVarLabel.Layout.Column = 1 ;
            expTGrid = uigridlayout(leftGrid, [1 2], ...
                'ColumnWidth', {'1x', 78}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 2) ;
            expTGrid.Layout.Row = 5 ; expTGrid.Layout.Column = 2 ;
            app.RTD_ExpTVarField = uieditfield(expTGrid, 'text', ...
                'Value', 't_exp') ;
            app.RTD_ExpTVarField.Layout.Row = 1 ; app.RTD_ExpTVarField.Layout.Column = 1 ;
            app.RTD_ExpTUnitDropdown = uidropdown(expTGrid, ...
                'Items', UnitConverterHelper.getUnits('Time'), ...
                'Value', 's') ;
            app.RTD_ExpTUnitDropdown.Layout.Row = 1 ; app.RTD_ExpTUnitDropdown.Layout.Column = 2 ;
            app.RTD_ExpTVarLabel.Visible = 'off' ;
            expTGrid.Visible = 'off' ;

            % Row 6: Experimental C variable
            app.RTD_ExpCVarLabel = uilabel(leftGrid, 'Text', 'C variable (workspace):') ;
            app.RTD_ExpCVarLabel.Layout.Row = 6 ; app.RTD_ExpCVarLabel.Layout.Column = 1 ;
            app.RTD_ExpCVarField = uieditfield(leftGrid, 'text', ...
                'Value', 'C_exp') ;
            app.RTD_ExpCVarField.Layout.Row = 6 ; app.RTD_ExpCVarField.Layout.Column = 2 ;
            app.RTD_ExpCVarLabel.Visible = 'off' ;
            app.RTD_ExpCVarField.Visible = 'off' ;

            % Row 7: C0 (step only)
            app.RTD_ExpC0Label = uilabel(leftGrid, 'Text', 'C<sub>0</sub> (same units as C(t)):', 'Interpreter', 'html') ;
            app.RTD_ExpC0Label.Layout.Row = 7 ; app.RTD_ExpC0Label.Layout.Column = 1 ;
            [app.RTD_ExpC0Field, tmpSG] = app.createNumericWithConv( ...
                leftGrid, 7, 2, 1, 'RawScalar', 'Limits', [0 Inf]) ;
            app.RTD_ExpC0Label.Visible = 'off' ;
            tmpSG.Visible = 'off' ;

            % Row 8: Import from file button (for experimental data)
            app.RTD_ImportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Import Experimental Data', ...
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
                'Tooltip', 'Use "t" as variable in the selected time unit. Example: 5*exp(-2.5*t)') ;
            app.RTD_EqField.Layout.Row = 4 ; app.RTD_EqField.Layout.Column = 2 ;
            app.RTD_EqField.Visible = 'off' ;

            app.RTD_EqTStartLabel = uilabel(leftGrid, 'Text', 't start:') ;
            app.RTD_EqTStartLabel.Layout.Row = 5 ; app.RTD_EqTStartLabel.Layout.Column = 1 ;
            app.RTD_EqTStartLabel.Visible = 'off' ;
            app.RTD_EqTStartField = uieditfield(leftGrid, 'text', ...
                'Value', '0', ...
                'Tooltip', 'Accepts simple arithmetic expressions in the selected time unit.') ;
            app.RTD_EqTStartField.Layout.Row = 5 ; app.RTD_EqTStartField.Layout.Column = 2 ;
            app.RTD_EqTStartField.Visible = 'off' ;

            app.RTD_EqTEndLabel = uilabel(leftGrid, 'Text', 't end:') ;
            app.RTD_EqTEndLabel.Layout.Row = 6 ; app.RTD_EqTEndLabel.Layout.Column = 1 ;
            app.RTD_EqTEndLabel.Visible = 'off' ;
            app.RTD_EqTEndField = uieditfield(leftGrid, 'text', ...
                'Value', '10', ...
                'Tooltip', 'Accepts simple arithmetic expressions in the selected time unit.') ;
            app.RTD_EqTEndField.Layout.Row = 6 ; app.RTD_EqTEndField.Layout.Column = 2 ;
            app.RTD_EqTEndField.Visible = 'off' ;

            app.RTD_EqTimeUnitLabel = uilabel(leftGrid, 'Text', 'Time unit:') ;
            app.RTD_EqTimeUnitLabel.Layout.Row = 7 ; app.RTD_EqTimeUnitLabel.Layout.Column = 1 ;
            app.RTD_EqTimeUnitLabel.Visible = 'off' ;
            app.RTD_EqTimeUnitDropdown = uidropdown(leftGrid, ...
                'Items', UnitConverterHelper.getUnits('Time'), ...
                'Value', 's', ...
                'Tooltip', 'Defines the units of t start, t end, and the variable t in C(t).') ;
            app.RTD_EqTimeUnitDropdown.Layout.Row = 7 ;
            app.RTD_EqTimeUnitDropdown.Layout.Column = 2 ;
            app.RTD_EqTimeUnitDropdown.Visible = 'off' ;

            app.RTD_EqNptsLabel = uilabel(leftGrid, 'Text', 'N points:') ;
            app.RTD_EqNptsLabel.Layout.Row = 8 ; app.RTD_EqNptsLabel.Layout.Column = 1 ;
            app.RTD_EqNptsLabel.Visible = 'off' ;
            app.RTD_EqNptsField = uieditfield(leftGrid, 'numeric', ...
                'Value', 500, 'Limits', [10 10000]) ;
            app.RTD_EqNptsField.Layout.Row = 8 ; app.RTD_EqNptsField.Layout.Column = 2 ;
            app.RTD_EqNptsField.Visible = 'off' ;

            % Rows 4-9: Tabular Input components (hidden by default)
            % These share rows with N/Bo, Exp, and Equation fields

            % Row 4: Data type dropdown (Pulse C(t) or Step C(t))
            app.RTD_DataTypeLabel = uilabel(leftGrid, 'Text', 'Data type:') ;
            app.RTD_DataTypeLabel.Layout.Row = 4 ; app.RTD_DataTypeLabel.Layout.Column = 1 ;
            app.RTD_DataTypeLabel.Visible = 'off' ;
            app.RTD_DataTypeDropdown = uidropdown(leftGrid, ...
                'Items', {'Pulse C(t)', 'Step C(t)'}, ...
                'Value', 'Pulse C(t)', ...
                'Tooltip', 'Pulse: enter C(t) directly. Step: enter cumulative C(t) response to a step input.', ...
                'ValueChangedFcn', @(~,~) app.RTD_dataTypeChanged()) ;
            app.RTD_DataTypeDropdown.Layout.Row = 4 ; app.RTD_DataTypeDropdown.Layout.Column = 2 ;
            app.RTD_DataTypeDropdown.Visible = 'off' ;

            % Row 5: C0 for step input (reuse same row as ExpC0)
            % (uses existing RTD_ExpC0Label and RTD_ExpC0Field, toggled in sourceChanged)

            % Rows 5-8: Editable data table
            app.RTD_DataTable = uitable(leftGrid, ...
                'ColumnName', {'t [s]', 'C(t) [mol/m³]'}, ...
                'ColumnEditable', [true true], ...
                'Data', cell(10, 2), ...
                'RowName', {}, ...
                'Tooltip', 'Enter time and concentration data. Use Add/Remove Row buttons below.') ;
            app.RTD_DataTable.Layout.Row = [5 8] ;
            app.RTD_DataTable.Layout.Column = [1 2] ;
            app.RTD_DataTable.Visible = 'off' ;

            % Row 9: Add/Remove row buttons
            app.RTD_AddRowButton = uibutton(leftGrid, 'push', ...
                'Text', '+ Row', ...
                'BackgroundColor', [0.85 0.95 0.85], ...
                'ButtonPushedFcn', @(~,~) app.RTD_addTableRow()) ;
            app.RTD_AddRowButton.Layout.Row = 9 ; app.RTD_AddRowButton.Layout.Column = 1 ;
            app.RTD_AddRowButton.Visible = 'off' ;

            app.RTD_RemoveRowButton = uibutton(leftGrid, 'push', ...
                'Text', '- Row', ...
                'BackgroundColor', [0.95 0.85 0.85], ...
                'ButtonPushedFcn', @(~,~) app.RTD_removeTableRow()) ;
            app.RTD_RemoveRowButton.Layout.Row = 9 ; app.RTD_RemoveRowButton.Layout.Column = 2 ;
            app.RTD_RemoveRowButton.Visible = 'off' ;

            % Row 10: Generate button
            app.RTD_GenerateButton = uibutton(leftGrid, 'push', ...
                'Text', 'Generate RTD', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.RTD_generate()) ;
            app.RTD_GenerateButton.Layout.Row = 10 ;
            app.RTD_GenerateButton.Layout.Column = [1 2] ;

            % Row 11-12: Display units
            lbl = uilabel(leftGrid, 'Text', 'Display units:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 11 ; lbl.Layout.Column = [1 2] ;
            unitsGrid = uigridlayout(leftGrid, [2 2], ...
                'ColumnWidth', {'1x', '1x'}, ...
                'RowHeight', {28, 28}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 6) ;
            unitsGrid.Layout.Row = 12 ;
            unitsGrid.Layout.Column = [1 2] ;
            app.DisplayControls.RTD.time = app.createDisplayUnitControl( ...
                unitsGrid, 1, 1, 'Time base:', 'Time', 's', @(~,~) app.refreshDisplayUnits('RTD')) ;
            app.DisplayControls.RTD.volume = app.createDisplayUnitControl( ...
                unitsGrid, 1, 2, 'Volume:', 'Volume', 'm^3', @(~,~) app.refreshDisplayUnits('RTD')) ;

            % Row 13: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 13 ; lbl.Layout.Column = [1 2] ;

            % Row 14: tau_m
            app.RTD_ResultTauLabel = uilabel(leftGrid, ...
                'Text', '&tau;<sub>m</sub> [s]:', 'Interpreter', 'html') ;
            app.RTD_ResultTauLabel.Layout.Row = 14 ; app.RTD_ResultTauLabel.Layout.Column = 1 ;
            app.RTD_ResultTau = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultTau.Layout.Row = 14 ;
            app.RTD_ResultTau.Layout.Column = 2 ;

            % Row 15: sigma^2
            app.RTD_ResultSigma2Label = uilabel(leftGrid, ...
                'Text', '&sigma;&sup2; [s&sup2;]:', 'Interpreter', 'html') ;
            app.RTD_ResultSigma2Label.Layout.Row = 15 ; app.RTD_ResultSigma2Label.Layout.Column = 1 ;
            app.RTD_ResultSigma2 = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultSigma2.Layout.Row = 15 ;
            app.RTD_ResultSigma2.Layout.Column = 2 ;

            % Row 16: sigma^2_theta
            lbl = uilabel(leftGrid, 'Text', '&sigma;&sup2;<sub>&theta;</sub>:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 16 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultSigma2Theta = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultSigma2Theta.Layout.Row = 16 ;
            app.RTD_ResultSigma2Theta.Layout.Column = 2 ;

            % Row 17: s^3
            lbl = uilabel(leftGrid, 'Text', 's&sup3; [skewness]:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 17 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultS3 = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultS3.Layout.Row = 17 ;
            app.RTD_ResultS3.Layout.Column = 2 ;

            % Row 18: N_est
            lbl = uilabel(leftGrid, 'Text', 'N<sub>est</sub> [= &tau;&sup2;/&sigma;&sup2;]:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 18 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultN = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultN.Layout.Row = 18 ;
            app.RTD_ResultN.Layout.Column = 2 ;

            % Row 19: V_eff
            app.RTD_ResultVeffLabel = uilabel(leftGrid, ...
                'Text', 'V<sub>eff</sub> [m&sup3;]:', 'Interpreter', 'html') ;
            app.RTD_ResultVeffLabel.Layout.Row = 19 ; app.RTD_ResultVeffLabel.Layout.Column = 1 ;
            app.RTD_ResultVeff = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultVeff.Layout.Row = 19 ;
            app.RTD_ResultVeff.Layout.Column = 2 ;

            % Row 20: Export name
            lbl = uilabel(leftGrid, 'Text', 'Export name:') ;
            lbl.Layout.Row = 20 ; lbl.Layout.Column = 1 ;
            app.RTD_ExportNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'RTD_1') ;
            app.RTD_ExportNameField.Layout.Row = 20 ;
            app.RTD_ExportNameField.Layout.Column = 2 ;

            % Row 21: Export button
            app.RTD_ExportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Export RTD to Workspace', ...
                'BackgroundColor', [0.2 0.7 0.3], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.RTD_export()) ;
            app.RTD_ExportButton.Layout.Row = 21 ;
            app.RTD_ExportButton.Layout.Column = [1 2] ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'RTD Plots') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % E(t) plot
            app.RTD_AxesEt = uiaxes(plotGrid) ;
            title(app.RTD_AxesEt, 'E(t)') ;
            xlabel(app.RTD_AxesEt, 't [s]') ;
            ylabel(app.RTD_AxesEt, 'E(t) [1/s]') ;
            grid(app.RTD_AxesEt, 'off') ;

            % F(t) plot
            app.RTD_AxesFt = uiaxes(plotGrid) ;
            title(app.RTD_AxesFt, 'F(t)') ;
            xlabel(app.RTD_AxesFt, 't [s]') ;
            ylabel(app.RTD_AxesFt, 'F(t)') ;
            grid(app.RTD_AxesFt, 'off') ;

            % E(theta) plot
            app.RTD_AxesEtheta = uiaxes(plotGrid) ;
            title(app.RTD_AxesEtheta, 'E(\Theta)') ;
            xlabel(app.RTD_AxesEtheta, '\Theta = t/\tau') ;
            ylabel(app.RTD_AxesEtheta, 'E(\Theta)') ;
            grid(app.RTD_AxesEtheta, 'off') ;

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
            app.RTD_ExpTVarField.Parent.Visible = 'off' ;
            app.RTD_ExpCVarLabel.Visible = 'off' ;
            app.RTD_ExpCVarField.Visible = 'off' ;
            app.RTD_ExpC0Label.Visible = 'off' ;
            app.RTD_ExpC0Field.Parent.Visible = 'off' ;
            app.RTD_ImportButton.Visible = 'off' ;
            app.RTD_ImportLabel.Visible = 'off' ;
            app.RTD_EqLabel.Visible = 'off' ;
            app.RTD_EqField.Visible = 'off' ;
            app.RTD_EqTStartLabel.Visible = 'off' ;
            app.RTD_EqTStartField.Visible = 'off' ;
            app.RTD_EqTEndLabel.Visible = 'off' ;
            app.RTD_EqTEndField.Visible = 'off' ;
            app.RTD_EqTimeUnitLabel.Visible = 'off' ;
            app.RTD_EqTimeUnitDropdown.Visible = 'off' ;
            app.RTD_EqNptsLabel.Visible = 'off' ;
            app.RTD_EqNptsField.Visible = 'off' ;
            app.RTD_DataTypeLabel.Visible = 'off' ;
            app.RTD_DataTypeDropdown.Visible = 'off' ;
            app.RTD_DataTable.Visible = 'off' ;
            app.RTD_AddRowButton.Visible = 'off' ;
            app.RTD_RemoveRowButton.Visible = 'off' ;

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
                    app.RTD_ExpTVarField.Parent.Visible = 'on' ;
                    app.RTD_ExpCVarLabel.Visible = 'on' ;
                    app.RTD_ExpCVarField.Visible = 'on' ;
                    app.RTD_ImportButton.Visible = 'on' ;
                    app.RTD_ImportLabel.Visible = 'on' ;
                    tauVisible = 'off' ;

                case 'Experimental Step'
                    app.RTD_ExpTVarLabel.Visible = 'on' ;
                    app.RTD_ExpTVarField.Parent.Visible = 'on' ;
                    app.RTD_ExpCVarLabel.Visible = 'on' ;
                    app.RTD_ExpCVarField.Visible = 'on' ;
                    app.RTD_ExpC0Label.Visible = 'on' ;
                    app.RTD_ExpC0Field.Parent.Visible = 'on' ;
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
                    app.RTD_EqTimeUnitLabel.Visible = 'on' ;
                    app.RTD_EqTimeUnitDropdown.Visible = 'on' ;
                    app.RTD_EqNptsLabel.Visible = 'on' ;
                    app.RTD_EqNptsField.Visible = 'on' ;
                    tauVisible = 'off' ;

                case 'Tabular Input'
                    app.RTD_DataTypeLabel.Visible = 'on' ;
                    app.RTD_DataTypeDropdown.Visible = 'on' ;
                    app.RTD_DataTable.Visible = 'on' ;
                    app.RTD_AddRowButton.Visible = 'on' ;
                    app.RTD_RemoveRowButton.Visible = 'on' ;
                    % Show C0 field only for step input
                    if strcmp(app.RTD_DataTypeDropdown.Value, 'Step C(t)')
                        app.RTD_ExpC0Label.Visible = 'on' ;
                        app.RTD_ExpC0Field.Parent.Visible = 'on' ;
                    end
                    tauVisible = 'off' ;
            end

            app.RTD_TauField.Parent.Visible = tauVisible ;
        end

        function RTD_dataTypeChanged(app)
            % Show/hide C0 field when switching between Pulse and Step in Tabular Input
            if strcmp(app.RTD_SourceDropdown.Value, 'Tabular Input')
                if strcmp(app.RTD_DataTypeDropdown.Value, 'Step C(t)')
                    app.RTD_ExpC0Label.Visible = 'on' ;
                    app.RTD_ExpC0Field.Parent.Visible = 'on' ;
                else
                    app.RTD_ExpC0Label.Visible = 'off' ;
                    app.RTD_ExpC0Field.Parent.Visible = 'off' ;
                end
            end
        end

        function RTD_addTableRow(app)
            % Add a row to the tabular input data table
            currentData = app.RTD_DataTable.Data ;
            if iscell(currentData)
                app.RTD_DataTable.Data = [currentData ; cell(1, 2)] ;
            else
                app.RTD_DataTable.Data = [currentData ; {[], []}] ;
            end
        end

        function RTD_removeTableRow(app)
            % Remove the last row from the tabular input data table
            currentData = app.RTD_DataTable.Data ;
            if size(currentData, 1) > 1
                app.RTD_DataTable.Data = currentData(1:end-1, :) ;
            end
        end

        function RTD_generate(app)
            % Generate RTD based on selected source and parameters

            try
                app.updateStatus('Generating RTD...') ;
                source = app.RTD_SourceDropdown.Value ;
                tau_val = app.readInputField(app.RTD_TauField) ;

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
                        tau_val = app.readInputField(app.RTD_TauField) ;
                        app.rtd = RTD.laminar_flow(tau_val) ;

                    case 'Experimental Pulse'
                        t_var = app.RTD_ExpTVarField.Value ;
                        C_var = app.RTD_ExpCVarField.Value ;
                        t_data = evalin('base', t_var) ;
                        C_data = evalin('base', C_var) ;
                        t_data = UnitConverterHelper.convertToSI('Time', t_data, app.RTD_ExpTUnitDropdown.Value) ;
                        app.rtd = RTD.from_pulse(t_data, C_data) ;

                    case 'Experimental Step'
                        t_var = app.RTD_ExpTVarField.Value ;
                        C_var = app.RTD_ExpCVarField.Value ;
                        t_data = evalin('base', t_var) ;
                        C_data = evalin('base', C_var) ;
                        t_data = UnitConverterHelper.convertToSI('Time', t_data, app.RTD_ExpTUnitDropdown.Value) ;
                        C0 = app.readInputField(app.RTD_ExpC0Field) ;
                        app.rtd = RTD.from_step(t_data, C_data, C0) ;

                    case 'C(t) Equation'
                        eq_str = app.RTD_EqField.Value ;
                        t_unit = app.RTD_EqTimeUnitDropdown.Value ;
                        t_start_user = InputLayerHelper.parseArithmeticExpression(app.RTD_EqTStartField.Value) ;
                        t_end_user = InputLayerHelper.parseArithmeticExpression(app.RTD_EqTEndField.Value) ;
                        n_pts = round(app.RTD_EqNptsField.Value) ;

                        if t_end_user <= t_start_user
                            error('t end must be greater than t start for C(t) Equation.') ;
                        end

                        % Evaluate C(t) in the user-selected time unit, then
                        % convert the timeline to SI before creating the RTD.
                        t = linspace(t_start_user, t_end_user, n_pts) ;
                        try
                            C_data = eval(eq_str) ;
                        catch evalErr
                            error('Error evaluating equation "%s": %s', ...
                                eq_str, evalErr.message) ;
                        end

                        % Validate result
                        if ~isnumeric(C_data) || length(C_data) ~= length(t)
                            error('The equation must return a numeric vector of the same size as t. Make sure you use element-wise operators (.*  ./  .^)') ;
                        end

                        % Ensure non-negative
                        C_data = max(C_data, 0) ;

                        % Build RTD from pulse response
                        t_si = UnitConverterHelper.convertToSI('Time', t, t_unit) ;
                        app.rtd = RTD.from_pulse(t_si, C_data) ;

                    case 'Tabular Input'
                        % Read data from the editable table
                        rawData = app.RTD_DataTable.Data ;

                        % Convert cell array to numeric, filtering empty rows
                        if iscell(rawData)
                            numData = zeros(size(rawData)) ;
                            validRows = true(size(rawData, 1), 1) ;
                            for iRow = 1:size(rawData, 1)
                                for iCol = 1:2
                                    val = rawData{iRow, iCol} ;
                                    if isempty(val) || (ischar(val) && isempty(strtrim(val)))
                                        validRows(iRow) = false ;
                                        break
                                    end
                                    if ischar(val) || isstring(val)
                                        try
                                            val = InputLayerHelper.parseArithmeticExpression(val) ;
                                        catch
                                            validRows(iRow) = false ;
                                            break
                                        end
                                    end
                                    if isnan(val)
                                        validRows(iRow) = false ;
                                        break
                                    end
                                    numData(iRow, iCol) = val ;
                                end
                            end
                            numData = numData(validRows, :) ;
                        else
                            % Already numeric (table or matrix)
                            if istable(rawData)
                                numData = table2array(rawData) ;
                            else
                                numData = rawData ;
                            end
                            validRows = all(isfinite(numData), 2) ;
                            numData = numData(validRows, :) ;
                        end

                        if size(numData, 1) < 3
                            error('At least 3 valid data points are required. Fill the table with time [s] and C(t) [mol/m³] values.') ;
                        end

                        t_data = numData(:, 1)' ;
                        C_data = numData(:, 2)' ;

                        % Validate
                        if any(t_data < 0)
                            error('Time values must be non-negative.') ;
                        end

                        % Ensure non-negative concentrations
                        C_data = max(C_data, 0) ;

                        dataType = app.RTD_DataTypeDropdown.Value ;
                        if strcmp(dataType, 'Pulse C(t)')
                            app.rtd = RTD.from_pulse(t_data, C_data) ;
                        else
                            % Step input: need C0
                            C0 = app.readInputField(app.RTD_ExpC0Field) ;
                            app.rtd = RTD.from_step(t_data, C_data, C0) ;
                        end
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

                app.updateStatus('Ready') ;

            catch ME
                app.updateStatus('Error') ;
                uialert(app.UIFigure, ME.message, 'RTD Generation Error') ;
            end
        end

        function RTD_updateResults(app)
            % Update the results labels with RTD moments

            if isempty(app.rtd)
                return
            end

            timeDD = app.DisplayControls.RTD.time ;
            volDD = app.DisplayControls.RTD.volume ;

            app.RTD_ResultTauLabel.Text = app.htmlLabelWithUnit('&tau;<sub>m</sub>', timeDD) ;
            app.RTD_ResultSigma2Label.Text = sprintf('&sigma;&sup2; [%s]:', ...
                app.unitToHtml(app.timeSquaredUnitName(timeDD))) ;
            app.RTD_ResultVeffLabel.Text = app.htmlLabelWithUnit('V<sub>eff</sub>', volDD) ;

            tauDisplay = app.convertOutputFromTime('time', app.rtd.tau, timeDD) ;
            sigmaDisplay = app.convertOutputFromTime('timeSquared', app.rtd.sigma2, timeDD) ;
            app.RTD_ResultTau.Text = sprintf('%.4f', tauDisplay) ;
            app.RTD_ResultSigma2.Text = sprintf('%.4f', sigmaDisplay) ;

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
            Qv = app.readInputField(app.RTD_QvField) ;
            V_eff = app.rtd.tau * Qv ;
            VeffDisplay = app.convertOutputScalar('Volume', V_eff, volDD) ;
            app.RTD_ResultVeff.Text = sprintf('%.6g', VeffDisplay) ;
        end

        function RTD_updatePlots(app)
            % Update all three RTD plots

            if isempty(app.rtd)
                return
            end

            timeDD = app.DisplayControls.RTD.time ;
            t_display = app.convertOutputVectorFromTime('time', app.rtd.t, timeDD) ;
            Et_display = app.convertOutputVectorFromTime('timeInverse', app.rtd.Et, timeDD) ;

            % E(t) plot
            cla(app.RTD_AxesEt) ;
            plot(app.RTD_AxesEt, t_display, Et_display, 'b-', 'LineWidth', 1.5) ;
            title(app.RTD_AxesEt, 'E(t)') ;
            xlabel(app.RTD_AxesEt, app.axisLabelWithUnit('t', timeDD)) ;
            ylabel(app.RTD_AxesEt, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(timeDD))) ;

            % F(t) plot
            cla(app.RTD_AxesFt) ;
            plot(app.RTD_AxesFt, t_display, app.rtd.Ft, 'r-', 'LineWidth', 1.5) ;
            title(app.RTD_AxesFt, 'F(t)') ;
            xlabel(app.RTD_AxesFt, app.axisLabelWithUnit('t', timeDD)) ;
            ylabel(app.RTD_AxesFt, 'F(t)') ;
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
                        'The file must have at least 2 columns (t and C).', ...
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
            leftGrid = uigridlayout(leftPanel, [15 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 15) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: RTD status
            uilabel(leftGrid, 'Text', 'Current RTD:', ...
                'FontWeight', 'bold') ;
            app.Pred_RTDStatusLabel = uilabel(leftGrid, ...
                'Text', 'None (generate in Tab 1)', ...
                'FontColor', [0.8 0 0]) ;

            % Row 2: Reaction System header
            lbl = uilabel(leftGrid, 'Text', 'Reaction System:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 2 ; lbl.Layout.Column = [1 2] ;

            % Row 3: New RS + Edit RS buttons
            app.Pred_RSDefineButton = uibutton(leftGrid, 'push', ...
                'Text', 'New RS', ...
                'BackgroundColor', [0.85 0.90 1.0], ...
                'Tooltip', 'Create a new Reaction System from scratch', ...
                'ButtonPushedFcn', @(~,~) defineReactionSysApp()) ;
            app.Pred_RSDefineButton.Layout.Row = 3 ;
            app.Pred_RSDefineButton.Layout.Column = 1 ;

            app.Pred_RSEditButton = uibutton(leftGrid, 'push', ...
                'Text', 'Edit RS', ...
                'BackgroundColor', [1.0 0.95 0.80], ...
                'Tooltip', 'Edit the currently loaded Reaction System', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Pred_editRS()) ;
            app.Pred_RSEditButton.Layout.Row = 3 ;
            app.Pred_RSEditButton.Layout.Column = 2 ;

            % Row 4: RS name field + Load button
            app.Pred_RSNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'RS', ...
                'Tooltip', 'Name of the ReactionSys variable in the MATLAB workspace') ;
            app.Pred_RSNameField.Layout.Row = 4 ; app.Pred_RSNameField.Layout.Column = 1 ;
            app.Pred_RSLoadButton = uibutton(leftGrid, 'push', ...
                'Text', 'Load from Workspace', ...
                'BackgroundColor', [0.85 0.95 0.85], ...
                'Tooltip', 'Load the ReactionSys object from the workspace', ...
                'ButtonPushedFcn', @(~,~) app.Pred_loadRS()) ;
            app.Pred_RSLoadButton.Layout.Row = 4 ; app.Pred_RSLoadButton.Layout.Column = 2 ;

            % Row 5: RS status
            app.Pred_RSStatusLabel = uilabel(leftGrid, ...
                'Text', 'No Reaction System loaded', 'FontColor', [0.6 0 0]) ;
            app.Pred_RSStatusLabel.Layout.Row = 5 ;
            app.Pred_RSStatusLabel.Layout.Column = [1 2] ;

            % Row 6: CA0
            app.Pred_CA0Label = uilabel(leftGrid, 'Text', 'C<sub>A0</sub>:', 'Interpreter', 'html') ;
            app.Pred_CA0Label.Layout.Row = 6 ; app.Pred_CA0Label.Layout.Column = 1 ;
            [app.Pred_CA0Field, ~] = app.createNumericWithConv( ...
                leftGrid, 6, 2, 1000, 'Concentration', ...
                'Limits', [0.001 Inf], ...
                'Tooltip', 'Initial concentration of limiting reactant (component A) in the feed.') ;

            % Row 7: Compute button
            app.Pred_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Compute', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Pred_compute()) ;
            app.Pred_ComputeButton.Layout.Row = 7 ;
            app.Pred_ComputeButton.Layout.Column = [1 2] ;

            % Row 8: Display units
            unitsGrid = uigridlayout(leftGrid, [1 2], ...
                'ColumnWidth', {110, '1x'}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 4) ;
            unitsGrid.Layout.Row = 8 ;
            unitsGrid.Layout.Column = [1 2] ;
            app.DisplayControls.Prediction.time = app.createDisplayUnitControl( ...
                unitsGrid, 1, 1, 'Time base:', 'Time', 's', @(~,~) app.refreshDisplayUnits('Prediction')) ;

            % Row 9: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 9 ; lbl.Layout.Column = [1 2] ;

            % Row 10: Segregation result
            lbl = uilabel(leftGrid, 'Text', 'Segregation X<sub>seg</sub>:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 10 ; lbl.Layout.Column = 1 ;
            app.Pred_ResultSegLabel = uilabel(leftGrid, 'Text', '--') ;
            app.Pred_ResultSegLabel.Layout.Row = 10 ; app.Pred_ResultSegLabel.Layout.Column = 2 ;

            % Row 11: Max Mixedness result
            lbl = uilabel(leftGrid, 'Text', 'Max Mixedness X<sub>MM</sub>:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 11 ; lbl.Layout.Column = 1 ;
            app.Pred_ResultMMLabel = uilabel(leftGrid, 'Text', '--') ;
            app.Pred_ResultMMLabel.Layout.Row = 11 ; app.Pred_ResultMMLabel.Layout.Column = 2 ;

            % Row 12: Interpretation
            lbl = uilabel(leftGrid, 'Text', 'Interpretation:') ;
            lbl.Layout.Row = 12 ; lbl.Layout.Column = 1 ;
            app.Pred_ResultBoundsLabel = uilabel(leftGrid, 'Text', '--') ;
            app.Pred_ResultBoundsLabel.Layout.Row = 13 ;
            app.Pred_ResultBoundsLabel.Layout.Column = [1 2] ;
            app.Pred_ResultBoundsLabel.WordWrap = 'on' ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Model Results') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % X_batch(t) plot (Segregation)
            app.Pred_AxesXbatch = uiaxes(plotGrid) ;
            title(app.Pred_AxesXbatch, 'Batch Conversion X(t)') ;
            xlabel(app.Pred_AxesXbatch, 't [s]') ;
            ylabel(app.Pred_AxesXbatch, 'X_{batch}(t)') ;
            grid(app.Pred_AxesXbatch, 'off') ;

            % Integrand plot (Segregation)
            app.Pred_AxesIntegrand = uiaxes(plotGrid) ;
            title(app.Pred_AxesIntegrand, 'Integrand X(t)*E(t)') ;
            xlabel(app.Pred_AxesIntegrand, 't [s]') ;
            ylabel(app.Pred_AxesIntegrand, 'X(t)*E(t)') ;
            grid(app.Pred_AxesIntegrand, 'off') ;

            % X(lambda) plot (Max Mixedness)
            app.Pred_AxesXlambda = uiaxes(plotGrid) ;
            title(app.Pred_AxesXlambda, 'X(lambda) - Max Mixedness') ;
            xlabel(app.Pred_AxesXlambda, 'lambda') ;
            ylabel(app.Pred_AxesXlambda, 'X(lambda)') ;
            grid(app.Pred_AxesXlambda, 'off') ;

            % Comparison bar chart
            app.Pred_AxesComparison = uiaxes(plotGrid) ;
            title(app.Pred_AxesComparison, 'Conversion Bounds') ;
            ylabel(app.Pred_AxesComparison, 'Conversion X') ;
            grid(app.Pred_AxesComparison, 'off') ;
        end

        %% ============== PREDICTION CALLBACKS ==============

        function Pred_loadRS(app)
            % Load a ReactionSys object from the MATLAB workspace by name
            rsName = app.Pred_RSNameField.Value ;
            try
                RS = evalin('base', rsName) ;
                if ~isa(RS, 'ReactionSys')
                    error('Variable "%s" is not a ReactionSys object.', rsName) ;
                end
                app.Pred_RS = RS ;
                nR = RS.nReactions ;
                nC = RS.nComponents ;
                app.Pred_RSStatusLabel.Text = sprintf('Loaded: %d reactions, %d components', nR, nC) ;
                app.Pred_RSStatusLabel.FontColor = [0 0.5 0] ;
                app.Pred_RSEditButton.Enable = 'on' ;
            catch ME
                app.Pred_RSStatusLabel.Text = ME.message ;
                app.Pred_RSStatusLabel.FontColor = [0.8 0 0] ;
            end
        end

        function Pred_editRS(app)
            % Open defineReactionSysApp pre-loaded with the current RS
            if isempty(app.Pred_RS)
                uialert(app.UIFigure, ...
                    'No Reaction System loaded to edit.', 'Nothing to Edit') ;
                return
            end
            rsName = app.Pred_RSNameField.Value ;
            defineReactionSysApp(app.Pred_RS, rsName) ;
        end

        function Pred_compute(app)
            % Compute segregation and max mixedness predictions/bounds
            % using the loaded ReactionSys object.

            try
                app.updateStatus('Computing conversion bounds...') ;

                % Check RTD is available
                if isempty(app.rtd)
                    uialert(app.UIFigure, ...
                        'No RTD available. Go to Tab 1 and generate an RTD first.', ...
                        'RTD Required') ;
                    app.updateStatus('Ready') ;
                    return
                end

                % Validate that a ReactionSys is loaded
                if isempty(app.Pred_RS)
                    uialert(app.UIFigure, ...
                        'No Reaction System loaded. Use "Define Reaction System" to create one, then "Load from Workspace" to import it.', ...
                        'Missing Reaction System') ;
                    app.updateStatus('Ready') ;
                    return ;
                end

                RS = app.Pred_RS ;
                CA0_val = app.readInputField(app.Pred_CA0Field) ;

                % Build initial concentration vector: [CA0, 0, 0, ...]
                C0 = zeros(1, RS.nComponents) ;
                C0(1) = CA0_val ;

                % Create model objects with RTD
                app.seg_model = SegregationModel ;
                app.seg_model.rtd = app.rtd ;

                app.mm_model = MaxMixednessModel ;
                app.mm_model.rtd = app.rtd ;

                % Compute using the general isothermal methods
                app.seg_model = app.seg_model.compute_isothermal(RS, C0) ;
                app.mm_model = app.mm_model.compute_isothermal(RS, C0) ;

                % Update main results
                X_seg = app.seg_model.X_mean ;
                X_mm = app.mm_model.X_exit ;

                app.Pred_ResultSegLabel.Text = sprintf('%.4f', X_seg) ;
                app.Pred_ResultMMLabel.Text = sprintf('%.4f', X_mm) ;

                % Interpretation text
                if abs(X_seg - X_mm) < 0.001
                    boundsText = sprintf('Seg ~ MM ~ %.4f (mixing state independent)', X_seg) ;
                    boundsColor = [0 0.5 0] ;
                elseif X_seg > X_mm
                    boundsText = sprintf('Seg=%.4f (upper) >= MM=%.4f (lower)', X_seg, X_mm) ;
                    boundsColor = [0 0 0.7] ;
                else
                    boundsText = sprintf('MM=%.4f (upper) >= Seg=%.4f (lower)', X_mm, X_seg) ;
                    boundsColor = [0.7 0 0] ;
                end
                app.Pred_ResultBoundsLabel.Text = boundsText ;
                app.Pred_ResultBoundsLabel.FontColor = boundsColor ;

                % Update plots
                app.Pred_updatePlots() ;

                % Update RTD status label
                app.Pred_RTDStatusLabel.Text = sprintf('tau=%.2f, sigma2=%.2f', ...
                    app.rtd.tau, app.rtd.sigma2) ;
                app.Pred_RTDStatusLabel.FontColor = [0 0.5 0] ;

                app.updateStatus('Ready') ;

            catch ME
                app.updateStatus('Error') ;
                uialert(app.UIFigure, ME.message, 'Computation Error') ;
            end
        end

        function Pred_updatePlots(app)
            % Update all prediction model plots

            if isempty(app.seg_model) || isempty(app.mm_model)
                return
            end

            timeDD = app.DisplayControls.Prediction.time ;
            t_display = app.convertOutputVectorFromTime('time', app.seg_model.rtd.t, timeDD) ;
            lambda_display = app.convertOutputVectorFromTime('time', app.mm_model.lambda_profile, timeDD) ;
            integrand_display = app.convertOutputVectorFromTime('timeInverse', app.seg_model.integrand, timeDD) ;

            % Segregation plots (X_batch and integrand)
            cla(app.Pred_AxesXbatch) ;
            plot(app.Pred_AxesXbatch, t_display, app.seg_model.X_batch, ...
                'b-', 'LineWidth', 1.5) ;
            xlabel(app.Pred_AxesXbatch, app.axisLabelWithUnit('t', timeDD)) ;
            ylabel(app.Pred_AxesXbatch, 'X_{batch}(t)') ;
            title(app.Pred_AxesXbatch, 'Intrinsic Conversion X(t)') ;
            grid(app.Pred_AxesXbatch, 'on') ;
            ylim(app.Pred_AxesXbatch, [0 1]) ;

            cla(app.Pred_AxesIntegrand) ;
            area(app.Pred_AxesIntegrand, t_display, integrand_display, ...
                'FaceColor', [0.3 0.6 0.9], 'FaceAlpha', 0.5, 'EdgeColor', 'b') ;
            xlabel(app.Pred_AxesIntegrand, app.axisLabelWithUnit('t', timeDD)) ;
            ylabel(app.Pred_AxesIntegrand, app.axisLabelWithUnitName('X(t)*E(t)', app.timeInverseUnitName(timeDD))) ;
            title(app.Pred_AxesIntegrand, sprintf('Segregation Integrand | X_{seg} = %.4f', ...
                app.seg_model.X_mean)) ;
            grid(app.Pred_AxesIntegrand, 'on') ;

            % Max mixedness plot (X(lambda))
            cla(app.Pred_AxesXlambda) ;
            plot(app.Pred_AxesXlambda, lambda_display, app.mm_model.X_profile, ...
                'm-', 'LineWidth', 1.5) ;
            hold(app.Pred_AxesXlambda, 'on') ;
            plot(app.Pred_AxesXlambda, 0, app.mm_model.X_exit, ...
                'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r') ;
            hold(app.Pred_AxesXlambda, 'off') ;
            xlabel(app.Pred_AxesXlambda, app.axisLabelWithUnit('\lambda', timeDD)) ;
            ylabel(app.Pred_AxesXlambda, 'X(\lambda)') ;
            title(app.Pred_AxesXlambda, sprintf('Maximum Mixedness Conversion | X_{MM} = %.4f', ...
                app.mm_model.X_exit)) ;
            grid(app.Pred_AxesXlambda, 'on') ;
            ylim(app.Pred_AxesXlambda, [0 1]) ;
            legend(app.Pred_AxesXlambda, 'X(\lambda)', ...
                sprintf('X_{MM} = %.4f', app.mm_model.X_exit), 'Location', 'best') ;

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
            leftGrid = uigridlayout(leftPanel, [15 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 15) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: N method
            lbl = uilabel(leftGrid, 'Text', 'N Method:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = 1 ;
            methodSubGrid = uigridlayout(leftGrid, [1 2], ...
                'ColumnWidth', {'1x', 28}, 'Padding', [0 0 0 0], 'ColumnSpacing', 2) ;
            methodSubGrid.Layout.Row = 1 ; methodSubGrid.Layout.Column = 2 ;
            app.TIS_NMethodDropdown = uidropdown(methodSubGrid, ...
                'Items', {'Manual', 'From Calculated Data'}, ...
                'Value', 'Manual', ...
                'ValueChangedFcn', @(~,~) app.TIS_NMethodChanged()) ;
            app.TIS_RefreshButton = uibutton(methodSubGrid, 'push', ...
                'Text', char(8635), 'FontSize', 12, ...
                'Tooltip', 'Refresh imported data from Tab 1 and Tab 2', ...
                'Visible', 'off', ...
                'ButtonPushedFcn', @(~,~) app.TIS_NMethodChanged()) ;

            % Row 2: N tanks
            app.TIS_NLabel = uilabel(leftGrid, 'Text', 'N [tanks]:') ;
            app.TIS_NLabel.Layout.Row = 2 ; app.TIS_NLabel.Layout.Column = 1 ;
            app.TIS_NField = uieditfield(leftGrid, 'numeric', ...
                'Value', 3, 'Limits', [0.1 Inf], ...
                'Tooltip', 'Number of tanks in series. N=1: CSTR, N→∞: PFR. Can be non-integer for RTD.') ;
            app.TIS_NField.Layout.Row = 2 ; app.TIS_NField.Layout.Column = 2 ;

            % Row 3: RTD status (shown when "From RTD")
            app.TIS_RTDStatusLabel = uilabel(leftGrid, ...
                'Text', 'RTD: not loaded', 'FontColor', [0.6 0 0]) ;
            app.TIS_RTDStatusLabel.Layout.Row = 3 ;
            app.TIS_RTDStatusLabel.Layout.Column = [1 2] ;
            app.TIS_RTDStatusLabel.Visible = 'off' ;

            % Row 4: tau
            app.TIS_tauLabel = uilabel(leftGrid, 'Text', 'tau total:') ;
            app.TIS_tauLabel.Layout.Row = 4 ; app.TIS_tauLabel.Layout.Column = 1 ;
            [app.TIS_tauField, ~] = app.createNumericWithConv( ...
                leftGrid, 4, 2, 10, 'Time', ...
                'Limits', [0.001 Inf], ...
                'Tooltip', 'Total mean residence time: tau = V_total / Q.') ;

            % Row 5: Reaction System header
            lbl = uilabel(leftGrid, 'Text', 'Reaction System:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 5 ; lbl.Layout.Column = [1 2] ;

            % Row 6: Define RS button + Load from workspace
            app.TIS_RSDefineButton = uibutton(leftGrid, 'push', ...
                'Text', 'New RS', ...
                'BackgroundColor', [0.85 0.90 1.0], ...
                'Tooltip', 'Create a new Reaction System from scratch', ...
                'ButtonPushedFcn', @(~,~) defineReactionSysApp()) ;
            app.TIS_RSDefineButton.Layout.Row = 6 ;
            app.TIS_RSDefineButton.Layout.Column = 1 ;

            app.TIS_RSEditButton = uibutton(leftGrid, 'push', ...
                'Text', 'Edit RS', ...
                'BackgroundColor', [1.0 0.95 0.80], ...
                'Tooltip', 'Edit the currently loaded Reaction System', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.TIS_editRS()) ;
            app.TIS_RSEditButton.Layout.Row = 6 ;
            app.TIS_RSEditButton.Layout.Column = 2 ;

            % Row 7: RS name field + Load button
            app.TIS_RSNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'RS', ...
                'Tooltip', 'Name of the ReactionSys variable in the MATLAB workspace') ;
            app.TIS_RSNameField.Layout.Row = 7 ; app.TIS_RSNameField.Layout.Column = 1 ;
            app.TIS_RSLoadButton = uibutton(leftGrid, 'push', ...
                'Text', 'Load from Workspace', ...
                'BackgroundColor', [0.85 0.95 0.85], ...
                'Tooltip', 'Load the ReactionSys object from the workspace', ...
                'ButtonPushedFcn', @(~,~) app.TIS_loadRS()) ;
            app.TIS_RSLoadButton.Layout.Row = 7 ; app.TIS_RSLoadButton.Layout.Column = 2 ;

            % Row 8: RS status
            app.TIS_RSStatusLabel = uilabel(leftGrid, ...
                'Text', 'No Reaction System loaded', 'FontColor', [0.6 0 0]) ;
            app.TIS_RSStatusLabel.Layout.Row = 8 ;
            app.TIS_RSStatusLabel.Layout.Column = [1 2] ;

            % Row 9: CA0
            app.TIS_CA0Label = uilabel(leftGrid, 'Text', 'C<sub>A0</sub>:', 'Interpreter', 'html') ;
            app.TIS_CA0Label.Layout.Row = 9 ; app.TIS_CA0Label.Layout.Column = 1 ;
            [app.TIS_CA0Field, ~] = app.createNumericWithConv( ...
                leftGrid, 9, 2, 1000, 'Concentration', ...
                'Limits', [0.001 Inf], ...
                'Tooltip', 'Initial concentration of limiting reactant (component A) in the feed.') ;

            % Row 10: Compute button
            app.TIS_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Compute', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.TIS_compute()) ;
            app.TIS_ComputeButton.Layout.Row = 10 ;
            app.TIS_ComputeButton.Layout.Column = [1 2] ;

            % Row 11: Display units
            unitsGrid = uigridlayout(leftGrid, [1 2], ...
                'ColumnWidth', {110, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 4) ;
            unitsGrid.Layout.Row = 11 ;
            unitsGrid.Layout.Column = [1 2] ;
            app.DisplayControls.TIS.time = app.createDisplayUnitControl( ...
                unitsGrid, 1, 1, 'Time base:', 'Time', 's', @(~,~) app.refreshDisplayUnits('TIS')) ;

            % Row 12: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 12 ; lbl.Layout.Column = [1 2] ;

            % Row 13: N used
            lbl = uilabel(leftGrid, 'Text', 'N used:') ;
            lbl.Layout.Row = 13 ; lbl.Layout.Column = 1 ;
            app.TIS_ResultNused = uilabel(leftGrid, 'Text', '--') ;
            app.TIS_ResultNused.Layout.Row = 13 ;
            app.TIS_ResultNused.Layout.Column = 2 ;

            % Row 14: X_TIS
            lbl = uilabel(leftGrid, 'Text', 'X<sub>TIS</sub>:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 14 ; lbl.Layout.Column = 1 ;
            app.TIS_ResultXtis = uilabel(leftGrid, 'Text', '--') ;
            app.TIS_ResultXtis.Layout.Row = 14 ;
            app.TIS_ResultXtis.Layout.Column = 2 ;
            app.TIS_ResultXtis.FontWeight = 'bold' ;

            % Row 15: X_CSTR + X_PFR on same row
            app.TIS_ResultXcstr = uilabel(leftGrid, 'Text', 'X<sub>CSTR</sub>: --', 'Interpreter', 'html') ;
            app.TIS_ResultXcstr.Layout.Row = 15 ; app.TIS_ResultXcstr.Layout.Column = 1 ;
            app.TIS_ResultXpfr = uilabel(leftGrid, 'Text', 'X<sub>PFR</sub>: --', 'Interpreter', 'html') ;
            app.TIS_ResultXpfr.Layout.Row = 15 ; app.TIS_ResultXpfr.Layout.Column = 2 ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'TIS Results') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % E(t) plot for TIS model
            app.TIS_AxesEt = uiaxes(plotGrid) ;
            title(app.TIS_AxesEt, 'E(t) - TIS Model') ;
            xlabel(app.TIS_AxesEt, 't [s]') ;
            ylabel(app.TIS_AxesEt, 'E(t) [1/s]') ;
            grid(app.TIS_AxesEt, 'off') ;

            % X vs N sweep plot
            app.TIS_AxesXvsN = uiaxes(plotGrid) ;
            title(app.TIS_AxesXvsN, 'Conversion vs N') ;
            xlabel(app.TIS_AxesXvsN, 'N [number of tanks]') ;
            ylabel(app.TIS_AxesXvsN, 'X_A') ;
            grid(app.TIS_AxesXvsN, 'off') ;

            % Comparison bar chart
            app.TIS_AxesComparison = uiaxes(plotGrid) ;
            app.TIS_AxesComparison.Layout.Column = [1 2] ;
            title(app.TIS_AxesComparison, 'Comparison: CSTR vs TIS vs PFR') ;
            ylabel(app.TIS_AxesComparison, 'Conversion X') ;
            grid(app.TIS_AxesComparison, 'off') ;
        end

        %% ============== TIS CALLBACKS ==============

        function TIS_NMethodChanged(app)
            source = app.TIS_NMethodDropdown.Value ;
            if contains(source, 'From Calculated')
                % Auto-compute N from RTD variance
                app.TIS_NField.Enable = 'off' ;
                app.TIS_tauField.Enable = 'off' ;
                app.TIS_RTDStatusLabel.Visible = 'on' ;
                app.TIS_RefreshButton.Visible = 'on' ;

                infoLines = {} ;

                if ~isempty(app.rtd) && app.rtd.sigma2 > 0
                    N_from_rtd = app.rtd.tau^2 / app.rtd.sigma2 ;
                    app.TIS_NField.Value = N_from_rtd ;
                    app.setInputFieldValue(app.TIS_tauField, app.rtd.tau) ;
                    infoLines{end+1} = sprintf('RTD: tau=%.2f, N=%.2f', ...
                        app.rtd.tau, N_from_rtd) ;
                else
                    infoLines{end+1} = 'RTD: not loaded' ;
                end

                % Import RS from Prediction Models tab (if loaded)
                if ~isempty(app.Pred_RS)
                    app.TIS_RS = app.Pred_RS ;
                    app.TIS_RSNameField.Value = app.Pred_RSNameField.Value ;
                    nR = app.Pred_RS.nReactions ;
                    nC = app.Pred_RS.nComponents ;
                    app.TIS_RSStatusLabel.Text = sprintf('Loaded: %d reactions, %d components', nR, nC) ;
                    app.TIS_RSStatusLabel.FontColor = [0 0.5 0] ;
                    app.TIS_RSEditButton.Enable = 'on' ;
                    infoLines{end+1} = sprintf('RS: %s', app.Pred_RSNameField.Value) ;
                else
                    infoLines{end+1} = 'RS: not loaded' ;
                end

                % Import CA0 from Prediction Models tab
                if ~isempty(app.Pred_CA0Field)
                    app.TIS_CA0Field.Value = app.Pred_CA0Field.Value ;
                    app.TIS_CA0Field.UserData.unitDropdown.Value = app.Pred_CA0Field.UserData.unitDropdown.Value ;
                    infoLines{end+1} = sprintf('CA0=%.4g', app.readInputField(app.Pred_CA0Field)) ;
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
                app.TIS_RTDStatusLabel.Visible = 'off' ;
                app.TIS_RefreshButton.Visible = 'off' ;
            end
        end

        function TIS_loadRS(app)
            % Load a ReactionSys object from the MATLAB workspace by name
            rsName = app.TIS_RSNameField.Value ;
            try
                RS = evalin('base', rsName) ;
                if ~isa(RS, 'ReactionSys')
                    error('Variable "%s" is not a ReactionSys object.', rsName) ;
                end
                app.TIS_RS = RS ;
                nR = RS.nReactions ;
                nC = RS.nComponents ;
                app.TIS_RSStatusLabel.Text = sprintf('Loaded: %d reactions, %d components', nR, nC) ;
                app.TIS_RSStatusLabel.FontColor = [0 0.5 0] ;
                app.TIS_RSEditButton.Enable = 'on' ;
            catch ME
                app.TIS_RSStatusLabel.Text = ME.message ;
                app.TIS_RSStatusLabel.FontColor = [0.8 0 0] ;
            end
        end

        function TIS_editRS(app)
            % Open defineReactionSysApp pre-loaded with the current RS
            if isempty(app.TIS_RS)
                uialert(app.UIFigure, ...
                    'No Reaction System loaded to edit.', 'Nothing to Edit') ;
                return
            end
            rsName = app.TIS_RSNameField.Value ;
            defineReactionSysApp(app.TIS_RS, rsName) ;
        end

        function TIS_compute(app)
            try
                app.updateStatus('Computing TIS model...') ;

                % Validate that a ReactionSys is loaded
                if isempty(app.TIS_RS)
                    uialert(app.UIFigure, ...
                        'No Reaction System loaded. Use "Define Reaction System" to create one, then "Load from Workspace" to import it.', ...
                        'Missing Reaction System') ;
                    app.updateStatus('Ready') ;
                    return ;
                end

                N_val = app.TIS_NField.Value ;
                tau_val = app.readInputField(app.TIS_tauField) ;
                RS = app.TIS_RS ;
                CA0_val = app.readInputField(app.TIS_CA0Field) ;

                % Build initial concentration vector: [CA0, 0, 0, ...]
                C0 = zeros(1, RS.nComponents) ;
                C0(1) = CA0_val ;

                % --- Compute X_TIS for selected N ---
                [~, X_tis] = TanksInSeries.solve_sequential(N_val, RS, C0, tau_val) ;

                % --- Reference: CSTR (N=1) ---
                [~, X_cstr] = TanksInSeries.solve_sequential(1, RS, C0, tau_val) ;

                % --- Reference: PFR (N→inf) ---
                [~, X_pfr] = TanksInSeries.solve_PFR(RS, C0, tau_val) ;

                % --- Update results ---
                app.TIS_ResultNused.Text = sprintf('%.2f', N_val) ;
                app.TIS_ResultXtis.Text = sprintf('%.4f', X_tis) ;
                app.TIS_ResultXcstr.Text = sprintf('X_{CSTR}: %.4f', X_cstr) ;
                app.TIS_ResultXpfr.Text = sprintf('X_{PFR}: %.4f', X_pfr) ;

                app.DisplayCache.TIS = struct( ...
                    'N_val', N_val, ...
                    'tau_val', tau_val, ...
                    'RS', RS, ...
                    'C0', C0, ...
                    'X_tis', X_tis, ...
                    'X_cstr', X_cstr, ...
                    'X_pfr', X_pfr) ;

                % --- Update plots ---
                app.TIS_updatePlots(N_val, tau_val, RS, C0, ...
                    X_tis, X_cstr, X_pfr) ;

                app.updateStatus('Ready') ;

            catch ME
                app.updateStatus('Error') ;
                uialert(app.UIFigure, ME.message, 'TIS Computation Error') ;
            end
        end

        function TIS_updatePlots(app, N_val, tau_val, RS, C0, ...
                                 X_tis, X_cstr, X_pfr)

            % ---- Plot 1: E(t) for current N ----
            cla(app.TIS_AxesEt) ;
            rtd_tis = RTD.tanks_in_series(N_val, tau_val) ;
            timeDD = app.DisplayControls.TIS.time ;
            t_display = app.convertOutputVectorFromTime('time', rtd_tis.t, timeDD) ;
            Et_display = app.convertOutputVectorFromTime('timeInverse', rtd_tis.Et, timeDD) ;
            plot(app.TIS_AxesEt, t_display, Et_display, 'b-', 'LineWidth', 1.5) ;
            title(app.TIS_AxesEt, sprintf('E(t) - TIS  N=%.1f', N_val)) ;
            xlabel(app.TIS_AxesEt, app.axisLabelWithUnit('t', timeDD)) ;
            ylabel(app.TIS_AxesEt, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(timeDD))) ;

            % ---- Plot 2: X vs N sweep ----
            cla(app.TIS_AxesXvsN) ;
            N_sweep = [1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 50, 100] ;
            X_sweep = zeros(size(N_sweep)) ;

            for idx = 1:length(N_sweep)
                [~, X_sweep(idx)] = TanksInSeries.solve_sequential( ...
                    N_sweep(idx), RS, C0, tau_val) ;
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
            leftGrid = uigridlayout(leftPanel, [18 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 18) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: Input method
            lbl = uilabel(leftGrid, 'Text', 'Input:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = 1 ;
            methodSubGridD = uigridlayout(leftGrid, [1 2], ...
                'ColumnWidth', {'1x', 28}, 'Padding', [0 0 0 0], 'ColumnSpacing', 2) ;
            methodSubGridD.Layout.Row = 1 ; methodSubGridD.Layout.Column = 2 ;
            app.Disp_InputMethodDropdown = uidropdown(methodSubGridD, ...
                'Items', {'Manual', 'From Calculated Data'}, ...
                'Value', 'Manual', ...
                'ValueChangedFcn', @(~,~) app.Disp_inputMethodChanged()) ;
            app.Disp_RefreshButton = uibutton(methodSubGridD, 'push', ...
                'Text', char(8635), 'FontSize', 12, ...
                'Tooltip', 'Refresh imported data from Tab 1 and Tab 2', ...
                'Visible', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Disp_inputMethodChanged()) ;

            % Row 2: Import status (hidden by default)
            app.Disp_RTDStatusLabel = uilabel(leftGrid, ...
                'Text', '', 'FontColor', [0 0.5 0]) ;
            app.Disp_RTDStatusLabel.Layout.Row = 2 ;
            app.Disp_RTDStatusLabel.Layout.Column = [1 2] ;
            app.Disp_RTDStatusLabel.Visible = 'off' ;

            % Row 3: Bo
            app.Disp_BoLabel = uilabel(leftGrid, 'Text', 'Bo [= D<sub>e</sub>/uL]:', 'Interpreter', 'html') ;
            app.Disp_BoLabel.Layout.Row = 3 ; app.Disp_BoLabel.Layout.Column = 1 ;
            app.Disp_BoLabel.FontWeight = 'bold' ;
            app.Disp_BoField = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.025, 'Limits', [1e-6 100], ...
                'ValueChangedFcn', @(~,~) app.Disp_updatePe(), ...
                'Tooltip', 'Dispersion number Bo = De/(u·L). Bo→0: plug flow (PFR), Bo→∞: perfect mixing (CSTR).') ;
            app.Disp_BoField.Layout.Row = 3 ; app.Disp_BoField.Layout.Column = 2 ;

            % Row 4: Pe display (read-only)
            lbl = uilabel(leftGrid, 'Text', 'Pe [= 1/Bo]:') ;
            lbl.Layout.Row = 4 ; lbl.Layout.Column = 1 ;
            app.Disp_PeLabel = uilabel(leftGrid, 'Text', sprintf('%.2f', 1/0.025)) ;
            app.Disp_PeLabel.Layout.Row = 4 ; app.Disp_PeLabel.Layout.Column = 2 ;

            % Row 5: Boundary conditions
            app.Disp_BCLabel = uilabel(leftGrid, 'Text', 'Boundary:') ;
            app.Disp_BCLabel.Layout.Row = 5 ; app.Disp_BCLabel.Layout.Column = 1 ;
            app.Disp_BCDropdown = uidropdown(leftGrid, ...
                'Items', {'closed-closed', 'open-open'}, ...
                'Value', 'closed-closed', ...
                'Tooltip', 'closed-closed: confined reactor (Danckwerts). open-open: open reactor (Gaussian approximation).') ;
            app.Disp_BCDropdown.Layout.Row = 5 ; app.Disp_BCDropdown.Layout.Column = 2 ;

            % Row 6: tau
            app.Disp_tauLabel = uilabel(leftGrid, 'Text', '&tau;:', 'Interpreter', 'html') ;
            app.Disp_tauLabel.Layout.Row = 6 ; app.Disp_tauLabel.Layout.Column = 1 ;
            [app.Disp_tauField, ~] = app.createNumericWithConv( ...
                leftGrid, 6, 2, 10, 'Time', ...
                'Limits', [0.001 Inf], ...
                'Tooltip', 'Mean residence time: tau = V/Q = L/u.') ;

            % Row 7: Reaction System header
            lbl = uilabel(leftGrid, 'Text', 'Reaction System:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 7 ; lbl.Layout.Column = [1 2] ;

            % Row 8: New RS + Edit RS buttons
            app.Disp_RSDefineButton = uibutton(leftGrid, 'push', ...
                'Text', 'New RS', ...
                'BackgroundColor', [0.85 0.90 1.0], ...
                'Tooltip', 'Create a new Reaction System from scratch', ...
                'ButtonPushedFcn', @(~,~) defineReactionSysApp()) ;
            app.Disp_RSDefineButton.Layout.Row = 8 ;
            app.Disp_RSDefineButton.Layout.Column = 1 ;

            app.Disp_RSEditButton = uibutton(leftGrid, 'push', ...
                'Text', 'Edit RS', ...
                'BackgroundColor', [1.0 0.95 0.80], ...
                'Tooltip', 'Edit the currently loaded Reaction System', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Disp_editRS()) ;
            app.Disp_RSEditButton.Layout.Row = 8 ;
            app.Disp_RSEditButton.Layout.Column = 2 ;

            % Row 9: RS name field + Load button
            app.Disp_RSNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'RS', ...
                'Tooltip', 'Name of the ReactionSys variable in the MATLAB workspace') ;
            app.Disp_RSNameField.Layout.Row = 9 ; app.Disp_RSNameField.Layout.Column = 1 ;
            app.Disp_RSLoadButton = uibutton(leftGrid, 'push', ...
                'Text', 'Load from Workspace', ...
                'BackgroundColor', [0.85 0.95 0.85], ...
                'Tooltip', 'Load the ReactionSys object from the workspace', ...
                'ButtonPushedFcn', @(~,~) app.Disp_loadRS()) ;
            app.Disp_RSLoadButton.Layout.Row = 9 ; app.Disp_RSLoadButton.Layout.Column = 2 ;

            % Row 10: RS status
            app.Disp_RSStatusLabel = uilabel(leftGrid, ...
                'Text', 'No Reaction System loaded', 'FontColor', [0.6 0 0]) ;
            app.Disp_RSStatusLabel.Layout.Row = 10 ;
            app.Disp_RSStatusLabel.Layout.Column = [1 2] ;

            % Row 11: CA0
            app.Disp_CA0Label = uilabel(leftGrid, 'Text', 'C<sub>A0</sub>:', 'Interpreter', 'html') ;
            app.Disp_CA0Label.Layout.Row = 11 ; app.Disp_CA0Label.Layout.Column = 1 ;
            [app.Disp_CA0Field, ~] = app.createNumericWithConv( ...
                leftGrid, 11, 2, 1000, 'Concentration', ...
                'Limits', [0.001 Inf], ...
                'Tooltip', 'Initial concentration of limiting reactant in the feed.') ;

            % Row 12: Compute button
            app.Disp_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Compute', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Disp_compute()) ;
            app.Disp_ComputeButton.Layout.Row = 12 ;
            app.Disp_ComputeButton.Layout.Column = [1 2] ;

            % Row 13: Display units
            unitsGrid = uigridlayout(leftGrid, [1 2], ...
                'ColumnWidth', {110, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 4) ;
            unitsGrid.Layout.Row = 13 ;
            unitsGrid.Layout.Column = [1 2] ;
            app.DisplayControls.Dispersion.time = app.createDisplayUnitControl( ...
                unitsGrid, 1, 1, 'Time base:', 'Time', 's', @(~,~) app.refreshDisplayUnits('Dispersion')) ;

            % Row 14: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 14 ; lbl.Layout.Column = [1 2] ;

            % Row 15: Bo info
            lbl = uilabel(leftGrid, 'Text', 'Bo:') ;
            lbl.Layout.Row = 15 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultBo = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultBo.Layout.Row = 15 ; app.Disp_ResultBo.Layout.Column = 2 ;

            % Row 16: X_dispersion
            lbl = uilabel(leftGrid, 'Text', 'X<sub>dispersion</sub>:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 16 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultX = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultX.Layout.Row = 16 ; app.Disp_ResultX.Layout.Column = 2 ;
            app.Disp_ResultX.FontWeight = 'bold' ;

            % Row 17: X_CSTR
            lbl = uilabel(leftGrid, 'Text', 'X<sub>CSTR</sub> [Bo&#8594;&#8734;]:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 17 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultXcstr = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultXcstr.Layout.Row = 17 ; app.Disp_ResultXcstr.Layout.Column = 2 ;

            % Row 18: X_PFR
            lbl = uilabel(leftGrid, 'Text', 'X<sub>PFR</sub> [Bo&#8594;0]:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 18 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultXpfr = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultXpfr.Layout.Row = 18 ; app.Disp_ResultXpfr.Layout.Column = 2 ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Dispersion Results') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % E(t) plot
            app.Disp_AxesEt = uiaxes(plotGrid) ;
            title(app.Disp_AxesEt, 'E(t) - Dispersion') ;
            xlabel(app.Disp_AxesEt, 't [s]') ;
            ylabel(app.Disp_AxesEt, 'E(t) [1/s]') ;
            grid(app.Disp_AxesEt, 'off') ;

            % X vs Bo sweep
            app.Disp_AxesXvsBo = uiaxes(plotGrid) ;
            title(app.Disp_AxesXvsBo, 'X vs Bo') ;
            xlabel(app.Disp_AxesXvsBo, 'Bo [dispersion number]') ;
            ylabel(app.Disp_AxesXvsBo, 'X_A') ;
            grid(app.Disp_AxesXvsBo, 'off') ;

            % Comparison bar chart (spans 2 columns)
            app.Disp_AxesComparison = uiaxes(plotGrid) ;
            app.Disp_AxesComparison.Layout.Column = [1 2] ;
            title(app.Disp_AxesComparison, 'PFR vs Dispersion vs CSTR') ;
            ylabel(app.Disp_AxesComparison, 'Conversion X') ;
            grid(app.Disp_AxesComparison, 'off') ;
        end

        %% ============== DISPERSION CALLBACKS ==============

        function Disp_updatePe(app)
            Bo = app.Disp_BoField.Value ;
            Pe = 1 / Bo ;
            app.Disp_PeLabel.Text = sprintf('%.2f', Pe) ;
        end

        function Disp_loadRS(app)
            % Load a ReactionSys object from the MATLAB workspace by name
            rsName = app.Disp_RSNameField.Value ;
            try
                RS = evalin('base', rsName) ;
                if ~isa(RS, 'ReactionSys')
                    error('Variable "%s" is not a ReactionSys object.', rsName) ;
                end
                app.Disp_RS = RS ;
                nR = RS.nReactions ;
                nC = RS.nComponents ;
                app.Disp_RSStatusLabel.Text = sprintf('Loaded: %d reactions, %d components', nR, nC) ;
                app.Disp_RSStatusLabel.FontColor = [0 0.5 0] ;
                app.Disp_RSEditButton.Enable = 'on' ;
            catch ME
                app.Disp_RSStatusLabel.Text = ME.message ;
                app.Disp_RSStatusLabel.FontColor = [0.8 0 0] ;
            end
        end

        function Disp_editRS(app)
            % Open defineReactionSysApp pre-loaded with the current RS
            if isempty(app.Disp_RS)
                uialert(app.UIFigure, ...
                    'No Reaction System loaded to edit.', 'Nothing to Edit') ;
                return
            end
            rsName = app.Disp_RSNameField.Value ;
            defineReactionSysApp(app.Disp_RS, rsName) ;
        end

        function Disp_inputMethodChanged(app)
            source = app.Disp_InputMethodDropdown.Value ;

            if contains(source, 'From Calculated')
                % Disable manual fields and import data
                app.Disp_BoField.Enable = 'off' ;
                app.Disp_tauField.Enable = 'off' ;
                app.Disp_CA0Field.Enable = 'off' ;
                app.Disp_RTDStatusLabel.Visible = 'on' ;
                app.Disp_RefreshButton.Visible = 'on' ;

                infoLines = {} ;

                % Import RTD data (tau, sigma2_theta -> Bo)
                if ~isempty(app.rtd) && app.rtd.sigma2 > 0
                    app.setInputFieldValue(app.Disp_tauField, app.rtd.tau) ;
                    sigma2_theta = app.rtd.sigma2 / app.rtd.tau^2 ;
                    bcType = app.Disp_BCDropdown.Value ;

                    % Compute Bo from sigma2_theta
                    Bo_calc = app.compute_Bo_from_variance(sigma2_theta, bcType) ;
                    if isnan(Bo_calc) || isinf(Bo_calc) || Bo_calc < 1e-6 || Bo_calc > 100
                        msg = sprintf(['Calculated Bo = %g is outside the valid range [1e-6, 100].\n\n' ...
                            'Possible causes:\n' ...
                            '  - Near-ideal RTD (PFR-like): variance is too small, leading to Bo ≈ 0.\n' ...
                            '  - Invalid RTD data: sigma² or tau contain NaN/Inf values.\n' ...
                            '  - Very large dispersion: variance is too high, producing Bo > 100.\n\n' ...
                            'Current RTD values: sigma² = %.4g, tau = %.4g'], ...
                            Bo_calc, app.rtd.sigma2, app.rtd.tau) ;
                        uialert(app.UIFigure, msg, 'Bo Out of Range', 'Icon', 'warning') ;
                        return
                    end
                    app.Disp_BoField.Value = Bo_calc ;
                    app.Disp_updatePe() ;

                    infoLines{end+1} = sprintf('RTD: tau=%.2f, Bo=%.4g', ...
                        app.rtd.tau, Bo_calc) ;
                else
                    infoLines{end+1} = 'RTD: not loaded' ;
                end

                % Import RS from Prediction Models tab (if loaded)
                if ~isempty(app.Pred_RS)
                    app.Disp_RS = app.Pred_RS ;
                    app.Disp_RSNameField.Value = app.Pred_RSNameField.Value ;
                    nR = app.Disp_RS.nReactions ;
                    nC = app.Disp_RS.nComponents ;
                    app.Disp_RSStatusLabel.Text = sprintf('Loaded: %d reactions, %d components', nR, nC) ;
                    app.Disp_RSStatusLabel.FontColor = [0 0.5 0] ;
                    app.Disp_RSEditButton.Enable = 'on' ;
                    infoLines{end+1} = sprintf('RS: %s', app.Pred_RSNameField.Value) ;
                else
                    infoLines{end+1} = 'RS: not loaded' ;
                end

                % Import CA0 from Prediction Models tab
                if ~isempty(app.Pred_CA0Field)
                    app.Disp_CA0Field.Value = app.Pred_CA0Field.Value ;
                    app.Disp_CA0Field.UserData.unitDropdown.Value = app.Pred_CA0Field.UserData.unitDropdown.Value ;
                    infoLines{end+1} = sprintf('CA0=%.4g', app.readInputField(app.Pred_CA0Field)) ;
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
                app.Disp_CA0Field.Enable = 'on' ;
                app.Disp_RTDStatusLabel.Visible = 'off' ;
                app.Disp_RefreshButton.Visible = 'off' ;
            end
        end

        function Disp_compute(app)

            try
                app.updateStatus('Computing dispersion model...') ;

                % Validate that a ReactionSys is loaded
                if isempty(app.Disp_RS)
                    uialert(app.UIFigure, ...
                        'No Reaction System loaded. Use "New RS" to create one, then "Load from Workspace" to import it.', ...
                        'Missing Reaction System') ;
                    app.updateStatus('Ready') ;
                    return ;
                end

                Bo_val = app.Disp_BoField.Value ;
                bcType = app.Disp_BCDropdown.Value ;
                tau_val = app.readInputField(app.Disp_tauField) ;
                CA0_val = app.readInputField(app.Disp_CA0Field) ;
                RS = app.Disp_RS ;

                % Build initial concentration vector
                C0 = zeros(1, RS.nComponents) ;
                C0(1) = CA0_val ;

                % Create DispersionReactor
                app.disp_reactor = DispersionReactor(Bo_val, bcType) ;

                % Compute dispersion conversion via general method
                X_disp = app.disp_reactor.compute_conversion_general(RS, C0, tau_val) ;

                % Reference: CSTR and PFR via TanksInSeries module
                [~, X_cstr] = TanksInSeries.solve_sequential(1, RS, C0, tau_val) ;
                [~, X_pfr]  = TanksInSeries.solve_PFR(RS, C0, tau_val) ;

                X_cstr = max(0, min(1, X_cstr)) ;
                X_pfr  = max(0, min(1, X_pfr)) ;

                % Update results
                app.Disp_ResultBo.Text = sprintf('Bo=%.4g, Pe=%.4g', Bo_val, 1/Bo_val) ;
                app.Disp_ResultX.Text = sprintf('%.4f', X_disp) ;
                app.Disp_ResultXcstr.Text = sprintf('%.4f', X_cstr) ;
                app.Disp_ResultXpfr.Text = sprintf('%.4f', X_pfr) ;

                app.DisplayCache.Dispersion = struct( ...
                    'Bo_val', Bo_val, ...
                    'tau_val', tau_val, ...
                    'RS', RS, ...
                    'C0', C0, ...
                    'X_disp', X_disp, ...
                    'X_cstr', X_cstr, ...
                    'X_pfr', X_pfr) ;

                % Update plots
                app.Disp_updatePlots(Bo_val, tau_val, RS, C0, ...
                                     X_disp, X_cstr, X_pfr) ;

                app.updateStatus('Ready') ;

            catch ME
                app.updateStatus('Error') ;
                uialert(app.UIFigure, ME.message, 'Dispersion Model Error') ;
            end
        end

        function Disp_updatePlots(app, Bo_val, tau_val, RS, C0, ...
                                  X_disp, X_cstr, X_pfr)

            % ---- Plot 1: E(t) ----
            cla(app.Disp_AxesEt) ;
            rtd_obj = app.disp_reactor.generate_RTD(tau_val) ;
            timeDD = app.DisplayControls.Dispersion.time ;
            t_display = app.convertOutputVectorFromTime('time', rtd_obj.t, timeDD) ;
            Et_display = app.convertOutputVectorFromTime('timeInverse', rtd_obj.Et, timeDD) ;
            plot(app.Disp_AxesEt, t_display, Et_display, 'b-', 'LineWidth', 1.5) ;
            title(app.Disp_AxesEt, sprintf('E(t) - %s, Bo=%.4g', ...
                  app.Disp_BCDropdown.Value, Bo_val)) ;
            xlabel(app.Disp_AxesEt, app.axisLabelWithUnit('t', timeDD)) ;
            ylabel(app.Disp_AxesEt, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(timeDD))) ;

            % Add annotation
            tau_display = app.convertOutputScalar('Time', tau_val, timeDD) ;
            text(app.Disp_AxesEt, 0.95, 0.90, ...
                sprintf('Bo = %.4g\nPe = %.4g\n\\tau = %.4g %s', ...
                        Bo_val, 1/Bo_val, tau_display, timeDD.Value), ...
                'Units', 'normalized', 'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'top', 'FontSize', 9, ...
                'Interpreter', 'tex', ...
                'BackgroundColor', [1 1 1 0.8], 'EdgeColor', [0.7 0.7 0.7]) ;

            % ---- Plot 2: X vs Bo sweep ----
            cla(app.Disp_AxesXvsBo) ;
            [Bo_sweep, X_sweep] = app.disp_reactor.sweep_Bo_general(RS, C0, tau_val) ;
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

            % ---- Plot 3: Comparison bar chart (CSTR → Disp → PFR) ----
            cla(app.Disp_AxesComparison) ;
            bar_data = [X_cstr ; X_disp ; X_pfr] ;
            b = bar(app.Disp_AxesComparison, bar_data) ;
            b.FaceColor = 'flat' ;
            b.CData = [0.9 0.3 0.3 ; 0.3 0.6 0.9 ; 0.3 0.8 0.3] ;
            set(app.Disp_AxesComparison, 'XTickLabel', ...
                {'CSTR (Bo->inf)', sprintf('Disp (Bo=%.3g)', Bo_val), 'PFR (Bo->0)'}) ;
            ylabel(app.Disp_AxesComparison, 'Conversion X') ;
            title(app.Disp_AxesComparison, 'CSTR vs Dispersion vs PFR') ;
            ylim(app.Disp_AxesComparison, [0 1.12]) ;

            % Value labels
            hold(app.Disp_AxesComparison, 'on') ;
            vals = [X_cstr, X_disp, X_pfr] ;
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
            leftPanel = uipanel(mainGrid, 'Title', 'Convolution / Deconvolution') ;
            leftGrid = uigridlayout(leftPanel, [23 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 23) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 4 ;

            % Row 1: Workflow hint
            lbl = uilabel(leftGrid, 'Text', '1) Choose mode  2) Select source  3) Compute', ...
                'FontAngle', 'italic', 'FontColor', [0.4 0.4 0.4], 'FontSize', 10) ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = [1 2] ;

            % Row 2: Mode
            lbl = uilabel(leftGrid, 'Text', 'Mode:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 2 ; lbl.Layout.Column = 1 ;
            app.Conv_ModeDropdown = uidropdown(leftGrid, ...
                'Items', {'Convolution', 'Deconvolution'}, ...
                'Value', 'Convolution', ...
                'ValueChangedFcn', @(~,~) app.Conv_modeChanged()) ;
            app.Conv_ModeDropdown.Layout.Row = 2 ;
            app.Conv_ModeDropdown.Layout.Column = 2 ;

            % Row 3: Data Source (expanded)
            lbl = uilabel(leftGrid, 'Text', 'Data Source:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 3 ; lbl.Layout.Column = 1 ;
            app.Conv_InputDropdown = uidropdown(leftGrid, ...
                'Items', {'From Workspace', 'From Equation', 'From Tab 1 (RTD)', 'From File'}, ...
                'Value', 'From Workspace', ...
                'ValueChangedFcn', @(~,~) app.Conv_sourceChanged()) ;
            app.Conv_InputDropdown.Layout.Row = 3 ;
            app.Conv_InputDropdown.Layout.Column = 2 ;

            % Row 4: RTD Status (Tab1 mode only — hidden by default)
            app.Conv_RTDStatusLabel = uilabel(leftGrid, ...
                'Text', 'RTD: not loaded', ...
                'FontAngle', 'italic', 'FontColor', [0.5 0.5 0.5], ...
                'WordWrap', 'on', 'Visible', 'off') ;
            app.Conv_RTDStatusLabel.Layout.Row = 4 ;
            app.Conv_RTDStatusLabel.Layout.Column = [1 2] ;

            % ---- Workspace / File fields (rows 5-7, visible by default) ----
            app.Conv_tVarLabel = uilabel(leftGrid, 'Text', 'Variable t [s]:') ;
            app.Conv_tVarLabel.Layout.Row = 5 ; app.Conv_tVarLabel.Layout.Column = 1 ;
            app.Conv_tVarField = uieditfield(leftGrid, 'text', 'Value', 't') ;
            app.Conv_tVarField.Layout.Row = 5 ; app.Conv_tVarField.Layout.Column = 2 ;

            app.Conv_CinVarLabel = uilabel(leftGrid, ...
                'Text', 'Variable C<sub>in</sub>(t):', 'Interpreter', 'html') ;
            app.Conv_CinVarLabel.Layout.Row = 6 ; app.Conv_CinVarLabel.Layout.Column = 1 ;
            app.Conv_CinVarField = uieditfield(leftGrid, 'text', 'Value', 'C_in') ;
            app.Conv_CinVarField.Layout.Row = 6 ; app.Conv_CinVarField.Layout.Column = 2 ;

            app.Conv_EVarLabel = uilabel(leftGrid, 'Text', 'Variable E(t) [1/s]:') ;
            app.Conv_EVarLabel.Layout.Row = 7 ; app.Conv_EVarLabel.Layout.Column = 1 ;
            app.Conv_EVarField = uieditfield(leftGrid, 'text', 'Value', 'E') ;
            app.Conv_EVarField.Layout.Row = 7 ; app.Conv_EVarField.Layout.Column = 2 ;

            app.Conv_CoutVarLabel = uilabel(leftGrid, ...
                'Text', 'Variable C<sub>out</sub>(t):', 'Interpreter', 'html', ...
                'Visible', 'off') ;
            app.Conv_CoutVarLabel.Layout.Row = 7 ; app.Conv_CoutVarLabel.Layout.Column = 1 ;
            app.Conv_CoutVarField = uieditfield(leftGrid, 'text', ...
                'Value', 'C_out', 'Visible', 'off') ;
            app.Conv_CoutVarField.Layout.Row = 7 ; app.Conv_CoutVarField.Layout.Column = 2 ;

            % ---- Equation mode: time params (rows 5-7, overlapping WS) ----
            app.Conv_TstartLabel = uilabel(leftGrid, ...
                'Text', 't start:', 'Visible', 'off') ;
            app.Conv_TstartLabel.Layout.Row = 5 ; app.Conv_TstartLabel.Layout.Column = 1 ;
            [app.Conv_TstartField, tmpSGcs] = app.createNumericWithConv( ...
                leftGrid, 5, 2, 0, 'Time') ;
            tmpSGcs.Visible = 'off' ;

            app.Conv_TendLabel = uilabel(leftGrid, ...
                'Text', 't end:', 'Visible', 'off') ;
            app.Conv_TendLabel.Layout.Row = 6 ; app.Conv_TendLabel.Layout.Column = 1 ;
            [app.Conv_TendField, tmpSGce] = app.createNumericWithConv( ...
                leftGrid, 6, 2, 50, 'Time', 'Limits', [0.001 Inf]) ;
            tmpSGce.Visible = 'off' ;

            app.Conv_NptsLabel = uilabel(leftGrid, ...
                'Text', 'N points:', 'Visible', 'off') ;
            app.Conv_NptsLabel.Layout.Row = 7 ; app.Conv_NptsLabel.Layout.Column = 1 ;
            app.Conv_NptsField = uieditfield(leftGrid, 'numeric', ...
                'Value', 200, 'Limits', [10 100000], 'Visible', 'off') ;
            app.Conv_NptsField.Layout.Row = 7 ; app.Conv_NptsField.Layout.Column = 2 ;

            % ---- Equation fields (rows 8-11, hidden by default) ----
            % C_in equation (shown for Equation and Tab1 modes)
            app.Conv_CinEqLabel = uilabel(leftGrid, ...
                'Text', 'C<sub>in</sub>(t) equation:', ...
                'Interpreter', 'html', 'FontWeight', 'bold', 'Visible', 'off') ;
            app.Conv_CinEqLabel.Layout.Row = 8 ; app.Conv_CinEqLabel.Layout.Column = [1 2] ;
            app.Conv_CinEqField = uieditfield(leftGrid, 'text', ...
                'Value', '5*exp(-0.1*t)', ...
                'Tooltip', 'MATLAB expression using t. Examples: 5*exp(-t/10), 10*(1-exp(-t/5))', ...
                'Visible', 'off') ;
            app.Conv_CinEqField.Layout.Row = 9 ; app.Conv_CinEqField.Layout.Column = [1 2] ;

            % E(t) equation (Equation + Conv mode only)
            app.Conv_EEqLabel = uilabel(leftGrid, ...
                'Text', 'E(t) equation:', ...
                'FontWeight', 'bold', 'Visible', 'off') ;
            app.Conv_EEqLabel.Layout.Row = 10 ; app.Conv_EEqLabel.Layout.Column = [1 2] ;
            app.Conv_EEqField = uieditfield(leftGrid, 'text', ...
                'Value', '(1/5)*exp(-t/5)', ...
                'Tooltip', 'MATLAB expression using t. E(t) >= 0, integral ~ 1.', ...
                'Visible', 'off') ;
            app.Conv_EEqField.Layout.Row = 11 ; app.Conv_EEqField.Layout.Column = [1 2] ;

            % C_out equation (Equation + Deconv mode, overlapping rows 10-11)
            app.Conv_CoutEqLabel = uilabel(leftGrid, ...
                'Text', 'C<sub>out</sub>(t) equation:', ...
                'Interpreter', 'html', 'FontWeight', 'bold', 'Visible', 'off') ;
            app.Conv_CoutEqLabel.Layout.Row = 10 ; app.Conv_CoutEqLabel.Layout.Column = [1 2] ;
            app.Conv_CoutEqField = uieditfield(leftGrid, 'text', ...
                'Value', 't.*exp(-t/2)', ...
                'Tooltip', 'MATLAB expression using t.', ...
                'Visible', 'off') ;
            app.Conv_CoutEqField.Layout.Row = 11 ; app.Conv_CoutEqField.Layout.Column = [1 2] ;

            % Row 12: nE (deconvolution only)
            app.Conv_nELabel = uilabel(leftGrid, 'Text', 'N points E(t):', ...
                'Tooltip', 'Number of points to reconstruct E(t). Typically 30-100.', ...
                'Visible', 'off') ;
            app.Conv_nELabel.Layout.Row = 12 ; app.Conv_nELabel.Layout.Column = 1 ;
            app.Conv_nEField = uieditfield(leftGrid, 'numeric', ...
                'Value', 50, 'Limits', [2 10000], ...
                'Tooltip', 'More points = higher resolution but slower', ...
                'Visible', 'off') ;
            app.Conv_nEField.Layout.Row = 12 ; app.Conv_nEField.Layout.Column = 2 ;

            % Row 13: Import from file button (File mode only)
            app.Conv_ImportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Import from File', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [1 1 1], ...
                'FontColor', [0.8 0 0], ...
                'Visible', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Conv_importFromFile()) ;
            app.Conv_ImportButton.Layout.Row = 13 ;
            app.Conv_ImportButton.Layout.Column = [1 2] ;

            % Row 14: Import / status label
            app.Conv_ImportLabel = uilabel(leftGrid, 'Text', '') ;
            app.Conv_ImportLabel.Layout.Row = 14 ;
            app.Conv_ImportLabel.Layout.Column = [1 2] ;
            app.Conv_ImportLabel.FontColor = [0 0.5 0] ;
            app.Conv_ImportLabel.WordWrap = 'on' ;

            % Row 15: Compute button
            app.Conv_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Compute', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Conv_compute()) ;
            app.Conv_ComputeButton.Layout.Row = 15 ;
            app.Conv_ComputeButton.Layout.Column = [1 2] ;

            % Row 16: Display units
            unitsGrid = uigridlayout(leftGrid, [1 2], ...
                'ColumnWidth', {110, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 4) ;
            unitsGrid.Layout.Row = 16 ;
            unitsGrid.Layout.Column = [1 2] ;
            app.DisplayControls.Convolution.time = app.createDisplayUnitControl( ...
                unitsGrid, 1, 1, 'Time base:', 'Time', 's', @(~,~) app.refreshDisplayUnits('Convolution')) ;

            % Row 17: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 17 ; lbl.Layout.Column = [1 2] ;

            % Row 18-19: Result text
            app.Conv_ResultLabel = uilabel(leftGrid, 'Text', '--') ;
            app.Conv_ResultLabel.Layout.Row = [18 19] ;
            app.Conv_ResultLabel.Layout.Column = [1 2] ;
            app.Conv_ResultLabel.WordWrap = 'on' ;

            % Row 20: Use Previous Result as C_in (chaining)
            app.Conv_UsePrevButton = uibutton(leftGrid, 'push', ...
                'Text', 'Use Previous C_out as C_in', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.95 0.85 0.55], ...
                'FontColor', [0.3 0.2 0], ...
                'Enable', 'off', ...
                'Tooltip', 'Load the last convolution output as new input for chaining.', ...
                'ButtonPushedFcn', @(~,~) app.Conv_usePreviousResult()) ;
            app.Conv_UsePrevButton.Layout.Row = 20 ;
            app.Conv_UsePrevButton.Layout.Column = [1 2] ;

            % Row 21: Export name
            lbl = uilabel(leftGrid, 'Text', 'Export Name:') ;
            lbl.Layout.Row = 21 ; lbl.Layout.Column = 1 ;
            app.Conv_ExportNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'conv_result') ;
            app.Conv_ExportNameField.Layout.Row = 21 ;
            app.Conv_ExportNameField.Layout.Column = 2 ;

            % Row 22: Export button
            app.Conv_ExportButton = uibutton(leftGrid, 'push', ...
                'Text', 'Export to Workspace', ...
                'BackgroundColor', [0.2 0.7 0.3], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Conv_export()) ;
            app.Conv_ExportButton.Layout.Row = 22 ;
            app.Conv_ExportButton.Layout.Column = [1 2] ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Signals') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            app.Conv_AxesInput = uiaxes(plotGrid) ;
            title(app.Conv_AxesInput, 'Input Signals') ;
            xlabel(app.Conv_AxesInput, 't [s]') ;
            ylabel(app.Conv_AxesInput, 'Concentration / E(t)') ;
            grid(app.Conv_AxesInput, 'off') ;

            app.Conv_AxesResult = uiaxes(plotGrid) ;
            title(app.Conv_AxesResult, 'Result') ;
            xlabel(app.Conv_AxesResult, 't [s]') ;
            ylabel(app.Conv_AxesResult, 'C_{out}(t)') ;
            grid(app.Conv_AxesResult, 'off') ;

            app.Conv_AxesRecovered = uiaxes(plotGrid) ;
            app.Conv_AxesRecovered.Layout.Column = [1 2] ;
            title(app.Conv_AxesRecovered, 'Verification') ;
            xlabel(app.Conv_AxesRecovered, 't [s]') ;
            ylabel(app.Conv_AxesRecovered, 'Amplitude') ;
            grid(app.Conv_AxesRecovered, 'off') ;
        end

        %% ============== CONVOLUTION CALLBACKS ==============

        function Conv_modeChanged(app)
            mode = app.Conv_ModeDropdown.Value ;
            if strcmp(mode, 'Convolution')
                app.Conv_InputDropdown.Items = ...
                    {'From Workspace', 'From Equation', 'From Tab 1 (RTD)', 'From File'} ;
            else
                % Tab 1 RTD not applicable for deconvolution
                if strcmp(app.Conv_InputDropdown.Value, 'From Tab 1 (RTD)')
                    app.Conv_InputDropdown.Value = 'From Workspace' ;
                end
                app.Conv_InputDropdown.Items = ...
                    {'From Workspace', 'From Equation', 'From File'} ;
            end
            app.Conv_updateVisibility() ;
        end

        function Conv_sourceChanged(app)
            app.Conv_updateVisibility() ;
        end

        function Conv_updateVisibility(app)
            source = app.Conv_InputDropdown.Value ;
            isConv = strcmp(app.Conv_ModeDropdown.Value, 'Convolution') ;
            isWS   = strcmp(source, 'From Workspace') ;
            isEq   = strcmp(source, 'From Equation') ;
            isTab1 = strcmp(source, 'From Tab 1 (RTD)') ;
            isFile = strcmp(source, 'From File') ;

            showWS = isWS || isFile ;

            % ---- Workspace / File variable fields (rows 5-7) ----
            if showWS
                app.Conv_tVarLabel.Visible = 'on' ;
                app.Conv_tVarField.Visible = 'on' ;
                app.Conv_CinVarLabel.Visible = 'on' ;
                app.Conv_CinVarField.Visible = 'on' ;
                if isConv
                    app.Conv_EVarLabel.Visible = 'on' ;
                    app.Conv_EVarField.Visible = 'on' ;
                    app.Conv_CoutVarLabel.Visible = 'off' ;
                    app.Conv_CoutVarField.Visible = 'off' ;
                else
                    app.Conv_EVarLabel.Visible = 'off' ;
                    app.Conv_EVarField.Visible = 'off' ;
                    app.Conv_CoutVarLabel.Visible = 'on' ;
                    app.Conv_CoutVarField.Visible = 'on' ;
                end
            else
                app.Conv_tVarLabel.Visible = 'off' ;
                app.Conv_tVarField.Visible = 'off' ;
                app.Conv_CinVarLabel.Visible = 'off' ;
                app.Conv_CinVarField.Visible = 'off' ;
                app.Conv_EVarLabel.Visible = 'off' ;
                app.Conv_EVarField.Visible = 'off' ;
                app.Conv_CoutVarLabel.Visible = 'off' ;
                app.Conv_CoutVarField.Visible = 'off' ;
            end

            % ---- Equation time params (rows 5-7, overlapping WS) ----
            if isEq
                app.Conv_TstartLabel.Visible = 'on' ;
                app.Conv_TstartField.Parent.Visible = 'on' ;
                app.Conv_TendLabel.Visible = 'on' ;
                app.Conv_TendField.Parent.Visible = 'on' ;
                app.Conv_NptsLabel.Visible = 'on' ;
                app.Conv_NptsField.Visible = 'on' ;
            else
                app.Conv_TstartLabel.Visible = 'off' ;
                app.Conv_TstartField.Parent.Visible = 'off' ;
                app.Conv_TendLabel.Visible = 'off' ;
                app.Conv_TendField.Parent.Visible = 'off' ;
                app.Conv_NptsLabel.Visible = 'off' ;
                app.Conv_NptsField.Visible = 'off' ;
            end

            % ---- C_in equation (rows 8-9, Equation and Tab1 modes) ----
            if isEq || isTab1
                app.Conv_CinEqLabel.Visible = 'on' ;
                app.Conv_CinEqField.Visible = 'on' ;
            else
                app.Conv_CinEqLabel.Visible = 'off' ;
                app.Conv_CinEqField.Visible = 'off' ;
            end

            % ---- E(t) equation (rows 10-11, Equation + Conv only) ----
            if isEq && isConv
                app.Conv_EEqLabel.Visible = 'on' ;
                app.Conv_EEqField.Visible = 'on' ;
            else
                app.Conv_EEqLabel.Visible = 'off' ;
                app.Conv_EEqField.Visible = 'off' ;
            end

            % ---- C_out equation (rows 10-11, Equation + Deconv only) ----
            if isEq && ~isConv
                app.Conv_CoutEqLabel.Visible = 'on' ;
                app.Conv_CoutEqField.Visible = 'on' ;
            else
                app.Conv_CoutEqLabel.Visible = 'off' ;
                app.Conv_CoutEqField.Visible = 'off' ;
            end

            % ---- RTD status (row 4, Tab1 only) ----
            if isTab1
                app.Conv_RTDStatusLabel.Visible = 'on' ;
                if ~isempty(app.rtd) && ~isempty(app.rtd.t)
                    app.Conv_RTDStatusLabel.Text = sprintf( ...
                        'RTD loaded: tau=%.2f s, %d pts', ...
                        app.rtd.tau, length(app.rtd.t)) ;
                    app.Conv_RTDStatusLabel.FontColor = [0 0.5 0] ;
                else
                    app.Conv_RTDStatusLabel.Text = ...
                        'RTD: not loaded (generate in Tab 1 first)' ;
                    app.Conv_RTDStatusLabel.FontColor = [0.8 0 0] ;
                end
            else
                app.Conv_RTDStatusLabel.Visible = 'off' ;
            end

            % ---- Import button (row 13, File mode only) ----
            if isFile
                app.Conv_ImportButton.Visible = 'on' ;
            else
                app.Conv_ImportButton.Visible = 'off' ;
            end

            % ---- nE (row 12, deconvolution only) ----
            if ~isConv
                app.Conv_nELabel.Visible = 'on' ;
                app.Conv_nEField.Visible = 'on' ;
            else
                app.Conv_nELabel.Visible = 'off' ;
                app.Conv_nEField.Visible = 'off' ;
            end

            app.Conv_ImportLabel.Text = '' ;
        end

        function Conv_importFromFile(app)
            % Import data from Excel/CSV/TSV file for convolution
            [file, filepath] = uigetfile( ...
                {'*.xlsx;*.xls;*.csv;*.tsv', 'Data Files' ; ...
                 '*.*', 'All Files'}, ...
                'Select Data File') ;

            if isequal(file, 0)
                return
            end

            try
                fullPath = fullfile(filepath, file) ;
                data = readmatrix(fullPath) ;
                data = data(~any(isnan(data(:,1:min(end,3))), 2), :) ;

                if size(data, 2) < 2
                    uialert(app.UIFigure, ...
                        'The file must have at least 2 columns (t, signal).', ...
                        'Import Error') ;
                    return
                end

                t_data = data(:, 1)' ;
                dt_vec = diff(t_data) ;
                if max(dt_vec) - min(dt_vec) > 0.01 * mean(dt_vec)
                    app.Conv_ImportLabel.Text = ...
                        'Warning: dt is not uniform. Results may be inaccurate.' ;
                    app.Conv_ImportLabel.FontColor = [0.8 0.5 0] ;
                end

                assignin('base', app.Conv_tVarField.Value, t_data) ;

                if size(data, 2) >= 2
                    assignin('base', app.Conv_CinVarField.Value, data(:, 2)') ;
                end

                if size(data, 2) >= 3
                    mode = app.Conv_ModeDropdown.Value ;
                    if strcmp(mode, 'Convolution')
                        assignin('base', app.Conv_EVarField.Value, data(:, 3)') ;
                    else
                        assignin('base', app.Conv_CoutVarField.Value, data(:, 3)') ;
                    end
                end

                app.Conv_ImportLabel.Text = sprintf( ...
                    'Loaded: %s (%d pts, %d cols)', ...
                    file, length(t_data), size(data, 2)) ;
                app.Conv_ImportLabel.FontColor = [0 0.5 0] ;

            catch ME
                uialert(app.UIFigure, ...
                    sprintf('Import error: %s', ME.message), ...
                    'Import Error') ;
            end
        end

        function Conv_compute(app)
            try
                app.updateStatus('Computing...') ;
                mode = app.Conv_ModeDropdown.Value ;
                source = app.Conv_InputDropdown.Value ;
                isConv = strcmp(mode, 'Convolution') ;

                % ---- Resolve signals based on source mode ----
                switch source
                    case {'From Workspace', 'From File'}
                        t_data = evalin('base', app.Conv_tVarField.Value) ;
                        C_in = evalin('base', app.Conv_CinVarField.Value) ;
                        if isConv
                            E = evalin('base', app.Conv_EVarField.Value) ;
                        else
                            C_out_data = evalin('base', app.Conv_CoutVarField.Value) ;
                        end

                    case 'From Equation'
                        t_data = linspace( ...
                            app.readInputField(app.Conv_TstartField), ...
                            app.readInputField(app.Conv_TendField), ...
                            round(app.Conv_NptsField.Value)) ;
                        t = t_data ; %#ok<NASGU>
                        C_in = eval(app.Conv_CinEqField.Value) ;
                        if isConv
                            E = eval(app.Conv_EEqField.Value) ;
                        else
                            C_out_data = eval(app.Conv_CoutEqField.Value) ;
                        end

                    case 'From Tab 1 (RTD)'
                        if isempty(app.rtd) || isempty(app.rtd.t)
                            error('No RTD available. Generate one in Tab 1 first.') ;
                        end
                        t_data = app.rtd.t ;
                        E = app.rtd.Et ;
                        t = t_data ; %#ok<NASGU>
                        C_in = eval(app.Conv_CinEqField.Value) ;
                end

                % Ensure row vectors
                t_data = t_data(:)' ;
                C_in = C_in(:)' ;

                if isConv
                    E = E(:)' ;

                    % ---- CONVOLUTION ----
                    [C_out, t_out] = ConvolutionTool.convolve( ...
                        t_data, E, t_data, C_in) ;

                    % Store for chaining and export
                    app.Conv_lastCout = C_out ;
                    app.Conv_lastTout = t_out ;
                    app.Conv_UsePrevButton.Enable = 'on' ;
                    assignin('base', 'conv_t_out', t_out) ;
                    assignin('base', 'conv_C_out', C_out) ;

                    timeDD = app.DisplayControls.Convolution.time ;
                    t_input_display = app.convertOutputVectorFromTime('time', t_data, timeDD) ;
                    t_out_display = app.convertOutputVectorFromTime('time', t_out, timeDD) ;
                    E_display = app.convertOutputVectorFromTime('timeInverse', E, timeDD) ;

                    % Plot inputs (dual y-axis)
                    cla(app.Conv_AxesInput) ;
                    yyaxis(app.Conv_AxesInput, 'left') ;
                    plot(app.Conv_AxesInput, t_input_display, C_in, 'b-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, 'C_{in}(t)') ;
                    yyaxis(app.Conv_AxesInput, 'right') ;
                    plot(app.Conv_AxesInput, t_input_display, E_display, 'r-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(timeDD))) ;
                    xlabel(app.Conv_AxesInput, app.axisLabelWithUnit('t', timeDD)) ;
                    title(app.Conv_AxesInput, 'Input: C_{in}(t) and E(t)') ;
                    legend(app.Conv_AxesInput, 'C_{in}', 'E(t)', 'Location', 'best') ;

                    % Plot result
                    cla(app.Conv_AxesResult) ;
                    plot(app.Conv_AxesResult, t_out_display, C_out, 'b-', 'LineWidth', 1.5) ;
                    xlabel(app.Conv_AxesResult, app.axisLabelWithUnit('t', timeDD)) ;
                    ylabel(app.Conv_AxesResult, 'C_{out}(t)') ;
                    title(app.Conv_AxesResult, 'Result: C_{out} = E \otimes C_{in}') ;

                    % Verification: overlay C_in and C_out
                    cla(app.Conv_AxesRecovered) ;
                    plot(app.Conv_AxesRecovered, t_input_display, C_in, 'b--', 'LineWidth', 1) ;
                    hold(app.Conv_AxesRecovered, 'on') ;
                    plot(app.Conv_AxesRecovered, t_out_display, C_out, 'r-', 'LineWidth', 1.5) ;
                    hold(app.Conv_AxesRecovered, 'off') ;
                    xlabel(app.Conv_AxesRecovered, app.axisLabelWithUnit('t', timeDD)) ;
                    title(app.Conv_AxesRecovered, 'Comparison: C_{in} vs C_{out}') ;
                    legend(app.Conv_AxesRecovered, 'C_{in}(t)', 'C_{out}(t)', ...
                        'Location', 'best') ;

                    app.Conv_ResultLabel.Text = sprintf( ...
                        'Convolution OK\nC_{out}: %d points, t=[%.2f, %.2f] %s\nSource: %s', ...
                        length(C_out), t_out_display(1), t_out_display(end), timeDD.Value, source) ;

                    app.DisplayCache.Convolution = struct( ...
                        'mode', 'Convolution', ...
                        'source', source, ...
                        't_input', t_data, ...
                        'C_in', C_in, ...
                        'E', E, ...
                        't_out', t_out, ...
                        'C_out', C_out) ;

                else
                    C_out_data = C_out_data(:)' ;

                    % ---- DECONVOLUTION ----
                    nE = app.Conv_nEField.Value ;
                    t_Cin = t_data ;
                    m = length(C_in) ;
                    v = length(C_out_data) ;
                    dt = (t_Cin(end) - t_Cin(1)) / (m - 1) ;
                    t_Cout = t_Cin(1) + (0:(v-1)) * dt ;

                    [E_rec, t_E, residual] = ConvolutionTool.deconvolve( ...
                        t_Cin, C_in, t_Cout, C_out_data, nE) ;

                    assignin('base', 'deconv_t_E', t_E) ;
                    assignin('base', 'deconv_E', E_rec) ;

                    timeDD = app.DisplayControls.Convolution.time ;
                    t_cin_display = app.convertOutputVectorFromTime('time', t_Cin, timeDD) ;
                    t_cout_display = app.convertOutputVectorFromTime('time', t_Cout, timeDD) ;
                    t_E_display = app.convertOutputVectorFromTime('time', t_E, timeDD) ;
                    E_display = app.convertOutputVectorFromTime('timeInverse', E_rec, timeDD) ;

                    % Plot inputs
                    cla(app.Conv_AxesInput) ;
                    yyaxis(app.Conv_AxesInput, 'left') ;
                    plot(app.Conv_AxesInput, t_cin_display, C_in, 'b-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, 'C_{in}(t)') ;
                    yyaxis(app.Conv_AxesInput, 'right') ;
                    plot(app.Conv_AxesInput, t_cout_display, C_out_data, 'r-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, 'C_{out}(t)') ;
                    xlabel(app.Conv_AxesInput, app.axisLabelWithUnit('t', timeDD)) ;
                    title(app.Conv_AxesInput, 'Input: C_{in}(t) and C_{out}(t)') ;
                    legend(app.Conv_AxesInput, 'C_{in}', 'C_{out}', 'Location', 'best') ;

                    % Plot recovered E(t)
                    cla(app.Conv_AxesResult) ;
                    plot(app.Conv_AxesResult, t_E_display, E_display, 'm-', 'LineWidth', 1.5) ;
                    xlabel(app.Conv_AxesResult, app.axisLabelWithUnit('t', timeDD)) ;
                    ylabel(app.Conv_AxesResult, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(timeDD))) ;
                    title(app.Conv_AxesResult, sprintf('Recovered E(t) | area=%.4f', ...
                        trapz(t_E, E_rec))) ;

                    % Verification: re-convolve and compare (T5e)
                    [C_out_check, t_check] = ConvolutionTool.convolve( ...
                        t_E, E_rec, t_Cin, C_in) ;
                    v_min = min(length(t_Cout), length(t_check)) ;
                    residual_norm = norm( ...
                        C_out_data(1:v_min) - C_out_check(1:v_min)) / v_min ;

                    cla(app.Conv_AxesRecovered) ;
                    plot(app.Conv_AxesRecovered, t_cout_display, C_out_data, ...
                        'b-', 'LineWidth', 1.5) ;
                    hold(app.Conv_AxesRecovered, 'on') ;
                    plot(app.Conv_AxesRecovered, app.convertOutputVectorFromTime('time', t_check, timeDD), C_out_check, ...
                        'r--', 'LineWidth', 1.5) ;
                    hold(app.Conv_AxesRecovered, 'off') ;
                    xlabel(app.Conv_AxesRecovered, app.axisLabelWithUnit('t', timeDD)) ;
                    title(app.Conv_AxesRecovered, sprintf( ...
                        'Verification (err=%.2e)', residual_norm)) ;
                    legend(app.Conv_AxesRecovered, 'C_{out} (data)', ...
                        'E_{rec} \otimes C_{in}', 'Location', 'best') ;

                    app.Conv_ResultLabel.Text = sprintf( ...
                        'Deconvolution OK\nResidual: %.4e\nReconv. error: %.4e\nE: %d pts, t=[%.2f, %.2f] %s', ...
                        residual, residual_norm, length(E_rec), t_E_display(1), t_E_display(end), timeDD.Value) ;

                    app.DisplayCache.Convolution = struct( ...
                        'mode', 'Deconvolution', ...
                        't_Cin', t_Cin, ...
                        'C_in', C_in, ...
                        't_Cout', t_Cout, ...
                        'C_out_data', C_out_data, ...
                        't_E', t_E, ...
                        'E_rec', E_rec, ...
                        't_check', t_check, ...
                        'C_out_check', C_out_check, ...
                        'residual', residual, ...
                        'residual_norm', residual_norm) ;
                end

                app.Conv_ExportButton.Enable = 'on' ;
                app.updateStatus(sprintf('%s completed', mode)) ;

            catch ME
                app.updateStatus('Error') ;
                uialert(app.UIFigure, ...
                    sprintf('Computation error: %s\nHint: check variables exist or equations use valid MATLAB syntax with t as the variable.', ...
                    ME.message), ...
                    'Convolution Error') ;
            end
        end

        function Conv_usePreviousResult(app)
            % Load the last convolution C_out as new C_in for chaining
            if isempty(app.Conv_lastCout) || isempty(app.Conv_lastTout)
                uialert(app.UIFigure, ...
                    'No previous result available. Run a convolution first.', ...
                    'No Data') ;
                return
            end

            % Store in workspace
            assignin('base', 'conv_prev_t', app.Conv_lastTout) ;
            assignin('base', 'conv_prev_Cin', app.Conv_lastCout) ;

            % Switch to Workspace mode and set variable names
            app.Conv_InputDropdown.Value = 'From Workspace' ;
            app.Conv_tVarField.Value = 'conv_prev_t' ;
            app.Conv_CinVarField.Value = 'conv_prev_Cin' ;
            app.Conv_updateVisibility() ;

            app.Conv_ImportLabel.Text = sprintf( ...
                'Previous C_out loaded as C_in (%d pts)', ...
                length(app.Conv_lastCout)) ;
            app.Conv_ImportLabel.FontColor = [0 0.5 0] ;
        end

        function Conv_refreshPlots(app)
            if ~isfield(app.DisplayCache, 'Convolution') || isempty(app.DisplayCache.Convolution)
                return
            end

            c = app.DisplayCache.Convolution ;
            timeDD = app.DisplayControls.Convolution.time ;

            switch c.mode
                case 'Convolution'
                    t_input_display = app.convertOutputVectorFromTime('time', c.t_input, timeDD) ;
                    t_out_display = app.convertOutputVectorFromTime('time', c.t_out, timeDD) ;
                    E_display = app.convertOutputVectorFromTime('timeInverse', c.E, timeDD) ;

                    cla(app.Conv_AxesInput) ;
                    yyaxis(app.Conv_AxesInput, 'left') ;
                    plot(app.Conv_AxesInput, t_input_display, c.C_in, 'b-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, 'C_{in}(t)') ;
                    yyaxis(app.Conv_AxesInput, 'right') ;
                    plot(app.Conv_AxesInput, t_input_display, E_display, 'r-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(timeDD))) ;
                    xlabel(app.Conv_AxesInput, app.axisLabelWithUnit('t', timeDD)) ;
                    title(app.Conv_AxesInput, 'Input: C_{in}(t) and E(t)') ;
                    legend(app.Conv_AxesInput, 'C_{in}', 'E(t)', 'Location', 'best') ;

                    cla(app.Conv_AxesResult) ;
                    plot(app.Conv_AxesResult, t_out_display, c.C_out, 'b-', 'LineWidth', 1.5) ;
                    xlabel(app.Conv_AxesResult, app.axisLabelWithUnit('t', timeDD)) ;
                    ylabel(app.Conv_AxesResult, 'C_{out}(t)') ;
                    title(app.Conv_AxesResult, 'Result: C_{out} = E \otimes C_{in}') ;

                    cla(app.Conv_AxesRecovered) ;
                    plot(app.Conv_AxesRecovered, t_input_display, c.C_in, 'b--', 'LineWidth', 1) ;
                    hold(app.Conv_AxesRecovered, 'on') ;
                    plot(app.Conv_AxesRecovered, t_out_display, c.C_out, 'r-', 'LineWidth', 1.5) ;
                    hold(app.Conv_AxesRecovered, 'off') ;
                    xlabel(app.Conv_AxesRecovered, app.axisLabelWithUnit('t', timeDD)) ;
                    title(app.Conv_AxesRecovered, 'Comparison: C_{in} vs C_{out}') ;
                    legend(app.Conv_AxesRecovered, 'C_{in}(t)', 'C_{out}(t)', ...
                        'Location', 'best') ;

                    app.Conv_ResultLabel.Text = sprintf( ...
                        'Convolution OK\nC_{out}: %d points, t=[%.2f, %.2f] %s\nSource: %s', ...
                        length(c.C_out), t_out_display(1), t_out_display(end), timeDD.Value, c.source) ;

                case 'Deconvolution'
                    t_cin_display = app.convertOutputVectorFromTime('time', c.t_Cin, timeDD) ;
                    t_cout_display = app.convertOutputVectorFromTime('time', c.t_Cout, timeDD) ;
                    t_E_display = app.convertOutputVectorFromTime('time', c.t_E, timeDD) ;
                    E_display = app.convertOutputVectorFromTime('timeInverse', c.E_rec, timeDD) ;
                    t_check_display = app.convertOutputVectorFromTime('time', c.t_check, timeDD) ;

                    cla(app.Conv_AxesInput) ;
                    yyaxis(app.Conv_AxesInput, 'left') ;
                    plot(app.Conv_AxesInput, t_cin_display, c.C_in, 'b-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, 'C_{in}(t)') ;
                    yyaxis(app.Conv_AxesInput, 'right') ;
                    plot(app.Conv_AxesInput, t_cout_display, c.C_out_data, 'r-', 'LineWidth', 1.5) ;
                    ylabel(app.Conv_AxesInput, 'C_{out}(t)') ;
                    xlabel(app.Conv_AxesInput, app.axisLabelWithUnit('t', timeDD)) ;
                    title(app.Conv_AxesInput, 'Input: C_{in}(t) and C_{out}(t)') ;
                    legend(app.Conv_AxesInput, 'C_{in}', 'C_{out}', 'Location', 'best') ;

                    cla(app.Conv_AxesResult) ;
                    plot(app.Conv_AxesResult, t_E_display, E_display, 'm-', 'LineWidth', 1.5) ;
                    xlabel(app.Conv_AxesResult, app.axisLabelWithUnit('t', timeDD)) ;
                    ylabel(app.Conv_AxesResult, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(timeDD))) ;
                    title(app.Conv_AxesResult, sprintf('Recovered E(t) | area=%.4f', ...
                        trapz(c.t_E, c.E_rec))) ;

                    cla(app.Conv_AxesRecovered) ;
                    plot(app.Conv_AxesRecovered, t_cout_display, c.C_out_data, 'b-', 'LineWidth', 1.5) ;
                    hold(app.Conv_AxesRecovered, 'on') ;
                    plot(app.Conv_AxesRecovered, t_check_display, c.C_out_check, 'r--', 'LineWidth', 1.5) ;
                    hold(app.Conv_AxesRecovered, 'off') ;
                    xlabel(app.Conv_AxesRecovered, app.axisLabelWithUnit('t', timeDD)) ;
                    title(app.Conv_AxesRecovered, sprintf('Verification (err=%.2e)', c.residual_norm)) ;
                    legend(app.Conv_AxesRecovered, 'C_{out} (data)', ...
                        'E_{rec} \otimes C_{in}', 'Location', 'best') ;

                    app.Conv_ResultLabel.Text = sprintf( ...
                        'Deconvolution OK\nResidual: %.4e\nReconv. error: %.4e\nE: %d pts, t=[%.2f, %.2f] %s', ...
                        c.residual, c.residual_norm, length(c.E_rec), ...
                        t_E_display(1), t_E_display(end), timeDD.Value) ;
            end
        end

        function Conv_export(app)
            varName = app.Conv_ExportNameField.Value ;
            if ~isvarname(varName)
                uialert(app.UIFigure, ...
                    sprintf('"%s" is not a valid variable name.', varName), ...
                    'Invalid Name') ;
                return
            end

            mode = app.Conv_ModeDropdown.Value ;
            if strcmp(mode, 'Convolution')
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
                sprintf('Result exported as "%s"', varName), ...
                'Export Successful', 'Icon', 'success') ;
        end

        %% ============== TAB 6: COMBINED MODELS ==============

        function createCombinedTab(app)

            app.CombTab = uitab(app.TabGroup, 'Title', 'Combined Models') ;

            mainGrid = uigridlayout(app.CombTab, [1 2]) ;
            mainGrid.ColumnWidth = {320, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'Combined Model Configuration') ;
            leftGrid = uigridlayout(leftPanel, [18 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 18) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: Model selection
            lbl = uilabel(leftGrid, 'Text', 'Model:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = 1 ;
            app.Comb_ModelDropdown = uidropdown(leftGrid, ...
                'Items', {'CSTR + Dead Vol.', ...
                          'CSTR + Bypass', ...
                          'CSTR + Bypass + Dead Vol.', ...
                          'CSTR + PFR in Series'}, ...
                'Value', 'CSTR + Dead Vol.', ...
                'ValueChangedFcn', @(~,~) app.Comb_modelChanged()) ;
            app.Comb_ModelDropdown.Layout.Row = 1 ;
            app.Comb_ModelDropdown.Layout.Column = 2 ;

            % Row 2: Model description (dynamic)
            app.Comb_ModelDescLabel = uilabel(leftGrid, ...
                'Text', 'V<sub>active</sub> = &alpha; &middot; V<sub>total</sub>. The rest is dead volume.', ...
                'Interpreter', 'html', ...
                'FontAngle', 'italic', 'FontColor', [0.4 0.4 0.4], ...
                'FontSize', 10, 'WordWrap', 'on') ;
            app.Comb_ModelDescLabel.Layout.Row = 2 ; app.Comb_ModelDescLabel.Layout.Column = [1 2] ;

            % Row 3: tau (with "From RTD" option)
            lbl = uilabel(leftGrid, 'Text', 'tau total:') ;
            lbl.Layout.Row = 3 ; lbl.Layout.Column = 1 ;
            [app.Comb_tauField, ~] = app.createNumericWithConv( ...
                leftGrid, 3, 2, 10, 'Time', 'Limits', [0.001 Inf]) ;

            % Row 4: Parameter 1
            app.Comb_Param1Label = uilabel(leftGrid, ...
                'Text', 'alpha (active vol. frac.):', ...
                'Interpreter', 'html', ...
                'Tooltip', 'Fraction of reactor volume that is well-mixed (0 < alpha <= 1). The rest is dead volume with no flow.') ;
            app.Comb_Param1Label.Layout.Row = 4 ; app.Comb_Param1Label.Layout.Column = 1 ;
            app.Comb_Param1Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.8, 'Limits', [0.01 1]) ;
            app.Comb_Param1Field.Layout.Row = 4 ; app.Comb_Param1Field.Layout.Column = 2 ;

            % Row 5: Parameter 2 (hidden for 1-param models)
            app.Comb_Param2Label = uilabel(leftGrid, ...
                'Text', 'beta (bypass frac.):', ...
                'Interpreter', 'html', ...
                'Tooltip', 'Fraction of flow that bypasses directly without reacting (0 <= beta < 1).') ;
            app.Comb_Param2Label.Layout.Row = 5 ; app.Comb_Param2Label.Layout.Column = 1 ;
            app.Comb_Param2Label.Visible = 'off' ;
            app.Comb_Param2Field = uieditfield(leftGrid, 'numeric', ...
                'Value', 0.1, 'Limits', [0 0.99]) ;
            app.Comb_Param2Field.Layout.Row = 5 ; app.Comb_Param2Field.Layout.Column = 2 ;
            app.Comb_Param2Field.Visible = 'off' ;

            % Row 6: Kinetics
            lbl = uilabel(leftGrid, 'Text', 'Kinetics:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 6 ; lbl.Layout.Column = 1 ;
            app.Comb_KineticsDropdown = uidropdown(leftGrid, ...
                'Items', {'1st Order (-rA = k*CA)', ...
                          '2nd Order (-rA = k*CA^2)'}, ...
                'Value', '1st Order (-rA = k*CA)', ...
                'ValueChangedFcn', @(~,~) app.Comb_kineticsChanged()) ;
            app.Comb_KineticsDropdown.Layout.Row = 6 ;
            app.Comb_KineticsDropdown.Layout.Column = 2 ;

            % Row 7: k
            app.Comb_kLabel = uilabel(leftGrid, 'Text', 'k:', 'Interpreter', 'html') ;
            app.Comb_kLabel.Layout.Row = 7 ; app.Comb_kLabel.Layout.Column = 1 ;
            [app.Comb_kField, ~] = app.createNumericWithConv( ...
                leftGrid, 7, 2, 0.1, 'k_1stOrder', ...
                'Limits', [0 Inf], ...
                'Tooltip', 'Rate constant. Units depend on order: 1/s (1st order), m³/(mol·s) (2nd order).') ;

            % Row 8: CA0 (2nd order only)
            app.Comb_CA0Label = uilabel(leftGrid, 'Text', 'C<sub>A0</sub>:', 'Interpreter', 'html') ;
            app.Comb_CA0Label.Layout.Row = 8 ; app.Comb_CA0Label.Layout.Column = 1 ;
            app.Comb_CA0Label.Visible = 'off' ;
            [app.Comb_CA0Field, tmpSGcomb] = app.createNumericWithConv( ...
                leftGrid, 8, 2, 1000, 'Concentration', ...
                'Limits', [0.001 Inf], ...
                'Tooltip', 'Initial concentration of limiting reactant in the feed.') ;
            tmpSGcomb.Visible = 'off' ;

            % Row 9: Compute button
            app.Comb_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Compute', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Comb_compute()) ;
            app.Comb_ComputeButton.Layout.Row = 9 ;
            app.Comb_ComputeButton.Layout.Column = [1 2] ;

            % Row 10: Display units
            unitsGrid = uigridlayout(leftGrid, [1 2], ...
                'ColumnWidth', {110, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 4) ;
            unitsGrid.Layout.Row = 10 ;
            unitsGrid.Layout.Column = [1 2] ;
            app.DisplayControls.Combined.time = app.createDisplayUnitControl( ...
                unitsGrid, 1, 1, 'Time base:', 'Time', 's', @(~,~) app.refreshDisplayUnits('Combined')) ;

            % Row 11: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 11 ; lbl.Layout.Column = [1 2] ;

            % Row 12: Model params info
            lbl = uilabel(leftGrid, 'Text', 'Parameters:') ;
            lbl.Layout.Row = 12 ; lbl.Layout.Column = 1 ;
            app.Comb_ResultParams = uilabel(leftGrid, 'Text', '--') ;
            app.Comb_ResultParams.Layout.Row = 12 ;
            app.Comb_ResultParams.Layout.Column = 2 ;

            % Row 13: X combined
            lbl = uilabel(leftGrid, 'Text', 'X<sub>model</sub>:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 13 ; lbl.Layout.Column = 1 ;
            app.Comb_ResultX = uilabel(leftGrid, 'Text', '--') ;
            app.Comb_ResultX.Layout.Row = 13 ;
            app.Comb_ResultX.Layout.Column = 2 ;
            app.Comb_ResultX.FontWeight = 'bold' ;

            % Row 14: X_CSTR
            lbl = uilabel(leftGrid, 'Text', 'X<sub>CSTR</sub> ideal:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 14 ; lbl.Layout.Column = 1 ;
            app.Comb_ResultXcstr = uilabel(leftGrid, 'Text', '--') ;
            app.Comb_ResultXcstr.Layout.Row = 14 ;
            app.Comb_ResultXcstr.Layout.Column = 2 ;

            % Row 15: X_PFR
            lbl = uilabel(leftGrid, 'Text', 'X<sub>PFR</sub> ideal:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 15 ; lbl.Layout.Column = 1 ;
            app.Comb_ResultXpfr = uilabel(leftGrid, 'Text', '--') ;
            app.Comb_ResultXpfr.Layout.Row = 15 ;
            app.Comb_ResultXpfr.Layout.Column = 2 ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Combined Model Results') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % E(t) plot
            app.Comb_AxesEt = uiaxes(plotGrid) ;
            app.Comb_AxesEt.Layout.Row = 1 ; app.Comb_AxesEt.Layout.Column = [1 2] ;
            title(app.Comb_AxesEt, 'E(t) - Combined Model') ;
            xlabel(app.Comb_AxesEt, 't [s]') ;
            ylabel(app.Comb_AxesEt, 'E(t) [1/s]') ;
            grid(app.Comb_AxesEt, 'off') ;

            % Comparison bar chart
            app.Comb_AxesComparison = uiaxes(plotGrid) ;
            app.Comb_AxesComparison.Layout.Row = 2 ; app.Comb_AxesComparison.Layout.Column = 1 ;
            title(app.Comb_AxesComparison, 'Conversion Comparison') ;
            ylabel(app.Comb_AxesComparison, 'Conversion X') ;
            grid(app.Comb_AxesComparison, 'off') ;

            % Sensitivity plot (new)
            app.Comb_AxesSensitivity = uiaxes(plotGrid) ;
            app.Comb_AxesSensitivity.Layout.Row = 2 ; app.Comb_AxesSensitivity.Layout.Column = 2 ;
            title(app.Comb_AxesSensitivity, 'Parameter Sensitivity') ;
            ylabel(app.Comb_AxesSensitivity, 'Conversion X') ;
            grid(app.Comb_AxesSensitivity, 'off') ;
        end

        %% ============== COMBINED CALLBACKS ==============

        function Comb_modelChanged(app)
            model = app.Comb_ModelDropdown.Value ;

            switch model
                case 'CSTR + Dead Vol.'
                    app.Comb_Param1Label.Text = 'alpha (active vol. frac.):' ;
                    app.Comb_Param1Label.Tooltip = 'Fraction of reactor volume that is well-mixed (0 < alpha <= 1). The rest is dead volume with no flow.' ;
                    app.Comb_Param1Field.Value = 0.8 ;
                    app.Comb_Param1Field.Limits = [0.01 1] ;
                    app.Comb_Param2Label.Visible = 'off' ;
                    app.Comb_Param2Field.Visible = 'off' ;
                    app.Comb_ModelDescLabel.Text = 'V<sub>active</sub> = &alpha; &middot; V<sub>total</sub>. The rest is dead volume.' ;

                case 'CSTR + Bypass'
                    app.Comb_Param1Label.Text = 'beta (bypass frac.):' ;
                    app.Comb_Param1Label.Tooltip = 'Fraction of flow that bypasses directly without reacting (0 <= beta < 1).' ;
                    app.Comb_Param1Field.Value = 0.1 ;
                    app.Comb_Param1Field.Limits = [0 0.99] ;
                    app.Comb_Param2Label.Visible = 'off' ;
                    app.Comb_Param2Field.Visible = 'off' ;
                    app.Comb_ModelDescLabel.Text = 'Q<sub>bypass</sub> = &beta; &middot; Q. The rest enters the CSTR.' ;

                case 'CSTR + Bypass + Dead Vol.'
                    app.Comb_Param1Label.Text = 'alpha (active vol. frac.):' ;
                    app.Comb_Param1Label.Tooltip = 'Active volume fraction (0 < alpha <= 1).' ;
                    app.Comb_Param1Field.Value = 0.8 ;
                    app.Comb_Param1Field.Limits = [0.01 1] ;
                    app.Comb_Param2Label.Text = 'beta (bypass frac.):' ;
                    app.Comb_Param2Label.Tooltip = 'Bypass flow fraction (0 <= beta < 1).' ;
                    app.Comb_Param2Label.Visible = 'on' ;
                    app.Comb_Param2Field.Visible = 'on' ;
                    app.Comb_Param2Field.Value = 0.1 ;
                    app.Comb_Param2Field.Limits = [0 0.99] ;
                    app.Comb_ModelDescLabel.Text = 'Combines bypass (beta) and dead volume (alpha).' ;

                case 'CSTR + PFR in Series'
                    app.Comb_Param1Label.Text = '&tau;<sub>CSTR</sub> [s]:' ;
                    app.Comb_Param1Label.Tooltip = 'Residence time in the CSTR.' ;
                    app.Comb_Param1Field.Value = 5 ;
                    app.Comb_Param1Field.Limits = [0.001 Inf] ;
                    app.Comb_Param2Label.Text = '&tau;<sub>PFR</sub> [s]:' ;
                    app.Comb_Param2Label.Tooltip = 'Residence time in the PFR.' ;
                    app.Comb_Param2Label.Visible = 'on' ;
                    app.Comb_Param2Field.Visible = 'on' ;
                    app.Comb_Param2Field.Value = 5 ;
                    app.Comb_Param2Field.Limits = [0.001 Inf] ;
                    app.Comb_ModelDescLabel.Text = 'PFR followed by CSTR in series. E(t) = shifted exponential.' ;
            end
        end

        function Comb_kineticsChanged(app)
            kinetics = app.Comb_KineticsDropdown.Value ;
            app.updateInputFieldCategory(app.Comb_kField, app.getKCategory(app.Comb_KineticsDropdown)) ;
            if contains(kinetics, '2nd')
                app.Comb_CA0Label.Visible = 'on' ;
                app.Comb_CA0Field.Parent.Visible = 'on' ;
                app.Comb_kLabel.Text = 'k:' ;
            else
                app.Comb_CA0Label.Visible = 'off' ;
                app.Comb_CA0Field.Parent.Visible = 'off' ;
                app.Comb_kLabel.Text = 'k:' ;
            end
        end

        function Comb_compute(app)

            try
                app.updateStatus('Computing combined model...') ;
                model = app.Comb_ModelDropdown.Value ;
                tau_val = app.readInputField(app.Comb_tauField) ;
                p1 = app.Comb_Param1Field.Value ;
                p2 = app.Comb_Param2Field.Value ;
                k_val = app.readInputField(app.Comb_kField) ;
                kinetics = app.Comb_KineticsDropdown.Value ;
                is2nd = contains(kinetics, '2nd') ;
                if is2nd
                    CA0_val = app.readInputField(app.Comb_CA0Field) ;
                end

                Da = k_val * tau_val ;

                % Generate RTD and compute conversion
                switch model
                    case 'CSTR + Dead Vol.'
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

                    case 'CSTR + Bypass + Dead Vol.'
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

                    case 'CSTR + PFR in Series'
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

                app.DisplayCache.Combined = struct( ...
                    'rtd_comb', rtd_comb, ...
                    'model', model, ...
                    'X_model', X_model, ...
                    'X_cstr', X_cstr, ...
                    'X_pfr', X_pfr, ...
                    'paramStr', paramStr) ;

                % Update plots
                app.Comb_updatePlots(rtd_comb, model, X_model, X_cstr, X_pfr, paramStr) ;

                app.updateStatus('Ready') ;

            catch ME
                app.updateStatus('Error') ;
                uialert(app.UIFigure, ...
                    sprintf('Combined model error: %s', ME.message), ...
                    'Computation Error') ;
            end
        end

        function Comb_updatePlots(app, rtd_comb, model, X_model, X_cstr, X_pfr, paramStr)

            % ---- Plot 1: E(t) ----
            cla(app.Comb_AxesEt) ;

            % Plot combined model E(t)
            timeDD = app.DisplayControls.Combined.time ;
            t_comb_display = app.convertOutputVectorFromTime('time', rtd_comb.t, timeDD) ;
            Et_comb_display = app.convertOutputVectorFromTime('timeInverse', rtd_comb.Et, timeDD) ;
            plot(app.Comb_AxesEt, t_comb_display, Et_comb_display, 'b-', 'LineWidth', 1.5) ;
            hold(app.Comb_AxesEt, 'on') ;

            % Overlay ideal CSTR for reference
            tau_val = app.readInputField(app.Comb_tauField) ;
            rtd_ideal = RTD.ideal_cstr(tau_val) ;
            plot(app.Comb_AxesEt, ...
                app.convertOutputVectorFromTime('time', rtd_ideal.t, timeDD), ...
                app.convertOutputVectorFromTime('timeInverse', rtd_ideal.Et, timeDD), ...
                'r--', 'LineWidth', 1) ;
            hold(app.Comb_AxesEt, 'off') ;

            title(app.Comb_AxesEt, sprintf('E(t): %s', model)) ;
            xlabel(app.Comb_AxesEt, app.axisLabelWithUnit('t', timeDD)) ;
            ylabel(app.Comb_AxesEt, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(timeDD))) ;
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
            title(app.Comb_AxesComparison, 'Conversion Comparison') ;
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
            k_val = app.readInputField(app.Comb_kField) ;
            kinetics = app.Comb_KineticsDropdown.Value ;
            is2nd = contains(kinetics, '2nd') ;
            if is2nd
                CA0_val = app.readInputField(app.Comb_CA0Field) ;
            end

            switch model
                case 'CSTR + Dead Vol.'
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

                case 'CSTR + Bypass + Dead Vol.'
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

                case 'CSTR + PFR in Series'
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
                    xlabel(app.Comb_AxesSensitivity, 'fraction tau_{CSTR} / tau_{total}') ;
            end

            ylabel(app.Comb_AxesSensitivity, 'Conversion X') ;
            title(app.Comb_AxesSensitivity, 'Parameter Sensitivity') ;
        end

        %% ============== TAB 7: OPTIMIZATION ==============
        function createOptimizationTab(app)

            app.OptTab = uitab(app.TabGroup, 'Title', 'Optimization') ;

            mainGrid = uigridlayout(app.OptTab, [1 2]) ;
            mainGrid.ColumnWidth = {320, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'RTD Model Fitting') ;
            leftGrid = uigridlayout(leftPanel, [22 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 22) ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: Section header - Data
            lbl = uilabel(leftGrid, 'Text', 'Experimental Data', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = [1 2] ;

            % Row 2: Data source
            lbl = uilabel(leftGrid, 'Text', 'Source:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 2 ; lbl.Layout.Column = 1 ;
            app.Opt_DataSourceDropdown = uidropdown(leftGrid, ...
                'Items', {'From Workspace', 'From File', 'From RTD (Tab 1)'}, ...
                'Value', 'From Workspace', ...
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
                'Text', 'Load Data', ...
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
            lbl = uilabel(leftGrid, 'Text', 'Experimental tau:') ;
            lbl.Layout.Row = 7 ; lbl.Layout.Column = 1 ;
            app.Opt_tauLabel = uilabel(leftGrid, 'Text', '-- s') ;
            app.Opt_tauLabel.Layout.Row = 7 ;
            app.Opt_tauLabel.Layout.Column = 2 ;
            app.Opt_tauLabel.FontWeight = 'bold' ;

            % Row 8: Section header - Models
            lbl = uilabel(leftGrid, 'Text', 'Models to Fit', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 8 ; lbl.Layout.Column = [1 2] ;

            % Row 9-14: Model checkboxes
            app.Opt_CheckTIS = uicheckbox(leftGrid, ...
                'Text', 'Tanks-in-Series (N)', 'Value', true) ;
            app.Opt_CheckTIS.Layout.Row = 9 ; app.Opt_CheckTIS.Layout.Column = [1 2] ;

            app.Opt_CheckDispOpen = uicheckbox(leftGrid, ...
                'Text', 'Dispersion open-open (Bo)', 'Value', true) ;
            app.Opt_CheckDispOpen.Layout.Row = 10 ; app.Opt_CheckDispOpen.Layout.Column = [1 2] ;

            app.Opt_CheckDispClosed = uicheckbox(leftGrid, ...
                'Text', 'Dispersion closed-closed (Bo)', 'Value', true) ;
            app.Opt_CheckDispClosed.Layout.Row = 11 ; app.Opt_CheckDispClosed.Layout.Column = [1 2] ;

            app.Opt_CheckDeadVol = uicheckbox(leftGrid, ...
                'Text', 'CSTR + Dead Volume (alpha)', 'Value', false) ;
            app.Opt_CheckDeadVol.Layout.Row = 12 ; app.Opt_CheckDeadVol.Layout.Column = [1 2] ;

            app.Opt_CheckBypass = uicheckbox(leftGrid, ...
                'Text', 'CSTR + Bypass (beta)', 'Value', false) ;
            app.Opt_CheckBypass.Layout.Row = 13 ; app.Opt_CheckBypass.Layout.Column = [1 2] ;

            app.Opt_CheckBypassDead = uicheckbox(leftGrid, ...
                'Text', 'CSTR + Bypass + Dead Vol. (alpha, beta)', 'Value', false) ;
            app.Opt_CheckBypassDead.Layout.Row = 14 ; app.Opt_CheckBypassDead.Layout.Column = [1 2] ;

            % Row 15: Fit button
            app.Opt_FitButton = uibutton(leftGrid, 'push', ...
                'Text', 'Fit Models', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Opt_fitModels()) ;
            app.Opt_FitButton.Layout.Row = 15 ;
            app.Opt_FitButton.Layout.Column = [1 2] ;

            % Row 16: Display units
            unitsGrid = uigridlayout(leftGrid, [1 2], ...
                'ColumnWidth', {110, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 4) ;
            unitsGrid.Layout.Row = 16 ;
            unitsGrid.Layout.Column = [1 2] ;
            app.DisplayControls.Optimization.time = app.createDisplayUnitControl( ...
                unitsGrid, 1, 1, 'Time base:', 'Time', 's', @(~,~) app.refreshDisplayUnits('Optimization')) ;

            % Row 17: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 17 ; lbl.Layout.Column = [1 2] ;

            % Row 18: Best model label
            app.Opt_ResultBestLabel = uilabel(leftGrid, 'Text', '--') ;
            app.Opt_ResultBestLabel.Layout.Row = 18 ;
            app.Opt_ResultBestLabel.Layout.Column = [1 2] ;
            app.Opt_ResultBestLabel.FontWeight = 'bold' ;
            app.Opt_ResultBestLabel.FontColor = [0 0.4 0.8] ;
            app.Opt_ResultBestLabel.WordWrap = 'on' ;

            % Row 19-23: Results table
            app.Opt_ResultTable = uitable(leftGrid, ...
                'ColumnName', {'Model', 'Params', 'SSE', 'R^2', 'AIC'}, ...
                'ColumnWidth', {95, 80, 55, 50, 50}, ...
                'RowName', {}, ...
                'ColumnEditable', false) ;
            app.Opt_ResultTable.Layout.Row = [19 23] ;
            app.Opt_ResultTable.Layout.Column = [1 2] ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Fitting Results') ;
            plotGrid = uigridlayout(rightPanel, [2 2]) ;
            plotGrid.RowHeight = {'1x', '1x'} ;
            plotGrid.ColumnWidth = {'1x', '1x'} ;

            % Data + fitted curves
            app.Opt_AxesDataFit = uiaxes(plotGrid) ;
            app.Opt_AxesDataFit.Layout.Row = 1 ;
            app.Opt_AxesDataFit.Layout.Column = [1 2] ;
            title(app.Opt_AxesDataFit, 'Experimental Data vs Fitted Models') ;
            xlabel(app.Opt_AxesDataFit, 't [s]') ;
            ylabel(app.Opt_AxesDataFit, 'E(t) [1/s]') ;
            grid(app.Opt_AxesDataFit, 'off') ;

            % Residuals
            app.Opt_AxesResiduals = uiaxes(plotGrid) ;
            app.Opt_AxesResiduals.Layout.Row = 2 ;
            app.Opt_AxesResiduals.Layout.Column = 1 ;
            title(app.Opt_AxesResiduals, 'Residuals') ;
            xlabel(app.Opt_AxesResiduals, 't [s]') ;
            ylabel(app.Opt_AxesResiduals, 'E_{exp} - E_{mod} [1/s]') ;
            grid(app.Opt_AxesResiduals, 'off') ;

            % R^2 comparison bar chart
            app.Opt_AxesComparison = uiaxes(plotGrid) ;
            app.Opt_AxesComparison.Layout.Row = 2 ;
            app.Opt_AxesComparison.Layout.Column = 2 ;
            title(app.Opt_AxesComparison, 'R² Comparison') ;
            ylabel(app.Opt_AxesComparison, 'R^2') ;
            grid(app.Opt_AxesComparison, 'off') ;
        end

        %% ============== OPTIMIZATION CALLBACKS ==============

        function Opt_sourceChanged(app)
            source = app.Opt_DataSourceDropdown.Value ;
            if strcmp(source, 'From RTD (Tab 1)')
                app.Opt_tVarLabel.Visible = 'off' ;
                app.Opt_tVarField.Visible = 'off' ;
                app.Opt_EtVarLabel.Visible = 'off' ;
                app.Opt_EtVarField.Visible = 'off' ;
                app.Opt_ImportButton.Text = 'Load from RTD (Tab 1)' ;
            else
                app.Opt_tVarLabel.Visible = 'on' ;
                app.Opt_tVarField.Visible = 'on' ;
                app.Opt_EtVarLabel.Visible = 'on' ;
                app.Opt_EtVarField.Visible = 'on' ;
                if strcmp(source, 'From File')
                    app.Opt_ImportButton.Text = 'Import File' ;
                else
                    app.Opt_ImportButton.Text = 'Load Data' ;
                end
            end
        end

        function Opt_loadData(app)
            try
                source = app.Opt_DataSourceDropdown.Value ;

                if strcmp(source, 'From RTD (Tab 1)')
                    % Load from current RTD object in Tab 1
                    if isempty(app.rtd) || isempty(app.rtd.t)
                        uialert(app.UIFigure, ...
                            'No RTD generated in Tab 1. Generate an RTD first.', ...
                            'No RTD Data') ;
                        return
                    end
                    app.opt_exp_t = app.rtd.t ;
                    app.opt_exp_Et = app.rtd.Et ;
                    app.Opt_ImportLabel.Text = sprintf( ...
                        'Loaded from Tab 1: %d points, source: %s', ...
                        length(app.opt_exp_t), app.rtd.source) ;

                elseif strcmp(source, 'From File')
                    % Import from file
                    [file, filepath] = uigetfile( ...
                        {'*.xlsx;*.xls;*.csv;*.tsv', 'Data Files' ; ...
                         '*.*', 'All Files'}, ...
                        'Select Experimental Data File') ;
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
                            'The file must have at least 2 columns (t and E(t)).', ...
                            'Import Error') ;
                        return
                    end

                    data = data(~any(isnan(data(:,1:2)), 2), :) ;
                    app.opt_exp_t = data(:, 1)' ;
                    app.opt_exp_Et = data(:, 2)' ;
                    app.Opt_ImportLabel.Text = sprintf( ...
                        'Loaded: %s (%d points)', file, length(app.opt_exp_t)) ;

                else
                    % From workspace
                    t_var = app.Opt_tVarField.Value ;
                    Et_var = app.Opt_EtVarField.Value ;
                    app.opt_exp_t = evalin('base', t_var) ;
                    app.opt_exp_Et = evalin('base', Et_var) ;
                    app.Opt_ImportLabel.Text = sprintf( ...
                        'Loaded from workspace: %d points', length(app.opt_exp_t)) ;
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
                app.DisplayCache.Optimization = [] ;

                app.Opt_tauLabel.Text = sprintf('%.4f %s', ...
                    app.convertOutputFromTime('time', app.opt_exp_tau, ...
                    app.DisplayControls.Optimization.time), ...
                    app.DisplayControls.Optimization.time.Value) ;
                app.Opt_ImportLabel.FontColor = [0 0.5 0] ;
                app.Opt_FitButton.Enable = 'on' ;

                % Preview plot of loaded data
                cla(app.Opt_AxesDataFit) ;
                plot(app.Opt_AxesDataFit, ...
                    app.convertOutputVectorFromTime('time', app.opt_exp_t, app.DisplayControls.Optimization.time), ...
                    app.convertOutputVectorFromTime('timeInverse', app.opt_exp_Et, app.DisplayControls.Optimization.time), ...
                    'ko', 'MarkerSize', 5, 'MarkerFaceColor', [0.3 0.3 0.3]) ;
                title(app.Opt_AxesDataFit, 'Loaded Experimental Data') ;
                xlabel(app.Opt_AxesDataFit, app.axisLabelWithUnit('t', app.DisplayControls.Optimization.time)) ;
                ylabel(app.Opt_AxesDataFit, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(app.DisplayControls.Optimization.time))) ;
                legend(app.Opt_AxesDataFit, 'Exp. Data', 'Location', 'best') ;

            catch ME
                app.Opt_ImportLabel.Text = ME.message ;
                app.Opt_ImportLabel.FontColor = [0.8 0 0] ;
                uialert(app.UIFigure, ...
                    sprintf('Load error: %s\nHint: check that the variables exist in the workspace.', ME.message), ...
                    'Load Error') ;
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
                app.updateStatus('Fitting models...') ;
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
                    r = struct('name', 'Disp. Open', 'params', Bo_opt, ...
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
                    r = struct('name', 'Disp. Closed', 'params', Bo_opt, ...
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
                        'Select at least one model to fit.', ...
                        'No Models') ;
                    return
                end

                % Display results
                app.Opt_displayResults(results) ;

                app.updateStatus('Ready') ;

            catch ME
                app.updateStatus('Error') ;
                uialert(app.UIFigure, ...
                    sprintf('Fitting error: %s', ME.message), ...
                    'Optimization Error') ;
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
            app.DisplayCache.Optimization = struct('results', results) ;

            % Find best model (highest R^2)
            R2_vals = [results.R2] ;
            [~, bestIdx] = max(R2_vals) ;
            app.Opt_ResultBestLabel.Text = sprintf( ...
                'Best model: %s (R^2 = %.4f)', ...
                results(bestIdx).name, results(bestIdx).R2) ;

            % ---- Colors for models ----
            colors = [0.0 0.45 0.74 ;   % blue
                      0.85 0.33 0.10 ;   % orange
                      0.47 0.67 0.19 ;   % green
                      0.49 0.18 0.56 ;   % purple
                      0.93 0.69 0.13 ;   % yellow
                      0.30 0.75 0.93] ;  % cyan

            % ---- Plot 1: Data vs fitted curves ----
            timeDD = app.DisplayControls.Optimization.time ;
            t_display = app.convertOutputVectorFromTime('time', t_exp, timeDD) ;
            Et_exp_display = app.convertOutputVectorFromTime('timeInverse', Et_exp_norm, timeDD) ;
            cla(app.Opt_AxesDataFit) ;
            plot(app.Opt_AxesDataFit, t_display, Et_exp_display, ...
                'ko', 'MarkerSize', 5, 'MarkerFaceColor', [0.3 0.3 0.3]) ;
            hold(app.Opt_AxesDataFit, 'on') ;
            legendEntries = {'Exp. Data'} ;
            for i = 1:nModels
                cidx = mod(i-1, size(colors,1)) + 1 ;
                plot(app.Opt_AxesDataFit, t_display, ...
                    app.convertOutputVectorFromTime('timeInverse', results(i).Et_fit, timeDD), ...
                    '-', 'LineWidth', 1.5, 'Color', colors(cidx,:)) ;
                legendEntries{end+1} = results(i).name ; %#ok<AGROW>
            end
            hold(app.Opt_AxesDataFit, 'off') ;
            title(app.Opt_AxesDataFit, 'Experimental Data vs Fitted Models') ;
            xlabel(app.Opt_AxesDataFit, app.axisLabelWithUnit('t', timeDD)) ;
            ylabel(app.Opt_AxesDataFit, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(timeDD))) ;
            legend(app.Opt_AxesDataFit, legendEntries, 'Location', 'best') ;

            % ---- Plot 2: Residuals ----
            cla(app.Opt_AxesResiduals) ;
            hold(app.Opt_AxesResiduals, 'on') ;
            for i = 1:nModels
                cidx = mod(i-1, size(colors,1)) + 1 ;
                residuals = Et_exp_norm - results(i).Et_fit ;
                plot(app.Opt_AxesResiduals, t_display, ...
                    app.convertOutputVectorFromTime('timeInverse', residuals, timeDD), ...
                    '-', 'LineWidth', 1, 'Color', colors(cidx,:)) ;
            end
            yline(app.Opt_AxesResiduals, 0, 'k--') ;
            hold(app.Opt_AxesResiduals, 'off') ;
            title(app.Opt_AxesResiduals, 'Residuals') ;
            xlabel(app.Opt_AxesResiduals, app.axisLabelWithUnit('t', timeDD)) ;
            ylabel(app.Opt_AxesResiduals, app.axisLabelWithUnitName('E_{exp} - E_{mod}', app.timeInverseUnitName(timeDD))) ;

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
            title(app.Opt_AxesComparison, 'R² Comparison') ;
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

        function Opt_refreshDisplayUnits(app)
            timeDD = app.DisplayControls.Optimization.time ;

            if ~isempty(app.opt_exp_tau)
                app.Opt_tauLabel.Text = sprintf('%.4f %s', ...
                    app.convertOutputFromTime('time', app.opt_exp_tau, timeDD), ...
                    timeDD.Value) ;
            end

            if isfield(app.DisplayCache, 'Optimization') && ~isempty(app.DisplayCache.Optimization) && ...
                    isfield(app.DisplayCache.Optimization, 'results')
                app.Opt_displayResults(app.DisplayCache.Optimization.results) ;
                return
            end

            if isempty(app.opt_exp_t) || isempty(app.opt_exp_Et)
                return
            end

            cla(app.Opt_AxesDataFit) ;
            plot(app.Opt_AxesDataFit, ...
                app.convertOutputVectorFromTime('time', app.opt_exp_t, timeDD), ...
                app.convertOutputVectorFromTime('timeInverse', app.opt_exp_Et, timeDD), ...
                'ko', 'MarkerSize', 5, 'MarkerFaceColor', [0.3 0.3 0.3]) ;
            title(app.Opt_AxesDataFit, 'Loaded Experimental Data') ;
            xlabel(app.Opt_AxesDataFit, app.axisLabelWithUnit('t', timeDD)) ;
            ylabel(app.Opt_AxesDataFit, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(timeDD))) ;
            legend(app.Opt_AxesDataFit, 'Exp. Data', 'Location', 'best') ;
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

        % -----------------------------------------------------------------
        % Help dialog
        % -----------------------------------------------------------------
        function showHelp(~)
            docsDir = fullfile(fileparts(mfilename('fullpath')), 'docs') ;
            guidePath = fullfile(docsDir, 'UserGuide.html') ;

            try
                if ~isfile(guidePath)
                    error('NonIdealReactorApp:MissingUserGuide', ...
                        'User guide HTML file not found.') ;
                end

                fig = uifigure('Name', 'Help - NonIdealReactorApp', ...
                    'Position', [120 60 980 740], ...
                    'Resize', 'on') ;
                uihtml(fig, ...
                    'HTMLSource', guidePath, ...
                    'Position', [10 10 960 720]) ;
            catch
                fallbackPath = fullfile(docsDir, 'UserGuide.md') ;
                helpText = { ...
                    'Formatted user guide not available.', ...
                    '', ...
                    ['Expected file: ' guidePath], ...
                    '', ...
                    ['Reference markdown: ' fallbackPath], ...
                    '', ...
                    'Opening the HTML guide in the system browser if possible.'} ;
                try
                    web(guidePath, '-browser') ;
                catch
                end

                fig = uifigure('Name', 'Help - NonIdealReactorApp', ...
                    'Position', [180 120 700 220], ...
                    'Resize', 'off') ;
                uitextarea(fig, ...
                    'Value', helpText, ...
                    'Position', [10 10 680 200], ...
                    'Editable', 'off', ...
                    'FontName', 'Consolas', ...
                    'FontSize', 12) ;
            end
            return
            helpText = { ...
                'NonIdealReactorApp — Quick Guide', ...
                '==================================', ...
                '', ...
                'Tab 1: RTD Analysis', ...
                '  Generate or import E(t) from analytical expression, experimental', ...
                '  data (pulse/step), Excel file or manual table.', ...
                '  Computes tau, variance, skewness, equivalent N and effective volume.', ...
                '', ...
                'Tab 2: Prediction Models', ...
                '  Predicts conversion with Segregation and Maximum Mixedness.', ...
                '  Requires RTD generated in Tab 1.', ...
                '  Supports 6 kinetics: 1st/2nd Order, Michaelis-Menten,', ...
                '  Reversible, Parallel and Custom Rate Law.', ...
                '', ...
                'Tab 3: Tanks-in-Series (TIS)', ...
                '  Model of N equal CSTRs in series.', ...
                '  Computes N from variance or accepts manual input.', ...
                '', ...
                'Tab 4: Dispersion Model', ...
                '  Reactor with axial dispersion (Bo = u*L/De).', ...
                '  Boundary conditions: open-open or closed-closed (Danckwerts).', ...
                '  Bo->0 = CSTR, Bo->inf = PFR.', ...
                '', ...
                'Tab 5: Convolution / Deconvolution', ...
                '  Given E(t) and C_in(t), computes C_out(t) (convolution).', ...
                '  Given C_in(t) and C_out(t), recovers E(t) (deconvolution).', ...
                '', ...
                'Tab 6: Combined Models', ...
                '  CSTR with dead volume, bypass, exchange,', ...
                '  PFR+CSTR in series. Sensitivity analysis included.', ...
                '', ...
                'Tab 7: Optimization', ...
                '  Fits experimental RTD data to 6 theoretical models.', ...
                '  Compares R^2, parameters and automatic ranking.', ...
                '', ...
                '==================================', ...
                'Internal units: SI (s, m^3, mol/m^3, m^3/s, Pa, K)', ...
                'Use the Unit Converter to convert.', ...
                '', ...
                'Author: Javier Berenguer Sabater (TFG, March 2026)', ...
                'Based on ReactorApp by Isabela Fons.'} ;

            fig = uifigure('Name', 'Help — NonIdealReactorApp', ...
                'Position', [200 100 520 560], ...
                'Resize', 'off') ;
            uitextarea(fig, ...
                'Value', helpText, ...
                'Position', [10 10 500 540], ...
                'Editable', 'off', ...
                'FontName', 'Consolas', ...
                'FontSize', 12) ;
        end

    end
end
