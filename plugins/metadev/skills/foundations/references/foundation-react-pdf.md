# Foundation: @react-pdf/renderer

- **Last validated:** not re-validated since February 2026 (carried over from `skills/frontend-patterns/references/frontend-patterns.md`)
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** what the library is for, installation and bundle size, the document API, generating a blob in the browser and downloading it, styling differences from web CSS, fonts, repeated headers and footers, page numbers.
- **Does not cover:** server-side PDF rendering, browser print CSS, canvas or screenshot approaches, how to load the library on demand (see `foundation-nextjs-app-router.md`, "Code splitting").

## What it is for

| Fits | Does not fit |
| --- | --- |
| Exported documents (reports, memos, invoices) | Printing an existing page as it looks (browser print CSS does this) |
| Printable output with its own formatting | Screenshots (canvas-based approaches do this) |
| Multi-page documents with headers and footers | |

- It generates PDFs in the browser from React components.

## Installation and size

```bash
npm install @react-pdf/renderer
```

- Bundle size is about 400KB gzipped (unverified).

## Document API

- A document is built from `Document`, `Page`, `View` and `Text`. Styles are created with `StyleSheet.create`.
- `Page` takes a `size` such as `'A4'`. A4 is the standard page size for international business documents.
- Sizes are in points: `padding: 72` is a one-inch margin.
- `pdf(doc).toBlob()` returns the finished PDF as a Blob.
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
| Flexbox `gap` | Not supported; spacing is done with margins on the items (unverified: newer releases may support `gap`) |
| CSS Grid | Not supported |

```typescript
// Not supported:
const styles = StyleSheet.create({
  container: { display: 'flex', gap: 16 },
});

// Supported:
const styles = StyleSheet.create({
  container: { display: 'flex' },
  item: { marginBottom: 16 },
});
```

## Fonts

- Built-in fonts: Helvetica, Times-Roman, Courier. They need no embedding. Bold is a separate family name, for example `Helvetica-Bold`.
- Helvetica has been sufficient for executive-style business documents without any custom font.
- A custom font is registered from a file and then used by family name:

```typescript
import { Font } from '@react-pdf/renderer';

Font.register({
  family: 'CustomFont',
  src: '/fonts/custom-font.ttf',
});

const styles = StyleSheet.create({
  text: { fontFamily: 'CustomFont' },
});
```

## Headers, footers and page numbers

- An element with the `fixed` prop is repeated on every page. Elements without it flow across pages.
- A `Text` with a `render` function receives `pageNumber` and `totalPages`.

```typescript
createElement(Page, { size: 'A4', style: styles.page },
  // Header (repeats on all pages)
  createElement(View, { style: styles.header, fixed: true },
    createElement(Text, 'Company name'),
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

- The library does not render markdown. Markdown has to be parsed into structured elements (headings, paragraphs, lists) and each element mapped to a PDF component.

## External documentation

- @react-pdf/renderer: https://react-pdf.org/
