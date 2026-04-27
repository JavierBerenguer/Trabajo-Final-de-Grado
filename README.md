# NonIdealReactorApp — Simulación de Reactores No Ideales

Herramienta de MATLAB para el análisis y simulación de reactores químicos no ideales, desarrollada como Trabajo Final de Grado (TFG) en Ingeniería Química.

Extiende la aplicación de reactores ideales de Isabela Fons con 7 módulos dedicados al análisis de distribuciones de tiempo de residencia (RTD), modelos de predicción de conversión y herramientas de ajuste y optimización.

## Requisitos

- **MATLAB R2020b o superior** (usa `uigridlayout`, `uitabgroup` programáticos)
- Toolboxes recomendados:
  - Optimization Toolbox (`fminsearch`, `fmincon`)
  - Statistics and Machine Learning Toolbox (opcional, para análisis avanzado)
- **Aspen HYSYS** (opcional) — para importar propiedades termodinámicas vía COM

## Instalación

1. Clonar o descargar el repositorio.
2. Abrir MATLAB y navegar a la carpeta `ReactorApp toolbox`.
3. Añadir la carpeta al path de MATLAB:
4. Lanzar la aplicación:

   ```matlab
   app = NonIdealReactorApp;
   ```

   O bien lanzar la aplicación de Reactores Ideales y acceder a la app de Reactores No Ideales usando el botón `No Ideal Reactor`

   ```matlab
   app = ReactorApp;
   ```

## Módulos (Tabs)

### Tab 1 — Análisis RTD

Genera o importa distribuciones de tiempo de residencia E(t), F(t) y E(θ).

* **Fuentes de datos:** expresion analitica (modelos ideales, tanques en serie y dispersion), datos experimentales (pulso/escalon), ecuacion `C(t)` y entrada manual en tabla.
* **Modelos analíticos:** CSTR ideal, PFR ideal, Tanques en Serie, Dispersión (open/closed), Flujo Laminar.
* **Resultados:** graficas E(t), F(t) y E(θ), tiempo medio de residencia (τ), varianza (σ<sup>2</sup>), varianza adimensional (σ<sub>θ</sub><sup>2</sup>), sesgo (S<sup>3</sup>), numero de tanques equivalente (N<sub>est</sub>) y volumen efectivo (V<sub>eff</sub>).
* **Exportación:** guarda la RTD calculada al workspace de MATLAB.

### Tab 2 — Modelos de Prediccion
Predice la conversión del modelo E(t), generado en la Tab 1, usando los modelos de Segregación y Máxima Mezcla.

- **Backend actual:** ambos modelos trabajan via `ReactionSys` y su ruta numerica general, no mediante ramas analiticas separadas por tipo de cinetica dentro de las clases del modelo.
- **Entrada cinetica:** el usuario define un `ReactionSys` en `defineReactionSysApp` y la tab construye `C0 = [CA0, 0, 0, ...]`.
- **Resultados:** estimacion de la conversion de salida con los modelos de Segregacion y Maxima Mezcla, que representan dos comportamientos limite de micromezcla en reactores no ideales.
- **Gráficas:** Conversión intrínseca e integrando del modelo de Segregación, la conversión de máxima mezcla y la comparativa entre las conversiones de ambos límites.

### Tab 3 — Tanques en Serie (TIS)
Modelo de N tanques CSTR iguales en serie.

- **Cálculo de N:** automático desde la varianza de la RTD experimental, o entrada manual.
- **RTD analítica:** E(t) = t^(N-1) / ((N-1)! * tau_i^N) * exp(-t/τ_i).
- **Conversion:** resolucion secuencial general de `N` balances CSTR via `ReactionSys`, con referencias `CSTR` y `PFR` calculadas con el mismo backend.
- **Importacion:** puede reutilizar RTD, `ReactionSys` y `CA0` desde Tabs 1 y 2.

### Tab 4 — Modelo de Dispersión
Reactor con dispersión axial, parametrizado por el número de Bodenstein (Bo = u*L/De).

- **Condiciones de contorno:** open-open (Gaussiana) y closed-closed (Danckwerts).
- **Limites:** Bo -> 0 reproduce CSTR; Bo -> infinito reproduce PFR.
- **Conversion:** ruta general numerica basada en `ReactionSys` y en la RTD de dispersion.

## Módulos (Tabs) en desarrollo

### Tab 5 — Convolución / Deconvolución
Herramienta matricial para predecir senales de salida o recuperar la RTD.

