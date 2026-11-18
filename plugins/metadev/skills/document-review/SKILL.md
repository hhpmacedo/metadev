---
name: document-review
description: Quality check of a mandate document (requirements, design, QA report, delivery) for gaps, ambiguity and missing rationale before it reaches a checkpoint. Use when asked whether a requirements, design or QA document is ready.
argument-hint: "[path to the document or mandate name]"
---

# Document Review

Quality assessment for mandate checkpoint documents. Catches gaps, ambiguities, and missing rationale before documents reach checkpoint gates — where rework costs multiply.

## When to Use

- **Pre-flight (author):** Before submitting a document to the checkpoint. "Is my requirements.md ready for the owner?"
- **Review (team):** When reviewing a teammate's document. "Does this design.md cover everything?"
- **Checkpoint gate:** As part of formal checkpoint validation. Pairs with `/design-review` at CP2.

## How It Works

1. Identify the document type (requirements, design, or qa-report)
2. Read the document and its upstream dependencies
3. Run universal quality checks (apply to all document types)
4. Run type-specific quality checks
5. Produce a structured assessment with verdict

## Step 0: Identify and Load

1. Determine the document type from the file name or user input
2. Read the document being reviewed
3. Read upstream dependencies:
   - **requirements.md** → Read the mandate brief or the owner's original request
   - **design.md** → Read the approved requirements.md
   - **qa-report.md** → Read both requirements.md and design.md
4. Read the project's CLAUDE.md for project context

---

## Universal Quality Checks

These apply to every checkpoint document regardless of type.

### U1: Completeness

**What:** Every section from the template is present and substantively filled.

**Why:** Blank or placeholder sections signal unfinished thinking. A section left as "[TODO]" or "[TBD]" means the author deferred a decision that the checkpoint reviewer will have to catch — or worse, that nobody catches until implementation.

**Check for:**

- All template sections present (compare against `docs/mandates/_template/`)
- No placeholder text remaining (`[TODO]`, `[TBD]`, `[fill in]`, `...`)
- Sections have substantive content, not single-line placeholders
- If a section genuinely doesn't apply, it says "N/A — [reason]" not just "N/A"

**Verdict:** `COMPLETE` / `GAPS` (list missing sections)

### U2: Clarity

**What:** A reader unfamiliar with the project context can understand the document without asking clarifying questions.

**Why:** Documents outlive conversations. When a developer picks up this mandate two weeks from now, or when the owner reviews it async, they should not need to ask "what did you mean by X?" Ambiguity in documents becomes misalignment in implementation.

**Check for:**

- Specific language, not vague ("users can manage their profile" → manage how? edit, delete, view?)
- Technical terms are used correctly and consistently
- Acronyms defined on first use (or universally known in this team)
- No sentences that require asking "what exactly does this mean?"
- Numbers, dates, and thresholds are explicit ("fast" → under 2 seconds; "recent" → last 7 days)

**Verdict:** `CLEAR` / `AMBIGUOUS` (list specific ambiguities)

### U3: Decision Rationale

**What:** When the document makes a choice, it explains why.

**Why:** "We'll use React" is a statement. "We'll use React because the existing codebase is React and switching frameworks mid-project adds risk without benefit" is a decision. Future readers need the reasoning to know whether the decision still holds when context changes. Decisions without rationale become cargo-culted constraints.

**Check for:**

- Key Decisions table filled with Options Considered + Rationale (design.md)
- Trade-offs stated explicitly, not implied
- "We chose X" is always followed by "because Y"
- When something is explicitly out of scope, the reason is stated
- Decisions inherited from upstream docs are referenced ("per requirements.md, we're limiting to 5 participants")

**Verdict:** `REASONED` / `UNJUSTIFIED` (list decisions without rationale)

### U4: Traceability

**What:** The document connects to its upstream and downstream neighbors in the mandate chain.

**Why:** Requirements → Design → QA Report is a chain. If design.md doesn't reference requirements, you can't verify alignment. If qa-report.md doesn't reference design, you can't verify coverage. Traceability is how the team catches drift between what was asked, what was designed, and what was tested.

