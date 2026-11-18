---
name: design-review
description: Seven-check gate for a mandate design before building starts - scope alignment, complexity, deployment plan, technical debt, external dependency validation, testability, simplicity - ending in approve, revise or escalate. Use at checkpoint 2, or when asked to review or validate a design.
argument-hint: "[path to the document or mandate name]"
---

# Design Review

Interactive design review for Checkpoint 2. Transforms the team's Design Review Checklist into a guided assessment that explains _why_ each check matters, identifies gaps, and produces a structured verdict.

## When to Use

- At Checkpoint 2, before the team self-validates a design
- When Alex finishes drafting design.md and wants a pre-flight check
- When any team member wants to challenge or validate a design decision
- When the owner asks for a design review on a mandate

## Prerequisites

Before running this review, ensure:

1. `requirements.md` exists and is approved (Checkpoint 1 passed)
2. `design.md` is drafted with architecture, components, decisions, and implementation plan
3. Teresa has confirmed or drafted a test plan

If any prerequisite is missing, stop and address that first.

## Review Process

### Step 0: Load Context

1. Read the mandate's `requirements.md` — understand what was asked
2. Read the mandate's `design.md` — understand what was proposed
3. Identify the project repo and read its `CLAUDE.md` for project-specific context
4. Note the team members involved and their roles for this mandate

### Step 1: Scope Alignment

**Owner:** Paula
**Why this matters:** Scope creep is the #1 killer of mandates. A design that doesn't match requirements wastes everyone's time — the team builds the wrong thing, the owner rejects it, and rework doubles the effort. Equally dangerous: a design that _under-delivers_ by quietly dropping requirements.

**What to check:**

- Every requirement in `requirements.md` has a corresponding design element
- Every design element traces back to a requirement (no gold-plating)
- Success criteria from requirements are achievable with this design
- Out-of-scope items from requirements are genuinely absent from design
- User stories and acceptance criteria are covered by the component design

**Common failure modes:**

- Design solves a _related_ problem but not the _stated_ problem
- Design adds "nice-to-have" features that weren't in requirements
- A requirement is partially addressed but the edge cases are missing
- Scope was implicitly expanded during design ("while we're at it...")

**Assessment:** Does the design solve exactly what was asked — no more, no less?

Output: `PASS` / `FAIL` / `CONCERN` with specific findings.

---

### Step 2: Complexity Check

**Owner:** Alex
**Why this matters:** Complexity compounds. Every unnecessary abstraction, configuration option, or "just in case" pattern adds maintenance cost that the team pays on every future mandate. The right design is the _simplest_ one that meets the requirements. Three similar lines of code are better than a premature abstraction.

**What to check:**

- Could a simpler approach achieve the same result?
- Are there abstractions that only have one implementation?
- Are there configuration options that will only ever have one value?
- Is the component count justified? Could components be merged?
- Does the data model have entities that won't be used in this mandate?
- Are there "extensibility" hooks for hypothetical future requirements?

**Common failure modes:**

- Factory patterns for a single product type
- Configuration files for values that never change
- Middleware chains with one middleware
- Generic base classes with one subclass
- "Plugin architecture" for a system with no plugins planned

**Assessment:** Is this the simplest design that works? If not, what can be removed?

Output: `PASS` / `FAIL` / `CONCERN` with specific findings.

---

### Step 3: Deployment Plan

**Owner:** Marco
**Why this matters:** "Works on my machine" is not delivered. A design without a deployment plan creates a gap between "code complete" and "in production" that absorbs days. Undefined deployment details (hosting, env vars, migrations, domains) become blockers at the worst time — when the code is done and the team wants to ship.

**What to check:**

- Hosting environment is identified (Vercel, VPS, etc.)
- Environment variables are listed with their purpose
- Database migrations are planned (if applicable) with rollback strategy
- Domain/DNS changes are documented (if applicable)
- Deployment sequence is ordered (what deploys first, what depends on what)
- CI/CD pipeline changes are identified (if any)
- Cost implications are stated (free tier? paid service? ongoing cost?)

**Common failure modes:**

- "We'll figure out deployment later" (no, figure it out now)
- Missing env vars that only surface in production
- Database migration that works locally but fails against production data
- DNS changes that require 48h propagation, not accounted for in timeline
- No rollback plan for schema changes

**Assessment:** Is there a clear, executable path from "code merged" to "running in production"?

Output: `PASS` / `FAIL` / `CONCERN` with specific findings.

---

### Step 4: Tech Debt Assessment

**Owner:** Alex
**Why this matters:** Tech debt is not inherently bad — it's a deliberate trade-off. What's bad is _accidental_ or _unacknowledged_ debt. When the team takes on debt deliberately (e.g., "we're hardcoding this value because there's only one client"), that's a conscious decision. When debt accumulates because nobody noticed, it compounds silently until it blocks future work.

**What to check:**

- Does this design introduce new technical debt? If yes, is it documented and intentional?
- Does this design increase existing debt in the codebase? If yes, is it justified?
- Are there shortcuts in the design that should be flagged for future cleanup?
- Does the design follow "tend the garden" — leaving the codebase cleaner than found?
- Are there temporary solutions marked as temporary (with cleanup criteria)?

**Common failure modes:**

- Copying patterns from elsewhere without understanding if they still apply
- Adding a quick fix that becomes permanent because it "works"
- Introducing a second way to do something the codebase already does
- Not documenting why a shortcut was taken (future developers won't know it's intentional)

**Assessment:** Is new debt intentional, documented, and justified? Does this design tend the garden?

