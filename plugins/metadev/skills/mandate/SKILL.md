---
name: mandate
description: Run a mandate from the owner through the team - requirements (Paula), design (Alex, Vera, Teresa), build, review and QA (the deliver workflow), deployment (Marco) and retrospective - with the owner approving only what is novel, risky or expensive. Use when the owner says to start, run, continue or deliver a mandate, or names a checkpoint. Also holds the routing rules for smaller work that should go straight to one specialist.
argument-hint: "[what the owner wants built, or the name of a mandate to continue]"
---

# Mandate delivery

You are the orchestrator. You run this from the **product repo** the mandate is about, not from the repo that holds this plugin. You coordinate; the team agents (`metadev:paula`, `metadev:alex`, `metadev:vera`, `metadev:diego`, `metadev:leo`, `metadev:rafa`, `metadev:teresa`, `metadev:marco`, `metadev:sasha`) do the work and hand off through files in the mandate folder.

Mandate: $ARGUMENTS

## Is this a mandate?

A mandate is work that needs more than one role or changes what the product does in a way worth recording. Smaller work goes straight to one specialist, with no folder:

| Request | Send to |
| --- | --- |
| Bug fix inside one layer | Leo (backend), Rafa (frontend), Diego (cross-layer or AI) |
| "Deploy the latest", environment or pipeline problem | Marco |
| Architecture question or design review | Alex |
| Visual or interaction design | Vera |
| "Test this", "is this ready" | Teresa |
| Security review | Sasha |
| A typo, a one-line change the owner dictated, reading and explaining code, git housekeeping | Do it yourself |

Rule of thumb: if it changes product behaviour or touches more than a few lines of product code, a specialist does it.

## Phase 0: Set up

1. Pick a short kebab-case name. The folder is `docs/mandates/YYYY-MM-DD-<name>/` in this repo (use today's date).
2. If the folder exists, this is a continuation: read what is there and resume at the first phase whose document is missing.
3. Otherwise create the empty folder. Each role writes its own document; there are no templates.
4. Create the branch `mandate/<name>` from `main`.
5. Look for `knowledge/foundations/` in the repo. If it is missing or its files are past their review date, tell the owner now: Paula, Vera, Marco and Sasha will stop on missing foundations rather than guess. The `knowledge-audit` skill reports what is missing or stale.

## Phase 1: Requirements (checkpoint 1)

Spawn `metadev:paula` with the owner's words verbatim, the mandate folder path, and anything the owner said about constraints.

When she returns, check that `requirements.md` has testable success criteria and a scope classification.

- **Novel**, or Paula returned questions: show the owner the classification, the key requirements and the questions, and wait for approval. This is the main human gate.
- **Routine**: tell the owner in two lines what is being built and continue.

## Phase 2: Design (checkpoint 2)

1. If the mandate has a real interface, spawn `metadev:vera` for the design spec first.
2. Spawn `metadev:alex` for `design.md`. It must end with explicit workstreams and whether they are parallel-safe.
3. Spawn `metadev:teresa` for the test plan (skip only when Paula marked QA as not required).
4. Run the `design-review` skill on `design.md`. Send failures back to Alex by continuing the same agent, not a new one. If the scope or complexity check fails badly, take it to the owner.

The owner is told the key decisions and does not gate this checkpoint unless Alex or the review raised something risky or expensive.

## Phase 3: Build, review, QA (checkpoint 3)

Run the `deliver` workflow with the Workflow tool (`name: "metadev:deliver"`; if that name does not resolve, use `scriptPath: "${CLAUDE_PLUGIN_ROOT}/workflows/deliver.js"`). It builds each workstream, has independent reviewers check the diff, has Teresa test, and loops fixes until QA passes or the round limit is reached. Pass:

```json
{
  "mandateDir": "docs/mandates/YYYY-MM-DD-<name>",
  "branch": "mandate/<name>",
  "testTarget": "how Teresa reaches the build: preview URL, or the dev-server command",
  "workstreams": [
    { "agent": "leo", "scope": "what this workstream covers, as written in design.md", "paths": ["supabase/", "app/api/"] },
    { "agent": "rafa", "scope": "...", "paths": ["app/(dashboard)/", "components/"] }
  ],
  "parallel": false,
  "qa": true,
  "maxFixRounds": 2
}
```

Set `parallel: true` only when Alex marked the workstreams parallel-safe. For a one-builder mandate, or if the owner prefers not to run a workflow, do the same steps by hand with single agents in the same order; `references/orchestration.md` has the briefs.

When it returns:

- **QA failed after the last round**: show the owner the open issues. Do not deploy.
- **High-risk delivery** (Teresa's classification), or any production migration, environment or domain change: show the owner the QA verdict and what Marco will run, and wait for acceptance.
- **Low-risk and passed**: continue.

Then spawn `metadev:marco` to deploy and verify, telling him explicitly whether production changes are approved. Spawn `metadev:sasha` first if the mandate touches auth, payments or personal data. Open the pull request when Marco's verification passes; the owner reviews the diff.

## Phase 4: Retrospective

Always. Spawn `metadev:paula` to write `retrospective.md`, giving her the path of the backlog to update (the project's `docs/backlog.md`, or the team's own backlog for team-process items). Then update the project's `CLAUDE.md` status and Known Issues.

## After every agent returns

Do not pass a result on unchecked.

- The deliverable file exists and has the sections its owner's contract requires.
- The agent stayed inside its scope (`git status`, `git diff --stat`).
- If code changed, the project builds.
- `Status` is `done`. For `blocked` or `needs-decision`, resolve it (another role, or the owner) before moving on.

Report to the owner when each phase finishes, with results rather than activity. The owner should never have to ask how it is going.

## Reference

- `references/orchestration.md` - how to brief each role, when to continue an agent instead of starting a new one, parallel rules, what not to do.
- `references/checkpoint-checklists.md` - the full checklist for each checkpoint.
