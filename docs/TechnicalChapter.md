# Technical Chapter - Internal Operation of the Non-Ideal Reactor Application

**Javier Berenguer Sabater**  
TFG - Chemical Engineering

---

## 1. Purpose of This Document

This chapter explains how the application works internally from a **chemical engineering** point of view. Its purpose is not to document MATLAB syntax or UI programming, but to show:

- what engineering problem each active tab solves,
- which reactor-theory model is being applied,
- how reaction kinetics and feed composition enter the calculation,
- which assumptions are imposed on the current workflows,
- and how the numerical results should be interpreted.

The active scope of this chapter is the current **5-tab** application:

- **Tab 1: RTD Analysis**
- **Tab 2: Prediction Models**
- **Tab 3: Tanks-in-Series**
- **Tab 4: Dispersion Model**
- **Tab 5: Design & Optimization**

---

## 2. Engineering Problem Addressed by the Application

The application is designed to analyze **non-ideal reactors**. In chemical engineering terms, the core question is:

> Given a residence time distribution and a reaction system, how does non-ideal flow modify conversion, selectivity, and yield compared with ideal reactor assumptions?

The software is therefore organized around two complementary tasks:

1. **Characterize the hydrodynamics** through the residence time distribution, RTD.
2. **Propagate the RTD through a reaction model** in order to estimate conversion bounds, equivalent-model behavior, or optimization trends.

This is the reason why the application begins with RTD generation and only afterwards moves to conversion prediction or design tasks.

---

## 3. Global Engineering Workflow

From an engineering point of view, the program follows the sequence:

```text
Hydrodynamic description -> RTD object -> Reaction system + feed stream -> Non-ideal reactor model -> Conversion / selectivity / yield result
```

More explicitly:

1. The user defines or imports an RTD in Tab 1.
2. The RTD is normalized and converted into statistical descriptors.
3. The user defines a `ReactionSys` and a feed `Stream`.
4. The selected non-ideal model uses the same chemistry and hydrodynamic information to compute the response.
5. The program reports either:
   - mixing bounds (`Segregation`, `Max Mixedness`),
   - an equivalent reactor response (`TIS`, `Dispersion`),
   - or a design-oriented comparison (`Diagnosis & Fit`, `Reactive Performance`, `Optimization`).

The key design choice is that **hydrodynamics and chemistry are coupled only at the model-evaluation stage**, not while building the RTD itself.

---

## 4. Common Modeling Assumptions

The current application shares the following engineering assumptions.

### 4.1 Internal SI consistency

All internal calculations are performed in SI units:

- time in `s`
- concentration in `mol/m^3`
- volume in `m^3`
- volumetric flow rate in `m^3/s`

Unit conversion is intentionally isolated in the input and output layers. This avoids mixing units inside the numerical models.

### 4.2 Isothermal and steady-state prediction routes

The active prediction and design routes are isothermal. Temperature may still exist in the kinetic object, but the tabs described here do not solve an energy balance.

Tabs 2-5 are also evaluated in steady state for the reactor response of interest.

### 4.3 Stoichiometry and kinetics must stay consistent

The numerical models assume that:

- the stoichiometric matrix is correctly defined,
- each kinetic expression matches that stoichiometry,
- and species indexing is used consistently across `ReactionSys`, `Stream`, and all reactor models.

This is especially important for custom kinetics, because the backend reuses the same chemistry across all active models.

### 4.4 Multicomponent feed support with key-component reporting

The current workflow uses a full feed concentration vector taken from a `Stream` object. The models therefore operate on multicomponent inlet conditions, not only on a single `C_A0` scalar.

Even so, the main conversion metric is still tied to a **key reactant**:

```math
X = \frac{C_{A,in} - C_{A,out}}{C_{A,in}}
```

For multicomponent systems, the program also keeps outlet concentrations for all species and can derive selectivity and yield where relevant.

---

## 5. Representation of the Reaction System

The reaction system is defined by three linked elements:

1. **Stoichiometric matrix**
2. **Rate law**
3. **Feed composition vector**

### 5.1 Stoichiometric matrix

Each row corresponds to one reaction and each column to one chemical species. For example, for:

```math
2A \rightarrow B
```

the stoichiometric row is:

```math
[-2 \quad 1]
```

The application uses this matrix to convert reaction rates into species balances.

### 5.2 Meaning of the kinetic expression

In the free-kinetics path (`Other kinetics`), the user defines the **rate of each reaction**, `r_i`, not directly the disappearance rate of a specific species.

If:

```math
2A \rightarrow B
```

and a statement gives:

```math
-r_A = k C_A^2
```

then the reaction-rate expression entered in the app must be:

```math
r_1 = \frac{1}{2} k C_A^2
```

because:

