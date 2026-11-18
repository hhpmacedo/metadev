---
name: qa-council
description: Thorough multi-perspective QA of a feature, page or deployment - functional, UX, accessibility and integration - ending in a single report with a ready or not-ready verdict. Use when asked to run QA, test something thoroughly, or do a full quality pass; for a mandate, the report is written to its qa-report.md.
argument-hint: "[mandate name, feature, or URL]"
---

# QA Council

Multi-perspective quality assurance that analyzes a feature or deployment from multiple specialist viewpoints, then synthesizes findings into a single actionable report.

## Overview

The QA Council pattern decomposes quality assurance into specialist perspectives, each examining the target from a different angle. This catches issues that single-pass testing misses — accessibility problems, performance regressions, security gaps, and UX inconsistencies.

## When to Use

- After implementation, before marking a mandate as delivered
- When a feature touches user-facing UI, data persistence, or external APIs
- When the owner asks for thorough testing beyond a smoke test
- Before major releases or after significant refactors

## Council Perspectives

### 1. Functional Analyst

Examine whether the feature works as specified.

- Map acceptance criteria from requirements to test cases
- Execute the core user flow end-to-end
- Test edge cases: empty states, error handling, invalid input, boundary values
- Verify data persistence (create, read, update, delete cycles)
- Check that error messages are helpful and actionable

### 2. UX Reviewer

Evaluate the user experience quality.

- Test responsive behavior at mobile (375px), tablet (768px), and desktop (1280px)
- Check loading states, empty states, and transition animations
- Verify navigation flow and information hierarchy
- Test keyboard navigation and focus management
- Confirm visual consistency with design intent

### 3. Accessibility Auditor

Verify accessibility compliance.

- Check semantic HTML structure (headings, landmarks, lists)
- Verify ARIA labels on interactive elements
- Test keyboard-only navigation (Tab, Enter, Escape, Arrow keys)
- Check color contrast ratios (minimum 4.5:1 for text)
- Verify screen reader compatibility for dynamic content

### 4. Integration Tester

Validate system boundaries and data flow.

- Test API endpoints return expected status codes
- Verify no console errors on key pages
- Check network requests for failed resources (404s on CSS, JS, images)
- Test with slow network conditions when relevant
- Verify environment variables and external service connections

## Process

1. **Read requirements and design docs** to understand success criteria
2. **Open the deployed feature** with browser tools if the session has them; otherwise use real HTTP requests and record what could not be covered
3. **Run each perspective.** For a large surface, give each perspective to its own `metadev:teresa` agent in parallel and merge the findings; for a small one, run them in sequence yourself
4. **Classify issues** by severity:
   - **Critical:** Blocks core functionality, data loss, security vulnerability
   - **High:** Broken secondary flows
   - **Medium:** Degraded experience, non-blocking
   - **Low:** Cosmetic
5. **Confirm before reporting:** reproduce every Critical and High issue a second time; drop what does not reproduce
6. **Synthesize report** with overall verdict: Ready / Not Ready (with blocking issues listed). If the target is a mandate, write it to `docs/mandates/<mandate>/qa-report.md` and include the delivery risk classification

## Output Format

```markdown
# QA Council Report: [Feature/Mandate Name]

## Verdict: [READY / NOT READY]

## Summary

[1-2 sentence overall assessment]

## Critical Issues

- [Issue description + reproduction steps]

## High Issues

- [Issue description + reproduction steps]

## Medium and Low Issues

- [Issue description]

## Perspective Reports

### Functional: [PASS/FAIL]

[Key findings]

### UX: [PASS/FAIL]

[Key findings]

### Accessibility: [PASS/FAIL]

[Key findings]

### Integration: [PASS/FAIL]

[Key findings]

## Test Coverage

- Total test cases: [N]
- Passed: [N]
- Failed: [N]
- Skipped: [N]
```

## Tools

Use whatever browser automation the session provides (Playwright, Chrome DevTools or Claude in Chrome tools) for snapshots, user flows, responsive breakpoints, console errors and network requests.

## Additional Resources

### Reference Files

- **`references/test-categories.md`** — Mandatory test categories and common patterns

### Related skills

- `deploy-verify` - infrastructure-focused deployment checks
