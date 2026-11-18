# Orchestration reference

How the orchestrator briefs, sequences and checks the team. Read when running a mandate by hand or when a hand-off goes wrong.

## Briefing an agent

Each agent already has its role contract, the team standards and its knowledge skill loaded. The brief supplies only what it cannot know:

1. **The task**, in a sentence or two. For Paula, the owner's words verbatim.
2. **Where**: the mandate folder path and the branch. Agents work in the current project repo.
3. **What to read** beyond the mandate files, if you know of specific code or docs.
4. **Boundaries**: the workstream and paths it owns, and what other agents are touching.
5. **Approvals already given**, stated explicitly (for Marco: whether production changes are approved).

Do not paste conversation history or summarise an upstream document. Point at the file; a summary loses the detail the next role needs.

Example, builder:

```
Mandate folder: docs/mandates/2026-11-20-export-csv. Branch: mandate/export-csv.
Your workstream (design.md, "Workstreams"): the export API route and its tests.
You own app/api/export/ and lib/export/. Rafa is working in components/export/ - do not edit it.
```

Example, Teresa:

```
Mandate folder: docs/mandates/2026-11-20-export-csv.
Test target: https://preview-url.example (or: run `npm run dev`, then http://localhost:3000).
Test the build against requirements.md and write qa-report.md.
```

## Continue an agent, or start a new one?

- **Continue the same agent** (send it a message) when the follow-up depends on what it already knows: Alex revising his design after review, a builder fixing bugs in code it just wrote, Teresa re-verifying her own findings. It keeps its context, so the fix round is cheap and accurate.
- **Start a new agent** when you want independence: reviewing someone else's work, a second opinion, or a new workstream. A reviewer who shares the author's context shares the author's blind spots.

## Sequence and parallelism

Default to one agent at a time. Run agents together only in these cases:

| Together | Condition |
| --- | --- |
| Teresa (test plan) with Alex finishing design | Both read requirements; they write different sections |
| Two builders | Alex marked the workstreams parallel-safe: no shared files, and the contract between them is fixed in `design.md` |
| Independent reviewers on one diff | Always safe; they only read |
| Teresa (final QA) with Marco (deploy preparation on preview) | Marco does not touch production until QA passes |

Never together: anything with Paula's requirements (they gate everything), and a builder with Teresa testing that builder's unfinished code.

If two builders must touch the same files, run them in sequence in the order Alex gave. Parallel builders in separate git worktrees are possible, but the merge then becomes your job; it is rarely worth it at this team's scale.

## Checks after each phase

**Requirements**: file exists; success criteria are testable; scope classification present; QA requirement stated.

**Design**: file exists; implementation plan is ordered; workstreams name an owner and paths; decisions carry reasons; external dependencies were verified; `design-review` passed.

**Build**: project builds; work is on the mandate branch; `delivery.md` updated; no files changed outside the workstream.

**QA**: `qa-report.md` exists; verdict is explicit; no open Critical or High issue (or the owner accepted it); delivery risk classification present.

**Deployment**: public production URL returns 200; primary flow works in production; variables and migrations confirmed; state and rollback recorded in `delivery.md`.

## What goes wrong

| Mistake | What happens | Instead |
| --- | --- | --- |
| Summarising one agent's output for the next | Detail is lost and the next role builds on the summary | Have the next agent read the file |
| Starting parallel builders without path boundaries | Conflicting edits, duplicated work | Alex assigns paths first |
| Accepting "done" without checking | A missing piece surfaces two phases later | Run the checks above every time |
| Asking the author's agent to review its own work | It confirms itself | Use a fresh agent or a different role |
| Giving a reviewer your conclusion | It returns your conclusion | Give it the diff and the requirement, not your opinion |
| Letting a fix loop run without a limit | Cost with no convergence | Two rounds, then take the open issues to the owner |
| Spawning agents for a one-line edit or a doc change | Overhead with no gain | Do it yourself |
