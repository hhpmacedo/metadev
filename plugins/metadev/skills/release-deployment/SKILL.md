---
name: release-deployment
description: Taking a finished change to production and proving it works there - audit the live state, compare it to what the code expects, close each gap, deploy, smoke-test a logged-in flow, and record the verified state. Use when a change is "code complete" and has to be delivered, or when a delivery report needs a deployment section.
user-invocable: false
---

# Release Deployment

A good outcome is a production environment that demonstrably matches what the code expects: every migration applied, every variable set, every external resource present, a real user flow working, and all of it written down with the commands that proved it. A passing build is not that outcome.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-vercel.md` (plugin, `foundations` skill) | Deploy and inspect commands, environment variable scopes, which URLs are publicly reachable, function time limits |
| `foundation-supabase-cli.md` (plugin, `foundations` skill) | Commands for migration status, pushing migrations, storage buckets, linking a project |
| Project `knowledge/foundations/foundation-infrastructure.md` | Production URL (the public one), database project reference, required variables, external resources, test account for smoke tests |

If the production URL, the database project reference, or the list of required variables is missing and cannot be read from the repo, stop and return `needs-decision`. Guessing which project is "production" can apply migrations to the wrong database.

## Required context

- Required: the design document or change description, so you know what infrastructure the change expects (tables, buckets, variables, third-party services).
- Required: the migration files in the change and the project's `.env.example` or equivalent variable documentation.
- Required: approval to change production. Auditing is read-only; applying migrations and setting variables is not.
- Optional: the previous delivery report, to see the last verified state.
- Optional: a rollback plan, required instead of optional when the change is hard to undo (see the `deployment-rollback` skill).

## Approach

1. **Review the design for deployment requirements before the build is finished.** List what production will need that it does not have today. Raising a missing bucket or a risky function at design review is cheap; discovering it after delivery is not.
2. **Audit the current state with the platform tooling.** Do not rely on memory or on what a previous report said.

   ```bash
   npx supabase db remote status --linked   # which migrations are applied
   npx vercel env ls production             # which variables are set
   npx supabase storage ls                  # which buckets exist
   ```

3. **Compare to the expected state.** Read the design document for expected infrastructure, the migration files for the schema that should exist, and `.env.example` for the required variables. Write the differences as a list of gaps.
4. **Write the rollback before applying anything hard to undo.** Destructive migrations, auth changes and configuration changes need it first. Use the `deployment-rollback` skill.
5. **Close each gap and record it** in this shape, so the report shows what was done and how it was confirmed:

   ```
   Gap: Migration <NNN> not applied to production
   Action: npx supabase db push
   Result: Migration <NNN> applied successfully
   Verified: Table "<name>" exists with expected columns
   ```
6. **Deploy, and confirm the deployment succeeded.** Where the hosting project deploys automatically from the main branch, the merge is the deployment; confirm the PR is ready before merging and check the deployment status afterwards rather than assuming it.
7. **Smoke-test on the public address, including a logged-in flow.** Loading the login page proves the app exists, not that it works. Log in with a test account, perform at least one core action, confirm the result appears, refresh and confirm it persisted. The read-only checklist in the `deploy-verify` skill covers the remaining checks (console errors, API routes, load time).
8. **Check now what can be checked now.** If a tool is available and the check is quick, run it during the release. Do not write "to monitor" for something you could have verified in a minute.
9. **Quantify every risk you flag.** Name the concern, look up the constraint (for example the function time limit of the hosting plan), measure the actual behaviour, and state a verdict:

   ```markdown
   ### Risk Assessment: <operation> timeout
   **Concern:** Large files may exceed the function time limit.
   **Constraint:** <plan> = <limit>.
   **Measurement:** Tested with <size> input. Time taken: <measured>.
   **Verdict:** Safe margin, no action. Re-check if inputs exceed <threshold>.
   ```

10. **Script the verification and save the script** at `scripts/deploy-verify-<feature>.sh`. A check performed once by hand is forgotten; a saved script can be re-run on the next release and read by the next person. A template is in `references/verification-script-and-report.md`.
11. **Document the final state in the delivery report**: environment, date, who verified, database, variables, external resources, build, smoke test, risks, and the script path. Include the script output and the logged-in smoke test steps. The report template is in the same reference file.

## Done means

- The migration status command shows every migration in the change applied to production.
- Every variable in `.env.example` appears in the production variable listing.
- Every external resource the design names (buckets, third-party services, DNS) is listed by the tool that owns it.
- The latest production deployment shows as successful and its build log has no errors.
- The public URL returns 200, the health endpoint (if the project has one) returns 200, and one logged-in core flow was completed with the data persisting after a refresh.
- Each flagged risk has a constraint, a measurement and a verdict.
- `scripts/deploy-verify-<feature>.sh` exists and its output is in the delivery report.
- A rollback plan exists if the change is hard to undo.

## Anti-patterns

- **Treating "the build passes" as "deployed".** A release once shipped as code complete with a migration unapplied, a storage bucket missing and an API key unset, and the next phase was built on top of that state. The workflow had ended at build success. Delivery ends at verified production.
- **Verifying only that the app loads.** "App exists" is not "app works". Complete a logged-in flow.
- **Flagging a risk as "may hit timeout" or "to monitor".** That is not actionable. Measure it and state whether the risk is real or theoretical.
- **Deferring a check you have the tools to run.** If a setting can be read during the audit, read it.
- **Verifying on a deployment-specific URL.** Those may sit behind the hosting platform's login. Use the public alias or custom domain.
- **Closing gaps without recording them.** An unrecorded fix cannot be distinguished from an assumption next time. If it is not written down, it does not exist.
