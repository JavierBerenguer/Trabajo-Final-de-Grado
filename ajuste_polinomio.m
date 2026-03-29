function [coeficientes, ecuacion_str, grado] = ajuste_polinomio_auto(t, Et)
%AJUSTE_POLINOMIO_AUTO Ajusta automáticamente un polinomio a datos (t, Et).
%   Esta función toma únicamente dos vectores de datos: t (variable
%   independiente) y Et (variable dependiente). Determina el grado
%   mínimo del polinomio que reproduce los datos con alta precisión y
%   devuelve los coeficientes y la ecuación de la curva ajustada.  Se
%   utiliza la función polyfit para calcular los coeficientes del
%   polinomio de grado n, que devuelve el vector de coeficientes en
%   orden descendente【272504949180872†L87-L90】. En general, con n puntos
%   distintos se puede ajustar un polinomio de grado n‑1 que pasa
%   exactamente por todos ellos【272504949180872†L205-L210】.
%
%   Sintaxis:
%      [coef, ecuacion, grado] = ajuste_polinomio_auto(t, Et)
%
%   Entradas:
%      t  - Vector de valores de la variable independiente.  Debe ser un
%           vector numérico de una dimensión.
%      Et - Vector de valores de la variable dependiente, con la misma
%           longitud que t.
%
%   Salidas:
%      coeficientes - Vector de coeficientes del polinomio en orden
%                     descendente de potencias.
%      ecuacion_str - Cadena con la ecuación en formato legible.
%      grado        - Grado del polinomio elegido para el ajuste.
%
%   Este algoritmo evalúa polinomios de grado creciente (desde 1 hasta
%   un máximo predeterminado) y calcula el coeficiente de determinación
%   (R^2).  Selecciona el grado más pequeño que produce un R^2 mayor
%   que un umbral (por ejemplo, 0.999), lo que indica que el ajuste
%   explica prácticamente toda la variación de los datos.  Si los datos
%   son constantes o el umbral no se alcanza, utiliza el grado más alto
%   disponible.

    % Comprobar que los vectores tienen la misma longitud
    if numel(t) ~= numel(Et)
        error('Los vectores t y Et deben tener la misma longitud.');
    end
    % Asegurarse de que sean vectores columna
    t  = t(:);
    Et = Et(:);
    nDatos = numel(t);

    % Si todos los valores de Et son iguales, el mejor ajuste es un
    % polinomio de grado 0 (constante).  polyfit puede hacerse cargo
    % directamente de esto.
    if all(abs(diff(Et)) < eps)
        grado = 0;
        coeficientes = mean(Et);
        ecuacion_str = sprintf('Et = %.4f', coeficientes);
        fprintf('Los datos son constantes; la ecuación ajustada es:\n  %s\n', ecuacion_str);
        return;
    end

    % Definir el grado máximo a probar.  Limitarlo evita ajustarse a
    % polinomios de orden excesivamente alto.  Utilizamos como límite
    % mínimo el número de puntos menos uno, pero nunca más de 10.
    grado_max = min(nDatos - 1, 10);
    umbral_R2 = 0.999;  % Umbral de R^2 para considerar el ajuste satisfactorio
    grado = grado_max;
    mejor_R2 = -inf;

    for g = 1:grado_max
        % Calcular el ajuste polinómico y evaluar el R^2
        p = polyfit(t, Et, g);
        Et_pred = polyval(p, t);
        % Error residual (suma de cuadrados)
        sse = sum((Et - Et_pred).^2);
        % Varianza total
        ss_tot = sum((Et - mean(Et)).^2);
        if ss_tot == 0
            % Todos los valores de Et son iguales; tratar como constante
            R2 = 1;
        else
            R2 = 1 - sse/ss_tot;
        end
        if R2 > mejor_R2
            mejor_R2 = R2;
            grado = g;
        end
        % Si se alcanza el umbral, salir del bucle
        if R2 >= umbral_R2
            grado = g;
            break;
        end
    end

    % Calcular los coeficientes finales con el grado seleccionado
    coeficientes = polyfit(t, Et, grado);

    % Construir la cadena de la ecuación de manera similar a la función
    % ajuste_polinomio
    ecuacion_str = '';
    for i = 1:length(coeficientes)
        coef = coeficientes(i);
        pot = grado - (i - 1);
        if abs(coef) < eps
            continue;
        end
        % Seleccionar signo y valor absoluto
        if coef < 0
            signo = ' - ';
            valor = abs(coef);
        else
            if isempty(ecuacion_str)
                signo = '';
            else
                signo = ' + ';
            end
            valor = coef;
        end
        % Construir término según la potencia
        if pot == 0
            termino = sprintf('%.4f', valor);
        elseif pot == 1
            if abs(valor - 1) > eps
                termino = sprintf('%.4f*t', valor);
            else
                termino = 't';
            end
        else
            if abs(valor - 1) > eps
                termino = sprintf('%.4f*t^%d', valor, pot);
            else
                termino = sprintf('t^%d', pot);
            end
        end
        ecuacion_str = [ecuacion_str, signo, termino]; %#ok<AGROW>
    end
    % Preceder la expresión con el nombre de la variable dependiente
    ecuacion_str = ['Et = ', ecuacion_str];
    % Mostrar resultados
    fprintf('Se ha seleccionado un polinomio de grado %d (R^2 = %.4f).\n', grado, mejor_R2);
    fprintf('La ecuación ajustada es:\n  %s\n', ecuacion_str);
end