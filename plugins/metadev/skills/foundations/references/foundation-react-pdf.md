# Foundation: @react-pdf/renderer

- **Last validated:** 2026-11-18, checked against the react-pdf documentation (react-pdf.org and its source repository), the react-pdf repository changelogs, and the published `@react-pdf/renderer` 4.9.0 package (type definitions, peer dependencies) by an automated documentation check. Not yet confirmed in a live project.
- **Versions checked:** `@react-pdf/renderer` 4.9.0 (npm `latest`), with `@react-pdf/layout` 5.2.0, `@react-pdf/font` 4.1.2, `@react-pdf/stylesheet` 6.3.2
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** what the library is for, installation, bundle size and compatibility, the document API, generating a blob in the browser and downloading it, styling differences from web CSS, fonts, repeated headers and footers, page numbers.
- **Does not cover:** server-side PDF rendering, browser print CSS, canvas or screenshot approaches, how to load the library on demand (see `foundation-nextjs-app-router.md`, "Code splitting").

## What it is for

| Fits | Does not fit |
| --- | --- |
| Exported documents (reports, memos, invoices) | Printing an existing page as it looks (browser print CSS does this) |
| Printable output with its own formatting | Screenshots (canvas-based approaches do this) |
| Multi-page documents with headers and footers | |

- It generates PDFs from React components, in the browser and on the server (Node). This file covers browser generation.

## Installation and size

```bash
npm install @react-pdf/renderer
```

