# Foundation: shadcn/ui

- **Last validated:** 2026-11-18, checked against the shadcn/ui documentation (installation, CLI, `components.json`, theming, dark mode, changelog, component pages), the Tailwind CSS v4 and v3 documentation, the Base UI and Radix UI Dialog documentation, the `@tailwindcss/typography` README and npm package metadata by an automated documentation check. Not yet confirmed in a live project.
- **Versions checked:** `shadcn` CLI 4.23.0 (npm `latest`); `tailwindcss` 4.3.5 (npm `latest`; the v3 line is published under the `v3-lts` tag at 3.4.19); `@tailwindcss/typography` 0.5.20.
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** what shadcn/ui is, installation, file structure, the commonly used components and their variants, built-in accessibility, and the Tailwind CSS behaviour that shadcn/ui components rely on (utilities, dark mode, breakpoints, arbitrary values, the typography plugin).
- **Does not cover:** a project's own tokens and theme (those live in the project's foundations), routing and rendering (see `foundation-nextjs-app-router.md`), PDF styling (see `foundation-react-pdf.md`).

## What it is

- shadcn/ui is not a component library installed as a dependency. Its documentation describes it as "a set of beautifully-designed, accessible components and a code distribution platform". Component source is copied into the project by a CLI.
- The components are styled with Tailwind CSS and wrap a headless primitive library. Three primitive libraries ("bases") are offered: Base UI (`base`), Radix UI (`radix`) and React Aria (`aria`).
- Base UI is the default base for new projects since July 2026. Before that, Radix UI was the default. Radix UI is not deprecated, and a project already on Radix does not have to migrate.
- A project uses one base. The same component name (`button`, `dialog`, ...) has a separate implementation and a separate documentation page per base: `/docs/components/base/<name>`, `/docs/components/radix/<name>`, `/docs/components/aria/<name>`.
- Radix-based components import from the unified `radix-ui` package (since February 2026), not from the per-component `@radix-ui/react-*` packages. `shadcn migrate radix` rewrites the old imports.
- The project owns the copied code. Customising a component means editing `components/ui/*.tsx` directly.

## Installation

```bash
npx shadcn@latest init
npx shadcn@latest add button
npx shadcn@latest add card
```

- The CLI package is `shadcn`. The older `shadcn-ui` package (last version 0.9.5) is marked on npm as no longer supported.
- `init` accepts `-t, --template <template>` (`next`, `vite`, `start`, `react-router`, `laravel`, `astro`), `-b, --base <base>` (`base`, `radix`, `aria`), `-p, --preset [name]`, `--monorepo`, `--rtl`, `--css-variables` (default) and `--no-css-variables`. `shadcn create` is an alias of `init`.
- `init -d` (`--defaults`) uses `--template=next --preset=nova`.
- A non-interactive `init` without `-b` produces a Base UI project. `init -b radix` produces a Radix UI project.
- `add` accepts component names, URLs or local paths, and `-o, --overwrite`, `-a, --all`, `-p, --path <path>`, `--dry-run`, `--diff [path]`, `--view [path]`.
- `init` writes `components.json` at the project root. The CLI reads it to decide where to put components and how to rewrite imports. Its documented fields are:

| Field | Meaning |
| --- | --- |
| `$schema` | Optional; `https://ui.shadcn.com/schema.json` |
| `style` | Component style. Cannot be changed after initialisation. The `default` style is deprecated |
| `rsc` | `true` makes the CLI add `use client` to client components |
| `tsx` | `false` makes the CLI write `.jsx` files |
| `tailwind.config` | Path to `tailwind.config.js`/`.ts`. Left blank for Tailwind v4 |
| `tailwind.css` | Path to the CSS file that imports Tailwind |
| `tailwind.baseColor` | `neutral`, `stone`, `zinc`, `mauve`, `olive`, `mist` or `taupe`. Cannot be changed after initialisation |
| `tailwind.cssVariables` | `true` (default): components use semantic tokens. `false`: components use inline Tailwind colour utilities. Cannot be changed without reinstalling components |
| `tailwind.prefix` | Prefix applied to Tailwind utility classes in added components |
| `aliases.components`, `aliases.ui`, `aliases.lib`, `aliases.hooks`, `aliases.utils` | Import aliases. `aliases.ui` also determines the install directory |
| `registries` | Maps a namespace such as `@acme` to a registry URL template containing `{name}` |

