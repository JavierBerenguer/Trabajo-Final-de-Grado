classdef dialogHysysStreamApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        DefinestreamfromAspenHysysLabel  matlab.ui.control.Label
        xmlLabel                    matlab.ui.control.Label
        Image                       matlab.ui.control.Image
        OKButton                    matlab.ui.control.Button
        StreamNameEditField         matlab.ui.control.EditField
        StreamNameEditFieldLabel    matlab.ui.control.Label
        FileNameEditField           matlab.ui.control.EditField
        FileNameEditFieldLabel      matlab.ui.control.Label
        FileLocationEditField       matlab.ui.control.EditField
        FileLocationEditFieldLabel  matlab.ui.control.Label
    end

    
    properties (Access = private)
        CallingApp
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainApp)
            app.CallingApp = mainApp ;
        end

        % Button pushed function: OKButton
        function OKButtonPushed(app, event)
            fileLocation    = app.FileLocationEditField.Value ;
            fileName        = app.FileNameEditField.Value ;
            streamName      = app.StreamNameEditField.Value ;
            
            if isempty(fileLocation)
                fileLocation = [] ;
            end
            streamCopy          = Stream ;
            streamCopy          = streamCopy.defineStreamFromHysys(fileLocation, fileName, streamName) ;
            app.CallingApp.Y    = streamCopy ;
            
            displayStreamValues(app.CallingApp,streamCopy) ;
            app.CallingApp.volumetricFlowUnitsEditField.Value = 'm^3/s' ;
            app.CallingApp.MolarFlowunitsEditField.Value = 'moles/s' ;
            
            delete(app)

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 317 176];
            app.UIFigure.Name = 'UI Figure';

            % Create FileLocationEditFieldLabel
            app.FileLocationEditFieldLabel = uilabel(app.UIFigure);
            app.FileLocationEditFieldLabel.HorizontalAlignment = 'right';
            app.FileLocationEditFieldLabel.Position = [31 120 74 22];
            app.FileLocationEditFieldLabel.Text = 'File Location';

            % Create FileLocationEditField
            app.FileLocationEditField = uieditfield(app.UIFigure, 'text');
            app.FileLocationEditField.Tooltip = {'Optional.'; ''; 'If this gap is not filled, the .xml file is searched in the current working folder'};
            app.FileLocationEditField.Position = [120 120 154 22];

            % Create FileNameEditFieldLabel
            app.FileNameEditFieldLabel = uilabel(app.UIFigure);
            app.FileNameEditFieldLabel.HorizontalAlignment = 'right';
            app.FileNameEditFieldLabel.Position = [45 83 60 22];
            app.FileNameEditFieldLabel.Text = 'File Name';

            % Create FileNameEditField
            app.FileNameEditField = uieditfield(app.UIFigure, 'text');
            app.FileNameEditField.Tooltip = {'Compulsory'};
            app.FileNameEditField.Position = [120 83 154 22];

            % Create StreamNameEditFieldLabel
            app.StreamNameEditFieldLabel = uilabel(app.UIFigure);
            app.StreamNameEditFieldLabel.HorizontalAlignment = 'right';
            app.StreamNameEditFieldLabel.Position = [25 47 80 22];
            app.StreamNameEditFieldLabel.Text = 'Stream Name';

            % Create StreamNameEditField
            app.StreamNameEditField = uieditfield(app.UIFigure, 'text');
            app.StreamNameEditField.Tooltip = {'Compulsory'};
            app.StreamNameEditField.Position = [120 47 154 22];

            % Create OKButton
            app.OKButton = uibutton(app.UIFigure, 'push');
            app.OKButton.ButtonPushedFcn = createCallbackFcn(app, @OKButtonPushed, true);
            app.OKButton.Position = [140 12 53 22];
            app.OKButton.Text = 'OK';

            % Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.Position = [1 151 22 30];
            app.Image.ImageSource = 'HysysLogo.png';

            % Create xmlLabel
            app.xmlLabel = uilabel(app.UIFigure);
            app.xmlLabel.FontColor = [0.502 0.502 0.502];
            app.xmlLabel.Position = [277 82 27 22];
            app.xmlLabel.Text = '.xml';

            % Create DefinestreamfromAspenHysysLabel
            app.DefinestreamfromAspenHysysLabel = uilabel(app.UIFigure);
            app.DefinestreamfromAspenHysysLabel.FontName = 'Arial';
            app.DefinestreamfromAspenHysysLabel.FontSize = 15;
            app.DefinestreamfromAspenHysysLabel.FontWeight = 'bold';
            app.DefinestreamfromAspenHysysLabel.FontColor = [0.2039 0.8118 0.6588];
            app.DefinestreamfromAspenHysysLabel.Position = [45 155 243 22];
            app.DefinestreamfromAspenHysysLabel.Text = 'Define stream from Aspen Hysys';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = dialogHysysStreamApp(varargin)

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