**Check for:**

- References to upstream document (requirements references the owner's mandate, design references requirements, QA references both)
- Acceptance criteria traceable across documents (requirement criteria → design components → test cases)
- Mandate name, date, and owner consistent across all documents
- Changes from upstream are documented ("requirements asked for X, but during design we discovered Y, so we're doing Z instead — the owner approved")

**Verdict:** `TRACED` / `DISCONNECTED` (list broken references)

### U5: Actionability

**What:** The reader knows exactly what to do after reading this document.

**Why:** A document that informs but doesn't direct is a report, not a working document. Requirements should tell the architect what to design. Design should tell the developer what to build. QA reports should tell the owner whether to accept.

**Check for:**

- Clear next steps or approval section
- Open questions are genuinely open (not rhetorical or already answered)
- If decisions are needed from someone (the owner, Alex, etc.), they're called out explicitly
- Action items are assigned ("Alex should validate" not "someone should check")

**Verdict:** `ACTIONABLE` / `PASSIVE` (list what's unclear about next steps)

---

## Type-Specific Checks

### For requirements.md

Run these after the universal checks.

#### R1: Problem Worth Solving

**What:** The problem statement explains _why_ this matters, not just _what_ the problem is.

**Check for:**

- Problem framed in terms of user pain or business impact
- Clear who is affected and how
- Current state described (what happens today without this)
- Not just a feature request disguised as a problem ("we need a dashboard" is a solution, not a problem)

**Gold standard:** a requirements document that opens with three specific problems, each traced to existing system behavior and user impact.

**Anti-pattern:** "We need a chat-app integration" — that's a solution. The problem is "scheduling meetings requires 6 back-and-forth messages."

#### R2: Testable Acceptance Criteria

**What:** Every acceptance criterion can be verified with a concrete yes/no test.

**Check for:**

- Criteria use Given/When/Then or equivalent concrete language
- No subjective criteria without measurement ("feels fast" → "loads in under 2 seconds")
- Each user story has at least 2 acceptance criteria
- Criteria cover the happy path AND at least one error/edge case
- `npm run build` passes is listed (team standard)

**Red flag:** Acceptance criteria that are really design decisions ("uses React Query for data fetching"). Keep criteria about outcomes, not implementation.

#### R3: Scope Boundaries

**What:** In-scope and out-of-scope are explicit, complete, and non-overlapping.

**Check for:**

- Out-of-scope list exists and is substantive (not just "everything else")
- Items that a reader might reasonably expect are explicitly called out as out-of-scope
- No items appear in both in-scope and out-of-scope
- Scope classification table is filled (Routine/Novel per criteria)
- Constraints are stated with specificity (not "must be fast" but "must load in under 2 seconds")

#### R4: Test Environment

**What:** QA knows where and how to test before implementation begins.

**Check for:**

- Test infrastructure identified (local, Vercel preview, staging)
- Test accounts/credentials plan stated
- External service sandbox/test mode confirmed
- Test data strategy (seed data, synthetic, real-world)
- Primary user flow for end-to-end validation identified

**Why this matters:** One messaging-integration mandate had no test environment section. QA had to improvise during testing, leading to incomplete coverage of the third-party API integration.

---

### For design.md

Run these after the universal checks.

#### D1: Requirements Coverage

**What:** Every requirement has a design element; every design element traces to a requirement.

**Check for:**

- Each acceptance criterion from requirements.md maps to a component, route, or API endpoint
- No "bonus" components that weren't in requirements (gold-plating)
- If a requirement was modified during design, the change is documented and justified
- Implementation plan steps cover all requirements

**How to verify:** Create a mental trace from each requirement to design element. If you can't find the connection, it's either missing or implicit.

#### D2: External Dependency Rigor

**What:** Every external API, model, or service has verified contracts, not assumptions.

**Check for:**

- Exact model IDs (not `claude-sonnet` but `claude-sonnet-4-5-20250929`)
- API request/response shapes documented
- Rate limits and cost implications stated
- Format normalization requirements identified
- Error handling strategy per dependency
- External Dependency Validation table filled

**Why this matters:** One AI chat mandate missed the stop condition (`stopWhen`) that lets a tool-calling pipeline continue past its first step. One messaging mandate had phone number format mismatches. Both were dependency validation failures.

#### D3: Implementation Sequencing

**What:** The implementation plan is ordered, with dependencies explicit.

**Check for:**

- Steps are numbered and ordered by dependency
- Each step states what it depends on
- Steps are independently testable (Teresa can verify each one)
- Parallel work opportunities are identified
- No circular dependencies

---

### For qa-report.md

Run these after the universal checks.

#### Q1: Acceptance Criteria Coverage

**What:** Every acceptance criterion from requirements.md has a corresponding test result.

**Check for:**

- Create a list of all acceptance criteria from requirements.md
- Each criterion has a test case in the report
- Any untested criteria are listed in "What Was NOT Tested" with reason
- No test cases that don't trace back to a criterion (test scope matches requirement scope)

#### Q2: Evidence, Not Opinion

**What:** Test results are backed by evidence, not assertions.

**Check for:**

- PASS results describe what was observed ("button clicked, form submitted, success toast displayed")
- FAIL results include steps to reproduce, expected vs actual, and evidence (screenshots, logs)
- "It works" is not a test result — "navigated to /dashboard, 3 decision cards rendered, clicked first card, navigated to /chat/abc123" is a test result

#### Q3: Delivery Risk Assessment

**What:** The Delivery Risk Classification table is filled with honest assessments.

**Check for:**

- All 5 criteria assessed (new users, infrastructure, budget, data, rollback)
- Classification matches the evidence (don't mark "low-risk" when there are schema migrations)
- Recommendation (Ready / NOT Ready) is consistent with the risk assessment
- Conditions are specific, not vague ("Ready if Issue #3 is fixed" not "Ready once bugs are addressed")

---

## Output Format

```markdown
# Document Review: [Document Name]

**Document:** [path/to/document.md]
**Type:** Requirements / Design / QA Report
**Author:** [Name]
**Reviewed by:** [Name]
**Date:** YYYY-MM-DD

## Verdict: READY / REVISE / NOT READY

## Universal Checks

| #   | Check              | Result               | Finding   |
| --- | ------------------ | -------------------- | --------- |
| U1  | Completeness       | COMPLETE/GAPS        | [Summary] |
| U2  | Clarity            | CLEAR/AMBIGUOUS      | [Summary] |
| U3  | Decision Rationale | REASONED/UNJUSTIFIED | [Summary] |
| U4  | Traceability       | TRACED/DISCONNECTED  | [Summary] |
| U5  | Actionability      | ACTIONABLE/PASSIVE   | [Summary] |

## Type-Specific Checks

| #          | Check        | Result   | Finding   |
| ---------- | ------------ | -------- | --------- |
| [R1/D1/Q1] | [Check name] | [Result] | [Summary] |
| ...        | ...          | ...      | ...       |

## Detailed Findings

[For any check that didn't pass, provide:

- What specifically is missing or unclear
- Why it matters for this document
- Suggested fix (specific, not vague)]

## Strengths

[What the document does well — reinforce good patterns]

## Recommendation

[Specific actions before this document is checkpoint-ready]
```

## Verdict Rules

- **READY:** All universal checks pass AND all type-specific checks pass. Document can proceed to checkpoint.
- **REVISE:** One or more checks have findings. Author should address findings and re-review. No checkpoint submission until resolved.
- **NOT READY:** Multiple critical gaps, or document is fundamentally incomplete. Needs significant rework before review is meaningful.

## Calibration

**READY does not mean perfect.** It means the document is good enough to support the next phase without causing rework. A requirements doc with minor clarity nits but solid acceptance criteria is READY. A requirements doc with vague acceptance criteria is REVISE regardless of how polished the prose is.

**Focus on substance, not style.** Bullet formatting, heading consistency, and table alignment are nice but don't determine the verdict. Testable acceptance criteria, traced requirements, and justified decisions do.

## Additional Resources

Read `references/document-quality-patterns.md` for examples of good and bad document patterns from past mandates.
