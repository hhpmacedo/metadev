# Foundation: Supabase CLI

- **Last validated:** 2026-11-18, checked against the Supabase CLI reference and guides, the CLI repository at tag `v3.2.0`, and the `--help` output of the CLI itself by an automated documentation check. Not yet confirmed in a live project.
- **Versions checked:** Supabase CLI 3.2.0 (npm `supabase`, dist-tag `latest`); help output of 2.122.0 compared for the v2 line (npm dist-tag `v2.stable` is 2.122.1)
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** Supabase CLI invocation, project linking, migration files and migration commands, local database, storage bucket commands, deployment-side behaviour of migrations
- **Does not cover:** database design, auth settings, row-level security, API keys (see `foundation-supabase.md`); hosting (see `foundation-vercel.md`); any one project's reference or schema (project `knowledge/foundations/`)

## Invocation

- The CLI is run through `npx supabase`; it is not assumed to be installed globally. `npx supabase` runs the version in the project's `package.json` if `supabase` is a dependency there, otherwise the npm `latest` release (3.2.0 on 2026-11-18). `npx supabase --version` prints the version in use.
- Version 3 changed which database a command acts on. Commands in this file are written for 3.x; where 2.x differs, the difference is stated. Version 2 still receives security and breakage fixes but no new features.
- **Target of a command (3.x):** every command that can run against the local stack does so unless `--remote` is passed. `--remote` alone selects the linked project; `--remote=<ref|branch|url>` selects another project, a branch of the linked project, or a database URL. This applies to `db push`, `db pull`, `db diff`, `db reset`, `migration list`, `migration repair`, `migration up`, `migration down`, `seed buckets` and `storage ls/cp/mv/rm`. Commands that resolve a target print a `Target:` line on stderr naming it.
- **Target of a command (2.x, checked on 2.122.0):** `db push`, `db pull` and `migration list` act on the linked project by default; `db diff` and `db reset` act on the local database by default; the target is chosen with `--linked`, `--local` or `--db-url`.
- In 3.x, `--linked`, `--db-url` and (on commands other than `link`) `--project-ref` still work but are deprecated: they are hidden from help, print a warning naming the `--remote` form, and are to be removed in version 4. `--local` does nothing and prints a warning.
- **Confirmation for hosted changes (3.x):** a command that changes a hosted project (`db push --remote`, `db reset --remote`, `migration repair --remote`, `migration down --remote`, `db pull --remote` when it writes to the remote migration history, `seed buckets --remote`, `storage cp/mv/rm --remote`) asks for confirmation, and the default answer is No. In a non-interactive run, a run with JSON output, or a run the CLI detects as an agent, the command fails unless `--yes` is passed or `SUPABASE_YES` is exported in the shell (a value in a `.env` file does not count; a piped `y` is not read).
- The global flag `--dns-resolver` takes `native` (the default) or `https`, and is accepted on every command. With `https` the CLI resolves hostnames through Cloudflare's DNS-over-HTTPS endpoint (`https://1.1.1.1/dns-query`) instead of the system resolver, then connects to the resolved address while keeping the original hostname for TLS. It exists in both 2.122.0 and 3.2.0.
- The flag is for networks where the system resolver cannot resolve the remote database host; without it, commands that connect to the remote database fail on such networks. (unverified: taken from the original notes; not reproduced, and the documentation does not describe when the flag is needed)

## Project linking

| Command | What it does |
| --- | --- |
| `npx supabase link --project-ref <project-ref>` | Links the local project directory to a hosted Supabase project. `npx supabase link <project-ref>` is equivalent. Requires being logged in. In 3.x, a command acts on the linked project only when `--remote` is passed. |
| `npx supabase status` | Shows the status of the local development stack (containers, local URLs and keys). It is local only, needs the stack to be running, and does not report whether the directory is linked to a hosted project. |
| `npx supabase start` | Starts the local Supabase stack (Docker containers) for development. On first start it applies the migrations, runs the seed files and creates the buckets declared in `supabase/config.toml`. |

- No command reports link status directly. `supabase link` records the linked project ref in `supabase/.temp/project-ref`; the file is absent in a directory that has never been linked. In 3.x, a command run with `--remote` names the resolved project on its `Target:` line; with no linked project (and no `SUPABASE_PROJECT_ID`) a non-interactive run fails, and an interactive terminal is offered a project picker.
- `npx supabase unlink` removes the link.

