# Foundation: Supabase

- **Last validated:** 2026-11-18, checked against the Supabase documentation (API keys, row-level security, tables, storage, auth, Edge Function limits), the Supabase pricing page, the PostgreSQL 18 and PostgREST documentation, and npm package metadata by an automated documentation check. Not yet confirmed in a live project.
- **Versions checked:** hosted Supabase platform as documented on 2026-11-18; `@supabase/supabase-js` 2.119.1; `@supabase/ssr` 0.12.7; PostgreSQL documentation for version 18
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** the Supabase database (Postgres), auth defaults, row-level security, storage bucket policies, publishable and secret keys, and query behaviour of the JavaScript client
- **Does not cover:** the Supabase CLI, migration file layout, local development and deployment (see `foundation-supabase-cli.md`)

## Database

- The database is Postgres.
- Postgres does not automatically create an index on foreign key columns (the referencing side).
- On small tables (under about 1000 rows) a sequential scan is fine and an index adds little. (unverified: the 1000-row figure is a rule of thumb with no primary source)
- In a composite B-tree index the column order matters. The index is most efficient when the query constrains the leading (leftmost) columns; columns the queries filter by equality go first.
- A partial index covers only the rows matching its WHERE condition.

```sql
CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_projects_client_status ON projects(client_id, status);
CREATE INDEX idx_projects_active ON projects(client_id) WHERE status = 'active';
```

## Keys and clients

| Key | Format | Where it may be used | Row-level security |
| --- | --- | --- | --- |
| Publishable key (`NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`) | `sb_publishable_...` | Browser and server. It is safe to expose, because row-level security policies protect the data. Requests run as the Postgres role `anon`, or `authenticated` when a user is signed in. | Enforced |
| Secret key (`SUPABASE_SECRET_KEY`) | `sb_secret_...` | Server only. It must never reach the browser; a secret key sent from a browser is rejected with HTTP 401. Requests run as the Postgres role `service_role`. | Bypassed |
| `anon` key (legacy) | Long-lived JWT | Legacy version of the publishable key. | Enforced |
| `service_role` key (legacy) | Long-lived JWT | Legacy version of the secret key. Server only. | Bypassed |

- Supabase is deprecating the legacy `anon` and `service_role` keys by the end of 2026. Until the legacy keys are disabled in the dashboard (Settings > API Keys), both kinds work at the same time.
- The older variable names `NEXT_PUBLIC_SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` hold the legacy keys; the Supabase documentation now uses `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` and `SUPABASE_SECRET_KEY`.
- Whether a newly created project is still issued legacy keys is not stated in the documentation. (unverified: not stated on the API keys page)
- A client created with a secret key bypasses row-level security only while the request carries no user access token. If the client holds a user session (a cookie-based server client, a manually set `Authorization` header, or a session returned by an auth call such as `signUp` on that client), requests run under that user's policies.
- For cookie-based user sessions in Next.js, the Supabase documentation uses `@supabase/ssr` (`createBrowserClient`, `createServerClient`) with the publishable key. `@supabase/auth-helpers-nextjs` is marked deprecated on npm.

```typescript
// lib/supabase/admin.ts (server-side client with the secret key, no user session)
import { createClient } from '@supabase/supabase-js';

export function createAdminClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SECRET_KEY!  // Secret key: server only, bypasses RLS
  );
}

// lib/supabase/client.ts (browser client)
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!  // Publishable key for browser (RLS enforced)
);
```

## Row-level security

