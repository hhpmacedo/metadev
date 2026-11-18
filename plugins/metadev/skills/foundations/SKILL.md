---
name: foundations
description: Index of the team's dated facts about tools and platforms (Supabase, the Supabase CLI, Vercel, the Vercel AI SDK, Next.js App Router, shadcn/ui and Tailwind, react-pdf, GitHub Actions, Playwright) and the rules for using a foundation. Preloaded into every team agent; read the matching reference file when a task depends on how one of these tools behaves.
user-invocable: false
---

# Foundations

A foundation is a set of claims about how something is, with a date. It tells you what is true; it never tells you what to do. Techniques tell you what to do and name the foundations they rely on.

## Using one

- Read the file for the tool your task touches, not all of them.
- Check its "Last validated" line first. Every file here was carried over from older material and has **not been re-validated since February 2026**. Treat versions, limits, prices, flags and command names as likely to have moved.
- A claim marked "(unverified)" was already doubted when it was carried over. Check it against the tool's current documentation or a real call before you depend on it.
- If you find a claim is wrong, say so in your report with what you observed. Do not silently work around it; the file needs correcting.
- Facts about the product you are working on (its users, brand, infrastructure, data) are not here. They are in the project's own `knowledge/foundations/`, described in `team-standards`.

## Index

| File in `references/` | Covers |
| --- | --- |
| `foundation-supabase.md` | Database and indexing, keys and clients, row-level security, storage, auth defaults, query behaviour, transactions, plan limits, connection variables |
| `foundation-supabase-cli.md` | Running the CLI, linking, migration commands and history, storage bucket commands |
| `foundation-vercel.md` | CLI, project configuration, deployments and previews, protected URLs and aliases, variable scopes, function time limits |
| `foundation-vercel-ai-sdk.md` | The step limit required in tool-calling pipelines |
| `foundation-nextjs-app-router.md` | Route groups, dynamic parameters, server and client components, code splitting, route handlers, public variables |
| `foundation-shadcn-ui.md` | What it is, installation, structure, components and variants, accessibility, Tailwind underneath |
| `foundation-react-pdf.md` | Use cases, document API, styling differences from web CSS, fonts, headers and footers |
| `foundation-github-actions.md` | Workflow structure, triggers, path filters, build-check and scheduled-check jobs |
| `foundation-playwright.md` | Browser tool names, prompts and dialogs, session injection, signs of a stalled browser, viewport widths |

## Adding or correcting one

- Declarative only. If a line starts telling the reader what to do, it belongs in a technique.
- State limits and known problems, not only what works.
- Update "Last validated" with the date and how it was checked, only for the claims you actually checked.
- Nothing about a specific product, client or person. Those facts live with the project.
