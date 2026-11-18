---
name: schema-migration
description: Changing a database schema safely - constraints in the database, reversible or split steps, backfills, indexes, row-level security, and testing forward and back against realistic data. Use when adding or altering tables, columns, constraints, indexes or policies.
user-invocable: false
---

# Schema migration

A good migration loses no data, can be undone or is split into steps that are each safe, leaves the rules enforced by the database itself, and has been run against data that looks like production before it reaches production.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-supabase.md` (plugin, `foundations` skill) | Row-level security defaults and policy syntax, storage bucket policies, which key bypasses policies, Postgres indexing behaviour, transactions through database functions |
| `foundation-supabase-cli.md` (plugin, `foundations` skill) | Where migration files live, how they are named and ordered, the commands to reset, diff and seed a local database |
| Project `knowledge/foundations/foundation-data.md` | Which tables hold personal or sensitive data, and which environments hold real data |
| The project's existing schema and migrations (not a foundation; the code is the source) | Existing tables, constraints and approximate row counts |

If you do not know whether the target table holds real data, or the change drops a table or column and nobody has stated that intent explicitly, stop and return `needs-decision`. A wrong guess here is not recoverable.

## Required context

- Required: the schema change wanted and the requirement behind it.
- Required: which application code reads or writes the affected tables and columns.
- Required: whether the table holds existing rows, and roughly how many.
- Required: whether the application must stay up during the change (decides whether a rename needs two steps).
- Optional: the queries that will filter, join or sort on the new columns (decides the indexes).

## Approach

1. **Express every rule you can as a constraint.** NOT NULL, UNIQUE, CHECK and FOREIGN KEY are the last line of defence; application validation is in addition to them, not instead of them.

   ```sql
   CREATE TABLE clients (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     name TEXT NOT NULL CHECK (length(name) > 0),
     email TEXT NOT NULL UNIQUE,
     plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'pro', 'enterprise')),
     created_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   ```

2. **Classify the change as additive or destructive.** Adding a table, a nullable column or a column with a default is safe in one step. Dropping or renaming anything is destructive and takes more than one migration.

3. **Give every new NOT NULL column a default,** or add it in three statements when the value must be backfilled:

   ```sql
   ALTER TABLE projects ADD COLUMN status TEXT DEFAULT 'active';
   UPDATE projects SET status = 'active' WHERE status IS NULL;
   ALTER TABLE projects ALTER COLUMN status SET NOT NULL;
   ```

4. **Split renames and replacements across two migrations.** Never drop a column in the migration that adds its replacement, because the running application still reads the old one.

   ```sql
   -- Migration 1: add the new column and copy the data
   ALTER TABLE clients ADD COLUMN display_name TEXT;
   UPDATE clients SET display_name = COALESCE(legacy_name, name);
   ALTER TABLE clients ALTER COLUMN display_name SET NOT NULL;

   -- Migration 2: only after the application code no longer uses the old column
   ALTER TABLE clients DROP COLUMN legacy_name;
   ```

5. **Batch large backfills.** Do not run a single UPDATE over millions of rows; update in ranges instead.

6. **Drop tables only with explicit intent,** after confirming no code refers to them (`DROP TABLE IF EXISTS deprecated_table;`).

7. **Write the rollback.** If the migration is not trivially reversible, put the rollback strategy in a comment at the top of the file.

8. **Add indexes for the queries you know about.**
   - Add for: columns used often in WHERE, JOIN conditions, ORDER BY on large tables, and foreign key columns.
   - Skip for: small tables (under about 1000 rows), low-cardinality columns (booleans, a status with three values), and write-heavy tables whose read performance is already acceptable.

   ```sql
   CREATE INDEX idx_clients_email ON clients(email);
   -- Composite: order matters, most selective column first
   CREATE INDEX idx_projects_client_status ON projects(client_id, status);
   -- Partial: only rows that match a condition
   CREATE INDEX idx_projects_active ON projects(client_id) WHERE status = 'active';
   ```

9. **Enable row-level security on every new table that holds user data, and write its policies in the same migration.** Row-level security is off by default on a new table. Policy syntax is in `foundation-supabase.md`.

10. **Put multi-statement writes that must succeed or fail together in a database function** and call it from the application, so they run in one transaction.

11. **Test forward and back against realistic data,** not an empty database. Reset the local database so all migrations reapply, compare the resulting schema with what you expect, then repeat with seed data loaded. The commands are in `foundation-supabase-cli.md`.

## Done means

- The migration runs on an empty database.
- The migration runs on a database with existing, representative data, and row counts and values in modified columns are unchanged afterwards.
- The rollback, where there is one, restores the previous state.
- The schema diff after applying shows nothing unexpected.
- New indexes exist (visible in the schema).
- Row-level security is enabled on each new user-data table, and a query as a different user returns none of another user's rows.
- No migration both adds a replacement column and drops the old one.

## Anti-patterns

- **Rules only in application code.** A table of bare nullable TEXT columns accepts anything from any code path. Put the rule in the table definition.
- **Destructive migration without a backfill.** `ALTER TABLE clients DROP COLUMN legacy_name;` on its own loses the data. Add the new column, copy, switch the code, then drop.
- **Testing only on an empty database.** NOT NULL additions, backfills and unique constraints only fail when rows exist.
- **One huge UPDATE as a backfill.** Batch it.
- **Indexing everything.** Each index slows writes; add them for known queries.
- **Leaving foreign key columns unindexed.** Postgres does not create those indexes for you.
- **Leaving row-level security for later.** The table is exposed from the moment it exists.
