---
name: environment-audit
description: Inventorying a project's environments, environment variables, migrations and external resources, and finding where they have drifted from each other or from what the code expects. Use when joining a project, before a release that touches infrastructure, when something works locally but not in production, or when no written environment inventory exists.
user-invocable: false
---

# Environment Audit

A good outcome is a written, current inventory of every environment, with each difference between "what the code expects" and "what exists" either closed or listed as an open gap with an owner. Environment state that is not written down does not exist for the next person.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-vercel.md` (plugin, `foundations` skill) | Environment variable scopes (Production, Preview, Development), listing and adding variables, preview deployments |
| `foundation-supabase-cli.md` (plugin, `foundations` skill) | Linking a project, migration status, local reset, pulling remote schema, storage buckets |
| Project `knowledge/foundations/foundation-infrastructure.md` | The existing inventory, if there is one. This audit creates or updates it |

If you cannot tell which database project or hosting project is production, stop and return `needs-decision`. Do not infer it from names.

## Required context

- Required: read access to the hosting project and the database project (CLI logged in and linked).
- Required: the repo, in particular `supabase/migrations/`, `.env.example` and any environment documentation.
- Required: whether this audit is read-only. By default it is; closing gaps in production needs approval and belongs to a release (see the `release-deployment` skill).
- Optional: the design documents of recent changes, to know which resources they introduced.

## Approach

1. **List the environments that exist** and what each one is made of. Most projects on the usual stack have three:

   ```markdown
   ## Environments

   ### Local Development
   - Database: Local Supabase (npx supabase start)
   - URL: http://localhost:3000
   - Config: .env.local

   ### Preview
   - Database: <shared project, or preview branch>
   - URL: Auto-generated per PR
   - Config: Hosting environment variables (Preview)

   ### Production
   - Database: Supabase project <ref>
   - URL: <public production URL>
   - Config: Hosting environment variables (Production)
   ```

2. **Inventory the variables the code needs.** `.env.example` should list every required variable with the value blank and a comment saying what it is and where to get it:

   ```
   # .env.example
   # Supabase connection
   NEXT_PUBLIC_SUPABASE_URL=        # Supabase project URL (from dashboard > Settings > API)
   NEXT_PUBLIC_SUPABASE_ANON_KEY=   # Supabase anon/public key
   SUPABASE_SERVICE_ROLE_KEY=       # Supabase service role key (server-side only)

   # External APIs
   <SERVICE>_API_KEY=               # <what it is for> (from <where to obtain it>)
   ```

   Search the code for environment variable reads and add any that are missing from the file.
3. **Compare variables per environment.** List what is set in each scope (`npx vercel env ls production`, and the same for preview) and compare names against `.env.example`. Record names only, never values. Note variables that are set in one scope and missing in another.
4. **Compare migrations.** List the local files (`ls supabase/migrations/`) and the remote status (`npx supabase db remote status --linked`). Every local migration should be applied remotely, and every remote migration should have a local file. A remote schema change with no file means someone changed the database through the dashboard; pull it into a migration (`npx supabase db pull`) so the repo is the source of truth again.
5. **Check that the migrations rebuild the schema from nothing.** `npx supabase db reset` applies all migrations from scratch locally. If that fails, the environments cannot be reproduced.
6. **Inventory external resources** that migrations and code do not create by themselves: storage buckets, third-party API accounts and keys, DNS records, scheduled jobs. Check each with the tool that owns it (`npx supabase storage ls` for buckets). The design documents of past changes say what should be there.
7. **Check that configuration fails fast.** Confirm the application validates required variables at startup and stops with a clear message if one is missing. If it does not, record that as a gap; a missing variable should not surface as a runtime error in one feature weeks later.
8. **Check that secrets are kept out of the repo.** `.env.local` and other env files are in `.gitignore`; no secret values appear in tracked files. Local development uses `.env.local`; deployed environments use the hosting platform's variable store.
9. **Write the gaps down**, each with the evidence (the command and what it showed), the expected state, and the action needed. Quantify where you can; do not leave a finding at "to monitor" if a quick check would settle it.
10. **Update the inventory** in the project's `knowledge/foundations/foundation-infrastructure.md` (or the project's existing environment document) with the date of the audit.

## Done means

- An environment inventory exists in the project, lists every environment with its database, URL and config source, and carries the audit date.
- Every variable the code reads is in `.env.example` with a blank value and a comment.
- For each environment, the list of set variable names has been compared to `.env.example` and the differences are recorded.
- Local migration files and remote migration status match, or each mismatch is recorded as a gap.
- `npx supabase db reset` completes locally.
- Each external resource the designs name has been listed by its owning tool or recorded as missing.
- Every gap has evidence, an expected state and an action. Nothing in production was changed without approval.

## Anti-patterns

- **Trusting the last report instead of the platform.** Verify, do not assume: migrations applied, variables set, resources present, each checked with the platform tooling at the time of the audit.
- **Committing secrets, or documenting values.** The inventory records variable names and where to obtain them, never the values.
- **One undifferentiated set of variables.** The hosting platform scopes variables by environment. Use the scopes; a production key in the preview scope is a finding.
- **Editing an applied migration to make environments match.** Create a new migration to fix the difference.
- **Assuming a migration created everything the feature needs.** Storage buckets and third-party resources may have to be created separately; list them explicitly.
- **Fixing drift silently during the audit.** An audit that changes production without recording it leaves the next audit with nothing to compare against.