## Migrations

- Migration files live in `supabase/migrations/` and are named `<timestamp>_<name>.sql`. The CLI recognises files matching `<digits>_<name>.sql`; the leading digits are the migration's version.
- Migrations are applied in timestamp (version) order.
- Each database records which migrations have been applied to it in the table `supabase_migrations.schema_migrations`, one row per version. `db push` creates the table the first time it runs.

| Command | What it does |
| --- | --- |
| `npx supabase migration new descriptive_name` | Creates a new, empty migration file `supabase/migrations/<timestamp>_descriptive_name.sql`. The timestamp is the current UTC time as `YYYYMMDDHHMMSS`. Local only. |
| `npx supabase db push --remote` | Applies pending local migrations to the linked hosted database (3.x). Asks for confirmation; see Invocation. `--dry-run` prints the migrations that would be applied without applying them. Without `--remote`, 3.x pushes to the local database and leaves the hosted project untouched. In 2.x, `npx supabase db push` with no flag pushes to the linked project. |
| `npx supabase db pull --remote` | Compares `supabase/migrations` with the linked hosted database, writes the difference as a new migration file, and records that migration in the remote migration history (3.x; asks for confirmation before writing). Used when changes were made through the dashboard. Requires Docker. Without `--remote`, 3.x pulls from the local database. In 2.x, `npx supabase db pull` pulls from the linked project by default. |
| `npx supabase db reset` | Recreates the local database, applies all migrations from scratch, then runs the seed files. With `--remote` (3.x) or `--linked` (2.x) it instead drops every user-created object in the hosted database and reapplies the migrations. |
| `npx supabase migration list --remote` | Lists the local migration files next to the migration history of the linked hosted database (3.x), which shows which migrations are applied remotely. Without `--remote`, 3.x lists the history of the local database (column headed `Local DB`). In 2.x, `npx supabase migration list` lists the linked project by default. |
| `npx supabase db diff` | Prints the schema differences between a shadow database built from `supabase/migrations` and a live database: the local database by default (in 2.x and 3.x; the local stack must be running), the linked project with `--remote` (3.x) or `--linked` (2.x). `-f <name>` saves the diff as a new migration file. |

- `npx supabase db remote status` does not exist in 2.122.0 or 3.2.0. The `db remote` group contains only `changes` and `commit`, both removed (replaced by `db diff --remote` and `db pull --remote`). Remote migration status comes from `migration list`.
- `db diff` reports schema drift, not the list of unapplied migrations. Pending migrations are shown by `migration list --remote` (a version present locally and absent remotely) and by `db push --remote --dry-run`.

Behaviour:

- The CLI has no reverse ("down") migration scripts and does not undo a single migration. Undoing one means applying a further migration that reverses it. `npx supabase migration down --last <n>` exists but is a reset: it drops every user schema and object in the target database and reapplies the migrations up to the earlier version, so the data is lost.
- `db push` applies every local migration that is not yet in the target's history, in order, including any reverse migration that has been placed in `supabase/migrations/`, and skips those already applied. If a local file has a version earlier than the last migration applied on the target, `db push` stops with "Found local migration files to be inserted before the last migration on remote database" unless `--include-all` is passed.
- `db push` does not run seed files unless `--include-seed` is passed.

## Storage buckets

| Command | What it does |
| --- | --- |
| `npx supabase storage ls ss:/// --remote --experimental` | Lists the buckets of the linked project (3.x). `ss:///` is the root of all buckets and is the default path; `ss:///<bucket>/<prefix>` lists objects. Every `storage` subcommand (`ls`, `cp`, `mv`, `rm`) requires the global `--experimental` flag or the `SUPABASE_EXPERIMENTAL` variable, and otherwise exits with "must set the --experimental flag to run this command". Without `--remote`, 3.x lists the local stack's storage. In 2.x the linked project is selected with `--linked`. |
| `npx supabase seed buckets --remote` | Creates or updates, in the linked project, the buckets declared under `[storage.buckets.<name>]` in `supabase/config.toml` (settings such as `public`, `file_size_limit`, `allowed_mime_types`), and uploads the files under a bucket's `objects_path` if one is set (3.x). Asks for confirmation; see Invocation. Without `--remote` it acts on the local stack. |

