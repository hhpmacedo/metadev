---
name: ai-feature-design
description: The product-level decision about whether and how a feature uses a language model - what the model does, what context it is given, how wrong answers are caught, and how the prompt is shaped. Use when scoping a feature that might use AI, writing requirements for one, or reviewing a prompt and its context.
user-invocable: false
---

# AI feature design

A good outcome is a feature where the model does only the part that needs judgment, a wrong answer is cheap to notice and correct, and the requirements say so in terms QA can test.

This technique covers the product decision. The architecture of features built on agents (orchestration, tools, multi-agent coordination) is the `agentic-feature-design` technique.

## Required foundations

None.

## Required context

- The user job the feature serves and the requirement it belongs to (required).
- What the input looks like in practice, with real examples if available (required).
- What happens when the answer is wrong: who notices, and what it costs (required).
- Latency and cost expectations for the feature (optional).

## Approach

1. **Decide whether the task is a fit.** Good fits:
   - Unstructured to structured: turning free-form input into organised data.
   - Generation with constraints: creating content within defined parameters.
   - Classification and routing.
   - Summarisation.
   - Natural language interfaces to a system.
   - Augmentation: enhancing what a person can do, not replacing their judgment.

   Poor fits:
   - Deterministic operations (maths, lookups, CRUD). Use ordinary code.
   - High-stakes decisions without oversight. The model informs, a person decides.
   - Paths where real-time performance is critical. A model call adds latency.
   - Simple rule-based logic. If-then rules do not need a model.

2. **Run the four questions.**
   1. Does this require understanding intent or context? If yes, consider a model.
   2. Is there significant variability in the inputs? If yes, consider a model.
   3. Is roughly 95% accuracy acceptable? If not, reconsider.
   4. Can a person review or override? This is required for consequential decisions.

3. **Define exactly what the model does and what ordinary code does.** Keep the model's part as small as the job allows. Everything deterministic around it (validation, storage, calculations) stays in code.

4. **Design for the wrong answer.**
   - Set expectations: be clear in the product about what the feature can and cannot do. Never promise perfection.
   - Degrade gracefully when the model fails or is unavailable.
   - For important decisions, the model proposes and the person decides.
   - Make the reasoning visible where possible.
   - Give an easy way to override or correct.

5. **Plan the feedback loop.** Capture when the model gets it wrong, use corrections to improve over time, and measure actual against expected performance.

6. **Decide what goes into the context.**
   - In: information directly needed for the task, background that improves quality, organised so it is easy to refer to.
   - Out: redundant information, stale data, loosely related content that adds noise.
   - Structure it, either hierarchically (goal, current task, specific details) or in named sections:

   ```
   ## User Info
   [who they are]

   ## Current State
   [what's happening]

   ## Task
   [what to do]
   ```

7. **Shape the prompt.**
   - Role, context, task, format: who the model is and whom it helps, the background, the specific task, the desired output format.
   - Few-shot examples: show two or three input and output pairs, then the real input.
   - Step-by-step reasoning for complex judgments: ask the model to consider, then evaluate, then decide.
   - Explicit boundaries: "Only use information from the provided context", "If unsure, say so rather than guessing", "Keep the response under X words".

8. **Write it into the requirements.** State the accuracy that is acceptable, the review or override path, the failure behaviour, and which guardrails apply: preventive (block a dangerous operation before it runs), corrective (validate or format the output afterwards), verification (a second check on complex conditions), and pipeline checks that catch what the model misses.

## Done means

- The requirements say what the model does, what code does, and why a rule would not do the model's part.
- An acceptable accuracy level is written down, with how it will be measured.
- A person can review or override every consequential output, and the requirements name where.
- The behaviour when the model fails or returns something unusable is specified and testable.
- The context given to the model is listed, and each item is there for a stated reason.
- There is a way to record wrong answers once the feature is live.

## Anti-patterns

- **Using a model where a rule would do.** It adds latency, cost and a failure mode to something code does exactly.
- **Promising perfection, or designing only for the right answer.** The feature then has no behaviour for the wrong one.
- **Letting the model make a consequential decision with no person in the loop.**
- **Filling the context with everything available.** Stale and loosely related content lowers quality. Budget the context for the task.
- **Shipping with no way to learn from errors.** Without captured corrections, quality cannot be measured or improved.
