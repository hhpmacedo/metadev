---
name: technology-selection
description: Choosing a framework, service, library, hosting platform or model and recording why - requirements, options, trade-offs, total cost of ownership, and the conditions that would reopen the decision. Use when a design needs a technology the project does not already have, or when asked to compare or justify a stack choice.
user-invocable: false
---

# Technology selection

A good choice solves the problem with the least friction, is one the people maintaining it already understand, and is written down with its reason and with what would make the team revisit it.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-<subject>.md` (plugin, `foundations` skill) for each candidate that has one | Plan limits, rate limits, pricing tiers and known problems, with the date they were last validated |
| Project `knowledge/foundations/foundation-<subject>.md` | What the project already uses, on which plan, and any limits already reached |

If the decision turns on a limit, a price or a capability that no foundation states and you cannot confirm from current documentation or a real call, do not guess. Stop and return `needs-decision`, naming the fact that is missing. Treat a foundation whose validation date is old as a prompt to re-check, not as proof.

## Required context

- The requirement the technology has to meet, from the approved requirements or the design in progress (required).
- What the project and the team already use for similar problems (required).
- Constraints: team skills, budget, timeline, existing systems and infrastructure (required).
- Who will maintain the result (required).
- The owner's stated preferences about stack or vendors, if any (optional; ask if unknown and the choice is expensive).
- Expected scale: users, data volume, request rate (optional, but needed to judge plan limits).

## Approach

1. **Define the requirements.** Separate what it must do (hard requirements) from what it should do (nice to have). List the constraints. Without this, the evaluation becomes a comparison of features nobody asked for.

2. **Start from what is already in use.** Ask what the project already has and what the team already uses for similar problems. Choose boring, well-supported technology that the project already uses unless it fails a hard requirement. "Boring" means well documented, with an active community, known failure modes, and familiar to the team or quick to learn.

3. **Match the problem.** A command-line tool, a web application and a data-processing job suggest different tools. Name the kind of problem before naming candidates.

4. **Identify the options.** Name the obvious default, then the real alternatives. `references/common-choices.md` has comparison tables for frontend frameworks, backend runtimes, databases and hosting, with a default for each.

5. **Evaluate each option the same way.**
   - Pros: what it does well.
   - Cons: the downsides.
   - Risks: what could go wrong.
   - Fit: how well it matches this project's context.

6. **Count the total cost of ownership,** not only the cost of adopting it: learning curve, operational complexity, maintenance burden, ecosystem and tooling, long-term viability. New technology is worth it only when it gives a significant advantage for this specific problem.

7. **Check plan limits against expected use.** Read the limits of the tier the project will be on (project count, storage, request and invocation quotas, rate limits, timeouts) and compare them with what the feature will do. Do not bend the design to stay inside a free tier once the project has real users: that creates technical debt that has to be undone at the upgrade. State in the decision when the upgrade is expected.

8. **Verify before the design depends on it.** Confirm the candidate's API, SDK or model behaviour with a real call or current documentation. Documentation from memory goes stale.

9. **Decide and document.** Choose on evidence, not preference. Record the decision, the rationale, the alternatives rejected and why, and what would make the team revisit it. A new paid service or new infrastructure is an expensive decision: follow `team-standards` on what goes to the owner.

10. **Start simple.** Complexity can be added later. It can rarely be removed.

## Done means

- The decision record names the hard requirements, the options considered, and the pros, cons, risks and fit of each.
- The record states the reason for the choice and the conditions that would reopen it.
- The chosen technology is either already in the project, or the record explains which hard requirement the existing tools fail.
- Plan limits and prices used in the decision cite a foundation or current documentation, with the date checked.
- The behaviour the design relies on has been confirmed by a real call or current documentation, and the record says which.
- The person who will maintain it is named, and the choice matches their skills.

## Anti-patterns

These statements signal a bad choice. When you hear one, go back to the requirements.

- **"It's what everyone is using."** Popularity without understanding why is not a reason.
- **"It's the future."** Unproven in production means its failure modes are unknown.
- **"It will be good for my resume."** Choosing technology because it looks good rather than because it fits. Choose boring technology that solves the problem.
- **"We might need it later."** Do not build for hypotheticals.
- **"It's more powerful."** Power you do not need is complexity you do not need.

Other failures:

- **Optimizing for a free tier.** Designing around free-tier limits for a product with real users trades a small monthly cost for rework later.
- **Discovering a limit in production.** Rate limits on signup, storage caps and function timeouts cause failures that look like bugs, including in automated tests. Read the limits in step 7.
- **Choosing without recording.** An undocumented choice gets re-argued by the next person, or silently reversed.
- **Evaluating only adoption cost.** The maintenance burden lasts longer than the build.
