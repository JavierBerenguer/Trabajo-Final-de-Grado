# NonIdealReactorApp - Simulacion de Reactores No Ideales

Herramienta de MATLAB para analizar reactores no ideales a partir de distribuciones de tiempo de residencia (RTD) y modelos limite de mezcla.

La app actual se ha acotado a **5 tabs**:

1. `RTD Analysis`
2. `Prediction Models`
3. `Tanks-in-Series`
4. `Dispersion Model`
5. `Design & Optimization`

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

## Sesiones

- `File > Guardar` crea un archivo `.mat` de sesion dentro de `saves/`.
- `File > Cargar` restaura los inputs, objetos `RTD` / `ReactionSys` / `Stream` y las selecciones de visualizacion para continuar trabajando sin reintroducir datos.
- La carga no recalcula automaticamente; deja la app lista para pulsar `Compute`.

## Alcance funcional

### Tab 1 - RTD Analysis

- Generacion o importacion de `E(t)`, `F(t)` y `E(theta)`.
- Fuentes: modelos ideales, Tanks-in-Series, dispersion, datos experimentales, `C(t)` y tabla manual.
- Resultados: `tau_m`, `sigma^2`, `sigma_theta^2`, `s^3`, `N_est` y `V_eff`.

### Tab 2 - Prediction Models

- Prediccion de conversion con `SegregationModel` y `MaxMixednessModel`.
- Uso de `ReactionSys` definido desde la UI o cargado desde workspace.
- `Display units` en este tab se centra en concentracion y seleccion de especies/reactivos; no incluye `Time base`.
- Comparacion de conversion por reactivo con orden fijo `CSTR`, `Segregation`, `Max Mixedness` y `PFR`.
- Comparacion de concentracion de salida para todas las especies, con multiseleccion independiente de reactivos y especies.
- Leyenda compartida entre ambas graficas para los cuatro modelos comparados.
- Resumen compacto `Non-Ideal Mixing Effect (%)` con la perdida relativa de conversion frente a `PFR`.

### Tab 3 - Tanks-in-Series

- Modelo de `N` CSTR iguales en serie.
- `N` manual o estimado desde la RTD de la Tab 1.
- Comparacion de conversion con referencias `CSTR` y `PFR`.

### Tab 4 - Dispersion Model

- Modelo de dispersion axial parametrizado con `Bo`.
- Soporte para contornos `open-open` y `closed-closed`.
- `Display units` reorganizado como en `Tanks-in-Series`: `Time base` solo para `E(t)`, `Concentration` para concentraciones y listas multiseleccion para `Species` y `Reactants`.
- Graficas superiores `Outlet Concentration vs Bo` y `Conversion vs Bo`, ambas filtrables por multiseleccion.
- Tabla `Exit Summary` con `C_in`, `Disp C_out`, referencias `CSTR`/`PFR` y conversion por reactivo.
- `E(t)` se mantiene en la parte inferior derecha con anotacion de `Bo`, `Pe` y `tau`.

### Tab 5 - Design & Optimization

- Workspace abierto para trabajo no ideal en tres subareas:
  - `Diagnosis & Fit`
  - `Reactive Performance`
  - `Optimization`
- La caracterizacion RTD se hace en `Tab 1 - RTD Analysis`; Tab 5 ya no duplica esa etapa.
- `Diagnosis & Fit` ajusta `Tanks-in-Series`, `Axial Dispersion`, `CSTR + Dead Volume`, `CSTR + Bypass` y `CSTR + Dead Volume + Bypass` a partir de la RTD de Tab 1.
- `Reactive Performance` compara `Ideal CSTR`, `Segregation`, `Max Mixedness` e `Ideal PFR`, e incluye deteccion directa de 1er orden cuando aplica.
- `Optimization` optimiza sobre `tau`, `N`, `Bo`, `bypass`, `activeFraction` y `recycleRatio` reutilizando la quimica cargada en `Reactive Performance`.
- La persistencia de sesion ya incluye snapshot propio `designWorkspace`.

## Unidades

La app convierte entradas a SI internamente y permite seleccionar unidades de visualizacion por tab.

```matlab
UnitConverterHelper.launch()
```

## Estructura principal

```text
ReactorApp toolbox/
  NonIdealReactorApp.m
  DesignWorkspaceHelper.m
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
