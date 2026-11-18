# Design Review Framework

Detailed reasoning and worked examples behind each Design Review check.

---

## Worked examples

### Example: an AI chat product

**What happened:** The design included an AI chat pipeline with multi-step tool execution. The `stopWhen: stepCountIs(5)` config was a one-line requirement that was part of the SDK contract, but wasn't called out in the design as a critical configuration item.

**Which checks would have caught it:**

- **Check 5 (External Dependencies):** The exact AI SDK configuration requirements should have been listed. `stepCountIs` is not obvious from the SDK docs — it requires knowing the Vercel AI SDK v6 multi-step API.
- **Check 6 (Testability):** Teresa's test plan should have included "conversation terminates after N steps" as a testable acceptance criterion.
- **Check 3 (Deployment Plan):** The deployment checklist should have included AI pipeline configuration verification.

**Lesson:** External dependency validation isn't just "which APIs" — it's "which specific configuration parameters are required for correct behavior."

---

### Example: a messaging-integration product

**What happened:** 5 bugs found post-deployment. 4 of 5 were preventable planning failures:

- Phone number format mismatch (international vs local format)
- Duplicate webhook registrations under concurrent requests
- Missing timezone handling in scheduling logic
- Incomplete error handling for external API failures

**Which checks would have caught them:**

- **Check 5 (External Dependencies):** Format normalization for phone numbers (the API expects international format, user input may be local format)
- **Check 2 (Complexity):** Concurrent webhook registration could have been simplified with a uniqueness constraint
- **Check 4 (Tech Debt):** Timezone handling was "we'll figure it out" — should have been designed up front
- **Check 6 (Testability):** Error paths for third-party API failures weren't testable in the original design

**Lesson:** Most production bugs originate in design, not implementation. A thorough design review prevents 80% of post-deployment issues.

---

### Example: a workshop landing page

**Good example:** This design passed all checks cleanly because:

- **Scope:** Simple, well-bounded (one page at `/workshop`)
- **Complexity:** Used existing React + Vite + Supabase stack, no new patterns
- **Deployment:** Existing Vercel deployment, just a new route
- **Dependencies:** No external APIs, static content
- **Testability:** Visual page, Playwright-testable

**Lesson:** Simple mandates should produce simple designs. The design review confirms simplicity is genuine, not hiding complexity.

---

## Calibration Guide

### When to Mark PASS

The check genuinely passes. Not "it's probably fine" — the reviewer has confirmed the criterion is met and can point to specific evidence in design.md.

### When to Mark CONCERN

Something isn't clearly wrong, but isn't clearly right either:

- Missing information that should be present
- An assumption that hasn't been validated
- A decision that seems reasonable but has unstated risks
- A gap that _might_ not matter but deserves a second look

CONCERNs don't block progress. They require the team to acknowledge them and decide: address now, or accept the risk.

### When to Mark FAIL

A clear gap or problem that must be addressed before implementation:

- A requirement with no design coverage
- An external dependency with no validation
- No deployment plan at all
- Complexity that isn't justified

FAILs block progress. The design must be revised before proceeding.

---

## Team Dynamics

The design review is a team exercise, not Alex reviewing his own work. Each check has a designated owner, but any team member can raise concerns on any check.

**Healthy signs:**

- Teresa challenges Alex on testability
- Paula pushes back on scope additions
- Marco flags deployment gaps early
- Diego questions complexity from an implementer's perspective

**Unhealthy signs:**

- Rubber-stamping (all PASS in 2 minutes)
- Only Alex speaking
- Concerns raised but dismissed without discussion
- "We'll figure it out during implementation" on critical items
