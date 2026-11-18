---
name: frontend-performance
description: Finding and fixing slow loads and unnecessary re-renders in the UI - keeping heavy dependencies out of the initial bundle, splitting at component level, parallel requests, and using memoization only where it pays. Use when a page loads slowly, a heavy library is being added, or a view re-renders more than it should.
user-invocable: false
---

# Frontend performance

A good outcome is an initial load that carries only what the first view needs, with each fix confirmed by observing the page and not assumed from the code.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-nextjs-app-router.md` (plugin, `foundations` skill) | How `import()` and `React.lazy` split code, what stays out of the client bundle in server components |
| `foundation-react-pdf.md` (plugin, `foundations` skill) | Only when the heavy dependency is the PDF library: its size |

## Required context

- Which page or interaction is slow, and how that was observed (required).
- Whether the problem is load (too much shipped or fetched up front) or render (too much re-rendering after load) (required; if unknown, step 1 finds out).
- Any heavy dependency recently added or about to be added (optional).
- The project's performance target, if it has one (optional).

## Approach

1. **Establish which kind of problem it is before changing code.** Open the browser's network tab and reload the page. A large script or many requests in sequence before the first view is a load problem. A page that loads quickly and then lags during interaction is a render problem. Follow the evidence-first rule in the `team-standards` skill: do not start with the fix you expect to need.

2. **Load: keep code on the server where it can stay there.** A component that needs no hooks, handlers or browser APIs should be a server component. Its code then never reaches the client bundle. Check whether a `'use client'` at the top of a large file is pulling everything it imports into the browser.

3. **Load: import heavy dependencies at the moment of use.** A library needed only after a user action (an export, an editor, a chart behind a tab) should be loaded with `import()` inside the handler. It then costs nothing on initial load.

   ```typescript
   const handleExport = async () => {
     const { generatePdf } = await import('@/lib/pdf-export');
     await generatePdf(item);
   };
   ```

   Keep the library's imports inside the module you load dynamically. A static import of the same library anywhere on the initial path puts it back in the first bundle.

4. **Load: split heavy components with `React.lazy`.** When the heavy part is a component and not a function, load it lazily inside `Suspense` with a fallback. The file that calls `lazy()` must itself be a client component, or nothing is split; the lazy component must be a default export. `next/dynamic` with `ssr: false` is likewise only allowed in a client component.

5. **Load: start independent requests together.** Requests that do not depend on each other should run in parallel, and each section should render when its own data arrives. The `ui-data-fetching` skill covers the pattern.

6. **Render: look at what triggers the re-renders first.** A frequently changing value in React Context re-renders every consumer on every change. Move such values to local state, props or the URL before reaching for memoization.

7. **Render: memoize only where it pays.** Wrap a component in `React.memo` when it re-renders often with the same props, or when its render is expensive.

   ```typescript
   export const ExpensiveList = React.memo(function ExpensiveList({ items }) {
     return (
       <ul>
         {items.map(item => (
           <li key={item.id}>{item.name}</li>
         ))}
       </ul>
     );
   });
   ```

   Do not memoize simple components or ones that rarely re-render. The comparison then costs more than the render it saves.

8. **Confirm each fix by observation.** Reload with the network tab open and check that the split chunk is absent on initial load and appears only when the action is triggered. For a render fix, repeat the interaction that was slow.

## Done means

- The network tab on initial load does not show the chunk of any dependency that was moved behind an action.
- Triggering the action loads that chunk, and the action completes.
- Independent requests start at the same time.
- The interaction that was slow has been repeated and is no longer slow.
- Each `React.memo` added can be justified by one of the two cases in step 7.
- The project builds.

## Anti-patterns

- **Fixing before observing.** Splitting bundles for a render problem, or adding memoization for a load problem, changes code and not the symptom. Look at the network tab first.
- **Assuming a dynamic import worked.** One static import of the library elsewhere undoes it. Check the network tab: the library should load only when the user triggers the action.
- **Putting a large, rarely used library in the initial bundle.** Every visitor then pays for a feature few of them use. Import it at the moment of use.
- **Memoizing everything.** On simple components the overhead is larger than the render cost. Memoize the frequent or expensive ones.
- **Frequently changing values in Context.** This is a common cause of whole-tree re-renders. Narrow the state before optimising the consumers.
- **`'use client'` on a whole page.** Everything the page imports ships to the browser. Keep the page on the server and make the interactive part a small client component.
