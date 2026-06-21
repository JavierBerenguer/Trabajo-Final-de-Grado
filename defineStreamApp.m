classdef defineStreamApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        DefinestreamfromHysysButton     matlab.ui.control.Button
        UnitconversionhelperButton      matlab.ui.control.Button
        PhaseDropDown                   matlab.ui.control.DropDown
        PhaseDropDownLabel              matlab.ui.control.Label
        TextArea                        matlab.ui.control.TextArea
        CheckBoxT                       matlab.ui.control.CheckBox
        CheckBoxP                       matlab.ui.control.CheckBox
        NumberofcomponentsSpinner       matlab.ui.control.Spinner
        NumberofcomponentsSpinnerLabel  matlab.ui.control.Label
        CreateStreamButton              matlab.ui.control.Button
        ViscosityUnitsDropDown          matlab.ui.control.DropDown
        ViscosityPasEditField           matlab.ui.control.NumericEditField
        ViscosityPasEditFieldLabel      matlab.ui.control.Label
        DensityUnitsDropDown            matlab.ui.control.DropDown
        DensitykgmEditField             matlab.ui.control.NumericEditField
        DensitykgmEditFieldLabel        matlab.ui.control.Label
        TemperatureUnitsDropDown        matlab.ui.control.DropDown
        TemperatureEditField            matlab.ui.control.NumericEditField
        TKEditFieldLabel                matlab.ui.control.Label
        PressureUnitsDropDown           matlab.ui.control.DropDown
        PressureEditField               matlab.ui.control.NumericEditField
        PPaEditFieldLabel               matlab.ui.control.Label
        volumetricFlowUnitsEditField    matlab.ui.control.DropDown
        UnitsEditField_3Label           matlab.ui.control.Label
        VolumetricFlowmsEditField       matlab.ui.control.NumericEditField
        VolumetricFlowmsEditFieldLabel  matlab.ui.control.Label
        ConcentrationUnitsDropDown      matlab.ui.control.DropDown
        ConcentrationUnitsDropDownLabel matlab.ui.control.Label
        MolarFlowunitsEditField         matlab.ui.control.DropDown
        MolarFlowunitsEditFieldLabel    matlab.ui.control.Label
        UITableStreamData               matlab.ui.control.Table
        NameEditField                   matlab.ui.control.EditField
        NameEditFieldLabel              matlab.ui.control.Label
        StreamLabel                     matlab.ui.control.Label
    end

    properties (Access = public)
        Y = Stream
        UnitsApp
    end

    properties (Access = private)
        IsReadOnlyDisplay logical = false
        IsEditMode logical = false
        DisplayedStream = []
    end

    methods (Access = public)

        function displayStreamValues(app, materialStream)
            if ~isa(materialStream, 'Stream')
                return
            end

            app.DisplayedStream = materialStream ;
            app.applyStreamUnitPreferences(materialStream) ;
            app.renderStreamInSelectedUnits(materialStream) ;
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, varargin)
            app.configureUnitControls() ;
            app.NumberofcomponentsSpinner.Value = 1 ;
            app.setComponentCount(1, false) ;
            app.applyPressureFieldState() ;
            app.applyTemperatureFieldState() ;

            if ~isempty(varargin)
                materialStream = varargin{1} ;
                mode = '' ;
                streamName = '' ;
                if numel(varargin) >= 2
                    mode = string(varargin{2}) ;
                end
                if numel(varargin) >= 3
                    streamName = string(varargin{3}) ;
                end

                if strcmpi(mode, "edit") && isa(materialStream, 'Stream')
                    app.IsEditMode = true ;
                    app.TextArea.Value = { ...
                        'Edit the selected feed stream.' ; ...
                        'Modify the fields and press "Save Stream" to update or save it in the workspace.'} ;
                    app.TextArea.HorizontalAlignment = 'center' ;
                    app.CreateStreamButton.Text = 'Save Stream' ;
                    if strlength(streamName) > 0
                        app.NameEditField.Value = char(streamName) ;
                    end
                    app.displayStreamValues(materialStream) ;
                else
                    Product = materialStream ;

                    app.IsReadOnlyDisplay = true ;
                    app.NumberofcomponentsSpinner.Visible = 'off' ;
                    app.NumberofcomponentsSpinnerLabel.Visible = 'off' ;
                    app.CreateStreamButton.Visible = 'off' ;
                    app.TextArea.Value = { ...
                        'This window shows the product stream for the selected problem.' ; ...
                        'Numeric fields are locked, but unit selectors remain active so you can change the display units.'} ;
                    app.TextArea.HorizontalAlignment = 'center' ;
                    app.CheckBoxP.Visible = 'off' ;
                    app.CheckBoxT.Visible = 'off' ;
                    app.NameEditField.Value = 'Product' ;
                    app.NameEditField.Editable = 'off' ;
                    app.PhaseDropDown.Enable = 'off' ;
                    app.setNumericInputsEditable(false) ;
                    app.UITableStreamData.ColumnEditable = [false false] ;

                    if ~isempty(Product.phase)
                        app.PhaseDropDown.Value = Product.phase ;
                    end
                    app.displayStreamValues(Product) ;

                    if exist("solutionVariablesFile.mat", "file") == 2
                        delete("solutionVariablesFile.mat")
                    end
                end
            end
        end

        % Value changed function: NumberofcomponentsSpinner
        function NumberofcomponentsSpinnerValueChanged(app, event)
            components = max(1, round(app.NumberofcomponentsSpinner.Value)) ;
            app.NumberofcomponentsSpinner.Value = components ;
            app.setComponentCount(components, true) ;
        end

        % Button pushed function: CreateStreamButton
        function CreateStreamButtonPushed(app, event)
            if isempty(strtrim(app.NameEditField.Value))
                msgbox('Name edit field is empty. Please write an identifier before pushing "Create Stream".', ...
                    'Warning', 'warn') ;
                return
            end

            try
                newStream = Stream ;
                newStream.phase = app.PhaseDropDown.Value ;

                newStream.molarFlow = app.readTableColumnToSI(1, 'MolarFlow') ;
                newStream.concentration = app.readTableColumnToSI(2, 'Concentration') ;

                volumetricFlow = app.readOptionalFieldToSI(app.VolumetricFlowmsEditField) ;
                if ~isempty(volumetricFlow)
                    newStream.volumetricFlow = volumetricFlow ;
                end

                if app.CheckBoxP.Value
                    newStream.P = [] ;
                else
                    pressure = app.readOptionalFieldToSI(app.PressureEditField) ;
                    if ~isempty(pressure)
                        newStream.P = pressure ;
                    end
                end

                if app.CheckBoxT.Value
                    newStream.T = [] ;
                else
                    temperature = app.readOptionalFieldToSI(app.TemperatureEditField) ;
                    if ~isempty(temperature)
                        newStream.T = temperature ;
                    end
                end

                density = app.readOptionalFieldToSI(app.DensitykgmEditField) ;
                if ~isempty(density)
                    newStream.density = density ;
                end

                viscosity = app.readOptionalFieldToSI(app.ViscosityPasEditField) ;
                if ~isempty(viscosity)
                    newStream.viscosity = viscosity ;
                end

                newStream.molarFlow_Units = char(app.MolarFlowunitsEditField.Value) ;
                newStream.concentration_Units = char(app.ConcentrationUnitsDropDown.Value) ;
                newStream.volumetricFlow_Units = char(app.volumetricFlowUnitsEditField.Value) ;
                newStream.P_Units = char(app.PressureUnitsDropDown.Value) ;
                newStream.T_Units = char(app.TemperatureUnitsDropDown.Value) ;
                newStream.density_Units = char(app.DensityUnitsDropDown.Value) ;
                newStream.viscosity_Units = char(app.ViscosityUnitsDropDown.Value) ;

                app.Y = newStream ;
                app.DisplayedStream = newStream ;
                assignin("base", app.NameEditField.Value, app.Y)

                % Refresh in the currently selected units to show derived values too.
                app.displayStreamValues(app.Y) ;
            catch ME
                msgbox(ME.message, 'Invalid stream data', 'error') ;
            end
        end

        % Button pushed function: UnitconversionhelperButton
        function UnitconversionhelperButtonPushed(app, event)
            app.UnitsApp = unitConverterApp(app) ;
        end

        % Value changed function: CheckBoxP
        function CheckBoxPValueChanged(app, event)
            app.applyPressureFieldState() ;
        end

        % Value changed function: CheckBoxT
        function CheckBoxTValueChanged(app, event)
            app.applyTemperatureFieldState() ;
        end

        % Cell edit callback: UITableStreamData
        function UITableStreamDataCellEdit(app, event)
            indices = event.Indices ;
            newData = event.NewData ;

            if isstring(newData)
                newData = char(newData) ;
            end

            if ischar(newData)
                newData = strtrim(newData) ;
                if isempty(newData)
                    app.UITableStreamData.Data{indices(1), indices(2)} = [] ;
                    return
                end
                try
                    app.UITableStreamData.Data{indices(1), indices(2)} = ...
                        InputLayerHelper.parseArithmeticExpression(newData) ;
                catch
                    app.UITableStreamData.Data{indices(1), indices(2)} = newData ;
                end
            elseif isnumeric(newData) && isscalar(newData) && isnan(newData)
                app.UITableStreamData.Data{indices(1), indices(2)} = [] ;
            end
        end

        function ScalarFieldValueChanged(app, event)
            field = event.Source ;
            userData = field.UserData ;
            if ~isstruct(userData)
                userData = struct() ;
            end
            userData.isDirty = true ;
            field.UserData = userData ;
        end

        % Button pushed function: DefinestreamfromHysysButton
        function DefinestreamfromHysysButtonPushed(app, event)
            dialogHysysStreamApp(app) ;
        end

        % Value changed function: any unit dropdown
        function UnitDropdownValueChanged(app, event)
            source = event.Source ;
            if ~isstruct(source.UserData)
                return
            end

            userData = source.UserData ;
            oldUnit = userData.previousUnit ;
            newUnit = source.Value ;
            if strcmp(oldUnit, newUnit)
                return
            end

            if app.IsReadOnlyDisplay && isa(app.DisplayedStream, 'Stream')
                userData.previousUnit = newUnit ;
                source.UserData = userData ;
                app.renderStreamInSelectedUnits(app.DisplayedStream) ;
                return
            end

            switch userData.kind
                case 'field'
                    app.convertDisplayedFieldUnits(userData.fieldHandle, userData.category, oldUnit, newUnit) ;
                case 'table'
                    app.convertDisplayedTableUnits(userData.columnIndex, userData.category, oldUnit, newUnit) ;
            end

            userData.previousUnit = newUnit ;
            source.UserData = userData ;
        end

        function configureUnitControls(app)
            app.configureDropdown(app.MolarFlowunitsEditField, 'MolarFlow', 'table', 1) ;
            app.configureDropdown(app.ConcentrationUnitsDropDown, 'Concentration', 'table', 2) ;
            app.configureDropdown(app.volumetricFlowUnitsEditField, 'VolumetricFlow', 'field', app.VolumetricFlowmsEditField) ;
            app.configureDropdown(app.PressureUnitsDropDown, 'Pressure', 'field', app.PressureEditField) ;
            app.configureDropdown(app.TemperatureUnitsDropDown, 'Temperature', 'field', app.TemperatureEditField) ;
            app.configureDropdown(app.DensityUnitsDropDown, 'Density', 'field', app.DensitykgmEditField) ;
            app.configureDropdown(app.ViscosityUnitsDropDown, 'Viscosity', 'field', app.ViscosityPasEditField) ;

            app.VolumetricFlowmsEditField.UserData = struct( ...
                'unitCategory', 'VolumetricFlow', ...
                'unitDropdown', app.volumetricFlowUnitsEditField, ...
                'isDirty', false) ;
            app.PressureEditField.UserData = struct( ...
                'unitCategory', 'Pressure', ...
                'unitDropdown', app.PressureUnitsDropDown, ...
                'isDirty', false) ;
            app.TemperatureEditField.UserData = struct( ...
                'unitCategory', 'Temperature', ...
                'unitDropdown', app.TemperatureUnitsDropDown, ...
                'isDirty', false) ;
            app.DensitykgmEditField.UserData = struct( ...
                'unitCategory', 'Density', ...
                'unitDropdown', app.DensityUnitsDropDown, ...
                'isDirty', false) ;
            app.ViscosityPasEditField.UserData = struct( ...
                'unitCategory', 'Viscosity', ...
                'unitDropdown', app.ViscosityUnitsDropDown, ...
                'isDirty', false) ;
        end

        function renderStreamInSelectedUnits(app, materialStream)
            molarFlow = materialStream.molarFlow ;
            concentration = materialStream.concentration ;
            nComp = max([numel(molarFlow), numel(concentration), 1]) ;

            app.NumberofcomponentsSpinner.Value = nComp ;
            app.setComponentCount(nComp, false) ;

            app.writeTableColumnFromSI(1, molarFlow, 'MolarFlow', app.MolarFlowunitsEditField.Value) ;
            app.writeTableColumnFromSI(2, concentration, 'Concentration', app.ConcentrationUnitsDropDown.Value) ;

            app.writeFieldFromSI(app.VolumetricFlowmsEditField, materialStream.volumetricFlow) ;
            app.writeFieldFromSI(app.PressureEditField, materialStream.P) ;
            app.writeFieldFromSI(app.TemperatureEditField, materialStream.T) ;
            app.writeFieldFromSI(app.DensitykgmEditField, materialStream.density) ;
            app.writeFieldFromSI(app.ViscosityPasEditField, materialStream.viscosity) ;

            if ~isempty(materialStream.phase)
                app.PhaseDropDown.Value = materialStream.phase ;
            end
        end

        function configureDropdown(app, dropdown, category, kind, target)
            dropdown.Items = UnitConverterHelper.getUnits(category) ;
            dropdown.Value = UnitConverterHelper.defaultUnit(category) ;
            dropdown.ValueChangedFcn = createCallbackFcn(app, @UnitDropdownValueChanged, true) ;

            userData = struct( ...
                'category', category, ...
                'kind', kind, ...
                'previousUnit', dropdown.Value) ;

            if strcmp(kind, 'field')
                userData.fieldHandle = target ;
            else
                userData.columnIndex = target ;
            end

            dropdown.UserData = userData ;
        end

        function setComponentCount(app, components, preserveData)
            components = max(1, round(components)) ;
            oldData = app.ensureTableCellData() ;
            newData = cell(components, 2) ;

            if preserveData && ~isempty(oldData)
                nCopy = min(size(oldData, 1), components) ;
                newData(1:nCopy, :) = oldData(1:nCopy, :) ;
            end

            app.UITableStreamData.Data = newData ;
            app.UITableStreamData.RowName = app.buildRowNames(components) ;
        end

        function rowNames = buildRowNames(app, components)
            rowNames = cell(1, components) ;
            for i = 1:components
                rowNames{i} = sprintf('Component %d', i) ;
            end
        end

        function data = ensureTableCellData(app)
            data = app.UITableStreamData.Data ;
            if istable(data)
                data = table2cell(data) ;
            end
            if isempty(data)
                data = cell(max(1, round(app.NumberofcomponentsSpinner.Value)), 2) ;
            end
            if size(data, 2) < 2
                data(:, 2) = cell(size(data, 1), 1) ;
            end
            if ~iscell(data)
                data = num2cell(data) ;
            end
            app.UITableStreamData.Data = data ;
        end

        function values = readTableColumnToSI(app, columnIndex, category)
            data = app.ensureTableCellData() ;
            dropdown = app.getDropdownForTableColumn(columnIndex) ;
            values = nan(1, size(data, 1)) ;
            hasAnyValue = false ;

            for i = 1:size(data, 1)
                raw = data{i, columnIndex} ;
                if app.isMissingCell(raw)
                    continue
                end
                parsed = InputLayerHelper.parseArithmeticExpression(raw) ;
                values(i) = UnitConverterHelper.convertToSI(category, parsed, dropdown.Value) ;
                hasAnyValue = true ;
            end

            if ~hasAnyValue
                values = [] ;
            end
        end

        function value = readOptionalFieldToSI(app, field)
            userData = field.UserData ;
            raw = double(field.Value) ;
            if isempty(raw) || ~isfinite(raw)
                value = [] ;
                return
            end

            isDirty = isstruct(userData) && isfield(userData, 'isDirty') && userData.isDirty ;
            category = userData.unitCategory ;

            if strcmp(category, 'Temperature')
                if raw == 0 && ~isDirty
                    value = [] ;
                    return
                end
            else
                if raw == 0 && ~isDirty
                    value = [] ;
                    return
                end
                if raw <= 0
                    error('%s must be greater than 0 when specified.', category) ;
                end
            end

            value = InputLayerHelper.readFieldToSI(field) ;
        end

        function writeFieldFromSI(app, field, siValue)
            userData = field.UserData ;
            if isempty(siValue)
                field.Value = 0 ;
                if isstruct(userData)
                    userData.isDirty = false ;
                    field.UserData = userData ;
                end
                return
            end
            if isa(field, 'matlab.ui.control.NumericEditField')
                field.Value = UnitConverterHelper.convertFromSI( ...
                    userData.unitCategory, siValue, userData.unitDropdown.Value) ;
            else
                InputLayerHelper.setFieldFromSI(field, siValue) ;
            end
            if isstruct(userData)
                userData.isDirty = true ;
                field.UserData = userData ;
            end
        end

        function writeTableColumnFromSI(app, columnIndex, siValues, category, unitName)
            data = app.ensureTableCellData() ;
            data(:, columnIndex) = {[]} ;

            if isempty(siValues)
                app.UITableStreamData.Data = data ;
                return
            end

            values = siValues(:) ;
            nRows = max(size(data, 1), numel(values)) ;
            if size(data, 1) ~= nRows
                app.setComponentCount(nRows, true) ;
                data = app.ensureTableCellData() ;
            end

            converted = UnitConverterHelper.convertFromSI(category, values, unitName) ;
            for i = 1:numel(converted)
                if ~isnan(converted(i))
                    data{i, columnIndex} = converted(i) ;
                end
            end
            app.UITableStreamData.Data = data ;
        end

        function dropdown = getDropdownForTableColumn(app, columnIndex)
            switch columnIndex
                case 1
                    dropdown = app.MolarFlowunitsEditField ;
                case 2
                    dropdown = app.ConcentrationUnitsDropDown ;
                otherwise
                    error('Unsupported table column %d.', columnIndex) ;
            end
        end

        function tf = isMissingCell(app, raw)
            tf = isempty(raw) || (isnumeric(raw) && isscalar(raw) && isnan(raw)) ;
            if isstring(raw) || ischar(raw)
                tf = isempty(strtrim(char(raw))) ;
            end
        end

        function convertDisplayedFieldUnits(app, field, category, oldUnit, newUnit)
            userData = field.UserData ;
            raw = double(field.Value) ;
            if isempty(raw) || ~isfinite(raw)
                return
            end

            isDirty = isstruct(userData) && isfield(userData, 'isDirty') && userData.isDirty ;
            if strcmp(category, 'Temperature')
                if raw == 0 && ~isDirty
                    return
                end
            elseif raw <= 0
                return
            end

            siValue = UnitConverterHelper.convertToSI(category, raw, oldUnit) ;
            field.Value = UnitConverterHelper.convertFromSI(category, siValue, newUnit) ;
        end

        function convertDisplayedTableUnits(app, columnIndex, category, oldUnit, newUnit)
            data = app.ensureTableCellData() ;
            for i = 1:size(data, 1)
                raw = data{i, columnIndex} ;
                if app.isMissingCell(raw)
                    continue
                end
                try
                    parsed = InputLayerHelper.parseArithmeticExpression(raw) ;
                    siValue = UnitConverterHelper.convertToSI(category, parsed, oldUnit) ;
                    data{i, columnIndex} = UnitConverterHelper.convertFromSI(category, siValue, newUnit) ;
                catch
                    % Leave invalid user text untouched so it can still be corrected manually.
                end
            end
            app.UITableStreamData.Data = data ;
        end

        function applyStreamUnitPreferences(app, streamObj)
            app.setDropdownValue(app.MolarFlowunitsEditField, streamObj.molarFlow_Units) ;
            app.setDropdownValue(app.ConcentrationUnitsDropDown, streamObj.concentration_Units) ;
            app.setDropdownValue(app.volumetricFlowUnitsEditField, streamObj.volumetricFlow_Units) ;
            app.setDropdownValue(app.PressureUnitsDropDown, streamObj.P_Units) ;
            app.setDropdownValue(app.TemperatureUnitsDropDown, streamObj.T_Units) ;
            app.setDropdownValue(app.DensityUnitsDropDown, streamObj.density_Units) ;
            app.setDropdownValue(app.ViscosityUnitsDropDown, streamObj.viscosity_Units) ;
        end

        function setDropdownValue(app, dropdown, unitValue)
            if isempty(unitValue)
                targetUnit = UnitConverterHelper.defaultUnit(dropdown.UserData.category) ;
            else
                targetUnit = app.normalizeLegacyUnitName(char(unitValue)) ;
            end

            if ~any(strcmp(dropdown.Items, targetUnit))
                targetUnit = UnitConverterHelper.defaultUnit(dropdown.UserData.category) ;
            end

            dropdown.Value = targetUnit ;
            userData = dropdown.UserData ;
            userData.previousUnit = targetUnit ;
            dropdown.UserData = userData ;
        end

        function unitValue = normalizeLegacyUnitName(app, unitValue)
            switch strtrim(unitValue)
                case {'moles/s', 'gmole/s', 'gmol/s'}
                    unitValue = 'mol/s' ;
                case 'moles/min'
                    unitValue = 'mol/min' ;
                case 'moles/h'
                    unitValue = 'mol/h' ;
                case 'm3/s'
                    unitValue = 'm^3/s' ;
                case 'kg/m3'
                    unitValue = 'kg/m^3' ;
                case 'Pa-s'
                    unitValue = 'Pa*s' ;
            end
        end

        function setNumericInputsEditable(app, isEditable)
            app.UITableStreamData.ColumnEditable = [isEditable isEditable] ;
            app.setEditFieldState(app.VolumetricFlowmsEditField, isEditable) ;
            app.setEditFieldState(app.DensitykgmEditField, isEditable) ;
            app.setEditFieldState(app.ViscosityPasEditField, isEditable) ;
            app.applyPressureFieldState() ;
            app.applyTemperatureFieldState() ;
        end

        function applyPressureFieldState(app)
            editable = ~app.IsReadOnlyDisplay && ~app.CheckBoxP.Value ;
            app.setEditFieldState(app.PressureEditField, editable) ;
        end

        function applyTemperatureFieldState(app)
            editable = ~app.IsReadOnlyDisplay && ~app.CheckBoxT.Value ;
            app.setEditFieldState(app.TemperatureEditField, editable) ;
        end

        function setEditFieldState(app, field, editable)
            if editable
                field.Editable = 'on' ;
                field.BackgroundColor = [1 1 1] ;
            else
                field.Editable = 'off' ;
                field.BackgroundColor = [0.8 0.8 0.8] ;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 700 430];
            app.UIFigure.Name = 'Define Stream';

            % Create StreamLabel
            app.StreamLabel = uilabel(app.UIFigure);
            app.StreamLabel.HorizontalAlignment = 'center';
            app.StreamLabel.FontName = 'Arial';
            app.StreamLabel.FontSize = 16;
            app.StreamLabel.FontWeight = 'bold';
            app.StreamLabel.Position = [245 393 210 25];
            app.StreamLabel.Text = 'Stream';

            % Create NameEditFieldLabel
            app.NameEditFieldLabel = uilabel(app.UIFigure);
            app.NameEditFieldLabel.HorizontalAlignment = 'right';
            app.NameEditFieldLabel.FontWeight = 'bold';
            app.NameEditFieldLabel.Position = [505 325 38 22];
            app.NameEditFieldLabel.Text = 'Name';

            % Create NameEditField
            app.NameEditField = uieditfield(app.UIFigure, 'text');
            app.NameEditField.Tooltip = {'Choose a name to identify the stream'};
            app.NameEditField.Position = [558 325 115 22];

            % Create UITableStreamData
            app.UITableStreamData = uitable(app.UIFigure);
            app.UITableStreamData.ColumnName = {'Molar Flow'; 'Concentration'};
            app.UITableStreamData.ColumnWidth = {120, 120};
            app.UITableStreamData.RowName = {};
            app.UITableStreamData.ColumnEditable = true;
            app.UITableStreamData.CellEditCallback = createCallbackFcn(app, @UITableStreamDataCellEdit, true);
            app.UITableStreamData.Position = [38 52 285 168];

            % Create MolarFlowunitsEditFieldLabel
            app.MolarFlowunitsEditFieldLabel = uilabel(app.UIFigure);
            app.MolarFlowunitsEditFieldLabel.HorizontalAlignment = 'center';
            app.MolarFlowunitsEditFieldLabel.Position = [38 29 120 22];
            app.MolarFlowunitsEditFieldLabel.Text = 'Molar Flow Units';

            % Create MolarFlowunitsEditField
            app.MolarFlowunitsEditField = uidropdown(app.UIFigure);
            app.MolarFlowunitsEditField.Position = [38 8 120 22];

            % Create ConcentrationUnitsDropDownLabel
            app.ConcentrationUnitsDropDownLabel = uilabel(app.UIFigure);
            app.ConcentrationUnitsDropDownLabel.HorizontalAlignment = 'center';
            app.ConcentrationUnitsDropDownLabel.Position = [171 29 120 22];
            app.ConcentrationUnitsDropDownLabel.Text = 'Concentration Units';

            % Create ConcentrationUnitsDropDown
            app.ConcentrationUnitsDropDown = uidropdown(app.UIFigure);
            app.ConcentrationUnitsDropDown.Position = [171 8 120 22];

            % Create VolumetricFlowmsEditFieldLabel
            app.VolumetricFlowmsEditFieldLabel = uilabel(app.UIFigure);
            app.VolumetricFlowmsEditFieldLabel.HorizontalAlignment = 'right';
            app.VolumetricFlowmsEditFieldLabel.Position = [357 178 100 22];
            app.VolumetricFlowmsEditFieldLabel.Text = 'Volumetric Flow';

            % Create VolumetricFlowmsEditField
            app.VolumetricFlowmsEditField = uieditfield(app.UIFigure, 'numeric');
            app.VolumetricFlowmsEditField.Tooltip = {'Internal calculations use SI units.'; 'These controls convert only the UI input/output layer.'};
            app.VolumetricFlowmsEditField.ValueChangedFcn = createCallbackFcn(app, @ScalarFieldValueChanged, true);
            app.VolumetricFlowmsEditField.Position = [472 178 90 22];

            % Create UnitsEditField_3Label
            app.UnitsEditField_3Label = uilabel(app.UIFigure);
            app.UnitsEditField_3Label.HorizontalAlignment = 'center';
            app.UnitsEditField_3Label.Position = [569 157 90 22];
            app.UnitsEditField_3Label.Text = 'Flow Units';

            % Create volumetricFlowUnitsEditField
            app.volumetricFlowUnitsEditField = uidropdown(app.UIFigure);
            app.volumetricFlowUnitsEditField.Position = [569 178 100 22];

            % Create PPaEditFieldLabel
            app.PPaEditFieldLabel = uilabel(app.UIFigure);
            app.PPaEditFieldLabel.HorizontalAlignment = 'right';
            app.PPaEditFieldLabel.Position = [417 251 40 22];
            app.PPaEditFieldLabel.Text = 'P';

            % Create PressureEditField
            app.PressureEditField = uieditfield(app.UIFigure, 'numeric');
            app.PressureEditField.ValueChangedFcn = createCallbackFcn(app, @ScalarFieldValueChanged, true);
            app.PressureEditField.Position = [472 251 90 22];

            % Create PressureUnitsDropDown
            app.PressureUnitsDropDown = uidropdown(app.UIFigure);
            app.PressureUnitsDropDown.Position = [569 251 100 22];

            % Create TKEditFieldLabel
            app.TKEditFieldLabel = uilabel(app.UIFigure);
            app.TKEditFieldLabel.HorizontalAlignment = 'right';
            app.TKEditFieldLabel.Position = [425 217 32 22];
            app.TKEditFieldLabel.Text = 'T';

            % Create TemperatureEditField
            app.TemperatureEditField = uieditfield(app.UIFigure, 'numeric');
            app.TemperatureEditField.ValueChangedFcn = createCallbackFcn(app, @ScalarFieldValueChanged, true);
            app.TemperatureEditField.Position = [472 217 90 22];

            % Create TemperatureUnitsDropDown
            app.TemperatureUnitsDropDown = uidropdown(app.UIFigure);
            app.TemperatureUnitsDropDown.Position = [569 217 100 22];

            % Create DensitykgmEditFieldLabel
            app.DensitykgmEditFieldLabel = uilabel(app.UIFigure);
            app.DensitykgmEditFieldLabel.HorizontalAlignment = 'right';
            app.DensitykgmEditFieldLabel.Position = [412 138 45 22];
            app.DensitykgmEditFieldLabel.Text = 'Density';

            % Create DensitykgmEditField
            app.DensitykgmEditField = uieditfield(app.UIFigure, 'numeric');
            app.DensitykgmEditField.ValueChangedFcn = createCallbackFcn(app, @ScalarFieldValueChanged, true);
            app.DensitykgmEditField.Position = [472 138 90 22];

            % Create DensityUnitsDropDown
            app.DensityUnitsDropDown = uidropdown(app.UIFigure);
            app.DensityUnitsDropDown.Position = [569 138 100 22];

            % Create ViscosityPasEditFieldLabel
            app.ViscosityPasEditFieldLabel = uilabel(app.UIFigure);
            app.ViscosityPasEditFieldLabel.HorizontalAlignment = 'right';
            app.ViscosityPasEditFieldLabel.Position = [405 103 52 22];
            app.ViscosityPasEditFieldLabel.Text = 'Viscosity';

            % Create ViscosityPasEditField
            app.ViscosityPasEditField = uieditfield(app.UIFigure, 'numeric');
            app.ViscosityPasEditField.ValueChangedFcn = createCallbackFcn(app, @ScalarFieldValueChanged, true);
            app.ViscosityPasEditField.Position = [472 103 90 22];

            % Create ViscosityUnitsDropDown
            app.ViscosityUnitsDropDown = uidropdown(app.UIFigure);
            app.ViscosityUnitsDropDown.Position = [569 103 100 22];

            % Create CreateStreamButton
            app.CreateStreamButton = uibutton(app.UIFigure, 'push');
            app.CreateStreamButton.ButtonPushedFcn = createCallbackFcn(app, @CreateStreamButtonPushed, true);
            app.CreateStreamButton.FontSize = 16;
            app.CreateStreamButton.FontWeight = 'bold';
            app.CreateStreamButton.Position = [448 37 170 30];
            app.CreateStreamButton.Text = 'Create Stream';

            % Create NumberofcomponentsSpinnerLabel
            app.NumberofcomponentsSpinnerLabel = uilabel(app.UIFigure);
            app.NumberofcomponentsSpinnerLabel.HorizontalAlignment = 'right';
            app.NumberofcomponentsSpinnerLabel.Position = [38 234 130 22];
            app.NumberofcomponentsSpinnerLabel.Text = 'Number of components';

            % Create NumberofcomponentsSpinner
            app.NumberofcomponentsSpinner = uispinner(app.UIFigure);
            app.NumberofcomponentsSpinner.Limits = [1 Inf];
            app.NumberofcomponentsSpinner.Value = 1;
            app.NumberofcomponentsSpinner.ValueChangedFcn = createCallbackFcn(app, @NumberofcomponentsSpinnerValueChanged, true);
            app.NumberofcomponentsSpinner.Position = [183 234 100 22];

            % Create CheckBoxP
            app.CheckBoxP = uicheckbox(app.UIFigure);
            app.CheckBoxP.ValueChangedFcn = createCallbackFcn(app, @CheckBoxPValueChanged, true);
            app.CheckBoxP.Text = '';
            app.CheckBoxP.Position = [392 253 16 18];

            % Create CheckBoxT
            app.CheckBoxT = uicheckbox(app.UIFigure);
            app.CheckBoxT.ValueChangedFcn = createCallbackFcn(app, @CheckBoxTValueChanged, true);
            app.CheckBoxT.Text = '';
            app.CheckBoxT.Position = [392 219 16 18];

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.Editable = 'off';
            app.TextArea.FontColor = [0.0745 0.6235 1];
            app.TextArea.BackgroundColor = [0.9412 0.9412 0.9412];
            app.TextArea.Position = [38 280 310 93];
            app.TextArea.Value = { ...
                'TIPS'; ...
                'Select one unit per composition column and one per scalar field.'; ...
                'Leave cells blank if the stream should deduce that magnitude automatically.'; ...
                'Use the P/T checkboxes only when those properties are intentionally unspecified.'};

            % Create PhaseDropDownLabel
            app.PhaseDropDownLabel = uilabel(app.UIFigure);
            app.PhaseDropDownLabel.HorizontalAlignment = 'right';
            app.PhaseDropDownLabel.Position = [503 291 40 22];
            app.PhaseDropDownLabel.Text = 'Phase';

            % Create PhaseDropDown
            app.PhaseDropDown = uidropdown(app.UIFigure);
            app.PhaseDropDown.Items = {'L', 'G'};
            app.PhaseDropDown.Tooltip = {'Select ''L'' for liquid phase or ''G'' for gas phase.'};
            app.PhaseDropDown.Position = [558 291 111 22];
            app.PhaseDropDown.Value = 'L';

            % Create UnitconversionhelperButton
            app.UnitconversionhelperButton = uibutton(app.UIFigure, 'push');
            app.UnitconversionhelperButton.ButtonPushedFcn = createCallbackFcn(app, @UnitconversionhelperButtonPushed, true);
            app.UnitconversionhelperButton.Icon = 'UnitsLogo.png';
            app.UnitconversionhelperButton.Position = [1 397 164 22];
            app.UnitconversionhelperButton.Text = 'Unit conversion helper';

            % Create DefinestreamfromHysysButton
            app.DefinestreamfromHysysButton = uibutton(app.UIFigure, 'push');
            app.DefinestreamfromHysysButton.ButtonPushedFcn = createCallbackFcn(app, @DefinestreamfromHysysButtonPushed, true);
            app.DefinestreamfromHysysButton.Icon = 'HysysLogo.png';
            app.DefinestreamfromHysysButton.Position = [487 397 200 22];
            app.DefinestreamfromHysysButton.Text = 'Define stream from Hysys';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = defineStreamApp(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
