classdef UtilitiesApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure            matlab.ui.Figure
        OKButton            matlab.ui.control.Button
        ColdUtilitiesLabel  matlab.ui.control.Label
        HotUtilitiesLabel   matlab.ui.control.Label
        ColdUtilitiesTab    matlab.ui.control.Table
        HotUtilitiesTab     matlab.ui.control.Table
    end

    
    properties (Access = public)
        CallingApp
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, reactorApp)
            load('UtilitiesDataBase.mat')
            nRowsHot = size(HotUtilitiesTable,1) ;
            newColumnHot = table('Size',[nRowsHot,1],'VariableTypes',"logical") ;
            app.HotUtilitiesTab.Data = [HotUtilitiesTable newColumnHot] ;
            app.HotUtilitiesTab.ColumnName = {'Tin(ºC)','Tout(ºC)','U (W/m²/K)','Cost ($/kW/year)','Select'} ;
            app.HotUtilitiesTab.RowName = HotUtilitiesTable.Row ;
            app.HotUtilitiesTab.ColumnEditable = logical([1,1,1,1,1]) ;
            
            nRowsCold = size(ColdUtilitiesTable,1) ;
            newColumnCold = table('Size',[nRowsCold,1],'VariableTypes',"logical") ;
            app.ColdUtilitiesTab.Data = [ColdUtilitiesTable newColumnCold] ;
            app.ColdUtilitiesTab.ColumnName = {'Tin(ºC)','Tout(ºC)','U (W/m²/K)','Cost ($/kW/year)','Select'} ;
            app.ColdUtilitiesTab.RowName = ColdUtilitiesTable.Row ;
            app.ColdUtilitiesTab.ColumnEditable = logical([1,1,1,1,1]) ;
            
            app.CallingApp = reactorApp ;
        end

        % Button pushed function: OKButton
        function OKButtonPushed(app, event)
            selectedHot = app.HotUtilitiesTab.Data{:,5} ;
            selectedCold = app.ColdUtilitiesTab.Data{:,5} ;
            if sum(selectedHot)+sum(selectedCold) > 1
                error('Only one utility can be selected')
            elseif sum(selectedHot)+sum(selectedCold) == 1
                if sum(selectedHot) == 1
                    selection = app.HotUtilitiesTab.Data{selectedHot,:} ;
                elseif sum(selectedCold) == 1
                    selection = app.ColdUtilitiesTab.Data{selectedCold,:} ;
                end
            end
            app.CallingApp.UEditField.Value = selection(3) ;
            app.CallingApp.TwEditField.Value = selection(1);
            
            app.CallingApp.TwoutletKLabel.Visible = 'on' ; 
            app.CallingApp.TwOutletEditField.Visible = 'on' ;
            app.CallingApp.CostkWyearEditFieldLabel.Visible = 'on' ; 
            app.CallingApp.CostUtilityEditField.Visible = 'on' ;
            
            app.CallingApp.TwOutletEditField.Value= selection(2) ;
            app.CallingApp.CostUtilityEditField.Value = selection(4) ;
            delete(app)
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 635 324];
            app.UIFigure.Name = 'UI Figure';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create HotUtilitiesTab
            app.HotUtilitiesTab = uitable(app.UIFigure);
            app.HotUtilitiesTab.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.HotUtilitiesTab.RowName = {};
            app.HotUtilitiesTab.Position = [31 165 580 117];

            % Create ColdUtilitiesTab
            app.ColdUtilitiesTab = uitable(app.UIFigure);
            app.ColdUtilitiesTab.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.ColdUtilitiesTab.RowName = {};
            app.ColdUtilitiesTab.Position = [30 43 580 93];

            % Create HotUtilitiesLabel
            app.HotUtilitiesLabel = uilabel(app.UIFigure);
            app.HotUtilitiesLabel.FontSize = 16;
            app.HotUtilitiesLabel.FontWeight = 'bold';
            app.HotUtilitiesLabel.Position = [274 286 94 22];
            app.HotUtilitiesLabel.Text = 'Hot Utilities';

            % Create ColdUtilitiesLabel
            app.ColdUtilitiesLabel = uilabel(app.UIFigure);
            app.ColdUtilitiesLabel.FontSize = 16;
            app.ColdUtilitiesLabel.FontWeight = 'bold';
            app.ColdUtilitiesLabel.Position = [269 140 103 22];
            app.ColdUtilitiesLabel.Text = 'Cold Utilities';

            % Create OKButton
            app.OKButton = uibutton(app.UIFigure, 'push');
            app.OKButton.ButtonPushedFcn = createCallbackFcn(app, @OKButtonPushed, true);
            app.OKButton.Position = [287 13 64 22];
            app.OKButton.Text = 'OK';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = UtilitiesApp(varargin)

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