```math
\frac{dC_A}{dt} = \nu_A r_1 = -2r_1
```

### 5.3 Feed stream

The inlet composition is supplied by a `Stream` object. This is important because:

- Tabs 2-4 use the same concentration vector for all species,
- Tab 1 can already hold the `ReactionSys` and `Stream` that Tab 2 reuses,
- and Tab 5 reuses the same chemistry for reactive comparison, optimization, and scale-up.

---

## 6. Tab 1 - RTD Analysis

This tab converts experimental or analytical hydrodynamic information into a usable **residence time distribution**.

### 6.1 Supported RTD sources

The RTD can be generated from:

- ideal model expressions,
- pulse-response experimental data,
- step-response experimental data,
- a user-defined `C(t)` expression,
- direct tabulated input.

Regardless of the source, the result is transformed into a common RTD representation.

### 6.2 Quantities computed

Once the tracer curve is converted into `E(t)`, the tab computes:

```math
\tau = \int_0^\infty t E(t)\,dt
```

```math
\sigma^2 = \int_0^\infty (t-\tau)^2 E(t)\,dt
```

```math
\sigma_\theta^2 = \frac{\sigma^2}{\tau^2}
```

and the cumulative distribution:

```math
F(t) = \int_0^t E(\xi)\,d\xi
```

The dimensionless RTD is built using:

```math
\theta = \frac{t}{\tau}
```

which gives the normalized distribution `E(\theta)`.

### 6.3 Effective volume

If the user supplies volumetric flow rate `Q_v`, the tab also reports:

```math
V_{eff} = \tau Q_v
```

### 6.4 Role as shared source

Tab 1 is not only an RTD editor. It also acts as a practical handoff point:

- the RTD is reused by Tabs 2-5,
- the `ReactionSys` and `Stream` loaded in the RTD utilities can be reused directly by Tab 2,
- and the `F(t)` query gives a direct physical interpretation of effluent already exited versus fluid still inside the reactor.

---

## 7. Tab 2 - Prediction Models

This tab computes the two classical **micromixing bounds** for a non-ideal reactor:

- **Segregation**
- **Maximum mixedness**

and compares them with ideal `CSTR` and `PFR` references.

### 7.1 Segregation model

The model proceeds in two steps.

First, the intrinsic batch problem is solved:

```math
\frac{dC}{dt} = \nu\,r(C)
```

using the same kinetics defined by the user.

Then the outlet state is computed through RTD weighting. In physical terms, the reactor is treated as a superposition of non-interacting fluid packets of different ages.

### 7.2 Maximum mixedness model

The maximum-mixedness route uses the life-expectancy coordinate `\lambda` and the RTD pair `E(\lambda)`, `F(\lambda)`.

Its internal balance includes:

- the local reaction term,
- and a mixing term proportional to:

```math
\frac{E(\lambda)}{1-F(\lambda)}
```

The exit state is recovered at:

```math
\lambda = 0
```

In physical terms, this model represents the opposite admissible limit to segregation for the same macroscopic RTD.

### 7.3 Engineering value of the tab

If `Segregation` and `Max Mixedness` are close, the effect of micromixing assumptions is weak.

If the gap is large, then:

- micromixing matters strongly,
- reaction nonlinearity is important,
- and RTD alone is not enough to identify a unique reactor response.

The tab therefore acts as both a predictor and a diagnosis tool.

### 7.4 Current outputs

The active UI reports:

- reactant conversion comparison for `Ideal CSTR`, `Segregation`, `Max Mixedness`, and `Ideal PFR`,
- outlet concentration comparison for all species,
- an exit summary table with concentrations and per-reactant conversion,
- and a compact percentage comparison of non-ideal mixing effects.

---

## 8. Tab 3 - Tanks-in-Series

This tab approximates the real reactor by a cascade of ideal CSTRs in series.

### 8.1 Estimation of the number of tanks

When the user selects **From Calculated Data**, the classical relation between RTD moments and tanks-in-series is used:

```math
N = \frac{\tau^2}{\sigma^2}
```

This links the measured RTD to the equivalent cascade structure.

Large `N` approaches plug-flow behavior, while `N = 1` corresponds to a single ideal CSTR.

### 8.2 Species balance in each tank

Each tank is solved with the stationary CSTR balance:

```math
C_{out} - C_{in} - \tau_i\,\nu\,r(C_{out}) = 0
```

where:

```math
\tau_i = \frac{\tau_{total}}{N}
```

The outlet of one tank becomes the inlet of the next one.

### 8.3 Data flow

In calculated mode, the tab imports:

- `N` and `tau` from the RTD in Tab 1,
- and the chemistry from Tab 2 if a `ReactionSys` and `Stream` have already been loaded there.

This preserves consistency when comparing prediction routes.

---

## 9. Tab 4 - Dispersion Model

