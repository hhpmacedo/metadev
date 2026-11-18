# Foundation: Vercel AI SDK

- **Last validated:** 2026-11-18, checked against the AI SDK documentation (ai-sdk.dev), the migration guides and loop-control page shipped inside the `ai` package, and the type definitions and runtime defaults of `ai` 5.0.291, 6.0.333 and 7.0.176, by an automated documentation check. Not yet confirmed in a live project.
- **Versions checked:** `ai` 7.0.176 (npm `latest`); 6.0.333 (`ai-v6`) and 5.0.291 (`ai-v5`) for the older names
- **Review cadence:** every 3 months, and whenever the SDK has a major release
- **Covers:** the one configuration fact the team has learned the hard way about tool-calling pipelines
- **Does not cover:** the rest of the SDK; read its current documentation

## Multi-step tool calling

- A chat route that lets the model call tools runs as a loop of steps: a model call, the tool executions, then another model call that receives the tool results. The loop is controlled by the `stopWhen` option of `generateText` and `streamText`.
- When `stopWhen` is not set, `generateText` and `streamText` stop after one step (the default is a step count of 1, in `ai` 5, 6 and 7). They do not loop. The model's tool calls are executed, but no further model call is made, so the response ends with tool results and no answer text. No error is raised.
- Setting `stopWhen` is therefore what enables multi-step tool calling, and the step count given is the upper bound on model calls, for example `stopWhen: isStepCount(5)`.
- The step-count helper is imported from `ai`. Its name depends on the major version:

| `ai` version | Bounding a tool loop |
| --- | --- |
| 4.x and earlier | `maxSteps: 5` (removed in 5.0, including from `useChat`) |
| 5.x, 6.x | `stopWhen: stepCountIs(5)` |
| 7.x | `stopWhen: isStepCount(5)`; `stepCountIs` is still exported as an alias in 7.0.176. The codemod `rename-step-count-is` does the rename. |

- `stopWhen` accepts one condition or an array; the loop stops when any condition is true. Conditions are evaluated only when the last step contains tool results. Other built-in conditions are `hasToolCall('<tool name>')` and, from 6.x, `isLoopFinished()`.
- Independently of `stopWhen`, the loop ends when the model returns a finish reason other than tool calls, when a tool without an `execute` function is called, or when a tool call needs approval.
- A loop can run without an upper bound only when it is configured that way: `stopWhen: isLoopFinished()` (which never triggers), a custom condition that never returns true, or `WorkflowAgent.stream()` in 7.x, which applies no default step limit.
- `ToolLoopAgent` (6.x and 7.x) has a different default from `generateText` and `streamText`: it stops after 20 steps when `stopWhen` is not set.
- The default and the stop conditions are documented on the "Tool Calling" page, in the `generateText` and `streamText` reference, and on the agents "Loop Control" page.

## Validation notes (2026-11-18)

- Sources:
  - https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling
  - https://ai-sdk.dev/docs/reference/ai-sdk-core/generate-text
  - `npm view ai version dist-tags` (latest 7.0.176, ai-v6 6.0.333, ai-v5 5.0.291)
  - Package contents of `ai` 7.0.176: `dist/index.d.ts`, `dist/index.js`, `docs/03-agents/04-loop-control.mdx`, `docs/08-migration-guides/23-migration-guide-7-0.mdx`, `docs/08-migration-guides/26-migration-guide-5-0.mdx`, `CHANGELOG.md`
  - Package contents of `ai` 6.0.333 and 5.0.291: `dist/index.d.ts`, `dist/index.mjs`
- Corrected:
  - "Without an explicit stop condition the loop can continue indefinitely" -> without `stopWhen`, `generateText` and `streamText` stop after one step; the failure is a conversation that ends after the tool call with no answer text, not an endless loop.
  - "`stopWhen: stepCountIs(5)` ... the option name comes from SDK v6" -> `stopWhen` and `stepCountIs` date from 5.0 (replacing `maxSteps`); in 7.x the helper is `isStepCount`, with `stepCountIs` kept as an alias.
  - "The requirement is not prominent in the SDK documentation" -> the default and the stop conditions are stated in the tool-calling page, the function reference and the loop-control page.
  - "Its absence stalls or loops a production conversation without an error" -> it stalls (ends after one step) without an error; it does not loop.
  - Added, to make the above exact: the conditions under which a loop is unbounded, and the `ToolLoopAgent` default of 20 steps.
- Still unverified:
  - Whether `stepCountIs` is formally marked deprecated in 7.x (it is exported as an alias in 7.0.176 with no deprecation tag found in the type definitions; the migration guide only says to rename it).
  - Behaviour was read from documentation, type definitions and the default parameter in the built code; no model call was run.
