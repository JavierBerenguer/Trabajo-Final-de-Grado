# Non-Ideal Reactor Analysis - User Guide

**Version 1.4 - July 2026**  
Javier Berenguer Sabater | TFG - Chemical Engineering

---

## Quick Start

```matlab
% Launch the application
app = NonIdealReactorApp;
```

The main window includes **5 tabs**, a **File** menu, a **Tools** menu, a **Help** menu, and a status bar at the bottom.

### Working with Units

- Most numeric inputs include a unit dropdown next to the field.
- You can type values directly in your preferred units.
- Several fields also accept simple expressions such as `10/60` or `2*5`.
- Experimental RTD sources and `C(t)` equations include time-unit selectors.
- Each main tab includes local **Display units** controls for plots and results.
- Internal calculations remain in SI, so unit changes only affect input and display layers.

---

## Tab 1: RTD Analysis

**Purpose:** Generate or import a residence time distribution `E(t)` and calculate its main moments.

### Available RTD Sources

| Source | Description |
|--------|-------------|
| Ideal CSTR | Exponential RTD for a perfectly mixed reactor |
| Ideal PFR | Ideal plug-flow reference |
| Tanks-in-Series | RTD for `N` equal tanks in series |
| Dispersion (open) | Axial-dispersion RTD with open-open boundaries |
| Dispersion (closed) | Axial-dispersion RTD with closed-closed boundaries |
| Laminar Flow | Laminar-flow RTD |
| Experimental Pulse | Build RTD from pulse tracer data |
| Experimental Step | Build RTD from step tracer data |
| C(t) Equation | Generate RTD from a custom `C(t)` expression |
| Tabular Input | Enter time and signal values manually |

### Basic Workflow

1. Choose an **RTD Source**.
2. Fill in the required inputs using the field unit dropdowns when available.
3. Click **Generate RTD**.
4. Review the calculated values: `tau_m`, `sigma^2`, `sigma^2_theta`, `s^3`, `N_est`, and `V_eff`.
5. Use **Display units** to inspect time and volume in other units without changing the stored RTD.
6. Use **Export RTD to Workspace** if you want to reuse the RTD in MATLAB.

### RTD Utilities

The lower-right **RTD Utilities** panel includes:

- **F(t) Query:** evaluate `F(t)` and `1 - F(t)` at a chosen elapsed time, with a point and guide lines drawn on the `F(t)` plot.
- **Reaction System:** create, edit, or load a `ReactionSys` directly from Tab 1.
- **Feed Stream:** create, edit, or load a `Stream` directly from Tab 1.

If you later set **Tab 2** to **From Calculated Data**, the RTD, `ReactionSys`, and `Stream` loaded here are reused automatically.

### Importing Experimental Data

- **From workspace:** provide the names of the time and signal variables in the corresponding fields.
- **Pulse data:** use `t` in the selected time unit and keep `C(t)` in a consistent concentration scale.
- **Step data:** use `t` in the selected time unit and keep the measured outlet response consistent with `C0`.
- **From file:** click **Import Experimental Data** and choose an `.xlsx`, `.xls`, `.csv`, or `.tsv` file.
- For file imports, the first column must contain time and the second column must contain concentration or response.
- In Excel files, keep the headers in row 1 and the data starting in row 2.
- **Tabular Input:** use **+ Row** and **- Row** to edit the manual table.

---

## Tab 2: Prediction Models

**Purpose:** Estimate conversion limits using the **Segregation** and **Max Mixedness** models and compare them with ideal `CSTR` and `PFR` references.

### Input Modes

- **Manual:** load the `ReactionSys` and `Stream` directly in Tab 2.
- **From Calculated Data:** reuse the RTD, `ReactionSys`, and `Stream` currently loaded in Tab 1.

### Workflow

1. Generate an RTD first in **Tab 1**.
2. Choose **Manual** or **From Calculated Data**.
3. Load or create a compatible `ReactionSys`.
4. Load or create a compatible feed `Stream`.
5. Click **Compute**.
6. Review the plots, the `Exit Summary` table, and the `Non-Ideal Mixing Effect (%)` comparison.

### Results

- **Conversion Comparison:** bar chart for the selected reactants in the fixed model order `Ideal CSTR`, `Segregation`, `Max Mixedness`, `Ideal PFR`.
- **Outlet Concentration:** bar chart for the selected species in the same fixed model order.
- **Exit Summary:** per-species table with `C_in`, outlet concentrations, and reactant conversion for the four models.
- **Non-Ideal Mixing Effect (%):** compact percentage comparison between `Segregation` / `Max Mixedness` and the ideal references.
- **Shared Legend:** both plots use the same colors and a single legend.

### Notes

- This tab does **not** include a `Time base` display selector.
- `Reactants` and `Species` are independent multiselection controls.
- The loaded `Stream` must match the number of components in the loaded `ReactionSys`.

---

## Tab 3: Tanks-in-Series (TIS)

**Purpose:** Model non-ideal behavior as `N` equal CSTRs in series and compare it with ideal `CSTR` and `PFR` references.

### N Method

- **Manual:** enter `N` and `tau` directly.
- **From Calculated Data:** estimate `N` from the RTD in Tab 1 and import `ReactionSys` plus `Stream` from Tab 2 when they are available.

### Workflow

