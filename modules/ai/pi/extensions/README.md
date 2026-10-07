# Pi controls

`/session-budget` shows recorded cost and latest request context for the current session, including inherited history. Warnings default to 100,000 context tokens and $10. Set `PI_CONTEXT_WARNING_TOKENS` or `PI_SESSION_WARNING_USD` to change them; zero disables a warning. Thresholds are starting values to calibrate against task quality and completion cost, not context limits or reset boundaries. Warnings do not stop execution. Other sessions and non-token charges are excluded.

Run tests with `node --test modules/ai/pi/extensions/session-budget.test.ts`.