- The exact `style` value and the field that records the base in a `components.json` written by CLI 4.23.0 (unverified: the CLI was not run in this check, and the `components.json` page does not state it).

## File structure

```
components/
  ui/              -- shadcn primitives (button, card, dialog, ...)
  dashboard/       -- composed components built from the primitives
  workspace/       -- domain-specific components
```

- `components/ui/` is where the CLI installs components when `aliases.ui` is `@/components/ui`, the value shown in the documentation. The other folders are a project convention, not something the CLI creates.
- With `init --monorepo`, components are imported from `@workspace/ui/components/<name>` and added with `add <name> -c apps/web`.

## Common components

Checked against the Radix UI pages of the component documentation. The import paths are the same for every base.

| Component | Import | Parts and variants |
| --- | --- | --- |
| Button | `@/components/ui/button` | `variant`: `default`, `outline`, `ghost`, `destructive`, `secondary`, `link`. `size`: `default`, `xs`, `sm`, `lg`, `icon`, `icon-xs`, `icon-sm`, `icon-lg` |
| Card | `@/components/ui/card` | `Card` (`size`: `default`, `sm`), `CardHeader`, `CardTitle`, `CardDescription`, `CardAction`, `CardContent`, `CardFooter` |
| Dialog | `@/components/ui/dialog` | `Dialog` (`open`, `onOpenChange`), `DialogTrigger`, `DialogContent`, `DialogHeader`, `DialogTitle`, `DialogDescription`, `DialogFooter` |
| Badge | `@/components/ui/badge` | `variant`: `default`, `secondary`, `destructive`, `outline`, `ghost`, `link` |

- `open` and `onOpenChange` are props of the underlying primitive's dialog root. Both Base UI (`Dialog.Root`) and Radix UI (`Dialog.Root`) define them.
- Base UI composes a part with another element through a `render` prop. Radix UI uses `asChild`. Copied component code and examples differ accordingly between the two bases.

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

- Keyboard navigation, focus management and ARIA attributes come from the primitive library the project's base uses (Base UI, Radix UI or React Aria), not from shadcn/ui's own code.
- Example, Radix UI Dialog: follows the WAI-ARIA Dialog pattern, traps focus when modal, and closes on Escape without extra code.
- Example, Base UI Dialog: `modal` defaults to `true`, which traps focus, locks page scroll and disables pointer interaction outside the dialog; Escape requests close and is reported to `onOpenChange` with the reason `escape-key`.
- The equivalent behaviour of the React Aria base (unverified: its component pages were not checked).
- This covers the primitives only. Markup composed around them gets no accessibility behaviour from the primitive library.

## Tailwind CSS underneath

Statements in this section apply to Tailwind CSS v4 (current major, 4.3.5 checked) unless marked v3. In v4, configuration is written in CSS; a `tailwind.config.js` is not detected automatically and is loaded only through an explicit `@config "<path>";` directive. shadcn/ui supports both: `tailwind.config` in `components.json` is blank for v4 and holds the config path for v3.

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
- v4: by default `dark:` follows the `prefers-color-scheme` media feature. Class-based dark mode is configured in the CSS file by overriding the variant, and toggled with `<html class="dark">`:

```css
@import "tailwindcss";
@custom-variant dark (&:where(.dark, .dark *));
```