Output: `PASS` / `FAIL` / `CONCERN` with specific findings.

---

### Step 5: External Dependency Validation

**Owner:** Alex
**Why this matters:** External dependencies are the most common source of production surprises. An API that works in docs but not in practice, a model ID that changed, a rate limit that kicks in at scale — these are the bugs that take hours to debug because the team assumes the external service works as documented. Validate _before_ building, not after.

**What to check:**

- Every external API, AI model, or third-party service is listed in design.md
- Model IDs are verified against provider docs (exact string, not approximate)
- API contracts are documented (request/response shapes, auth method)
- Rate limits and cost implications are stated
- Format normalization requirements are identified (phone numbers, dates, currencies)
- Error handling strategy exists for each dependency (what happens when it fails?)
- Sandbox/test mode is available for development and QA

**Common failure modes:**

- Using `claude-sonnet` instead of the exact model ID `claude-sonnet-4-5-20250929`
- Assuming an API returns data in a specific format without verifying
- Not accounting for rate limits that trigger under real usage
- Missing format normalization (phone number with/without country code, date formats)
- No fallback when an external service is temporarily unavailable

**Assessment:** Are all external dependencies verified with actual calls, not assumptions?

Output: `PASS` / `FAIL` / `CONCERN` with specific findings.

---

### Step 6: Testability

**Owner:** Teresa
**Why this matters:** A design that can't be tested can't be verified. If Teresa can't write a test plan for it, the team is shipping on faith. Testability isn't about writing tests — it's about designing components that _can_ be observed, measured, and validated. If a feature's success criteria can't be checked, the criteria or the design needs to change.

**What to check:**

- Every acceptance criterion from requirements can be tested against this design
- Complex features have testability considerations (not just "we'll test it")
- External dependencies have mock/sandbox options for testing
- State changes are observable (not buried in side effects)
- Error paths are testable (can QA trigger error conditions?)
- The primary user flow can be executed end-to-end in a test environment

**Common failure modes:**

- AI-powered features with non-deterministic output and no way to validate quality
- Background processes that produce no observable output until they fail
- Features that require manual setup to test (credentials, data seeding, external accounts)
- "Trust me, it works" — untestable by design

**Assessment:** Can Teresa write concrete test cases for every acceptance criterion?

Output: `PASS` / `FAIL` / `CONCERN` with specific findings.

---

### Step 7: Tend the Garden

**Owner:** Any team member
**Why this matters:** This is the meta-check. Steps 1-6 verify specific aspects; this step asks the bigger question: _is this design making the codebase better or worse?_ Every design choice either simplifies or adds complexity. The team's job is to build features while keeping the system maintainable. A design that delivers the feature but makes the next feature harder has failed this check.

**What to check:**

- Net complexity: is the codebase simpler or more complex after this design?
- Consistency: does this design follow established patterns or introduce new ones?
- If new patterns are introduced, are they justified and documented?
- Could any existing code be simplified or removed as part of this work?
- Does this design create shared infrastructure that benefits future mandates?
- Would a new team member understand this design without a walkthrough?

**Common failure modes:**

- "It works, don't touch it" — adding new code without cleaning up related old code
- Introducing Pattern B alongside existing Pattern A for the same problem
- Building a feature that requires the team to learn a new framework/paradigm
- Code that's clever but not clear

**Assessment:** Does this design leave the codebase healthier than it found it?

Output: `PASS` / `FAIL` / `CONCERN` with specific findings.

---

## Output Format

After completing all 7 checks, produce the Design Review Report:

```markdown
# Design Review: [Mandate Name]

**Date:** YYYY-MM-DD
**Reviewer(s):** [Names]
**Design doc:** docs/mandates/[mandate]/design.md

## Verdict: APPROVE / REVISE / ESCALATE

## Check Results

| #   | Check                 | Owner  | Result            | Summary            |
| --- | --------------------- | ------ | ----------------- | ------------------ |
| 1   | Scope Alignment       | Paula  | PASS/FAIL/CONCERN | [One-line finding] |
| 2   | Complexity            | Alex   | PASS/FAIL/CONCERN | [One-line finding] |
| 3   | Deployment Plan       | Marco  | PASS/FAIL/CONCERN | [One-line finding] |
| 4   | Tech Debt             | Alex   | PASS/FAIL/CONCERN | [One-line finding] |
| 5   | External Dependencies | Alex   | PASS/FAIL/CONCERN | [One-line finding] |
| 6   | Testability           | Teresa | PASS/FAIL/CONCERN | [One-line finding] |
| 7   | Tend the Garden       | Team   | PASS/FAIL/CONCERN | [One-line finding] |

## Detailed Findings

[For any check that is FAIL or CONCERN, provide:

- What specifically failed
- Why it matters for this mandate
- Recommended action to resolve]

## Escalation Assessment

- [ ] Any FAIL on checks 1 or 2 → Escalate to the owner
- [ ] Design introduces new infrastructure or ongoing costs → Notify the owner
- [ ] Team members disagree on approach → Resolve or escalate

## Decision

**Proceed to implementation:** Yes / No / After revisions

**Conditions (if any):**
[What must be addressed before implementation begins]
```

## Verdict Rules

- **APPROVE:** All checks PASS. Proceed to implementation.
- **REVISE:** One or more FAIL or CONCERN. Address findings, re-run affected checks.
- **ESCALATE:** FAIL on checks 1 (Scope Alignment) or 2 (Complexity), or team cannot agree. The owner decides.

## Additional Resources

Read `references/design-review-framework.md` for the full reasoning framework behind each check, including real examples from past mandates.