- There is no `supabase storage create` command in 2.122.0 or 3.2.0; the `storage` group has only `ls`, `cp`, `mv` and `rm`, which act on objects.
- A storage bucket has to be created explicitly; creating a table or a policy that refers to a bucket does not create it. A bucket is created through the dashboard, through the client library (`createBucket`), through `seed buckets` from `config.toml`, or with SQL by inserting a row into `storage.buckets`. A migration that contains such an `insert into storage.buckets (id, name, public) values (...)` statement creates the bucket wherever the migration is applied.
- `supabase start` creates the buckets declared in `config.toml` in the local stack only; it does not create them in a hosted project.

## Known problems

| Problem | Detail |
| --- | --- |
| Remote commands fail to connect on some networks | DNS resolution of the database host fails. `--dns-resolver https` makes the CLI resolve over DNS-over-HTTPS. (unverified: not reproduced; see Invocation) |
| `db push` reports success but production is unchanged | On 3.x, `db push` without `--remote` pushed to the local database. The `Target:` line on stderr names the database that was used. |
| A remote command fails in a script or agent run with a consent error | On 3.x, changes to a hosted project need `--yes` or `SUPABASE_YES` exported in the shell when the run is non-interactive. |
| Feature fails in production with "bucket not found" | The bucket was never created in that environment; it does not exist unless a migration inserts it into `storage.buckets` or it was created by another route. |
| Remote schema differs from the migration files | A change was made through the dashboard. `db pull --remote` captures it as a migration and records it in the remote history. |

## Migration files and history (carried over from `backend-patterns.md`, `coding-standards.md`, `tech-selection-guide.md`)

- Migrations are SQL files under `supabase/migrations/`, applied in version order. Database functions (for example an RPC used as a transaction) are migration files too.
- `supabase migration new` generates names with a 14-digit UTC timestamp prefix (`20250101000000_create_clients.sql`). The source material numbered files sequentially (`001_create_clients.sql`); such names match the `<digits>_<name>.sql` pattern the CLI recognises, with `001` as the version. (unverified: how the CLI orders a directory that mixes sequential and timestamp prefixes was not tested; which scheme a given project uses is a per-project fact)
- `npx supabase db reset` rebuilds the local database from all migrations and then runs the seed files by default. The seed file is `supabase/seed.sql` unless `[db.seed] sql_paths` in `supabase/config.toml` names others. `--no-seed` skips seeding. There is no `--seed` flag.
- Seed files also run the first time `supabase start` is run.
- `npx supabase db diff` shows the difference between the migrations and the local database schema (the local database is the default target).
- `npx supabase db push --remote` applies local migrations to the linked project (3.x; in 2.x `npx supabase db push`).
- `npx supabase migration list --remote` shows the local migration files next to the versions applied on the linked project (3.x; in 2.x `npx supabase migration list`). Only the version prefixes are compared.
- `npx supabase migration repair <version> --status applied --remote` inserts a row for that version into the remote migration history; `--status reverted` deletes the row (3.x; in 2.x the same command without `--remote` acts on the linked project). `migration repair` changes only the history table and runs no migration SQL. In 3.x it asks for confirmation on a hosted target, and without `--remote` it repairs the local database's history.
- An orphan entry in the remote history (a version recorded remotely with no local file) blocks `db push`, which stops with "Remote migration versions not found in local migrations directory". It is cleared by marking that version `--status reverted`, or by restoring the missing file (`npx supabase migration fetch --remote` writes the migration files recorded in the remote history table). `--status applied` is for the opposite case: a local migration whose changes already exist remotely but which has no history row.
- `npx supabase start` starts the local stack.
- Observed classes of migration problem: two migrations with colliding names, an orphan history entry, a migration written but never pushed.

## Validation notes (2026-11-18)

