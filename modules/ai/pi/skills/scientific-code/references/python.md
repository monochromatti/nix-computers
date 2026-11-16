# Python

These look vectorized but leave the interpreter iterating per element:

- `np.vectorize`, `np.frompyfunc`: a Python loop with an array-shaped signature.
- Comprehensions or loops whose results are fed to `np.array`: the array is built after the scalar work is done.
- NumPy calls on scalars or small slices inside a Python loop: each call pays dispatch overhead larger than its arithmetic.

Push down with broadcasting, ufuncs, reductions with `axis=`, `np.einsum`/`@` for contractions, `scipy.sparse` and `LinearOperator` for structured operators, and batched `np.linalg`/`scipy.linalg` solves.

Call `np.asarray` once at the public boundary. Repeated conversions inside the kernel copy data and hide the type the kernel expects.

When a loop is truly needed (a recurrence over a long array), compile it with Numba or JAX (`lax.scan`) rather than vectorizing it into the wrong algorithm.