- v4: there is no `darkMode` key to set; the Tailwind v4 dark mode documentation does not mention `tailwind.config.js`.
- v3 only: class-based dark mode is configured with `darkMode: 'selector'` in `tailwind.config.js` (`'selector'` replaced `'class'` in v3.4.1) and toggled with `<html class="dark">`.
- A shadcn/ui project on v4 declares the variant in its global stylesheet as `@custom-variant dark (&:is(.dark *));`.
- In a Next.js project the shadcn/ui documentation sets the class with `next-themes`: a `ThemeProvider` with `attribute="class"`, `defaultTheme="system"`, `enableSystem` and `disableTransitionOnChange`, and `suppressHydrationWarning` on the `<html>` tag.

### Theme tokens in a shadcn/ui project

- With `tailwind.cssVariables: true` (the default), components use semantic tokens instead of palette classes: `bg-background`, `text-foreground`, `bg-primary text-primary-foreground`.
- Token values are CSS custom properties defined in the global stylesheet under `:root` (light) and `.dark` (dark), in `oklch()` format. An `@theme inline` block maps each one to a Tailwind colour so that the utility exists. The stylesheet begins with `@import "tailwindcss";` and `@import "shadcn/tailwind.css";`.

```css
:root {
  --radius: 0.625rem;
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
}
```

- Each surface token has a `-foreground` partner for text and icons on it. The token names are `background`, `foreground`, `card`, `popover`, `primary`, `secondary`, `muted`, `accent` (each with `-foreground`), `destructive`, `border`, `input`, `ring`, `chart-1` to `chart-5`, the `sidebar` group, and `radius`.
- A token that is defined under `:root` and `.dark` but not mapped in `@theme inline` as `--color-<name>` produces no utility class.
- Because the `.dark` block redefines the tokens, a token class such as `bg-background` changes in dark mode without a `dark:` counterpart. Palette classes such as `bg-white` do not, and need one.
- v3 only: tokens are mapped to colours in `theme.extend.colors` in `tailwind.config.js`, not in `@theme`.

### Breakpoints

Breakpoints are mobile-first: an unprefixed class applies at every width, a prefixed class applies from that width up. The defaults are the same in v3 and v4; v4 defines them in `rem`.

| Prefix | Min width |
| --- | --- |
| `sm:` | 40rem (640px) |
| `md:` | 48rem (768px) |
| `lg:` | 64rem (1024px) |
| `xl:` | 80rem (1280px) |
| `2xl:` | 96rem (1536px) |

```typescript
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
```

- v4: a breakpoint is changed or added with a `--breakpoint-*` variable inside `@theme` in the CSS file (for example `--breakpoint-3xl: 120rem;`). v3 only: in `theme.screens` in `tailwind.config.js`.

### Arbitrary values

- Arbitrary values go in square brackets: `bg-[rgb(250,250,249)]`.
- A space inside the brackets is read as a class separator and breaks the class. An underscore stands for the space and is converted to a space at build time: `grid-cols-[1fr_2fr]`.
- An underscore is kept where a space would be invalid, such as inside `url()`. A literal underscore elsewhere is written `\_`.
- v4: a CSS variable can be referenced with parentheses, `fill-(--my-brand-color)`, which is shorthand for `fill-[var(--my-brand-color)]`.

### Typography plugin

- `npm install -D @tailwindcss/typography` provides the `prose` classes for long-form content. Version 0.5.20 supports Tailwind v3 and v4.
- Installing the package is not enough; the plugin has to be loaded. v4: `@plugin "@tailwindcss/typography";` in the main CSS file, after `@import "tailwindcss";`. v3 only: `require('@tailwindcss/typography')` in the `plugins` array of `tailwind.config.js`.
- `prose prose-zinc dark:prose-invert max-w-none` gives readable document styling with a dark variant and no width cap. The grey scales are `prose-gray` (default), `prose-slate`, `prose-zinc`, `prose-neutral` and `prose-stone`.
- Element modifiers adjust single elements: `prose-headings:font-semibold`, `prose-h2:mt-10 prose-h2:border-t prose-h2:pt-8`, `prose-p:leading-relaxed`, `prose-li:leading-relaxed`.

## External documentation

