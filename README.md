# NonIdealReactorApp — Simulacion de Reactores No Ideales

Herramienta de MATLAB para el analisis y simulacion de reactores quimicos no ideales, desarrollada como Trabajo Final de Grado (TFG) en Ingenieria Quimica.

Extiende la aplicacion de reactores ideales de Isabela Fons con 7 modulos dedicados al analisis de distribuciones de tiempo de residencia (RTD), modelos de prediccion de conversion, y herramientas de ajuste y optimizacion.

## Requisitos

- **MATLAB R2020b o superior** (usa `uigridlayout`, `uitabgroup` programaticos)
- Toolboxes recomendados:
  - Optimization Toolbox (`fminsearch`, `fmincon`)
  - Statistics and Machine Learning Toolbox (opcional, para analisis avanzado)
- **Aspen HYSYS** (opcional) — para importar propiedades termodinamicas via COM

## Instalacion

1. Clonar o descargar el repositorio.
2. Abrir MATLAB y navegar a la carpeta `TFG Base Isabela Fons/ReactorApp toolbox/`.
3. Anadir la carpeta al path de MATLAB:
   ```matlab
   addpath(genpath(pwd))
   ```
4. Lanzar la aplicacion:
   ```matlab
   app = NonIdealReactorApp;
   ```

## Modulos (Tabs)

### Tab 1 — Analisis RTD
Genera o importa distribuciones de tiempo de residencia E(t), F(t) y E(theta).

- **Fuentes de datos:** expresion analitica, datos experimentales (pulso/escalon), importacion desde archivo Excel, o entrada manual en tabla.
- **Modelos analiticos:** CSTR ideal, PFR ideal, Tanques en Serie, Dispersion (open/closed), Flujo Laminar.
- **Estadisticos:** tiempo medio de residencia (tau), varianza (sigma^2), varianza adimensional, sesgo (s3), N equivalente.
- **Volumen muerto:** calculo a partir de V_total y caudal volumetrico Q_v.
- **Exportacion:** guarda la RTD calculada al workspace de MATLAB.

### Tab 2 — Modelos de Prediccion
Predice la conversion usando los modelos de Segregacion y Maxima Mezcla.

- **Cineticas soportadas:** 1er Orden, 2do Orden, Michaelis-Menten, Reversible 1er Orden, Reacciones Paralelas, Ley de velocidad personalizada.
- **Resultados:** conversion media X, comparacion entre segregacion (limite superior para n>1) y maxima mezcla (limite inferior para n>1).
- **Graficas:** X_batch(t) y contribucion ponderada X(t)*E(t).

### Tab 3 — Tanques en Serie (TIS)
Modelo de N tanques CSTR iguales en serie.

- **Calculo de N:** automatico desde la varianza de la RTD experimental, o entrada manual.
- **RTD analitica:** E(t) = t^(N-1) / ((N-1)! * tau_i^N) * exp(-t/tau_i).
- **Conversion:** solucion analitica para 1er orden; resolucion secuencial de N balances CSTR para otros ordenes.
- **Importacion:** reutiliza parametros del Tab 2 (cinetica, k, CA0).

### Tab 4 — Modelo de Dispersion
Reactor con dispersion axial, parametrizado por el numero de Bodenstein (Bo = u*L/De).

- **Condiciones de contorno:** open-open (Gaussiana) y closed-closed (Danckwerts).
- **Limites:** Bo -> 0 reproduce CSTR; Bo -> infinito reproduce PFR.
- **Conversion:** solucion analitica (1er orden) o numerica (otros ordenes).

### Tab 5 — Convolucion / Deconvolucion
Herramienta matricial para predecir senales de salida o recuperar la RTD.

