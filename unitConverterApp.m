classdef unitConverterApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        AddrowButton               matlab.ui.control.Button
        DropDown4                  matlab.ui.control.DropDown
        DropDown4Label             matlab.ui.control.Label
        DropDown3                  matlab.ui.control.DropDown
        DropDown3Label             matlab.ui.control.Label
        DesiredUnitsLabel          matlab.ui.control.Label
        OutputUnitsEditField       matlab.ui.control.EditField
        DropDown2                  matlab.ui.control.DropDown
        DropDown2Label             matlab.ui.control.Label
        DropDown                   matlab.ui.control.DropDown
        DropDownLabel              matlab.ui.control.Label
        InputUnitsEditField        matlab.ui.control.EditField
        InitialUnitsLabel          matlab.ui.control.Label
        PropertiesListBox          matlab.ui.control.ListBox
        PropertiesListBoxLabel     matlab.ui.control.Label
        convertedDataTable         matlab.ui.control.Table
        ConvertButton              matlab.ui.control.Button
        initialDataTable           matlab.ui.control.Table
        UnitconversionhelperLabel  matlab.ui.control.Label
    end

    
    methods (Access = public)
        
        function dropDownVisibility(app,state)
            app.InputUnitsEditField.Visible = 'off' ;
            app.OutputUnitsEditField.Visible = 'off' ;
            
            nDropDown = 1:4 ;
            for i = 1:length(nDropDown)
                switch nDropDown(i)
                    case 1
                        app.DropDown.Visible = state{i} ;
                        app.DropDownLabel.Visible = state{i} ;
                    case 2
                        app.DropDown2.Visible = state{i} ;
                        app.DropDown2Label.Visible = state{i} ;
                    case 3
                        app.DropDown3.Visible = state{i} ;
                        app.DropDown3Label.Visible = state{i} ;
                    case 4
                        app.DropDown4.Visible = state{i} ;
                        app.DropDown4Label.Visible = state{i} ;
                end
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, varargin)
            app.initialDataTable.Data = table(0) ;
            app.initialDataTable.ColumnEditable = logical(true) ;
            
            app.dropDownVisibility({'off','off','off','off'}) ;
            app.InputUnitsEditField.Visible = 'off' ;
            app.OutputUnitsEditField.Visible = 'off' ;
        end

        % Button pushed function: AddrowButton
        function AddrowButtonPushed(app, event)
            newTable = [app.initialDataTable.Data ; table(0)] ;
            app.initialDataTable.Data = newTable ;
            app.initialDataTable.ColumnEditable = logical(true) ;
        end

        % Button pushed function: ConvertButton
        function ConvertButtonPushed(app, event)
            u = cmu.unit.simple_units ;
            initialData = table2array(app.initialDataTable.Data) ;
            clear app.convertedDataTable.Data
            
            switch app.PropertiesListBox.Value
                case {'Pressure','Volume'}
                    initialUnits = eval(string(['initialData*u.',app.DropDown.Value])) ;
                    convertedUnits = eval(string(['initialUnits/u.',app.DropDown3.Value])) ;
                case 'Temperature'
                    combination = string([app.DropDown.Value ,'to', app.DropDown3.Value]) ; 
                    switch combination
                        case 'KtoC'
                            convertedUnits = initialData - 273.15 ;
                        case 'KtoF'
                            initialUnits = initialData - 273.15 ;
                            convertedUnits = u.degC2F(initialUnits) ;
                        case 'CtoK'
                            convertedUnits = initialData + 273.15 ;
                        case 'CtoF'
                            convertedUnits = u.degC2F(initialData) ;
                        case 'FtoK'
                            initialUnits = u.degF2C(initialData) ;
                            convertedUnits = initialUnits + 273.15 ;
                        case 'FtoC'
                            convertedUnits = u.degF2C(initialData) ;
                    end
                    
                case {'Molar Flow','Concentration','Enthalpy','Cp','Activation energy'}
                    initialUnits = eval(string(['initialData*(u.',app.DropDown.Value,'/u.',app.DropDown2.Value,')'])) ;
                    convertedUnits = eval(string(['initialUnits/(u.',app.DropDown3.Value,'/u.',app.DropDown4.Value,')'])) ;
                    
                case 'Kinetic constant'
                    initialUnits = eval(string(['initialData*',app.InputUnitsEditField.Value])) ;
                    convertedUnits = eval(string(['initialUnits/(',app.OutputUnitsEditField.Value,')'])) ;
            end
            
            app.convertedDataTable.Visible = 'on' ;
            app.convertedDataTable.Data = array2table(convertedUnits) ;
        end

        % Value changed function: PropertiesListBox
        function PropertiesListBoxValueChanged(app, event)
            physicalProperty = app.PropertiesListBox.Value;
            
            switch physicalProperty
                case 'Pressure'
                    app.dropDownVisibility({'on','off','on','off'}) ;
                    app.DropDownLabel.Text = '' ;
                    app.DropDown.Items = {'','atm','Pa','kPa','MPa','GPa','torr','mtorr','bar','mbar','psi','mmHg'} ;
                    
                    app.DropDown3Label.Text = '' ;
                    app.DropDown3.Items =  {'','atm','Pa','kPa','MPa','GPa','torr','mtorr','bar','mbar','psi','mmHg'} ;
                case 'Temperature'
                    app.dropDownVisibility({'on','off','on','off'}) ;
                    app.DropDownLabel.Text = '' ;
                    app.DropDown.Items = {'','K','C','F'} ;
                    
                    app.DropDown3Label.Text = '' ;
                    app.DropDown3.Items = {'','K','C','F'} ;
                case 'Volume'
                    app.dropDownVisibility({'on','off','on','off'}) ;
                    app.DropDownLabel.Text = '' ;
                    app.DropDown.Items =  {'','L','mL','m^3','dm^3','cm^3','ft^3'} ;
                    
                    app.DropDown3Label.Text = '' ;
                    app.DropDown3.Items =  {'','L','mL','m^3','dm^3','cm^3','ft^3'} ;
                case 'Molar Flow'
                    app.dropDownVisibility({'on','on','on','on'}) ;
                    app.DropDownLabel.Text = 'Molar basis' ;
                    app.DropDown.Items = {'','mol','kmol','mmol','kgmol','gmmol','lbmol'} ;
                    
                    app.DropDown2Label.Text = 'Time basis' ;
                    app.DropDown2.Items = {'','s','min','hr','week','year'} ;
                    
                    app.DropDown3Label.Text = 'Molar basis' ;
                    app.DropDown3.Items = {'','mol','kmol','mmol','kgmol','gmmol','lbmol'} ;
                    
                    app.DropDown4Label.Text = 'Time basis' ;
                    app.DropDown4.Items = {'','s','min','hr','week','year'} ;
                case 'Concentration'
                    app.dropDownVisibility({'on','on','on','on'}) ;
                    app.DropDownLabel.Text = 'Molar basis' ;
                    app.DropDown.Items = {'','mol','kmol','mmol','kgmol','gmmol','lbmol'} ;
                    
                    app.DropDown2Label.Text = 'Volume basis' ;
                    app.DropDown2.Items = {'','L','mL','m^3','dm^3','cm^3','ft^3'} ;
                    
                    app.DropDown3Label.Text = 'Molar basis' ;
                    app.DropDown3.Items = {'','mol','kmol','mmol','kgmol','gmmol','lbmol'} ;
                    
                    app.DropDown4Label.Text = 'Volume basis' ;
                    app.DropDown4.Items = {'','L','mL','m^3','dm^3','cm^3','ft^3'} ;
                case {'Enthalpy','Cp','Activation energy'}
                    app.dropDownVisibility({'on','on','on','on'}) ;
                    app.DropDownLabel.Text = 'Energy basis' ;
                    app.DropDown.Items = {'','J','kJ','MJ','BTU','cal','kcal'} ;
                    
                    app.DropDown2Label.Text = 'Molar basis' ;
                    app.DropDown2.Items = {'','mol','kmol','mmol','kgmol','gmmol','lbmol'} ;
                    
                    app.DropDown3Label.Text = 'Energy basis' ;
                    app.DropDown3.Items = {'','J','kJ','MJ','BTU','cal','kcal'} ;
                    
                    app.DropDown4Label.Text = 'Molar basis' ;
                    app.DropDown4.Items = {'','mol','kmol','mmol','kgmol','gmmol','lbmol'} ;
                case 'Kinetic constant'
                    app.dropDownVisibility({'off','off','off','off'}) ;
                    app.InputUnitsEditField.Visible = 'on' ;
                    app.OutputUnitsEditField.Visible = 'on' ;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.9412 0.9412 0.9412];
            app.UIFigure.Position = [100 100 582 370];
            app.UIFigure.Name = 'UI Figure';

            % Create UnitconversionhelperLabel
            app.UnitconversionhelperLabel = uilabel(app.UIFigure);
            app.UnitconversionhelperLabel.FontSize = 16;
            app.UnitconversionhelperLabel.FontWeight = 'bold';
            app.UnitconversionhelperLabel.Position = [193 338 179 22];
            app.UnitconversionhelperLabel.Text = 'Unit conversion helper';

            % Create initialDataTable
            app.initialDataTable = uitable(app.UIFigure);
            app.initialDataTable.ColumnName = {'Insert value'};
            app.initialDataTable.RowName = {};
            app.initialDataTable.Position = [211 46 133 185];

            % Create ConvertButton
            app.ConvertButton = uibutton(app.UIFigure, 'push');
            app.ConvertButton.ButtonPushedFcn = createCallbackFcn(app, @ConvertButtonPushed, true);
            app.ConvertButton.FontSize = 16;
            app.ConvertButton.FontWeight = 'bold';
            app.ConvertButton.Position = [40 39 100 26];
            app.ConvertButton.Text = 'Convert';

            % Create convertedDataTable
            app.convertedDataTable = uitable(app.UIFigure);
            app.convertedDataTable.ColumnName = {'Solution'};
            app.convertedDataTable.RowName = {};
            app.convertedDataTable.Visible = 'off';
            app.convertedDataTable.Position = [400 46 133 185];

            % Create PropertiesListBoxLabel
            app.PropertiesListBoxLabel = uilabel(app.UIFigure);
            app.PropertiesListBoxLabel.HorizontalAlignment = 'right';
            app.PropertiesListBoxLabel.FontWeight = 'bold';
            app.PropertiesListBoxLabel.Position = [55 280 65 22];
            app.PropertiesListBoxLabel.Text = 'Properties';

            % Create PropertiesListBox
            app.PropertiesListBox = uilistbox(app.UIFigure);
            app.PropertiesListBox.Items = {'', 'Pressure', 'Temperature', 'Volume', 'Molar Flow', 'Concentration', 'Enthalpy', 'Cp', 'Activation energy', 'Kinetic constant'};
            app.PropertiesListBox.ValueChangedFcn = createCallbackFcn(app, @PropertiesListBoxValueChanged, true);
            app.PropertiesListBox.Position = [30 94 123 187];
            app.PropertiesListBox.Value = '';

            % Create InitialUnitsLabel
            app.InitialUnitsLabel = uilabel(app.UIFigure);
            app.InitialUnitsLabel.FontWeight = 'bold';
            app.InitialUnitsLabel.Position = [274 301 70 22];
            app.InitialUnitsLabel.Text = 'Initial Units';

            % Create InputUnitsEditField
            app.InputUnitsEditField = uieditfield(app.UIFigure, 'text');
            app.InputUnitsEditField.Tooltip = {'Write u. before specifying each unit.'; 'Example: to write m^3/(mol·s) use the following notation'; '(u.m^3/u.mol/u.s)'; ''; 'For more inofrmation, read unit_tutorials.m (cmu+/examples/unit_tutorials.m)'};
            app.InputUnitsEditField.Position = [193 265 151 22];

            % Create DropDownLabel
            app.DropDownLabel = uilabel(app.UIFigure);
            app.DropDownLabel.HorizontalAlignment = 'right';
            app.DropDownLabel.Position = [161 276 79 22];
            app.DropDownLabel.Text = 'Drop Down';

            % Create DropDown
            app.DropDown = uidropdown(app.UIFigure);
            app.DropDown.Position = [244 276 100 22];

            % Create DropDown2Label
            app.DropDown2Label = uilabel(app.UIFigure);
            app.DropDown2Label.HorizontalAlignment = 'right';
            app.DropDown2Label.Position = [166 255 72 22];
            app.DropDown2Label.Text = 'Drop Down2';

            % Create DropDown2
            app.DropDown2 = uidropdown(app.UIFigure);
            app.DropDown2.Position = [243 255 100 22];

            % Create OutputUnitsEditField
            app.OutputUnitsEditField = uieditfield(app.UIFigure, 'text');
            app.OutputUnitsEditField.Tooltip = {'Write u. before specifying each unit.'; 'Example: to write m^3/(mol·s) use the following notation'; '(u.m^3/u.mol/u.s)'; ''; 'For more inofrmation, read unit_tutorials.m (cmu+/examples/unit_tutorials.m)'};
            app.OutputUnitsEditField.Position = [378 265 147 22];

            % Create DesiredUnitsLabel
            app.DesiredUnitsLabel = uilabel(app.UIFigure);
            app.DesiredUnitsLabel.FontWeight = 'bold';
            app.DesiredUnitsLabel.Position = [378 301 83 22];
            app.DesiredUnitsLabel.Text = 'Desired Units';

            % Create DropDown3Label
            app.DropDown3Label = uilabel(app.UIFigure);
            app.DropDown3Label.HorizontalAlignment = 'right';
            app.DropDown3Label.Position = [378 276 72 22];
            app.DropDown3Label.Text = 'Drop Down3';

            % Create DropDown3
            app.DropDown3 = uidropdown(app.UIFigure);
            app.DropDown3.Position = [455 276 100 22];

            % Create DropDown4Label
            app.DropDown4Label = uilabel(app.UIFigure);
            app.DropDown4Label.HorizontalAlignment = 'right';
            app.DropDown4Label.Position = [378 255 72 22];
            app.DropDown4Label.Text = 'Drop Down4';

            % Create DropDown4
            app.DropDown4 = uidropdown(app.UIFigure);
            app.DropDown4.Position = [455 255 100 22];

            % Create AddrowButton
            app.AddrowButton = uibutton(app.UIFigure, 'push');
            app.AddrowButton.ButtonPushedFcn = createCallbackFcn(app, @AddrowButtonPushed, true);
            app.AddrowButton.FontColor = [0.502 0.502 0.502];
            app.AddrowButton.Position = [277 16 67 22];
            app.AddrowButton.Text = 'Add row +';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = unitConverterApp(varargin)

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