- shadcn/ui: https://ui.shadcn.com/
- Tailwind CSS: https://tailwindcss.com/ (v3: https://v3.tailwindcss.com/)
- Base UI: https://base-ui.com/
- Radix UI primitives: https://www.radix-ui.com/primitives

## Validation notes (2026-11-18)

- Sources:
  - https://ui.shadcn.com/docs
  - https://ui.shadcn.com/docs/installation/next
  - https://ui.shadcn.com/docs/cli
  - https://ui.shadcn.com/docs/components-json
  - https://ui.shadcn.com/docs/theming
  - https://ui.shadcn.com/docs/dark-mode/next
  - https://ui.shadcn.com/docs/changelog and its entries "Base UI as the Default" (July 2026) and "shadcn/cli v4" (March 2026)
  - https://ui.shadcn.com/docs/components/radix/button, `/radix/badge`, `/radix/card`, `/radix/dialog`, and `/base/dialog`
  - https://base-ui.com/react/components/dialog
  - https://www.radix-ui.com/primitives/docs/components/dialog
  - https://tailwindcss.com/docs/dark-mode
  - https://tailwindcss.com/docs/responsive-design
  - https://tailwindcss.com/docs/adding-custom-styles
  - https://tailwindcss.com/docs/functions-and-directives
  - https://tailwindcss.com/docs/upgrade-guide
  - https://v3.tailwindcss.com/docs/dark-mode
  - https://github.com/tailwindlabs/tailwindcss-typography
  - `npm view` for `shadcn`, `shadcn-ui`, `tailwindcss` and `@tailwindcss/typography` (versions, dist-tags, deprecation, peer dependencies)
- Corrected:
  - "built on Radix UI and Tailwind CSS" -> built on Tailwind CSS and one of three bases (Base UI, Radix UI, React Aria); Base UI is the default for new projects since July 2026.
  - Accessibility "the components use Radix UI primitives" -> behaviour comes from the project's base; Radix UI and Base UI Dialog behaviour stated separately.
  - Install commands confirmed; added that `shadcn-ui` is unsupported on npm, the `init` options (`--base`, `--template`, `--preset`, `--no-css-variables`), and what `components.json` contains.
  - Button `variant` list `default, destructive, outline, ghost` -> also `secondary`, `link`; `size` values added.
  - Badge `variant` list `default, secondary, destructive` -> also `outline`, `ghost`, `link`.
  - Card parts -> added `CardDescription`, `CardAction`, `CardFooter` and the `size` prop. Dialog parts -> added `DialogTrigger`, `DialogDescription`, `DialogFooter`.
  - Dark mode "`darkMode: 'class'` in `tailwind.config.js`" -> v4: `@custom-variant dark (...)` in CSS, default is `prefers-color-scheme`; v3: `darkMode: 'selector'` (replaced `'class'` in v3.4.1).
  - Breakpoint table -> same pixel widths, now stated in `rem` as v4 defines them; customisation through `--breakpoint-*` in `@theme`.
  - Typography plugin "`npm install` provides the `prose` classes" -> the plugin must also be loaded: `@plugin` in CSS for v4, `plugins` array for v3.
  - Added a "Theme tokens in a shadcn/ui project" subsection (CSS variables under `:root`/`.dark`, `@theme inline`, `oklch`), needed to make the dark mode claims correct for token classes.
- Still unverified:
  - The exact `style` value and the base field in a `components.json` written by CLI 4.23.0: the CLI could not be run in this check, and the fetched `components.json` page does not state it.
  - CLI option lists come from the CLI documentation page, not from `npx shadcn@latest --help` output, for the same reason.
  - Accessibility behaviour of the React Aria base: its component pages were not checked.
  - Component variants and parts were checked on the Radix UI documentation pages only (Dialog parts also on the Base UI page); the Base UI and React Aria Button, Badge and Card pages were not compared.
  - The illustrative folders `dashboard/` and `workspace/` are a project convention with no primary source.
