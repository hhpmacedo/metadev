---
name: project-setup
description: Checklist for bringing up the infrastructure of a new project (auth provider, storage, environment variables, database migrations) so that it is working, not merely configured. Use when setting up a new project or a new environment, or before declaring infrastructure "ready" for a build or QA.
user-invocable: false
---

# Project setup

Infrastructure is ready when a new user can sign up and the first feature can read and write everything it needs, in the environment QA will use. A list of remaining steps is not "ready".

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-supabase.md` (plugin, `foundations` skill) | Auth provider defaults (email confirmation), storage buckets, the migration commands and how to repair migration history |
| `foundation-vercel.md` (plugin, `foundations` skill) | How environment variables are set per environment |
| Project `knowledge/foundations/` | Any project-specific account, region or naming facts |

The steps below assume the team's usual stack (Supabase and Vercel). On another stack the four areas still apply; take the commands from that stack's foundation. If you do not know which project or environment you are meant to configure, stop and return `needs-decision`: applying migrations or changing auth settings on the wrong project is hard to undo.

## Required context

- The design document or requirements, for the list of what the project needs: tables, storage buckets, third-party services (required).
- Which environment you are setting up, and whether it is a test or demo app or one with real users (required). This decides the auth settings.
- The full list of environment variables the code reads, including third-party API keys (required).
- Access to the database project and the hosting project (required).

## Approach

1. **Configure the auth provider for the kind of app this is.** Email confirmation is on by default in the database platform's auth settings. For a test or demo app, turn it off (dashboard: Authentication, Providers, Email), because it blocks user creation in development and QA. Decide this on purpose for the kind of app you are setting up; the default has blocked QA before.

2. **Create the storage buckets now.** Every bucket the design mentions is created before infrastructure is called ready. A missing bucket fails at the first upload, usually in front of QA.

3. **Set every environment variable in every place it is read.** Check the hosting environment and `.env.local` for development against the list of variables the code reads. Missing API keys cause silent failures: the call simply does nothing, and nobody sees an error.

4. **Apply the migrations and confirm they applied.**

   ```bash
   npx supabase db push          # after linking the project
   npx supabase migration list   # verify what was applied
   ```

   If orphan entries in the migration history block the push, repair the history and push again:

   ```bash
   npx supabase migration repair <version> --status applied
   ```

5. **Prove it with the first real flow.** Create a user, and exercise one read, one write and one upload (if storage is used) in the environment you set up. This is the verify-before-done rule in `team-standards` applied to infrastructure.

6. **Report what is in place and what is not.** Anything you could not complete is a blocker with an owner, stated as such.

## Done means

- A new user can be created in the target environment without manual intervention.
- Each required bucket exists (list them and check).
- Every variable the code reads has a value in the hosting environment and in local development. You compared the two lists rather than assuming.
- The migrations were pushed and `npx supabase migration list` was run afterwards to confirm they applied.
- One end-to-end flow that touches auth, the database and storage has been run and observed to work.

## Anti-patterns

- **Listing setup work as "next steps".** A delivery that needs a migration, a bucket and an API key that are not yet in place is not delivered. Either do them or hand them over explicitly as blockers.
- **Trusting the defaults.** Email confirmation left on by default has caused a critical QA blocker in a demo app.
- **Patching migration problems one at a time.** Naming collisions, orphan history entries and unpushed migrations are one class of problem. If they recur, write a migration runbook for the project rather than solving each from scratch.
- **Checking that a variable exists in one environment only.** Local works, production silently does not.
