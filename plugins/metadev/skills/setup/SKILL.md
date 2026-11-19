---
name: setup
description: Check what the metadev team depends on outside this plugin - command-line tools, browser tools and companion plugins - say what the team loses without each one, and offer to install what is missing. Use when the plugin has just been installed, when asked what metadev needs or depends on, when an agent reported that it could not test in a browser, or before the first mandate in a session.
argument-hint: "[optional: 'check' to report only]"
---

# Setup

The plugin works on its own, but parts of it are weaker without tools it does not ship. This skill reports what is present and installs what the owner picks. With `check` it reports and stops.

Arguments: $ARGUMENTS

## 1. Check

Run the check script and read every line. Each line is `status`, `level`, `name`, what it is for, and the install command.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-deps.sh"
```

Then look at the tools this session has. The script sees which plugins are installed; only you can see what is loaded.

- **Browser tools**: any tool that drives a browser (navigate, click, screenshot). They can come from the `playwright` plugin or from a browser server the owner configured another way. If the session has them, browser tools are present whatever the script says.
- A plugin the script reports as `ok` whose tools or skills are not in this session was installed after the session started. It needs `/reload-plugins` or a new session.

## 2. Report

One table, most important first. For each dependency: present or not, and what the team does without it.

| Dependency | Level | Without it |
| --- | --- | --- |
| `git` | Required | Nothing runs; every mandate works on a branch |
| `jq` or `python3` | Required | The commit guard refuses every git command |
| Browser tools (`playwright` plugin; needs Node) | Recommended | Teresa tests with HTTP requests only: no layout, keyboard or console checks, and no screenshots, so Vera reviews a build from its code alone. The production smoke test is requests only |
| `gh` | Recommended | The owner opens the pull request by hand |
| Node and `npx` | Recommended | No browser tools, and the platform command-line tools the foundations describe cannot start |
| `frontend-design` plugin | Optional | Vera and Rafa work from the `interface-design` technique alone |
| `pr-review-toolkit` plugin | Optional | Pre-merge review uses the `code-review-gate` skill alone |
| `context7` plugin | Optional | Builders rely on the dated foundations and on web search for library behaviour |

Say plainly when everything required and recommended is present, and stop there.

## 3. Offer to install

Skip this step with `check`. Otherwise ask the owner which of the missing ones to install, recommended ones first, in one question. Install nothing the owner did not pick.

- **Plugins**: run the command the script printed (`claude plugin install <name>@claude-plugins-official`, or `claude plugin enable ...` for a disabled one). They install for the owner's user account, so every project gets them.
- **Command-line tools**: the script prints a command for the system's package manager. If it needs `sudo`, do not run it; give the owner the command to run.
- The `playwright` plugin downloads a browser the first time a browser tool is used. That first call is slow.

## 4. Confirm

Run the check script again and show what changed. Tell the owner that newly installed plugins load after `/reload-plugins` or in a new session, and that the first mandate after that will have them.

## Limits

- The script knows the plugins by the names they have in the `claude-plugins-official` marketplace. A browser server set up another way is found only by looking at the session's tools.
- Teresa, the builders and the orchestrator receive whatever browser tools the session has. Marco has a fixed tool list that names the browser tools of the `playwright` plugin, or of a server the owner added under the name `playwright`; a browser server under any other name does not reach him. Paula, Alex, Vera and Sasha do not receive browser tools.
