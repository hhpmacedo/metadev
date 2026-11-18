---
name: test-planning
description: Turns acceptance criteria and a design into a test plan - what will be tested, at which level, what is critical, and what is deliberately left out. Use when a design is being reviewed and tests have to be planned before implementation starts, or when a build arrives with no plan and you must decide what to cover.
user-invocable: false
---

# Test Planning

A good plan lets someone else run the tests and reach the same verdict: every acceptance criterion maps to at least one case, the riskiest areas are covered first, and everything left out is listed with a reason.

## Required foundations

None.

## Required context

- Required: the acceptance criteria (for a mandate, its `requirements.md`). If the criteria are missing or cannot be tested as written, stop and return `needs-decision` with the criteria that need rewording; do not invent them.
- Required: the design or a description of what is being built, including every external service it calls.
- Required: the environment users will actually use (production URL, preview URL, device types).
- Optional: bugs found in earlier work on the same product. What has broken before is likely to break again.

## Approach

1. **Review the criteria for testability.** For each acceptance criterion ask what you would observe to call it passed. A criterion with no observable result ("the page feels fast") goes back to the PM for rewording before the design is approved. This is the cheapest moment to fix it.
2. **Review the design for testability, not only for test cases.** Complex features (file upload, multi-step workspaces) need testability planning, not only test planning. Raise concerns with the architect during design review, while the design can still change.
3. **Look at the feature from three positions.** Each one produces different cases.
   - As a user: what are they trying to accomplish, what mistakes will they make, what would confuse or frustrate them?
   - As an attacker: which inputs could break it, which assumptions can be violated, what happens under stress?
   - As a maintainer: will this test catch a regression, is it clear what it checks, will a failure be easy to diagnose?
4. **Cover the base set for every feature.** The main path, input validation (invalid input is rejected correctly), error handling (it fails without losing data or showing internals), edge cases (boundaries, empty input, nulls), and every acceptance criterion.
5. **Add the three mandatory categories.** These are the areas most often missed, so each must appear in every plan. If one does not apply, mark it N/A and say why.
   - **Data format validation.** Normalization of input and output formats: phone numbers, emails, dates, currency. Use the variants real people type, not only the clean format.
   - **Concurrent operations.** Several users or sessions at once. Check that state does not leak between sessions and that uniqueness constraints hold.
   - **External API contracts.** Check that real responses have the shape the code expects. Mocked tests are not enough: include at least one live smoke test per external dependency, because a simulator or mock can drift from the real service without anyone noticing.
6. **Pick the cases with boundary values and equivalence classes** so the plan stays small.
   - Boundaries: minimum minus one, minimum, minimum plus one, maximum minus one, maximum, maximum plus one.
   - Equivalence classes: group inputs that should behave the same and test one from each group (one valid email, one invalid format, one empty string).
7. **Rank by risk.** Ask three questions: what would be worst if it broke, what is most likely to break, what has broken before. Cases that score on any of them are the critical ones and run first. Give every case a priority.
8. **Choose the level for each case.** Put a case at the lowest level that can catch the failure, so the suite has many fast tests and few slow ones.

   | Level | Use for | Character |
   | --- | --- | --- |
   | Unit | Core business logic, pure functions, complex algorithms | Fast, isolated, many |
   | Integration | API endpoints, database interactions, service integrations | Slower, real interactions, fewer |
   | End-to-end | Critical user journeys, checkout, authentication | Slowest, most realistic, fewest |
   | Exploratory | New features and complex interfaces, after automated tests pass | Unscripted, relies on human judgment, finds the unexpected |

9. **Leave out what is not worth testing, and write it down.** Framework and library behaviour is already tested by its authors. Trivial getters and setters carry no risk. Implementation details should not be tested at all: test behaviour, so a refactor does not break the suite.
10. **Share the device and viewport matrix with the developers at the start of implementation.** For user-facing work the matrix is 375px (smallest common phone), 768px (tablet portrait) and 1280px (desktop), plus 1920px when the design targets large screens. Developers who have the matrix test at 375px while building; clipped and truncated layouts are then caught during development and not at final QA.
11. **Write the plan.** It contains:
    - Scope: the features and areas under test.
    - Test cases: an id, a description, the steps, the expected result and a priority for each. The expected result must be specific enough that two people would agree on pass or fail.
    - The three mandatory categories, each with cases or an N/A and its reason.
    - Out of scope: what is deliberately not tested, so nobody assumes it was.
    - Environment: where and how the tests will run.
    - Risks: what might prevent thorough testing.

## Done means

- Every acceptance criterion is linked to at least one test case, and no criterion is left without an observable expected result.
- The plan contains all three mandatory categories, each with cases or an explicit N/A with reasoning.
- Every case has a priority and a level, and the critical cases can be listed on their own.
- Every external dependency has at least one live smoke test in the plan.
- The plan has out-of-scope, environment and risks sections that are filled in, not empty.
- The developers have received the viewport matrix before implementation started (for user-facing work).
- Testability concerns about the design were raised with the architect before the design was approved, or the plan states there were none.

## Anti-patterns

- **Planning only the main path.** A plan that confirms the feature works when used correctly finds almost nothing. Most shipped bugs sit in format handling, concurrency and the boundary with external services.
- **Trusting mocks for external services.** A mock encodes what the developer believed the service returns. Plan a live call for each dependency.
- **Clean test data only.** Real people type phone numbers, dates and amounts in many formats. Plan the variants.
- **Planning tests after the build is finished.** Testability problems found then are expensive. Plan during design, test increments as they land, and validate at delivery.
- **Silent omissions.** An area left out without a note reads as covered. List it under out of scope.
- **Testing internals.** A case tied to how the code is written fails on every refactor and says nothing about behaviour.
- **Keeping the viewport matrix until final QA.** Responsive defects that a developer could have seen in a minute come back as bug reports.
