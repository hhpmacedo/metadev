---
name: caching
description: Adding a cache to a read path with the cache-aside pattern, a time-to-live and an explicit invalidation rule, and deciding when not to cache at all. Use when a slow or expensive read needs a cache, or when reviewing code that adds one.
user-invocable: false
---

# Caching

A good cache makes a measured slow read fast, and for every cached value someone can say how stale it may get and what removes it.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| Project `knowledge/foundations/foundation-infrastructure.md` | Which cache store the project uses and its limits |
| The project's existing cache code (not a foundation; the code is the source) | Client API and key naming already in use |

If the project has no cache store yet, choosing one is an architecture decision: stop and return `needs-decision` for the architect.

## Required context

- Required: the read that is slow or expensive, with evidence (a timing, a query plan, a cost figure).
- Required: every code path that writes the underlying data.
- Required: how stale the data may be before a user is harmed or misled.
- Optional: whether the same data also appears in cached lists or aggregates.

## Approach

1. **Confirm a cache is the right fix.** Do not cache:
   - data that changes on every request (real-time feeds);
   - data that is cheap to compute (a simple lookup on an indexed column);
   - data where staleness is unacceptable (financial transactions, auth tokens);
   - anything early in development, before there is evidence of a performance problem.

2. **Use cache-aside.** It is the most common and the safest pattern: check the cache, on a miss read the database, then populate the cache with a time-to-live.

   ```typescript
   async function getClient(id: string): Promise<Client> {
     // 1. Check cache
     const cached = await cache.get(`client:${id}`);
     if (cached) return JSON.parse(cached);

     // 2. Cache miss -- fetch from database
     // .single() returns an error, not an empty result, when no row matches. Never cache an error.
     const { data: client, error } = await db.from('clients').select('*').eq('id', id).single();
     if (error) throw error;

     // 3. Populate cache with TTL
     await cache.set(`client:${id}`, JSON.stringify(client), { ex: 300 }); // 5 min TTL

     return client;
   }
   ```

3. **Set a time-to-live on every cached value.** It is simple, predictable, and bounds the damage if an invalidation is missed. Choose it from the acceptable staleness for that data:

   | Data type | Suggested TTL | Reasoning |
   | --- | --- | --- |
   | User profile | 5 minutes | Changes rarely, stale data is low-risk |
   | Dashboard stats | 1 minute | Changes frequently, users expect freshness |
   | Config/settings | 15 minutes | Changes very rarely |
   | Search results | 30 seconds | Changes with every new entry |

4. **Invalidate on write.** Every path that changes the data deletes the cached entries that contain it, including lists and aggregates. Update the database first, then delete the keys.

   ```typescript
   async function updateClient(id: string, data: Partial<Client>) {
     // 1. Update database
     const { data: client, error } = await db.from('clients').update(data).eq('id', id).select().single();
     if (error) throw error;   // do not invalidate for a write that did not happen

     // 2. Invalidate cache
     await cache.del(`client:${id}`);
     await cache.del(`clients:list`); // Also invalidate list cache

     return client;
   }
   ```

5. **When unsure, invalidate more.** Stale data is worse than a cache miss.

6. **Document the invalidation rule next to the cache write,** in a comment: the TTL, and which writes delete the key.

## Done means

- A before and after measurement shows the read is faster on a cache hit.
- Every `cache.set` has a TTL.
- For every cached key there is a comment at the write naming its TTL and the writes that invalidate it.
- A test or manual check shows: read, update through the API, read again returns the new value.
- Searching the code for writes to the underlying table finds no path that skips invalidation.

## Anti-patterns

- **A cache with no staleness strategy.** If nobody can say when a value expires or what removes it, do not add it.
- **Caching before measuring.** Without evidence of a problem the cache is only a new source of bugs.
- **Invalidating the item but not the list.** The detail page is right and the list page is stale. Delete every key that contains the changed data.
- **A cache write with no TTL.** One missed invalidation then serves stale data forever.
- **Caching auth tokens or financial state.** Read these from the source every time.
