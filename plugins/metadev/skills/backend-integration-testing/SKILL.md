---
name: backend-integration-testing
description: Testing API routes and data access against a real database with realistic seed data - happy path, error cases, authorization, and the database state after each operation. Use when writing or reviewing integration tests for an endpoint or a data-access function.
user-invocable: false
---

# Backend integration testing

Good integration tests show that the API, the application logic and the database constraints agree: each response is correct, and the database holds what the response says happened.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-supabase.md` (plugin, `foundations` skill) | Which client and key to use in tests, and that the service-role key bypasses row-level security (so authorization tests must not use it for the request under test) |
| `foundation-supabase-cli.md` (plugin, `foundations` skill) | How to reset and seed a local database |
| The project's test configuration and README (not a foundation; the code is the source) | Test runner, how the app and a test database are started, where seed data lives |

If the only database available to the tests holds real data, stop and return `needs-decision`. These tests delete rows.

## Required context

- Required: the endpoint or function under test and its contract (inputs, status codes, error shape).
- Required: the tables it touches and their constraints.
- Required: the authorization rule (who may access what).
- Optional: expected data volume in production, to size the seed data.

## Approach

1. **Start each test from a known state.** Clean the tables the test touches in `beforeEach`, so tests do not depend on order.

2. **Seed realistic data.** Empty tables hide bugs. Include edge cases in the seed: null optional fields, maximum-length strings, special characters. For list endpoints use the volume the application will see, at least 100 rows.

3. **Cover these cases for every endpoint:**
   - happy path: valid input produces the expected output;
   - validation errors: missing fields, invalid formats;
   - not found: a resource ID that does not exist;
   - duplicates: a unique constraint violation;
   - authorization: accessing a resource you should not;
   - database state: the database reflects what the API said happened.

4. **Assert on the status code and the error code,** not only on the body text. Clients branch on these.

5. **After each write, read the row back from the database and assert on it.** A 201 with nothing stored, or the wrong value stored, passes a response-only test.

6. **Simulate failures,** not only success: a duplicate, a missing parent row, a dependency that errors.

   ```typescript
   describe('POST /api/clients', () => {
     beforeEach(async () => {
       // Clean state for each test
       await db.from('clients').delete().neq('id', '');
     });

     it('creates a client with valid data', async () => {
       const res = await fetch('/api/clients', {
         method: 'POST',
         headers: { 'Content-Type': 'application/json' },
         body: JSON.stringify({ name: 'Acme Corp', email: 'admin@acme.com' }),
       });

       expect(res.status).toBe(201);
       const body = await res.json();
       expect(body.name).toBe('Acme Corp');
       expect(body.id).toBeDefined();

       // Verify database state
       const dbRecord = await db.from('clients').select('*').eq('id', body.id).single();
       expect(dbRecord.data.email).toBe('admin@acme.com');
     });

     it('returns 400 for missing required fields', async () => {
       const res = await fetch('/api/clients', {
         method: 'POST',
         headers: { 'Content-Type': 'application/json' },
         body: JSON.stringify({ name: '' }),
       });

       expect(res.status).toBe(400);
       const body = await res.json();
       expect(body.error.code).toBe('VALIDATION_ERROR');
     });

     it('returns 409 for duplicate email', async () => {
       // Setup: create existing client
       await db.from('clients').insert({ name: 'Existing', email: 'taken@example.com' });

       const res = await fetch('/api/clients', {
         method: 'POST',
         headers: { 'Content-Type': 'application/json' },
         body: JSON.stringify({ name: 'New', email: 'taken@example.com' }),
       });

       expect(res.status).toBe(409);
     });
   });
   ```

7. **Run the suite and read the output** before reporting. The `team-standards` skill covers verifying before claiming done.

## Done means

- The suite passes when run twice in a row and when test order changes.
- Each endpoint has a test for every case in step 3.
- Every test of a write asserts on a row read back from the database.
- List endpoint tests run against at least 100 seeded rows.
- The authorization test makes its request as a user who should be refused, and is refused.

## Anti-patterns

- **Testing against empty tables.** Pagination, ordering, constraint and performance problems only show with data.
- **Asserting only on the response.** The database may disagree with it.
- **Only the happy path.** Most production failures are in the error paths.
- **Tests that depend on each other's leftovers.** Reset state in `beforeEach`.
- **Authorization tests run with a key that bypasses policies.** They pass whatever the policies say.
- **Seed data that is all tidy.** Nulls, long strings and special characters are where the bugs are.