- A table created in the dashboard Table Editor has row-level security enabled by default. A table created with SQL (SQL Editor, migration, or any other tool) has it off; it is enabled per table with `ALTER TABLE x ENABLE ROW LEVEL SECURITY;`.
- Automatic enabling for SQL-created tables exists only as an opt-in event trigger that the project installs itself; it applies to tables created after it is installed.
- A table in the `public` schema without row-level security is readable and writable through the Data API by anyone holding the publishable key, where the Data API roles hold grants on it. Default grants on new tables differ between projects depending on creation date and Data API settings; Supabase is changing the platform default so that exposure is opt-in.
- The secret key and the legacy `service_role` key bypass row-level security: the Postgres role `service_role` has the `BYPASSRLS` attribute, so no policy is evaluated for it.
- `auth.uid()` returns the ID of the user making the request, and `null` when no user is authenticated. `auth.jwt()` returns the request's JWT.
- `auth.role()` still exists and returns the `role` claim of the request, but it is deprecated in favour of the `TO` clause of a policy (`TO authenticated`, `TO anon`).

```sql
-- Enable RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Policy: signed-in users see only their own data
CREATE POLICY "Users see own clients"
  ON clients FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
```

- A policy written for the service role (for example `USING (auth.role() = 'service_role')`) has no effect and is not needed, because the service role never evaluates policies.

## Storage

- Buckets are rows in `storage.buckets`; files are rows in `storage.objects`, and access to them is controlled with row-level security policies on `storage.objects`.
- A bucket is private unless created with `public` set to true. Without policies on `storage.objects`, Storage allows no uploads. The secret key bypasses these policies.
- `storage.foldername(name)` returns the path segments of an object, so a policy can restrict users to a folder named after their user ID.

```sql
-- Create a private storage bucket for file uploads
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false);

-- RLS policy for storage
CREATE POLICY "Users access own documents"
  ON storage.objects FOR ALL
  TO authenticated
  USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## Auth

- Email confirmation is on by default on hosted projects. It is turned off in the dashboard under Authentication > Sign In / Providers, in the Email provider's settings ("Confirm email").
- In local development and self-hosted projects email confirmation is off by default (`auth.email.enable_confirmations` in the CLI configuration).

## Query behaviour (JavaScript client)

Checked against `@supabase/supabase-js` 2.119.1 documentation.

- Queries return `{ data, error }`.
- A related table can be embedded in a select, which fetches the relation in one query:

```typescript
const { data, error } = await supabase
  .from('projects')
  .select('id, name, status, client:clients(name)')
  .eq('client_id', clientId)
  .order('created_at', { ascending: false })
  .limit(20);

// All clients with their projects, one query
const { data } = await supabase.from('clients').select('*, projects(*)');
```

- Upsert inserts or updates, matching on the unique column(s) given in `onConflict`. Upserted rows are not returned unless `.select()` is chained. The comma-separated form for several columns is not shown on the reference page. (unverified: the reference page shows only a single column)

```typescript
const { data, error } = await supabase
  .from('settings')
  .upsert(
    { user_id: userId, key: 'theme', value: 'dark' },
    { onConflict: 'user_id,key' }
  )
  .select();
```

- An update filtered on a column value (for example `.eq('version', expectedVersion)`) changes no row when the filter does not match. `.single()` requires exactly one row, so `.select().single()` on that update returns an error and no data.

## Transactions

- Transactions are done through RPC: statements that must succeed or fail together are written as a Postgres function and called with `rpc`. Every Data API request runs inside one transaction, so the function body runs in one transaction.
- A database function is `security invoker` by default and, by default, can be executed by any role, including `anon`.

```sql
CREATE OR REPLACE FUNCTION transfer_project(
  p_project_id UUID,
  p_new_client_id UUID
) RETURNS void AS $$
BEGIN
  UPDATE projects SET client_id = p_new_client_id WHERE id = p_project_id;
  INSERT INTO audit_log (action, entity_id, details)
  VALUES ('transfer', p_project_id, jsonb_build_object('new_client', p_new_client_id));
END;
$$ LANGUAGE plpgsql;
```

```typescript
const { error } = await supabase.rpc('transfer_project', {
  p_project_id: projectId,
  p_new_client_id: newClientId,
});
```

## Plan limits and pricing

Figures from the Supabase pricing page (`https://supabase.com/pricing`) on 2026-11-18.

