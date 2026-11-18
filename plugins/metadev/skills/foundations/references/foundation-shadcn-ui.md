# Foundation: shadcn/ui

- **Last validated:** not re-validated since February 2026 (carried over from `skills/frontend-patterns/references/frontend-patterns.md`)
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** what shadcn/ui is, installation, file structure, the commonly used components and their variants, built-in accessibility, and the Tailwind CSS behaviour that shadcn/ui components rely on (utilities, dark mode, breakpoints, arbitrary values, the typography plugin).
- **Does not cover:** a project's own tokens and theme (those live in the project's foundations), routing and rendering (see `foundation-nextjs-app-router.md`), PDF styling (see `foundation-react-pdf.md`).

## What it is

- shadcn/ui is not a component library installed as a dependency. It is a collection of component primitives, built on Radix UI and Tailwind CSS, that are copied into the project.
- The project owns the copied code. Customising a component means editing `components/ui/*.tsx` directly.

## Installation

```bash
npx shadcn@latest init
npx shadcn@latest add button
npx shadcn@latest add card
```

## File structure

```
components/
  ui/              -- shadcn primitives (button, card, dialog, ...)
  dashboard/       -- composed components built from the primitives
  workspace/       -- domain-specific components
```

## Common components

| Component | Import | Parts and variants |
| --- | --- | --- |
| Button | `@/components/ui/button` | `variant`: `default`, `destructive`, `outline`, `ghost` |
| Card | `@/components/ui/card` | `Card`, `CardHeader`, `CardTitle`, `CardContent` |
| Dialog | `@/components/ui/dialog` | `Dialog` (`open`, `onOpenChange`), `DialogContent`, `DialogHeader`, `DialogTitle` |
| Badge | `@/components/ui/badge` | `variant`: `default`, `secondary`, `destructive` |

```typescript
<Button variant="destructive">Delete</Button>

<Card>
  <CardHeader>
    <CardTitle>Recent items</CardTitle>
  </CardHeader>
  <CardContent>{/* ... */}</CardContent>
</Card>

<Dialog open={isOpen} onOpenChange={setIsOpen}>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Confirm delete</DialogTitle>
    </DialogHeader>
    {/* ... */}
  </DialogContent>
</Dialog>

<Badge variant="secondary">Draft</Badge>
```

## Accessibility

- The components use Radix UI primitives, which handle keyboard navigation, focus management, ARIA attributes and screen reader support.
- Example: Dialog traps focus and closes on Escape without extra code.
- This covers the primitives only. Markup composed around them gets no accessibility behaviour from Radix.

## Tailwind CSS underneath

### Utilities and variants

- Styling is done with utility classes on the element, for example `flex items-center gap-4 rounded-lg bg-white p-6 shadow-sm`.
- A variant can be expressed as a map from prop value to class string:

```typescript
const VARIANT_STYLES = {
  default: 'bg-zinc-100 text-zinc-700',
  success: 'bg-green-100 text-green-700',
  warning: 'bg-yellow-100 text-yellow-700',
  error: 'bg-red-100 text-red-700',
};
```

### Dark mode

- The `dark:` prefix applies a class in dark mode: `bg-white text-zinc-900 dark:bg-zinc-900 dark:text-zinc-100`.
- Class-based dark mode is configured with `darkMode: 'class'` in `tailwind.config.js` and toggled with `<html class="dark">` (unverified: this is the Tailwind v3 configuration; Tailwind v4 configures dark mode in CSS).

### Breakpoints

Breakpoints are mobile-first: an unprefixed class applies at every width, a prefixed class applies from that width up.

| Prefix | Min width |
| --- | --- |
| `sm:` | 640px |
| `md:` | 768px |
| `lg:` | 1024px |
| `xl:` | 1280px |
| `2xl:` | 1536px |

```typescript
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
```

### Arbitrary values

- Arbitrary values go in square brackets: `bg-[rgb(250,250,249)]`.
- A space inside the brackets is read as a class separator and breaks the class. An underscore stands for the space: `grid-cols-[1fr_2fr]`.

### Typography plugin

- `npm install @tailwindcss/typography` provides the `prose` classes for long-form content.
- `prose prose-zinc dark:prose-invert max-w-none` gives readable document styling with a dark variant and no width cap.
- Element modifiers adjust single elements: `prose-headings:font-semibold`, `prose-h2:mt-10 prose-h2:border-t prose-h2:pt-8`, `prose-p:leading-relaxed`, `prose-li:leading-relaxed`.

## External documentation

- shadcn/ui: https://ui.shadcn.com/
- Tailwind CSS: https://tailwindcss.com/
