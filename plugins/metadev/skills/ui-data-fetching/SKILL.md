---
name: ui-data-fetching
description: Fetching data and running async actions from the UI - where the fetch happens, parallel requests, per-section errors, cancelling requests on unmount, and choosing between local, context and URL state. Use when a page or component loads data, triggers an async action, or shares state across views.
user-invocable: false
---

# UI data fetching

A good outcome is a page where independent data loads in parallel, one failed request costs one section and not the page, nothing updates state after unmount, and each piece of state lives in the narrowest place that works.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-nextjs-app-router.md` (plugin, `foundations` skill) | What server and client components can do, client layouts as context providers, async route params |

The API contract is task context, not a foundation. If the response shape of an endpoint is unknown, read the route or ask the backend developer. Do not guess field names.

## Required context

- The endpoints the view needs and their response shapes (required).
- Which parts of the view depend on which request, and which can render without the others (required).
- The loading, empty and error behaviour the design asks for per section (required).
- Whether any state must survive a reload, be shareable by link, or work with browser back and forward (required).
- Existing context providers or data hooks in the project (optional; check before adding a new one).

## Approach

1. **Decide where each fetch happens.** If the data is needed to render and no interaction drives it, fetch in a server component and pass the result down as props. Fetch in a client component when the request depends on interaction or browser state.

2. **Tell the backend developer what you need early.** New endpoints and response shape changes should be raised when you read the spec, not when you are blocked.

3. **Fire independent requests in parallel.** Requests that do not depend on each other should not wait for each other.

   ```typescript
   useEffect(() => {
     const load = async () => {
       const [itemsRes, reportsRes, statusRes] = await Promise.all([
         fetch('/api/dashboard/items'),
         fetch('/api/dashboard/reports'),
         fetch('/api/dashboard/status'),
       ]);
       setData({
         items: await itemsRes.json(),
         reports: await reportsRes.json(),
         status: await statusRes.json(),
       });
     };
     load();
   }, []);
   ```

   Use this single `Promise.all` form when the sections only make sense together.

4. **Isolate errors per section.** When sections can stand alone, give each its own request, its own data state and its own error state, so one failing endpoint renders one failed section and the rest of the page still works. Each section also renders as soon as its own request returns.

   ```typescript
   const [items, setItems] = useState([]);
   const [itemsError, setItemsError] = useState(null);

   useEffect(() => {
     fetch('/api/dashboard/items')
       .then(res => res.json())
       .then(setItems)
       .catch(setItemsError);
   }, []);

   return (
     <section>
       {itemsError ? <div>Failed to load items</div> : <ItemsList items={items} />}
     </section>
   );
   ```

5. **Give every fetching section four states.** Loading, empty, error and success. Decide what each shows before writing the fetch.

6. **Cancel in-flight requests on unmount.** A component can unmount while its fetch is still running. Pass an `AbortController` signal and abort in the effect cleanup, and ignore the resulting abort error. Streaming responses need the same treatment so the stream stops cleanly on navigation. If a library hook already does this, confirm it and do not duplicate it.

   ```typescript
   useEffect(() => {
     const controller = new AbortController();

     fetch('/api/data', { signal: controller.signal })
       .then(res => res.json())
       .then(setData)
       .catch(err => {
         if (err.name === 'AbortError') return;
         setError(err);
       });

     return () => controller.abort();
   }, []);
   ```

7. **Wrap user-triggered async actions the same way every time.** Set a pending flag, run the action in `try`, report success and failure to the user, and clear the flag in `finally` so the control never stays disabled.

   ```typescript
   const handleExport = async () => {
     setIsExporting(true);
     try {
       await runExport(item);
       toast.success('Downloaded');
     } catch (err) {
       toast.error('Export failed');
     } finally {
       setIsExporting(false);
     }
   };
   ```

8. **Put each piece of state in the narrowest place that works.**

   | State | Where it lives |
   | --- | --- |
   | Used by one component | Local state |
   | Used by a child or two | Props |
   | Shareable, deep-linkable, or should follow back and forward (a session id, a record id) | The URL, for example `/chat/[sessionId]` |
   | Rarely changing and needed by every view under a shell (signed-in user, selected account) | React Context, in a provider client component rendered by the shared layout |

   For the context case, a worked example is in `references/workspace-context.md`.

9. **Verify before reporting done**, following the `team-standards` skill: force each endpoint to fail and to return nothing, and look at what the page does.

## Done means

- The network tab shows independent requests starting at the same time, not one after another.
- With one endpoint forced to fail, only its section shows an error and the other sections render.
- With an endpoint returning no rows, the section shows its empty state, not a blank area or a spinner that never ends.
- Navigating away mid-request produces no state-update warning and no error in the console.
- After a failed action, the triggering control is enabled again and the user has been told it failed.
- State that should survive a reload or be shared by link is in the URL: reloading the page returns to the same view.

## Anti-patterns

- **Sequential awaits for independent requests.** Each one waits for the previous for no reason. Start them together.
- **One error state for a whole page of independent sections.** A single failing endpoint then blanks everything. Catch per section and render what did load.
- **Context for frequently changing values.** Every consumer re-renders on every change. Context is for values like the signed-in user that change rarely.
- **Context for what props or local state can do.** It hides the data flow and adds re-renders. Pass props, or keep the state in the component.
- **Context for the active record.** The active session or record belongs in the URL so it can be linked, reloaded and reached with the back button.
- **No cleanup on a fetching effect.** The request finishes after unmount and writes to state that no longer exists.
- **Treating an abort as an error.** Aborting on unmount is expected. Showing an error for it puts a failure message on a page the user has already left or returned to.
- **Formatting a local date with `toISOString()`.** It returns UTC, so the calendar day can shift by one depending on the user's timezone. Build `YYYY-MM-DD` from `getFullYear()`, `getMonth() + 1` and `getDate()` with zero padding when the local day is what you mean.
- **Guessing the response shape.** Read the route handler or ask the backend developer.
