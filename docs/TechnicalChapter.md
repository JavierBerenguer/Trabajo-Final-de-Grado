# Technical Chapter — Non-Ideal Reactor Analysis Application

**Javier Berenguer Sabater**
TFG — Chemical Engineering, March 2026

---

## 1. Introduction

This chapter describes the architecture, design decisions, and implementation details of the Non-Ideal Reactor Analysis application developed in MATLAB. The application provides a graphical interface for Residence Time Distribution (RTD) analysis, conversion prediction, and reactor modeling using the theoretical framework from Fogler's *Elements of Chemical Reaction Engineering* and Levenspiel's *Chemical Reaction Engineering*.

The application extends a previous reactor simulation toolbox (ideal reactors: CSTR, PFR, Batch) developed by Isabela Fons, adding non-ideal reactor analysis capabilities through a new programmatic GUI.

---

## 2. Architecture Overview

### 2.1 Technology Choice

The application uses **MATLAB programmatic UI** (uifigure, uigridlayout, uitabgroup) rather than App Designer. This decision was made because:

- Full control over layout and component positioning.
- Easier version control (single `.m` file, no binary `.mlapp`).
- Direct integration with existing class hierarchy (Reactor, CSTR, PFR, etc.).
- Simpler debugging workflow.

### 2.2 Class Hierarchy

```
Reactor (abstract base class — Isabela Fons)
├── CSTR
├── PFR
├── Batch
└── TanksInSeries (new — extends Reactor)

RTD (standalone class — new)
SegregationModel (standalone — new)
MaxMixednessModel (standalone — new)
DispersionReactor (standalone — new)
ConvolutionTool (static methods — new)
UnitConverterHelper (static methods — new)
NonIdealReactorApp (handle class — main GUI)
```

### 2.3 File Structure

```
ReactorApp toolbox/
├── NonIdealReactorApp.m    (~3700 lines, main GUI)
├── RTD.m                   (RTD class, 10 factory methods)
├── SegregationModel.m      (Segregation model, 6 kinetics)
├── MaxMixednessModel.m     (Max mixedness model, 6 kinetics)
├── DispersionReactor.m     (Axial dispersion, open/closed BC)
├── TanksInSeries.m         (N-CSTR model, extends Reactor)
├── ConvolutionTool.m       (Static convolution/deconvolution)
├── UnitConverterHelper.m   (Unit conversion utility)
├── Reactor.m               (Base class — inherited)
├── CSTR.m                  (Ideal CSTR — inherited)
├── PFR.m                   (Ideal PFR — inherited)
├── Batch.m                 (Ideal Batch — inherited)
├── Stream.m                (Stream data — inherited)
├── ReactionSys.m           (Reaction system — inherited)
├── Test_NonIdealReactors.m (Unit tests)
├── Test_ReferenceProblems.m(Reference problem validation)
└── docs/
    ├── UserGuide.md
    └── TechnicalChapter.md
```

---

## 3. Design Decisions

### 3.1 Internal Units

All internal computations use SI units exclusively:

| Quantity | Unit | Rationale |
|----------|------|-----------|
| Time | s | Consistent with MATLAB's ODE solvers |
| Volume | m^3 | SI base |
| Concentration | mol/m^3 | Avoids ambiguity with L vs m^3 |
| Flow rate | m^3/s | Consistent V/Q = tau in seconds |
| Pressure | Pa | SI base |
| Temperature | K | Required for Arrhenius calculations |

A separate `UnitConverterHelper` class provides conversions for the user.

### 3.2 UI Layout Convention

Every tab follows a consistent 2-column layout:

- **Left panel** (320px fixed): Input controls in a `uigridlayout` with labeled rows.
- **Right panel** (`'1x'` flexible): Plot axes in a `uigridlayout`.

This pattern ensures visual consistency and makes the code predictable.

### 3.3 Tab Naming Prefixes

All UI component properties use tab-specific prefixes to avoid naming collisions:

| Tab | Prefix | Example |
|-----|--------|---------|
| RTD Analysis | `RTD_` | `RTD_SourceDropdown` |
| Prediction | `Pred_` | `Pred_KineticsDropdown` |
| Tanks-in-Series | `TIS_` | `TIS_NField` |
| Dispersion | `Disp_` | `Disp_BoField` |
| Convolution | `Conv_` | `Conv_ModeDropdown` |
| Combined | `Comb_` | `Comb_ModelDropdown` |
| Optimization | `Opt_` | `Opt_FitButton` |

