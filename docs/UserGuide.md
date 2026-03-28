# Non-Ideal Reactor Analysis — User Guide

**Version 1.0 — March 2026**
Javier Berenguer Sabater | TFG — Chemical Engineering

---

## Quick Start

```matlab
% Launch the application
app = NonIdealReactorApp ;
```

The main window has **7 tabs** plus a **Help** button and a **Unit Converter** button (top-right). A status bar at the bottom shows the current operation state.

---

## Tab 1: RTD Analysis

**Purpose**: Generate or import a Residence Time Distribution E(t) and compute its moments.

### RTD Sources

| Source | Description |
|--------|-------------|
| CSTR | Ideal CSTR: E(t) = (1/tau) * exp(-t/tau) |
| PFR | Ideal PFR: E(t) = delta(t - tau) |
| Laminar Flow | E(t) = tau^2 / (2*t^3) for t >= tau/2 |
| Tanks-in-Series | N equal CSTRs with parameter N |
| Dispersion (open-open) | Axial dispersion with Bodenstein number Bo |
| Dispersion (closed-closed) | Danckwerts boundary conditions |
| Experimental (pulse) | Import pulse tracer data C(t) -> normalize to E(t) |
| Experimental (step) | Import step tracer data F(t) -> differentiate to E(t) |
| From Equation | Enter a custom E(t) equation |
| Direct Data Entry | Type t and C(t) values in a table |

### Steps

1. Select an **RTD Source** from the dropdown.
2. Enter the required parameters (tau, N, Bo, etc.).
3. Click **Generate** to compute E(t), F(t), and moments.
4. View results in the left panel: tau_m, sigma^2, sigma^2_theta, s^3, N_est, V_eff.
5. (Optional) Enter Q_v and V_total to compute dead volume.
6. (Optional) **Export RTD to Workspace** for use in MATLAB scripts or other tabs.

### Importing Experimental Data

- For **pulse** data: provide workspace variables with t [s] and C(t) [mol/m^3], plus C0.
- For **step** data: provide t and F(t) (cumulative).
- For **Direct Data Entry**: click "Add Row" to enter values manually in the table.

### Tips

- The generated RTD is shared with Tabs 2-4 automatically.
- E(t) plots in blue, F(t) in red, E(theta) in green.
- The dimensionless variance sigma^2_theta = sigma^2 / tau^2 indicates deviation from ideal behavior.

---

## Tab 2: Prediction Models (Segregation & Max Mixedness)

**Purpose**: Compute conversion bounds using the Segregation Model (lower bound for n > 1) and Maximum Mixedness Model (upper bound for n > 1).

### Supported Kinetics

| Kinetics | Rate Law |
|----------|----------|
| 1st Order | -r_A = k * C_A |
| 2nd Order | -r_A = k * C_A^2 |
| Michaelis-Menten | -r_A = a * C_A / (1 + b * C_A) |
| Reversible 1st Order | -r_A = k_fwd * C_A - k_rev * (C_A0 - C_A) |
| Parallel Reactions | -r_A = k1 * C_A^n1 + k2 * C_A^n2 |
| Custom Rate Law | User-defined expression in C_A |

### Steps

1. Generate an RTD in Tab 1 first (status label shows "RTD loaded").
2. Select kinetics type and enter parameters (k, C_A0, etc.).
3. Click **Compute**.
4. Results show X_seg (segregation), X_mm (max mixedness), and the conversion bounds.

### Plots

- **X_batch(t)**: Batch conversion vs time for the chosen kinetics.
- **Integrand**: The integrand E(t)*X_batch(t) for the segregation model.
- **X(lambda)**: Maximum mixedness conversion profile vs life expectancy.
- **Comparison**: Bar chart comparing X_seg, X_mm, X_CSTR, X_PFR.

---

## Tab 3: Tanks-in-Series (TIS)

**Purpose**: Model non-ideal behavior as N equal CSTRs in series.

### N Determination

- **Manual**: Enter N directly.
- **From Calculated Data**: Auto-compute N = tau^2 / sigma^2 from Tab 1 RTD.

### Steps

1. Choose N method. If "From Calculated Data", an RTD must exist in Tab 1.
2. Enter tau [s], kinetics, k, and C_A0.
3. Click **Compute**.
4. Results: X_TIS (N tanks), X_CSTR (N=1), X_PFR (N=inf).

### Notes

- Non-integer N is rounded for sequential CSTR computation (a warning appears).
- The E(t) for the TIS model is plotted alongside the RTD from Tab 1 for comparison.

---

## Tab 4: Dispersion Model

**Purpose**: Model non-ideal behavior using axial dispersion with Bodenstein number (Bo = uL/D_e).

### Input Methods

- **Manual**: Enter Bo directly.
- **From Calculated Data**: Estimate Bo from Tab 1 RTD variance.

### Boundary Conditions

- **Open-Open**: Simpler, used when tracer can diffuse across boundaries.
- **Closed-Closed**: Danckwerts BCs, more physically realistic for packed beds.

### Steps

1. Choose input method and boundary condition.
2. Enter Bo, tau, kinetics, k, C_A0.
3. Click **Compute**.
4. Results: X_disp, X_CSTR, X_PFR, effective Pe number.

### Notes

