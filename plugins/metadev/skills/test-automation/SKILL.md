---
name: test-automation
description: Deciding which tests to automate, writing them so they stay readable and stable, and driving a browser without the session stalling on prompts, banners, dialogs or sign-in. Use when adding automated tests for a feature, turning a manual check or a bug reproduction into a repeatable script, or when a browser automation run hangs or gives misleading failures.
user-invocable: false
---

# Test Automation

A good outcome is a small set of automated tests that run on every build, fail only when behaviour is broken, and tell the reader what broke; everything that needs human judgment stays manual on purpose.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-playwright.md` (plugin, `foundations` skill) | Browser tool names, non-interactive behaviour, permission and dialog handling, recovery from a stalled session |
| Project `knowledge/foundations/foundation-infrastructure.md` | Environment URLs, test accounts, and how protected preview deployments are reached |

If the project does not record how to obtain a test session or which URL is publicly reachable, stop and return `needs-decision`. Do not work around access protection by guessing.

## Required context

- Required: the behaviour to cover, as a test case or a reproduced bug with steps.
- Required: the environment the tests will run against.
- Required: the project's test runner and where tests live.
- Optional: test credentials or a way to create a session.
- Optional: the test plan, which already assigns a level to each case (see `test-planning`).

## Approach

1. **Decide whether the case should be automated at all.**

   | Automate when | Keep manual when |
   | --- | --- |
   | The test is run often | It is a one-time verification |
   | It is stable and does not flake | It is highly exploratory |
   | It catches real bugs | The area is likely to change soon |
   | It can be maintained | It needs human judgment, such as evaluating the experience |

2. **Put it at the lowest level that can catch the failure.** Many fast unit tests for business logic and algorithms, some integration tests for endpoints, database and service interactions, and few end-to-end tests reserved for critical journeys such as authentication and checkout. End-to-end tests are the slowest and the most fragile, so each one must earn its place.
3. **Test behaviour, not internals.** Do not test what the framework or library already guarantees, trivial getters and setters, or implementation details.
4. **Give each test a visible structure.** Arrange, act, assert:

   ```javascript
   // Arrange - set up test conditions
   const user = createTestUser();
   const order = createTestOrder(user);

   // Act - perform the action
   const result = orderService.process(order);

   // Assert - verify the outcome
   expect(result.status).toBe('completed');
   expect(user.orders).toContain(order);
   ```

   For user flows, state the case as given, when, then, so it reads as the acceptance criterion it verifies:

   ```
   Given a user with items in their cart
   When they proceed to checkout
   Then they should see an order summary
   And the total should match their cart
   ```

5. **Write for the person who will debug the failure.** Ask whether the test will catch a regression, whether it is clear what it checks, and whether a failure will be easy to diagnose. One behaviour per test, named after that behaviour.
6. **For browser tests, apply four rules.**
   - Select elements by `data-testid` attributes. Selectors tied to styling or text break on unrelated changes.
   - Wait for elements or conditions. Never use fixed delays; they are slow when the page is fast and flaky when it is slow.
   - Keep tests independent, with no shared state, so they pass in any order and alone.
   - Take a screenshot on failure, so the failure can be diagnosed without re-running.
7. **Clear the page before starting a flow.** Automated browser sessions cannot answer prompts by themselves, and an unanswered prompt looks like a broken feature.
   - Grant only the browser permissions the test needs (notifications, location, camera). There is no call that denies them; a permission that was not granted stays ungranted.
   - Take a snapshot first to detect a cookie consent banner, and dismiss it with a click before the flow. If an overlay still blocks interaction, remove it from the page with a script.
   - Dialogs from `alert()`, `confirm()` or `prompt()`: through the browser MCP server, handle the dialog after it opens (`browser_handle_dialog`); until then every other browser tool is refused. In a scripted Playwright test it is the other way round: register the handler before the action that triggers the dialog.
8. **Reach signed-in pages without repeating the sign-in flow.** Cookies can be set before navigating. Local storage belongs to an origin, so it needs a saved storage state, the server's storage tools, or a page of that origin already loaded. With token-based auth such as Supabase, inject the session token directly. For preview deployments behind access protection, use the publicly reachable address recorded in the project foundation.
9. **When the browser stalls, diagnose before retrying.**
   1. Take a snapshot. If a dialog is open the snapshot is refused and the tool response reports a modal state; handle the dialog first.
   2. Read the console messages for errors.
   3. Reload the page to reset state.
   4. If it is still stuck, close the page and open it again.
10. **Turn every reproduced bug into a script where the criteria in step 1 allow.** Save it in the project's test directory and reference its path in the bug report. The bug then has a regression check from the day it is fixed.

## Done means

- Each new test passes on the current build with the project's existing test command.
- Each test passes when run alone, with no dependence on another test's state.
- Repeated runs give the same result; a test that flakes is not finished.
- No browser test contains a fixed delay, and selectors use `data-testid`.
- A failing browser test produces a screenshot.
- The cases left manual are listed with the reason.
- Each automated bug reproduction is referenced by path in its bug report.

## Anti-patterns

- **Automating everything.** Tests for volatile or one-time checks cost more to maintain than they return.
- **Automating a judgment.** Whether something feels intuitive or fast cannot be asserted. Keep it exploratory.
- **Fixed delays.** They are the most common source of flaky tests.
- **Tests that depend on each other.** A shared account or leftover data makes failures appear in the wrong test.
- **Reading a stall as a product bug.** A consent banner, permission prompt or unhandled dialog produces misleading failures. Take a snapshot before reporting.
- **Signing in through the interface in every test.** Set the session directly and keep the flow under test short.
- **Many end-to-end tests, few unit tests.** The suite becomes slow and nobody runs it.
