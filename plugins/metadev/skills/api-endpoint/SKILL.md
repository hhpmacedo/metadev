---
name: api-endpoint
description: Designing and building an API route - resource naming, HTTP methods and status codes, input validation, one error shape, pagination and concurrent-write handling. Use when adding, changing or reviewing an API endpoint.
user-invocable: false
---

# API endpoint

A good endpoint has a contract a client can rely on: predictable resource names, correct status codes, input rejected before it reaches business logic or the database, and every error in the same shape.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-supabase.md` (plugin, `foundations` skill) | Which client and key to use server-side, how row-level security applies to the request, query, join, upsert and RPC behaviour |
| The project's existing API code (not a foundation; the code is the source) | The error shape, auth scheme and pagination style already in use. Follow them |

If the project already has endpoints, its existing error shape and pagination style win over the defaults below. Read an existing route before writing a new one. If the endpoint's authorization rule (who may read or write which rows) is not stated anywhere, stop and return `needs-decision`; guessing it creates a data leak.

## Required context

- Required: the resource and the operations needed (list, get, create, update, delete).
- Required: who may call it and what they may see or change.
- Required: the fields accepted, which are mandatory, and their formats and limits.
- Required: the tables involved and their constraints.
- Optional: expected data volume for list operations (decides the pagination style).
- Optional: whether two users can edit the same record at the same time.

## Approach

1. **Name the resource.** Use plural nouns and let the HTTP method carry the verb. Nest only to show clear ownership, and keep nesting to two levels at most.

   ```
   GET    /api/clients              -- List
   GET    /api/clients/:id          -- Get one
   POST   /api/clients              -- Create
   PATCH  /api/clients/:id          -- Update (partial)
   DELETE /api/clients/:id          -- Delete
   GET    /api/clients/:id/projects -- Nested resource
   ```

2. **Decide the status code for every outcome before writing the handler.** Clients branch on these.

   | Code | When to use |
   | --- | --- |
   | 200 | Successful GET, PATCH, DELETE |
   | 201 | Successful POST that creates a resource |
   | 204 | Successful DELETE with no response body |
   | 400 | Invalid input, malformed JSON, missing required fields |
   | 401 | No auth token or expired token |
   | 403 | Valid auth but insufficient permissions |
   | 404 | Resource does not exist |
   | 409 | Duplicate entry, optimistic locking conflict |
   | 422 | Valid JSON that fails business rules |
   | 500 | Unexpected server failure |

3. **Use one error shape for every error.** A machine-readable `code` for client handling, a human-readable `message` for debugging, and a `details` array for field-level validation errors.

   ```json
   {
     "error": {
       "code": "VALIDATION_ERROR",
       "message": "Email is required",
       "details": [{ "field": "email", "message": "This field is required" }]
     }
   }
   ```

4. **Validate input first, before any business logic or database call.** Return 400 with messages the caller can act on. For anything beyond a couple of fields, use a schema library such as Zod so the validated value is also typed. A hand-rolled version is in `references/examples.md`.

   ```typescript
   const CreateClientSchema = z.object({
     name: z.string().min(1, 'Name is required').max(255),
     email: z.string().email('Invalid email format'),
     plan: z.enum(['free', 'pro', 'enterprise']).default('free'),
   });

   export async function POST(req: Request) {
     const result = CreateClientSchema.safeParse(await req.json());
     if (!result.success) {
       return Response.json(
         { error: { code: 'VALIDATION_ERROR', message: 'Invalid input', details: result.error.issues } },
         { status: 400 }
       );
     }
     const client = await createClient(result.data);
     return Response.json(client, { status: 201 });
   }
   ```

5. **Check that the database enforces the same rules.** Validation in the route is one layer of four: database constraints, API validation, application logic for rules a constraint cannot express, and tests that all three agree. If a rule can be a constraint (NOT NULL, UNIQUE, CHECK, FOREIGN KEY) and is not one yet, add it with the `schema-migration` technique. Application code crashes; the database persists.

6. **Paginate every list endpoint that can grow.**
   - Offset (`?page=1&limit=20`, response carries `page`, `limit`, `total`, `totalPages`): simple CRUD lists, admin panels, small datasets.
   - Cursor (`?cursor=abc123&limit=20`, response carries `nextCursor`, `hasMore`): feeds, event logs, large tables, data that changes while the user pages through it.

7. **Fetch related data in one query.** Use a join or embedded select instead of querying per row (see Anti-patterns).

8. **Handle concurrent writes where two callers can edit the same record.** Use optimistic locking: a `version` column, an update that matches on the expected version, and a 409 when no row is updated. The code is in `references/examples.md`.

9. **Write the integration tests** with the `backend-integration-testing` technique.

## Done means

- Each operation returns the status code from the table for success, invalid input, missing resource, duplicate and unauthorized access, shown by a test or a recorded request.
- Every error response has `error.code` and `error.message`, and field errors appear in `error.details`.
- A request with invalid input never reaches the database (the validation test passes with no row written).
- An error response in production mode contains no stack trace and no SQL.
- List endpoints return pagination metadata and honour the limit.
- Every rule the route validates that can be a database constraint exists as one.

## Anti-patterns

- **Verbs or singular names in paths** (`/api/getClients`, `/api/client`). Use `/api/clients` and the HTTP method.
- **Returning 200 with an error body, or 500 for bad input.** Pick the code from the table.
- **Leaking internals in errors.** Stack traces and SQL in a response help an attacker and no one else. Log them server-side.
- **Validation only in application code.** Another code path, a script or a later bug will write bad rows. Put the rule in the database as well.
- **N+1 queries.** Fetching a list and then querying related rows inside a loop makes one query per item. Fetch the relation in the same query:

  ```typescript
  // Instead of a query per client inside a loop:
  const { data } = await supabase.from('clients').select('*, projects(*)');
  ```

- **Silent last-write-wins.** Two requests update the same record and the first change disappears without an error. Use the version check in step 8.
- **Deep nesting.** More than two levels of nested resources makes URLs brittle; expose the child as its own resource with a filter.