- Sources:
  - `npx supabase <command> --help` on 3.2.0 for: `link`, `unlink`, `status`, `start`, `migration` (`new`, `list`, `repair`, `up`, `down`, `squash`, `fetch`), `db` (`push`, `pull`, `reset`, `diff`, `remote`, `start`), `storage` (`ls`, `cp`), `seed buckets`, `projects`, `pull`, `init`; and on 2.122.0 for `db push`, `db pull`, `db reset`, `db diff`, `db remote`, `migration list`, `migration repair`, `storage ls`, `seed buckets`
  - `npm view supabase version`, `dist-tags`, `time`
  - https://supabase.com/docs/reference/cli/supabase-db-push (CLI reference, single page covering all commands)
  - https://supabase.com/docs/guides/local-development/cli/migrating-to-v3
  - https://supabase.com/docs/guides/deployment/database-migrations
  - https://supabase.com/docs/guides/local-development/overview
  - https://supabase.com/docs/guides/local-development/seeding-your-database
  - https://supabase.com/docs/guides/storage/buckets/creating-buckets
  - https://github.com/supabase/cli/releases/tag/v3.0.0
  - https://github.com/supabase/cli/tree/v3.2.0/apps/cli/docs/supabase (`migration/new.md`, `migration/list.md`, `migration/repair.md`, `db/push.md`, `db/pull.md`, `db/reset.md`, `db/diff.md`, `link.md`, `status.md`)
  - https://github.com/supabase/cli/tree/v3.2.0/apps/cli/src/commands (`SIDE_EFFECTS.md` for `migration/new`, `migration/down`, `link`, `storage/ls`, `seed/buckets`) and `apps/cli/src/command-internal/` (`global-flags.ts`, `db-dns.ts`)
- Corrected:
  - `npx supabase db push` "applies pending local migrations to the linked remote database" -> true only in 2.x; in 3.x it pushes to the local database, and the linked project needs `db push --remote` plus confirmation (`--yes` when non-interactive).
  - `npx supabase db remote status --linked` -> the command does not exist; replaced by `npx supabase migration list --remote` (3.x) / `npx supabase migration list` (2.x).
  - `npx supabase migration list` "shows which migrations are applied locally and remotely" -> in 3.x it compares with the local database unless `--remote` is passed.
  - `npx supabase db pull` "pulls the remote schema" -> in 3.x needs `--remote`; it also writes a row to the remote migration history and asks for confirmation.
  - `npx supabase migration repair <version> --status applied` -> in 3.x needs `--remote` to act on the hosted history; an orphan remote entry is cleared with `--status reverted`, not `--status applied`.
  - `npx supabase status` as a link check -> it reports the local stack only; the link is recorded in `supabase/.temp/project-ref`.
  - `npx supabase storage ls` -> requires `--experimental`, and in 3.x `--remote` to reach the hosted project: `npx supabase storage ls ss:/// --remote --experimental`.
  - `npx supabase storage create <bucket-name> --public` -> no such command; buckets are created through the dashboard, the client library, `seed buckets` from `config.toml`, or SQL.
  - "Schema migrations do not create a bucket; it is created through the CLI or the dashboard" -> a migration that inserts into `storage.buckets` does create it.
  - `db reset` seed behaviour -> seeds by default; the flag is `--no-seed`; `--seed` does not exist.
  - `db diff` "used by the `deploy-verify` skill as a pending-migration check" -> removed; `deploy-verify` uses `migration list`, and `db diff` reports schema drift against the local database by default.
  - "There is no automatic rollback" -> kept, with the addition that `migration down --last <n>` exists and is a destructive reset, not a reverse migration.
  - "`db push` applies every pending file" -> added the out-of-order condition (`--include-all`).
  - "Applied in filename order" -> applied in timestamp (version) order, per the documentation.
  - `--dns-resolver https` -> added the accepted values, the default (`native`), the endpoint used, and that it is a global flag on every command.
  - Added the 3.x target rule (`--remote`), the deprecated flags, and the confirmation rule, because the remote commands above are wrong or unsafe without them.
- Still unverified:
  - That `--dns-resolver https` is needed on some networks to reach the remote database host: comes from the original notes; no network with the fault was available and the documentation does not describe the case.
  - How the CLI orders a migrations directory that mixes sequential (`001_`) and timestamp prefixes: not tested, since it needs a running local stack.
  - Nothing here was run against a linked project or a local stack; behaviour beyond help output is taken from the documentation and the repository at tag `v3.2.0`.
