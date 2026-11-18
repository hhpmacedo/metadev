---
name: bug-reporting
description: Writing a bug report that a developer who was not there can reproduce, with evidence and a severity that tells the team what to do next. Use when you have found a defect during testing or in production and need to record it or hand it to a developer.
user-invocable: false
---

# Bug Reporting

A good report is fixed without a single question coming back: the developer follows the steps, sees the same failure, and knows from the severity whether to stop everything or schedule it.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-playwright.md` (plugin, `foundations` skill) | Tool names for snapshots, screenshots, console messages and network requests, when the bug is in a browser |

The foundation is only needed for browser bugs. For anything else, none.

## Required context

- Required: the build and environment where the defect appeared (URL, browser, operating system, viewport, account and data state).
- Required: what should have happened, taken from the acceptance criteria or the design. If nothing states the expected behaviour, say so in the report; do not present your assumption as the requirement.
- Optional: where the project tracks bugs (for example a known-issues table in the project instructions), so the report lands where the team looks.
- Optional: the path of an automated script that triggers the bug.

## Approach

1. **Reproduce it yourself.** Do not write a report from someone else's description. This is the evidence-first rule in `team-standards`: see the failure before you describe it.
2. **Write down the steps as you repeat them,** including the starting point (signed in or not, which data exists), so a developer can follow them without you.
3. **Gather evidence while it is on screen.** Browser console messages, the failing network request and its response, a page snapshot, a screenshot. For a browser bug, capture the exact interaction sequence with browser automation so it can be replayed.
4. **Write the report.** It must contain the following, each for a reason:
   - Summary: one line naming what fails and where, so the list of bugs can be scanned.
   - Steps to reproduce: numbered, starting from a known state, ending with the step where the failure appears. Someone who was not there must be able to follow them.
   - Expected behaviour: what should happen, and the source of that expectation.
   - Actual behaviour: what happens, with the exact error text.
   - Environment: browser, operating system, viewport, URL, and relevant data state. Many bugs only appear in one of these.
   - Severity: one of the four levels below.
   - Evidence: screenshots and logs.
   - How it was found: the path of the automated script, or "manual". This tells the team whether a regression check already exists.
5. **Assign severity by impact and workaround.** The level carries the action.

   | Severity | What it is | Action |
   | --- | --- | --- |
   | Critical | System crash, data loss or security breach; core functionality completely broken; no workaround | Stop and fix immediately |
   | High | A major feature broken; significant user impact; the workaround is painful | Fix before release |
   | Medium | A feature partially broken; moderate impact; a reasonable workaround exists | Fix soon; not necessarily a blocker |
   | Low | Minor or cosmetic; minimal impact; easy workaround or can be ignored | Fix when convenient |

   When two levels seem to fit, ask whether a user can still finish what they came to do, and how hard the workaround is.
6. **State a cause only if the evidence supports it.** A hypothesis about the root cause helps when it comes from a log line or a failing request. Label it as a hypothesis. A guess presented as a finding sends the developer in the wrong direction.
7. **File it where the team tracks bugs.** A Critical bug is raised immediately, because its action is to stop and fix; it does not wait for the QA report.
8. **Follow it through.** A reported bug needs a recorded resolution. After the fix, run the original steps on the fixed build and record the result.

## Done means

- You reproduced the failure yourself.
- A person who was not present can trigger the failure using only the steps and environment in the report.
- Expected and actual behaviour are both stated, and the expected behaviour names its source.
- The report has exactly one severity from the four levels, and it matches the table.
- At least one piece of evidence is attached (screenshot, log, or failing request).
- The report is recorded where the project tracks bugs.
- After a fix, the report shows a re-test result.

## Anti-patterns

- **No reproduction steps.** A report without them is sent back, and the round trip costs more than writing the steps would have.
- **Reporting from a secondhand account.** What the reporter remembers is rarely the minimal path. Reproduce first.
- **"It does not work."** State the exact step, the exact message and the exact state.
- **Leaving out the environment.** "Works for me" is usually a difference in browser, viewport or data.
- **A cause stated without evidence.** A guess presented as a finding misdirects the fix.
- **No record of resolution.** A bug that was found and then never tracked to a fix or a waiver was only documented.
