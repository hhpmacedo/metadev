---
name: code-implementation
description: How to write a code change so that it reads clearly, fails loudly, is tested, and is handed over in a state the next role can use. Covers naming, function design, error handling, tests alongside the change, comments, organisation and the delivery handoff. Use when writing or reviewing product code.
user-invocable: false
---

# Code implementation

A good change looks like the code around it, does what the acceptance criteria say, fails with a message that helps, and arrives with the tests and instructions QA needs to check it.

## Required foundations

None. Facts about the framework, database or host you are building on are in the plugin's `foundations` skill and the project's `knowledge/foundations/`; read the one for the tool you are touching.

## Required context

- The requirement and its acceptance criteria (required). You verify against these at the end, not against "it builds".
- The design document for the change, if one exists (required when it exists).
- The project's existing conventions: neighbouring files, lint and formatter config, test layout (required).
- Who consumes what you build: a frontend developer reading your API, QA testing your feature (optional, but it decides what you document).

## Approach

1. **Read the surrounding code first and match it.** Consistency beats personal preference. When in doubt, do what the codebase already does. The project's conventions come before anything in this skill.

2. **Solve today's problem.** Do not be clever; be clear. The best code is code you do not write. Three clear lines beat one abstraction with a single caller. Do not build for a hypothetical future requirement.

3. **Name things for the reader.** Code is read far more than it is written.
   - Descriptive names: `userEmail`, not `e`. Avoid abbreviations unless universally understood.
   - Booleans read as questions: `isValid`, `hasPermission`.
   - Functions are verbs: `calculateTotal`, `sendEmail`.
   - A file's name reflects its contents and uses the project's casing.

4. **Give each function one job.**
   - A function that validates, creates, emails, logs and updates metrics should become an orchestrator that calls single-purpose functions.
   - Prefer 0 to 3 parameters. Pass an object when several parameters are related: `createUser({ name, email, role })`, not `createUser(name, email, isAdmin, sendEmail, logAction)`.
   - Avoid boolean flags that change behaviour.
   - Return consistently. Prefer returning a value over a side effect.

5. **Handle errors explicitly.**
   - Never swallow an error. An empty `catch` hides the defect from everyone. Log it with context and rethrow, or return an error type.
   - Fail fast: validate inputs at the top of the function and at system boundaries (user input, API responses), then work with valid data.
   - Write messages that help debugging: `Invalid email format: "${email}"`, not `Invalid input`.

   ```javascript
   try {
     doSomething();
   } catch (error) {
     logger.error('Failed to do something', { error });
     throw new ApplicationError('Operation failed', { cause: error });
   }
   ```

6. **Write the tests with the change.** Cover the happy path, the edge cases (empty inputs, boundaries) and the error cases. Test behaviour, not implementation: assert that an invalid email is rejected, not that a particular validator function was called. Group tests by unit and method (`describe('OrderService')` > `describe('createOrder')`) with names that state the behaviour.

7. **Organise the code.**
   - Group by feature rather than by type, usually. Keep related code close together. Extract shared utilities to a common location.
   - Order imports: standard library, external packages, internal modules, relative imports.
   - If a file passes 200 to 300 lines, consider splitting it. If you cannot name a module clearly, it probably does too much.

8. **Comment the why.** Explain a non-obvious reason, a gotcha, or a deliberate shortcut, and document public interfaces. Do not explain what the code does, do not leave commented-out code, and do not add noise (`// increment counter`).

   ```javascript
   // We use a 5-second timeout because the external API can be slow
   // under load. See incident #123 for context.
   const TIMEOUT_MS = 5000;

   // Intentionally not awaited - fire and forget analytics
   trackEvent('user_signup');
   ```

9. **Apply the language's own idioms.**
   - TypeScript and JavaScript: strict mode, prefer `const`, use types.
   - Python: follow PEP 8, use type hints, prefer explicit over implicit.
   - Go: follow Effective Go, embrace simplicity.
   - Shell scripts: quote variables, `set -e` to fail fast.

10. **Record deviations as they happen.** When the implementation diverges from the design (a tool added, an approach changed), write it in the delivery document at that moment. QA adjusts the test plan from it and the architect updates the design from it. A deviation reported only at the end reaches both too late.

11. **Document what others consume.** When you add an API endpoint that was not in the design, write down its response shape so the frontend developer does not have to read the route handler to learn the contract.

12. **Check the acceptance criteria one by one, then hand over.** Go down the acceptance criteria as a checklist and confirm each in the running feature. Then write the testing handoff for QA: seed data, example requests (for example `curl` commands), how to reach the test state, and known limitations. Follow the verify-before-done rule in `team-standards`.

Longer before-and-after examples for steps 3 to 6 are in `references/examples.md`.

## Done means

- Build, lint, type-check and tests pass using the project's own scripts, and you can state what you ran and what it printed.
- Every acceptance criterion has been checked against the running feature, not inferred from the code.
- New behaviour has tests for the happy path, an edge case and a failure case.
- No dead code, commented-out code, unused imports or debug logging remains in the diff.
- The delivery document lists every deviation from the design, the response shape of any new endpoint, and testing instructions for QA.
- Anything the feature needs outside the code (a migration applied, a storage bucket, an environment variable) is either in place or explicitly handed to the DevOps role as a blocker, not listed as a "next step".

## Anti-patterns

- **"Code complete" treated as "delivered".** A feature has shipped with its migration not applied, its storage bucket not created and an API key not set, with all three listed as "next steps". The feature did not work. Do not mark delivery complete until the feature works in the target environment, or hand the deployment steps over explicitly as blockers.
- **Verifying "does it build" instead of the acceptance criteria.** A high-severity feature has been missed even though it appeared in the requirements, the UX approach, the API design and the acceptance criteria. Documentation in four places did not prevent it; a checklist pass over the acceptance criteria would have.
- **Solving the same class of problem from scratch each time.** When the same kind of failure appears a third time (for example migration history problems), stop patching and write a runbook.
- **"It builds" as a testing handoff.** QA needs to know what to test and how to set up the state.
- **Silent failure.** An empty `catch`, or a missing key that makes a call quietly do nothing, costs far more to find later than a loud error costs now.
- **Testing implementation details.** Spying on an internal call makes the test break on refactoring and pass on wrong behaviour.
- **Abstraction for one caller, or code for a requirement nobody has stated.**
