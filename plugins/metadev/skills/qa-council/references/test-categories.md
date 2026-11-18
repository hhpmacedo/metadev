# Mandatory Test Categories

Reference for QA Council perspectives. Each category lists common test cases and patterns.

---

## Functional Testing

### Core Flow Tests

- Execute the primary user flow end-to-end (the one thing the product must do)
- Create → Read → Update → Delete cycles for persistent data
- Verify all form submissions produce expected results
- Test navigation between all reachable pages

### Edge Cases

- Empty states: no data, first-time user, cleared data
- Boundary values: min/max input lengths, zero, negative numbers
- Invalid input: special characters, SQL injection attempts, XSS payloads
- Concurrent operations: rapid clicks, multiple tabs, simultaneous submissions
- Network interruption: what happens mid-submission?

### Error Handling

- Server errors (500) show user-friendly messages, not stack traces
- Validation errors are specific and actionable ("Email must include @")
- Timeout handling: long-running operations show progress or timeout gracefully
- Authentication expiry: graceful redirect to login, not broken state

---

## UX Testing

### Responsive Breakpoints

- **Mobile:** 375px width (iPhone SE/standard)
- **Tablet:** 768px width (iPad portrait)
- **Desktop:** 1280px width (standard laptop)

### States to Verify

- Loading state: skeleton, spinner, or progressive content
- Empty state: helpful message with call-to-action, not blank page
- Error state: clear message with recovery action
- Success state: confirmation that action completed
- Transition animations: smooth, not jarring

### Navigation

- All links work and go to expected destinations
- Back button behavior is predictable
- Breadcrumbs (if present) reflect actual hierarchy
- Mobile navigation is accessible and usable

---

## Accessibility Testing

### Semantic Structure

- One `<h1>` per page
- Heading hierarchy is sequential (h1 → h2 → h3, no skipping)
- Navigation landmarks present (`<nav>`, `<main>`, `<footer>`)
- Lists use `<ul>`/`<ol>`, not styled divs

### Interactive Elements

- All clickable elements have visible focus indicators
- Tab order follows visual order (no surprising jumps)
- Escape closes modals and dropdowns
- Enter/Space activate buttons and links

### ARIA

- Images have meaningful alt text (or `alt=""` for decorative)
- Form inputs have associated labels
- Dynamic content changes are announced (aria-live regions)
- Custom components have appropriate ARIA roles

### Visual

- Color contrast minimum 4.5:1 for normal text, 3:1 for large text
- Information not conveyed by color alone
- Text readable at 200% zoom
- Respects `prefers-reduced-motion` setting

---

## Integration Testing

### API Endpoints

- Correct HTTP methods (GET for reads, POST for creates, etc.)
- Proper status codes (200, 201, 400, 404, 500)
- Error responses include actionable messages
- Authentication required where expected

### Data Format Validation

- Phone numbers normalized consistently
- Dates handled in correct timezone (use `getFullYear()/getMonth()/getDate()`, never `toISOString().split("T")[0]`)
- Currency/numbers formatted per locale
- UTF-8 encoding for international characters

### External Services

- API keys not exposed in client-side code (view page source)
- Rate limiting handled gracefully
- Fallback behavior when external service is down
- No CORS errors in console

---

## AI-Specific Testing (when applicable)

### Conversation Flow

- AI responds coherently to the first message
- Multi-turn conversations maintain context
- Tool calls execute and results render correctly
- A stop condition is set so the pipeline continues after tool calls and is bounded (critical: a missing one has stalled a production chat pipeline before, with no error shown)

### Rendering

- All AI response part types render correctly
- Unknown part types show fallback, not blank space
- Streaming responses display incrementally
- Tool results display inline with conversation

### Configuration

- Model ID matches expected version
- System prompt loads correctly
- Temperature/max_tokens within expected ranges
- API key environment variable is set in production
