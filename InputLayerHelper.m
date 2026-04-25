classdef InputLayerHelper
% InputLayerHelper - Safe parsing and SI normalization for UI inputs
%
% Provides:
%   - Safe parsing of simple arithmetic expressions
%   - Conversion of parsed values to and from SI
%   - Wrapping of user-defined kinetics with unit adaptation
%
% Supported arithmetic syntax:
%   numbers, spaces, + - * / ^, parentheses, scientific notation

    methods (Static)

        function value = parseArithmeticExpression(expr)
            % parseArithmeticExpression Parse a simple arithmetic expression safely.

            if isnumeric(expr)
                if ~isscalar(expr) || ~isfinite(expr)
                    error('InputLayerHelper:InvalidNumericInput', ...
                        'Input must be a finite numeric scalar.') ;
                end
                value = double(expr) ;
                return
            end

            if isstring(expr)
                expr = char(expr) ;
            end

            if ~ischar(expr)
                error('InputLayerHelper:InvalidInputType', ...
                    'Input must be numeric, char, or string.') ;
            end

            expr = strtrim(expr) ;
            if isempty(expr)
                error('InputLayerHelper:EmptyExpression', ...
                    'Input expression is empty.') ;
            end

            if ~isempty(regexp(expr, '[^0-9eE\+\-\*\/\^\(\)\.\s]', 'once'))
                error('InputLayerHelper:UnsupportedCharacters', ...
                    'Only numbers, spaces, +, -, *, /, ^, parentheses, and scientific notation are allowed.') ;
            end

            idx = 1 ;
            [value, idx] = InputLayerHelper.parseExpression(expr, idx) ;
            idx = InputLayerHelper.skipSpaces(expr, idx) ;
            if idx <= length(expr)
                error('InputLayerHelper:TrailingCharacters', ...
                    'Unexpected characters found near "%s".', expr(idx:end)) ;
            end

            if ~isfinite(value)
                error('InputLayerHelper:NonFiniteResult', ...
                    'The expression does not evaluate to a finite scalar.') ;
            end
        end

        function siValue = parseNumericExpressionToSI(expr, categoryName, unitName)
            % parseNumericExpressionToSI Parse a simple expression and convert to SI.
            value = InputLayerHelper.parseArithmeticExpression(expr) ;
            siValue = UnitConverterHelper.convertToSI(categoryName, value, unitName) ;
        end

        function value = readFieldToSI(field)
            % readFieldToSI Read a text field configured by createNumericWithConv.
            userData = field.UserData ;
            if ~isstruct(userData) || ~isfield(userData, 'unitCategory') || ...
                    ~isfield(userData, 'unitDropdown')
                error('InputLayerHelper:MissingFieldMetadata', ...
                    'Field metadata for unit parsing is incomplete.') ;
            end

            value = InputLayerHelper.parseNumericExpressionToSI( ...
                field.Value, userData.unitCategory, userData.unitDropdown.Value) ;
        end

        function setFieldFromSI(field, siValue)
            % setFieldFromSI Convert an SI value to the currently selected unit.
            userData = field.UserData ;
            if ~isstruct(userData) || ~isfield(userData, 'unitCategory') || ...
                    ~isfield(userData, 'unitDropdown')
                field.Value = InputLayerHelper.formatScalar(siValue) ;
                return
            end

            displayValue = UnitConverterHelper.convertFromSI( ...
                userData.unitCategory, siValue, userData.unitDropdown.Value) ;
            field.Value = InputLayerHelper.formatScalar(displayValue) ;
        end

        function txt = formatScalar(value)
            txt = sprintf('%.15g', value) ;
        end

        function wrappedFcn = wrapExpressionKinetics(exprList, timeUnit, concentrationUnit)
            % wrapExpressionKinetics Wrap user expressions so they operate in SI internally.

            if isstring(exprList)
                exprList = cellstr(exprList(:)) ;
            elseif ischar(exprList)
                exprList = {exprList} ;
            end

            exprList = exprList(:)' ;
            handles = cell(1, numel(exprList)) ;
            for i = 1:numel(exprList)
                expr = strtrim(char(exprList{i})) ;
                if isempty(expr)
                    error('InputLayerHelper:EmptyRateExpression', ...
                        'Rate expression %d is empty.', i) ;
                end
                handles{i} = str2func(['@(concentration,T) ' expr]) ;
            end

            concentrationFactor = UnitConverterHelper.factorToSI( ...
                'Concentration', concentrationUnit) ;
            timeFactor = UnitConverterHelper.factorToSI('Time', timeUnit) ;
            rateFactor = concentrationFactor / timeFactor ;

            wrappedFcn = @(concentration,T) InputLayerHelper.evaluateKineticsHandles( ...
                handles, concentration, T, concentrationFactor, rateFactor) ;
        end

        function wrappedFcn = wrapNamedKinetics(functionName, timeUnit, concentrationUnit)
            % wrapNamedKinetics Wrap an external kinetics function with unit adaptation.
            functionName = strtrim(char(functionName)) ;
            if isempty(functionName)
                error('InputLayerHelper:MissingFunctionName', ...
                    'The kinetics function name cannot be empty.') ;
            end

            userFcn = str2func(functionName) ;
            concentrationFactor = UnitConverterHelper.factorToSI( ...
                'Concentration', concentrationUnit) ;
            timeFactor = UnitConverterHelper.factorToSI('Time', timeUnit) ;
            rateFactor = concentrationFactor / timeFactor ;

            wrappedFcn = @(concentration,T) InputLayerHelper.evaluateNamedKinetics( ...
                userFcn, concentration, T, concentrationFactor, rateFactor) ;
        end

    end

    methods (Static, Access = private)

        function [value, idx] = parseExpression(expr, idx)
            [value, idx] = InputLayerHelper.parseTerm(expr, idx) ;
            while true
                idx = InputLayerHelper.skipSpaces(expr, idx) ;
                if idx > length(expr) || ~any(expr(idx) == ['+' '-'])
                    return
                end

                op = expr(idx) ;
                [rhs, idx] = InputLayerHelper.parseTerm(expr, idx + 1) ;
                if op == '+'
                    value = value + rhs ;
                else
                    value = value - rhs ;
                end
            end
        end

        function [value, idx] = parseTerm(expr, idx)
            [value, idx] = InputLayerHelper.parsePower(expr, idx) ;
            while true
                idx = InputLayerHelper.skipSpaces(expr, idx) ;
                if idx > length(expr) || ~any(expr(idx) == ['*' '/'])
                    return
                end

                op = expr(idx) ;
                [rhs, idx] = InputLayerHelper.parsePower(expr, idx + 1) ;
                if op == '*'
                    value = value * rhs ;
                else
                    value = value / rhs ;
                end
            end
        end

        function [value, idx] = parsePower(expr, idx)
            [value, idx] = InputLayerHelper.parseUnary(expr, idx) ;
            idx = InputLayerHelper.skipSpaces(expr, idx) ;
            if idx <= length(expr) && expr(idx) == '^'
                [rhs, idx] = InputLayerHelper.parsePower(expr, idx + 1) ;
                value = value ^ rhs ;
            end
        end

        function [value, idx] = parseUnary(expr, idx)
            idx = InputLayerHelper.skipSpaces(expr, idx) ;
            if idx <= length(expr) && any(expr(idx) == ['+' '-'])
                op = expr(idx) ;
                [value, idx] = InputLayerHelper.parseUnary(expr, idx + 1) ;
                if op == '-'
                    value = -value ;
                end
                return
            end
            [value, idx] = InputLayerHelper.parsePrimary(expr, idx) ;
        end

        function [value, idx] = parsePrimary(expr, idx)
            idx = InputLayerHelper.skipSpaces(expr, idx) ;
            if idx > length(expr)
                error('InputLayerHelper:UnexpectedEnd', ...
                    'Unexpected end of expression.') ;
            end

            if expr(idx) == '('
                [value, idx] = InputLayerHelper.parseExpression(expr, idx + 1) ;
                idx = InputLayerHelper.skipSpaces(expr, idx) ;
                if idx > length(expr) || expr(idx) ~= ')'
                    error('InputLayerHelper:MissingClosingParenthesis', ...
                        'Missing closing parenthesis in expression.') ;
                end
                idx = idx + 1 ;
                return
            end

            [value, idx] = InputLayerHelper.parseNumber(expr, idx) ;
        end

        function [value, idx] = parseNumber(expr, idx)
            token = regexp(expr(idx:end), ...
                '^((\d+(\.\d*)?)|(\.\d+))([eE][\+\-]?\d+)?', 'match', 'once') ;
            if isempty(token)
                error('InputLayerHelper:ExpectedNumber', ...
                    'Expected a numeric token near "%s".', expr(idx:end)) ;
            end
            value = str2double(token) ;
            idx = idx + length(token) ;
        end

        function idx = skipSpaces(expr, idx)
            while idx <= length(expr) && isspace(expr(idx))
                idx = idx + 1 ;
            end
        end

        function rates = evaluateKineticsHandles(handles, concentrationSI, T, concentrationFactor, rateFactor)
            concentrationUser = concentrationSI(:)' / concentrationFactor ;
            ratesUser = zeros(1, numel(handles)) ;
            for i = 1:numel(handles)
                ratesUser(i) = handles{i}(concentrationUser, T) ;
            end
            rates = ratesUser * rateFactor ;
        end

        function rates = evaluateNamedKinetics(userFcn, concentrationSI, T, concentrationFactor, rateFactor)
            concentrationUser = concentrationSI(:)' / concentrationFactor ;
            ratesUser = userFcn(concentrationUser, T) ;
            rates = ratesUser(:)' * rateFactor ;
        end

    end
end
