# Foundation: Vercel AI SDK

- **Last validated:** not re-validated since February 2026 (carried over from `ai-testing-patterns.md` and `design-review-framework.md`)
- **Review cadence:** every 3 months, and whenever the SDK has a major release
- **Covers:** the one configuration fact the team has learned the hard way about tool-calling pipelines
- **Does not cover:** the rest of the SDK; read its current documentation

## Multi-step tool calling

- A chat route that lets the model call tools runs as a loop of steps. Without an explicit stop condition the loop can continue indefinitely.
- The stop condition is set in the pipeline configuration, for example `stopWhen: stepCountIs(5)`. (unverified for current SDK versions; the option name comes from SDK v6)
- The requirement is not prominent in the SDK documentation. It is a one-line setting whose absence stalls or loops a production conversation without an error.