- Bundle size of 4.9.0 is about 442 kB minified and gzipped (1.2 MB minified), as measured by Bundlephobia (https://bundlephobia.com/package/@react-pdf/renderer@4.9.0). The project documentation states no figure.

## Compatibility

- React: the peer dependency range of 4.9.0 is `^16.8.0 || ^17.0.0 || ^18.0.0 || ^19.0.0`. React 19 is supported since 4.1.0.
- Next.js: the documentation states the library works with Next.js "regardless of the version", with one exception: before Next.js 14.1.1 the App Router server crashed with `TypeError: ba.Component is not a constructor`. Next.js 14.1.1 or later does not have this bug.
- `PDFViewer`, `PDFDownloadLink`, `BlobProvider` and `usePDF` are web-only. Called from the Node build of the package they throw "is a web specific API". In a Next.js App Router project they therefore run only in client code.
- `pdf(doc).toBlob()` is documented under "On the fly rendering", which is marked web only. On Node the documented functions are `renderToFile`, `renderToString`, `renderToBuffer` and `renderToStream`.

## Document API

- A document is built from `Document`, `Page`, `View` and `Text`. Styles are created with `StyleSheet.create`.
- `Page` takes a `size` such as `'A4'`; `'A4'` is the default when `size` is omitted. A4 is the standard page size for international business documents.
- Unitless sizes are in points (`pt`, 72 per inch): `padding: 72` is a one-inch margin. Other valid units are `in`, `mm`, `cm`, `%`, `vw` and `vh`.
- `pdf(doc).toBlob()` returns a Promise that resolves to the finished PDF as a Blob.
- The document can be built with `createElement`, so the module can be a plain `.ts` file.

```typescript
// lib/pdf-export.ts
import { Document, Page, Text, View, StyleSheet, pdf } from '@react-pdf/renderer';
import { createElement } from 'react';

const styles = StyleSheet.create({
  page: {
    padding: 72,  // 1 inch margins
    fontFamily: 'Helvetica',
    fontSize: 11,
  },
  title: {
    fontSize: 24,
    fontFamily: 'Helvetica-Bold',
    marginBottom: 12,
  },
  paragraph: {
    marginBottom: 8,
    lineHeight: 1.6,
  },
});

function MyDocument({ title, content }: { title: string; content: string }) {
  return createElement(Document, {},
    createElement(Page, { size: 'A4', style: styles.page },
      createElement(Text, { style: styles.title }, title),
      createElement(Text, { style: styles.paragraph }, content),
    )
  );
}

export async function generatePdf(data: any) {
  const doc = createElement(MyDocument, data);
  const blob = await pdf(doc).toBlob();

  // Trigger browser download
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = 'document.pdf';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
```

## Styling differences from web CSS

| Web CSS | In @react-pdf/renderer |
| --- | --- |
| Flexbox | Supported |
| Flexbox `gap`, `rowGap`, `columnGap` | Supported since `@react-pdf/renderer` 3.1.0 (implemented in `@react-pdf/layout` 3.3.0). Percentage values are accepted from `@react-pdf/layout` 4.3.0. |
| CSS Grid | Not supported. `display` accepts only `flex` and `none`. |

```typescript
// Supported:
const styles = StyleSheet.create({
  container: { display: 'flex', gap: 16 },
});

// Not supported (no grid layout):
const styles = StyleSheet.create({
  container: { display: 'grid', gridTemplateColumns: '1fr 1fr' },
});
```

## Fonts

- Built-in fonts are three families: Courier, Helvetica and Times-Roman. They need no registration. Each variant is a separate family name:

| Family | Variants |
| --- | --- |
| `Courier` | `Courier-Bold`, `Courier-Oblique`, `Courier-BoldOblique` |
| `Helvetica` | `Helvetica-Bold`, `Helvetica-Oblique`, `Helvetica-BoldOblique` |
| `Times-Roman` | `Times-Bold`, `Times-Italic`, `Times-BoldItalic` |

- Helvetica has been sufficient for executive-style business documents without any custom font. (unverified: team experience, not a documented fact)
- A custom font is registered with `Font.register` and then used by family name. `src` is a URL in the browser, or an absolute file path on Node. Only TTF and WOFF files are supported. OpenType variable fonts do not render correctly; each weight is registered as a separate static file.
- `Font.register` takes `family`, `src`, and optional `fontStyle` (`normal`, `italic`, `oblique`) and `fontWeight` (a name from `thin` to `heavy`, or a number). Several variants of one family are registered either by calling it once per variant or by passing a `fonts` array of `{ src, fontStyle, fontWeight }`. When the requested weight is not registered, the nearest registered weight is used.

```typescript
import { Font } from '@react-pdf/renderer';

Font.register({
  family: 'CustomFont',
  fonts: [
    { src: '/fonts/custom-font-regular.ttf' },
    { src: '/fonts/custom-font-bold.ttf', fontWeight: 'bold' },
  ],
});

const styles = StyleSheet.create({
  text: { fontFamily: 'CustomFont' },
});
```

## Headers, footers and page numbers

- An element with the `fixed` prop is repeated on every page. Elements without it flow across pages.
- A `Text` with a `render` function receives `pageNumber`, `totalPages`, `subPageNumber` and `subPageTotalPages`. `View` also accepts `render`, but receives only `pageNumber` and `subPageNumber`. The function is called twice for `Text`: once during layout and once after the total page count is known.

```typescript
createElement(Page, { size: 'A4', style: styles.page },
  // Header (repeats on all pages)
  createElement(View, { style: styles.header, fixed: true },
    createElement(Text, null, 'Company name'),
  ),

  // Content (flows across pages)
  ...contentElements,

  // Footer with page numbers (repeats on all pages)
  createElement(Text, {
    style: styles.footer,
    fixed: true,
    render: ({ pageNumber, totalPages }) => `${pageNumber} / ${totalPages}`,
  }),
)
```

## Markdown content

- The library has no markdown component. Markdown has to be parsed into structured elements (headings, paragraphs, lists) and each element mapped to a PDF component.

## External documentation

- @react-pdf/renderer: https://react-pdf.org/
- Repository: https://github.com/diegomura/react-pdf

## Validation notes (2026-11-18)

- Sources:
  - https://react-pdf.org/styling, https://react-pdf.org/fonts, https://react-pdf.org/compatibility, https://react-pdf.org/components, https://react-pdf.org/advanced (read from the site's source repository, https://github.com/diegomura/react-pdf-site, `docs/*.md`, last commit 2026-08-27)
  - https://github.com/diegomura/react-pdf: `README.md`, `packages/renderer/CHANGELOG.md`, `packages/layout/CHANGELOG.md`, `packages/layout/src/page/getSize.ts`
  - `npm view @react-pdf/renderer version peerDependencies dependencies`; package contents of `@react-pdf/renderer` 4.9.0 (`index.d.ts`, `lib/react-pdf.js`), `@react-pdf/font` 4.1.2, `@react-pdf/layout` 5.2.0, `@react-pdf/stylesheet` 6.3.2
  - https://bundlephobia.com/package/@react-pdf/renderer@4.9.0 (bundle size only)
- Corrected:
  - "Flexbox `gap`: not supported; spacing is done with margins" -> `gap`, `rowGap` and `columnGap` are supported since 3.1.0. The code example was reversed accordingly.
  - "Bundle size is about 400KB gzipped (unverified)" -> about 442 kB minified and gzipped for 4.9.0 (Bundlephobia).
  - "It generates PDFs in the browser" -> in the browser and on the server.
  - "Built-in fonts: Helvetica, Times-Roman, Courier ... Bold is a separate family name" -> the full list of twelve names, including the Times variants `Times-Bold`, `Times-Italic`, `Times-BoldItalic`.
  - `Font.register({ family, src })` only -> also `fontStyle`, `fontWeight` and the `fonts` array; TTF and WOFF only; no variable fonts.
  - "A `Text` with a `render` function receives `pageNumber` and `totalPages`" -> four arguments for `Text`; `View` gets no totals; called twice.
  - `createElement(Text, 'Company name')` in the header example -> `createElement(Text, null, 'Company name')` (the second argument of `createElement` is props).
  - "`pdf(doc).toBlob()` returns ... a Blob" -> returns a Promise of a Blob.
  - Added, to make existing claims safe: React peer range (React 19 since 4.1.0), the Next.js App Router bug before 14.1.1, which APIs are web-only, valid units, `'A4'` as default page size.
- Still unverified:
  - Whether `pdf(doc).toBlob()` works outside the browser: the documentation lists it under a web-only heading; not run.
  - Behaviour with the current Next.js major (16.x) and with React Server Components beyond what the compatibility page states: the page names only the pre-14.1.1 bug; not run.
  - "Helvetica has been sufficient for executive-style business documents" is team experience, not a documented fact.
  - The bundle size figure comes from a third-party measurement, not from the project.
