---
name: retro
description: Write the retrospective for a completed mandate from its four other documents, and put every action into the backlog. Use when asked for a retro or retrospective, and at the end of every mandate.
argument-hint: "[mandate name]"
---

# Retrospective Facilitator

Facilitate a structured retrospective for the specified mandate.

## Instructions

1. The mandate name is: $ARGUMENTS (if empty, list available mandates from `docs/mandates/` and ask which one).
2. Find the mandate folder in `docs/mandates/`.
3. Read ALL mandate docs to build context:
   - `requirements.md` — what was asked for
   - `design.md` — how it was designed
   - `delivery.md` — what was delivered
   - `qa-report.md` — quality results
4. Read the existing `retrospective.md` template in the mandate folder.

## Retrospective Process

Delegate the writing to the `metadev:paula` agent when it is available (give her the mandate folder and the backlog path); otherwise do it yourself. The retrospective covers:

1. **Summary:** One paragraph on how the mandate went overall.
2. **What Worked Well:** Identify 3-5 things the team did right.
3. **What Didn't Work:** Identify problems with specific "what we'll do differently" actions.
4. **What We Learned:** New knowledge or insights from this mandate.
5. **Action Items:** Concrete changes with owner and target destination.
6. **Knowledge Updates:** Sort each lesson. True in any project: name the technique skill in the metadev plugin whose steps or anti-patterns should change (applied in the plugin's repo on a `knowledge/` branch). A fact about this project: name the file in `knowledge/foundations/` it belongs in. Read `.claude/agent-memory/*/MEMORY.md` and list the notes that should be promoted once the owner confirms them.
7. **Team Dynamics:** How communication, handoffs, and feedback worked.
8. **Metrics:** Fill in time-to-delivery, checkpoint pass rates, bug counts.

## Critical Step: Backlog Integration

After writing the retrospective, for EVERY action item identified:

1. Open the project's `docs/backlog.md` for product items, or the team's own backlog for team-process items
2. Add the item to the appropriate category with priority, effort, owner, and date
3. This is non-negotiable — if it's not tracked, it doesn't exist

## Promotion

Ask the owner to confirm the project facts listed under Knowledge Updates. For each confirmed one, add it to the named foundation and update that file's "Last validated" date and validator. Do not promote unconfirmed notes.

## Output

Write the completed retrospective.md and report: number of action items identified, number added to backlog, and key learnings.
