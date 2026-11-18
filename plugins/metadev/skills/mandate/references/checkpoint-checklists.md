# Checkpoint Checklists

Detailed checklists for each mandate checkpoint. Reference during mandate execution.

---

## Checkpoint 1: Requirements

**Owner:** Paula | **Gate:** The owner approves

- [ ] Problem statement is clear and specific
- [ ] Success criteria are measurable and testable
- [ ] User stories cover primary and secondary flows
- [ ] UX flows describe the user's journey step-by-step
- [ ] AI strategy defined (if applicable): what AI does, what humans do
- [ ] Scope boundaries explicit: what is IN scope, what is OUT
- [ ] Constraints documented: timeline, budget, technology, dependencies
- [ ] Test environment section filled: infrastructure needs, test data, validation approach
- [ ] Team composition proposed (which team members needed)
- [ ] Filed at `docs/mandates/[mandate]/requirements.md`

### Routine Pattern Self-Approval Criteria

Paula can self-approve (the owner reviews async) when ALL of these are true:

- Similar mandate delivered successfully before
- No new infrastructure, users, or budget required
- Scope is clearly bounded (single feature or enhancement)
- No external dependencies or third-party integrations

---

## Checkpoint 2: Design

**Owner:** Alex + Teresa | **Gate:** Team self-validates

- [ ] Architecture overview with component diagram
- [ ] Data model defined (schema, relationships, constraints)
- [ ] Key technical decisions documented with rationale
- [ ] Trade-offs explicitly stated (what was chosen AND what was rejected, with why)
- [ ] Implementation plan with ordered steps
- [ ] External dependency validation completed (model IDs, API contracts, rate limits)
- [ ] Teresa's test plan covers the design
- [ ] Deployment plan outlined (environment, migrations, env vars)
- [ ] Team reviewed and self-validated
- [ ] the owner notified (not gated, but informed)
- [ ] Filed at `docs/mandates/[mandate]/design.md`

### Escalation Triggers

Any team member should escalate to the owner when:

- Design introduces new infrastructure or ongoing costs
- Architecture is novel (not following established patterns)
- Scope appears to have grown beyond original requirements
- Team members disagree on approach and cannot resolve

---

## Checkpoint 3: Delivery

**Owner:** Diego/Leo/Rafa + Teresa + Marco | **Gate:** The owner accepts

- [ ] All acceptance criteria from requirements are met
- [ ] Feature branch merged to main via PR
- [ ] Core Flow Smoke Test performed and passing
- [ ] Teresa's QA report completed (`qa-report.md` in the mandate folder)
- [ ] Marco's deployment verification completed (`deploy-verify` skill)
- [ ] No critical or major issues open
- [ ] `delivery.md` documents: items delivered, deployment state, deviations from design
- [ ] Filed at `docs/mandates/[mandate]/delivery.md`

### "Delivered" Definition

"Delivered" means ALL of:

1. Code is merged to main
2. Deployed to production
3. Verified working in production (not just locally)
4. Documented in delivery.md
5. QA report filed

Code complete is NOT delivered.

---

## Post-Delivery: Retrospective

**Owner:** Paula (facilitator) | **Gate:** Non-negotiable

- [ ] Retrospective facilitated (`retro` skill)
- [ ] What worked well identified (3-5 items)
- [ ] What didn't work identified with "do differently" actions
- [ ] Learnings captured
- [ ] Every action item added to `docs/backlog.md`
- [ ] Knowledge updates identified and filed
- [ ] Team dynamics assessed
- [ ] Filed at `docs/mandates/[mandate]/retrospective.md`
- [ ] CLAUDE.md updated with mandate status
