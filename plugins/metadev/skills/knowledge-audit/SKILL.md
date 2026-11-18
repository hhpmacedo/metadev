---
name: knowledge-audit
description: Audit the knowledge a project's team relies on - which project foundations exist, which are missing, which are past their review date, and whether any file mixes facts with instructions. Use when asked to audit or check knowledge or foundations, before starting a mandate in a repo for the first time, or when an agent's output was generic or wrong and the cause may be stale or missing knowledge.
argument-hint: "[optional: 'plugin' to audit the plugin's own stack foundations]"
---

# Knowledge audit

This reads and reports. It changes nothing unless the owner asks for a fix afterwards.

Scope: $ARGUMENTS (default: the current project's `knowledge/foundations/`; with `plugin`, the files under `${CLAUDE_PLUGIN_ROOT}/skills/foundations/references/`).

## Checks

Use today's date from the system, not from memory.

1. **Presence.** For a project, list which of these exist: `foundation-product.md`, `foundation-audience.md`, `foundation-brand.md`, `foundation-infrastructure.md`, `foundation-data.md`, `foundation-constraints.md`. For each missing one, name the role that will stop without it (product and audience: Paula; brand: Vera; infrastructure: Marco; data: Sasha).
2. **Freshness.** Read each file's "Last validated" and "Review cadence" lines. Report as current, due (past cadence), or undated. "Not re-validated since ..." counts as due.
3. **Separation.** Flag lines in a foundation that tell the reader what to do ("always", "never", "when writing ...", numbered procedures): those belong in a technique. Flag lines that are about one task or one moment: those are context and should not be stored.
4. **Honesty.** Flag claims with no limits or weaknesses stated where there obviously are some, and aspirations written as facts.
5. **Duplication and conflict.** Flag the same fact stated in two files, and any two claims that disagree. Do not pick a winner.
6. **Code restatement.** Flag sections that describe what the code already says (schemas, route lists). Those go stale silently and should be removed.
7. **Unpromoted notes.** List what is in `.claude/agent-memory/*/MEMORY.md` that reads like a project fact and is not in any foundation.

For the infrastructure foundation only, spot-check two or three claims against reality with read-only commands (the production URL responds, the named environment variables exist). Report mismatches; do not correct them.

## Report

```
Knowledge audit: <project or "plugin">, <date>

Missing:    <file> - blocks <role>
Due:        <file> - last validated <date>, cadence <n>
Separation: <file>:<line> - <what and where it belongs>
Conflicts:  <file A> vs <file B> - <claim>
Unpromoted: <agent> - <note>
Checked against reality: <claim> - matches | differs (<what you saw>)

Next step: <the one thing most worth doing first>
```

If the project has no `knowledge/foundations/` at all, say so and offer to draft the missing ones by interviewing the owner. Draft from the owner's answers and from what can be observed, never from general knowledge about similar products, and leave "Last validated" for the owner to fill in.
