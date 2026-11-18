# Foundation: Playwright browser automation

- **Last validated:** 2026-11-18, checked against the Playwright MCP server repository (README and release notes of `microsoft/playwright-mcp`), the server's tool source in `microsoft/playwright`, and the Playwright API documentation by an automated documentation check. Not yet confirmed in a live project.
- **Versions checked:** `@playwright/mcp` 0.0.85 (released 2026-11-09), `playwright` 1.65.1. The server was not run; tool names come from its generated README and source.
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** the Playwright MCP server as used from a Claude Code session: tool names, non-interactive behaviour, permission prompts, overlays, dialogs, signs of a stalled session, viewport sizes used for responsive checks
- **Does not cover:** the Playwright test runner (`@playwright/test`) configuration, CI setup, other browser tools (Chrome DevTools, Claude in Chrome), how a specific project's preview deployments or auth are reached

## Tools exposed by the Playwright MCP server

Tools available by default (the "core" set) in `@playwright/mcp` 0.0.85:

| Tool | What it does |
| --- | --- |
| `browser_navigate` | Loads a URL. Navigating to the current URL loads the page again and resets its state. |
| `browser_snapshot` | Returns the accessibility snapshot of the page, with element references (refs). Refs from the snapshot are what the interaction tools take as targets. |
| `browser_click` | Clicks an element. The element is passed in the `target` parameter: a ref from the snapshot, a unique selector, or (from 0.0.84) a Playwright locator expression. |
| `browser_type` | Types text into an editable element identified by `target`. |
| `browser_select_option` | Selects one or more values in a dropdown identified by `target`. |
| `browser_take_screenshot` | Captures an image of the viewport, the full page (`fullPage`) or one element. |
| `browser_resize` | Resizes the browser window to a given `width` and `height` (both required). |
| `browser_handle_dialog` | Accepts or dismisses an open `alert()`, `confirm()` or `prompt()` dialog (`accept: true` or `false`, optional `promptText`). |
| `browser_console_messages` | Returns the page's console output since the last navigation. The `level` parameter defaults to `info`; each level includes the more severe ones, so errors are included. |
| `browser_evaluate` | Runs JavaScript in the page. Takes a `function` of the form `() => { ... }`, or `(element) => { ... }` when a `target` is given. |
| `browser_run_code_unsafe` | Runs a Playwright code snippet of the form `async (page) => { ... }` that receives the `page` object, giving access to the browser context (permissions, cookies). It executes in the server process, not in the page. Named `browser_run_code` before 0.0.72 (2026-04-30). |
| `browser_wait_for` | Waits for text to appear, for text to disappear, or for a number of seconds (at most 30). |
| `browser_tabs` | Lists, creates, closes or selects a tab (`action`). |
| `browser_close` | Closes the browser and all open tabs. |

- Other tool groups are off by default and are enabled with the server's `--caps` option, for example `--caps=storage` (cookies, local storage, session storage, storage state), `--caps=network`, `--caps=vision`, `--caps=pdf`, `--caps=devtools`, `--caps=testing`.
- Tool names change between releases: `browser_run_code` was renamed in 0.0.72, and the element parameter of the interaction tools is `target` in 0.0.85.

## Non-interactive behaviour

