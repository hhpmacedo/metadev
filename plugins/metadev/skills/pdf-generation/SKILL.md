---
name: pdf-generation
description: Adding a PDF export of documents from the browser - deciding whether a PDF library is needed, building the document module, loading it on demand, mapping content to PDF components, and checking the result. Use when a feature needs a downloadable, formatted PDF such as a report, memo or invoice.
user-invocable: false
---

# PDF generation

A good outcome is a correctly formatted, multi-page PDF that downloads on request, from a library that no visitor pays for until they ask for an export.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-react-pdf.md` (plugin, `foundations` skill) | The document API, blob download, styling differences from web CSS, built-in fonts, fixed headers and footers, page numbers, bundle size |
| `foundation-nextjs-app-router.md` (plugin, `foundations` skill) | How `import()` splits a module out of the initial bundle |

## Required context

- What is being exported and from which data: the fields, and whether the body is markdown or structured content (required).
- What the document should look like: page size, margins, header, footer, page numbers (required; if not specified, use A4 with one-inch margins).
- Where the export is triggered in the UI (required).
- Whether brand fonts are a requirement (optional; default is the built-in fonts).
- Real samples of the content, including the longest one (required).

## Approach

1. **Check that a PDF library is the right tool.** It fits exported documents with their own formatting, and multi-page documents with headers and footers. If the need is to print an existing page as it looks, use browser print CSS. If the need is a screenshot, use a canvas-based approach. Do not add the library for those.

2. **Put all PDF code in one module.** Create a single module (for example `lib/pdf-export.ts`) that imports the library, defines the styles and the document, and exports one function that takes the data and triggers the download. No other file imports the library. This is what makes on-demand loading possible in step 6.

3. **Start with built-in fonts.** Use Helvetica (or Times-Roman or Courier) for the first version. They need no embedding and are sufficient for business documents. Register a custom font only when brand fonts are a stated requirement.

4. **Lay out with flexbox.** Do not carry web styles across. `gap` is supported; CSS Grid is not. Check the foundation for what else the library does not support. Use `fixed` elements for the header and footer and a `render` function for page numbers.

5. **Map the content to PDF components.** The library does not render markdown. Parse markdown into structured elements (headings, paragraphs, lists) and map each element type to a PDF component with its own style. Give unknown element types a plain-text fallback so content is never dropped from the export.

6. **Load the module on demand from the trigger.** Import the module dynamically inside the click handler, with a pending flag, error handling and user feedback.

   ```typescript
   const handleExport = async () => {
     setIsExporting(true);
     try {
       const { generatePdf } = await import('@/lib/pdf-export');
       await generatePdf(item);
       toast.success('PDF downloaded');
     } catch (err) {
       toast.error('Failed to export PDF');
     } finally {
       setIsExporting(false);
     }
   };
   ```

7. **Format dates for the reader's calendar day.** Dates printed in the document or used in the filename should be built from local date parts (`getFullYear()`, `getMonth() + 1`, `getDate()`, zero-padded). `toISOString()` returns UTC and can shift the day.

8. **Check the result with real content.** Export the longest real sample and open the file. Look at page breaks, the header and footer on every page, page numbers, lists and headings. Then reload the page with the network tab open and confirm the library is requested only when the export button is clicked. Verify before reporting done, following the `team-standards` skill.

## Done means

- Clicking export downloads a PDF that opens in a standard viewer.
- A document long enough to span several pages shows the header and footer on every page and correct `page / total` numbers.
- Headings, paragraphs and lists from the source content all appear in the PDF, in order, with nothing dropped.
- The network tab shows no request for the PDF library on initial page load, and shows one when export is clicked.
- When generation fails, the user sees an error message and the export button is enabled again.
- Dates in the document match the dates shown in the UI.

## Anti-patterns

- **Importing the PDF library statically.** It is large, and a static import anywhere on the initial path ships it to every visitor. Keep it in one module and import that module dynamically.
- **Claiming on-demand loading without checking.** Look at the network tab. The library should appear only after the click.
- **Reusing web styles.** Layout features that work in the browser may not exist in the PDF renderer, and the failure is a wrong layout, not an error. Write PDF styles separately against the foundation.
- **Embedding custom fonts in the first version.** It adds font files, registration and failure modes for little gain. Built-in fonts are enough until brand fonts are required.
- **Passing a markdown string straight into a text element.** The PDF then shows raw markdown syntax. Parse it and map the elements.
- **Testing with a one-page sample.** Page breaks, repeated headers and page numbers only show their problems on a long document.
- **Using a PDF library to print a page.** Browser print CSS does that with no added dependency.
- **Using `toISOString()` for a date in the document or filename.** The day can be off by one for some users.
