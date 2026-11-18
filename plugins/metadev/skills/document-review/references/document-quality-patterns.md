# Document Quality Patterns

Worked examples of good and bad patterns for each document type.

---

## Requirements Documents

### Gold standard: an AI chat workspace mandate

**What makes it excellent:**

1. **Problem statement names three specific problems**, each traced to existing system behavior:
   - "Decisions are invisible" → session_insights exist but aren't surfaced
   - "Artifacts are trapped in chat" → artifacts table stores them but renders as bubbles
   - "Knowledge is a black box" → three knowledge layers, zero user visibility

2. **Acceptance criteria are precise and testable:**
   - "Dashboard renders as the default view at `/` when the user logs in" (testable: navigate to /, check what renders)
   - "Limited to 5-8 items. Sorted by creation date, most recent first." (testable: count items, verify sort order)
   - "npm run build passes" (testable: run the command)

3. **Decisions are documented with reasoning:**
   - "Chat state does not need to survive view transitions — When the user navigates away from Chat and back, we reload from the session record... This is simpler than keeping the Chat component mounted. The tradeoff: navigating away from an unsaved new conversation loses nothing because there is nothing to lose."

4. **Questions for Alex are specific and answerable:**
   - Not "how should we handle PDF?" but "Which client-side PDF library: html2pdf.js, jspdf, or @react-pdf/renderer? I lean toward html2pdf.js for implementation speed."

### Needs improvement: a messaging-integration mandate

**What's missing:**

1. **No test environment section** — QA had to improvise during testing. Led to incomplete coverage of the third-party API integration.

2. **No scope classification** — Was this routine or novel? Novel (new external API, new infrastructure, new users). Should have been flagged.

3. **Acceptance criteria are outcome-focused but lack edge cases:**
   - "Both A and B join and interact (≥1 message each)" — what if A doesn't join? What if the group creation fails? What's the timeout?
   - "Agent understands natural language availability" — how do we test this? What's the accuracy threshold?

4. **No constraints section** with specifics — just implied "minimal" and "simple."

---

## Design Documents

### Good Pattern: Explicit Trade-offs Table

```markdown
## Trade-offs

| Trade-off                 | What We Get                         | What We Give Up                     |
| ------------------------- | ----------------------------------- | ----------------------------------- |
| Client-side PDF           | No server infrastructure            | Potentially lower quality rendering |
| URL-based session restore | Simplicity, no state management     | Lose unsaved new conversations      |
| Separate API routes       | Parallel fetch, independent caching | 3 requests instead of 1             |
```

This tells the reader: "We know the cost. We chose to pay it. Here's why."

### Bad Pattern: Missing Dependency Validation

A design that says "Uses a third-party API for messaging integration" without:

- Exact API version
- Request/response shapes for key operations (send message, create group)
- Rate limits (what happens at 100 users?)
- Phone number format requirements (international vs local format)
- Error response shapes (how does the API signal failure?)
- Sandbox/test mode availability

Result: in one mandate, 4 of 5 post-deployment bugs were dependency validation failures.

### Good Pattern: Implementation Sequencing with Dependencies

```markdown
## Implementation Plan

1. [ ] Workspace shell layout — depends on: nothing (goes first)
2. [ ] Dashboard view — depends on: Item 1 (shell provides container)
3. [ ] Artifact detail view — depends on: Item 1 (routing)
4. [ ] PDF export — depends on: Item 3 (artifact view provides content)
5. [ ] Knowledge dashboard — depends on: Item 1 (can parallel with 2-4)
6. [ ] Context panel upgrade — depends on: Items 1, 5 (build last)
```

Each step states its dependency. Teresa can verify each independently. Developer knows what can be parallelized.

---

## QA Reports

### Good Pattern: Evidence-Based Test Results

```markdown
### Dashboard View

| Test Case              | Result | Notes                                                                 |
| ---------------------- | ------ | --------------------------------------------------------------------- |
| Default landing page   | PASS   | Navigated to /, dashboard rendered with 3 sections visible            |
| Decision cards display | PASS   | 5 cards rendered, sorted by date, most recent first                   |
| Empty state (new user) | PASS   | Welcome message displayed with "Start conversation" CTA               |
| Card click navigation  | PASS   | Clicked "Q2 Pricing" card → navigated to /chat/abc123, session loaded |
```

Each PASS describes what was _observed_, not just "it works."

### Bad Pattern: Opinion-Based Results

```markdown
| Test Case            | Result | Notes                   |
| -------------------- | ------ | ----------------------- |
| Dashboard looks good | PASS   | Looks fine              |
| Navigation works     | PASS   | Tested                  |
| PDF exports          | PASS   | Downloaded successfully |
```

"Looks fine" is not evidence. "Tested" doesn't say what was tested. These results can't be verified by anyone else.

### Good Pattern: Honest Risk Assessment

```markdown
## Delivery Risk Classification

| Criteria       | Assessment | Notes                                       |
| -------------- | ---------- | ------------------------------------------- |
| New users      | High-risk  | Dashboard is new public-facing feature      |
| Infrastructure | Low-risk   | Existing Vercel deployment, no new services |
| Budget         | Low-risk   | No new paid services                        |
| Data           | Low-risk   | Reads existing tables, no migrations        |
| Rollback       | Low-risk   | Feature branch, easy revert                 |

**Classification:** High-risk (the owner accepts) — new public-facing feature
```

One honest "High-risk" triggers the correct approval path. Don't mark everything "Low-risk" to avoid the gate.

---

## Cross-Document Traceability

The strongest mandate documentation has visible threads between all three documents:

```
requirements.md: "Dashboard shows 5 most recent decisions"
        ↓
design.md: "GET /api/dashboard/decisions — returns session_insights where type='decision', limit 5, order by created_at desc"
        ↓
qa-report.md: "Test: Decision cards display — PASS — 5 cards rendered, sorted by date, most recent first"
```

If you can trace a requirement from inception → design → test result, the mandate chain is healthy. If a requirement appears in requirements.md but has no corresponding design element or test case, the chain is broken.
