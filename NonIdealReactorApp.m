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
            uimenu(mHelp, 'Text', 'Technical Guide', ...
                'MenuSelectedFcn', @(~,~) app.showTechnicalGuide()) ;
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
            end
        end

        function htmlText = unitToHtml(~, unitText)
            htmlText = strrep(unitText, '^2', '<sup>2</sup>') ;
            htmlText = strrep(htmlText, '^3', '<sup>3</sup>') ;
        end

        %% ============== ABOUT DIALOG (T7) ==============

        function showAbout(app) 
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
            grid(app.RTD_AxesEt, 'on') ;

            % F(t) plot
            app.RTD_AxesFt = uiaxes(plotGrid) ;
            title(app.RTD_AxesFt, 'F(t)') ;
            xlabel(app.RTD_AxesFt, 't [s]') ;
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
            grid(app.Disp_AxesEt, 'on') ;

            % X vs Bo sweep
            app.Disp_AxesXvsBo = uiaxes(plotGrid) ;
            title(app.Disp_AxesXvsBo, 'X vs Bo') ;
            xlabel(app.Disp_AxesXvsBo, 'Bo [dispersion number]') ;
            ylabel(app.Disp_AxesXvsBo, 'X_A') ;
            grid(app.Disp_AxesXvsBo, 'on') ;

            % Comparison bar chart (spans 2 columns)
            app.Disp_AxesComparison = uiaxes(plotGrid) ;
            app.Disp_AxesComparison.Layout.Column = [1 2] ;
            title(app.Disp_AxesComparison, 'PFR vs Dispersion vs CSTR') ;
            ylabel(app.Disp_AxesComparison, 'Conversion X') ;
            grid(app.Disp_AxesComparison, 'on') ;
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

        function showTechnicalGuide(~)
            docsDir = fullfile(fileparts(mfilename('fullpath')), 'docs') ;
            guidePath = fullfile(docsDir, 'TechnicalChapter.html') ;

            try
                if ~isfile(guidePath)
                    error('NonIdealReactorApp:MissingTechnicalGuide', ...
                        'Technical guide HTML file not found.') ;
                end

                fig = uifigure('Name', 'Help - Technical Guide', ...
                    'Position', [120 60 980 740], ...
                    'Resize', 'on') ;
                uihtml(fig, ...
                    'HTMLSource', guidePath, ...
                    'Position', [10 10 960 720]) ;
            catch
                fallbackPath = fullfile(docsDir, 'TechnicalChapter.md') ;
                helpText = { ...
                    'Formatted technical guide not available.', ...
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

                fig = uifigure('Name', 'Help - Technical Guide', ...
                    'Position', [180 120 700 220], ...
                    'Resize', 'off') ;
                uitextarea(fig, ...
                    'Value', helpText, ...
                    'Position', [10 10 680 200], ...
                    'Editable', 'off', ...
                    'FontName', 'Consolas', ...
                    'FontSize', 12) ;
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

