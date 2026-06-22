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
        RTD_RSNameField
        RTD_RSDefineButton
        RTD_RSEditButton
        RTD_RSLoadButton
        RTD_RSStatusLabel
        RTD_RS
        RTD_StreamNameField
        RTD_StreamDefineButton
        RTD_StreamEditButton
        RTD_StreamLoadButton
        RTD_StreamStatusLabel
        RTD_feedStream
        RTD_FQueryPanel
        RTD_FQueryInputField
        RTD_FQueryValueLabel
        RTD_FQueryComplementLabel
        RTD_FQueryPointHandle = []
        RTD_FQueryVerticalHandle = []
        RTD_FQueryHorizontalHandle = []
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
        Pred_InputMethodDropdown
        Pred_RefreshButton
        Pred_RTDStatusLabel
        Pred_StreamNameField    % Name of feed Stream in workspace
        Pred_StreamDefineButton % Launches defineStreamApp
        Pred_StreamEditButton   % Launches defineStreamApp with loaded stream
        Pred_StreamLoadButton   % Loads Stream from workspace
        Pred_StreamStatusLabel  % Shows loaded Stream info
        Pred_feedStream         % Loaded feed Stream object
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
        Pred_C_exitPanel
        Pred_C_exitLabel
        Pred_C_exitTable        % UITable: outlet concentrations per component
        Pred_AxesXbatch
        Pred_AxesIntegrand
        Pred_SharedLegend

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
        TIS_StreamNameField     % Name of feed Stream in workspace
        TIS_StreamDefineButton  % Launches defineStreamApp
        TIS_StreamEditButton    % Launches defineStreamApp with loaded stream
        TIS_StreamLoadButton    % Loads Stream from workspace
        TIS_StreamStatusLabel   % Shows loaded Stream info
        TIS_feedStream          % Loaded feed Stream object
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
        TIS_C_exitLabel
        TIS_C_exitTable         % UITable: outlet concentrations per component
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
        Disp_StreamNameField    % Name of feed Stream in workspace
        Disp_StreamDefineButton % Launches defineStreamApp
        Disp_StreamEditButton   % Launches defineStreamApp with loaded stream
        Disp_StreamLoadButton   % Loads Stream from workspace
        Disp_StreamStatusLabel  % Shows loaded Stream info
        Disp_feedStream         % Loaded feed Stream object
        Disp_C_exitLabel
        Disp_C_exitTable        % UITable: outlet concentrations per component
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
            app.RTD_updateFQuery() ;
            app.Pred_inputMethodChanged() ;

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
                labelText, category, defaultUnit, callbackFcn, dropdownWidth)
            if nargin < 9 || isempty(dropdownWidth)
                dropdownWidth = 110 ;
            end
            subGrid = uigridlayout(parentGrid, [1 2], ...
                'ColumnWidth', {'fit', dropdownWidth}, ...
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

        function dropdown = createDisplayChoiceControl(~, parentGrid, row, col, ...
                labelText, items, defaultValue, callbackFcn, dropdownWidth)
            if nargin < 9 || isempty(dropdownWidth)
                dropdownWidth = 110 ;
            end
            subGrid = uigridlayout(parentGrid, [1 2], ...
                'ColumnWidth', {'fit', dropdownWidth}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 4) ;
            subGrid.Layout.Row = row ;
            subGrid.Layout.Column = col ;

            uilabel(subGrid, 'Text', labelText, 'FontSize', 11) ;
            dropdown = uidropdown(subGrid, ...
                'Items', items, ...
                'Value', defaultValue, ...
                'FontSize', 11, ...
                'ValueChangedFcn', callbackFcn) ;
            dropdown.Layout.Row = 1 ;
            dropdown.Layout.Column = 2 ;
        end

        function listbox = createDisplayMultiSelectControl(~, parentGrid, row, col, ...
                labelText, callbackFcn, listHeight)
            if nargin < 7 || isempty(listHeight)
                listHeight = 88 ;
            end
            subGrid = uigridlayout(parentGrid, [2 1], ...
                'RowHeight', {18, listHeight}, ...
                'ColumnWidth', {'1x'}, ...
                'Padding', [0 0 0 0], ...
                'RowSpacing', 4) ;
            subGrid.Layout.Row = row ;
            subGrid.Layout.Column = col ;

            uilabel(subGrid, 'Text', labelText, 'FontSize', 11, ...
                'FontWeight', 'bold') ;
            listbox = uilistbox(subGrid, ...
                'Multiselect', 'on', ...
                'FontSize', 11, ...
                'ValueChangedFcn', callbackFcn) ;
            listbox.Layout.Row = 2 ;
            listbox.Layout.Column = 1 ;
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

        function values = convertOutputConcentration(app, siValues, dropdown)
            values = app.convertOutputVector('Concentration', siValues, dropdown) ;
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
                    app.RTD_syncQueryFieldToDisplayUnit() ;
                    app.RTD_updateFQuery() ;
                case 'Prediction'
                    app.Pred_updatePlots() ;
                case 'TIS'
                    if isfield(app.DisplayCache, 'TIS') && ~isempty(app.DisplayCache.TIS)
                        c = app.DisplayCache.TIS ;
                        app.TIS_updatePlots(c.N_val, c.tau_val, c.RS, c.C0, ...
                            c.X_tis, c.X_cstr, c.X_pfr, ...
                            c.C_out_tis, c.C_out_cstr, c.C_out_pfr) ;
                    end
                case 'Dispersion'
                    if isfield(app.DisplayCache, 'Dispersion') && ~isempty(app.DisplayCache.Dispersion)
                        c = app.DisplayCache.Dispersion ;
                        app.Disp_updatePlots(c.Bo_val, c.tau_val, c.RS, c.C0, ...
                            c.X_disp, c.X_cstr, c.X_pfr, ...
                            c.C_out_disp, c.C_out_cstr, c.C_out_pfr, c.bcType) ;
                    end
            end
        end

        function labels = getComponentLabels(~, nComp)
            labels = arrayfun(@(i) sprintf('C%d', i), 1:nComp, 'UniformOutput', false) ;
        end

        function labels = getReactionComponentLabels(app, RS)
            labels = app.getComponentLabels(RS.nComponents) ;
            if ~isprop(RS, 'componentNames') || isempty(RS.componentNames)
                return
            end

            for i = 1:min(numel(RS.componentNames), RS.nComponents)
                nameValue = RS.componentNames{i} ;
                if isstring(nameValue)
                    nameValue = char(nameValue) ;
                end
                if ischar(nameValue)
                    nameValue = strtrim(nameValue) ;
                    if ~isempty(nameValue)
                        labels{i} = nameValue ;
                    end
                end
            end
        end

        function info = getPredictionReactantInfo(app, RS, C0)
            compLabels = app.getReactionComponentLabels(RS) ;
            reactantMask = any(RS.stochiometricMatrix < 0, 1) ;
            reactantIdx = find(reactantMask & (C0(:)' > 1e-12)) ;
            reactantLabels = compLabels(reactantIdx) ;
            info = struct( ...
                'componentLabels', {compLabels}, ...
                'reactantIndices', reactantIdx, ...
                'reactantLabels', {reactantLabels}) ;
        end

        function ensurePredictionReactantSelector(~, listbox, reactantInfo)
            if isempty(listbox) || ~isvalid(listbox)
                return
            end

            if isempty(reactantInfo.reactantIndices)
                listbox.Items = {'No reactants'} ;
                listbox.ItemsData = [] ;
                listbox.Value = {'No reactants'} ;
                listbox.Enable = 'off' ;
                return
            end

            currentValue = [] ;
            if isnumeric(listbox.Value)
                currentValue = reshape(listbox.Value, 1, []) ;
            end
            listbox.Enable = 'on' ;
            listbox.Items = reactantInfo.reactantLabels ;
            listbox.ItemsData = reactantInfo.reactantIndices ;
            selectedValues = intersect(reactantInfo.reactantIndices, currentValue, 'stable') ;
            if isempty(selectedValues)
                selectedValues = reactantInfo.reactantIndices ;
            end
            listbox.Value = selectedValues ;
        end

        function idx = getPredictionSelectedReactants(~, listbox, reactantInfo)
            if isempty(reactantInfo.reactantIndices) || isempty(listbox) || ~isvalid(listbox) || ...
                    strcmp(listbox.Enable, 'off')
                idx = [] ;
                return
            end

            if isnumeric(listbox.Value)
                idx = reshape(listbox.Value, 1, []) ;
            else
                idx = [] ;
            end
        end

        function info = getPredictionSpeciesInfo(app, RS)
            compLabels = app.getReactionComponentLabels(RS) ;
            speciesIdx = 1:RS.nComponents ;
            info = struct( ...
                'componentLabels', {compLabels}, ...
                'speciesIndices', speciesIdx) ;
        end

        function ensurePredictionSpeciesSelector(~, listbox, speciesInfo)
            if isempty(listbox) || ~isvalid(listbox)
                return
            end

            if isempty(speciesInfo.speciesIndices)
                listbox.Items = {'No species'} ;
                listbox.ItemsData = [] ;
                listbox.Value = {'No species'} ;
                listbox.Enable = 'off' ;
                return
            end

            currentValue = [] ;
            if isnumeric(listbox.Value)
                currentValue = reshape(listbox.Value, 1, []) ;
            end
            listbox.Enable = 'on' ;
            listbox.Items = speciesInfo.componentLabels ;
            listbox.ItemsData = speciesInfo.speciesIndices ;
            selectedValues = intersect(speciesInfo.speciesIndices, currentValue, 'stable') ;
            if isempty(selectedValues)
                selectedValues = speciesInfo.speciesIndices ;
            end
            listbox.Value = selectedValues ;
        end

        function idx = getPredictionSelectedSpecies(~, listbox, speciesInfo)
            if isempty(speciesInfo.speciesIndices) || isempty(listbox) || ~isvalid(listbox) || ...
                    strcmp(listbox.Enable, 'off')
                idx = [] ;
                return
            end

            if isnumeric(listbox.Value)
                idx = reshape(listbox.Value, 1, []) ;
            else
                idx = [] ;
            end
        end

        function [labels, colors] = getPredictionModelLegendSpec(~)
            labels = {'Segregation', 'Max Mixedness', 'Ideal CSTR', 'Ideal PFR'} ;
            colors = [ ...
                0.18 0.45 0.78
                0.85 0.33 0.10
                0.29 0.64 0.25
                0.49 0.18 0.56] ;
        end

        function applyPredictionBarStyles(app, barHandles)
            [labels, colors] = app.getPredictionModelLegendSpec() ;
            for i = 1:min(numel(barHandles), size(colors, 1))
                barHandles(i).FaceColor = colors(i, :) ;
                barHandles(i).DisplayName = labels{i} ;
            end
        end

        function legendHandles = createPredictionLegendPlaceholders(app, ax)
            [labels, colors] = app.getPredictionModelLegendSpec() ;
            legendHandles = gobjects(1, numel(labels)) ;
            hold(ax, 'on') ;
            for i = 1:numel(labels)
                legendHandles(i) = plot(ax, nan, nan, 's', ...
                    'MarkerSize', 8, ...
                    'MarkerFaceColor', colors(i, :), ...
                    'MarkerEdgeColor', colors(i, :), ...
                    'LineStyle', 'none', ...
                    'DisplayName', labels{i}) ;
            end
            hold(ax, 'off') ;
        end

        function updatePredictionSharedLegend(app, legendHandles)
            if ~isempty(app.Pred_SharedLegend) && isvalid(app.Pred_SharedLegend)
                delete(app.Pred_SharedLegend) ;
            end
            [labels, ~] = app.getPredictionModelLegendSpec() ;
            app.Pred_SharedLegend = legend(app.Pred_AxesXbatch, legendHandles, labels, ...
                'Orientation', 'horizontal', ...
                'Location', 'southoutside') ;
            app.Pred_SharedLegend.Layout.Tile = 'south' ;
        end

        function X = computeSpeciesConversion(~, C0, C_exit, indices)
            X = zeros(1, numel(indices)) ;
            for k = 1:numel(indices)
                i = indices(k) ;
                denom = max(C0(i), 1e-12) ;
                X(k) = (C0(i) - C_exit(i)) / denom ;
            end
            X = max(min(X, 1), 0) ;
        end

        function roles = classifySpeciesRoles(~, RS)
            nComp = RS.nComponents ;
            roles = cell(1, nComp) ;
            for i = 1:nComp
                hasNeg = any(RS.stochiometricMatrix(:, i) < 0) ;
                hasPos = any(RS.stochiometricMatrix(:, i) > 0) ;
                if hasNeg && ~hasPos
                    roles{i} = 'Reactant' ;
                elseif ~hasNeg && hasPos
                    roles{i} = 'Product' ;
                elseif hasNeg && hasPos
                    roles{i} = 'Intermediate' ;
                else
                    roles{i} = 'Inert' ;
                end
            end
        end

        function updatePredictionSummaryTable(app, ...
                compLabels, roles, C0, ...
                C_seg, C_mm, C_cstr, C_pfr, ...
                reactantIndices, X_seg, X_mm, X_cstr, X_pfr, ...
                selectedIdx, concDropdown)

            nComp = numel(compLabels) ;
            summaryRows = cell(nComp, 11) ;
            concMatrix = [C0(:), C_seg(:), C_mm(:), C_cstr(:), C_pfr(:)] ;
            concDisplay = reshape(app.convertOutputConcentration(concMatrix(:)', concDropdown), size(concMatrix)) ;

            reactantPosMap = containers.Map('KeyType', 'double', 'ValueType', 'double') ;
            for k = 1:numel(reactantIndices)
                reactantPosMap(reactantIndices(k)) = k ;
            end

            for i = 1:nComp
                summaryRows{i, 1} = compLabels{i} ;
                summaryRows{i, 2} = roles{i} ;
                for j = 1:5
                    summaryRows{i, j + 2} = sprintf('%.4g', concDisplay(i, j)) ;
                end

                if isKey(reactantPosMap, i) && strcmp(roles{i}, 'Reactant')
                    pos = reactantPosMap(i) ;
                    summaryRows{i, 8} = sprintf('%.4f', X_seg(pos)) ;
                    summaryRows{i, 9} = sprintf('%.4f', X_mm(pos)) ;
                    summaryRows{i, 10} = sprintf('%.4f', X_cstr(pos)) ;
                    summaryRows{i, 11} = sprintf('%.4f', X_pfr(pos)) ;
                else
                    summaryRows{i, 8} = '--' ;
                    summaryRows{i, 9} = '--' ;
                    summaryRows{i, 10} = '--' ;
                    summaryRows{i, 11} = '--' ;
                end
            end

            if isempty(selectedIdx) || isequal(selectedIdx, reactantIndices)
                rolePriority = zeros(1, nComp) ;
                for i = 1:nComp
                    switch roles{i}
                        case 'Reactant'
                            rolePriority(i) = 1 ;
                        case 'Intermediate'
                            rolePriority(i) = 2 ;
                        case 'Product'
                            rolePriority(i) = 3 ;
                        otherwise
                            rolePriority(i) = 4 ;
                    end
                end
                [~, rowOrder] = sortrows([rolePriority(:), (1:nComp)']) ;
                rowOrder = rowOrder(:)' ;
            else
                remaining = setdiff(1:nComp, selectedIdx, 'stable') ;
                rowOrder = [selectedIdx, remaining] ;
            end

            app.Pred_C_exitTable.ColumnName = { ...
                'Component', 'Role', 'C0', 'Seg. C_exit', 'MM C_exit', ...
                'CSTR C_exit', 'PFR C_exit', ...
                'X_seg', 'X_MM', 'X_CSTR', 'X_PFR'} ;
            app.Pred_C_exitTable.ColumnWidth = {100, 90, 80, 85, 85, 95, 95, 75, 75, 85, 85} ;
            app.Pred_C_exitTable.Data = summaryRows(rowOrder, :) ;
        end

        function ensureComponentSelectorItems(app, dropdown, nComp)
            if isempty(dropdown) || ~isvalid(dropdown)
                return
            end
            items = [{'All'}, app.getComponentLabels(nComp)] ;
            currentValue = dropdown.Value ;
            dropdown.Items = items ;
            if any(strcmp(items, currentValue))
                dropdown.Value = currentValue ;
            else
                dropdown.Value = 'All' ;
            end
        end

        function idx = getSelectedComponentIndices(~, dropdown, nComp)
            if isempty(dropdown) || ~isvalid(dropdown) || strcmp(dropdown.Value, 'All')
                idx = 1:nComp ;
                return
            end

            token = regexp(dropdown.Value, '^C(\d+)$', 'tokens', 'once') ;
            if isempty(token)
                idx = 1:nComp ;
                return
            end

            idx = str2double(token{1}) ;
            if ~isfinite(idx) || idx < 1 || idx > nComp
                idx = 1:nComp ;
            end
        end

        function unitName = concentrationUnitName(~, dropdown)
            if isempty(dropdown) || ~isvalid(dropdown)
                unitName = 'mol/m^3' ;
            else
                unitName = dropdown.Value ;
            end
        end

        function setTooltip(~, tooltipText, varargin)
            for k = 1:numel(varargin)
                h = varargin{k} ;
                if ~isempty(h) && isvalid(h)
                    h.Tooltip = tooltipText ;
                end
            end
        end

        function updateConcentrationHeader(app, labelHandle, concDropdown)
            if isempty(labelHandle) || ~isvalid(labelHandle)
                return
            end
            labelHandle.Text = sprintf('Outlet Conc. at Exit [%s]:', ...
                app.concentrationUnitName(concDropdown)) ;
        end

        function updateConcentrationTable(app, tableHandle, seriesData, seriesNames, concDropdown)
            nComp = size(seriesData, 1) ;
            compLabels = app.getComponentLabels(nComp) ;
            app.updateNamedConcentrationTable(tableHandle, compLabels, seriesData, ...
                seriesNames, concDropdown) ;
        end

        function updateNamedConcentrationTable(app, tableHandle, rowLabels, seriesData, seriesNames, concDropdown)
            concDisplay = reshape(app.convertOutputConcentration(seriesData(:)', concDropdown), size(seriesData)) ;

            tableData = cell(numel(rowLabels), 1 + size(concDisplay, 2)) ;
            for i = 1:numel(rowLabels)
                tableData{i, 1} = rowLabels{i} ;
                for j = 1:size(concDisplay, 2)
                    tableData{i, j + 1} = sprintf('%.4g', concDisplay(i, j)) ;
                end
            end

            tableHandle.ColumnName = [{'Comp.'}, seriesNames] ;
            tableHandle.Data = tableData ;
        end

        function htmlText = unitToHtml(~, unitText)
            htmlText = strrep(unitText, '^2', '<sup>2</sup>') ;
            htmlText = strrep(htmlText, '^3', '<sup>3</sup>') ;
        end

        %% ============== ABOUT DIALOG (T7) ==============

        function showAbout(~) 
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
            mainGrid.ColumnWidth = {350, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'RTD Configuration') ;
            leftGrid = uigridlayout(leftPanel, [24 2]) ;
            leftGrid.RowHeight = repmat({28}, 1, 24) ;
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
                'ColumnWidth', {'1.15x', '0.9x'}, ...
                'RowHeight', {28, 28}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 6) ;
            unitsGrid.Layout.Row = 12 ;
            unitsGrid.Layout.Column = [1 2] ;
            app.DisplayControls.RTD.time = app.createDisplayUnitControl( ...
                unitsGrid, 1, 1, 'Time base:', 'Time', 's', @(~,~) app.refreshDisplayUnits('RTD'), 92) ;
            app.DisplayControls.RTD.volume = app.createDisplayUnitControl( ...
                unitsGrid, 1, 2, 'Volume:', 'Volume', 'm^3', @(~,~) app.refreshDisplayUnits('RTD'), 78) ;

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
            app.setTooltip('Mean residence time of the RTD. It is the average time spent by fluid elements inside the reactor.', ...
                app.RTD_ResultTauLabel, app.RTD_ResultTau) ;

            % Row 15: sigma^2
            app.RTD_ResultSigma2Label = uilabel(leftGrid, ...
                'Text', '&sigma;&sup2; [s&sup2;]:', 'Interpreter', 'html') ;
            app.RTD_ResultSigma2Label.Layout.Row = 15 ; app.RTD_ResultSigma2Label.Layout.Column = 1 ;
            app.RTD_ResultSigma2 = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultSigma2.Layout.Row = 15 ;
            app.RTD_ResultSigma2.Layout.Column = 2 ;
            app.setTooltip('Variance of the RTD. Higher values indicate broader residence-time spreading and stronger deviation from ideal plug flow.', ...
                app.RTD_ResultSigma2Label, app.RTD_ResultSigma2) ;

            % Row 16: sigma^2_theta
            lbl = uilabel(leftGrid, 'Text', '&sigma;&sup2;<sub>&theta;</sub>:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 16 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultSigma2Theta = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultSigma2Theta.Layout.Row = 16 ;
            app.RTD_ResultSigma2Theta.Layout.Column = 2 ;
            app.setTooltip('Dimensionless RTD variance, sigma_theta^2 = sigma^2 / tau_m^2. Useful to compare RTDs independently of time scale.', ...
                lbl, app.RTD_ResultSigma2Theta) ;

            % Row 17: s^3
            lbl = uilabel(leftGrid, 'Text', 's&sup3; [skewness]:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 17 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultS3 = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultS3.Layout.Row = 17 ;
            app.RTD_ResultS3.Layout.Column = 2 ;
            app.setTooltip('Skewness of the RTD. It indicates whether the residence-time distribution is symmetric or biased toward early or late times.', ...
                lbl, app.RTD_ResultS3) ;

            % Row 18: N_est
            lbl = uilabel(leftGrid, 'Text', 'N<sub>est</sub> [= &tau;&sup2;/&sigma;&sup2;]:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 18 ; lbl.Layout.Column = 1 ;
            app.RTD_ResultN = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultN.Layout.Row = 18 ;
            app.RTD_ResultN.Layout.Column = 2 ;
            app.setTooltip('Equivalent number of tanks in series estimated from the RTD variance. Higher N means behavior closer to plug flow.', ...
                lbl, app.RTD_ResultN) ;

            % Row 19: V_eff
            app.RTD_ResultVeffLabel = uilabel(leftGrid, ...
                'Text', 'V<sub>eff</sub> [m&sup3;]:', 'Interpreter', 'html') ;
            app.RTD_ResultVeffLabel.Layout.Row = 19 ; app.RTD_ResultVeffLabel.Layout.Column = 1 ;
            app.RTD_ResultVeff = uilabel(leftGrid, 'Text', '--') ;
            app.RTD_ResultVeff.Layout.Row = 19 ;
            app.RTD_ResultVeff.Layout.Column = 2 ;
            app.setTooltip('Effective reactor volume inferred from V_eff = tau_m * Q. It represents the volume effectively used by the flow.', ...
                app.RTD_ResultVeffLabel, app.RTD_ResultVeff) ;

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
            app.RTD_AxesEt.Layout.Row = 1 ;
            app.RTD_AxesEt.Layout.Column = 1 ;
            title(app.RTD_AxesEt, 'E(t)') ;
            xlabel(app.RTD_AxesEt, 't [s]') ;
            ylabel(app.RTD_AxesEt, 'E(t) [1/s]') ;
            grid(app.RTD_AxesEt, 'on') ;

            % F(t) plot
            app.RTD_AxesFt = uiaxes(plotGrid) ;
            app.RTD_AxesFt.Layout.Row = 1 ;
            app.RTD_AxesFt.Layout.Column = 2 ;
            title(app.RTD_AxesFt, 'F(t)') ;
            xlabel(app.RTD_AxesFt, 't [s]') ;
            ylabel(app.RTD_AxesFt, 'F(t)') ;
            grid(app.RTD_AxesFt, 'on') ;

            % E(theta) plot
            app.RTD_AxesEtheta = uiaxes(plotGrid) ;
            app.RTD_AxesEtheta.Layout.Row = 2 ;
            app.RTD_AxesEtheta.Layout.Column = 1 ;
            title(app.RTD_AxesEtheta, 'E(\Theta)') ;
            xlabel(app.RTD_AxesEtheta, '\Theta = t/\tau') ;
            ylabel(app.RTD_AxesEtheta, 'E(\Theta)') ;
            grid(app.RTD_AxesEtheta, 'on') ;

            % RTD utilities panel
            app.RTD_FQueryPanel = uipanel(plotGrid, 'Title', 'RTD Utilities') ;
            app.RTD_FQueryPanel.Layout.Row = 2 ;
            app.RTD_FQueryPanel.Layout.Column = 2 ;
            queryGrid = uigridlayout(app.RTD_FQueryPanel, [12 2]) ;
            queryGrid.RowHeight = {22, 28, 24, 22, 28, 28, 38, 22, 28, 28, 38, '1x'} ;
            queryGrid.ColumnWidth = {'1x', '1x'} ;
            queryGrid.Padding = [8 8 8 8] ;
            queryGrid.RowSpacing = 4 ;
            queryGrid.ColumnSpacing = 6 ;

            lbl = uilabel(queryGrid, 'Text', 'F(t) Query', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 1 ;
            lbl.Layout.Column = [1 2] ;
            lbl.Tooltip = ['Interpret F(t) as in exercise 51(c): x is elapsed time, ' ...
                'y = F(t) is the fraction of effluent that has already left, ' ...
                'and 1-y is the fraction that still remains inside the reactor.'] ;

            lbl = uilabel(queryGrid, 'Text', 'x = elapsed time:') ;
            lbl.Tooltip = 'Elapsed time since the tracer entered the reactor, expressed in the selected display time unit.' ;
            app.RTD_FQueryInputField = uieditfield(queryGrid, 'text', ...
                'Value', '0', ...
                'Tooltip', 'Elapsed time x in the selected RTD display time unit.', ...
                'ValueChangedFcn', @(~,~) app.RTD_queryValueChanged()) ;
            app.RTD_FQueryInputField.Layout.Row = 2 ;
            app.RTD_FQueryInputField.Layout.Column = 2 ;
            app.setTooltip('Elapsed time x in the selected RTD display time unit.', ...
                lbl, app.RTD_FQueryInputField) ;

            lbl = uilabel(queryGrid, 'Text', 'y = F(t):') ;
            app.RTD_FQueryValueLabel = uilabel(queryGrid, 'Text', '--') ;
            app.RTD_FQueryValueLabel.Layout.Row = 3 ;
            app.RTD_FQueryValueLabel.Layout.Column = 2 ;
            app.setTooltip(['Fraction of the effluent that has already left the reactor ' ...
                'by elapsed time x.'], lbl, app.RTD_FQueryValueLabel) ;

            lbl = uilabel(queryGrid, 'Text', '1 - y:') ;
            app.RTD_FQueryComplementLabel = uilabel(queryGrid, 'Text', '--') ;
            app.RTD_FQueryComplementLabel.Layout.Row = 4 ;
            app.RTD_FQueryComplementLabel.Layout.Column = 2 ;
            app.setTooltip(['Fraction of the effluent that still remains inside the reactor ' ...
                'at elapsed time x.'], lbl, app.RTD_FQueryComplementLabel) ;

            lbl = uilabel(queryGrid, 'Text', 'Reaction System', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 5 ;
            lbl.Layout.Column = [1 2] ;

            app.RTD_RSDefineButton = uibutton(queryGrid, 'push', ...
                'Text', 'New RS', ...
                'BackgroundColor', [0.85 0.90 1.0], ...
                'Tooltip', 'Create a new Reaction System from scratch', ...
                'ButtonPushedFcn', @(~,~) defineReactionSysApp()) ;
            app.RTD_RSDefineButton.Layout.Row = 6 ;
            app.RTD_RSDefineButton.Layout.Column = 1 ;
            app.RTD_RSEditButton = uibutton(queryGrid, 'push', ...
                'Text', 'Edit RS', ...
                'BackgroundColor', [1.0 0.95 0.80], ...
                'Tooltip', 'Edit the currently loaded Reaction System', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.RTD_editRS()) ;
            app.RTD_RSEditButton.Layout.Row = 6 ;
            app.RTD_RSEditButton.Layout.Column = 2 ;
            app.RTD_RSNameField = uieditfield(queryGrid, 'text', ...
                'Value', 'RS', ...
                'Tooltip', 'Name of the ReactionSys variable in the MATLAB workspace') ;
            app.RTD_RSNameField.Layout.Row = 7 ;
            app.RTD_RSNameField.Layout.Column = 1 ;
            app.RTD_RSLoadButton = uibutton(queryGrid, 'push', ...
                'Text', 'Load', ...
                'BackgroundColor', [0.85 0.95 0.85], ...
                'Tooltip', 'Load the ReactionSys object from the workspace', ...
                'ButtonPushedFcn', @(~,~) app.RTD_loadRS()) ;
            app.RTD_RSLoadButton.Layout.Row = 7 ;
            app.RTD_RSLoadButton.Layout.Column = 2 ;
            app.RTD_RSStatusLabel = uilabel(queryGrid, ...
                'Text', 'No Reaction System loaded', ...
                'FontColor', [0.6 0 0], ...
                'WordWrap', 'on') ;
            app.RTD_RSStatusLabel.Layout.Row = 8 ;
            app.RTD_RSStatusLabel.Layout.Column = [1 2] ;

            lbl = uilabel(queryGrid, 'Text', 'Feed Stream', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 9 ;
            lbl.Layout.Column = [1 2] ;

            app.RTD_StreamDefineButton = uibutton(queryGrid, 'push', ...
                'Text', 'New Stream', ...
                'BackgroundColor', [0.85 0.90 1.0], ...
                'Tooltip', 'Create a new feed stream with defineStreamApp', ...
                'ButtonPushedFcn', @(~,~) defineStreamApp()) ;
            app.RTD_StreamDefineButton.Layout.Row = 10 ;
            app.RTD_StreamDefineButton.Layout.Column = 1 ;
            app.RTD_StreamEditButton = uibutton(queryGrid, 'push', ...
                'Text', 'Edit Stream', ...
                'BackgroundColor', [1.0 0.95 0.80], ...
                'Tooltip', 'Edit the currently loaded feed stream', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.RTD_editStream()) ;
            app.RTD_StreamEditButton.Layout.Row = 10 ;
            app.RTD_StreamEditButton.Layout.Column = 2 ;
            app.RTD_StreamNameField = uieditfield(queryGrid, 'text', ...
                'Value', 'feed', ...
                'Tooltip', 'Name of the feed Stream variable in the MATLAB workspace') ;
            app.RTD_StreamNameField.Layout.Row = 11 ;
            app.RTD_StreamNameField.Layout.Column = 1 ;
            app.RTD_StreamLoadButton = uibutton(queryGrid, 'push', ...
                'Text', 'Load', ...
                'BackgroundColor', [0.85 0.95 0.85], ...
                'Tooltip', 'Load the feed Stream object from the workspace', ...
                'ButtonPushedFcn', @(~,~) app.RTD_loadStream()) ;
            app.RTD_StreamLoadButton.Layout.Row = 11 ;
            app.RTD_StreamLoadButton.Layout.Column = 2 ;
            app.RTD_StreamStatusLabel = uilabel(queryGrid, ...
                'Text', 'No feed stream loaded', ...
                'FontColor', [0.6 0 0], ...
                'WordWrap', 'on') ;
            app.RTD_StreamStatusLabel.Layout.Row = 12 ;
            app.RTD_StreamStatusLabel.Layout.Column = [1 2] ;

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
                app.RTD_updateFQuery() ;

                % Enable export button
                app.RTD_ExportButton.Enable = 'on' ;

                % Update Tab 2 RTD status if tab exists
                if ~isempty(app.Pred_RTDStatusLabel)
                    app.Pred_RTDStatusLabel.Text = sprintf('%s | tau=%.2f, sigma2=%.2f', ...
                        source, app.rtd.tau, app.rtd.sigma2) ;
                    app.Pred_RTDStatusLabel.FontColor = [0 0.5 0] ;
                end
                if ~isempty(app.Pred_InputMethodDropdown) && ...
                        contains(app.Pred_InputMethodDropdown.Value, 'From Calculated')
                    app.Pred_syncFromRTDTab() ;
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

        function RTD_queryValueChanged(app)
            if isempty(app.RTD_FQueryInputField) || ~isvalid(app.RTD_FQueryInputField)
                return
            end

            queryText = strtrim(app.RTD_FQueryInputField.Value) ;
            if isempty(queryText)
                app.RTD_FQueryInputField.UserData = [] ;
                app.RTD_updateFQuery() ;
                return
            end

            try
                queryValue = InputLayerHelper.parseArithmeticExpression(queryText) ;
                querySI = UnitConverterHelper.convertToSI('Time', queryValue, ...
                    app.DisplayControls.RTD.time.Value) ;
                app.RTD_FQueryInputField.UserData = struct('querySI', querySI) ;
                app.RTD_syncQueryFieldToDisplayUnit() ;
            catch
                app.RTD_FQueryInputField.UserData = [] ;
            end
            app.RTD_updateFQuery() ;
        end

        function RTD_syncQueryFieldToDisplayUnit(app)
            if isempty(app.RTD_FQueryInputField) || ~isvalid(app.RTD_FQueryInputField)
                return
            end

            if ~isstruct(app.RTD_FQueryInputField.UserData) || ...
                    ~isfield(app.RTD_FQueryInputField.UserData, 'querySI')
                return
            end

            queryDisplay = UnitConverterHelper.convertFromSI('Time', ...
                app.RTD_FQueryInputField.UserData.querySI, app.DisplayControls.RTD.time.Value) ;
            app.RTD_FQueryInputField.Value = sprintf('%.6g', queryDisplay) ;
        end

        function RTD_updateFQuery(app)
            if isempty(app.RTD_FQueryValueLabel) || ~isvalid(app.RTD_FQueryValueLabel)
                return
            end

            if isempty(app.rtd) || ~isstruct(app.RTD_FQueryInputField.UserData) || ...
                    ~isfield(app.RTD_FQueryInputField.UserData, 'querySI')
                app.RTD_FQueryValueLabel.Text = '--' ;
                app.RTD_FQueryComplementLabel.Text = '--' ;
                app.RTD_clearFQueryOverlay() ;
                return
            end

            querySI = app.RTD_FQueryInputField.UserData.querySI ;
            tData = app.rtd.t(:) ;
            fData = app.rtd.Ft(:) ;

            if isempty(tData) || isempty(fData)
                app.RTD_FQueryValueLabel.Text = '--' ;
                app.RTD_FQueryComplementLabel.Text = '--' ;
                app.RTD_clearFQueryOverlay() ;
                return
            end

            if querySI <= tData(1)
                fValue = 0 ;
            elseif querySI >= tData(end)
                fValue = 1 ;
            else
                fValue = interp1(tData, fData, querySI, 'linear') ;
            end

            fValue = min(max(fValue, 0), 1) ;
            app.RTD_FQueryValueLabel.Text = sprintf('%.6f', fValue) ;
            app.RTD_FQueryComplementLabel.Text = sprintf('%.6f', 1 - fValue) ;
            app.RTD_drawFQueryOverlay(querySI, fValue) ;
        end

        function RTD_clearFQueryOverlay(app)
            overlayHandles = { ...
                app.RTD_FQueryPointHandle, ...
                app.RTD_FQueryVerticalHandle, ...
                app.RTD_FQueryHorizontalHandle} ;

            for k = 1:numel(overlayHandles)
                h = overlayHandles{k} ;
                if ~isempty(h) && isgraphics(h)
                    delete(h) ;
                end
            end

            app.RTD_FQueryPointHandle = [] ;
            app.RTD_FQueryVerticalHandle = [] ;
            app.RTD_FQueryHorizontalHandle = [] ;
        end

        function RTD_drawFQueryOverlay(app, querySI, fValue)
            if isempty(app.RTD_AxesFt) || ~isvalid(app.RTD_AxesFt)
                return
            end

            app.RTD_clearFQueryOverlay() ;

            timeDD = app.DisplayControls.RTD.time ;
            xQuery = app.convertOutputFromTime('time', querySI, timeDD) ;
            xLimits = xlim(app.RTD_AxesFt) ;
            yLimits = ylim(app.RTD_AxesFt) ;

            hold(app.RTD_AxesFt, 'on') ;
            app.RTD_FQueryVerticalHandle = plot(app.RTD_AxesFt, ...
                [xQuery xQuery], [yLimits(1) fValue], ...
                'k--', 'LineWidth', 1, 'HandleVisibility', 'off') ;
            app.RTD_FQueryHorizontalHandle = plot(app.RTD_AxesFt, ...
                [xLimits(1) xQuery], [fValue fValue], ...
                'k--', 'LineWidth', 1, 'HandleVisibility', 'off') ;
            app.RTD_FQueryPointHandle = plot(app.RTD_AxesFt, ...
                xQuery, fValue, 'ko', 'MarkerSize', 6, ...
                'MarkerFaceColor', [1 0.8 0], ...
                'HandleVisibility', 'off') ;
            hold(app.RTD_AxesFt, 'off') ;
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

        function RTD_loadRS(app)
            rsName = app.RTD_RSNameField.Value ;
            try
                RS = evalin('base', rsName) ;
                if ~isa(RS, 'ReactionSys')
                    error('Variable "%s" is not a ReactionSys object.', rsName) ;
                end
                app.RTD_RS = RS ;
                app.RTD_RSStatusLabel.Text = sprintf('Loaded: %d reactions, %d components', ...
                    RS.nReactions, RS.nComponents) ;
                app.RTD_RSStatusLabel.FontColor = [0 0.5 0] ;
                app.RTD_RSEditButton.Enable = 'on' ;

                if ~isempty(app.RTD_feedStream) && ...
                        length(app.RTD_feedStream.concentration) ~= RS.nComponents
                    app.RTD_feedStream = [] ;
                    app.RTD_StreamEditButton.Enable = 'off' ;
                    app.RTD_StreamStatusLabel.Text = 'Loaded stream cleared: its component count does not match the new Reaction System.' ;
                    app.RTD_StreamStatusLabel.FontColor = [0.8 0 0] ;
                end
                if ~isempty(app.Pred_InputMethodDropdown) && ...
                        contains(app.Pred_InputMethodDropdown.Value, 'From Calculated')
                    app.Pred_syncFromRTDTab() ;
                end
            catch ME
                app.RTD_RSStatusLabel.Text = ME.message ;
                app.RTD_RSStatusLabel.FontColor = [0.8 0 0] ;
            end
        end

        function RTD_editRS(app)
            if isempty(app.RTD_RS)
                uialert(app.UIFigure, 'No Reaction System loaded to edit.', 'Nothing to Edit') ;
                return
            end
            defineReactionSysApp(app.RTD_RS, app.RTD_RSNameField.Value) ;
        end

        function RTD_loadStream(app)
            [S, ok] = app.loadStreamFromWorkspace( ...
                app.RTD_StreamNameField, app.RTD_StreamStatusLabel, app.RTD_RS) ;
            if ok
                app.RTD_feedStream = S ;
                app.RTD_StreamEditButton.Enable = 'on' ;
                if ~isempty(app.Pred_InputMethodDropdown) && ...
                        contains(app.Pred_InputMethodDropdown.Value, 'From Calculated')
                    app.Pred_syncFromRTDTab() ;
                end
            end
        end

        function RTD_editStream(app)
            if isempty(app.RTD_feedStream)
                uialert(app.UIFigure, 'No feed stream loaded to edit.', 'Nothing to Edit') ;
                return
            end
            defineStreamApp(app.RTD_feedStream, 'edit', app.RTD_StreamNameField.Value) ;
        end

        %% ============== TAB 2: PREDICTION MODELS ==============
        function createPredictionTab(app)

            app.PredTab = uitab(app.TabGroup, 'Title', 'Prediction Models') ;

            % Main grid: left panel (controls) + right panel (plots)
            mainGrid = uigridlayout(app.PredTab, [1 2]) ;
            mainGrid.ColumnWidth = {430, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'Prediction Configuration') ;
            leftGrid = uigridlayout(leftPanel, [13 2]) ;
            rowH = repmat({28}, 1, 13) ; rowH{13} = 190 ;
            leftGrid.RowHeight = rowH ;
            leftGrid.ColumnWidth = {'1x', '1x'} ;
            leftGrid.Padding = [10 10 10 10] ;
            leftGrid.RowSpacing = 5 ;

            % Row 1: Input method
            lbl = uilabel(leftGrid, 'Text', 'Input:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 1 ; lbl.Layout.Column = 1 ;
            methodSubGrid = uigridlayout(leftGrid, [1 2], ...
                'ColumnWidth', {'1x', 28}, 'Padding', [0 0 0 0], 'ColumnSpacing', 2) ;
            methodSubGrid.Layout.Row = 1 ; methodSubGrid.Layout.Column = 2 ;
            app.Pred_InputMethodDropdown = uidropdown(methodSubGrid, ...
                'Items', {'Manual', 'From Calculated Data'}, ...
                'Value', 'Manual', ...
                'ValueChangedFcn', @(~,~) app.Pred_inputMethodChanged()) ;
            app.Pred_RefreshButton = uibutton(methodSubGrid, 'push', ...
                'Text', char(8635), 'FontSize', 12, ...
                'Tooltip', 'Refresh imported data from Tab 1', ...
                'Visible', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Pred_inputMethodChanged()) ;

            % Row 2: RTD status
            lbl = uilabel(leftGrid, 'Text', 'Current RTD:', ...
                'FontWeight', 'bold') ;
            lbl.Layout.Row = 2 ; lbl.Layout.Column = 1 ;
            app.Pred_RTDStatusLabel = uilabel(leftGrid, ...
                'Text', 'None (generate in Tab 1)', ...
                'FontColor', [0.8 0 0]) ;
            app.Pred_RTDStatusLabel.Layout.Row = 2 ;
            app.Pred_RTDStatusLabel.Layout.Column = 2 ;

            % Row 3: Reaction System header
            lbl = uilabel(leftGrid, 'Text', 'Reaction System:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 3 ; lbl.Layout.Column = [1 2] ;

            % Row 4: New RS + Edit RS buttons
            app.Pred_RSDefineButton = uibutton(leftGrid, 'push', ...
                'Text', 'New RS', ...
                'BackgroundColor', [0.85 0.90 1.0], ...
                'Tooltip', 'Create a new Reaction System from scratch', ...
                'ButtonPushedFcn', @(~,~) defineReactionSysApp()) ;
            app.Pred_RSDefineButton.Layout.Row = 4 ;
            app.Pred_RSDefineButton.Layout.Column = 1 ;

            app.Pred_RSEditButton = uibutton(leftGrid, 'push', ...
                'Text', 'Edit RS', ...
                'BackgroundColor', [1.0 0.95 0.80], ...
                'Tooltip', 'Edit the currently loaded Reaction System', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Pred_editRS()) ;
            app.Pred_RSEditButton.Layout.Row = 4 ;
            app.Pred_RSEditButton.Layout.Column = 2 ;

            % Row 5: RS name field + Load button
            app.Pred_RSNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'RS', ...
                'Tooltip', 'Name of the ReactionSys variable in the MATLAB workspace') ;
            app.Pred_RSNameField.Layout.Row = 5 ; app.Pred_RSNameField.Layout.Column = 1 ;
            app.Pred_RSLoadButton = uibutton(leftGrid, 'push', ...
                'Text', 'Load from Workspace', ...
                'BackgroundColor', [0.85 0.95 0.85], ...
                'Tooltip', 'Load the ReactionSys object from the workspace', ...
                'ButtonPushedFcn', @(~,~) app.Pred_loadRS()) ;
            app.Pred_RSLoadButton.Layout.Row = 5 ; app.Pred_RSLoadButton.Layout.Column = 2 ;

            % Row 6: RS status
            app.Pred_RSStatusLabel = uilabel(leftGrid, ...
                'Text', 'No Reaction System loaded', 'FontColor', [0.6 0 0]) ;
            app.Pred_RSStatusLabel.Layout.Row = 6 ;
            app.Pred_RSStatusLabel.Layout.Column = [1 2] ;

            % Row 7: Feed Stream header
            lbl = uilabel(leftGrid, 'Text', 'Feed Stream:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 7 ; lbl.Layout.Column = [1 2] ;

            % Row 8: New Stream + Edit Stream buttons
            app.Pred_StreamDefineButton = uibutton(leftGrid, 'push', ...
                'Text', 'New Stream', ...
                'BackgroundColor', [0.85 0.90 1.0], ...
                'Tooltip', 'Create a new feed stream with defineStreamApp', ...
                'ButtonPushedFcn', @(~,~) defineStreamApp()) ;
            app.Pred_StreamDefineButton.Layout.Row = 8 ;
            app.Pred_StreamDefineButton.Layout.Column = 1 ;
            app.Pred_StreamEditButton = uibutton(leftGrid, 'push', ...
                'Text', 'Edit Stream', ...
                'BackgroundColor', [1.0 0.95 0.80], ...
                'Tooltip', 'Edit the currently loaded feed stream', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Pred_editStream()) ;
            app.Pred_StreamEditButton.Layout.Row = 8 ;
            app.Pred_StreamEditButton.Layout.Column = 2 ;

            % Row 9: stream name + Load button
            app.Pred_StreamNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'feed', ...
                'Tooltip', 'Name of the feed Stream variable in the MATLAB workspace') ;
            app.Pred_StreamNameField.Layout.Row = 9 ; app.Pred_StreamNameField.Layout.Column = 1 ;
            app.Pred_StreamLoadButton = uibutton(leftGrid, 'push', ...
                'Text', 'Load from Workspace', ...
                'BackgroundColor', [0.85 0.95 0.85], ...
                'Tooltip', 'Load the feed Stream object from the workspace', ...
                'ButtonPushedFcn', @(~,~) app.Pred_loadStream()) ;
            app.Pred_StreamLoadButton.Layout.Row = 9 ; app.Pred_StreamLoadButton.Layout.Column = 2 ;

            % Row 10: Stream status
            app.Pred_StreamStatusLabel = uilabel(leftGrid, ...
                'Text', 'No feed stream loaded', 'FontColor', [0.6 0 0]) ;
            app.Pred_StreamStatusLabel.Layout.Row = 10 ;
            app.Pred_StreamStatusLabel.Layout.Column = [1 2] ;

            % Row 11: Compute button
            app.Pred_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Compute', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Pred_compute()) ;
            app.Pred_ComputeButton.Layout.Row = 11 ;
            app.Pred_ComputeButton.Layout.Column = [1 2] ;

            % Row 12: Display units title
            lbl = uilabel(leftGrid, 'Text', 'Display units:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 12 ; lbl.Layout.Column = [1 2] ;

            % Row 13: Display units
            unitsGrid = uigridlayout(leftGrid, [1 2], ...
                'ColumnWidth', {'1x', '1x'}, ...
                'RowHeight', {'1x'}, ...
                'Padding', [0 0 0 0], ...
                'ColumnSpacing', 4, ...
                'RowSpacing', 4) ;
            unitsGrid.Layout.Row = 13 ;
            unitsGrid.Layout.Column = [1 2] ;
            conversionPanel = uipanel(unitsGrid, 'Title', 'Conversion Comparison') ;
            conversionPanel.Layout.Row = 1 ;
            conversionPanel.Layout.Column = 1 ;
            conversionGrid = uigridlayout(conversionPanel, [1 1], ...
                'Padding', [6 6 6 6]) ;
            app.DisplayControls.Prediction.reactant = app.createDisplayMultiSelectControl( ...
                conversionGrid, 1, 1, 'Reactants:', @(~,~) app.refreshDisplayUnits('Prediction'), 120) ;

            concentrationPanel = uipanel(unitsGrid, 'Title', 'Outlet Concentration') ;
            concentrationPanel.Layout.Row = 1 ;
            concentrationPanel.Layout.Column = 2 ;
            concentrationGrid = uigridlayout(concentrationPanel, [2 1], ...
                'RowHeight', {'fit', '1x'}, ...
                'Padding', [6 6 6 6], ...
                'RowSpacing', 6) ;
            app.DisplayControls.Prediction.concentration = app.createDisplayUnitControl( ...
                concentrationGrid, 1, 1, 'Concentration:', 'Concentration', 'mol/m^3', @(~,~) app.refreshDisplayUnits('Prediction'), 92) ;
            app.DisplayControls.Prediction.species = app.createDisplayMultiSelectControl( ...
                concentrationGrid, 2, 1, 'Species:', @(~,~) app.refreshDisplayUnits('Prediction'), 90) ;

            % ---- RIGHT PANEL (PLOTS) ----
            rightPanel = uipanel(mainGrid, 'Title', 'Model Results') ;
            rightGrid = uigridlayout(rightPanel, [2 1]) ;
            rightGrid.RowHeight = {'1x', '1x'} ;
            rightGrid.ColumnWidth = {'1x'} ;
            rightGrid.Padding = [0 0 0 0] ;
            rightGrid.RowSpacing = 6 ;

            plotPanel = uipanel(rightGrid, 'BorderType', 'none') ;
            plotPanel.Layout.Row = 1 ;
            plotPanel.Layout.Column = 1 ;
            plotLayout = tiledlayout(plotPanel, 1, 2, ...
                'Padding', 'compact', ...
                'TileSpacing', 'compact') ;

            % Conversion comparison bar chart (all models, per reactant)
            app.Pred_AxesXbatch = nexttile(plotLayout, 1) ;
            title(app.Pred_AxesXbatch, 'Conversion Comparison') ;
            xlabel(app.Pred_AxesXbatch, 'Reactant') ;
            ylabel(app.Pred_AxesXbatch, 'Conversion X (-)') ;
            grid(app.Pred_AxesXbatch, 'on') ;

            % Outlet concentration bar chart for all species
            app.Pred_AxesIntegrand = nexttile(plotLayout, 2) ;
            title(app.Pred_AxesIntegrand, 'Outlet Concentration') ;
            xlabel(app.Pred_AxesIntegrand, 'Species') ;
            ylabel(app.Pred_AxesIntegrand, 'C [mol/m^3]') ;
            grid(app.Pred_AxesIntegrand, 'on') ;

            % Exit summary table
            app.Pred_C_exitPanel = uipanel(rightGrid, ...
                'Title', 'Exit Summary - Concentration [mol/m^3]') ;
            app.Pred_C_exitPanel.Layout.Row = 2 ;
            app.Pred_C_exitPanel.Layout.Column = 1 ;
            app.Pred_C_exitPanel.Tooltip = ...
                'Per-species summary of feed concentration, outlet concentration and reactant conversion for each prediction model.' ;
            tableGrid = uigridlayout(app.Pred_C_exitPanel, [1 1], ...
                'Padding', [6 6 6 6]) ;
            app.Pred_C_exitLabel = uilabel(tableGrid, ...
                'Text', '', ...
                'Visible', 'off') ;
            app.Pred_C_exitTable = uitable(tableGrid, ...
                'ColumnName', {'Component', 'Role', 'C0', 'Seg. C_exit', 'MM C_exit', 'CSTR C_exit', 'PFR C_exit', 'X_seg', 'X_MM', 'X_CSTR', 'X_PFR'}, ...
                'ColumnEditable', false(1, 11), ...
                'ColumnWidth', {100, 90, 80, 85, 85, 95, 95, 75, 75, 85, 85}, ...
                'RowName', {}) ;
            app.Pred_C_exitTable.Layout.Row = 1 ;
            app.Pred_C_exitTable.Tooltip = ...
                'Reactants show concentration and conversion. Products, intermediates and inerts show concentration only.' ;
        end

        %% ============== STREAM LOADING HELPER + CALLBACKS ==============

        function [S, ok] = loadStreamFromWorkspace(~, nameField, statusLabel, RS)
            ok = false ; S = [] ;
            streamName = nameField.Value ;
            try
                S = evalin('base', streamName) ;
                if ~isa(S, 'Stream')
                    error('Variable "%s" is not a Stream object.', streamName) ;
                end
                if ~isempty(RS) && length(S.concentration) ~= RS.nComponents
                    error('Stream has %d components but RS has %d. They must match.', ...
                        length(S.concentration), RS.nComponents) ;
                end
                C_str = sprintf('%.4g  ', S.concentration) ;
                statusLabel.Text = sprintf('Loaded C0 (internal SI): [%s] mol/m^3', strtrim(C_str)) ;
                statusLabel.FontColor = [0 0.5 0] ;
                ok = true ;
            catch ME
                statusLabel.Text = ME.message ;
                statusLabel.FontColor = [0.8 0 0] ;
            end
        end

        function Pred_loadStream(app)
            [S, ok] = app.loadStreamFromWorkspace( ...
                app.Pred_StreamNameField, app.Pred_StreamStatusLabel, app.Pred_RS) ;
            if ok
                app.Pred_feedStream = S ;
                app.Pred_StreamEditButton.Enable = 'on' ;
            end
        end

        function TIS_loadStream(app)
            [S, ok] = app.loadStreamFromWorkspace( ...
                app.TIS_StreamNameField, app.TIS_StreamStatusLabel, app.TIS_RS) ;
            if ok
                app.TIS_feedStream = S ;
                app.TIS_StreamEditButton.Enable = 'on' ;
            end
        end

        function Disp_loadStream(app)
            [S, ok] = app.loadStreamFromWorkspace( ...
                app.Disp_StreamNameField, app.Disp_StreamStatusLabel, app.Disp_RS) ;
            if ok
                app.Disp_feedStream = S ;
                app.Disp_StreamEditButton.Enable = 'on' ;
            end
        end

        function Pred_editStream(app)
            if isempty(app.Pred_feedStream)
                uialert(app.UIFigure, ...
                    'No feed stream loaded to edit.', 'Nothing to Edit') ;
                return
            end
            defineStreamApp(app.Pred_feedStream, 'edit', app.Pred_StreamNameField.Value) ;
        end

        function TIS_editStream(app)
            if isempty(app.TIS_feedStream)
                uialert(app.UIFigure, ...
                    'No feed stream loaded to edit.', 'Nothing to Edit') ;
                return
            end
            defineStreamApp(app.TIS_feedStream, 'edit', app.TIS_StreamNameField.Value) ;
        end

        function Disp_editStream(app)
            if isempty(app.Disp_feedStream)
                uialert(app.UIFigure, ...
                    'No feed stream loaded to edit.', 'Nothing to Edit') ;
                return
            end
            defineStreamApp(app.Disp_feedStream, 'edit', app.Disp_StreamNameField.Value) ;
        end

        %% ============== PREDICTION CALLBACKS ==============

        function Pred_inputMethodChanged(app)
            useCalculated = contains(app.Pred_InputMethodDropdown.Value, 'From Calculated') ;
            manualState = 'on' ;
            refreshState = 'off' ;
            if useCalculated
                manualState = 'off' ;
                refreshState = 'on' ;
            end

            app.Pred_RSDefineButton.Enable = manualState ;
            app.Pred_RSEditButton.Enable = 'off' ;
            app.Pred_RSNameField.Enable = manualState ;
            app.Pred_RSLoadButton.Enable = manualState ;
            app.Pred_StreamDefineButton.Enable = manualState ;
            app.Pred_StreamEditButton.Enable = 'off' ;
            app.Pred_StreamNameField.Enable = manualState ;
            app.Pred_StreamLoadButton.Enable = manualState ;
            app.Pred_RefreshButton.Visible = refreshState ;

            if useCalculated
                app.Pred_syncFromRTDTab() ;
            else
                if ~isempty(app.Pred_RS)
                    app.Pred_RSEditButton.Enable = 'on' ;
                end
                if ~isempty(app.Pred_feedStream)
                    app.Pred_StreamEditButton.Enable = 'on' ;
                end
                if isempty(app.rtd)
                    app.Pred_RTDStatusLabel.Text = 'None (generate in Tab 1)' ;
                    app.Pred_RTDStatusLabel.FontColor = [0.8 0 0] ;
                else
                    app.Pred_RTDStatusLabel.Text = sprintf('%s | tau=%.2f, sigma2=%.2f', ...
                        app.RTD_SourceDropdown.Value, app.rtd.tau, app.rtd.sigma2) ;
                    app.Pred_RTDStatusLabel.FontColor = [0 0.5 0] ;
                end
            end
        end

        function Pred_syncFromRTDTab(app)
            infoLines = {} ;

            if ~isempty(app.rtd)
                infoLines{end+1} = sprintf('RTD: %s | tau=%.2f', ...
                    app.RTD_SourceDropdown.Value, app.rtd.tau) ;
            else
                infoLines{end+1} = 'RTD: not loaded' ;
            end

            if ~isempty(app.RTD_RS)
                app.Pred_RS = app.RTD_RS ;
                app.Pred_RSNameField.Value = app.RTD_RSNameField.Value ;
                app.Pred_RSStatusLabel.Text = sprintf('From Tab 1: %d reactions, %d components', ...
                    app.RTD_RS.nReactions, app.RTD_RS.nComponents) ;
                app.Pred_RSStatusLabel.FontColor = [0 0.5 0] ;
                infoLines{end+1} = sprintf('RS: %s', app.RTD_RSNameField.Value) ;
            else
                app.Pred_RS = [] ;
                app.Pred_RSStatusLabel.Text = 'Tab 1 has no Reaction System loaded' ;
                app.Pred_RSStatusLabel.FontColor = [0.8 0 0] ;
                infoLines{end+1} = 'RS: not loaded' ;
            end

            if ~isempty(app.RTD_feedStream)
                app.Pred_feedStream = app.RTD_feedStream ;
                app.Pred_StreamNameField.Value = app.RTD_StreamNameField.Value ;
                C_str = sprintf('%.4g  ', app.RTD_feedStream.concentration) ;
                app.Pred_StreamStatusLabel.Text = sprintf('(from Tab 1, internal SI) [%s] mol/m^3', strtrim(C_str)) ;
                app.Pred_StreamStatusLabel.FontColor = [0 0.5 0] ;
                infoLines{end+1} = sprintf('Stream: %s', app.RTD_StreamNameField.Value) ;
            else
                app.Pred_feedStream = [] ;
                app.Pred_StreamStatusLabel.Text = 'Tab 1 has no feed stream loaded' ;
                app.Pred_StreamStatusLabel.FontColor = [0.8 0 0] ;
                infoLines{end+1} = 'Stream: not loaded' ;
            end

            if any(contains(infoLines, 'not loaded'))
                app.Pred_RTDStatusLabel.FontColor = [0.8 0 0] ;
            else
                app.Pred_RTDStatusLabel.FontColor = [0 0.5 0] ;
            end
            app.Pred_RTDStatusLabel.Text = strjoin(infoLines, ' | ') ;
        end

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

                if contains(app.Pred_InputMethodDropdown.Value, 'From Calculated')
                    app.Pred_syncFromRTDTab() ;
                end

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

                % Validate feed stream
                if isempty(app.Pred_feedStream)
                    uialert(app.UIFigure, ...
                        'No feed stream loaded. Define a Stream with "New Stream" and load it.', ...
                        'Missing Feed Stream') ;
                    app.updateStatus('Ready') ;
                    return ;
                end

                RS = app.Pred_RS ;
                C0 = app.Pred_feedStream.concentration(:)' ;

                if length(C0) ~= RS.nComponents
                    uialert(app.UIFigure, ...
                        sprintf('Feed stream has %d components but RS has %d. They must match.', ...
                        length(C0), RS.nComponents), 'Component Mismatch') ;
                    app.updateStatus('Ready') ;
                    return ;
                end

                % Create model objects with RTD
                app.seg_model = SegregationModel ;
                app.seg_model.rtd = app.rtd ;

                app.mm_model = MaxMixednessModel ;
                app.mm_model.rtd = app.rtd ;

                % Compute using the general isothermal methods
                app.seg_model = app.seg_model.compute_isothermal(RS, C0) ;
                app.mm_model = app.mm_model.compute_isothermal(RS, C0) ;

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

            concDD = app.DisplayControls.Prediction.concentration ;
            RS = app.Pred_RS ;
            C0 = app.Pred_feedStream.concentration(:)' ;
            reactantInfo = app.getPredictionReactantInfo(RS, C0) ;
            speciesInfo = app.getPredictionSpeciesInfo(RS) ;
            speciesRoles = app.classifySpeciesRoles(RS) ;
            app.ensurePredictionReactantSelector(app.DisplayControls.Prediction.reactant, reactantInfo) ;
            selectedIdx = app.getPredictionSelectedReactants( ...
                app.DisplayControls.Prediction.reactant, reactantInfo) ;
            app.ensurePredictionSpeciesSelector(app.DisplayControls.Prediction.species, speciesInfo) ;
            selectedSpeciesIdx = app.getPredictionSelectedSpecies( ...
                app.DisplayControls.Prediction.species, speciesInfo) ;
            [C_out_cstr_ref, ~] = TanksInSeries.solve_sequential(1, RS, C0, app.rtd.tau) ;
            [C_out_pfr_ref, ~] = TanksInSeries.solve_PFR(RS, C0, app.rtd.tau) ;

            % Compute conversions for all reactants up front
            X_seg_all  = app.computeSpeciesConversion(C0, app.seg_model.C_exit, reactantInfo.reactantIndices) ;
            X_mm_all   = app.computeSpeciesConversion(C0, app.mm_model.C_exit,  reactantInfo.reactantIndices) ;
            X_cstr_all = app.computeSpeciesConversion(C0, C_out_cstr_ref,       reactantInfo.reactantIndices) ;
            X_pfr_all  = app.computeSpeciesConversion(C0, C_out_pfr_ref,        reactantInfo.reactantIndices) ;

            % Update exit summary panel header
            app.updateConcentrationHeader(app.Pred_C_exitLabel, concDD) ;
            app.Pred_C_exitPanel.Title = sprintf('Exit Summary - Concentration [%s]', ...
                app.concentrationUnitName(concDD)) ;

            % --- PLOT 1: Conversion comparison (grouped bars, selected reactants) ---
            cla(app.Pred_AxesXbatch) ;
            nR = numel(reactantInfo.reactantIndices) ;
            if nR == 0
                text(app.Pred_AxesXbatch, 0.5, 0.5, 'No reactants with C_0 > 0', ...
                    'Units', 'normalized', 'HorizontalAlignment', 'center') ;
            elseif isempty(selectedIdx)
                text(app.Pred_AxesXbatch, 0.5, 0.5, 'No reactants selected', ...
                    'Units', 'normalized', 'HorizontalAlignment', 'center') ;
            else
                reactantPlotPos = arrayfun(@(idx) find(reactantInfo.reactantIndices == idx, 1), selectedIdx) ;
                X_matrix = [X_seg_all(reactantPlotPos)', X_mm_all(reactantPlotPos)', ...
                            X_cstr_all(reactantPlotPos)', X_pfr_all(reactantPlotPos)'] ;
                reactantLabels = reactantInfo.componentLabels(selectedIdx) ;
                nSelectedReactants = numel(selectedIdx) ;
                b = bar(app.Pred_AxesXbatch, 1:nSelectedReactants, X_matrix, 'grouped') ;
                app.applyPredictionBarStyles(b) ;
                app.Pred_AxesXbatch.XTick = 1:nSelectedReactants ;
                app.Pred_AxesXbatch.XTickLabel = reactantLabels ;
                ylim(app.Pred_AxesXbatch, [0, max(1, max(X_matrix(:)) * 1.1)]) ;
            end
            title(app.Pred_AxesXbatch, 'Conversion Comparison') ;
            xlabel(app.Pred_AxesXbatch, 'Reactant') ;
            ylabel(app.Pred_AxesXbatch, 'Conversion X (-)') ;
            grid(app.Pred_AxesXbatch, 'on') ;

            % --- PLOT 2: Outlet concentration for selected species ---
            cla(app.Pred_AxesIntegrand) ;
            if isempty(selectedSpeciesIdx)
                text(app.Pred_AxesIntegrand, 0.5, 0.5, 'No species selected', ...
                    'Units', 'normalized', 'HorizontalAlignment', 'center') ;
            else
                concMatrix = [app.seg_model.C_exit(:), app.mm_model.C_exit(:), ...
                              C_out_cstr_ref(:), C_out_pfr_ref(:)] ;  % nComp x 4
                concDisplay = reshape(app.convertOutputConcentration(concMatrix(:)', concDD), size(concMatrix)) ;
                C_species = concDisplay(selectedSpeciesIdx, :) ;
                speciesLabels = speciesInfo.componentLabels(selectedSpeciesIdx) ;
                nSelectedSpecies = numel(selectedSpeciesIdx) ;
                b = bar(app.Pred_AxesIntegrand, 1:nSelectedSpecies, C_species, 'grouped') ;
                app.applyPredictionBarStyles(b) ;
                app.Pred_AxesIntegrand.XTick = 1:nSelectedSpecies ;
                app.Pred_AxesIntegrand.XTickLabel = speciesLabels ;
            end
            legendHandles = app.createPredictionLegendPlaceholders(app.Pred_AxesXbatch) ;
            app.updatePredictionSharedLegend(legendHandles) ;
            title(app.Pred_AxesIntegrand, 'Outlet Concentration') ;
            xlabel(app.Pred_AxesIntegrand, 'Species') ;
            ylabel(app.Pred_AxesIntegrand, app.axisLabelWithUnit('C', concDD)) ;
            grid(app.Pred_AxesIntegrand, 'on') ;

            % --- Update Exit Summary table ---
            app.updatePredictionSummaryTable( ...
                reactantInfo.componentLabels, speciesRoles, C0, ...
                app.seg_model.C_exit, app.mm_model.C_exit, C_out_cstr_ref, C_out_pfr_ref, ...
                reactantInfo.reactantIndices, X_seg_all, X_mm_all, X_cstr_all, X_pfr_all, ...
                selectedIdx, concDD) ;
        end

        %% ============== TAB 3: TANKS-IN-SERIES ==============
        function createTISTab(app)

            app.TISTab = uitab(app.TabGroup, 'Title', 'Tanks-in-Series') ;

            % Main grid: left panel (controls) + right panel (plots)
            mainGrid = uigridlayout(app.TISTab, [1 2]) ;
            mainGrid.ColumnWidth = {430, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'TIS Configuration') ;
            leftGrid = uigridlayout(leftPanel, [20 2]) ;
            rowH = repmat({28}, 1, 20) ; rowH{14} = 56 ; rowH{20} = 80 ;
            leftGrid.RowHeight = rowH ;
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

            % Row 6: Define RS button + Edit RS button
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

            % Row 9: Feed Stream header
            lbl = uilabel(leftGrid, 'Text', 'Feed Stream:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 9 ; lbl.Layout.Column = [1 2] ;

            % Row 10: New Stream + Edit Stream buttons
            app.TIS_StreamDefineButton = uibutton(leftGrid, 'push', ...
                'Text', 'New Stream', ...
                'BackgroundColor', [0.85 0.90 1.0], ...
                'Tooltip', 'Create a new feed stream with defineStreamApp', ...
                'ButtonPushedFcn', @(~,~) defineStreamApp()) ;
            app.TIS_StreamDefineButton.Layout.Row = 10 ;
            app.TIS_StreamDefineButton.Layout.Column = 1 ;
            app.TIS_StreamEditButton = uibutton(leftGrid, 'push', ...
                'Text', 'Edit Stream', ...
                'BackgroundColor', [1.0 0.95 0.80], ...
                'Tooltip', 'Edit the currently loaded feed stream', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.TIS_editStream()) ;
            app.TIS_StreamEditButton.Layout.Row = 10 ;
            app.TIS_StreamEditButton.Layout.Column = 2 ;

            % Row 11: stream name + Load button
            app.TIS_StreamNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'feed', ...
                'Tooltip', 'Name of the feed Stream variable in the MATLAB workspace') ;
            app.TIS_StreamNameField.Layout.Row = 11 ; app.TIS_StreamNameField.Layout.Column = 1 ;
            app.TIS_StreamLoadButton = uibutton(leftGrid, 'push', ...
                'Text', 'Load from Workspace', ...
                'BackgroundColor', [0.85 0.95 0.85], ...
                'Tooltip', 'Load the feed Stream object from the workspace', ...
                'ButtonPushedFcn', @(~,~) app.TIS_loadStream()) ;
            app.TIS_StreamLoadButton.Layout.Row = 11 ; app.TIS_StreamLoadButton.Layout.Column = 2 ;

            % Row 12: Stream status
            app.TIS_StreamStatusLabel = uilabel(leftGrid, ...
                'Text', 'No feed stream loaded', 'FontColor', [0.6 0 0]) ;
            app.TIS_StreamStatusLabel.Layout.Row = 12 ;
            app.TIS_StreamStatusLabel.Layout.Column = [1 2] ;

            % Row 13: Compute button
            app.TIS_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Compute', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.TIS_compute()) ;
            app.TIS_ComputeButton.Layout.Row = 13 ;
            app.TIS_ComputeButton.Layout.Column = [1 2] ;

            % Row 14: Display units
            unitsGrid = uigridlayout(leftGrid, [2 2], ...
                'ColumnWidth', {'1x', '1x'}, 'RowHeight', {24, 24}, 'Padding', [0 0 0 0], 'ColumnSpacing', 4) ;
            unitsGrid.Layout.Row = 14 ;
            unitsGrid.Layout.Column = [1 2] ;
            app.DisplayControls.TIS.time = app.createDisplayUnitControl( ...
                unitsGrid, 1, 1, 'Time base:', 'Time', 's', @(~,~) app.refreshDisplayUnits('TIS'), 84) ;
            app.DisplayControls.TIS.concentration = app.createDisplayUnitControl( ...
                unitsGrid, 1, 2, 'Concentration:', 'Concentration', 'mol/m^3', @(~,~) app.refreshDisplayUnits('TIS'), 92) ;
            app.DisplayControls.TIS.component = app.createDisplayChoiceControl( ...
                unitsGrid, 2, [1 2], 'Plot:', {'All'}, 'All', @(~,~) app.refreshDisplayUnits('TIS'), 118) ;

            % Row 15: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 15 ; lbl.Layout.Column = [1 2] ;

            % Row 16: N used
            lbl = uilabel(leftGrid, 'Text', 'N used:') ;
            lbl.Layout.Row = 16 ; lbl.Layout.Column = 1 ;
            app.TIS_ResultNused = uilabel(leftGrid, 'Text', '--') ;
            app.TIS_ResultNused.Layout.Row = 16 ;
            app.TIS_ResultNused.Layout.Column = 2 ;
            app.setTooltip('Number of stirred tanks used in the tanks-in-series approximation for the current calculation.', ...
                lbl, app.TIS_ResultNused) ;

            % Row 17: X_TIS
            lbl = uilabel(leftGrid, 'Text', 'X<sub>TIS</sub>:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 17 ; lbl.Layout.Column = 1 ;
            app.TIS_ResultXtis = uilabel(leftGrid, 'Text', '--') ;
            app.TIS_ResultXtis.Layout.Row = 17 ;
            app.TIS_ResultXtis.Layout.Column = 2 ;
            app.TIS_ResultXtis.FontWeight = 'bold' ;
            app.setTooltip('Conversion predicted by the selected tanks-in-series model.', ...
                lbl, app.TIS_ResultXtis) ;

            % Row 18: X_CSTR + X_PFR on same row
            app.TIS_ResultXcstr = uilabel(leftGrid, 'Text', 'X<sub>CSTR</sub>: --', 'Interpreter', 'html') ;
            app.TIS_ResultXcstr.Layout.Row = 18 ; app.TIS_ResultXcstr.Layout.Column = 1 ;
            app.TIS_ResultXpfr = uilabel(leftGrid, 'Text', 'X<sub>PFR</sub>: --', 'Interpreter', 'html') ;
            app.TIS_ResultXpfr.Layout.Row = 18 ; app.TIS_ResultXpfr.Layout.Column = 2 ;
            app.setTooltip('Reference conversion for the ideal CSTR limit, equivalent to N = 1.', ...
                app.TIS_ResultXcstr) ;
            app.setTooltip('Reference conversion for the ideal plug-flow limit, equivalent to N approaching infinity.', ...
                app.TIS_ResultXpfr) ;

            % Row 19: Outlet concentrations header
            app.TIS_C_exitLabel = uilabel(leftGrid, ...
                'Text', 'Outlet Conc. at Exit [mol/m^3]:', ...
                'FontWeight', 'bold') ;
            app.TIS_C_exitLabel.Layout.Row = 19 ;
            app.TIS_C_exitLabel.Layout.Column = [1 2] ;
            app.TIS_C_exitLabel.Tooltip = ...
                'Per-component outlet concentrations at the reactor exit for TIS and its CSTR/PFR limits.' ;

            % Row 20: Per-component outlet concentration table
            app.TIS_C_exitTable = uitable(leftGrid, ...
                'ColumnName', {'Comp.', 'TIS', 'CSTR', 'PFR'}, ...
                'ColumnEditable', [false false false false], ...
                'ColumnWidth', {70, 80, 80, 80}) ;
            app.TIS_C_exitTable.Layout.Row = 20 ;
            app.TIS_C_exitTable.Layout.Column = [1 2] ;
            app.TIS_C_exitTable.Tooltip = ...
                'Outlet concentrations by component at the reactor exit for the selected TIS model and its CSTR/PFR references.' ;

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
            title(app.TIS_AxesXvsN, 'Outlet Concentration vs N') ;
            xlabel(app.TIS_AxesXvsN, 'N [number of tanks]') ;
            ylabel(app.TIS_AxesXvsN, 'C [mol/m^3]') ;
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

                % Import feed Stream from Prediction Models tab
                if ~isempty(app.Pred_feedStream)
                    app.TIS_feedStream = app.Pred_feedStream ;
                    app.TIS_StreamNameField.Value = app.Pred_StreamNameField.Value ;
                    app.TIS_StreamEditButton.Enable = 'on' ;
                    C_str = sprintf('%.4g  ', app.Pred_feedStream.concentration) ;
                    app.TIS_StreamStatusLabel.Text = sprintf('(from Prediction, internal SI) [%s] mol/m^3', strtrim(C_str)) ;
                    app.TIS_StreamStatusLabel.FontColor = [0 0.5 0] ;
                    infoLines{end+1} = 'Stream: from Prediction' ;
                else
                    infoLines{end+1} = 'Stream: not loaded' ;
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

                % Validate feed stream
                if isempty(app.TIS_feedStream)
                    uialert(app.UIFigure, ...
                        'No feed stream loaded. Define a Stream with "New Stream" and load it.', ...
                        'Missing Feed Stream') ;
                    app.updateStatus('Ready') ;
                    return ;
                end

                N_val = app.TIS_NField.Value ;
                tau_val = app.readInputField(app.TIS_tauField) ;
                RS = app.TIS_RS ;
                C0 = app.TIS_feedStream.concentration(:)' ;

                if length(C0) ~= RS.nComponents
                    uialert(app.UIFigure, ...
                        sprintf('Feed stream has %d components but RS has %d. They must match.', ...
                        length(C0), RS.nComponents), 'Component Mismatch') ;
                    app.updateStatus('Ready') ;
                    return ;
                end

                % --- Compute X_TIS for selected N ---
                [C_out_tis,  X_tis]  = TanksInSeries.solve_sequential(N_val, RS, C0, tau_val) ;

                % --- Reference: CSTR (N=1) ---
                [C_out_cstr, X_cstr] = TanksInSeries.solve_sequential(1, RS, C0, tau_val) ;

                % --- Reference: PFR (N→inf) ---
                [C_out_pfr,  X_pfr]  = TanksInSeries.solve_PFR(RS, C0, tau_val) ;

                % --- Update results ---
                app.TIS_ResultNused.Text = sprintf('%.2f', N_val) ;
                app.TIS_ResultXtis.Text = sprintf('%.4f', X_tis) ;
                app.TIS_ResultXcstr.Text = sprintf('X_{CSTR}: %.4f', X_cstr) ;
                app.TIS_ResultXpfr.Text = sprintf('X_{PFR}: %.4f', X_pfr) ;

                app.ensureComponentSelectorItems(app.DisplayControls.TIS.component, RS.nComponents) ;

                app.DisplayCache.TIS = struct( ...
                    'N_val', N_val, ...
                    'tau_val', tau_val, ...
                    'RS', RS, ...
                    'C0', C0, ...
                    'X_tis', X_tis, ...
                    'X_cstr', X_cstr, ...
                    'X_pfr', X_pfr, ...
                    'C_out_tis', C_out_tis, ...
                    'C_out_cstr', C_out_cstr, ...
                    'C_out_pfr', C_out_pfr) ;

                % --- Update plots ---
                app.TIS_updatePlots(N_val, tau_val, RS, C0, ...
                    X_tis, X_cstr, X_pfr, ...
                    C_out_tis, C_out_cstr, C_out_pfr) ;

                app.updateStatus('Ready') ;

            catch ME
                app.updateStatus('Error') ;
                uialert(app.UIFigure, ME.message, 'TIS Computation Error') ;
            end
        end

        function TIS_updatePlots(app, N_val, tau_val, RS, C0, ...
                                 X_tis, X_cstr, X_pfr, ...
                                 C_out_tis, C_out_cstr, C_out_pfr)

            % ---- Plot 1: E(t) for current N ----
            cla(app.TIS_AxesEt) ;
            rtd_tis = RTD.tanks_in_series(N_val, tau_val) ;
            timeDD = app.DisplayControls.TIS.time ;
            concDD = app.DisplayControls.TIS.concentration ;
            t_display = app.convertOutputVectorFromTime('time', rtd_tis.t, timeDD) ;
            Et_display = app.convertOutputVectorFromTime('timeInverse', rtd_tis.Et, timeDD) ;
            plot(app.TIS_AxesEt, t_display, Et_display, 'b-', 'LineWidth', 1.5) ;
            title(app.TIS_AxesEt, sprintf('E(t) - TIS  N=%.1f', N_val)) ;
            xlabel(app.TIS_AxesEt, app.axisLabelWithUnit('t', timeDD)) ;
            ylabel(app.TIS_AxesEt, app.axisLabelWithUnitName('E(t)', app.timeInverseUnitName(timeDD))) ;

            app.updateConcentrationHeader(app.TIS_C_exitLabel, concDD) ;
            app.updateConcentrationTable(app.TIS_C_exitTable, ...
                [C_out_tis(:), C_out_cstr(:), C_out_pfr(:)], ...
                {'TIS', 'CSTR', 'PFR'}, concDD) ;

            % ---- Plot 2: Outlet concentration vs N sweep ----
            cla(app.TIS_AxesXvsN) ;
            N_sweep = [1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 50, 100] ;
            C_sweep = zeros(numel(N_sweep), RS.nComponents) ;

            for idx = 1:length(N_sweep)
                [C_sweep(idx, :), ~] = TanksInSeries.solve_sequential( ...
                    N_sweep(idx), RS, C0, tau_val) ;
            end

            app.ensureComponentSelectorItems(app.DisplayControls.TIS.component, RS.nComponents) ;
            selectedIdx = app.getSelectedComponentIndices(app.DisplayControls.TIS.component, RS.nComponents) ;
            C_sweep_display = app.convertOutputConcentration(C_sweep, concDD) ;
            C_tis_display = app.convertOutputConcentration(C_out_tis, concDD) ;
            C_cstr_display = app.convertOutputConcentration(C_out_cstr, concDD) ;
            C_pfr_display = app.convertOutputConcentration(C_out_pfr, concDD) ;
            colors = lines(RS.nComponents) ;
            hold(app.TIS_AxesXvsN, 'on') ;
            for i = selectedIdx
                plot(app.TIS_AxesXvsN, N_sweep, C_sweep_display(:, i), 'o-', ...
                    'Color', colors(i,:), 'LineWidth', 1.5, ...
                    'MarkerFaceColor', colors(i,:), ...
                    'DisplayName', sprintf('C%d', i)) ;
                plot(app.TIS_AxesXvsN, N_val, C_tis_display(i), 'p', ...
                    'Color', colors(i,:), 'MarkerSize', 11, ...
                    'MarkerFaceColor', colors(i,:), ...
                    'HandleVisibility', 'off') ;
                if isscalar(selectedIdx)
                    yline(app.TIS_AxesXvsN, C_cstr_display(i), '--', 'CSTR', ...
                        'Color', [0.8 0 0], 'LineWidth', 1, ...
                        'LabelHorizontalAlignment', 'left') ;
                    yline(app.TIS_AxesXvsN, C_pfr_display(i), '--', 'PFR', ...
                        'Color', [0 0.6 0], 'LineWidth', 1, ...
                        'LabelHorizontalAlignment', 'left') ;
                end
            end
            hold(app.TIS_AxesXvsN, 'off') ;

            if isscalar(selectedIdx)
                title(app.TIS_AxesXvsN, sprintf('Outlet Concentration vs N - C%d', selectedIdx)) ;
            else
                title(app.TIS_AxesXvsN, 'Outlet Concentration vs N') ;
            end
            xlabel(app.TIS_AxesXvsN, 'N [number of tanks]') ;
            ylabel(app.TIS_AxesXvsN, app.axisLabelWithUnit('C', concDD)) ;
            if isscalar(selectedIdx)
                legend(app.TIS_AxesXvsN, 'off') ;
            else
                legend(app.TIS_AxesXvsN, 'Location', 'best') ;
            end

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
            mainGrid.ColumnWidth = {430, '1x'} ;

            % ---- LEFT PANEL ----
            leftPanel = uipanel(mainGrid, 'Title', 'Dispersion Configuration') ;
            leftGrid = uigridlayout(leftPanel, [23 2]) ;
            rowHD = repmat({28}, 1, 23) ; rowHD{16} = 56 ; rowHD{23} = 80 ;
            leftGrid.RowHeight = rowHD ;
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

            % Row 11: Feed Stream header
            lbl = uilabel(leftGrid, 'Text', 'Feed Stream:', 'FontWeight', 'bold') ;
            lbl.Layout.Row = 11 ; lbl.Layout.Column = [1 2] ;

            % Row 12: New Stream + Edit Stream buttons
            app.Disp_StreamDefineButton = uibutton(leftGrid, 'push', ...
                'Text', 'New Stream', ...
                'BackgroundColor', [0.85 0.90 1.0], ...
                'Tooltip', 'Create a new feed stream with defineStreamApp', ...
                'ButtonPushedFcn', @(~,~) defineStreamApp()) ;
            app.Disp_StreamDefineButton.Layout.Row = 12 ;
            app.Disp_StreamDefineButton.Layout.Column = 1 ;
            app.Disp_StreamEditButton = uibutton(leftGrid, 'push', ...
                'Text', 'Edit Stream', ...
                'BackgroundColor', [1.0 0.95 0.80], ...
                'Tooltip', 'Edit the currently loaded feed stream', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.Disp_editStream()) ;
            app.Disp_StreamEditButton.Layout.Row = 12 ;
            app.Disp_StreamEditButton.Layout.Column = 2 ;

            % Row 13: stream name + Load button
            app.Disp_StreamNameField = uieditfield(leftGrid, 'text', ...
                'Value', 'feed', ...
                'Tooltip', 'Name of the feed Stream variable in the MATLAB workspace') ;
            app.Disp_StreamNameField.Layout.Row = 13 ; app.Disp_StreamNameField.Layout.Column = 1 ;
            app.Disp_StreamLoadButton = uibutton(leftGrid, 'push', ...
                'Text', 'Load from Workspace', ...
                'BackgroundColor', [0.85 0.95 0.85], ...
                'Tooltip', 'Load the feed Stream object from the workspace', ...
                'ButtonPushedFcn', @(~,~) app.Disp_loadStream()) ;
            app.Disp_StreamLoadButton.Layout.Row = 13 ; app.Disp_StreamLoadButton.Layout.Column = 2 ;

            % Row 14: Stream status
            app.Disp_StreamStatusLabel = uilabel(leftGrid, ...
                'Text', 'No feed stream loaded', 'FontColor', [0.6 0 0]) ;
            app.Disp_StreamStatusLabel.Layout.Row = 14 ;
            app.Disp_StreamStatusLabel.Layout.Column = [1 2] ;

            % Row 15: Compute button
            app.Disp_ComputeButton = uibutton(leftGrid, 'push', ...
                'Text', 'Compute', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.Disp_compute()) ;
            app.Disp_ComputeButton.Layout.Row = 15 ;
            app.Disp_ComputeButton.Layout.Column = [1 2] ;

            % Row 16: Display units
            unitsGrid = uigridlayout(leftGrid, [2 2], ...
                'ColumnWidth', {'1x', '1x'}, 'RowHeight', {24, 24}, 'Padding', [0 0 0 0], 'ColumnSpacing', 4) ;
            unitsGrid.Layout.Row = 16 ;
            unitsGrid.Layout.Column = [1 2] ;
            app.DisplayControls.Dispersion.time = app.createDisplayUnitControl( ...
                unitsGrid, 1, 1, 'Time base:', 'Time', 's', @(~,~) app.refreshDisplayUnits('Dispersion'), 84) ;
            app.DisplayControls.Dispersion.concentration = app.createDisplayUnitControl( ...
                unitsGrid, 1, 2, 'Concentration:', 'Concentration', 'mol/m^3', @(~,~) app.refreshDisplayUnits('Dispersion'), 92) ;
            app.DisplayControls.Dispersion.component = app.createDisplayChoiceControl( ...
                unitsGrid, 2, [1 2], 'Plot:', {'All'}, 'All', @(~,~) app.refreshDisplayUnits('Dispersion'), 118) ;

            % Row 17: Results header
            lbl = uilabel(leftGrid, 'Text', 'Results:', ...
                'FontWeight', 'bold', 'FontSize', 13) ;
            lbl.Layout.Row = 17 ; lbl.Layout.Column = [1 2] ;

            % Row 18: Bo info
            lbl = uilabel(leftGrid, 'Text', 'Bo:') ;
            lbl.Layout.Row = 18 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultBo = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultBo.Layout.Row = 18 ; app.Disp_ResultBo.Layout.Column = 2 ;
            app.setTooltip('Current Bodenstein number and its inverse Peclet number. They quantify the intensity of axial mixing in the dispersion model.', ...
                lbl, app.Disp_ResultBo) ;

            % Row 19: X_dispersion
            lbl = uilabel(leftGrid, 'Text', 'X<sub>dispersion</sub>:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 19 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultX = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultX.Layout.Row = 19 ; app.Disp_ResultX.Layout.Column = 2 ;
            app.Disp_ResultX.FontWeight = 'bold' ;
            app.setTooltip('Conversion predicted by the axial-dispersion reactor model for the selected Bo and boundary condition.', ...
                lbl, app.Disp_ResultX) ;

            % Row 20: X_CSTR
            lbl = uilabel(leftGrid, 'Text', 'X<sub>CSTR</sub> [Bo&#8594;&#8734;]:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 20 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultXcstr = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultXcstr.Layout.Row = 20 ; app.Disp_ResultXcstr.Layout.Column = 2 ;
            app.setTooltip('Reference conversion for the perfectly mixed limit of the dispersion model, reached as Bo approaches infinity.', ...
                lbl, app.Disp_ResultXcstr) ;

            % Row 21: X_PFR
            lbl = uilabel(leftGrid, 'Text', 'X<sub>PFR</sub> [Bo&#8594;0]:', 'Interpreter', 'html') ;
            lbl.Layout.Row = 21 ; lbl.Layout.Column = 1 ;
            app.Disp_ResultXpfr = uilabel(leftGrid, 'Text', '--') ;
            app.Disp_ResultXpfr.Layout.Row = 21 ; app.Disp_ResultXpfr.Layout.Column = 2 ;
            app.setTooltip('Reference conversion for the plug-flow limit of the dispersion model, reached as Bo approaches zero in this app convention.', ...
                lbl, app.Disp_ResultXpfr) ;

            % Row 22: Outlet concentrations header
            app.Disp_C_exitLabel = uilabel(leftGrid, ...
                'Text', 'Outlet Conc. at Exit [mol/m^3]:', ...
                'FontWeight', 'bold') ;
            app.Disp_C_exitLabel.Layout.Row = 22 ;
            app.Disp_C_exitLabel.Layout.Column = [1 2] ;
            app.Disp_C_exitLabel.Tooltip = ...
                'Per-component outlet concentrations at the reactor exit for dispersion and its CSTR/PFR limits.' ;

            % Row 23: Per-component outlet concentration table
            app.Disp_C_exitTable = uitable(leftGrid, ...
                'ColumnName', {'Comp.', 'Disp.', 'CSTR', 'PFR'}, ...
                'ColumnEditable', [false false false false], ...
                'ColumnWidth', {70, 80, 80, 80}) ;
            app.Disp_C_exitTable.Layout.Row = 23 ;
            app.Disp_C_exitTable.Layout.Column = [1 2] ;
            app.Disp_C_exitTable.Tooltip = ...
                'Outlet concentrations by component at the reactor exit for the selected dispersion model and its CSTR/PFR references.' ;

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
            title(app.Disp_AxesXvsBo, 'Outlet Concentration vs Bo') ;
            xlabel(app.Disp_AxesXvsBo, 'Bo [dispersion number]') ;
            ylabel(app.Disp_AxesXvsBo, 'C [mol/m^3]') ;
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

                % Import feed Stream from Prediction Models tab
                if ~isempty(app.Pred_feedStream)
                    app.Disp_feedStream = app.Pred_feedStream ;
                    app.Disp_StreamNameField.Value = app.Pred_StreamNameField.Value ;
                    app.Disp_StreamEditButton.Enable = 'on' ;
                    C_str = sprintf('%.4g  ', app.Pred_feedStream.concentration) ;
                    app.Disp_StreamStatusLabel.Text = sprintf('(from Prediction, internal SI) [%s] mol/m^3', strtrim(C_str)) ;
                    app.Disp_StreamStatusLabel.FontColor = [0 0.5 0] ;
                    infoLines{end+1} = 'Stream: from Prediction' ;
                else
                    infoLines{end+1} = 'Stream: not loaded' ;
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

                % Validate feed stream
                if isempty(app.Disp_feedStream)
                    uialert(app.UIFigure, ...
                        'No feed stream loaded. Define a Stream with "New Stream" and load it.', ...
                        'Missing Feed Stream') ;
                    app.updateStatus('Ready') ;
                    return ;
                end

                RS = app.Disp_RS ;
                C0 = app.Disp_feedStream.concentration(:)' ;

                if length(C0) ~= RS.nComponents
                    uialert(app.UIFigure, ...
                        sprintf('Feed stream has %d components but RS has %d. They must match.', ...
                        length(C0), RS.nComponents), 'Component Mismatch') ;
                    app.updateStatus('Ready') ;
                    return ;
                end

                Bo_val = app.Disp_BoField.Value ;
                bcType = app.Disp_BCDropdown.Value ;
                tau_val = app.readInputField(app.Disp_tauField) ;

                % Create DispersionReactor
                app.disp_reactor = DispersionReactor(Bo_val, bcType) ;

                % Compute dispersion conversion via general method
                [X_disp, C_out_disp] = app.disp_reactor.compute_conversion_general(RS, C0, tau_val) ;

                % Reference: CSTR and PFR via TanksInSeries module
                [C_out_cstr, X_cstr] = TanksInSeries.solve_sequential(1, RS, C0, tau_val) ;
                [C_out_pfr,  X_pfr]  = TanksInSeries.solve_PFR(RS, C0, tau_val) ;

                X_cstr = max(0, min(1, X_cstr)) ;
                X_pfr  = max(0, min(1, X_pfr)) ;

                % Update results
                app.Disp_ResultBo.Text = sprintf('Bo=%.4g, Pe=%.4g', Bo_val, 1/Bo_val) ;
                app.Disp_ResultX.Text = sprintf('%.4f', X_disp) ;
                app.Disp_ResultXcstr.Text = sprintf('%.4f', X_cstr) ;
                app.Disp_ResultXpfr.Text = sprintf('%.4f', X_pfr) ;

                app.ensureComponentSelectorItems(app.DisplayControls.Dispersion.component, RS.nComponents) ;

                app.DisplayCache.Dispersion = struct( ...
                    'Bo_val', Bo_val, ...
                    'tau_val', tau_val, ...
                    'RS', RS, ...
                    'C0', C0, ...
                    'X_disp', X_disp, ...
                    'X_cstr', X_cstr, ...
                    'X_pfr', X_pfr, ...
                    'C_out_disp', C_out_disp, ...
                    'C_out_cstr', C_out_cstr, ...
                    'C_out_pfr', C_out_pfr, ...
                    'bcType', bcType) ;

                % Update plots
                app.Disp_updatePlots(Bo_val, tau_val, RS, C0, ...
                                     X_disp, X_cstr, X_pfr, ...
                                     C_out_disp, C_out_cstr, C_out_pfr, bcType) ;

                app.updateStatus('Ready') ;

            catch ME
                app.updateStatus('Error') ;
                uialert(app.UIFigure, ME.message, 'Dispersion Model Error') ;
            end
        end

        function Disp_updatePlots(app, Bo_val, tau_val, RS, C0, ...
                                  X_disp, X_cstr, X_pfr, ...
                                  C_out_disp, C_out_cstr, C_out_pfr, bcType)

            % ---- Plot 1: E(t) ----
            cla(app.Disp_AxesEt) ;
            rtd_obj = app.disp_reactor.generate_RTD(tau_val) ;
            timeDD = app.DisplayControls.Dispersion.time ;
            concDD = app.DisplayControls.Dispersion.concentration ;
            t_display = app.convertOutputVectorFromTime('time', rtd_obj.t, timeDD) ;
            Et_display = app.convertOutputVectorFromTime('timeInverse', rtd_obj.Et, timeDD) ;
            plot(app.Disp_AxesEt, t_display, Et_display, 'b-', 'LineWidth', 1.5) ;
            title(app.Disp_AxesEt, sprintf('E(t) - %s, Bo=%.4g', ...
                  bcType, Bo_val)) ;
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

            app.updateConcentrationHeader(app.Disp_C_exitLabel, concDD) ;
            app.updateConcentrationTable(app.Disp_C_exitTable, ...
                [C_out_disp(:), C_out_cstr(:), C_out_pfr(:)], ...
                {'Disp.', 'CSTR', 'PFR'}, concDD) ;

            % ---- Plot 2: Outlet concentration vs Bo sweep ----
            cla(app.Disp_AxesXvsBo) ;
            [Bo_sweep, ~, C_sweep] = app.disp_reactor.sweep_Bo_general(RS, C0, tau_val) ;
            app.ensureComponentSelectorItems(app.DisplayControls.Dispersion.component, RS.nComponents) ;
            selectedIdx = app.getSelectedComponentIndices(app.DisplayControls.Dispersion.component, RS.nComponents) ;
            C_sweep_display = app.convertOutputConcentration(C_sweep, concDD) ;
            C_disp_display = app.convertOutputConcentration(C_out_disp, concDD) ;
            C_cstr_display = app.convertOutputConcentration(C_out_cstr, concDD) ;
            C_pfr_display = app.convertOutputConcentration(C_out_pfr, concDD) ;
            colors = lines(RS.nComponents) ;
            hold(app.Disp_AxesXvsBo, 'on') ;
            for i = selectedIdx
                semilogx(app.Disp_AxesXvsBo, Bo_sweep, C_sweep_display(:, i), '-', ...
                    'Color', colors(i,:), 'LineWidth', 1.5, ...
                    'DisplayName', sprintf('C%d', i)) ;
                semilogx(app.Disp_AxesXvsBo, Bo_val, C_disp_display(i), 'p', ...
                    'Color', colors(i,:), 'MarkerSize', 12, ...
                    'MarkerFaceColor', colors(i,:), ...
                    'HandleVisibility', 'off') ;
                if isscalar(selectedIdx)
                    yline(app.Disp_AxesXvsBo, C_pfr_display(i), '--', 'PFR', ...
                        'Color', [0 0.6 0], 'LineWidth', 1, ...
                        'LabelHorizontalAlignment', 'left') ;
                    yline(app.Disp_AxesXvsBo, C_cstr_display(i), '--', 'CSTR', ...
                        'Color', [0.8 0 0], 'LineWidth', 1, ...
                        'LabelHorizontalAlignment', 'left') ;
                end
            end
            hold(app.Disp_AxesXvsBo, 'off') ;

            if isscalar(selectedIdx)
                title(app.Disp_AxesXvsBo, sprintf('Outlet Concentration vs Bo - C%d', selectedIdx)) ;
            else
                title(app.Disp_AxesXvsBo, 'Outlet Concentration vs Bo') ;
            end
            xlabel(app.Disp_AxesXvsBo, 'Bo [dispersion number]') ;
            ylabel(app.Disp_AxesXvsBo, app.axisLabelWithUnit('C', concDD)) ;
            if isscalar(selectedIdx)
                legend(app.Disp_AxesXvsBo, 'off') ;
            else
                legend(app.Disp_AxesXvsBo, 'Location', 'best') ;
            end

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

