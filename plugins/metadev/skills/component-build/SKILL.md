---
name: component-build
description: Building a UI component or page - where it runs, how it is composed, which states it handles, how it is styled from tokens, and the responsive and keyboard checks done during development. Use when creating or substantially changing a component, page or layout.
user-invocable: false
---

# Component build

A good outcome is a component that handles every state it can be in, uses the project's tokens and primitives, works at phone, tablet and desktop widths and by keyboard, and reaches QA without basic layout bugs.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-nextjs-app-router.md` (plugin, `foundations` skill) | What server and client components can and cannot do, route groups and shared layouts, async route params |
| `foundation-shadcn-ui.md` (plugin, `foundations` skill) | Which primitives exist and their variants, what accessibility they provide, Tailwind breakpoints, dark mode, arbitrary values |
| Project `knowledge/foundations/foundation-brand.md` | The project's colour, spacing, type, shadow and radius tokens, and any breakpoints the design names |

If the project has no token definitions at all, do not invent a palette. Use the scales under step 6 for spacing, type and radius, and return `needs-decision` for colour and brand choices.

## Required context

- The design or component spec for this work, including the required states and responsive behaviour (required).
- The requirement it serves, especially any explicit statements such as "mobile-friendly" or "do not stack vertically" (required).
- The route or parent layout the component lives in, and the existing components next to it (required).
- The API contract for any data it shows (required if it shows data).
- Whether the project supports dark mode (optional; check the existing components if not stated).

## Approach

1. **Read the spec and write down the states and widths before coding.** List the loading, empty, error and success states and what each shows. List what the layout does at 375px, 768px and 1280px. If the design intent is ambiguous, ask the product lead or designer to clarify. Do not improvise an interpretation.

2. **Raise data needs early.** If the component needs a new endpoint or a different response shape, tell the backend developer now, not when you are blocked. Interactive, data-rich components usually need several API adjustments, and most can be anticipated from the spec.

3. **Decide where it runs.** Keep it a server component unless it needs hooks, event handlers, browser APIs or a hook-based library. The usual shape is a server component that fetches and passes data to a small client component that holds the interaction. This keeps code out of the client bundle.

4. **Place it in the route structure.** When several views share a shell but not a URL prefix, put them in a route group with a shared layout. Do not copy the shell into each page. In dynamic routes, await `params`.

5. **Compose from primitives.** Use the project's existing primitives (`components/ui/`) before writing a new element, and put composed components in a domain folder next to them. Build complex components from simple ones with `children` and render props. Avoid deep hierarchies. If a component needs more than three dimensions of state, it probably needs to be decomposed; raise that at design review, before building it.

6. **Choose controlled or uncontrolled inputs deliberately.** Controlled (React state owns the value) for forms with validation. Uncontrolled (the DOM owns the value) for file uploads and simple inputs.

7. **Style from tokens.** Use the project's tokens and utility classes. No ad-hoc values. When the project does not define a scale, the team defaults are:

   | Token | Default scale |
   | --- | --- |
   | Colour | Semantic palette: primary, success, error, neutral scales |
   | Spacing | 4px grid: 4, 8, 12, 16, 24, 32, 48, 64 |
   | Type | xs, sm, base, lg, xl, 2xl, 3xl |
   | Shadow | Elevation: sm, md, lg |
   | Radius | sm 4px, md 8px, lg 12px, xl 16px |

   Express variants as a map from prop value to class string, not as conditionals spread through the markup. Write custom CSS only for complex animations, print styles and overrides of third-party libraries. If the project supports dark mode, give every colour class its `dark:` counterpart as you write it.

8. **Build all four states.** Loading (initial fetch and async operations), empty (no data, first use), error (failed fetch, validation errors) and success. Every interactive component handles all four.

9. **Build mobile-first and check widths as you go.** Start from the single-column layout and add breakpoint classes upward. Check every view at 375px, 768px and 1280px during development, not only at the end. At the start of implementation, share a responsive test matrix (viewports by critical screens) with QA so both sides test the same thing.

10. **Walk the keyboard path.** The primitives handle focus, Escape and ARIA for themselves. Your composition around them does not get that for free: tab through the whole component, operate every control, and confirm focus is visible and lands somewhere sensible after dialogs close.

11. **Verify before reporting done**, following the `team-standards` skill: the project builds, and you have looked at each state and each width yourself.

## Done means

- The project builds and type-checks with the new component.
- Each of the loading, empty, error and success states can be produced and has been seen rendering.
- The component has been viewed at 375px, 768px and 1280px. Nothing is clipped, no label is truncated without intent, and any horizontal scroll has a visible affordance.
- Every control can be reached and operated by keyboard.
- No colour, spacing, type size, shadow or radius is used that is not a project token or a default scale value.
- If the project has dark mode, the component has been viewed in both modes.
- `'use client'` appears only in files that need hooks, handlers or browser APIs.

## Anti-patterns

- **Leaving responsive checks to QA.** Clipped elements and truncated labels at 375px are basic issues that should never reach QA. When the requirement says mobile-friendly, test at 375px while building.
- **Ignoring an explicit layout instruction.** If the design says "do not stack vertically", a narrow layout that drops content off the edge with no scroll affordance does not meet it. Either it fits, or it scrolls and shows that it scrolls.
- **Improvising on ambiguous design intent.** A guess at what a phrase in the spec meant costs a rework cycle. Ask instead.
- **Waiting until blocked to ask for API changes.** Tell the backend developer about new endpoints and response shape changes as soon as the spec shows they are needed.
- **One component holding too much state.** More than three state dimensions in a single component is a sign it should be split. Flag it during design review.
- **Marking a whole page `'use client'` for one interactive element.** Move the interaction into a small client component and keep the page on the server.
- **Custom CSS classes for ordinary layout.** A `.card` class in a CSS file duplicates what utilities and the Card primitive already do, and drifts from the tokens.
- **A space inside a Tailwind arbitrary value.** The space splits the class. Use an underscore: `grid-cols-[1fr_2fr]`.
- **Building only the happy path.** A component with no empty or error state looks finished in the demo and broken on first real use.
