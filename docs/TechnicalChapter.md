# Technical Chapter - Non-Ideal Reactor Analysis Application

**Javier Berenguer Sabater**  
TFG - Chemical Engineering

---

## 1. Introduction

This chapter describes the current implementation state of the non-ideal reactor application after the cleanup of unused legacy API in Tabs 1-4. It focuses on the code that is still active in:

- RTD Analysis
- Prediction Models
- Tanks-in-Series
- Dispersion Model

Tabs 5-7 remain part of the application, but they are not the reference scope for the simplified model APIs described here.

---

## 2. Architecture Overview

### 2.1 Technology Choice

The application uses MATLAB programmatic UI (`uifigure`, `uigridlayout`, `uitabgroup`) rather than App Designer. This keeps the app in text `.m` files and integrates cleanly with the inherited reactor toolbox.

### 2.2 Class Hierarchy

```
Reactor (abstract base class - inherited)
|-- CSTR
|-- PFR
|-- Batch
`-- TanksInSeries

RTD
SegregationModel
MaxMixednessModel
DispersionReactor
ConvolutionTool
UnitConverterHelper
NonIdealReactorApp
```

### 2.3 File Structure

```
ReactorApp toolbox/
  NonIdealReactorApp.m
  RTD.m
  SegregationModel.m
  MaxMixednessModel.m
  TanksInSeries.m
  DispersionReactor.m
  ConvolutionTool.m
  UnitConverterHelper.m
  InputLayerHelper.m
  ReactionSys.m
  Reactor.m
  CSTR.m
  PFR.m
  Batch.m
  Stream.m
  docs/
    UserGuide.md
    TechnicalChapter.md
```

No visible files named `Test_NonIdealReactors.m` or `Test_ReferenceProblems.m` are currently present in the working tree.

---

## 3. Core Design Decisions

### 3.1 Internal Units

All numerical calculations are carried out in SI units:

| Quantity | Unit |
|---|---|
| Time | s |
| Volume | m^3 |
| Concentration | mol/m^3 |
| Flow rate | m^3/s |
| Pressure | Pa |
| Temperature | K |

Input conversion happens in the UI layer. Output conversion happens only when values are rendered back to the user.

### 3.2 Shared Data Flow

The active pipeline across Tabs 1-4 is:

```text
Tab 1 (RTD) -> app.rtd
Tab 2 (Prediction) -> app.Pred_RS + CA0
Tab 3 (TIS) -> optional import from Tabs 1-2
Tab 4 (Dispersion) -> optional import from Tabs 1-2
```

### 3.3 Reaction Definition Strategy

The current implementation does not branch inside the model classes by a hardcoded kinetics menu. Instead, Tabs 2-4 rely on:

- `ReactionSys`
- `ReactionSys.computeRate(concentration, T)`

This means the non-ideal models now operate through a common general kinetics path.

---

## 4. Mathematical Models

### 4.1 RTD Analysis

Tab 1 builds an `RTD` object from:

- analytical models
- pulse data
- step data
- `C(t)` equations
- tabular input

The `RTD` constructor normalizes `E(t)` and computes:

- `tau`
- `sigma^2`
- `sigma_theta^2`
- `s3`
- `F(t)`
- `E(theta)`

The tab also reports:

```math
V_{eff} = \tau \, Q_v
```

### 4.2 Segregation Model

`SegregationModel` now exposes a single active solver:

```text
compute_isothermal(RS, C0)
```

It solves the batch ODE:

```math
\frac{dC}{dt} = r(C)\,\nu
```

and then computes:

```math
X_{seg} = \int_0^\infty X_{batch}(t)\,E(t)\,dt
```

This is the route used by Tab 2.

### 4.3 Maximum Mixedness Model

`MaxMixednessModel` was simplified in the same way and now uses:

```text
compute_isothermal(RS, C0)
```

The model integrates in life-expectancy coordinates:

```math
\frac{dX}{d\lambda} = \frac{r_A(C)}{C_{A0}} + \frac{E(\lambda)}{1-F(\lambda)}X
```

with the exit conversion given by:

```math
X_{MM} = X(\lambda = 0)
```

### 4.4 Tanks-in-Series

The active backend for Tab 3 is:

- `TanksInSeries.solve_sequential(N, RS, C0, tau_total)`
- `TanksInSeries.solve_PFR(RS, C0, tau_total)`

Each CSTR stage solves:

```math
C_{out} - C_{in} - \tau_i\,r(C_{out})\,\nu = 0
```

The tab computes `N` from RTD moments directly in the app when needed:

```math
N = \tau^2 / \sigma^2
```

### 4.5 Dispersion Model

The active backend for Tab 4 is:

- `generate_RTD(tau)`
- `compute_conversion_general(RS, C0, tau)`
- `sweep_Bo_general(RS, C0, tau, n_points)`

The class no longer exposes active analytical branches by reaction order. Instead it:

1. generates the dispersion RTD
2. solves the batch ODE through `ReactionSys`
3. integrates `X_batch(t) * E(t)`

---

## 5. UI Layer

### 5.1 Input Layer

`NonIdealReactorApp` now includes:

- text-based numeric input
- simple arithmetic parsing
- per-field unit selectors
- normalization to SI before computation

`C(t) Equation` in Tab 1 uses a shared time unit for:

- `t start`
- `t end`
- the variable `t` inside the expression

### 5.2 Output Layer

Results and axes can be displayed in user-selected units without changing the internal calculations. Output controls are grouped by base magnitude and placed below `Compute` / `Generate RTD`.

---

## 6. Validation Strategy

Current validation for Tabs 1-4 relies on:

- smoke tests executed through `matlab -batch`
- comparison against reference problems
- targeted checks after refactors and API cleanup

This has been especially important after the removal of unused legacy methods from:

- `SegregationModel`
- `MaxMixednessModel`
- `TanksInSeries`
- `DispersionReactor`

---

## 7. Known Limitations

1. The app still assumes `C0 = [CA0, 0, 0, ...]` in the active Tabs 2-4 workflow.
2. Several flows still depend on `evalin` and `assignin`.
3. Tabs 5-7 still contain older logic that is expected to be reworked later.
4. Some historical documentation outside this file may lag behind implementation and must be interpreted with care.

---

## 8. Current Documentation Map

For the active Tabs 1-4 block, the detailed documents are now:

- `Documentation/SegregationModel.md`
- `Documentation/MaxMixednessModel.md`
- `Documentation/TanksInSeries.md`
- `Documentation/DispersionReactor.md`
- `Documentation/DOCUMENTO_TECNICO.md`
