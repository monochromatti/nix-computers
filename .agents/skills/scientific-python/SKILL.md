---
name: scientific-python
description: "Use when writing or reviewing numerical models, scientific scripts, simulations, fitting code, or array-oriented libraries."
license: MIT
---

# Scientific Python

Keep mathematics visible. A reader with the derivation should be able to match equations to code, including shapes, axes, units, approximations, and numerical choices. Let the model determine data layout and control flow; do not wrap numerical kernels in application architecture.

## Formulate before implementing

First identify the numerical problem: linear system, least-squares fit, eigenproblem, root find, optimization, integration, quadrature, recurrence, or another standard form. Use an established routine suited to its scale, structure, sparsity, and execution target. Prefer solves and reusable factorizations to explicit inverses.

Represent bulk data along meaningful array axes, or as sparse matrices and linear operators. Treat broadcasting, reductions, contractions, and batching as model design. `np.vectorize`, array comprehensions, and NumPy calls inside element-wise Python loops are still scalar execution. Loops remain appropriate for recurrences, irregular work, chunking, early stopping, and coarse orchestration. Do not force vectorization that creates large intermediates or obscures the method.

Choose a numerical stack deliberately and use its native operations. Convert inputs once at an interface when needed. Do not scatter `np.asarray` through internals, hide scalar Python behind array-shaped APIs, or build backend-neutral adapters without a real portability requirement.

## Match structure to use

For a problem-solving script, prefer direct flow: load data, define parameters, compute, inspect, then plot or save. Keep useful intermediate quantities visible. Extract functions for mathematical operations or repeated experiments, not to simulate an application framework.

For a library, prefer pure public functions over standard scientific types. Separate I/O from numerical kernels. Pass state explicitly, including random generators. Name variables after established notation when this aids comparison with the derivation. Document shapes, axes, units, dtype requirements, and model-relevant numerical controls. Validate public boundaries where invalid input could produce a plausible wrong result; use assertions only for internal invariants.

Keep related equations together. Extract code when it names a mathematical operation, captures a stable repeated concept, or defines a public boundary. Do not split a straight-line derivation into `_prepare_*`, `_compute_*`, and `_validate_*` methods. Use classes only for objects with mathematical meaning or necessary shared state, such as a factorization, operator, fitted model, or parameter record.

Do not add managers, handlers, registries, dependency injection, audit subsystems, candidate-ranking pipelines, or heuristic gates unless requirements or the numerical method call for them. Prefer a direct calculation or standard algorithm over generating alternatives and scoring them with ad hoc rules.

## Preserve numerical meaning

Use stable formulations. Account for conditioning, scaling, cancellation, overflow, underflow, dtype, and memory cost where relevant. Reuse work outside loops. Supply derivatives, sparsity, bounds, and scaling when known and useful. Expose convergence status, residuals, tolerances, and iteration limits. Do not hide failures, silently choose a result, or broadly catch numerical exceptions.

Test mathematical behavior: invariants, analytic special cases, limiting regimes, convergence rates, and agreement with a simple reference. Test numerical kernels with real computations; mock only external systems.