1. Choose the **N Method**.
2. Set or import `N` and `tau`.
3. Load or create the `ReactionSys`.
4. Load or create the feed `Stream`.
5. Click **Compute**.
6. Review `Outlet Concentration vs N`, `Conversion vs N`, the `Exit Summary` table, and the `E(t)` comparison.

### Notes

- If `N` is not an integer, the app still uses it for RTD estimation and reports the equivalent continuous value.
- The `Exit Summary` table reports `TIS`, `CSTR`, and `PFR` outlet concentrations and conversions.
- The lower-right plot compares the TIS `E(t)` with the RTD currently held by Tab 1.

---

## Tab 4: Dispersion Model

**Purpose:** Model non-ideal behavior using axial dispersion and compare it with ideal `CSTR` and `PFR` references.

### Input Modes

- **Manual:** enter `Bo`, the boundary condition, and `tau` directly.
- **From Calculated Data:** estimate `Bo` from the RTD in Tab 1 and import `ReactionSys` plus `Stream` from Tab 2 when they are available.

### Boundary Conditions

- **closed-closed**
- **open-open**

### Workflow

1. Choose the input mode and boundary condition.
2. Set or import `Bo` and `tau`.
3. Load or create the `ReactionSys`.
4. Load or create the feed `Stream`.
5. Click **Compute**.
6. Review `Outlet Concentration vs Bo`, `Conversion vs Bo`, the `Exit Summary` table, and the `E(t)` plot with `Bo`, `Pe`, and `tau`.

### Display Units and Results

- **E(t) Plot:** uses the local `Time base` selector only.
- **Outlet Concentration vs Bo:** uses the `Concentration` selector and a multiselect `Species` list.
- **Conversion vs Bo:** uses a multiselect `Reactants` list.
- **Exit Summary:** shows `C_in`, `Disp C_out`, `CSTR C_out`, `PFR C_out`, `X_Disp`, `X_CSTR`, and `X_PFR`.
- The lower-left table is not filtered by the species/reactant selectors; those selectors only affect the plots.

---

## Tab 5: Design & Optimization

**Purpose:** Work in a single workspace that starts from an RTD and connects equivalent-model fitting, reactive prediction, optimization, and scale-up.

### Subareas

- **Diagnosis & Fit:** fit `Tanks-in-Series`, `Axial Dispersion`, `CSTR + Dead Volume`, `CSTR + Bypass`, and `CSTR + Dead Volume + Bypass` to the RTD from Tab 1.
- **Reactive Performance:** compare `Ideal CSTR`, `Segregation`, `Max Mixedness`, and `Ideal PFR`, and report conversion, selectivity, yield, and outlet concentrations.
- **Optimization & Scale-Up:** optimize equivalent hydrodynamic parameters and compare pilot versus industrial scenarios.

### Typical Workflow

1. In **Tab 1**, generate or import the RTD.
2. In **Diagnosis & Fit**, choose a family and run the fit if you want an equivalent hydrodynamic model.
3. In **Reactive Performance**, load a `ReactionSys` and a feed `Stream` from the workspace, choose the key species, and compute the reference models using either `Tab 1 RTD` or `Fitted RTD`.
4. In **Optimization & Scale-Up**, reuse that same chemistry to optimize `tau`, `N`, `Bo`, `bypass`, `activeFraction`, and `recycleRatio`, or compare pilot and industrial scenarios.

### Notes

- Tab 5 is **isothermal** and **steady-state** in this version.
- RTD preprocessing belongs to **Tab 1**, so Tab 5 does not include a separate hydrodynamics editor.
- Optimization reuses the chemistry already loaded in **Reactive Performance**.
- Session save/load preserves the Tab 5 workspace through `designWorkspace`.

---

## Unit Converter

Open **Tools > Unit Converter** to convert values manually between common engineering units.

This tool is optional during normal use, because most scalar inputs in the app already support direct unit selection.

---

## Menu Bar

- **File > Guardar:** save the current session into the local `saves/` folder as a `.mat` file.
- **File > Cargar:** restore a previously saved session, including `RTD`, `ReactionSys`, `Stream`, input fields, and display selections.
- **File > Restart:** reopen the app in a clean state.
- **File > Exit:** close the application.
- **Tools > Unit Converter:** open the unit converter.
- **Help > User Guide:** open this guide inside the app.
- **Help > Technical Guide:** open the engineering-oriented technical chapter.
- **Help > About:** show version and author information.

---

## Troubleshooting

| Problem | What to check |
|---------|---------------|
| Tabs 2-5 say something is not loaded | Confirm the required RTD, `ReactionSys`, or `Stream` is available in the source tab or workspace |
| A model cannot compute | Check that all required inputs are filled in and that the component counts match |
| Imported data does not work | Check column order, headers, and unit consistency |
| A `C(t)` equation fails | Use valid MATLAB syntax and element-wise operators such as `.*` |
| `From Calculated Data` does not populate chemistry | Make sure Tab 1 or Tab 2 already holds a valid `ReactionSys` and `Stream` |

---

## Practical Tips

- Keep tracer signals and `C0` in the same concentration scale when using pulse/step RTD inputs.
- Use Tab 1 as the main handoff point when you want to reuse RTD, `ReactionSys`, and `Stream` in Prediction.
- Use Tab 2 as the handoff point for chemistry when you want Tabs 3 and 4 to import the same `ReactionSys` and `Stream`.
- Use the local **Display units** controls when you want to inspect results without changing the stored internal data.