- The server launches a headed browser by default and a headless one with `--headless`. In a Claude Code session nobody is present to answer a prompt in the browser window in either mode.
- Three things can appear that the interaction tools do not dismiss automatically: JavaScript dialogs, cookie consent banners, and browser permission prompts (notifications, location, camera) (unverified for permission prompts: the Playwright documentation does not say whether a Playwright-launched browser shows a prompt or silently denies a permission that has not been granted).
- HTTP authentication dialogs are carried over as a fourth case (unverified: not described in the server's documentation).
- An open JavaScript dialog blocks the session: every tool that works on the tab, including `browser_snapshot` and `browser_click`, returns the error `Tool "<name>" does not handle the modal state` until `browser_handle_dialog` is called.
- A banner or overlay that covers an element makes a click on that element fail when the action timeout expires (5000 ms by default, `--timeout-action`), because Playwright waits for the element to be the one that receives the click.
- These failures look like defects in the application but are not.

## Permissions

The browser context holds permission grants. A snippet for `browser_run_code_unsafe`:

```javascript
async (page) => {
  await page.context().grantPermissions(['geolocation']);
};
```

- `context.grantPermissions(permissions)` grants the listed permissions to the context, or to one origin when the `origin` option is given. `context.grantPermissions(['geolocation'])` grants the named permission.
- `context.grantPermissions([])` grants nothing. It is not a "deny all" call, and the `BrowserContext` API has no method that denies a permission.
- `context.clearPermissions()` clears all permission overrides for the context.
- The server option `--grant-permissions <permissions...>` grants permissions to the context at start-up, for example `--grant-permissions geolocation`.
- Whether a permission that has not been granted produces a visible prompt or is denied without one is unverified (not stated in the Playwright documentation; not run).

## Cookie banners and overlays

- A consent banner is part of the page, so it is visible in a `browser_snapshot` and can be dismissed with `browser_click`.
- An overlay that blocks interaction can be removed from the DOM. With `browser_evaluate`, which takes a function evaluated inside the page:

  ```javascript
  () => {
    document
      .querySelectorAll(
        '[class*="cookie"], [class*="consent"], [class*="modal-overlay"]',
      )
      .forEach((el) => el.remove());
  }
  ```

- The same removal wrapped as `async (page) => { await page.evaluate(() => { ... }); }` is the form `browser_run_code_unsafe` takes. `browser_evaluate` does not receive a `page` object, so that wrapped form does not work there.

## Dialogs

- The server listens for dialogs itself. When `alert()`, `confirm()` or `prompt()` fires, the dialog stays open, the response of the tool that triggered it contains a "Modal state" section describing the dialog, and other tab tools are refused until it is handled.
- `browser_handle_dialog` is called after the dialog has opened. Called when no dialog is open, it returns an error. Nothing is registered in advance through the MCP server.
- From 0.0.83, `browser_navigate` reports a dialog opened during page load instead of timing out.
- Registering a handler before the triggering action applies to Playwright library and test-runner code, not to the MCP tools: there, dialogs are dismissed automatically unless a `page.on('dialog')` listener was registered before the action, and a registered listener that neither accepts nor dismisses the dialog stalls the action.

## Authenticated pages

A signed-in state can be supplied without going through the sign-in form in these ways:

- **Persistent profile (the default).** The server keeps a browser profile on disk per workspace, so a sign-in done once is still there in later sessions. `--user-data-dir` points to a specific profile; `--isolated` keeps the profile in memory only.
- **Storage state file at start-up.** `--isolated --storage-state=<path>` loads cookies and local storage from a Playwright storage state file into the context.
- **Storage tools, with `--caps=storage`.** `browser_cookie_set` sets a cookie, `browser_localstorage_set` sets a local storage item, `browser_set_storage_state` restores cookies and local storage from a file (clearing the existing ones first), and `browser_storage_state` saves the current state to a file.
- **`browser_run_code_unsafe`.** `page.context().addCookies([...])` adds cookies to the context before navigation. Local storage belongs to an origin, not to the context: it is written with `page.evaluate` once a page of that origin is loaded, or with `page.context().addInitScript(...)`, which runs before the page's own scripts.
- A session stored client-side (for example a Supabase auth session token in local storage or a cookie) can be injected in any of these ways.

## Signs of a stalled session and what resets it

| Observation | Meaning |
| --- | --- |
| A tool response has a "Modal state" section, or a tool returns `does not handle the modal state` | A JavaScript dialog (or file chooser) is open; the page is blocked until `browser_handle_dialog` (or `browser_file_upload`) handles it |
| A click times out although the element is in the snapshot | Something covers the element; a snapshot or screenshot shows the banner or overlay |
| Errors in `browser_console_messages` | The page failed in script, not in the automation |
| Page unresponsive after the above are clear | `browser_navigate` to the same URL loads the page again and resets state |
| Still unresponsive after reload | `browser_tabs` with `action: "close"` then `action: "new"` starts a clean tab; `browser_close` closes the whole browser and all its tabs |

- A browser permission prompt is browser interface, not page content. Whether it appears in a `browser_snapshot` is unverified (not stated in the server's documentation; a snapshot is the page's accessibility tree).

## Evidence the tools produce

- Snapshots record page structure and interaction state; screenshots record the visual result. Together they make a run reproducible and leave an audit trail that manual clicking does not.

## Viewport sizes used for responsive checks

This table is a team convention, not a property of the tool.

| Width | Represents |
| --- | --- |
| 375px | iPhone SE, the smallest common mobile viewport |
| 768px | iPad portrait, tablet breakpoint |
| 1024px | Laptop, the `lg` breakpoint in Tailwind |
| 1280px | Desktop; the width the team checks by default |
| 1920px | Large desktop |

`browser_resize` or the browser's developer tools set these widths. `browser_resize` needs a height as well as a width.

## Selector and timing behaviour

- `data-testid` attributes give stable selectors. `data-testid` is the server's default test id attribute (`--test-id-attribute`).
- Waiting for an element is reliable; a fixed delay is not. The Playwright documentation marks `page.waitForTimeout()` as discouraged because tests that wait for time are flaky.
- A screenshot can be taken when a test fails: in the Playwright test runner, `screenshot: 'only-on-failure'` does this automatically. The MCP server takes a screenshot only when `browser_take_screenshot` is called.

## Validation notes (2026-11-18)

- Sources:
  - https://github.com/microsoft/playwright-mcp (README at `main`: options, user profile, initial state, generated tool list)
  - https://github.com/microsoft/playwright-mcp/releases (v0.0.47 to v0.0.85)
  - https://github.com/microsoft/playwright/tree/main/packages/playwright-core/src/tools/backend (`dialogs.ts`, `tool.ts`, `tab.ts`, `runCode.ts`, `evaluate.ts`, `navigate.ts`, `snapshot.ts`, `response.ts`)
  - https://playwright.dev/docs/api/class-browsercontext
  - https://playwright.dev/docs/dialogs
  - https://playwright.dev/docs/emulation
  - https://playwright.dev/docs/actionability
  - Playwright docs sources for `TestOptions.screenshot` and `Page.waitForTimeout` (`docs/src/test-api/class-testoptions.md`, `docs/src/api/class-page.md` in `microsoft/playwright`)
  - https://tailwindcss.com/docs/responsive-design (the `lg` breakpoint is 64rem, 1024px)
  - `npm view @playwright/mcp version`, `npm view playwright version`
- Corrected:
  - `browser_run_code` -> `browser_run_code_unsafe` (renamed in 0.0.72, 2026-04-30), everywhere in the file.
  - "Tool names and availability depend on the installed version (unverified)" -> confirmed, with the core set and the `--caps` groups stated.
  - `browser_click` / `browser_type` "an element identified by a ref" -> identified by the `target` parameter (ref, selector or locator).
  - "The Playwright MCP server ... runs non-interactively" -> the browser is headed by default and headless with `--headless`; nobody answers prompts in either mode.
  - "authentication dialogs" as an undismissed case -> kept as unverified; JavaScript dialogs named as the verified case.
  - "A snapshot taken during a stall may show the dialog or permission prompt" -> a JavaScript dialog is reported as "Modal state" in tool responses and blocks `browser_snapshot` itself; a permission prompt in a snapshot is unverified.
  - `context.grantPermissions([])` "deny all" -> removed from the snippet; an empty list grants nothing and the API has no deny call. `--grant-permissions` and `clearPermissions()` stated.
  - Overlay-removal snippet attributed to `browser_evaluate` in `async (page) => ...` form -> rewritten as `() => { ... }` for `browser_evaluate`; the `async (page)` form belongs to `browser_run_code_unsafe`.
  - "A handler set up after the triggering action is too late" -> true only for Playwright library code; through the MCP server `browser_handle_dialog` is called after the dialog opens.
  - "`browser_run_code` can set cookies or local storage on the context before navigation" -> cookies yes (`addCookies`); local storage is per origin; the persistent profile, `--storage-state` and the `--caps=storage` tools added as the documented ways.
  - "Closing the page and opening a new one" -> named the tools (`browser_tabs`, `browser_close`).
  - Viewport table -> labelled as a team convention; widths unchanged.
- Still unverified:
  - Whether a permission that was not granted shows a prompt or is denied silently in a Playwright-launched browser, and whether such a prompt appears in a snapshot: the Playwright documentation is silent, and no browser was run.
  - HTTP authentication dialogs stalling a session: not described in the server's documentation.
  - The tool list was read from the generated README and source at `main`, not from a running 0.0.85 server (running the package was not permitted in this check).
