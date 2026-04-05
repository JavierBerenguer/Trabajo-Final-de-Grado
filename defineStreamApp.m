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
        ViscosityPasEditField           matlab.ui.control.NumericEditField
        ViscosityPasEditFieldLabel      matlab.ui.control.Label
        DensitykgmEditField             matlab.ui.control.NumericEditField
        DensitykgmEditFieldLabel        matlab.ui.control.Label
        TemperatureEditField            matlab.ui.control.NumericEditField
        TKEditFieldLabel                matlab.ui.control.Label
        PressureEditField               matlab.ui.control.NumericEditField
        PPaEditFieldLabel               matlab.ui.control.Label
        volumetricFlowUnitsEditField    matlab.ui.control.EditField
        UnitsEditField_3Label           matlab.ui.control.Label
        VolumetricFlowmsEditField       matlab.ui.control.NumericEditField
        VolumetricFlowmsEditFieldLabel  matlab.ui.control.Label
        MolarFlowunitsEditField         matlab.ui.control.EditField
        MolarFlowunitsEditFieldLabel    matlab.ui.control.Label
        UITableStreamData               matlab.ui.control.Table
        NameEditField                   matlab.ui.control.EditField
        NameEditFieldLabel              matlab.ui.control.Label
        StreamLabel                     matlab.ui.control.Label
    end

    
    properties (Access = public)
        Y = Stream ; % Create a Stream class object
        UnitsApp
    end
    
    
    methods (Access = public)
        
        function displayStreamValues(app,materialStream)
            
            if isa(materialStream,'Stream')
                app.UITableStreamData.Data = array2table([materialStream.molarFlow' , materialStream.concentration']) ;
                rowNames = cell(1,length(materialStream.molarFlow)) ;
                for i=1:length(materialStream.molarFlow)
                    rowNames{i} = string(['Component ',num2str(i)]) ;
                end
                app.UITableStreamData.RowName = rowNames ;
                
                if ~isempty(materialStream.molarFlow_Units)
                    app.MolarFlowunitsEditField.Value = materialStream.molarFlow_Units ;
                end
                
                app.VolumetricFlowmsEditField.Value = materialStream.volumetricFlow ;
                if ~isempty(materialStream.volumetricFlow_Units)
                    app.volumetricFlowUnistEditField.Value = materialStream.volumetricFlow_Units ;
                end
                app.PressureEditField.Value = materialStream.P ;
                app.TemperatureEditField.Value = materialStream.T ;
                if ~isempty(materialStream.density)
                    app.DensitykgmEditField.Value = materialStream.density ;
                end
                if ~isempty(materialStream.viscosity)
                    app.ViscosityPasEditField.Value = materialStream.viscosity ;
                end
                if ~isempty(materialStream.phase)
                    app.PhaseDropDown.Value = materialStream.phase ;
                end
                
            end
            
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, varargin)
            app.UITableStreamData.ColumnEditable = logical(true) ;
            
            if ~isempty(varargin)
                Product = varargin{1} ;
                
                app.NumberofcomponentsSpinner.Visible = 'off' ;
                app.CreateStreamButton.Visible = 'off' ;
                app.TextArea.Value = newline + "This window is showing the product stream which gives the solution to the given problem" ;
                app.TextArea.HorizontalAlignment = 'center' ;
                app.CheckBoxP.Visible = 'off' ;
                app.CheckBoxT.Visible = 'off' ;
                app.NameEditField.Value = 'Product' ;
                app.PhaseDropDown.Value = Product.phase ;
                
                app.displayStreamValues(Product);
                
                % Delete .mat file that stored variable ProductData
                delete("solutionVariablesFile.mat")
            end
            
        end

        % Value changed function: NumberofcomponentsSpinner
        function NumberofcomponentsSpinnerValueChanged(app, event)
            components = app.NumberofcomponentsSpinner.Value;
            
            % Sizing UITableStreamData
            %             app.UITableStreamData.Data = table('Size',[components,2],'VariableTypes',{'double','double'}) ;
            app.UITableStreamData.Data = cell(components,2) ;
            rowNames = cell(1,components) ;
            for i=1:components
                rowNames{i} = string(['Component ',num2str(i)]) ;
            end
            app.UITableStreamData.RowName = rowNames ;
            
        end

        % Button pushed function: CreateStreamButton
        function CreateStreamButtonPushed(app, event)
            if isempty(app.NameEditField.Value)
                msgbox('Name edit field is empty. Please, write an identifier before pushing "Create Stream" button', 'Warning','warn');
            else
                molarFlowCell = app.UITableStreamData.Data(:,1) ;
                concentrationCell = app.UITableStreamData.Data(:,2) ;
                
                app.Y.phase = app.PhaseDropDown.Value ;
                
                if ~isempty(cell2mat(molarFlowCell))
                    for i = 1:length(molarFlowCell)
                        if isempty(molarFlowCell{i})
                            molarFlowCell{i} = NaN ;
                        end
                        app.Y.molarFlow = (cell2mat(molarFlowCell))' ;
                    end
                end
                
                if ~isempty(cell2mat(concentrationCell))
                    for i = 1:length(concentrationCell)
                        if isempty(concentrationCell{i})
                            concentrationCell{i} = NaN ;
                        end
                        app.Y.concentration = (cell2mat(concentrationCell))' ;
                    end
                end
                
                if app.VolumetricFlowmsEditField.Value > 0
                    app.Y.volumetricFlow = app.VolumetricFlowmsEditField.Value ;
                end
                
                if app.PressureEditField.Value > 0
                    app.Y.P = app.PressureEditField.Value ;
                elseif app.CheckBoxP.Value
                    app.Y.P = [] ;
                end
                
                if app.TemperatureEditField.Value > 0
                    app.Y.T = app.TemperatureEditField.Value ;
                elseif app.CheckBoxT.Value
                    app.Y.T = [] ;
                end
                if app.DensitykgmEditField.Value > 0
                    app.Y.density = app.DensitykgmEditField.Value ;
                end
                if app.ViscosityPasEditField.Value > 0
                    app.Y.viscosity = app.ViscosityPasEditField.Value ;
                end
                
                assignin("base",app.NameEditField.Value,app.Y)
                
                % Display authomatically calculated values that were not specified
                if sum(isempty(app.Y.molarFlow)) == 0
                    for i = 1 : length(app.Y.molarFlow)
                        if ~isnan(app.Y.molarFlow(i))
                            app.UITableStreamData.Data{i,1} = app.Y.molarFlow(i) ;
                        end
                    end
                end
                
                if sum(isempty(app.Y.concentration)) == 0
                    for i = 1 : length(app.Y.concentration)
                        if ~isnan(app.Y.concentration(i))
                            app.UITableStreamData.Data{i,2} = app.Y.concentration(i) ;
                        end
                    end
                end
                
                if app.VolumetricFlowmsEditField.Value == 0
                    if ~isnan(app.Y.volumetricFlow)
                        app.VolumetricFlowmsEditField.Value = app.Y.volumetricFlow ;
                    end
                end
            end
        end

        % Button pushed function: UnitconversionhelperButton
        function UnitconversionhelperButtonPushed(app, event)
            app.UnitsApp = unitConverterApp(app) ;
        end

        % Value changed function: CheckBoxP
        function CheckBoxPValueChanged(app, event)
            if app.CheckBoxP.Value
                app.PressureEditField.BackgroundColor = [0.8 0.8 0.8] ;
                app.PressureEditField.Editable = 'off' ;
            else
                app.PressureEditField.BackgroundColor = [1,1,1] ;
                app.PressureEditField.Editable = 'on' ;
            end
        end

        % Value changed function: CheckBoxT
        function CheckBoxTValueChanged(app, event)
            if app.CheckBoxT.Value
                app.TemperatureEditField.BackgroundColor = [0.8 0.8 0.8] ;
                app.TemperatureEditField.Editable = 'off' ;
            else
                app.TemperatureEditField.BackgroundColor = [1,1,1] ;
                app.TemperatureEditField.Editable = 'on' ;
            end
        end

        % Cell edit callback: UITableStreamData
        function UITableStreamDataCellEdit(app, event)
            indices = event.Indices;
            newData = event.NewData;
            if isa(newData,'char')
                app.UITableStreamData.Data{indices(1),indices(2)} = str2double(newData) ;
            elseif isnan(newData)
                app.UITableStreamData.Data{indices(1),indices(2)} = [] ;
            end
        end

        % Button pushed function: DefinestreamfromHysysButton
        function DefinestreamfromHysysButtonPushed(app, event)
            dialogHysysStreamApp(app) ;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 621 413];
            app.UIFigure.Name = 'UI Figure';

            % Create StreamLabel
            app.StreamLabel = uilabel(app.UIFigure);
            app.StreamLabel.HorizontalAlignment = 'center';
            app.StreamLabel.FontName = 'Arial';
            app.StreamLabel.FontSize = 16;
            app.StreamLabel.FontWeight = 'bold';
            app.StreamLabel.Position = [200 389 242 25];
            app.StreamLabel.Text = 'Stream';

            % Create NameEditFieldLabel
            app.NameEditFieldLabel = uilabel(app.UIFigure);
            app.NameEditFieldLabel.HorizontalAlignment = 'right';
            app.NameEditFieldLabel.FontWeight = 'bold';
            app.NameEditFieldLabel.Position = [428 325 38 22];
            app.NameEditFieldLabel.Text = 'Name';

            % Create NameEditField
            app.NameEditField = uieditfield(app.UIFigure, 'text');
            app.NameEditField.Tooltip = {'Choose a name to identify the stream'};
            app.NameEditField.Position = [481 325 100 22];

            % Create UITableStreamData
            app.UITableStreamData = uitable(app.UIFigure);
            app.UITableStreamData.ColumnName = {'Molar Flow'; 'Concentration'};
            app.UITableStreamData.ColumnWidth = {100, 100};
            app.UITableStreamData.RowName = {};
            app.UITableStreamData.ColumnEditable = true;
            app.UITableStreamData.CellEditCallback = createCallbackFcn(app, @UITableStreamDataCellEdit, true);
            app.UITableStreamData.Tooltip = {''};
            app.UITableStreamData.Position = [38 37 273 183];

            % Create MolarFlowunitsEditFieldLabel
            app.MolarFlowunitsEditFieldLabel = uilabel(app.UIFigure);
            app.MolarFlowunitsEditFieldLabel.HorizontalAlignment = 'right';
            app.MolarFlowunitsEditFieldLabel.Visible = 'off';
            app.MolarFlowunitsEditFieldLabel.Position = [38 13 93 22];
            app.MolarFlowunitsEditFieldLabel.Text = 'Molar Flow units';

            % Create MolarFlowunitsEditField
            app.MolarFlowunitsEditField = uieditfield(app.UIFigure, 'text');
            app.MolarFlowunitsEditField.Visible = 'off';
            app.MolarFlowunitsEditField.Position = [146 13 100 22];

            % Create VolumetricFlowmsEditFieldLabel
            app.VolumetricFlowmsEditFieldLabel = uilabel(app.UIFigure);
            app.VolumetricFlowmsEditFieldLabel.HorizontalAlignment = 'right';
            app.VolumetricFlowmsEditFieldLabel.Position = [342 178 125 22];
            app.VolumetricFlowmsEditFieldLabel.Text = 'Volumetric Flow (m³/s)';

            % Create VolumetricFlowmsEditField
            app.VolumetricFlowmsEditField = uieditfield(app.UIFigure, 'numeric');
            app.VolumetricFlowmsEditField.Tooltip = {'It is advisable to use SI units because all the operations use the gas constant as:'; 'R = 8,314 Pa·m^3/mol/K'};
            app.VolumetricFlowmsEditField.Position = [482 178 100 22];

            % Create UnitsEditField_3Label
            app.UnitsEditField_3Label = uilabel(app.UIFigure);
            app.UnitsEditField_3Label.HorizontalAlignment = 'right';
            app.UnitsEditField_3Label.Visible = 'off';
            app.UnitsEditField_3Label.Position = [434 157 33 22];
            app.UnitsEditField_3Label.Text = 'Units';

            % Create volumetricFlowUnitsEditField
            app.volumetricFlowUnitsEditField = uieditfield(app.UIFigure, 'text');
            app.volumetricFlowUnitsEditField.Visible = 'off';
            app.volumetricFlowUnitsEditField.Position = [482 157 100 22];

            % Create PPaEditFieldLabel
            app.PPaEditFieldLabel = uilabel(app.UIFigure);
            app.PPaEditFieldLabel.HorizontalAlignment = 'right';
            app.PPaEditFieldLabel.Position = [428 251 40 22];
            app.PPaEditFieldLabel.Text = 'P (Pa)';

            % Create PressureEditField
            app.PressureEditField = uieditfield(app.UIFigure, 'numeric');
            app.PressureEditField.Position = [483 251 100 22];

            % Create TKEditFieldLabel
            app.TKEditFieldLabel = uilabel(app.UIFigure);
            app.TKEditFieldLabel.HorizontalAlignment = 'right';
            app.TKEditFieldLabel.Position = [436 217 32 22];
            app.TKEditFieldLabel.Text = 'T (K)';

            % Create TemperatureEditField
            app.TemperatureEditField = uieditfield(app.UIFigure, 'numeric');
            app.TemperatureEditField.Position = [483 217 100 22];

            % Create DensitykgmEditFieldLabel
            app.DensitykgmEditFieldLabel = uilabel(app.UIFigure);
            app.DensitykgmEditFieldLabel.HorizontalAlignment = 'right';
            app.DensitykgmEditFieldLabel.Position = [381 138 87 22];
            app.DensitykgmEditFieldLabel.Text = 'Density (kg/m³)';

            % Create DensitykgmEditField
            app.DensitykgmEditField = uieditfield(app.UIFigure, 'numeric');
            app.DensitykgmEditField.Position = [483 138 100 22];

            % Create ViscosityPasEditFieldLabel
            app.ViscosityPasEditFieldLabel = uilabel(app.UIFigure);
            app.ViscosityPasEditFieldLabel.HorizontalAlignment = 'right';
            app.ViscosityPasEditFieldLabel.Position = [379 103 89 22];
            app.ViscosityPasEditFieldLabel.Text = 'Viscosity (Pa·s)';

            % Create ViscosityPasEditField
            app.ViscosityPasEditField = uieditfield(app.UIFigure, 'numeric');
            app.ViscosityPasEditField.Position = [483 103 100 22];

            % Create CreateStreamButton
            app.CreateStreamButton = uibutton(app.UIFigure, 'push');
            app.CreateStreamButton.ButtonPushedFcn = createCallbackFcn(app, @CreateStreamButtonPushed, true);
            app.CreateStreamButton.FontSize = 16;
            app.CreateStreamButton.FontWeight = 'bold';
            app.CreateStreamButton.Position = [407 37 145 28];
            app.CreateStreamButton.Text = 'Create Stream';

            % Create NumberofcomponentsSpinnerLabel
            app.NumberofcomponentsSpinnerLabel = uilabel(app.UIFigure);
            app.NumberofcomponentsSpinnerLabel.HorizontalAlignment = 'right';
            app.NumberofcomponentsSpinnerLabel.Position = [38 234 130 22];
            app.NumberofcomponentsSpinnerLabel.Text = 'Number of components';

            % Create NumberofcomponentsSpinner
            app.NumberofcomponentsSpinner = uispinner(app.UIFigure);
            app.NumberofcomponentsSpinner.Limits = [0 Inf];
            app.NumberofcomponentsSpinner.ValueChangedFcn = createCallbackFcn(app, @NumberofcomponentsSpinnerValueChanged, true);
            app.NumberofcomponentsSpinner.Position = [183 234 100 22];

            % Create CheckBoxP
            app.CheckBoxP = uicheckbox(app.UIFigure);
            app.CheckBoxP.ValueChangedFcn = createCallbackFcn(app, @CheckBoxPValueChanged, true);
            app.CheckBoxP.Text = '';
            app.CheckBoxP.Position = [407 253 16 18];

            % Create CheckBoxT
            app.CheckBoxT = uicheckbox(app.UIFigure);
            app.CheckBoxT.ValueChangedFcn = createCallbackFcn(app, @CheckBoxTValueChanged, true);
            app.CheckBoxT.Text = '';
            app.CheckBoxT.Position = [407 219 16 18];

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.Editable = 'off';
            app.TextArea.FontColor = [0.0745 0.6235 1];
            app.TextArea.BackgroundColor = [0.9412 0.9412 0.9412];
            app.TextArea.Position = [38 280 310 93];
            app.TextArea.Value = {'TIPS'; 'If a PRODUCT stream is being defined and you do not want to specify :'; '  - P or T >> select the check box.'; '  - The composition of any species >> simply do not enter any data in the corresponding cell'};

            % Create PhaseDropDownLabel
            app.PhaseDropDownLabel = uilabel(app.UIFigure);
            app.PhaseDropDownLabel.HorizontalAlignment = 'right';
            app.PhaseDropDownLabel.Position = [427 291 40 22];
            app.PhaseDropDownLabel.Text = 'Phase';

            % Create PhaseDropDown
            app.PhaseDropDown = uidropdown(app.UIFigure);
            app.PhaseDropDown.Items = {'L', 'G'};
            app.PhaseDropDown.Tooltip = {'Select ''L'' if liquid phase or ''G'' if gas phase'};
            app.PhaseDropDown.Position = [482 291 100 22];
            app.PhaseDropDown.Value = 'L';

            % Create UnitconversionhelperButton
            app.UnitconversionhelperButton = uibutton(app.UIFigure, 'push');
            app.UnitconversionhelperButton.ButtonPushedFcn = createCallbackFcn(app, @UnitconversionhelperButtonPushed, true);
            app.UnitconversionhelperButton.Icon = 'UnitsLogo.png';
            app.UnitconversionhelperButton.Position = [1 392 164 22];
            app.UnitconversionhelperButton.Text = 'Unit conversion helper';

            % Create DefinestreamfromHysysButton
            app.DefinestreamfromHysysButton = uibutton(app.UIFigure, 'push');
            app.DefinestreamfromHysysButton.ButtonPushedFcn = createCallbackFcn(app, @DefinestreamfromHysysButtonPushed, true);
            app.DefinestreamfromHysysButton.Icon = 'HysysLogo.png';
            app.DefinestreamfromHysysButton.Position = [432 392 190 22];
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