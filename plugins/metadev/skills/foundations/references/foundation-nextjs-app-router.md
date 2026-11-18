# Foundation: Next.js App Router

- **Last validated:** not re-validated since February 2026 (carried over from `skills/frontend-patterns/references/frontend-patterns.md`)
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** route groups, dynamic route parameters, server and client components, code splitting with `import()` and `React.lazy`.
- **Does not cover:** deployment and hosting (see `foundation-vercel.md`), data layer and auth, caching and revalidation, middleware, UI primitives (see `foundation-shadcn-ui.md`).

## Route groups

- A folder whose name is wrapped in parentheses, such as `(workspace)`, is a route group. It does not add a URL segment.
- A `layout.tsx` inside a route group wraps every page in that group. This gives several views one shared shell without a shared URL prefix.
- Routes outside the group do not get the group's layout.

```
app/
  (workspace)/          -- route group, no URL segment
    layout.tsx          -- shared shell for the group
    page.tsx            -- renders at /
    chat/
      page.tsx          -- renders at /chat
    artifacts/
      [id]/
        page.tsx        -- renders at /artifacts/[id]
  login/
    page.tsx            -- renders at /login, outside the shell
```

## Dynamic route parameters

- In Next.js 16, `params` in dynamic routes is a Promise and has to be awaited. This applies to pages and to API route handlers. Observed on 16.1.4.
- The source records the synchronous form as the pattern for Next.js 13 to 15 and the async form as new in 16 (unverified: the async form may already have been introduced in 15, with synchronous access only removed in 16).

Synchronous form (older versions):

```typescript
export default function Page({ params }: { params: { id: string } }) {
  const { id } = params;
}
```

Async form (Next.js 16):

```typescript
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
}
```

API route handler (Next.js 16):

```typescript
export async function GET(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
}
```

## Server and client components

| | Server component | Client component |
| --- | --- | --- |
| How it is declared | Default in the App Router | `'use client'` at the top of the file |
| Data fetching | Can fetch on the server with `await` | Fetches in the browser |
| Client bundle | Its code is not added to the client bundle | Its code is shipped to the browser |
| Hooks (`useState`, `useEffect`, `useContext`) | Not available | Available |
| Event handlers (`onClick`, `onChange`) | Not available | Available |
| Browser APIs (`localStorage`, `navigator`) | Not available | Available |

- Third-party libraries that use hooks only work inside client components.
- A server component can render a client component and pass it fetched data as props:

```typescript
// app/(workspace)/page.tsx (server component)
export default async function DashboardPage() {
  const items = await fetchItems();          // server-side fetch
  return <ItemsList items={items} />;        // client component
}

// components/dashboard/ItemsList.tsx (client component)
'use client';
export function ItemsList({ items }) {
  const [expanded, setExpanded] = useState(false);
  // ...
}
```

- A layout can be a client component (`'use client'` in `layout.tsx`) and can then hold a React Context provider for the pages under it.

## Code splitting

- `await import('@/lib/module')` inside a function loads that module as a separate chunk at the moment the function runs. The chunk is not part of the initial bundle and appears in the browser's network tab only when it is requested.

```typescript
const handleAction = async () => {
  const { heavyFunction } = await import('@/lib/heavy-module');
  await heavyFunction();
};
```

- `React.lazy` splits at component level. The lazy component has to be rendered inside `Suspense`, which shows the fallback until the chunk has loaded.

```typescript
import { lazy, Suspense } from 'react';

const HeavyComponent = lazy(() => import('@/components/HeavyComponent'));

export function Page() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <HeavyComponent />
    </Suspense>
  );
}
```

## Route handlers and environment variables (carried over from `backend-patterns.md`)

- A route handler is an exported async function named after the HTTP method. It receives a `Request` and returns a `Response`:

```typescript
export async function POST(req: Request) {
  const body = await req.json();
  return Response.json(created, { status: 201 });
}
```

- Environment variables prefixed `NEXT_PUBLIC_` are included in the browser bundle. Anything without the prefix is available on the server only.

## External documentation

- Next.js App Router: https://nextjs.org/docs/app