This tab represents the reactor as a one-dimensional flow with axial dispersion.

### 9.1 Governing idea

The key hydrodynamic parameter is the **Bodenstein number**, `Bo`, which measures the ratio between convective transport and axial dispersion. The interface also reports `Pe = 1/Bo`.

In engineering terms:

- low `Bo` means weaker dispersion resistance and behavior closer to plug flow in the implementation's convention,
- high `Bo` means broader backmixed behavior relative to that limit.

### 9.2 Current computational route

The active implementation builds an RTD associated with the selected dispersion parameters and then solves the reaction problem with the same general kinetic framework used elsewhere.

This keeps the dispersion route compatible with multicomponent kinetics rather than restricting it to a small set of analytical formulas.

### 9.3 Boundary conditions

The class retains the boundary-condition choice for the RTD model:

- `closed-closed`
- `open-open`

This matters because both formulations do not produce exactly the same RTD shape outside limiting cases.

### 9.4 Data flow

In calculated mode, the tab imports:

- `tau` and a variance-based estimate of `Bo` from Tab 1,
- and the chemistry from Tab 2 if available.

---

## 10. Tab 5 - Design & Optimization

This tab is the current design-oriented workspace of the application. It is intentionally narrower than a full process simulator, but it extends the engineering use of the same RTD and chemistry building blocks.

### 10.1 Diagnosis & Fit

This subarea fits equivalent hydrodynamic families to the RTD from Tab 1:

- `Tanks-in-Series`
- `Axial Dispersion`
- `CSTR + Dead Volume`
- `CSTR + Bypass`
- `CSTR + Dead Volume + Bypass`

The backend combines direct formulas, heuristic indicators, and lightweight numerical fitting. Its purpose is not to identify a unique physical internals model, but to build a compact equivalent representation that reproduces the observed RTD reasonably well.

### 10.2 Reactive Performance

This subarea reuses:

- an RTD from `Tab 1` or from the fitted equivalent model,
- a `ReactionSys`,
- and a feed `Stream`.

It then compares:

- `Ideal CSTR`
- `Segregation`
- `Max Mixedness`
- `Ideal PFR`

The outputs include conversion, selectivity, yield, outlet concentrations, and a direct first-order shortcut when the kinetic structure allows it.

### 10.3 Optimization

This subarea optimizes equivalent hydrodynamic parameters such as:

- `tau`
- `N`
- `Bo`
- `bypass`
- `activeFraction`
- `recycleRatio`

The active implementation uses a lightweight penalized search strategy, evaluates constraints on conversion/selectivity/yield or outlet concentration, and reuses the same chemistry loaded in `Reactive Performance`.

From an engineering standpoint, this tab is useful for:

- screening sensitivity to hydrodynamic parameters,
- comparing equivalent-model families,
- and building quick what-if scenarios before moving to a more detailed design stage.

---

## 11. Units, Persistence, and Reproducibility

From the point of view of engineering reliability, one of the most important implementation choices is the strict separation between:

- **input/output units**, which may be selected by the user,
- and **internal calculation units**, which remain SI.

The session system follows the same philosophy:

- the app saves explicit state snapshots,
- domain objects such as `RTD`, `ReactionSys`, and `Stream` are serialized to plain structures,
- and Tab 5 stores its own workspace state through `designWorkspace`.

This makes saved sessions more portable and less dependent on MATLAB handle serialization.

---

## 12. Current Limitations

The following limitations are important for correct interpretation of the results.

1. The active prediction routes are isothermal and do not solve energy balances.
2. The physical meaning of the answer still depends strongly on the quality of the RTD supplied by the user.
3. Custom kinetics require the user to define `r_i` consistently with the stoichiometric matrix.
4. The diagnosis flags in Tab 5 are heuristic indicators, not rigorous equipment-fault identifiers.
5. The optimization route is intentionally lightweight and should be treated as a screening tool, not as a final rigorous optimizer.
6. Session load restores the state but does not automatically recompute every tab.

---

## 13. File-Level Traceability

The main model responsibilities can be traced to the following files:

- `RTD.m`: RTD construction, normalization, moments, and equivalent RTD families
- `SegregationModel.m`: segregation prediction route
- `MaxMixednessModel.m`: maximum-mixedness prediction route
- `TanksInSeries.m`: cascade-of-CSTR equivalent model and ideal references
- `DispersionReactor.m`: dispersion RTD and reactor response helpers
- `ReactionSys.m`: stoichiometry and general kinetics definition
- `Stream.m`: inlet composition container in internal SI units
- `DesignWorkspaceHelper.m`: backend for Tab 5 fitting, reactive comparison, optimization, and scale-up
- `NonIdealReactorApp.m`: orchestration of user input, model execution, persistence, and output display