- **Convolucion:** dada E(t) y C_in(t), calcula C_out(t) = integral(E(t') * C_in(t-t') dt').
- **Deconvolucion:** dados C_in(t) y C_out(t), recupera E(t) por minimizacion (fminsearch).
- **Verificacion:** recalcula C_out a partir del E(t) recuperado para validar.
- **Importacion:** puede cargar E(t) desde el Tab 1 o desde archivo.

### Tab 6 — Modelos Combinados
Modelos de reactor con volumen muerto, bypass y zonas de intercambio.

- **Configuraciones:** CSTR con volumen muerto, CSTR con bypass, CSTR con intercambio, PFR+CSTR en serie, y combinaciones.
- **Parametros:** alpha (fraccion activa), beta (fraccion de bypass/intercambio).
- **Analisis de sensibilidad:** barrido parametrico con graficas de conversion vs parametro.

### Tab 7 — Optimizacion (Ajuste de Modelos)
Ajusta datos experimentales de RTD a 6 modelos teoricos.

- **Modelos:** N-CSTR, Dispersion open-open, Dispersion closed-closed, PFR+CSTR serie, Volumen muerto, Bypass.
- **Metodo:** minimizacion por fminsearch del error cuadratico.
- **Resultados:** tabla comparativa con parametros optimos, R^2, y ranking de modelos.
- **Graficas:** superposicion de todos los ajustes sobre los datos experimentales.

## Conversor de Unidades

Accesible desde el boton "Conversor de Unidades" en cualquier tab.

**9 categorias:** Tiempo, Volumen, Concentracion, Caudal, Presion, Temperatura, Constante cinetica (1er y 2do orden), Energia, Difusividad, Viscosidad, Longitud, Area.

```matlab
UnitConverterHelper.launch()   % Abre la ventana flotante
```

## Unidades Internas (SI)

Todas las clases trabajan internamente en unidades SI:

| Magnitud       | Unidad         |
|----------------|----------------|
| Tiempo         | s              |
| Volumen        | m^3            |
| Concentracion  | mol/m^3        |
| Caudal         | m^3/s          |
| Presion        | Pa             |
| Temperatura    | K              |
| k (1er orden)  | 1/s            |
| k (2do orden)  | m^3/(mol*s)    |

El conversor de unidades facilita la traduccion entre las unidades del problema y las unidades internas.

## Estructura del Proyecto

```
ReactorApp toolbox/
  NonIdealReactorApp.m    App principal (7 tabs, ~3500 lineas)
  RTD.m                   Clase RTD + 10 metodos factory estaticos
  SegregationModel.m      Modelo de segregacion (6 cineticas)
  MaxMixednessModel.m     Modelo de maxima mezcla (6 cineticas)
  DispersionReactor.m     Reactor dispersion axial (hereda de Reactor)
  TanksInSeries.m         N tanques en serie (hereda de Reactor)
  ConvolutionTool.m       Convolucion/deconvolucion matricial
  UnitConverterHelper.m   Conversor de unidades flotante (9 categorias)
  Reactor.m               Clase base (serie, paralelo, reciclo, coste)
  CSTR.m, PFR.m, Batch.m  Reactores ideales (Isabela Fons)
  Stream.m                Corrientes con propiedades
  ReactionSys.m           Sistema de reacciones (Arrhenius, LH, custom)
  call_DataBase.m         Interfaz COM con Aspen HYSYS
  computeCost.m           TAC (Total Annual Cost)
  Test_NonIdealReactors.m Tests de validacion (15 casos)
  Test_ReferenceProblems.m Verificacion problemas 51-64
  Datos Problemas no ideales.xlsx   Datos experimentales
  +cmu/                   Libreria de unidades CMU
  html/                   Ejemplos publicados
```

## Integracion con Aspen HYSYS

Todas las clases de reactores no ideales incluyen placeholders `[HYSYS]` para importar propiedades termodinamicas:

- Constantes cineticas (k via Arrhenius con parametros de HYSYS)
- Concentraciones de entrada (CA0 desde composicion de corriente)
- Parametros enzimaticos y de equilibrio
- Numero de Bodenstein (Bo desde Re, Sc, correlaciones)
- Numero de tanques (N desde geometria y propiedades del fluido)

La clase `Stream.m` ya implementa `defineStreamFromHysys()` para conectar con HYSYS.

## Tests

Ejecutar los tests desde MATLAB:

```matlab
% Tests de limites fisicos (15 casos)
results = runtests('Test_NonIdealReactors');

% Verificacion de problemas de referencia (problemas 51-64)
results = runtests('Test_ReferenceProblems');
```

## Problemas de Referencia

La app esta disenada para resolver los problemas 51-64 del material de Reactores Reales. Los datos experimentales se encuentran en `Datos Problemas no ideales.xlsx`. Los PDFs con los enunciados estan en la carpeta `Problemas Reactores Reales/`.

## Autor

**Javier Berenguer Sabater**
Trabajo Final de Grado — Ingenieria Quimica
Marzo 2026

Basado en la aplicacion de reactores ideales de **Isabela Fons**.

## Licencia

MIT License. Ver [LICENSE](LICENSE).
