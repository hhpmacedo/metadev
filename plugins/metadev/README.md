# metadev

A product and engineering team as a Claude Code plugin, for someone building products mostly alone. Install it once and the team is available in every project repo.

## Install

```bash
claude plugin marketplace add hhpmacedo/metadev
claude plugin install metadev@metadev
```

To try it without installing, clone the repo and run `claude --plugin-dir <clone>/plugins/metadev`. After editing plugin files, run `/reload-plugins` in an open session.

## What is in it

| Part | Contents |
| --- | --- |
| `agents/` | Nine roles: `paula` (PM), `alex` (architect), `vera` (design), `diego` / `leo` / `rafa` (builders), `teresa` (QA), `marco` (DevOps), `sasha` (security). Invoked as `metadev:<name>`. Each is a short contract: what it owns, which foundations and context it requires, what done means, what to return. |
| Process skills | `mandate` (the delivery process, `/metadev:mandate <what you want built>`), `retro`, `knowledge-audit`, `setup` (checks and installs what the plugin depends on). |
| Gate skills | `design-review`, `document-review`, `code-review-gate`, `qa-council`, `deploy-verify`. |
| Technique skills | One per situation, each with the same five sections (required foundations, required context, approach, done means, anti-patterns). Product and design: `requirements-framing`, `ai-feature-design`, `interface-design`. Architecture: `solution-design`, `technology-selection`, `agentic-feature-design`. Build: `code-implementation`, `project-setup`, `api-endpoint`, `schema-migration`, `caching`, `backend-integration-testing`, `component-build`, `ui-data-fetching`, `model-output-rendering`, `frontend-performance`, `pdf-generation`, `production-debugging`. QA: `test-planning`, `build-testing`, `bug-reporting`, `ai-feature-testing`, `test-automation`. Operations: `release-deployment`, `deployment-rollback`, `environment-audit`, `ci-pipeline`, `production-monitoring`. |
| `skills/foundations` | Dated facts about the tools the team uses. The index is preloaded into every agent; the file for a tool is read when a task depends on it. |
| `skills/team-standards` | Shared rules, preloaded into every agent. |
| `workflows/deliver.js` | Checkpoint 3 as a deterministic script: build each workstream, independent review with confirmation of each finding (joined by Sasha when asked), QA, Vera's review of the build against the design spec when asked, fix loop with a round limit. |
| `hooks/` | A commit guard in two layers, described under "Commit guard" below. |
| `scripts/check-deps.sh` | Reports which dependencies are present. Used by `setup` and at the start of a mandate. |

## Commit guard

The guard stops an agent from committing or pushing `.env` files and secret-shaped strings (private keys, and common API key and token formats). It has two layers.

1. **Before a commit.** Only a plain `git commit` run on its own from the repository directory is accepted, with `-m 'message'` or a quoted heredoc. The files it would take are scanned whole. Anything combined with staging, `cd`, `git -C`, pathspecs or shell substitution is refused, because the guard could not know what would be committed.
2. **After every shell command.** The guard compares the repository's branches with how they were before the command. Any new local commit, however it was made (an alias, a wrapper, a variable, another branch), has its changed files scanned. If one contains an environment file or a secret-shaped string, the agent is told to undo it, and any command that mentions a push is refused in that repository until the commit is gone.

Commits that arrive from a remote are not flagged; they are already published.

**Clearing a false positive.** The block is one file per repository under `~/.local/state/metadev-guard/` (or `$XDG_STATE_HOME/metadev-guard/`), named `flag.<number>`, listing the flagged commits. If a flagged commit is a deliberate fixture, the owner deletes that file. The guard does not tell agents this.

**A commit that was pushed in the same command.** If a commit is made and pushed within one command in a way layer 1 does not recognise, it cannot be stopped. Layer 2 still scans it and reports it as already on a remote, so that the secret gets rotated. Only commits made under your own git email are reported this way; other people's commits that you fetch are ignored.

**Limits.** It needs `jq` or `python3` to read the command; with neither, it refuses git commands and says so. It only sees commands run through Claude Code's shell tool, and only the repository the command started in: a command that changes directory into another repository and commits there is not checked. The push block works by refusing commands that mention a push, so a push spelled through a git alias is not blocked. Files over 50 MB and anything beyond the newest 500 commits from one command are not scanned; the guard says so when that happens. A real `pre-push` hook in the repository, or secret scanning on the remote, is still worth having.

