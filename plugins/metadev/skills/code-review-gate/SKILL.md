---
name: code-review-gate
description: Pre-merge quality gate for a branch or pull request - automated checks, correctness, security, conventions, architecture against the design doc, high-risk files, and the core-flow smoke test - ending in approve or request-changes. Use before merging to main, or when asked whether a change is ready to merge.
argument-hint: "[branch or PR number]"
---

# Code Review Gate

Pre-merge quality gate that validates code changes against team standards before merging to main. Combines automated checks with structured review.

## Overview

Every PR to main passes through this gate. The review covers correctness, security, conventions, and the Core Flow Smoke Test requirement. This is not a rubber stamp — it catches issues that automated checks miss.

## When to Use

- Before merging any PR to main
- When a developer says "this is ready for review"
- After implementation, before requesting the owner's acceptance
- When refactoring shared code that affects multiple features

## Review Process

### Step 1: Understand the Change

1. Read the PR diff (use `git diff main...HEAD` or `gh pr diff`)
2. Read the related requirements and design docs if this is a mandate PR
3. Understand the intent — what problem does this solve?

### Step 2: Automated Checks

Run these checks and report pass/fail:

- **TypeScript compilation:** `npx tsc --noEmit` — zero errors required
- **Linting:** `npx eslint .` or project-specific lint command
- **Tests:** `npm test` — all tests pass
- **Build:** `npm run build` — clean build with no warnings

### Step 3: Code Quality Review

Review the diff for:

**Correctness**

- Logic errors, off-by-one mistakes, race conditions
- Missing error handling at system boundaries (user input, API responses)
- Incomplete state management (loading, error, empty states)

**Security (OWASP Top 10)**

- No hardcoded secrets, API keys, or credentials
- Input validation on user-facing endpoints
- No SQL injection, XSS, or command injection vectors
- Authentication and authorization checks present where needed

**Conventions**

- Follows project coding style (naming, file structure, patterns)
- No unnecessary changes outside the scope of the PR
- Comments only where logic is non-obvious
- No dead code, unused imports, or debug logging left in

**Architecture**

- Changes align with the design doc (if mandate PR)
- No unnecessary abstractions or premature optimization
- Dependencies are justified and minimal

### Step 4: High-Risk File Check

If any high-risk files were modified, flag for extra scrutiny:

| Pattern                   | Risk     | Action                                                   |
| ------------------------- | -------- | -------------------------------------------------------- |
| `*/api/chat/route.ts`     | Critical | Verify AI pipeline config, step limits, tool definitions |
| Database migrations       | High     | Verify reversibility, test against real data shapes      |
| Auth middleware/config    | High     | Verify no lockout scenarios, no security holes           |
| Chat rendering components | High     | Verify unknown-type fallbacks exist                      |

### Step 5: Core Flow Smoke Test Verification

Confirm the developer has performed the Core Flow Smoke Test:

1. Open the deployed preview or local dev server
2. Execute the primary user flow end-to-end
3. Confirm the flow completes without errors — not just page load, but goal completion
4. Check browser console for errors

This takes 2 minutes. It is not optional.

## Output Format

```markdown
# Code Review: [PR Title]

## Verdict: [APPROVE / REQUEST CHANGES / NEEDS DISCUSSION]

## Automated Checks

- [ ] TypeScript: PASS/FAIL
- [ ] Lint: PASS/FAIL
- [ ] Tests: PASS/FAIL
- [ ] Build: PASS/FAIL

## Code Quality

- **Correctness:** [Findings or "Clean"]
- **Security:** [Findings or "Clean"]
- **Conventions:** [Findings or "Clean"]
- **Architecture:** [Findings or "Clean"]

## High-Risk Files

[List any modified high-risk files and findings, or "None modified"]

## Core Flow Smoke Test

- [ ] Confirmed performed by developer

## Action Items

1. [Required change before merge]
2. [Required change before merge]

## Notes

[Optional observations, suggestions for future improvement]
```

## Severity Levels

- **Blocking:** Must fix before merge (bugs, security issues, broken tests)
- **Should fix:** Strong recommendation, but PR can merge with tracking issue
- **Nit:** Style preference, no action required

## Additional Resources

### Independence

The review is worth more when the reviewer did not write the code. If you wrote the change in this session, hand Step 3 to a fresh agent with the diff and the requirement, not your own summary of it.

### Related tools

- The built-in `/code-review` skill for a deeper correctness review, and `/security-review` for security.
- Extra review agents, if the session has them (the `setup` skill lists the plugin): a silent-failure reviewer and a test-coverage reviewer are the most useful pair before merge.
