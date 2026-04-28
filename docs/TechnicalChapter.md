# Technical Chapter - Internal Operation of the Non-Ideal Reactor Application

**Javier Berenguer Sabater**  
TFG - Chemical Engineering

---

## 1. Purpose of This Document

This chapter explains how the application works internally from a **chemical engineering** point of view. Its purpose is not to document MATLAB syntax or UI programming, but to show:

- what engineering problem each tab solves,
- which reactor-theory model is being applied,
- how reaction kinetics enter the calculation,
- which assumptions are imposed on the user input,
- and how the numerical results should be interpreted.

The active scope of this chapter is the block formed by:

- **Tab 1: RTD Analysis**
- **Tab 2: Prediction Models**
- **Tab 3: Tanks-in-Series**
- **Tab 4: Dispersion Model**

Tabs 5-7 exist in the application, but they are not the reference scope of this chapter because they are expected to undergo deeper redesign later.

---

## 2. Engineering Problem Addressed by the Application

The application is designed to analyze **non-ideal reactors**. In chemical engineering terms, the core question is:

> Given a residence time distribution and a reaction system, how does non-ideal flow modify conversion compared with ideal reactor assumptions?

The software is therefore organized around two complementary tasks:

1. **Characterize the hydrodynamics** through the residence time distribution, RTD.
2. **Propagate the RTD through a reaction model** in order to estimate conversion bounds or conversion in equivalent non-ideal reactor models.

This is the reason why the application begins with RTD generation and only afterwards moves to conversion prediction.

---

## 3. Global Engineering Workflow

From an engineering point of view, the program follows the sequence:

```text
Hydrodynamic description -> RTD object -> Reaction system -> Non-ideal reactor model -> Conversion result
```

More explicitly:

1. The user defines or imports an RTD in Tab 1.
2. The RTD is normalized and converted into its statistical descriptors.
3. The user defines a reactive system through stoichiometry and kinetics.
4. The selected non-ideal model uses the same kinetics and the same RTD to estimate conversion.
5. The program reports either:
   - conversion bounds (`X_seg`, `X_MM`), or
   - conversion in a specific equivalent model (`N` tanks or dispersion model).

The key design choice is that **hydrodynamics and kinetics are coupled only at the reactor-model stage**, not at the RTD-definition stage.

---

## 4. Common Modeling Assumptions

The current Tabs 1-4 share the following engineering assumptions.

### 4.1 Isothermal operation

The active prediction route is isothermal. Temperature may still exist in the kinetic object, but the non-ideal tabs described here operate without solving an energy balance.

### 4.2 Single feed composition pattern in the UI

The current workflow assumes that the inlet concentration vector is built as:

```math
C_0 = [C_{A0}, 0, 0, \ldots]
```

This means the user directly enters the concentration of the key reactant and the rest of species are initialized at zero in the active tabs.

### 4.3 Internal SI consistency

All internal calculations are performed in SI units:

- time in `s`
- concentration in `mol/m^3`
- volume in `m^3`
- flow rate in `m^3/s`

Unit conversion is intentionally isolated in the input and output layers. This is important because it avoids mixing units inside the numerical models.

### 4.4 Conversion referred to a key component

The conversion reported by the active models is associated with the key reactant, usually species `A`:

```math
X = \frac{C_{A0} - C_A}{C_{A0}}
```

For multicomponent systems, the program still computes the full concentration evolution internally where needed, but the reported conversion remains tied to the selected key component.

---

## 5. Representation of the Reaction System

The reaction system is defined by two elements:

1. **Stoichiometric matrix**
2. **Rate law**

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

In the free-kinetics path (`Other kinetics`), the user defines the **reaction rate of each reaction**, `r_i`, not directly `-r_A`.

This distinction is essential. If:

```math
2A \rightarrow B
```

and the rate of disappearance is given in a statement as:

```math
-r_A = k C_A^2
```

then the reaction-rate expression that must be introduced in the app is:

```math
r_1 = \frac{1}{2} k C_A^2
```

because:

```math
\frac{dC_A}{dt} = \nu_A r_1 = -2 r_1
```

### 5.3 Why this matters for non-ideal models

Tabs 2-4 do not contain separate hardcoded branches for every reaction order. Instead, they call the same general kinetic object. From an engineering point of view, this means:

- the hydrodynamic model changes from tab to tab,
- but the reaction model is kept physically consistent across all of them.

This is a very important feature for comparison between non-ideal models.

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

which gives the normalized distribution `E(theta)`.

### 6.3 Effective volume

If the user supplies volumetric flow rate `Q_v`, the tab also reports:

```math
V_{eff} = \tau Q_v
```



---

## 7. Tab 2 - Prediction Models

This tab computes the two classical **micromixing bounds** for a non-ideal reactor:

- **Segregation**
- **Maximum mixedness**

### 7.2 Physical interpretation

- **Segregation model**: fluid elements of different ages do not micromix with one another before reacting. Each age behaves as a batch microreactor.
- **Maximum mixedness model**: fluid elements mix as intensely as possible while still being compatible with the measured RTD.

