classdef defineReactorApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        CostUtilityEditField         matlab.ui.control.NumericEditField
        CostkWyearEditFieldLabel     matlab.ui.control.Label
        ParticlediametermEditField   matlab.ui.control.NumericEditField
        ParticlediametermEditFieldLabel  matlab.ui.control.Label
        UtilitiesDataBaseLabel       matlab.ui.control.Label
        CatalystCheckBox             matlab.ui.control.CheckBox
        PressureDropEqn              matlab.ui.container.ButtonGroup
        ErgunButton                  matlab.ui.control.RadioButton
        PipeButton                   matlab.ui.control.RadioButton
        UnitconversionhelperButton   matlab.ui.control.Button
        TwOutletEditField            matlab.ui.control.NumericEditField
        TwoutletKLabel               matlab.ui.control.Label
        UtilitiesButton              matlab.ui.control.Button
        TypeofreactorButtonGroup     matlab.ui.container.ButtonGroup
        HelperButton                 matlab.ui.control.RadioButton
        BatchButton                  matlab.ui.control.RadioButton
        CSTRButton                   matlab.ui.control.RadioButton
        PFRButton                    matlab.ui.control.RadioButton
        UnitsEditField_2             matlab.ui.control.EditField
        UnitsEditField_2Label        matlab.ui.control.Label
        ReactiontimesEditField       matlab.ui.control.NumericEditField
        ReactiontimesLabel           matlab.ui.control.Label
        CreateReactorButton          matlab.ui.control.Button
        DisplayplotsSwitch           matlab.ui.control.Switch
        DisplayplotsSwitchLabel      matlab.ui.control.Label
        QUATTwLabel                  matlab.ui.control.Label
        TwEditField                  matlab.ui.control.NumericEditField
        TwinletKLabel                matlab.ui.control.Label
        AEditField                   matlab.ui.control.NumericEditField
        AmLabel                      matlab.ui.control.Label
        UEditField                   matlab.ui.control.NumericEditField
        UWmKLabel                    matlab.ui.control.Label
        PorosityEditField            matlab.ui.control.NumericEditField
        PorosityEditFieldLabel       matlab.ui.control.Label
        DensityEditField             matlab.ui.control.NumericEditField
        DensitykgmLabel              matlab.ui.control.Label
        TubediametermEditField       matlab.ui.control.NumericEditField
        TubediametermEditFieldLabel  matlab.ui.control.Label
        NumberoftubesEditField       matlab.ui.control.NumericEditField
        NumberoftubesEditFieldLabel  matlab.ui.control.Label
        LmEditField                  matlab.ui.control.NumericEditField
        LmEditFieldLabel             matlab.ui.control.Label
        BypassRatioEditField         matlab.ui.control.NumericEditField
        BypassRatioEditFieldLabel    matlab.ui.control.Label
        UnitsEditField               matlab.ui.control.EditField
        UnitsEditFieldLabel          matlab.ui.control.Label
        VolumemEditField             matlab.ui.control.NumericEditField
        VolumemEditFieldLabel        matlab.ui.control.Label
        PressureDropMode             matlab.ui.container.ButtonGroup
        NonconstantButton            matlab.ui.control.RadioButton
        ConstantButton               matlab.ui.control.RadioButton
        HeatexchangemodeButtonGroup  matlab.ui.container.ButtonGroup
        OtherButton                  matlab.ui.control.RadioButton
        AdiabaticButton              matlab.ui.control.RadioButton
        IsothermalButton             matlab.ui.control.RadioButton
        NameEditField                matlab.ui.control.EditField
        NameEditFieldLabel           matlab.ui.control.Label
        ChooseanametoidentifythereactorLabel  matlab.ui.control.Label
        ReactorLabel                 matlab.ui.control.Label
    end

    
    properties (Access = public)
        R % Reactor object
        DialogApp % Description
        UnitsApp
    end
    
    methods (Access = private)
        
        function visibilityPFRFeatures(app,state)
            app.LmEditField.Visible = state ;
            app.LmEditFieldLabel.Visible = state ;
            app.NumberoftubesEditField.Visible = state ;
            app.NumberoftubesEditFieldLabel.Visible = state ;
            app.TubediametermEditField.Visible = state;
            app.TubediametermEditFieldLabel.Visible = state ;
        end
        
        function visibilityHeatTransferFeatures(app,state)
            app.UEditField.Visible = state ;
            app.UWmKLabel.Visible = state ;
            app.AEditField.Visible = state ;
            app.AmLabel.Visible = state ;
            app.TwEditField.Visible = state ;
            app.TwinletKLabel.Visible = state ;
            app.UtilitiesButton.Visible = state ;
            app.QUATTwLabel.Visible = state ;
            app.UtilitiesDataBaseLabel.Visible = state ;
        end
        
        function visibilityBatchFeatures(app,state)
            app.ReactiontimesEditField.Visible = state ;
            app.ReactiontimesLabel.Visible = state ;
            %app.UnitsEditField_2.Visible = state ;
            %app.UnitsEditField_2Label.Visible = state ;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Selection changed function: TypeofreactorButtonGroup
        function TypeofreactorButtonGroupSelectionChanged(app, event)
            selectedButton = app.TypeofreactorButtonGroup.SelectedObject;
            switch selectedButton.Text
                case 'PFR'
                    app.visibilityPFRFeatures('on')
                    app.visibilityBatchFeatures('off')
                    if strcmp(app.PressureDropMode.SelectedObject.Text,'Non constant')
                        app.PressureDropEqn.Visible = 'on' ;
                    else
                        app.PressureDropEqn.Visible = 'off' ;
                    end
                case 'CSTR'
                    app.visibilityPFRFeatures('off')
                    app.visibilityBatchFeatures('off')
                    app.PressureDropEqn.Visible = 'off' ;
                case 'Batch'
                    app.visibilityPFRFeatures('off')
                    app.visibilityBatchFeatures('on')
                    app.PressureDropEqn.Visible = 'off' ;
            end
        end

        % Selection changed function: HeatexchangemodeButtonGroup
        function HeatexchangemodeButtonGroupSelectionChanged(app, event)
            selectedButton = app.HeatexchangemodeButtonGroup.SelectedObject;
            switch selectedButton.Text
                case 'Other'
                    app.visibilityHeatTransferFeatures('on')
                case {'Adiabatic','Isothermal'}
                    app.visibilityHeatTransferFeatures('off')
            end
        end

        % Button pushed function: CreateReactorButton
        function CreateReactorButtonPushed(app, event)
            if isempty(app.NameEditField.Value)
                msgbox('Name edit field is empty. Please, write an identifier before pushing "Create Reactor" button', 'Warning','warn');
            else
                selectedButton = app.TypeofreactorButtonGroup.SelectedObject;
                switch selectedButton.Text
                    case 'PFR'
                        app.R = PFR ;
                    case 'CSTR'
                        app.R = CSTR ;
                    case 'Batch'
                        app.R = Batch ;
                end
                
                if app.VolumemEditField.Value > 0
                    app.R.V = app.VolumemEditField.Value ;
                    app.R.V_Units = app.UnitsEditField.Value ;
                end
                
                app.R.bypassRatio = app.BypassRatioEditField.Value ;
                
                if app.ReactiontimesEditField.Value > 0
                    app.R.timeBatch = app.ReactiontimesEditField.Value ;
                    app.R.timeBatch_Units = app.UnitsEditField_2.Value ;
                end
                if app.LmEditField.Value > 0
                    app.R.L =app.LmEditField.Value ;
                    if app.TubediametermEditField.Value ~= 0.1
                        app.R.diameterTubes =app.TubediametermEditField.Value ;
                    end
                    if app.NumberoftubesEditField.Value > 1
                        app.R.nTubes = app.NumberoftubesEditField.Value ;
                    end
                end
                
                if app.CatalystCheckBox.Value
                    if app.DensityEditField.Value > 0
                        app.R.densityCatalyst = app.DensityEditField.Value ;
                    end
                    app.R.porosityCatalyst = app.PorosityEditField.Value ;
                end
                
                app.R.heatMode = app.HeatexchangemodeButtonGroup.SelectedObject.Text ;
                if strcmp(app.R.heatMode,'Other')
                    app.R.U = app.UEditField.Value ;
                    app.R.heatTransferArea = app.AEditField.Value ;
                    app.R.inletUtilityTemperature = app.TwEditField.Value ;
                    if strcmp(app.TwOutletEditField.Visible,'on')
                        app.R.outletUtilityTemperature = app.TwOutletEditField.Value ;
                        app.R.costUtility = app.CostUtilityEditField.Value ;
                    end
                end
                
                app.R.pressureMode = app.PressureDropMode.SelectedObject.Text ;
                
                if  strcmp(selectedButton.Text,'PFR')
                    app.R.pressureDropEqn = app.PressureDropEqn.SelectedObject.Text ;
                    if strcmp(app.PressureDropEqn.SelectedObject.Text,'Ergun')
                        app.R.particleDiameter = app.ParticlediametermEditField.Value ;
                    end
                end
                
                app.R.activatePlots  = app.DisplayplotsSwitch.Value ;
                
                assignin("base",app.NameEditField.Value,app.R) ;
            end
        end

        % Button pushed function: UtilitiesButton
        function UtilitiesButtonPushed(app, event)
            app.DialogApp = UtilitiesApp(app) ;
        end

        % Button pushed function: UnitconversionhelperButton
        function UnitconversionhelperButtonPushed(app, event)
            app.UnitsApp = unitConverterApp(app) ;
        end

        % Selection changed function: PressureDropEqn
        function PressureDropEqnSelectionChanged(app, event)
            selectedButton = app.PressureDropEqn.SelectedObject;
            if strcmp(selectedButton.Text,'Ergun')
                app.CatalystCheckBox.Value = logical(true) ;
                app.CatalystCheckBoxValueChanged(logical(true)) ;
                
                app.ParticlediametermEditField.Visible = 'on' ;
                app.ParticlediametermEditFieldLabel.Visible = 'on' ;
            else
                app.ParticlediametermEditField.Visible = 'off' ;
                app.ParticlediametermEditFieldLabel.Visible = 'off' ;
            end
        end

        % Value changed function: CatalystCheckBox
        function CatalystCheckBoxValueChanged(app, event)
            value = app.CatalystCheckBox.Value;
            if value
                app.DensityEditField.Enable = 'on' ;
                app.PorosityEditField.Enable = 'on' ;
            else
                app.DensityEditField.Enable = 'off' ;
                app.PorosityEditField.Enable = 'off' ;
            end
        end

        % Selection changed function: PressureDropMode
        function PressureDropModeSelectionChanged(app, event)
            if strcmp(app.TypeofreactorButtonGroup.SelectedObject.Text,'PFR') && strcmp(app.PressureDropMode.SelectedObject.Text,'Non constant')
                app.PressureDropEqn.Visible = 'on' ;
            else
                app.PressureDropEqn.Visible = 'off' ;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 609 482];
            app.UIFigure.Name = 'UI Figure';

            % Create ReactorLabel
            app.ReactorLabel = uilabel(app.UIFigure);
            app.ReactorLabel.HorizontalAlignment = 'center';
            app.ReactorLabel.FontName = 'Arial';
            app.ReactorLabel.FontSize = 16;
            app.ReactorLabel.FontWeight = 'bold';
            app.ReactorLabel.Position = [188 456 242 25];
            app.ReactorLabel.Text = 'Reactor';

            % Create ChooseanametoidentifythereactorLabel
            app.ChooseanametoidentifythereactorLabel = uilabel(app.UIFigure);
            app.ChooseanametoidentifythereactorLabel.FontColor = [0.502 0.502 0.502];
            app.ChooseanametoidentifythereactorLabel.Position = [203 422 207 22];
            app.ChooseanametoidentifythereactorLabel.Text = 'Choose a name to identify the reactor';

            % Create NameEditFieldLabel
            app.NameEditFieldLabel = uilabel(app.UIFigure);
            app.NameEditFieldLabel.HorizontalAlignment = 'right';
            app.NameEditFieldLabel.FontWeight = 'bold';
            app.NameEditFieldLabel.Position = [47 422 38 22];
            app.NameEditFieldLabel.Text = 'Name';

            % Create NameEditField
            app.NameEditField = uieditfield(app.UIFigure, 'text');
            app.NameEditField.Position = [100 422 100 22];

            % Create HeatexchangemodeButtonGroup
            app.HeatexchangemodeButtonGroup = uibuttongroup(app.UIFigure);
            app.HeatexchangemodeButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @HeatexchangemodeButtonGroupSelectionChanged, true);
            app.HeatexchangemodeButtonGroup.TitlePosition = 'centertop';
            app.HeatexchangemodeButtonGroup.Title = 'Heat exchange mode';
            app.HeatexchangemodeButtonGroup.FontWeight = 'bold';
            app.HeatexchangemodeButtonGroup.Position = [51 224 252 48];

            % Create IsothermalButton
            app.IsothermalButton = uiradiobutton(app.HeatexchangemodeButtonGroup);
            app.IsothermalButton.Text = 'Isothermal';
            app.IsothermalButton.Position = [3 4 78 22];

            % Create AdiabaticButton
            app.AdiabaticButton = uiradiobutton(app.HeatexchangemodeButtonGroup);
            app.AdiabaticButton.Text = 'Adiabatic';
            app.AdiabaticButton.Position = [99 4 71 22];

            % Create OtherButton
            app.OtherButton = uiradiobutton(app.HeatexchangemodeButtonGroup);
            app.OtherButton.Tooltip = {'Other implies the reactor is cooled or heated'};
            app.OtherButton.Text = 'Other';
            app.OtherButton.Position = [187 4 65 22];
            app.OtherButton.Value = true;

            % Create PressureDropMode
            app.PressureDropMode = uibuttongroup(app.UIFigure);
            app.PressureDropMode.SelectionChangedFcn = createCallbackFcn(app, @PressureDropModeSelectionChanged, true);
            app.PressureDropMode.Tooltip = {'Constant : momentum balnce is neglected'; ''; 'Not constant : momentum balance is considered'};
            app.PressureDropMode.TitlePosition = 'centertop';
            app.PressureDropMode.Title = 'Does pressure change inside the reactor?';
            app.PressureDropMode.FontWeight = 'bold';
            app.PressureDropMode.Position = [314 224 249 48];

            % Create ConstantButton
            app.ConstantButton = uiradiobutton(app.PressureDropMode);
            app.ConstantButton.Text = 'Constant';
            app.ConstantButton.Position = [23 4 70 22];
            app.ConstantButton.Value = true;

            % Create NonconstantButton
            app.NonconstantButton = uiradiobutton(app.PressureDropMode);
            app.NonconstantButton.Text = 'Non constant';
            app.NonconstantButton.Position = [138 4 93 22];

            % Create VolumemEditFieldLabel
            app.VolumemEditFieldLabel = uilabel(app.UIFigure);
            app.VolumemEditFieldLabel.Tooltip = {'It is advisable to use SI units because all the operations use the gas constant as:'; 'R = 8,314 Pa·m^3/mol/K'};
            app.VolumemEditFieldLabel.Position = [55 328 119 22];
            app.VolumemEditFieldLabel.Text = 'Volume (m³)';

            % Create VolumemEditField
            app.VolumemEditField = uieditfield(app.UIFigure, 'numeric');
            app.VolumemEditField.Tooltip = {'It is advisable to use SI units because all the operations use the gas constant as:'; 'R = 8,314 Pa·m^3/mol/K'};
            app.VolumemEditField.Position = [187 328 98 22];

            % Create UnitsEditFieldLabel
            app.UnitsEditFieldLabel = uilabel(app.UIFigure);
            app.UnitsEditFieldLabel.Visible = 'off';
            app.UnitsEditFieldLabel.Tooltip = {'It is advisable to use SI units because all the operations use the gas constant as:'; 'R = 8,314 Pa·m^3/mol/K'};
            app.UnitsEditFieldLabel.Position = [55 311 119 22];
            app.UnitsEditFieldLabel.Text = 'Units';

            % Create UnitsEditField
            app.UnitsEditField = uieditfield(app.UIFigure, 'text');
            app.UnitsEditField.Visible = 'off';
            app.UnitsEditField.Tooltip = {'It is advisable to use SI units because all the operations use the gas constant as:'; 'R = 8,314 Pa·m^3/mol/K'};
            app.UnitsEditField.Position = [187 311 98 22];

            % Create BypassRatioEditFieldLabel
            app.BypassRatioEditFieldLabel = uilabel(app.UIFigure);
            app.BypassRatioEditFieldLabel.Position = [55 292 119 22];
            app.BypassRatioEditFieldLabel.Text = 'Bypass Ratio';

            % Create BypassRatioEditField
            app.BypassRatioEditField = uieditfield(app.UIFigure, 'numeric');
            app.BypassRatioEditField.Limits = [0 Inf];
            app.BypassRatioEditField.Tooltip = {'Bypass Ratio = (moles bypassed) /(moles entering reactor)'};
            app.BypassRatioEditField.Position = [187 292 98 22];

            % Create LmEditFieldLabel
            app.LmEditFieldLabel = uilabel(app.UIFigure);
            app.LmEditFieldLabel.Visible = 'off';
            app.LmEditFieldLabel.Tooltip = {'It is advisable to use SI units because all the operations use the gas constant as:'; 'R = 8,314 Pa·m^3/mol/K'};
            app.LmEditFieldLabel.Position = [324 334 119 22];
            app.LmEditFieldLabel.Text = 'L (m)';

            % Create LmEditField
            app.LmEditField = uieditfield(app.UIFigure, 'numeric');
            app.LmEditField.Visible = 'off';
            app.LmEditField.Tooltip = {'It is advisable to use SI units because all the operations use the gas constant as:'; 'R = 8,314 Pa·m^3/mol/K'};
            app.LmEditField.Position = [456 334 98 22];

            % Create NumberoftubesEditFieldLabel
            app.NumberoftubesEditFieldLabel = uilabel(app.UIFigure);
            app.NumberoftubesEditFieldLabel.Visible = 'off';
            app.NumberoftubesEditFieldLabel.Position = [324 307 119 22];
            app.NumberoftubesEditFieldLabel.Text = 'Number of tubes';

            % Create NumberoftubesEditField
            app.NumberoftubesEditField = uieditfield(app.UIFigure, 'numeric');
            app.NumberoftubesEditField.Visible = 'off';
            app.NumberoftubesEditField.Position = [456 307 98 22];
            app.NumberoftubesEditField.Value = 1;

            % Create TubediametermEditFieldLabel
            app.TubediametermEditFieldLabel = uilabel(app.UIFigure);
            app.TubediametermEditFieldLabel.Visible = 'off';
            app.TubediametermEditFieldLabel.Tooltip = {'It is advisable to use SI units because all the operations use the gas constant as:'; 'R = 8,314 Pa·m^3/mol/K'};
            app.TubediametermEditFieldLabel.Position = [324 280 119 22];
            app.TubediametermEditFieldLabel.Text = 'Tube diameter (m)';

            % Create TubediametermEditField
            app.TubediametermEditField = uieditfield(app.UIFigure, 'numeric');
            app.TubediametermEditField.Visible = 'off';
            app.TubediametermEditField.Tooltip = {'It is advisable to use SI units because all the operations use the gas constant as:'; 'R = 8,314 Pa·m^3/mol/K'};
            app.TubediametermEditField.Position = [456 280 98 22];
            app.TubediametermEditField.Value = 0.1;

            % Create DensitykgmLabel
            app.DensitykgmLabel = uilabel(app.UIFigure);
            app.DensitykgmLabel.HorizontalAlignment = 'right';
            app.DensitykgmLabel.Position = [341 118 87 22];
            app.DensitykgmLabel.Text = 'Density (kg/m³)';

            % Create DensityEditField
            app.DensityEditField = uieditfield(app.UIFigure, 'numeric');
            app.DensityEditField.Limits = [0 Inf];
            app.DensityEditField.Enable = 'off';
            app.DensityEditField.Position = [446 118 100 22];

            % Create PorosityEditFieldLabel
            app.PorosityEditFieldLabel = uilabel(app.UIFigure);
            app.PorosityEditFieldLabel.HorizontalAlignment = 'right';
            app.PorosityEditFieldLabel.Position = [382 92 49 22];
            app.PorosityEditFieldLabel.Text = 'Porosity';

            % Create PorosityEditField
            app.PorosityEditField = uieditfield(app.UIFigure, 'numeric');
            app.PorosityEditField.Limits = [0 1];
            app.PorosityEditField.Enable = 'off';
            app.PorosityEditField.Position = [446 92 100 22];

            % Create UWmKLabel
            app.UWmKLabel = uilabel(app.UIFigure);
            app.UWmKLabel.HorizontalAlignment = 'right';
            app.UWmKLabel.Position = [87 142 65 22];
            app.UWmKLabel.Text = 'U (W/m²/K)';

            % Create UEditField
            app.UEditField = uieditfield(app.UIFigure, 'numeric');
            app.UEditField.Position = [167 142 100 22];

            % Create AmLabel
            app.AmLabel = uilabel(app.UIFigure);
            app.AmLabel.HorizontalAlignment = 'right';
            app.AmLabel.Position = [113 115 39 22];
            app.AmLabel.Text = 'A (m²)';

            % Create AEditField
            app.AEditField = uieditfield(app.UIFigure, 'numeric');
            app.AEditField.Tooltip = {'If the reactor is a PFR, it is unnecessary to specify the heat transfer area (A) '};
            app.AEditField.Position = [167 115 100 22];
            app.AEditField.Value = 1;

            % Create TwinletKLabel
            app.TwinletKLabel = uilabel(app.UIFigure);
            app.TwinletKLabel.HorizontalAlignment = 'right';
            app.TwinletKLabel.Position = [87 89 65 22];
            app.TwinletKLabel.Text = 'Tw,inlet (K)';

            % Create TwEditField
            app.TwEditField = uieditfield(app.UIFigure, 'numeric');
            app.TwEditField.Position = [167 89 100 22];
            app.TwEditField.Value = 0.1;

            % Create QUATTwLabel
            app.QUATTwLabel = uilabel(app.UIFigure);
            app.QUATTwLabel.FontColor = [0.502 0.502 0.502];
            app.QUATTwLabel.Position = [169 169 97 22];
            app.QUATTwLabel.Text = 'Q = UA ( T - Tw )';

            % Create DisplayplotsSwitchLabel
            app.DisplayplotsSwitchLabel = uilabel(app.UIFigure);
            app.DisplayplotsSwitchLabel.HorizontalAlignment = 'center';
            app.DisplayplotsSwitchLabel.Position = [476 438 74 22];
            app.DisplayplotsSwitchLabel.Text = 'Display plots';

            % Create DisplayplotsSwitch
            app.DisplayplotsSwitch = uiswitch(app.UIFigure, 'slider');
            app.DisplayplotsSwitch.Items = {'off', 'on'};
            app.DisplayplotsSwitch.Position = [489 420 45 20];
            app.DisplayplotsSwitch.Value = 'off';

            % Create CreateReactorButton
            app.CreateReactorButton = uibutton(app.UIFigure, 'push');
            app.CreateReactorButton.ButtonPushedFcn = createCallbackFcn(app, @CreateReactorButtonPushed, true);
            app.CreateReactorButton.FontSize = 16;
            app.CreateReactorButton.FontWeight = 'bold';
            app.CreateReactorButton.Position = [237 10 133 26];
            app.CreateReactorButton.Text = 'Create Reactor';

            % Create ReactiontimesLabel
            app.ReactiontimesLabel = uilabel(app.UIFigure);
            app.ReactiontimesLabel.Visible = 'off';
            app.ReactiontimesLabel.Position = [318 315 119 22];
            app.ReactiontimesLabel.Text = 'Reaction time (s)';

            % Create ReactiontimesEditField
            app.ReactiontimesEditField = uieditfield(app.UIFigure, 'numeric');
            app.ReactiontimesEditField.Visible = 'off';
            app.ReactiontimesEditField.Tooltip = {'It is advisable to use SI units because all the operations use the gas constant as:'; 'R = 8,314 Pa·m^3/mol/K'};
            app.ReactiontimesEditField.Position = [450 315 98 22];

            % Create UnitsEditField_2Label
            app.UnitsEditField_2Label = uilabel(app.UIFigure);
            app.UnitsEditField_2Label.Visible = 'off';
            app.UnitsEditField_2Label.Position = [318 282 119 22];
            app.UnitsEditField_2Label.Text = 'Units';

            % Create UnitsEditField_2
            app.UnitsEditField_2 = uieditfield(app.UIFigure, 'text');
            app.UnitsEditField_2.Visible = 'off';
            app.UnitsEditField_2.Position = [450 282 98 22];

            % Create TypeofreactorButtonGroup
            app.TypeofreactorButtonGroup = uibuttongroup(app.UIFigure);
            app.TypeofreactorButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @TypeofreactorButtonGroupSelectionChanged, true);
            app.TypeofreactorButtonGroup.Title = 'Type of reactor';
            app.TypeofreactorButtonGroup.FontWeight = 'bold';
            app.TypeofreactorButtonGroup.Position = [51 364 510 43];

            % Create PFRButton
            app.PFRButton = uiradiobutton(app.TypeofreactorButtonGroup);
            app.PFRButton.Text = 'PFR';
            app.PFRButton.Position = [6 1 58 22];

            % Create CSTRButton
            app.CSTRButton = uiradiobutton(app.TypeofreactorButtonGroup);
            app.CSTRButton.Text = 'CSTR';
            app.CSTRButton.Position = [219 1 65 22];

            % Create BatchButton
            app.BatchButton = uiradiobutton(app.TypeofreactorButtonGroup);
            app.BatchButton.Text = 'Batch';
            app.BatchButton.Position = [438 1 65 22];

            % Create HelperButton
            app.HelperButton = uiradiobutton(app.TypeofreactorButtonGroup);
            app.HelperButton.Visible = 'off';
            app.HelperButton.Text = 'Helper';
            app.HelperButton.Position = [117 1 57 22];
            app.HelperButton.Value = true;

            % Create UtilitiesButton
            app.UtilitiesButton = uibutton(app.UIFigure, 'push');
            app.UtilitiesButton.ButtonPushedFcn = createCallbackFcn(app, @UtilitiesButtonPushed, true);
            app.UtilitiesButton.Icon = 'DBIcon.png';
            app.UtilitiesButton.Tooltip = {''};
            app.UtilitiesButton.Position = [54 184 34 36];
            app.UtilitiesButton.Text = '';

            % Create TwoutletKLabel
            app.TwoutletKLabel = uilabel(app.UIFigure);
            app.TwoutletKLabel.HorizontalAlignment = 'right';
            app.TwoutletKLabel.Visible = 'off';
            app.TwoutletKLabel.Position = [80 68 72 22];
            app.TwoutletKLabel.Text = 'Tw,outlet (K)';

            % Create TwOutletEditField
            app.TwOutletEditField = uieditfield(app.UIFigure, 'numeric');
            app.TwOutletEditField.Visible = 'off';
            app.TwOutletEditField.Position = [167 68 100 22];
            app.TwOutletEditField.Value = Inf;

            % Create UnitconversionhelperButton
            app.UnitconversionhelperButton = uibutton(app.UIFigure, 'push');
            app.UnitconversionhelperButton.ButtonPushedFcn = createCallbackFcn(app, @UnitconversionhelperButtonPushed, true);
            app.UnitconversionhelperButton.Icon = 'UnitsLogo.png';
            app.UnitconversionhelperButton.Position = [1 461 164 22];
            app.UnitconversionhelperButton.Text = 'Unit conversion helper';

            % Create PressureDropEqn
            app.PressureDropEqn = uibuttongroup(app.UIFigure);
            app.PressureDropEqn.SelectionChangedFcn = createCallbackFcn(app, @PressureDropEqnSelectionChanged, true);
            app.PressureDropEqn.Tooltip = {''};
            app.PressureDropEqn.TitlePosition = 'centertop';
            app.PressureDropEqn.Title = 'How to compute pressure drop?';
            app.PressureDropEqn.FontWeight = 'bold';
            app.PressureDropEqn.Position = [314 175 249 48];

            % Create PipeButton
            app.PipeButton = uiradiobutton(app.PressureDropEqn);
            app.PipeButton.Tooltip = {'It implies that the pressure drop through the reactor is computed with a momentum balance considering it''s not a bed reactor'};
            app.PipeButton.Text = 'Pipe';
            app.PipeButton.Position = [23 4 46 22];
            app.PipeButton.Value = true;

            % Create ErgunButton
            app.ErgunButton = uiradiobutton(app.PressureDropEqn);
            app.ErgunButton.Text = 'Ergun';
            app.ErgunButton.Position = [138 4 54 22];

            % Create CatalystCheckBox
            app.CatalystCheckBox = uicheckbox(app.UIFigure);
            app.CatalystCheckBox.ValueChangedFcn = createCallbackFcn(app, @CatalystCheckBoxValueChanged, true);
            app.CatalystCheckBox.Text = 'Mark if the reactor is catalytic';
            app.CatalystCheckBox.FontWeight = 'bold';
            app.CatalystCheckBox.Position = [343 144 192 22];

            % Create UtilitiesDataBaseLabel
            app.UtilitiesDataBaseLabel = uilabel(app.UIFigure);
            app.UtilitiesDataBaseLabel.FontColor = [0.502 0.502 0.502];
            app.UtilitiesDataBaseLabel.Position = [90 191 104 22];
            app.UtilitiesDataBaseLabel.Text = 'Utilities Data Base';

            % Create ParticlediametermEditFieldLabel
            app.ParticlediametermEditFieldLabel = uilabel(app.UIFigure);
            app.ParticlediametermEditFieldLabel.HorizontalAlignment = 'right';
            app.ParticlediametermEditFieldLabel.Visible = 'off';
            app.ParticlediametermEditFieldLabel.Position = [314 64 117 22];
            app.ParticlediametermEditFieldLabel.Text = 'Particle diameter (m)';

            % Create ParticlediametermEditField
            app.ParticlediametermEditField = uieditfield(app.UIFigure, 'numeric');
            app.ParticlediametermEditField.Limits = [0 Inf];
            app.ParticlediametermEditField.Visible = 'off';
            app.ParticlediametermEditField.Position = [446 64 100 22];

            % Create CostkWyearEditFieldLabel
            app.CostkWyearEditFieldLabel = uilabel(app.UIFigure);
            app.CostkWyearEditFieldLabel.HorizontalAlignment = 'right';
            app.CostkWyearEditFieldLabel.Visible = 'off';
            app.CostkWyearEditFieldLabel.Position = [56 41 96 22];
            app.CostkWyearEditFieldLabel.Text = 'Cost ($/kW/year)';

            % Create CostUtilityEditField
            app.CostUtilityEditField = uieditfield(app.UIFigure, 'numeric');
            app.CostUtilityEditField.Visible = 'off';
            app.CostUtilityEditField.Position = [167 41 100 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = defineReactorApp

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

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