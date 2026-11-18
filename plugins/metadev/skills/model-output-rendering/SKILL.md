---
name: model-output-rendering
description: Rendering markdown or structured output that comes from a model or an API - a markdown renderer with document-quality styling, element overrides, and a visible fallback for types the UI does not know. Use when a view displays generated text, documents, or typed blocks whose format the frontend does not control.
user-invocable: false
---

# Model output rendering

A good outcome is generated content that reads like a designed document, and a renderer that still shows something useful when the format of that content changes.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-shadcn-ui.md` (plugin, `foundations` skill) | The Tailwind typography plugin (`prose` classes and element modifiers), dark mode variants |
| `foundation-react-pdf.md` (plugin, `foundations` skill) | Only if the same content is also exported as PDF: markdown has to be parsed and mapped there separately |
| Project `knowledge/foundations/foundation-brand.md` | The type scale and colours the rendered document should use |

## Required context

- What the content is and where it comes from: a markdown string, a list of typed blocks, or both (required).
- The set of types or elements the source can produce today, and whether that set is expected to grow (required).
- Real samples of the output, including the longest and the messiest available (required).
- How the design wants the content to look: section dividers, code blocks, tables (required).
- Whether the content streams in or arrives complete (optional).

## Approach

1. **Establish what you are rendering.** Collect real samples before writing the renderer. The format of model output is not under the frontend's control and can change without a frontend deploy, so treat the list of known types as incomplete from the start.

2. **Render markdown with a markdown renderer.** Use `react-markdown` with `remark-gfm`. GFM adds tables, task lists, strikethrough and autolinks, all of which models produce.

   ```bash
   npm install react-markdown remark-gfm
   ```

   ```typescript
   import ReactMarkdown from 'react-markdown';
   import remarkGfm from 'remark-gfm';

   <ReactMarkdown remarkPlugins={[remarkGfm]}>
     {markdownContent}
   </ReactMarkdown>
   ```

3. **Give it document typography with prose classes.** Wrap the renderer in an element with the typography plugin's `prose` classes and adjust elements with modifiers. The plugin must be loaded or the classes do nothing: `@plugin "@tailwindcss/typography";` in the CSS file on Tailwind v4, the `plugins` array on v3. This gets consistent headings, spacing and line height without styling every element by hand.

   ```typescript
   <article className="
     prose prose-zinc dark:prose-invert max-w-none
     prose-headings:font-semibold
     prose-h2:mt-10 prose-h2:border-t prose-h2:pt-8
     prose-p:leading-relaxed
     prose-li:leading-relaxed
   ">
     <ReactMarkdown>{content}</ReactMarkdown>
   </article>
   ```

   A top border on `h2` turns second-level headings into section dividers, which suits long generated documents.

4. **Override single elements where prose is not enough.** Pass `components` to replace an element with your own markup. Code is the usual case: block code needs horizontal scrolling so long lines do not widen the page, and inline code needs a different treatment from block code.

   ```typescript
   <ReactMarkdown
     remarkPlugins={[remarkGfm]}
     components={{
       h2: ({ children }) => (
         <h2 className="mt-10 border-t border-zinc-200 pt-8 text-2xl font-semibold">
           {children}
         </h2>
       ),
       code: ({ node, inline, className, children, ...props }) => {
         return !inline ? (
           <pre className="overflow-x-auto rounded-lg bg-zinc-900 p-4">
             <code className={className} {...props}>{children}</code>
           </pre>
         ) : (
           <code className="rounded bg-zinc-100 px-1 py-0.5 text-sm" {...props}>
             {children}
           </code>
         );
       },
     }}
   >
     {content}
   </ReactMarkdown>
   ```

   The `inline` prop on `code` depends on the installed `react-markdown` version (unverified for current releases). Check that inline and block code are told apart in the version the project uses.

5. **For typed or structured output, map each type to a renderer and add a fallback.** Every renderer of model or API output needs a branch for a type it does not recognise. The fallback must render something visible, such as the raw content in a plain block, and must not throw or render nothing. Without it, a format change upstream stalls the page silently and nobody is told.

6. **Keep other output targets in step.** If the same content is exported elsewhere (for example as PDF), that target has its own mapping from parsed elements to components. A new element type has to be handled in both, or fall back in both.

7. **Test with the real samples.** Render the longest sample, one with a table, one with a task list, one with a code block with a long line, and one deliberately containing an unknown type. Check at 375px and, if the project has it, in dark mode. Verify before reporting done, following the `team-standards` skill.

## Done means

- Real samples render with headings, lists, tables, task lists and code blocks all styled.
- A sample with an unknown type or element renders visible fallback content, and the page stays usable with no error in the console.
- A code block with a long line scrolls inside its block; the page does not scroll horizontally at 375px.
- Tables stay readable at 375px.
- In dark mode, text and code backgrounds keep readable contrast.
- If the content is also exported, the export of the same samples contains the same sections.

## Anti-patterns

- **No fallback for unknown types.** A renderer that handles only the types known today breaks, or silently shows nothing, on the day the model or API adds one. Always have a default branch that shows the content.
- **A fallback that renders nothing.** Returning `null` for an unknown type hides the problem. Show the raw content so the user gets the information and the team sees the gap.
- **Parsing markdown by hand with string operations.** It handles the samples you tried and fails on the next one. Use the renderer.
- **Leaving out GFM.** Tables and task lists then appear as raw pipes and brackets.
- **Styling every element individually when prose classes would do.** It takes longer and drifts from the type scale. Use prose, then override the few elements that need it.
- **Testing only with a short, clean sample.** Generated content is long and irregular. Test with the longest and messiest real output available.
- **Updating the on-screen renderer and leaving the export behind.** The exported document then drops the new element.
