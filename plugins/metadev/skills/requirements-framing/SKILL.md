---
name: requirements-framing
description: How to get from a request to requirements a team can build and QA can test - finding the real problem, stating it, writing stories and acceptance criteria, and deciding what is in, out and deferred. Use when framing a problem, writing or reviewing requirements, or deciding scope.
user-invocable: false
---

# Requirements framing

Good requirements trace every item to a person and the job they are trying to do, give QA a test for every success criterion, and say what is out of scope as clearly as what is in.

## Required foundations

None.

## Required context

- The owner's request in their own words, and the business context behind it (required).
- Who the user is and what they do today without this (required). If nobody can say, find out before writing anything.
- The existing product: what is already built that this touches (required when extending a product).
- Constraints on time, cost or technology (optional).

## Approach

1. **Find the job, not the feature.** Describe what the user is trying to accomplish:
   - Functional job: the practical task they need to complete.
   - Emotional job: how they want to feel.
   - Social job: how they want to be perceived.

   Frame the requirement around the job: "Help users [accomplish X] so they can [achieve Y]". A requirement that cannot be traced to a job is a candidate to cut.

2. **Ask why until you reach the real problem.** The first answer to "what do you want" is usually a solution.
   1. Why does the owner want this? Surface answer.
   2. Why is that important? Deeper need.
   3. Why does that matter? Core motivation.
   4. Why is that valuable? Business impact.
   5. Why now? Urgency and context.

3. **Write the problem statement.**

   ```
   [User] needs a way to [accomplish X]
   because [current situation or pain point],
   which results in [negative outcome].
   ```

4. **Map the flow before listing features.** Identify the user's goal, the steps to reach it, the decision points and where things can go wrong. Design for the happy path first, then the edge cases. For each step ask: what information does the user need, what actions can they take, what feedback do they get, and how do they know they succeeded? Each screen should have one primary action. Remove anything that does not serve the user's goal. When in doubt, leave it out.

5. **Write user stories.** Format: "As a [user type], I want [goal] so that [benefit]". A good story is independent (can be delivered separately), negotiable (details can be discussed), valuable, estimable, small and testable.

6. **Write acceptance criteria that QA can test.** Use "Given [context], when [action], then [expected result]". Include the happy path and the key edge cases. Be specific enough to test but not so specific that you constrain the implementation. If a criterion cannot be tested, it is not finished. Where precision removes ambiguity for the architect (exact field names, expected behaviours), give it.

7. **Decide scope explicitly.**
   - Must have: core functionality; the work fails without it.
   - Should have: important but not critical.
   - Could have: nice to have if time permits.
   - Won't have: explicitly out of scope. Write these down; an unstated exclusion comes back as a surprise.

   Scope that is not needed for the stated problem goes to the backlog, not into the build.

8. **Resolve ambiguity here, not in design.** If a requirement could mean two behaviours (for example the same element behaving per item and per group), decide which and write it down. List what you cannot decide as explicit questions for the architect.

9. **State the QA scope.** Say whether QA is required or optional for this work, and what it covers. If QA is named in the team but its scope is never stated, it tends not to happen.

10. **Hand over properly.** A good handoff has a clear deliverable, the context for why decisions were made, open questions flagged explicitly, and your availability for follow-up.

11. **Follow the requirements through to delivery.** Before QA, review the implemented copy and content against what you specified. Before the work is marked delivered, check each acceptance criterion against the working product.

## Done means

- The problem statement names a user, a situation and a negative outcome.
- Every requirement traces to the job in the problem statement.
- Every acceptance criterion is in a form QA can run, and QA (or a reader standing in for QA) can say how they would test each one.
- The document has a "won't have" list.
- QA scope is stated as required or optional.
- Open questions for the architect are listed, or the document says there are none.

## Anti-patterns

- **Writing the solution as the requirement.** "Add a dashboard" skips the question of what the user needs to see and why.
- **Leaving ambiguity for design.** A requirement that implied two different behaviours was left open, and the architect had to guess.
- **Untestable success criteria.** "Easy to use" and "fast" cannot be checked. Rewrite them or cut them.
- **Assuming documentation prevents omissions.** A feature that appeared in the requirements, the UX approach, the design and the acceptance criteria was still not built. The cause was that nobody walked the acceptance criteria as a checklist before delivery. More documentation would not have helped.
- **Verifying acceptance after marking delivered.** Check the criteria first, then mark delivered.
- **No review of implemented copy.** Content written in the requirements was implemented with inconsistent framing and nobody caught it until QA logged it as a bug.
- **Naming QA without activating it.** QA listed in the team for every phase but never run.
- **Imprecise status reports.** Crediting work to the role that was supposed to do it rather than the one that did. Say who did what.
- **Skipping checkpoints to save time.** Scope and approach before design work, technical design before implementation, working solution before acceptance. They prevent costly rework.
