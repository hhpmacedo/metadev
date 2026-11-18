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
| Process skills | `mandate` (the delivery process, `/metadev:mandate <what you want built>`), `retro`, `knowledge-audit`. |
| Gate skills | `design-review`, `document-review`, `code-review-gate`, `qa-council`, `deploy-verify`. |
| Technique skills | One per situation, each with the same five sections (required foundations, required context, approach, done means, anti-patterns). Product and design: `requirements-framing`, `ai-feature-design`, `interface-design`. Architecture: `solution-design`, `technology-selection`, `agentic-feature-design`. Build: `code-implementation`, `project-setup`, `api-endpoint`, `schema-migration`, `caching`, `backend-integration-testing`, `component-build`, `ui-data-fetching`, `model-output-rendering`, `frontend-performance`, `pdf-generation`, `production-debugging`. QA: `test-planning`, `build-testing`, `bug-reporting`, `ai-feature-testing`, `test-automation`. Operations: `release-deployment`, `deployment-rollback`, `environment-audit`, `ci-pipeline`, `production-monitoring`. |
| `skills/foundations` | Dated facts about the tools the team uses. The index is preloaded into every agent; the file for a tool is read when a task depends on it. |
| `skills/team-standards` | Shared rules, preloaded into every agent. |
| `workflows/deliver.js` | Checkpoint 3 as a deterministic script: build each workstream, independent review with confirmation of each finding, QA, fix loop with a round limit. |
| `hooks/` | A commit guard that blocks `git commit` when staged changes include `.env` files or secret-shaped strings. It accepts only a strict form of `git commit` run on its own from the repository directory (`-m 'message'` or a quoted heredoc), and refuses anything combined with staging, `cd`, `git -C`, pathspecs or shell substitution. It is a backstop: it does not see git aliases or commits made outside Claude Code. |

## Three kinds of knowledge

The plugin follows the Knowledge-as-Code separation.

| Kind | What it is | Where it lives |
| --- | --- | --- |
| Technique | How to approach a kind of situation; true in any project | This plugin |
| Foundation | A dated claim about reality | Tools and platforms: this plugin. Your product, users, brand, infrastructure and data: `knowledge/foundations/` in your project repo |
| Context | This task, this moment | The brief and the mandate folder |

Nothing about your products is stored in the plugin. The roles that depend on product knowledge (requirements, design direction, production changes, security) stop and ask when a required project foundation is missing instead of filling the gap from general knowledge. Run `/metadev:knowledge-audit` in a project to see which foundations exist, which are missing and which are past their review date.

The tool foundations shipped here were carried over from older material and are marked as not re-validated; each file says so.

## How a mandate runs

1. **Requirements** - Paula. The owner approves only if she classifies it Novel.
2. **Design** - Vera (if there is an interface), Alex, Teresa's test plan, then the design-review gate. The owner is informed.
3. **Build, review, QA** - the `deliver` workflow. The owner accepts only if delivery is high-risk or QA failed.
4. **Deploy** - Marco, with explicit approval for production changes. Sasha first for auth, payments or personal data.
5. **Retrospective** - Paula. Actions go to the backlog; confirmed project facts are promoted into project foundations, and general lessons come back to this plugin's techniques.

Mandate documents live in the product repo at `docs/mandates/YYYY-MM-DD-<name>/`.

## Where things are remembered

- What an agent notices about a project: its agent memory, `.claude/agent-memory/metadev-<agent>/` in the product repo. These are unvalidated notes.
- What the owner has confirmed about a project: `knowledge/foundations/` in the product repo.
- Lessons that hold in any project: a step or an anti-pattern in the matching technique skill here.

## Works well with

Optional, not required: the `frontend-design` plugin (Vera, Rafa), `pr-review-toolkit` (pre-merge), a browser automation plugin or MCP server (Teresa, Marco), `context7` (current library docs).

## Licence

MIT.