| Free plan | Limit |
| --- | --- |
| Projects | 2 active projects (paused projects do not count) |
| Database size | 500 MB |
| File storage | 1 GB |
| Monthly active users | 50,000 |
| Edge Function invocations | 500,000 per month |
| Egress | 5 GB |
| Inactivity | A project is paused after 1 week of inactivity |

- The Pro plan is from $25 per month and includes $10 of compute credits per month, which covers one Micro compute instance; each further project adds compute cost. It includes 8 GB of disk per project, 100 GB of file storage, 100,000 monthly active users and 2 million Edge Function invocations; usage above these is billed (for example $0.125 per GB of disk, $0.00325 per monthly active user, $2 per million invocations).

## Rate limits and defaults

Figures from the Supabase Auth rate limits page and the Edge Functions limits page on 2026-11-18.

- Auth sign-ups and sign-ins (`/auth/v1/signup`, `/recover`, `/resend`, `/magiclink`, `/otp`, `/user`): 30 requests per 5 minutes per IP address by default, customizable. Automated tests that sign up users can hit this.
- Emails sent by the built-in email provider: 2 per hour per project; the limit is configurable only with custom SMTP or a Send Email hook. Sign-ups that send a confirmation email count against it.
- Signup confirmation requests: one per 60-second window per user. Anonymous sign-ins: 30 per hour per IP address by default.
- Token requests (`/auth/v1/token`, including refresh): 150 per 5 minutes per IP address by default.
- REST (Data) API: the Supabase documentation publishes no platform-wide requests-per-second limit. The earlier figure of 1000 requests per second has no source. (unverified: no published limit found)
- Edge Functions: wall-clock duration 150 seconds on the Free plan and 400 seconds on paid plans; request idle timeout 150 seconds (then HTTP 504); CPU time 2 seconds per request; memory 256 MB. No concurrency limit is published. (concurrency unverified: not stated on the limits page)
- Default access token (JWT) expiry: 1 hour (3600 seconds), configured on the Sessions page of the dashboard's Auth settings.
- Email confirmation status for a user can be read with the secret key through the `auth.admin` methods. (unverified: the reference page checked does not list the returned fields)

## Connection variables

| Variable | Holds | Exposure |
| --- | --- | --- |
| `NEXT_PUBLIC_SUPABASE_URL` | Project URL (dashboard: Connect dialog, or Settings > API Keys) | Browser |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Publishable key (`sb_publishable_...`) | Browser |
| `SUPABASE_SECRET_KEY` | Secret key (`sb_secret_...`) | Server only |

- Projects still on legacy keys hold them in `NEXT_PUBLIC_SUPABASE_ANON_KEY` (browser) and `SUPABASE_SERVICE_ROLE_KEY` (server only).

## Known problems

- A table created by an SQL migration has row-level security off unless the migration enables it (see Row-level security).
- A client that was created with the secret key but carries a user session is subject to row-level security (see Keys and clients).
- A health check written as `supabase.from('_health').select('count').limit(1)` only works if a `_health` table exists and is readable by the key in use; Supabase does not provide one.
- In browser automation, the auth session is held client-side and can be set before navigation, which avoids going through the login form on every run. (unverified: not checked against a primary source)

## Validation notes (2026-11-18)

