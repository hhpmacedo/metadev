# metadev

Source of the `metadev` Claude Code plugin. This repo is public. The marketplace manifest is `.claude-plugin/marketplace.json`; the plugin is `plugins/metadev/`.

## Rules for changing the plugin

- **Nothing about a specific project, client or person goes in this repo.** No product names, no personal names other than the author credit, no domains, account identifiers, network details or dated incidents. The person the team works for is "the owner". Facts about a product belong in that product's own `knowledge/foundations/`.
- **Three kinds of knowledge, kept apart.**
  - *Techniques* are skills named by situation (`schema-migration`, `test-planning`) with five sections in this order: Required foundations, Required context, Approach, Done means, Anti-patterns. Apply the swap test: every sentence must hold on a different product.
  - *Foundations* are declarative, dated facts about tools, in `plugins/metadev/skills/foundations/references/`. State limits and known problems. Change "Last validated" only for claims actually checked, and say how.
  - *Context* is never stored here.
- **Agent files are contracts**: what the role owns, which foundations and context it requires, what done means, what it returns. About 70 lines at most.
- **Preloaded skills stay short.** `team-standards` and the `foundations` index are injected in full into every agent.
- **Dependencies are named in three places only**: the "Dependencies" section of the plugin README, the `setup` skill, and `plugins/metadev/scripts/check-deps.sh`. Keep the three in step. Everywhere else, name the capability ("browser tools", "a frontend design skill") and point to the `setup` skill; do not name a plugin or tool that is not in this repo. Foundations are the exception: they are about named tools. So is the `tools` line of an agent that has to list a companion plugin's tools to receive them (Marco and the browser tools); when the plugin's name changes, change that line and the three places together.

## Checking a change

```bash
claude plugin validate .
claude plugin validate plugins/metadev
claude --plugin-dir plugins/metadev        # try it in a session without installing
```

`plugins/metadev/scripts/check-deps.sh` prints one line per dependency; run it after changing it and read the output.

The commit guard (`plugins/metadev/scripts/guard-commit.sh`, `guard-history.sh`, `guard-lib.sh`) has a test script that drives both layers the way Claude Code does. Run it after any change to those files; add a case for every bug or bypass you fix.

```bash
bash tests/guard.sh
```

The `deliver` workflow (`plugins/metadev/workflows/deliver.js`) has a test that runs it against mocked agents and checks its control flow and what it returns. Run it after any change to the workflow; add a case for every bug you fix. It does not start real agents, so it does not show how they behave.

```bash
node tests/deliver.js
```

## Releasing

Bump `version` in `plugins/metadev/.claude-plugin/plugin.json` and the version line in `README.md`, then push to `main`. Installed copies pick the change up with `claude plugin update metadev@metadev`.
