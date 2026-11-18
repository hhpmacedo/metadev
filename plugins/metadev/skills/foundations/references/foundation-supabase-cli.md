# Foundation: Supabase CLI

- **Last validated:** not re-validated since February 2026 (carried over from `skills/devops/references/devops-patterns.md` and `skills/devops/SKILL.md`)
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** Supabase CLI invocation, project linking, migration files and migration commands, local database, storage bucket commands, deployment-side behaviour of migrations
- **Does not cover:** database design, auth settings, row-level security, API keys (see `foundation-supabase.md`); hosting (see `foundation-vercel.md`); any one project's reference or schema (project `knowledge/foundations/`)

## Invocation

- The CLI is run through `npx supabase`; it is not assumed to be installed globally.
- The global flag `--dns-resolver https` makes the CLI resolve hostnames over DNS-over-HTTPS instead of the system resolver. It is needed on networks where the system resolver cannot resolve the remote database host; without it, commands that connect to the remote database fail on such networks.

## Project linking

| Command | What it does |
| --- | --- |
| `npx supabase link --project-ref <project-ref>` | Links the local project directory to a remote Supabase project. Remote commands act on the linked project. |
| `npx supabase status` | Shows status. Recorded in the source as "check link status" (unverified; this command reports the local development stack, not the remote link). |
| `npx supabase start` | Starts the local Supabase stack for development |

## Migrations

- Migration files live in `supabase/migrations/`. The CLI applies them in filename order.
- The remote project records which migrations have been applied.

| Command | What it does |
| --- | --- |
| `npx supabase migration new descriptive_name` | Creates a new, empty, timestamped migration file |
| `npx supabase db push` | Applies pending local migrations to the linked remote database |
| `npx supabase db pull` | Pulls the remote schema into a local migration; used when changes were made through the dashboard |
| `npx supabase db reset` | Recreates the local database and applies all migrations from scratch |
| `npx supabase db remote status --linked` | Shows which migrations are applied on the remote (unverified; later CLI versions report this with `npx supabase migration list`) |
| `npx supabase db diff` | Shows schema differences between the migration files and a database; used by the plugin's `deploy-verify` skill as a pending-migration check (unverified as a check of remote state) |

Behaviour:

- There is no automatic rollback of a migration. Undoing one means applying a further migration that reverses it.
- `db push` applies every pending file in the chain, including any reverse migration that has been placed in `supabase/migrations/`.

## Storage buckets

| Command | What it does |
| --- | --- |
| `npx supabase storage ls` | Lists storage buckets (unverified; later CLI versions require a path such as `ss:///` and the `--experimental` flag) |
| `npx supabase storage create <bucket-name> --public` | Creates a public storage bucket (unverified; this subcommand may not exist in current CLI versions, where buckets are created through the dashboard, the API or SQL) |

- A storage bucket has to be created explicitly. Schema migrations that reference a bucket do not create it; the bucket is created through the CLI or the dashboard (unverified; a migration can create a bucket by inserting into `storage.buckets`).

## Known problems

| Problem | Detail |
| --- | --- |
| Remote commands fail to connect on some networks | DNS resolution of the database host fails. Add `--dns-resolver https`. |
| Feature fails in production with "bucket not found" | The bucket was never created in that environment; it does not come from the schema migration. |
| Remote schema differs from the migration files | A change was made through the dashboard. `db pull` captures it as a migration. |

## Migration files and history (carried over from `backend-patterns.md`, `coding-standards.md`, `tech-selection-guide.md`)

- Migrations are SQL files under `supabase/migrations/`, applied in filename order. Database functions (for example an RPC used as a transaction) are migration files too.
- The source material numbered files sequentially (`001_create_clients.sql`). The CLI itself generates timestamp-prefixed names. (unverified which the team's projects use; check the project)
- `npx supabase db reset` rebuilds the local database from all migrations. It is believed to run the seed file by default; the source's `db reset --seed` flag may not exist. (unverified)
- `npx supabase db diff` shows the difference between the local schema and the migrations.
- `npx supabase db push` applies local migrations to the linked project.
- `npx supabase migration list` shows which migrations are applied locally and remotely.
- `npx supabase migration repair <version> --status applied` marks a migration as applied in the remote history. An orphan entry in the remote history blocks `db push` until it is repaired.
- `npx supabase start` starts the local stack.
- Observed classes of migration problem: two migrations with colliding names, an orphan history entry, a migration written but never pushed.
