---
name: agentic-feature-design
description: Designing a feature built on models or agents - deciding the units of work and their boundaries, the coordination shape, tool access, guardrail layers and context budget. Use when a design includes one or more model-driven agents, a multi-agent workflow, or tools that a model can call.
user-invocable: false
---

# Agentic feature design

A good agentic design gives each agent one bounded job, the fewest tools that job needs, an explicit handoff to the next step, and guardrails that do not depend on the model behaving well. It is written into the design document like any other part of the architecture.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| Project `knowledge/foundations/foundation-<subject>.md` for the model provider and agent runtime in use | Which models are available, their context limits and costs, and what the runtime can enforce (tool restrictions, isolation, hooks) |

What a model or agent runtime can enforce changes often, and this technique does not describe any runtime's configuration format. If the design depends on a runtime capability or a model behaviour that is not in a foundation, verify it with a real call or current documentation. If you cannot, stop and return `needs-decision`. Do not design around a capability you remember.

## Required context

- The requirement the feature serves and what a correct result looks like (required).
- The actions the feature can take and which of them are hard to undo or touch user data (required).
- The model provider and agent runtime the project uses (required).
- The rest of the design, since this technique fills in one part of a `solution-design` (required).
- Expected volume and cost ceiling (optional, but it decides the model per role).

## Approach

1. **Decide whether the work needs an agent at all.** The simplest design that meets the requirement wins here too. Sort each piece of work into one of three kinds:
   - a reusable procedure or body of domain knowledge, which is loaded when needed;
   - an autonomous role with ongoing responsibility, which is an agent;
   - a one-off operation the user triggers, which is a command.
   Only the second kind needs an agent. Whether the feature should use a model at all is a product decision covered by `ai-feature-design`; this technique starts once that is settled.

2. **Give each unit a single purpose and a clear boundary.** State what each agent is responsible for and what it must not do. A generalist that does everything is harder to verify than specialists with clear scope.

3. **Define tool access per agent.** Give each agent only the tools its job needs. A reviewing or testing agent is read-only plus the one tool it tests with. Restrictions the runtime enforces are worth more than instructions the model is asked to follow.

4. **Choose the model per role.** Use a stronger model where the work is strategy or judgement and a cheaper one where it is execution. Record the choice in the design.

5. **Choose the coordination shape.**

   | Shape | How it works | Use when |
   | --- | --- | --- |
   | Sequential pipeline | Agents run in sequence. Each completes and returns its result; the parent passes the relevant context to the next. | Work moves through checkpoints and each step depends on the previous one. |
   | Parallel with isolated workspaces | Each agent works in its own isolated copy. Changes merge only after tests pass. | Independent workstreams that write; isolation removes conflicts. |
   | Team with a shared task list | Agents have independent contexts, share a task list and can message each other. | Read-heavy parallel work. |
   | Council | A generalist is decomposed into bounded specialists. Each has a clear scope it cannot exceed. An orchestrator delegates and synthesizes. | One role covers too many concerns to do each well. One team reported an 85% reduction in flaky tests and twice the test coverage from applying it to QA (unverified). |

   Default to the sequential pipeline. Have one coordinator as the entry point.

6. **Make handoffs explicit.** Say what each agent receives and what it returns. Synchronize at checkpoints. Where a sub-task produces a lot of intermediate output, run it in an isolated context that returns only a summary, so the parent's context is not filled with detail it does not need.

7. **Design the guardrails in three layers.**
   - Preventive, before an action: block dangerous operations before they run.
   - Corrective, after an action: fix what can be fixed mechanically, such as formatting.
   - Verification: an independent check of the result, for example that the file exists and contains no secrets.
   Include the guardrail layers in the design document.

8. **Treat the context budget as an architecture concern.** Tool definitions and always-loaded instructions take context before any work starts. Keep always-loaded instructions lean, load domain knowledge on demand with a short summary first and details behind it, load tool definitions on demand when there are many, and remove duplicate tool servers.

9. **Verify the models and SDKs with a real call** before the design depends on them, and plan to test the feature with real usage. The prompts are part of the implementation and need the same testing as code.

10. **Fill in the testability notes** in the design: which model calls can be mocked, which need real calls, and what has to be judged by a person.

## Done means

- The design lists each agent with its responsibility, the tools it may use and the model it runs on.
- The coordination shape is named, with the reason, and there is a single entry point.
- Each handoff states its input and output.
- The three guardrail layers are described, and every action that is hard to undo is covered by a preventive one.
- The design states what is always loaded into context and what is loaded on demand.
- Every model, SDK and runtime capability the design relies on has been confirmed by a real call or current documentation.
- The testability notes say what is mocked, what is real and what is manual.

## Anti-patterns

- **An agent where a procedure would do.** An agent adds cost and unpredictability. Use one only for work that needs autonomy.
- **One generalist agent with every tool.** Its scope cannot be checked and its mistakes can reach everything. Split it into bounded specialists.
- **Guardrails written only as instructions.** A rule in a prompt is a request. Put the important ones where the runtime enforces them.
- **Parallel agents writing to the same workspace.** They conflict. Isolate them and merge after tests pass, or run them in sequence.
- **Passing the whole history between agents.** Pass the relevant context and the result. The rest fills the budget.
- **Loading everything up front.** Many tool definitions and long standing instructions leave little room for the task.
- **Designing from remembered model or runtime behaviour.** These change between releases. Check first.