- Sources:
  - https://supabase.com/docs/guides/api/api-keys
  - https://supabase.com/docs/guides/database/postgres/row-level-security
  - https://supabase.com/docs/guides/database/tables
  - https://supabase.com/docs/guides/api/securing-your-api
  - https://supabase.com/docs/guides/database/postgres/event-triggers
  - https://supabase.com/docs/guides/troubleshooting/deprecated-rls-features-Pm77Zs
  - https://supabase.com/docs/guides/troubleshooting/why-is-my-service-role-key-client-getting-rls-errors-or-not-returning-data-7_1K9z
  - https://supabase.com/docs/guides/storage/security/access-control
  - https://supabase.com/docs/guides/storage/buckets/creating-buckets
  - https://supabase.com/docs/guides/auth/passwords
  - https://supabase.com/docs/guides/auth/general-configuration
  - https://supabase.com/docs/guides/auth/sessions
  - https://supabase.com/docs/guides/auth/rate-limits
  - https://supabase.com/docs/guides/auth/server-side/creating-a-client
  - https://supabase.com/docs/guides/functions/limits
  - https://supabase.com/docs/guides/functions/status-codes
  - https://supabase.com/docs/guides/database/functions
  - https://supabase.com/docs/guides/platform/billing-on-supabase
  - https://supabase.com/docs/reference/javascript/upsert
  - https://supabase.com/docs/reference/javascript/single
  - https://supabase.com/docs/reference/javascript/auth-admin-getuserbyid
  - https://supabase.com/pricing
  - https://docs.postgrest.org/en/stable/references/transactions.html
  - https://www.postgresql.org/docs/current/ddl-constraints.html
  - https://www.postgresql.org/docs/current/indexes-multicolumn.html
  - https://www.postgresql.org/docs/current/indexes-partial.html
  - npm metadata for `@supabase/supabase-js`, `@supabase/ssr`, `@supabase/auth-helpers-nextjs`
- Corrected:
  - Key names: "anon" and "service-role" as the current keys -> publishable (`sb_publishable_...`) and secret (`sb_secret_...`) keys; `anon` and `service_role` are legacy and deprecated by the end of 2026.
  - Environment variables: `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` -> `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY` (old names kept only as legacy).
  - Project URL location: dashboard Settings, API -> Connect dialog or Settings > API Keys.
  - Row-level security default: "off by default for new tables" -> on for tables created in the dashboard Table Editor, off for tables created with SQL.
  - Service-role policy (`auth.role() = 'service_role'`): presented as how the service role gets access -> has no effect and is not needed; example removed.
  - `auth.role()`: described as current -> deprecated in favour of the policy `TO` clause.
  - Service/secret key "bypasses row-level security" -> bypasses only while the request carries no user access token.
  - Server client example named `createServerClient` -> `createAdminClient` (the former is the name of the `@supabase/ssr` function for cookie-based user sessions).
  - Composite index: "most selective column goes first" -> columns constrained by equality go first; the index is most efficient with constraints on the leading columns.
  - Email confirmation toggle: Authentication > Settings -> Authentication > Sign In / Providers, Email provider; default is on for hosted projects and off locally.
  - `.select().single()` on an update matching no row: "returns no row" -> returns an error and no data.
  - Upsert: added that rows are not returned without `.select()`.
  - Free plan file storage: 50 MB -> 1 GB. Projects: 2 -> 2 active projects. Added egress and pausing figures from the same page.
  - Pro plan: "$25 per month and removes most of these limits" -> from $25 per month with $10 compute credits and stated included quotas, billed above them.
  - Auth signup rate limit: 30 requests per hour per IP -> 30 requests per 5 minutes per IP (default, customizable); built-in email provider is limited to 2 emails per hour per project.
  - Edge Functions: "150 concurrent connections, 10-second timeout" -> 150 s (Free) or 400 s (paid) wall-clock, 150 s request idle timeout, 2 s CPU time, 256 MB memory; no published concurrency limit.
  - REST API: "1000 requests per second" -> no published platform-wide limit.
- Still unverified:
  - The 1000-row threshold for when an index adds little: rule of thumb, no primary source.
  - Whether new projects are still issued legacy keys: not stated on the API keys page.
  - Comma-separated `onConflict` for several columns: the reference page shows only a single column.
  - REST (Data) API requests-per-second limit: none published.
  - Edge Function concurrency limit: none published.
  - Reading email confirmation status through `auth.admin`: returned fields not listed on the page checked.
  - Setting the auth session before navigation in browser automation: no primary source checked.