### 3.4 Cross-Tab Data Sharing

The `app.rtd` property (an `RTD` object) is shared across Tabs 1-4. When Tab 1 generates or imports an RTD, it stores the result in `app.rtd`. Tabs 2-4 read from this shared property, showing an "RTD loaded/not loaded" status label.

Tab 5 (Convolution) can optionally import E(t) from `app.rtd` via the "From Tab 1 (RTD)" source mode.

---

## 4. Mathematical Models

### 4.1 RTD Fundamentals

The RTD function E(t) describes the distribution of residence times for fluid elements exiting a reactor:

- **Normalization**: integral_0^inf E(t) dt = 1
- **Mean residence time**: tau_m = integral_0^inf t * E(t) dt
- **Variance**: sigma^2 = integral_0^inf (t - tau_m)^2 * E(t) dt
- **Cumulative**: F(t) = integral_0^t E(t') dt'

Implementation: `RTD.m` constructor computes moments numerically using `trapz()`.

### 4.2 Segregation Model

Models the reactor as a collection of batch reactors with residence times distributed according to E(t):

```
X_seg = integral_0^inf X_batch(t) * E(t) dt
```

Where X_batch(t) is the batch conversion at time t for the given kinetics.

Implementation: `SegregationModel.m` solves the batch ODE for each kinetics type, then integrates X_batch(t) * E(t) numerically.

### 4.3 Maximum Mixedness Model

Assumes complete mixing at the molecular level at the earliest possible point:

```
dX/dlambda = r_A(X) / C_A0 + E(lambda) / (1 - F(lambda)) * X
```

Where lambda is the life expectancy (time remaining in reactor). Integration proceeds from lambda = inf (reactor entrance) to lambda = 0 (exit).

Implementation: `MaxMixednessModel.m` uses `ode45` with the reversed lambda coordinate. The ODE is integrated backwards from a large lambda_max to 0.

**Sign convention**: The rate term r_A is the rate of disappearance of A (negative for consumption). The ODE uses `r_A/C_A0` directly since r_A < 0 for all consumption kinetics.

### 4.4 Tanks-in-Series Model

Models non-ideal behavior as N equal-sized CSTRs in series:

- **RTD**: E(t) = (t^(N-1) / ((N-1)! * tau_i^N)) * exp(-t/tau_i), where tau_i = tau/N
- **1st order conversion**: X = 1 - 1/(1 + tau_i * k)^N
- **Higher orders**: Sequential CSTR mass balances (quadratic formula for 2nd order)
- **N estimation**: N = tau^2 / sigma^2

Implementation: `TanksInSeries.m` extends the `Reactor` base class, reusing `CSTR.m` for sequential computation via `compute_series()`.

### 4.5 Dispersion Model

Accounts for axial mixing via the dispersion coefficient D_e:

- **Bodenstein number**: Bo = D_e / (u * L) (inverse of Peclet)
- **Open-open BC**: Gaussian approximation or exact solution
- **Closed-closed BC**: Danckwerts boundary conditions with eigenvalue series

For first-order reactions, the analytical Danckwerts equation gives:

```
X = 1 - 4*q*exp(Pe/2) / ((1+q)^2*exp(q*Pe/2) - (1-q)^2*exp(-q*Pe/2))
where q = sqrt(1 + 4*Da*Bo), Da = k*tau, Pe = 1/Bo
```

Implementation: `DispersionReactor.m` includes numerical stability guards:
- Bo < 1e-6: PFR fallback (exp terms overflow)
- Pe > 500 (closed-closed): PFR fallback
- Bo > 0.05: eigenvalue series with 500 terms and convergence check

### 4.6 Convolution / Deconvolution

**Convolution**: C_out(t) = integral_0^t E(t') * C_in(t - t') dt'

Discretized as matrix multiplication: C_out = A * C_in * dt, where A is a lower-triangular Toeplitz matrix built from E(t).

**Deconvolution**: Given C_in and C_out, recover E(t) by minimizing ||C_out - B*E*dt||^2.

Implementation: `ConvolutionTool.m` uses:
- `fmincon` (preferred): with non-negativity bounds (E >= 0) and area constraint (integral = 1).
- `fminsearch` (fallback): with penalized objective function for non-negativity and area normalization.

### 4.7 Combined Models

Four non-ideal reactor configurations:

| Model | E(t) | Conversion |
|-------|------|------------|
| CSTR + Dead Volume | E = (1/alpha*tau) * exp(-t/(alpha*tau)) | X = f(alpha*tau) |
| CSTR + Bypass | E = beta*delta(t) + (1-beta)/(tau/(1-beta)) * exp(...) | Weighted average |
| CSTR + Bypass + Dead Vol. | Combination of above | Sequential computation |
| CSTR + PFR in Series | Shift + exponential | Sequential computation |

---

## 5. Optimization (Model Fitting)

Tab 7 fits RTD models to experimental data using nonlinear least-squares optimization:

- **Algorithm**: Nelder-Mead simplex via `fminsearch` (derivative-free, robust for noisy data).
- **Objective**: Minimize SSE = sum((E_model(t_i) - E_exp(t_i))^2).
- **Metrics**: SSE, R^2 = 1 - SSE/SST, AIC = n*ln(SSE/n) + 2*p.
- **Fallback**: `lsqcurvefit` if Optimization Toolbox is available.

---

## 6. UI/UX Features

### 6.1 Responsive Resizing

The `SizeChangedFcn` callback on the main figure recalculates absolute positions for:
- `TabGroup`: fills the figure above the status bar.
- `UnitConvButton` and `HelpButton`: anchored to top-right corner.
- `StatusBar`: full-width at the bottom (22px height).

### 6.2 Status Bar

A `uilabel` at the bottom of the figure shows operation state:
- "Ready" after successful completion.
- "Computing..." / "Generating RTD..." / "Fitting models..." during operations.
- "Error" if a computation fails.

The `updateStatus(app, msg)` method is called from all 7 compute/generate callbacks.

### 6.3 HTML Rendering

UI labels use `'Interpreter', 'html'` for mathematical notation:
- Greek letters: `&tau;`, `&sigma;`
- Subscripts/superscripts: `<sub>`, `<sup>`
- Symbols: `&middot;` for multiplication

Dropdown items remain plain text to preserve `contains()` string matching logic.

### 6.4 Menu Bar

- **File > Exit**: Closes the application via `delete(app.UIFigure)`.
- **Help > User Guide**: Opens the in-app help dialog.
- **Help > About**: Shows version, author, university, and MATLAB version.

---

## 7. Testing Strategy

Two test files validate the application:

### 7.1 Test_NonIdealReactors.m

Unit tests for support classes:
- RTD moment calculations for known distributions.
- Segregation and Max Mixedness convergence for 1st/2nd order.
- TIS conversion vs analytical formula.
- Dispersion with extreme Bo values (stability guards).
- Convolution identity: convolve then deconvolve recovers original E(t).

### 7.2 Test_ReferenceProblems.m

Validation against textbook problems (Fogler Ch. 13-18):
- Problems 51-64 from the course problem set.
- Known analytical solutions compared with numerical results.
- Tolerance: relative error < 1% for conversion, < 5% for moments.

---

## 8. Known Limitations

1. **Non-integer N in TIS**: Rounded to nearest integer for sequential CSTR computation. A warning is issued.
2. **Laminar flow variance**: Theoretically infinite (integral diverges). The numerical value depends on truncation point (10*tau by default).
3. **Deconvolution accuracy**: Depends heavily on signal quality. Noisy C_out data produces noisy E(t). Increase N points and verify with the reconvolution plot.
4. **Large-scale systems**: The convolution matrix A is dense and O(n*m). For signals with > 10000 points, computation may be slow.
5. **Custom rate laws**: Evaluated with `eval()`, which requires valid MATLAB syntax and uses the method workspace.

---

## 9. Future Work

- **HYSYS integration**: Placeholders exist (`[HYSYS]` comments) for importing stream data and reaction kinetics from Aspen HYSYS via COM automation.
- **Parameter estimation**: Extend optimization to fit kinetic parameters (k, E_a) from conversion data, not just RTD shape.
- **3D visualization**: Add 3D surface plots for sensitivity analysis (e.g., X vs Bo vs Da).
- **Export to LaTeX**: Auto-generate formatted tables and equations for direct inclusion in reports.
