# Common technology choices

Comparison tables for the decisions that come up most often. Use them at step 4 of `technology-selection` to name the options. They are general characterisations carried over from February 2026 and not re-validated since; check anything a decision turns on against current documentation.

## Frontend framework

| Option     | Good for                                  | Watch out for                 |
| ---------- | ----------------------------------------- | ----------------------------- |
| React      | Complex UIs, large ecosystem              | Boilerplate, decision fatigue |
| Vue        | Gentle learning curve, batteries included | Smaller ecosystem             |
| Svelte     | Performance, simplicity                   | Younger ecosystem             |
| Vanilla JS | Simple interactions                       | Does not scale to complex UIs |

**Default:** React if the team knows it; Vue for simpler needs or new teams.

## Backend runtime

| Option  | Good for                             | Watch out for              |
| ------- | ------------------------------------ | -------------------------- |
| Node.js | JavaScript everywhere, async I/O     | CPU-intensive tasks        |
| Python  | Data, ML, scripting, readability     | Performance, concurrency   |
| Go      | Performance, simplicity, concurrency | Verbose, smaller ecosystem |
| Rust    | Performance-critical work, safety    | Steep learning curve       |

**Default:** match the team's skills and the problem domain.

## Database

| Option     | Good for                           | Watch out for                  |
| ---------- | ---------------------------------- | ------------------------------ |
| PostgreSQL | Most use cases, relational data    | Scaling writes horizontally    |
| SQLite     | Embedded, simple apps, development | Concurrent writes, distributed |
| MongoDB    | Document data, flexible schema     | Complex queries, consistency   |
| Redis      | Caching, sessions, simple key-value | Persistence, complex queries  |

**Default:** PostgreSQL unless there is a specific reason otherwise.

## Hosting and deployment

| Option      | Good for                      | Watch out for                 |
| ----------- | ----------------------------- | ----------------------------- |
| Vercel      | Frontend, Next.js, serverless | Vendor lock-in, cost at scale |
| Railway     | Simple full-stack deployment  | Fewer options                 |
| AWS         | Full control, enterprise      | Complexity                    |
| Self-hosted | Control, cost control         | Operational burden            |

**Default:** Vercel for web applications; Railway for simple backends.