Therefore, this tab gives **bounds or limiting references** for the expected conversion under non-ideal flow.

### 7.2 Segregation model

The model proceeds in two steps.

First, the intrinsic batch problem is solved:

```math
\frac{dC}{dt} = \nu\,r(C)
```

using the same kinetics defined by the user.

This produces a batch conversion history:

```math
X_{batch}(t)
```

Then the reactor conversion is computed through RTD weighting:

```math
X_{seg} = \int_0^\infty X_{batch}(t)\,E(t)\,dt
```

This means the reactor is treated as a superposition of non-interacting fluid packets of different ages.

### 7.3 Maximum mixedness model

The maximum-mixedness route uses the life-expectancy coordinate `lambda` and the RTD pair `E(lambda)`, `F(lambda)`.

Its internal balance includes:

- the local reaction term,
- and a mixing term proportional to:

```math
\frac{E(\lambda)}{1-F(\lambda)}
```

The exit conversion is the value at:

```math
\lambda = 0
```

In physical terms, this model represents the opposite limit to segregation: the strongest admissible micromixing consistent with the same macroscopic RTD.

### 7.4 Engineering value of comparing both results

If `X_seg` and `X_MM` are very close, the effect of micromixing assumptions is weak and the reactor behaves robustly with respect to mixing state.

If the gap is large, then:

- micromixing matters strongly,
- reaction order and nonlinearity are important,
- and RTD alone is not enough to identify a unique reactor behavior.

This makes Tab 2 especially valuable for diagnosis, not only for calculation.

---

## 8. Tab 3 - Tanks-in-Series

This tab approximates the real reactor by a cascade of ideal CSTRs in series.

### 8.1 Estimation of the number of tanks

The classical relation between RTD moments and tanks-in-series is used:

```math
N = \frac{\tau^2}{\sigma^2}
```

This links the experimental RTD to the idealized cascade structure.

Large `N` approaches plug flow behavior, while `N = 1` corresponds to a single ideal CSTR.

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

### 8.3 PFR comparison route

The tab also includes a plug-flow comparison route. This is useful because the series model naturally connects the two classical limits:

- `N = 1` -> CSTR-like behavior
- `N \to \infty` -> PFR-like behavior

This makes the tab a practical bridge between ideal-reactor intuition and RTD-based non-ideal analysis.

---

## 9. Tab 4 - Dispersion Model

This tab represents the reactor as a one-dimensional flow with axial dispersion.

### 9.1 Governing idea

Instead of describing the reactor as discrete stages, the model uses a continuous hydrodynamic picture. The key parameter is the **Bodenstein number**, `Bo`, which measures the ratio between convective transport and axial dispersion.

In engineering terms:

- high `Bo` means weak backmixing and behavior closer to plug flow,
- low `Bo` means strong backmixing and broader RTD behavior.

### 9.2 Current computational route

The active implementation for Tabs 1-4 does not use separate analytical conversion formulas by reaction order. Instead it:

1. generates the RTD associated with the selected dispersion parameters,
2. computes the batch conversion history for the chosen kinetics,
3. integrates the RTD against that intrinsic conversion history.

This makes the dispersion model consistent with the same general kinetic framework used in the other tabs.

### 9.3 Boundary conditions

The class retains the boundary-condition choice for the RTD model. This matters because open-open and closed-closed formulations do not produce exactly the same RTD shape, especially outside the asymptotic plug-flow limit.

---

## 10. Units and Reproducibility

From the point of view of engineering reliability, one of the most important implementation choices is the strict separation between:

- **input/output units**, which may be selected by the user,
- and **internal calculation units**, which remain SI.

This avoids one of the most common sources of reactor-calculation errors: mixing concentration, time or volumetric units inside the rate law or residence-time calculations.

The recent unit layer also allows the user to define kinetics in practical engineering units such as:

- `mol/L`
- `min`
- `h`

while keeping the backend numerically consistent.

---

## 11. Current Limitations

The following limitations are important for correct interpretation of the results.

1. Tabs 1-4 currently use a simplified inlet composition pattern based on `C_A0`.
2. The active prediction route is isothermal.
3. The quality of the prediction depends strongly on the representativeness of the RTD supplied by the user.
4. The free-kinetics route requires the user to define `r_i` consistently with the stoichiometric matrix.
5. Tabs 5-7 are not yet aligned with the same level of simplification and should not be used as the reference for the internal architecture described here.

---

## 12. File-Level Traceability

The main model responsibilities can be traced to the following files:

- `RTD.m`: RTD construction, normalization and moments
- `SegregationModel.m`: segregation conversion calculation
- `MaxMixednessModel.m`: maximum mixedness conversion calculation
- `TanksInSeries.m`: cascade-of-CSTR equivalent model
- `DispersionReactor.m`: dispersion RTD and conversion route
- `ReactionSys.m`: stoichiometry and general kinetics definition
- `NonIdealReactorApp.m`: orchestration of user input, model execution and output display