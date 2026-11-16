---
name: scientific-code
description: "Numerical and array code in any language: writing or reviewing models, simulations, fits, solvers."
license: MIT
---

# Scientific code

Numerical code is verified mostly by reading it against the mathematics: wrong results often look plausible, so tests catch less than in application code. Every rule below serves that reading, or the speed the mathematics allows.

1. **Formulate.** Name the standard problem: linear system, least squares, eigenproblem, root find, optimization, quadrature, recurrence. Standard forms have established routines with known convergence, stability, and error behaviour; an ad hoc method has none of these, and a reviewer cannot check it. Done when objective or residual, unknowns with shapes and units, and the routine are stated. Prefer solves and reusable factorizations to inverses: an inverse costs more and loses accuracy on ill-conditioned problems.
2. **Lay out data** along meaningful axes, or as sparse matrices and linear operators. The layout decides which operations the library can see whole; broadcasting, reductions, contractions, and batching are model design, not optimization.
3. **Push work down.** Done when every element-wise loop is either replaced by whole-array library calls or justified as a recurrence, irregular work, chunking, early stopping, or orchestration.

## Where work runs

An interpreted host (Python, R, MATLAB) pays dispatch, boxing, and type checks on every element it touches, often a hundred times the arithmetic. A library call over a whole array pays that once and runs the loop in compiled code with SIMD, cache-friendly access, and BLAS. Speed therefore comes from who iterates, not from the container: wrapping values in an array type, or calling library functions inside an interpreter loop, leaves the host iterating and changes nothing.

In compiled or JIT stacks (Julia, Fortran, C++, Rust, Numba, JAX under `jit`) loops become machine code, so loops are fine; cost moves to allocation inside loops, type instability, and memory order.

Loops stay right where vectorization cannot help or hurts: recurrences carry a data dependence between steps, and vectorizing into large intermediates trades arithmetic for memory traffic and can exhaust memory. Vectorize while intermediates stay bounded and the method stays legible.

Language patterns: `references/<language>.md`.

## Code shape

Keep mathematics visible: a reader with the derivation matches equations to code, including shapes, axes, units, and approximations, because that comparison is the main check of correctness.

Write deep modules: keep related equations together, and extract a function when it names a mathematical operation or a public boundary. Splitting a straight-line derivation into `prepare`/`compute`/`validate` steps makes the reader reassemble it and hides shapes behind call boundaries.

Classes hold mathematical objects with state: factorizations, operators, fitted models, parameter records.

Do I/O and input conversion once, at the edge. The kernel then has one known input type, avoids repeated copies, and can be tested against analytic cases.

Solve with a direct calculation or a standard algorithm. Managers, registries, dependency injection, and heuristic scoring of candidate solutions add indirection without mathematical content, and heuristics hide a failing formulation instead of fixing it; add them only when the user asks.
