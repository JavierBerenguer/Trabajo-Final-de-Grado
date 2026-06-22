# Non-Ideal Reactor Analysis - User Guide

**Version 1.3 - April 2026**  
Javier Berenguer Sabater | TFG - Chemical Engineering

---

## Quick Start

```matlab
% Launch the application
app = NonIdealReactorApp ;
```

The main window includes **4 tabs**, a **File** menu, a **Tools** menu, a **Help** menu, and a status bar at the bottom.

### Working with Units

- Most numeric inputs include a unit dropdown next to the field.
- You can type values directly in your preferred units.
- Several fields also accept simple expressions such as `10/60` or `2*5`.
- Experimental RTD sources and `C(t)` equations include time-unit selectors.
- Each main tab includes local **Display units** controls for plots and results.
- When importing data from files or the workspace, make sure your vectors match the units selected in the app.

---

## Tab 1: RTD Analysis

**Purpose:** Generate or import a residence time distribution `E(t)` and calculate its main moments.

### Available RTD Sources

| Source | Description |
|--------|-------------|
| Ideal CSTR | Exponential RTD for a perfectly mixed reactor |
| Ideal PFR | Ideal plug-flow reference |
| Tanks-in-Series | RTD for `N` equal tanks in series |
| Dispersion (open) | Axial dispersion model with open boundaries |
| Dispersion (closed) | Axial dispersion model with closed boundaries |
| Laminar Flow | Laminar-flow RTD |
| Experimental Pulse | Build RTD from pulse tracer data |
| Experimental Step | Build RTD from step tracer data |
| C(t) Equation | Generate RTD from a custom `C(t)` expression |
| Tabular Input | Enter time and signal values manually |

### Basic Workflow

1. Choose an **RTD Source**.
2. Fill in the required inputs using the unit dropdowns next to each field.
3. Click **Generate**.
4. Review the plots and the calculated values: `tau_m`, `sigma^2`, `sigma^2_theta`, `s^3`, `N_est`, and `V_eff`.
5. If needed, enter `Q_v` to estimate the effective volume `V_eff = tau * Q_v`.
6. Use **Export RTD to Workspace** if you want to reuse the RTD in MATLAB or in other tabs.

### Importing Experimental Data

- **From workspace:** provide the names of the time and signal variables in the corresponding fields.
- **Pulse data:** use `t` in the selected time unit and keep `C(t)` and `C0` in the same concentration scale.
- **Step data:** use `t` in the selected time unit and keep the measured outlet response consistent with `C0`.
- **From file:** click **Import Experimental Data** and choose an `.xlsx`, `.xls`, `.csv`, or `.tsv` file.
- For file imports, the first column must contain time and the second column must contain concentration or response.
- In Excel files, keep the headers in row 1 and the data starting in row 2.
- **Tabular Input:** click **Add Row** to enter values manually.

### Tips

- The RTD generated here is shared automatically with Tabs 2, 3, and 4.
- The **Display units** controls let you change how time-based plots and values are shown.
- `E(t)`, `F(t)`, and `E(theta)` are plotted separately for easier comparison.

---

## Tab 2: Prediction Models

**Purpose:** Estimate conversion limits using the **Segregation** and **Max Mixedness** models.

### Before You Compute

- Generate an RTD first in **Tab 1**.
- Create a reaction system with **New RS**, modify it with **Edit RS**, or load it with **Load from Workspace**.
- Enter `C_A0` using the concentration unit you want.

### Workflow

1. Confirm that the RTD status shows it was loaded from Tab 1.
2. Prepare or load the reaction system.
3. Prepare or load the feed stream with the full inlet concentration vector.
4. Click **Compute**.
5. Review the conversion comparison and outlet concentration plots, together with the exit summary table.

### Plots

- **Conversion Comparison:** compares reactant conversion for `Segregation`, `Max Mixedness`, `Ideal CSTR`, and `Ideal PFR`. The reactant selector lets you view one reactant or **All reactants**.
- **Outlet Concentration:** compares outlet concentration for every species across the same four models. The species selector lets you view one species or **All species**.
- **Exit Summary:** table with inlet concentration, outlet concentration, and reactant conversion per species.
- **Comparison:** direct comparison of both model predictions

---

## Tab 3: Tanks-in-Series (TIS)

**Purpose:** Model non-ideal behavior as `N` equal CSTRs in series.

### Choosing `N`

- **Manual:** type the number of tanks directly.
- **From Calculated Data:** estimate `N` automatically from the RTD obtained in Tab 1.

### Workflow

1. Choose how `N` will be defined.
2. Enter `tau` and `C_A0` using the unit dropdowns.
3. Create, edit, or load the reaction system.
4. Click **Compute**.
5. Review `X_TIS`, `X_CSTR`, and `X_PFR`.

### Notes

- If `N` is not an integer, the app rounds it and shows a warning.
- The RTD of the TIS model is plotted together with the RTD from Tab 1.

---

## Tab 4: Dispersion Model

**Purpose:** Model non-ideal behavior using axial dispersion.

### Input Options

- **Manual:** enter `Bo` directly.
- **From Calculated Data:** estimate `Bo` from the RTD in Tab 1.

### Boundary Conditions

- **Open-Open**
- **Closed-Closed**

### Workflow

1. Choose the input method and boundary condition.
2. Enter `Bo`, `tau`, and `C_A0`.
3. Create, edit, or load the reaction system.
4. Click **Compute**.
5. Review `X_disp`, `X_CSTR`, `X_PFR`, and the reported `Pe` value.

---

## Unit Converter

Open **Tools > Unit Converter** to convert values manually between common engineering units.

This tool is optional during normal use, because most scalar inputs in the app already support direct unit selection.

---

## Menu Bar

- **File > Exit:** close the application
- **Tools > Unit Converter:** open the unit converter
- **Help > User Guide:** open this guide inside the app
- **Help > About:** show version and author information

---

## Troubleshooting

| Problem | What to check |
|---------|---------------|
| Tabs 2-4 say the RTD is not loaded | Generate an RTD first in Tab 1 |
| A model cannot compute | Check that all required inputs are filled in |
| Reaction system is missing | Create one with **New RS** or load it from the workspace |
| Imported data does not work | Check column order, headers, and unit consistency |
| A `C(t)` equation fails | Use valid MATLAB syntax and element-wise operators such as `.*` |

---

## Practical Unit Tips

- Keep `C0` in the same concentration scale as the imported tracer signal.
- When using workspace or file imports, double-check that the selected unit in the app matches the data you are loading.
- Use the local **Display units** controls when you want to inspect results without changing your original inputs.
