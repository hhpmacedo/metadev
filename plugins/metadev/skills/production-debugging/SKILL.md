---
name: production-debugging
description: Find and fix the cause of a bug that shows up in a deployed environment, using evidence rather than guesses, one fix per deployment. Use when something is broken or behaving wrongly in production or preview and the cause is not yet proven.
user-invocable: false
---

# Production debugging

A good outcome is a fix for a cause you can point to, confirmed by the symptom disappearing, with nothing else changed.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| Project `knowledge/foundations/foundation-infrastructure.md` | Where the service runs, where its logs are, which environments exist |
| The platform files in the `foundations` skill | How to read logs and deployment state on the platform in use |

If the infrastructure foundation is missing, find the hosting and log locations from the repo's configuration and say that you did.

## Required context

- The symptom, as observed: what the user did, what they saw, what they expected. Required.
- Where it happens: environment, URL, account or data involved. Required.
- When it started, and what changed around then (deploys, migrations, configuration). Optional but usually decisive.

## Approach

1. **Reproduce it.** Follow the reported steps in the environment where it happens. If it does not reproduce, you do not yet understand the report; get more detail before reading code.
2. **Observe before theorising.** Collect what the system says: browser console, network requests and responses, platform logs, database state for the affected record. Write down what you saw, with timestamps.
3. **If you cannot observe the failing step, make it observable first.** Add logging or a diagnostic endpoint, deploy that alone, reproduce, and read the result. This is a deployment whose only purpose is evidence.
4. **State one hypothesis and the evidence for it.** "The request fails because X, shown by Y in the logs." If you have no evidence for it, it is a guess; go back to step 2.
5. **Check the hypothesis cheaply before fixing.** Predict something else that must be true if you are right (another record affected, a specific log line, a failing direct request) and look for it.
6. **Compare with what last worked.** Read the diff of the deploys since then, including configuration, environment variables and migrations, not only code.
7. **Fix the confirmed cause, and only that.** One change per deployment, so that the result tells you something.
8. **Confirm on the original reproduction.** Run the same steps in the same environment. Then check the nearest things the fix could have disturbed.
9. **Add what would have caught it:** a test, a validation, or a log line. Remove temporary diagnostics.
10. **Record it.** Update the project's Known Issues entry with the cause and the fix. If the cause was a fact nobody had written down, note it for the project foundation.

## Done means

- The original reproduction no longer fails, in the environment where it was reported.
- You can state the cause in one sentence and point to the evidence.
- The fix is one change, on its own commit.
- A test or check now covers the case, and temporary instrumentation is gone.

## Anti-patterns

| What goes wrong | Instead |
| --- | --- |
| Deploying a plausible fix without evidence | It often changes the symptom and hides the cause. Observe first. |
| Several fixes in one deployment | You cannot tell which one worked, or which one broke something else. One at a time. |
| Debugging locally a bug that only happens in production | The difference between the environments is usually the bug: configuration, data, versions. Work where it fails. |
| Reading code for an hour before reproducing | Reproduction narrows the search more than reading does. |
| Stopping when the error message disappears | Confirm the user's goal now completes, not only that the error is gone. |
| Leaving diagnostic logging in place | It becomes noise and can leak data. Remove it in the fixing commit or the next. |
