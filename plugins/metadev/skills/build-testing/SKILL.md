---
name: build-testing
description: Functional testing of a build against its acceptance criteria - running the real flows, collecting evidence, and giving a ready or not-ready verdict that holds. Use when an increment or a finished feature has to be tested before it merges or is accepted; for a full multi-perspective pass (UX, accessibility, integration) run `qa-council` and apply this technique to its functional part.
user-invocable: false
---

# Build Testing

A good outcome is a pass or fail for every acceptance criterion, backed by evidence someone else can inspect, and a verdict that is acted on: a build with open blocking issues does not ship as delivered.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-playwright.md` (plugin, `foundations` skill) | The browser tool names, how prompts and dialogs stall a session, and how to recover |
| Project `knowledge/foundations/foundation-infrastructure.md` | The URL of each environment, how to get a test account, and how to reach protected preview deployments |

If the project has no record of which URL to test or how to sign in, stop and return `needs-decision`. Testing the wrong environment produces a verdict about something users never see.

## Required context

- Required: the acceptance criteria (for a mandate, its `requirements.md`).
- Required: the build to test and the environment it runs in. Test in the environment users will use.
- Required: whether this is an increment during implementation or the final validation before acceptance.
- Optional: the test plan (see `test-planning`). If there is none, write a short one first.
- Optional: test credentials and seed data.
- Optional: the list of issues from earlier rounds, to re-test.

## Approach

1. **Start when code starts landing, not when someone hands over.** QA has three moments: a test plan at design, incremental testing during implementation, and final validation at delivery. If code is being committed, test the increment. Bugs found early cost the developer far less rework than bugs found at "feature complete". If you are named on the work and have not been asked to test, say so.
2. **Run the core user flow end to end before anything else.** Complete the primary action; a page that loads proves nothing. For a feature that calls a model, confirm the conversation completes, tools execute and the response is coherent (see `ai-feature-testing`). Static analysis, type checking and code review catch syntax errors. Only running the feature catches misconfiguration, where the code is valid and the behaviour is broken. A single missing configuration line can put a flow into an endless loop and still pass every static check.
3. **Do this before the pull request merges.** Functional execution after the merge is a production incident waiting to be reported by a user.
4. **Drive the browser with automation and capture as you go.** Manual clicking is not reproducible and leaves no trail. The sequence for each flow:
   1. Navigate to the application.
   2. Take a snapshot to get the page structure and element references.
   3. Click, type and select using the references from the snapshot.
   4. Take a snapshot again to verify the result.
   5. Take a screenshot to document it.

   If the session has no browser tools, use real HTTP requests and record what could not be covered.
5. **Walk the acceptance criteria one by one.** Open the criteria, test each, and record pass or fail with its evidence. QA's job is to verify the criteria, not only to find bugs. Then apply the verify-before-done rule from `team-standards` to your own verdict.
6. **Go looking for where it breaks.** After the criteria, test invalid input, boundaries, empty states, failures of external services and concurrent sessions, following the plan's mandatory categories.
7. **Test every user-facing screen at 375px, 768px and 1280px, and at 1920px when the design targets large screens.** 375px is the smallest common phone viewport and is where clipped content and truncated labels appear.
8. **Split the work between automation and your own judgment.**

   | Use browser automation for | Use manual exploratory testing for |
   | --- | --- |
   | Functional flows: sign-in, form submission, navigation | Whether the flow feels intuitive |
   | Regression: the same test on every build | Visual polish: spacing, alignment, typography |
   | Responsive checks at each viewport | Whether it feels fast |
   | Reproducing a bug with the exact interaction sequence | Discovering edge cases by doing the unexpected |

   Automation answers "does it work". Exploratory testing answers "does it work well". A final validation needs both.
9. **Verify the deployment, not only the code.** Confirm that the production environment was the one tested, migrations were applied, and environment variables are set. This closes the gap between "the code works" and "the feature works in production". Use `deploy-verify` for the infrastructure checks.
10. **Report each defect with `bug-reporting`,** then write the QA report. For a mandate it goes in the mandate's `qa-report.md`. It must contain:
    - Test summary: how many cases were executed, passed, failed and blocked. A blocked count shows what could not be tested.
    - Acceptance criteria: pass or fail for each, with evidence.
    - Coverage: what was tested, and what was not tested and why.
    - Findings: a table with id, severity, description, reproduction steps, how it was found (automated script path, or manual) and the screenshot. The "how it was found" column shows how much of the detection is repeatable.
    - Open issues: bugs not yet fixed.
    - Deployment verification: the results of step 9.
    - Recommendation: ready for release, or not ready with the blocking issues listed.
11. **Own the verdict and follow it through.** If the recommendation is not ready, the work is not delivered until each blocking issue is fixed and re-tested, or the PM or the owner waives it explicitly and the waiver is recorded. Re-test fixes yourself and update the report.

## Done means

- The core user flow was completed end to end in the target environment, before merge, and the report shows it.
- Every acceptance criterion has a recorded pass or fail with evidence, and all pass or carry a recorded waiver.
- Every finding has a screenshot or log and reproduction steps.
- User-facing screens were checked at 375px, 768px and 1280px.
- The report states what was not tested and why.
- Deployment verification covers environment, migrations and environment variables.
- The report ends with a ready or not-ready recommendation, and every issue from earlier rounds is marked fixed and re-tested, waived, or still open.

## Anti-patterns

- **A QA report with no functional execution.** Reading the code and loading the page is not testing. The report is incomplete without the core flow run to the end.
- **Confirming the main path only.** A run that only shows the feature works when used correctly is not QA.
- **QA named but never run.** If QA is on the team for a piece of work, a QA report is a deliverable. Skipping QA is a decision the PM makes explicitly and records in the requirements; it does not happen by nobody asking.
- **Findings without follow-through.** Bugs that are found, recommended for fixing, and then shipped unresolved make the report documentation, not quality assurance.
- **Waiting for a formal handoff.** Testing only at the end turns every defect into rework.
- **Testing locally or on a different environment from the one users reach.** Configuration differences are exactly what this testing exists to catch.
- **Relying on secondhand descriptions of a bug.** Reproduce it yourself and gather the evidence, per the evidence-first rule in `team-standards`.
