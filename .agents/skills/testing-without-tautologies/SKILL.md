---
name: testing-without-tautologies
description: "Use when writing, fixing, or reviewing tests: unit tests, fakes and mocks, numerical or simulation code, message-driven services, HTTP APIs, NixOS VM tests, or flake checks; also when a failing test tempts you to change its expectation."
---

# Testing Without Tautologies

A test earns its place by going **red** on a realistic break. Before writing one, name the **mutation**: the production change that should make it fail. No mutation, no test.

## Before writing the body

Answer each; if one has no answer, redesign the test.

- **Contract**: what does a caller observe? A return value, a table or array, an HTTP response, a published message, an ack, a written file, a unit's environment, an exit code, an error and its message.
- **Oracle**: where does the expected value come from? A literal, a hand-checked fixture, a closed-form case, or an invariant. Never the code under test.
- **Ownership**: is this our decision, or documented behavior of a library, framework, or the OS? Test our decision at that boundary.
- **Level**: the narrowest level that can go red. Pure logic → unit test. Wiring between processes, services, and config → integration or VM test. Generated artifacts → a check on the build output.

## Rules

1. **Assert the contract by value.** Compare against expected data: frame and array equality with stated tolerances, full response bodies, exact payloads. Assertions like `is not None`, `isinstance`, `len > 0`, or "is finite" go red only on crashes; pair them with a value check or drop them.

2. **Use an independent oracle.** In numerical and simulation code, derive expectations by hand, from an analytic special case (constant, zero, steady state, single element), or from an invariant: conservation, symmetry, monotonicity, bounds, round-trip identity. Computing the expectation with the same formula or from intermediate fields of the result is a **mirror**: it agrees with the code even when the code is wrong. State each tolerance and why it has that size.

3. **Fake at the seam, run the subject.** Replace what is slow, remote, or nondeterministic: message brokers, cloud SDKs, HTTP clients, credentials, clocks, randomness. Run the parser, handler, retry loop, or model itself. Prefer real lightweight collaborators (in-memory stores, temporary directories, an embedded database, a local broker binary) over generic mocks. Patching a function inside the module under test replaces the subject.

4. **Make fakes strict and branch-specific.** A fake records what it received and the test asserts those records. Give success, timeout, malformed input, and rejection paths separate fakes so the wrong branch cannot satisfy the test. Use spec'd mocks or small hand-written fakes; a mock that accepts any call checks nothing.

5. **Assert outcomes over choreography.** Verify a call only when the call is the contract: the request sent to an external API, the subject published to, the scope requested. For internal steps, assert the effect they produce. A test that replays the current call sequence goes red on refactors and stays green on bugs.

6. **Test behavior, skip declarations.** Field defaults, constructor assignment, inheritance, constants, and plain forwarding need no test. Validation, normalization, config and env parsing, serialization round-trips, secret redaction, and rejection of bad input do.

7. **Test message-driven code at its delivery guarantees.** Assert what happens to the message: acked once, nacked or redelivered on failure, published to the right subject with the right schema, deduplicated or ordered as promised. Cover the empty batch, the poison message, and the broker timeout.

8. **Exercise infrastructure, do not restate it.** Nix modules and deployment config are tested by building or booting them and observing effects: the service starts, answers a request, writes the expected log or output, renders the expected config file. Re-evaluating the same expression to compare an option with itself is a mirror. Bound every wait with a timeout and assert on content, not only exit status.

9. **Run scripts, do not grep them.** Execute scripts and CLIs against controlled inputs; assert output, files, and exit code. Reading source to find a flag or line is not a test.

10. **Investigate red before editing expectations.** Decide whether the production change was intended. If yes, update the test to describe the new contract and say so in the commit. If no, fix the code. Loosening a tolerance needs the same justification.

11. **Let deletions prove themselves.** After removing code, the build and the replacement's tests are the proof. Tests asserting that a symbol, file, or option stays gone protect nothing; delete them as part of the cleanup.

12. **Characterize surprising upstream behavior narrowly.** When correctness depends on a dependency quirk (nullable schema unions, timezone and DST handling, null ordering, ack policies), pin it with one small test at the integration point and name the assumption in the test name.

## Shape

- Table-driven or parametrized tests with literal expected values; one behavior per test; name the test after the behavior.
- Keep fixture builders simple enough to verify by reading. A helper that computes expected values needs its own test.
- Make concurrency deterministic: drive async code with fakes that resolve on cue, zero retry delays, and wait on conditions instead of sleeping.
- Inject time; use fixed, timezone-aware timestamps.
- In Go, compare whole structs with `cmp.Diff` or `reflect.DeepEqual` and use `t.TempDir()` and `httptest` for real in-process boundaries.

## Mutation check

Before finishing, mutate the production code in your head. For each realistic mutation, at least one test goes red:

- wrong constant, unit, sign, or axis;
- off-by-one in a range, slice, or time window;
- wrong branch on error, timeout, or empty input;
- message not acked, acked twice, or sent to the wrong destination;
- missing, partial, or wrongly typed write;
- validation dropped for empty, null, negative, or malformed input;
- secret leaking into serialized output or logs;
- config option not wired into the running service.

If none go red, the test is a tautology.

## Triage when reviewing

`tautology-triage FILE...` (on `PATH`; source `triage.sh` beside this file) scores every test in the given files with the Decision-1 model and prints `score  label  file:line:name`, highest first. It uses `AZURE_API_KEY` and `AZURE_RESOURCE_NAME` from the environment, or loads them with `aienv --azure`; that requires Azure login and Key Vault access. `tautology-triage --rubric` does not need Azure credentials. It reads only the test, not the production code, so treat it as a pointer to where to look. Measured against careful review: score ≥ 90 or label `weak_assertion` catches most tautologies with about one false alarm per hit; `mocks_subject` and `mirror` labels are usually wrong. Confirm every candidate with the mutation check against the production code before reporting it.
