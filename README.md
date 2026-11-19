# metadev

A product and engineering team as a Claude Code plugin, for someone building products mostly alone: nine role agents, a delivery process with human approval only where the work is novel or risky, a build-review-QA workflow, and knowledge organised as techniques and dated foundations.

## Install

```bash
claude plugin marketplace add hhpmacedo/metadev
claude plugin install metadev@metadev
```

Then, from any project repo:

```
/metadev:setup
/metadev:mandate <what you want built>
/metadev:knowledge-audit
```

`/metadev:setup` checks what the plugin depends on (command-line tools, browser tools, companion plugins) and offers to install what is missing. The full list is under "Dependencies" in the plugin README.

## Documentation

- [plugins/metadev/README.md](plugins/metadev/README.md) - what is in the plugin and how a mandate runs
- [plugins/metadev/skills/team-standards/SKILL.md](plugins/metadev/skills/team-standards/SKILL.md) - how the team works
- [plugins/metadev/skills/mandate/SKILL.md](plugins/metadev/skills/mandate/SKILL.md) - the delivery process

## Status

Version 2.4.0. The tool foundations under `plugins/metadev/skills/foundations/references/` were checked on 2026-11-18 against each tool's documentation and command help by an automated check; each file lists the versions and sources it was checked against and what remains unverified. None has yet been confirmed in a live project. The `deliver` workflow has not yet been exercised on a full mandate.

The knowledge structure follows [Knowledge-as-Code](https://github.com/hhpmacedo/kac-framework).

## Licence

MIT. See [LICENSE](LICENSE).