- Very small Bo (< 1e-6) automatically uses the PFR approximation.
- Very large Pe (> 500) in closed-closed also falls back to PFR.

---

## Tab 5: Convolution / Deconvolution

**Purpose**: Perform discrete convolution (C_out = E * C_in) or deconvolution (recover E from C_in and C_out).

### Data Sources

| Source | Description |
|--------|-------------|
| From Workspace | Read signals from MATLAB workspace variables |
| From Equation | Define signals as MATLAB expressions of t |
| From Tab 1 (RTD) | Use E(t) from Tab 1, define C_in as equation (convolution only) |
| From File | Import from Excel/CSV/TSV file |

### Convolution Workflow

1. Set Mode = **Convolution**.
2. Choose data source.
3. Provide C_in(t) and E(t):
   - **Workspace**: enter variable names (t, C_in, E must exist in workspace).
   - **Equation**: enter t_start, t_end, N points, then C_in(t) and E(t) as MATLAB expressions.
     - Example: `C_in = 5*exp(-0.1*t)`, `E = (1/5)*exp(-t/5)`
   - **Tab 1 (RTD)**: E(t) auto-loaded from Tab 1. Enter C_in(t) equation only.
   - **File**: click Import, select file (col1=t, col2=C_in, col3=E).
4. Click **Compute**.
5. Result: C_out(t) plotted and stored.

### Deconvolution Workflow

1. Set Mode = **Deconvolution**.
2. Choose source (Workspace, Equation, or File).
3. Provide C_in(t) and C_out(t), plus N points for E(t) reconstruction.
4. Click **Compute**.
5. Result: Recovered E(t) with verification plot (reconvolved C_out overlaid on original).

### Chaining

After a convolution, click **"Use Previous C_out as C_in"** to chain computations:
- C_in -> E_1 -> C_mid -> E_2 -> C_out (sequential reactors).

### Example: P4 Problem — CSTR with tau=5, C_in = 5*exp(-0.1*t)

1. Tab 1: Generate CSTR RTD with tau = 5 s.
2. Tab 5: Mode = Convolution, Source = From Tab 1 (RTD).
3. Enter C_in equation: `5*exp(-0.1*t)`.
4. Click Compute. C_out appears in the Result plot.

---

## Tab 6: Combined Models

**Purpose**: Analyze non-ideal reactor models combining ideal elements.

### Available Models

| Model | Parameters | Description |
|-------|-----------|-------------|
| CSTR + Dead Vol. | alpha | V_active = alpha * V_total |
| CSTR + Bypass | beta | Fraction beta bypasses the reactor |
| CSTR + Bypass + Dead Vol. | alpha, beta | Both dead volume and bypass |
| CSTR + PFR in Series | alpha | Fraction alpha in PFR, rest in CSTR |

### Steps

1. Select model and enter parameters (alpha, beta, tau, kinetics, k, C_A0).
2. Click **Compute**.
3. Results: X_model, X_CSTR, X_PFR.
4. Plots: E(t) of the combined model, conversion comparison bar, parameter sensitivity curve.

---

## Tab 7: Optimization (RTD Model Fitting)

**Purpose**: Fit analytical RTD models to experimental E(t) data using least-squares optimization.

### Models Available for Fitting

- Tanks-in-Series (parameter: N)
- Dispersion open-open (parameter: Bo)
- Dispersion closed-closed (parameter: Bo)
- CSTR + Dead Volume (parameter: alpha)
- CSTR + Bypass (parameter: beta)
- CSTR + Bypass + Dead Vol. (parameters: alpha, beta)

### Steps

1. Load experimental E(t) data (from workspace or file).
2. Check which models to fit.
3. Click **Fit Models**.
4. Results table shows: Model, Parameters, SSE, R^2, AIC.
5. Plots: data vs fitted curves, residuals, R^2 comparison.

### Tips

- The best model (highest R^2) is highlighted.
- AIC penalizes model complexity — use it to compare models with different numbers of parameters.

---

## Unit Converter

Click the **Unit Converter** button (top-right, blue) to open a floating window with conversions for:
- Length, Area, Volume, Mass, Temperature, Pressure, Flow rate, Concentration, Energy.

All internal computations use SI units. Use the converter to translate between your data's units and SI.

---

## Menu Bar

- **File > Exit**: Close the application.
- **Help > User Guide**: Open the in-app help dialog.
- **Help > About**: Show version, author, and MATLAB info.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "RTD: not loaded" in Tabs 2-4 | Generate an RTD in Tab 1 first |
| 2nd order kinetics gives wrong result | Ensure dropdown shows "2nd Order" (not "1st") |
| Convolution equation error | Use valid MATLAB syntax with `t` as variable. Use `.*` for element-wise multiply |
| Import file fails | Ensure file has numeric data, first column = time |
| Status bar stuck on "Computing..." | Computation may be slow (deconvolution with many points). Wait or reduce N points |
| Dispersion NaN for very small Bo | Fixed: uses PFR fallback for Bo < 1e-6 |

---

## Internal Units (SI)

| Quantity | Unit |
|----------|------|
| Time | s |
| Volume | m^3 |
| Concentration | mol/m^3 |
| Flow rate | m^3/s |
| Pressure | Pa |
| Temperature | K |
| k (1st order) | 1/s |
| k (2nd order) | m^3/(mol*s) |
