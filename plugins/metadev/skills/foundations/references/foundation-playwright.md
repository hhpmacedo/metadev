# Foundation: Playwright browser automation

- **Last validated:** not re-validated since February 2026 (carried over from `skills/testing/references/testing-strategies.md`)
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** the Playwright MCP server as used from a Claude Code session: tool names, non-interactive behaviour, permission prompts, overlays, dialogs, signs of a stalled session, viewport sizes used for responsive checks
- **Does not cover:** the Playwright test runner (`@playwright/test`) configuration, CI setup, other browser tools (Chrome DevTools, Claude in Chrome), how a specific project's preview deployments or auth are reached

## Tools exposed by the Playwright MCP server

| Tool | What it does |
| --- | --- |
| `browser_navigate` | Loads a URL. Navigating to the current URL reloads the page and resets its state. |
| `browser_snapshot` | Returns the page structure with element references (refs). Refs from the snapshot are what the interaction tools take as targets. |
| `browser_click` | Clicks an element identified by a ref. |
| `browser_type` | Types text into an element identified by a ref. |
| `browser_select_option` | Selects an option in a select element. |
| `browser_take_screenshot` | Captures an image of the page. |
| `browser_resize` | Changes the viewport size. |
| `browser_handle_dialog` | Accepts or dismisses an `alert()`, `confirm()` or `prompt()` dialog. |
| `browser_console_messages` | Returns the page's console output, including errors. |
| `browser_evaluate` | Runs JavaScript in the page. |
| `browser_run_code` | Runs a Playwright code snippet that receives the `page` object, giving access to the browser context (permissions, cookies, local storage). |

Tool names and availability depend on the installed version of the server (unverified for current releases).

## Non-interactive behaviour

- The Playwright MCP server in a Claude Code session runs non-interactively. Nobody is present to answer a prompt in the browser window.
- Three things can appear that the interaction tools do not dismiss automatically: browser permission prompts (notifications, location, camera), cookie consent banners, and authentication dialogs.
- An undismissed prompt, banner or dialog stalls the snapshot and click flow. The resulting failures look like defects in the application but are not.
- A snapshot taken during a stall may show the dialog or permission prompt that is blocking the page.

## Permissions

The browser context controls permission prompts. A snippet for `browser_run_code`:

```javascript
// Deny all permission prompts
async (page) => {
  const context = page.context();
  await context.grantPermissions([]); // deny all
  // or grant specific ones: await context.grantPermissions(['geolocation']);
};
```

- `context.grantPermissions([])` is carried over as "denies all permission prompts" (unverified: in the Playwright API this call grants the listed permissions, and an empty list grants none; whether it suppresses a prompt that would otherwise appear has not been checked).
- `context.grantPermissions(['geolocation'])` grants the named permission.

## Cookie banners and overlays

- A consent banner is visible in a `browser_snapshot` and can be dismissed with `browser_click`.
- An overlay that blocks interaction can be removed from the DOM:

  ```javascript
  async (page) => {
    await page.evaluate(() => {
      document
        .querySelectorAll(
          '[class*="cookie"], [class*="consent"], [class*="modal-overlay"]',
        )
        .forEach((el) => el.remove());
    });
  };
  ```

- The source attributes this snippet to `browser_evaluate`. Its `async (page) => ...` form is the one `browser_run_code` takes; `browser_evaluate` takes a function evaluated inside the page (unverified which tool accepts the snippet as written).

## Dialogs

- `browser_handle_dialog` accepts or dismisses a JavaScript dialog when `alert()`, `confirm()` or `prompt()` fires.
- A handler set up after the triggering action is too late; the dialog has already stalled the flow.

## Authenticated pages

- `browser_run_code` can set cookies or local storage on the context before navigation, which makes a page load in a signed-in state without the sign-in form.
- A session stored client-side (for example a Supabase auth session token) can be injected this way.

## Signs of a stalled session and what resets it

| Observation | Meaning |
| --- | --- |
| Snapshot shows a dialog or permission prompt | The page is blocked until it is handled |
| Errors in `browser_console_messages` | The page failed in script, not in the automation |
| Page unresponsive after the above are clear | `browser_navigate` to the same URL reloads and resets state |
| Still unresponsive after reload | Closing the page and opening a new one starts clean |

## Evidence the tools produce

- Snapshots record page structure and interaction state; screenshots record the visual result. Together they make a run reproducible and leave an audit trail that manual clicking does not.

## Viewport sizes used for responsive checks

| Width | Represents |
| --- | --- |
| 375px | iPhone SE, the smallest common mobile viewport |
| 768px | iPad portrait, tablet breakpoint |
| 1024px | Laptop, the `lg` breakpoint in Tailwind |
| 1280px | Desktop; the width the team checks by default |
| 1920px | Large desktop |

`browser_resize` or the browser's developer tools set these widths.

## Selector and timing behaviour

- `data-testid` attributes give stable selectors.
- Waiting for an element is reliable; a fixed delay is not.
- A screenshot can be taken when a test fails.
