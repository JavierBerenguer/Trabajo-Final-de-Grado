# NonIdealReactorApp - Simulacion de Reactores No Ideales

Herramienta de MATLAB para analizar reactores no ideales a partir de distribuciones de tiempo de residencia (RTD) y modelos limite de mezcla.

La app actual se ha acotado a **4 tabs**:

1. `RTD Analysis`
2. `Prediction Models`
3. `Tanks-in-Series`
4. `Dispersion Model`

## Requisitos

- `MATLAB R2020b` o superior
- `Statistics and Machine Learning Toolbox` opcional
- `Aspen HYSYS` opcional para integracion via COM

## Lanzamiento

Desde MATLAB, situate en `ReactorApp toolbox/` y ejecuta:

```matlab
app = NonIdealReactorApp;
```

Tambien puedes abrir primero la app base de reactores ideales:

```matlab
app = ReactorApp;
```

## Alcance funcional

### Tab 1 - RTD Analysis

- Generacion o importacion de `E(t)`, `F(t)` y `E(theta)`.
- Fuentes: modelos ideales, Tanks-in-Series, dispersion, datos experimentales, `C(t)` y tabla manual.
- Resultados: `tau_m`, `sigma^2`, `sigma_theta^2`, `s^3`, `N_est` y `V_eff`.

### Tab 2 - Prediction Models

- Prediccion de conversion con `SegregationModel` y `MaxMixednessModel`.
- Uso de `ReactionSys` definido desde la UI o cargado desde workspace.
- `Display units` en este tab se centra en concentracion y seleccion de especies/reactivos; no incluye `Time base`.
- Comparacion de conversion por reactivo entre `Segregation`, `Max Mixedness`, `CSTR` y `PFR`.
- Comparacion de concentracion de salida para todas las especies, con multiseleccion independiente de reactivos y especies.
- Leyenda compartida entre ambas graficas para los cuatro modelos comparados.

### Tab 3 - Tanks-in-Series

- Modelo de `N` CSTR iguales en serie.
- `N` manual o estimado desde la RTD de la Tab 1.
- Comparacion de conversion con referencias `CSTR` y `PFR`.

### Tab 4 - Dispersion Model

- Modelo de dispersion axial parametrizado con `Bo`.
- Soporte para contornos `open-open` y `closed-closed`.
- Comparacion de conversion con referencias `CSTR` y `PFR`.

## Unidades

La app convierte entradas a SI internamente y permite seleccionar unidades de visualizacion por tab.

```matlab
UnitConverterHelper.launch()
```

## Estructura principal

```text
ReactorApp toolbox/
  NonIdealReactorApp.m
  RTD.m
  SegregationModel.m
  MaxMixednessModel.m
  TanksInSeries.m
  DispersionReactor.m
  ReactionSys.m
  UnitConverterHelper.m
  InputLayerHelper.m
  defineReactionSysApp.m
  docs/
```

## Validacion

La validacion reciente del bloque no ideal se apoya en:

- problemas de referencia revisados manualmente
- smoke tests ejecutados via `matlab -batch`
- documentacion tecnica en `Documentation/`

## Autor

Javier Berenguer Sabater  
TFG - Ingenieria Quimica  
Marzo 2026