## Three kinds of knowledge

The plugin follows the Knowledge-as-Code separation.

| Kind | What it is | Where it lives |
| --- | --- | --- |
| Technique | How to approach a kind of situation; true in any project | This plugin |
| Foundation | A dated claim about reality | Tools and platforms: this plugin. Your product, users, brand, infrastructure and data: `knowledge/foundations/` in your project repo |
| Context | This task, this moment | The brief and the mandate folder |

Nothing about your products is stored in the plugin. The roles that depend on product knowledge (requirements, design direction, production changes, security) stop and ask when a required project foundation is missing instead of filling the gap from general knowledge. Run `/metadev:knowledge-audit` in a project to see which foundations exist, which are missing and which are past their review date.

The tool foundations shipped here were checked against each tool's documentation and command help on 2026-11-18. Each file names the versions it was checked against, lists its sources, and marks what is still unverified. They have not been confirmed in a live project, and they go out of date: run `/metadev:knowledge-audit plugin` to see which are due for review.

## How a mandate runs

1. **Requirements** - Paula. The owner approves only if she classifies it Novel.
2. **Design** - Vera (if there is an interface), Alex, Sasha on the design (for auth, payments, personal data, or untrusted content reaching a model with tools), Teresa's test plan, then the design-review gate. The owner is informed.
3. **Build, review, QA** - the `deliver` workflow. Sasha reviews the diff when the mandate is security-relevant; Vera compares the build with her design spec when there is one. The owner accepts only if delivery is high-risk or QA failed.
4. **Deploy** - Marco, with explicit approval for production changes.
5. **Retrospective** - Paula. Actions go to the backlog; confirmed project facts are promoted into project foundations, and general lessons come back to this plugin's techniques.

Mandate documents live in the product repo at `docs/mandates/YYYY-MM-DD-<name>/`.

## Where things are remembered

- What an agent notices about a project: its agent memory, `.claude/agent-memory/metadev-<agent>/` in the product repo. These are unvalidated notes.
- What the owner has confirmed about a project: `knowledge/foundations/` in the product repo.
- Lessons that hold in any project: a step or an anti-pattern in the matching technique skill here.

## Dependencies

The plugin runs on its own, but it is weaker without some things it does not ship. `/metadev:setup` checks all of them, says what the team loses without each, and offers to install the missing ones. `/metadev:setup check` only reports. Starting a mandate runs the same check and warns before any work if an interface mandate has no browser tools.

| Dependency | Level | What it is for | Install |
| --- | --- | --- | --- |
| `git` | Required | Every mandate works on a branch | System package manager |
| `jq` or `python3` | Required | The commit guard reads each shell command with one of them; with neither it refuses git commands | System package manager |
| Browser tools | Recommended | Teresa's testing in a real browser (layout at three widths, keyboard, console errors), the screenshots Vera's design review reads, the production smoke test. Without them QA falls back to HTTP requests and says what it could not cover | `claude plugin install playwright@claude-plugins-official` (needs Node) |
| `gh` | Recommended | Opening the pull request that ends a mandate | System package manager |
| Node and `npx` | Recommended | The browser tools, and the platform command-line tools the foundations describe, all start through `npx` | nodejs.org |
| `frontend-design` plugin | Optional | Design direction for Vera and Rafa | `claude plugin install frontend-design@claude-plugins-official` |
| `pr-review-toolkit` plugin | Optional | Extra review agents before a merge | `claude plugin install pr-review-toolkit@claude-plugins-official` |
| `context7` plugin | Optional | Current library documentation while building | `claude plugin install context7@claude-plugins-official` |

The `deliver` workflow needs a Claude Code version with the Workflow tool; without it, the `mandate` skill runs the same steps by hand.

The tool foundations describe one stack (Supabase, Vercel, Next.js, shadcn/ui, react-pdf, GitHub Actions, Playwright). A project on another stack can use the roles, the process and the techniques, but has no dated facts about its tools from this plugin.

## Licence

MIT.