- **Convolución:** dada E(t) y C_in(t), calcula C_out(t) = integral(E(t') * C_in(t-t') dt').
- **Deconvolución:** dados C_in(t) y C_out(t), recupera E(t) por minimización (fminsearch).
- **Verificación:** recalcula C_out a partir del E(t) recuperado para validar.
- **Importación:** puede cargar E(t) desde el Tab 1 o desde archivo.

### Tab 6 — Modelos Combinados
Modelos de reactor con volumen muerto, bypass y zonas de intercambio.

- **Configuraciones:** CSTR con volumen muerto, CSTR con bypass, CSTR con intercambio, PFR+CSTR en serie y combinaciones.
- **Parámetros:** α (fracción activa), β (fracción de bypass/intercambio).
- **Análisis de sensibilidad:** barrido paramétrico con gráficas de conversión vs parámetro.

### Tab 7 — Optimizacion (Ajuste de Modelos)
Ajusta datos experimentales de RTD a 6 modelos teoricos.

- **Modelos:** N-CSTR, Dispersión open-open, Dispersión closed-closed, PFR+CSTR serie, Volumen muerto, Bypass.
- **Método:** minimización por fminsearch del error cuadrático.
- **Resultados:** tabla comparativa con parámetros óptimos, R^2, y ranking de modelos.
- **Gráficas:** superposición de todos los ajustes sobre los datos experimentales.

## Conversor de Unidades

Accesible desde el botón "Conversor de Unidades" en cualquier tab.

Incluye categorias para tiempo, volumen, concentracion, caudal, presion, temperatura, constantes cineticas y otras magnitudes auxiliares del toolbox.

```matlab
UnitConverterHelper.launch()   % Abre la ventana flotante
```

## Unidades Internas (SI)

Todas las clases trabajan internamente en unidades SI:

| Magnitud       | Unidad         |
|----------------|----------------|
| Tiempo         | s              |
| Volumen        | m^3            |
| Concentración  | mol/m^3        |
| Caudal         | m^3/s          |
| Presión        | Pa             |
| Temperatura    | K              |
| k (1er orden)  | 1/s            |
| k (2do orden)  | m^3/(mol*s)    |

El conversor de unidades facilita la traducción entre las unidades del problema y las unidades internas.

## Estructura del Proyecto

```
ReactorApp toolbox/
  NonIdealReactorApp.m    App principal (7 tabs, ~3500 líneas)
  RTD.m                   Clase RTD + 10 métodos factory estáticos
  SegregationModel.m      Modelo de segregación via ReactionSys
  MaxMixednessModel.m     Modelo de máxima mezcla via ReactionSys
  DispersionReactor.m     Reactor de dispersión axial
  TanksInSeries.m         N tanques en serie
  ConvolutionTool.m       Convolución/deconvolución matricial
  UnitConverterHelper.m   Conversor de unidades flotante (9 categorías)
  Reactor.m               Clase base (serie, paralelo, reciclo, coste)
  CSTR.m, PFR.m, Batch.m  Reactores ideales (Isabela Fons)
  Stream.m                Corrientes con propiedades
  ReactionSys.m           Sistema de reacciones (Arrhenius, LH, custom)
  call_DataBase.m         Interfaz COM con Aspen HYSYS
  computeCost.m           TAC (Total Annual Cost)
  Datos Problemas no ideales.xlsx   Datos experimentales
  +cmu/                   Librería de unidades CMU
  html/                   Ejemplos publicados
```

## Integración con Aspen HYSYS

Todas las clases de reactores no ideales incluyen placeholders `[HYSYS]` para importar propiedades termodinámicas:

- Constantes cinéticas (k vía Arrhenius con parámetros de HYSYS)
- Concentraciones de entrada (CA0 desde composición de corriente)
- Parámetros enzimáticos y de equilibrio
- Número de Bodenstein (Bo desde Re, Sc, correlaciones)
- Número de tanques (N desde geometría y propiedades del fluido)

La clase `Stream.m` ya implementa `defineStreamFromHysys()` para conectar con HYSYS.

## Validacion

Actualmente no hay un harness de tests visible en el arbol principal con los nombres historicos `Test_NonIdealReactors` o `Test_ReferenceProblems`.

La validacion reciente del bloque no ideal se esta haciendo mediante:

- problemas de referencia contrastados manualmente
- smoke tests ejecutados via `matlab -batch`
- documentacion tecnica en `Documentation/`

## Problemas de Referencia

La app está diseñada para resolver los problemas 51-64 del material de Reactores Reales. Los datos experimentales se encuentran en `Datos Problemas no ideales.xlsx`. Los PDFs con los enunciados están en la carpeta `Problemas Reactores Reales/`.

## Autor

**Javier Berenguer Sabater**
Trabajo Final de Grado — Ingeniería Química
Marzo 2026

Basado en la aplicación de reactores ideales de **Isabela Fons**.

## Licencia

MIT License. Ver [LICENSE](LICENSE).
