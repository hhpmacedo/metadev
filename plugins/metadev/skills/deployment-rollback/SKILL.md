---
name: deployment-rollback
description: Writing a rollback plan before a change that is hard to undo, and carrying one out when production breaks - trigger condition, application revert, reverse migration, verification and who to tell. Use when a release drops or alters data, changes auth or configuration, ships to real users, or when a release has just gone wrong.
user-invocable: false
---

# Deployment Rollback

A good outcome is a rollback that was written and tested before the risky change went out, so that when it is needed it is a short list of commands with a known duration, not an improvisation under pressure.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-vercel.md` (plugin, `foundations` skill) | How long previous deployments are kept, how production is rolled back to one, and what a rollback switches off |
| `foundation-supabase-cli.md` (plugin, `foundations` skill) | That migrations have no automatic rollback; how to create, reset and push migrations |
| Project `knowledge/foundations/foundation-infrastructure.md` | Production URL, database project reference, who must be told about a production incident |

If you do not know which deployment was the last good one, or which database is production, stop and return `needs-decision`. Rolling back to the wrong deployment or pushing a reverse migration to the wrong project makes the incident worse.

## Required context

- Required: what the change does to production (migrations, auth or authorization logic, environment configuration, application code).
- Required: whether the system has real users and real data.
- Required: for a rollback in progress, the observed failure and when it started.
- Optional: the smoke test steps from the last release, to reuse as the rollback verification.

## Approach

### Planning (before the change is applied)

1. **Decide whether a plan is needed.** Write one for database migrations that drop or alter columns, changes to authentication or authorization logic, changes to environment configuration, and any deployment to a production system with real users.
2. **State the trigger.** Write the specific failure condition that means "roll back", so the decision is not argued during the incident.
3. **Record the last good deployment.** List the recent deployments and note the URL of the one currently serving production. The application side of a rollback is rolling production back to that deployment. Check that it is still within the platform's retention period and, on a plan that only allows going back one production deployment, that it is the immediately previous one.
4. **Write and test the reverse migration.** There is no automatic rollback for migrations. For each destructive migration, write the migration that undoes it and test the pair locally: reset the local database, apply forward, apply the reverse, confirm the schema is back. Keep the reverse migration ready but out of the migration chain, so it is not applied by accident.
5. **Note destructive changes.** If a migration drops a column or table, say so in the PR and in the delivery report.
6. **Write the plan down** in the delivery report or the PR:

   ```markdown
   ## Rollback Plan for <feature>

   ### Trigger
   Rollback if: <specific failure condition>

   ### Steps
   1. Revert the application to deployment <URL> (`npx vercel rollback <URL>`)
   2. Apply reverse migration: <filename> (`npx supabase db push --remote`)
   3. Verify rollback: <smoke test steps>
   4. Notify team: <who to tell, what to say>

   ### Time Estimate
   - Application rollback: < 1 minute
   - Database rollback: ~5 minutes (including verification)
   - Total: < 10 minutes
   ```

### Executing (when the trigger is met)

7. **Confirm the trigger is met**, with evidence, then follow the plan as written.
8. **Revert the application.** The hosting platform keeps previous deployments for a retention period, so this is near-instant: roll back to the last good deployment (`npx vercel rollback <URL>`). After a rollback, new pushes to the main branch no longer go live automatically; that resumes only when a deployment is promoted again, so record this in the incident notes.
9. **Then apply the reverse migration as a new migration**, added to the chain and pushed. Never edit or delete the applied forward migration; the record of what ran must stay true.
10. **Verify with the planned smoke test** on the public address, including a logged-in flow.
11. **Notify** the people named in the plan: what happened, what was rolled back, what state production is in now.
12. **Record what happened** in the delivery report.

## Done means

- Planning: the plan names a trigger, a last good deployment URL, a reverse migration file for each destructive migration, verification steps and who to notify.
- Planning: the reverse migration has been applied locally after the forward migration and the schema matched the starting state.
- Planning: destructive changes are noted in the PR and the delivery report.
- Executing: the deployment listing shows the last good deployment serving production.
- Executing: the migration status shows the reverse migration applied as a new entry, with the forward migration unedited.
- Executing: the smoke test passes on the public URL and the notification has been sent.

## Anti-patterns

- **Writing the rollback after the deployment that needs it.** By then the forward migration has run and the reverse can no longer be tested against the original state. The plan exists before the change is applied.
- **Editing an applied migration to "undo" it.** Create a new migration to fix or reverse it.
- **Leaving the reverse migration in the migration chain before it is needed.** Keep it ready, but outside the chain, until a rollback is actually executed.
- **A plan with no trigger.** Without a stated condition, the rollback is delayed while people decide whether things are bad enough.
- **Calling a rollback done without verifying it.** Run the smoke test; a rollback is a deployment too.
