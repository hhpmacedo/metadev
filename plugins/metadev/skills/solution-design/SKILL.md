---
name: solution-design
description: Going from approved requirements to an architecture a developer can build from - options and trade-offs, fitting the patterns already in the codebase, the data model and API shape, and the deployment and testability sections. Use when writing or revising a design document, structuring a system, data model or API, or deciding between architecture patterns.
user-invocable: false
---

# Solution design

A good design is the simplest one that meets the requirements, answers every open question decisively, and is specific enough that a developer can implement from it without guessing. It also says how the result is deployed, rolled back and tested.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| Project `knowledge/foundations/foundation-<subject>.md` for each platform or service the design touches | Limits, quotas, behaviour and known problems that constrain the design |
| The matching `foundation-<subject>.md` (plugin, `foundations` skill) for the hosting platform, database and framework in use | How the tool behaves, so the design does not assume something the tool does not do |

If the design depends on a limit, quota or behaviour of an external service and no foundation or current documentation states it, do not guess. Verify it with a real call or the current documentation; if you cannot, stop and return `needs-decision`.

## Required context

- The approved requirements for the work, including success criteria and the open questions addressed to the architect (required).
- The existing codebase: its structure, the patterns it already uses, and its project instructions file (required).
- Constraints: team size, timeline, existing systems, budget (required).
- The environments the project deploys to and how it is deployed today (required for the deployment section).
- Who will write the test plan and when (optional, but it shapes the testability section).

## Approach

1. **State the requirements and constraints in your own words.** Cover functional and non-functional requirements, then team size, timeline and existing systems. If a requirement is ambiguous, resolve it with the product manager now. A design built on a guessed requirement is rework.

2. **Read how the codebase already solves similar problems.** Fit the patterns already there unless there is a written reason not to. A second way of doing the same thing costs more than a slightly imperfect fit.

3. **Find the simplest approach that works and start there.** Add complexity only when there is evidence it is needed. Add structure when a second real use appears, not before. Ask what the central object of the feature is and whether the data model treats it as first-class: modelling the product's core concept as its own entity can be a better answer than restructuring existing screens around it.

4. **Lay out the real options with their trade-offs, then choose.** For structure, data and API style, `references/pattern-catalogue.md` lists the common patterns with when to use each and what each costs. Defaults that hold unless the requirements say otherwise: a modular monolith for a new project, REST for a web API, no CQRS or event sourcing without a specific requirement for them. Record the choice and the reason. Present a decision, not a menu.

5. **Ask what could go wrong and what might change.** Design for the likely failure modes. Put abstractions where change is likely and nowhere else.

6. **Check the data model and API shape against the UX intent.** The API response shape determines what the frontend can do. Walk through each interaction in the requirements and confirm the shape supports it. Example of the failure: the design returns one detail card per item, while the requirement says each stage of an item expands its own card. The singular field makes the required interaction impossible. Resolve these tensions in the design, not during implementation.

7. **Keep components separate and dependencies visible.** Each component has one job. A change in one area should not cascade to others. Make dependencies explicit, prefer configuration over convention where clarity matters, and document what is not obvious.

8. **Verify external dependencies before the design relies on them.** Check each external API, SDK and model with a real call or current documentation. For choosing a new framework, service, library or model, use the `technology-selection` technique. For a feature built on models or agents, use `agentic-feature-design`.

9. **Write the design so it can be implemented directly.** Include function signatures, data shapes and endpoint contracts. Add a section that answers each open question from the requirements, one by one. This gives the design an audit trail and removes guessing downstream.

10. **Write a "Deployment requirements" section.** List every prerequisite that must exist before the code works in an environment: migrations, storage buckets, environment variables and secrets, third-party accounts, configuration changes. State how the change is rolled back. Whoever owns deployment verifies against this list, so an item missing here is found in production instead.

11. **Write a "Testability notes" section.** State what can be mocked, what needs real data, and what requires manual verification. QA writes the test plan against the design, and complex features (file upload, multi-step workspaces) are where testability constraints are easiest to miss.

12. **Run the design through the `design-review` skill** before building starts. It is the gate; this technique is how the design gets written.

13. **Keep the design true after building starts.** When an implementation deviates from the design, the developer records it as a design delta in the delivery report, and the architect either accepts it or corrects it. Without this the design document stops describing the system.

## Done means

- Every requirement and every open question from the requirements maps to a section or an explicit answer in the design.
- Each significant decision names the option chosen, the alternatives considered and the reason.
- Each interaction in the requirements has been traced through the data model and API shape, and none is blocked by them.
- The design names the existing patterns it follows, and gives a written reason for each place it departs from them.
- The "Deployment requirements" section lists migrations, storage, environment variables and external accounts, and says how to roll back.
- The "Testability notes" section says what is mocked, what needs real data and what is manual.
- Every external API, SDK or model the design depends on has been checked by a real call or against current documentation, and the design says which.
- A developer who was not in the discussion can say what to build first from the document alone.

## Anti-patterns

- **Big ball of mud.** No clear structure; everything depends on everything. Introduce boundaries one module at a time rather than planning a rewrite.
- **Golden hammer.** Using the same solution for every problem. Match the pattern to the problem.
- **Premature optimization.** Optimizing before you know where the problems are. Measure first, then optimize what matters. A single-user tool does not need a cache.
- **Building for hypotheticals.** "We might need it later" is not evidence. Leave it out.
- **Microservices without the problems they solve.** They bring very large operational complexity. They are for large teams, independent scaling needs or different technology needs per service.
- **Layers for their own sake.** Layering suits most applications, but it can produce unnecessary abstraction in a simple one.
- **Deployment prerequisites discovered at deploy time.** A design that needed a storage bucket, new migrations and a new API key, and listed none of them, cost a failed deployment. Put them in the design.
- **Data model that contradicts the interaction.** Caught late, it forces either an API change or a degraded interface. Trace the interactions in step 6.
- **A design that drifts silently.** If a developer adds something the design did not have and nobody records it, the next reader is misled. Use design deltas.
- **Offering a menu instead of a decision.** The design is where the architect decides. Escalate to the owner only what is risky or expensive, as `team-standards` defines.
