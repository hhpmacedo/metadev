# API endpoint examples

Longer examples for the `api-endpoint` technique.

## Hand-rolled validation in a route handler

Use this for a small number of fields. For anything more complex use a schema library.

```typescript
// Next.js API route
export async function POST(req: Request) {
  const body = await req.json();

  // Validate required fields
  const errors: ValidationError[] = [];
  if (!body.name?.trim()) {
    errors.push({ field: 'name', message: 'Name is required' });
  }
  if (!body.email?.trim()) {
    errors.push({ field: 'email', message: 'Email is required' });
  }
  if (body.email && !isValidEmail(body.email)) {
    errors.push({ field: 'email', message: 'Invalid email format' });
  }

  if (errors.length > 0) {
    return Response.json(
      { error: { code: 'VALIDATION_ERROR', message: 'Invalid input', details: errors } },
      { status: 400 }
    );
  }

  // Proceed with validated data
  const client = await createClient(body);
  return Response.json(client, { status: 201 });
}
```

## Pagination request and response shapes

Offset:

```typescript
// Request
GET /api/clients?page=1&limit=20

// Response
{
  "data": [...],
  "pagination": { "page": 1, "limit": 20, "total": 87, "totalPages": 5 }
}
```

Cursor:

```typescript
// Request
GET /api/events?cursor=abc123&limit=20

// Response
{
  "data": [...],
  "pagination": { "nextCursor": "def456", "hasMore": true }
}
```

## Optimistic locking with a version column

The problem: two requests update the same record and the last write wins silently.

```sql
ALTER TABLE clients ADD COLUMN version INTEGER NOT NULL DEFAULT 1;
```

```typescript
async function updateClient(id: string, data: Partial<Client>, expectedVersion: number) {
  const { data: updated, error } = await supabase
    .from('clients')
    .update({ ...data, version: expectedVersion + 1 })
    .eq('id', id)
    .eq('version', expectedVersion)  // Only update if version matches
    .select()
    .single();

  // With no matching row (the version moved on), .single() returns an error and no data.
  if (error || !updated) {
    throw new ConflictError('Client was modified by another request. Please refresh and try again.');
  }

  return updated;
}
```

The route maps `ConflictError` to a 409 response.

## N+1 queries

```typescript
// BAD: N+1 queries
const clients = await supabase.from('clients').select('*');
for (const client of clients.data) {
  const projects = await supabase.from('projects').select('*').eq('client_id', client.id);
  client.projects = projects.data;
}

// GOOD: Single query with join
const { data } = await supabase
  .from('clients')
  .select('*, projects(*)');
```
