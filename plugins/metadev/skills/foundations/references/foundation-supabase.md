# Foundation: Supabase

- **Last validated:** not re-validated since February 2026 (carried over from `skills/backend-patterns/references/backend-patterns.md`)
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** the Supabase database (Postgres), auth defaults, row-level security, storage bucket policies, client and service-role keys, and query behaviour of the JavaScript client
- **Does not cover:** the Supabase CLI, migration file layout, local development and deployment (see `foundation-supabase-cli.md`)

## Database

- The database is Postgres.
- Postgres does not automatically create an index on foreign key columns.
- On small tables (under about 1000 rows) a sequential scan is fine and an index adds little.
- In a composite index the column order matters; the most selective column goes first.
- A partial index covers only the rows matching its WHERE condition.

```sql
CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_projects_client_status ON projects(client_id, status);
CREATE INDEX idx_projects_active ON projects(client_id) WHERE status = 'active';
```

## Keys and clients

| Key | Where it may be used | Row-level security |
| --- | --- | --- |
| Anon key (`NEXT_PUBLIC_SUPABASE_ANON_KEY`) | Browser and server. It is public and safe to expose, because row-level security policies protect the data. | Enforced |
| Service-role key (`SUPABASE_SERVICE_ROLE_KEY`) | Server only. It must never reach the browser. | Bypassed |

- The key names above are the ones in the source; Supabase's current key naming may differ (unverified).

```typescript
// lib/supabase/server.ts (server-side client)
import { createClient } from '@supabase/supabase-js';

export function createServerClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!  // Service role for server operations
  );
}

// lib/supabase/client.ts (browser client)
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!  // Anon key for browser (RLS enforced)
);
```

## Row-level security

- Row-level security is off by default for new tables. It is enabled per table with `ALTER TABLE x ENABLE ROW LEVEL SECURITY;`.
- The service-role key bypasses row-level security.
- `auth.uid()` returns the ID of the authenticated user making the request; `auth.role()` returns the request's role.

```sql
-- Enable RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Policy: users see only their own data
CREATE POLICY "Users see own clients"
  ON clients FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: service role full access (for server-side operations)
CREATE POLICY "Service role full access"
  ON clients FOR ALL
  USING (auth.role() = 'service_role');
```

- The source presents the second policy as how the service role gets access. Since the service-role key bypasses row-level security anyway, whether this policy is needed is doubtful (unverified).

## Storage

- Buckets are rows in `storage.buckets`; files are rows in `storage.objects`, and access to them is controlled with row-level security policies on `storage.objects`.
- `storage.foldername(name)` returns the path segments of an object, so a policy can restrict users to a folder named after their user ID.

```sql
-- Create a private storage bucket for file uploads
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false);

-- RLS policy for storage
CREATE POLICY "Users access own documents"
  ON storage.objects FOR ALL
  USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## Auth

- Email confirmation is on by default. It is turned off in the dashboard under Authentication > Settings (dashboard path unverified).

## Query behaviour (JavaScript client)

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

- Upsert inserts or updates, matching on the columns given in `onConflict`:

```typescript
const { data, error } = await supabase
  .from('settings')
  .upsert(
    { user_id: userId, key: 'theme', value: 'dark' },
    { onConflict: 'user_id,key' }
  );
```

- An update filtered on a column value (for example `.eq('version', expectedVersion)`) changes no row when the filter does not match, and returns no row from `.select().single()`.

## Transactions

- Transactions are done through RPC: statements that must succeed or fail together are written as a Postgres function and called with `rpc`; the function body runs in one transaction.

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

## Plan limits and pricing (carried over from `tech-selection-guide.md`)

Limits and prices are the claims most likely to have changed. All unverified.

| Free tier | Limit |
| --- | --- |
| Projects | 2 |
| Database size | 500 MB |
| File storage | 50 MB |
| Monthly active users | 50,000 |
| Edge Function invocations | 500,000 per month |

- The Pro tier is $25 per month and removes most of these limits. (unverified)

## Rate limits and defaults (carried over from `tech-selection-guide.md`)

- Auth signup: 30 requests per hour per IP. Automated tests that sign up users can hit this. (unverified)
- REST API: 1000 requests per second. (unverified)
- Edge Functions: 150 concurrent connections, 10-second timeout. (unverified)
- Default JWT expiry: 3600 seconds.
- Email confirmation status for a user can be read with the service-role key.

## Connection variables

| Variable | Holds | Exposure |
| --- | --- | --- |
| `NEXT_PUBLIC_SUPABASE_URL` | Project URL (dashboard, Settings, API) | Browser |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Anon (public) key | Browser |
| `SUPABASE_SERVICE_ROLE_KEY` | Service-role key | Server only |

## Known problems

- Row-level security is enabled by default on tables created in the dashboard. Whether a table created by an SQL migration has it enabled depends on the migration. (unverified)
- A health check written as `supabase.from('_health').select('count').limit(1)` only works if a `_health` table exists and is readable by the key in use; Supabase does not provide one.
- In browser automation, the auth session is held client-side and can be set before navigation, which avoids going through the login form on every run. (unverified)
