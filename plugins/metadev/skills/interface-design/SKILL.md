---
name: interface-design
description: How to design a user flow or screen - the happy path and its edge cases, information and action hierarchy, forms and lists, the words on the screen, every state, accessibility, and command-line output. Use when designing a flow or interface, writing a design spec, or reviewing a built interface.
user-invocable: false
---

# Interface design

A good design lets the user see at once what they can do, tells them what happened after every action, and has been thought through for the empty, loading and error states as well as the full one.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| Project design system (tokens, components) or the project's `knowledge/foundations/` entry for it | What already exists, so that you extend it before adding anything new |

If the project has no documented design system, read the existing screens and components and treat them as the system.

## Required context

- The requirement and the user's goal for this flow (required).
- The existing product screens and components this sits beside (required when extending a product).
- The real content: actual labels, messages and representative data (required; placeholder copy hides design problems).
- The medium: web, mobile or command line (required).

## Approach

1. **Design the happy path first.** The user arrives with a goal, takes the minimum steps to achieve it, sees a clear indication of success, and is offered a natural next action. Write it down:

   ```
   Goal: [What user wants to achieve]

   Steps:
   1. [Entry point] → User sees [what]
   2. [Action] → System responds with [what]
   3. [Decision point] → Options: A, B
   4. [Completion] → User knows success because [what]

   Edge cases:
   - If [condition], then [handling]
   ```

2. **Then handle what can go wrong.** Invalid input gets clear guidance to fix it. System errors get a helpful message. Unexpected states are handled gracefully. Prevention is better than recovery: prevent mistakes before they happen, confirm destructive actions, and make undo easy where possible.

3. **Design every state.** Do the empty, loading and error states before the full one; they are what users meet first. Every action has visible feedback, so the user never wonders whether it worked.

4. **Set the hierarchy.**
   - Information: the most important information is the most prominent. Group related items. Use whitespace to separate concepts. Visual weight guides attention.
   - Actions: one primary action per screen, and it is the most prominent. Secondary actions are less prominent. Destructive actions require confirmation.
   - Show only what is needed at each step and keep advanced options hidden until needed. This reduces cognitive load.

5. **Prefer familiar patterns.** Clarity beats cleverness. If you need to explain it, simplify it. Extend the product's existing tokens and components before adding new ones.

6. **Apply the standard patterns for forms and lists.**
   - Forms: label above the input, not placeholder text. Validate on blur, not while typing. Show requirements up front. The submit button names the action ("Save Profile", not "Submit").
   - Tables and lists: sortable columns for comparison, filters for finding, pagination or infinite scroll for large sets, and a clear empty state.

7. **Write the real words.**
   - Buttons use verbs and are specific: "Create Project", not "OK". The label matches what happens.
   - Error messages say what failed and what to do. "Error 500" is bad. "Something went wrong. Please try again." is better. "Couldn't save your changes. Check your connection and try again." is best.
   - Empty states explain why it is empty and point to the action that fills it: "No projects yet. Create your first project to get started."
   - Confirmations state the action taken ("Project created"), say what happens next if relevant, and give a path to view or undo.

8. **Build accessibility into the design.**
   - Visual: colour contrast of at least 4.5:1 for text, no meaning carried by colour alone, text that can be resized.
   - Keyboard: every action reachable, logical tab order, visible focus states.
   - Screen readers: meaningful alt text, semantic HTML structure, ARIA labels where needed.

9. **For a command-line interface, design the output.**
   - Concise by default, verbose on request. Clear indication of success or failure. Structured output where something will parse it.
   - Show that something is happening during long operations, show progress if it can be determined, and allow cancellation.
   - Errors give a clear message and actionable guidance, and set an exit code for scripting.

## Done means

- The flow is written down with its goal, steps, decision points, success indication and edge cases.
- Each screen has exactly one primary action that can be pointed to.
- Empty, loading, error and success states are specified for every screen that loads or changes data.
- All copy in the spec is real, including button labels, error messages and empty states.
- Text contrast is at least 4.5:1 (measure it), the flow can be completed by keyboard alone, and focus is visible.
- Every new token or component is listed with the reason an existing one would not do.
- Destructive actions have a confirmation or an undo.

## Anti-patterns

- **Designing only the full state.** The first thing a new user sees is the empty one.
- **Placeholder copy.** Real words change the layout and expose unclear steps.
- **Placeholder text used as the label.** It disappears when the user types.
- **Validating while the user is typing.** It reports errors before they have finished.
- **Generic buttons and errors.** "OK", "Submit" and "Error 500" tell the user nothing.
- **Two competing primary actions on one screen.**
- **A novel pattern where a familiar one works.**
- **Accessibility left for later.** It is part of the design, not a pass at the end.
