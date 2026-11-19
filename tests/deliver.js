// Drives plugins/metadev/workflows/deliver.js with mocked agents and checks its control flow.
// Run: node tests/deliver.js
const fs = require('fs')
const path = require('path')
const assert = require('assert')

const src = fs.readFileSync(path.join(__dirname, '../plugins/metadev/workflows/deliver.js'), 'utf8').replace('export const meta', 'const meta')
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor

async function run(args, handler) {
  const calls = []
  const agent = async (prompt, opts) => {
    calls.push(opts.label + (opts.isolation ? '[worktree]' : ''))
    return handler(opts.label, prompt)
  }
  const parallel = thunks => Promise.all(thunks.map(t => t().catch(() => null)))
  const pipeline = (items, ...stages) => Promise.all(items.map(async (item, i) => {
    let v = item
    try { for (const s of stages) v = await s(v, item, i) } catch (e) { return null }
    return v
  }))
  const result = await new AsyncFunction('args', 'agent', 'parallel', 'pipeline', 'phase', 'log', src)(args, agent, parallel, pipeline, () => {}, () => {})
  return { result, calls }
}

const done = { status: 'done', summary: 's', verification: 'v' }
const issue = (title, severity) => ({ title, severity, where: 'f:1', evidence: 'e', owner: 'leo' })
const base = { mandateDir: 'd', branch: 'mandate/x', workstreams: [{ agent: 'leo', scope: 'api' }, { agent: 'rafa', scope: 'ui' }] }

// Review finds A (High, confirmed), B (Low), C (Critical, not confirmed). QA passes with one Medium issue.
const team = (o = {}) => label => {
  if (label === 'build:merge') return o.merge || done
  if (label.startsWith('build:')) return done
  if (label === 'review:correctness') return o.review === null ? null : { issues: [issue('A', 'High'), issue('B', 'Low'), issue('C', 'Critical')] }
  if (label.startsWith('review:')) return { issues: [] }
  if (label.startsWith('verify:')) return { real: label.includes('A'), reason: 'r' }
  if (label.startsWith('fix:')) return o.fix || done
  if (label.startsWith('qa:')) return o.qa || { verdict: 'PASS', risk: 'low-risk', issues: [issue('Q', 'Medium')] }
}

const cases = {
  async 'sequential run passes and reports every finding'() {
    const { result: r, calls } = await run(base, team())
    assert.equal(r.outcome, 'qa-passed')
    assert.deepEqual(calls.filter(c => c.startsWith('build:')), ['build:leo', 'build:rafa'])
    assert.deepEqual(r.otherIssues.map(i => `${i.source}:${i.title}`), ['review:B', 'qa:Q'])
    assert.deepEqual(r.reviewFixed.map(i => i.title), ['A'])
    assert.deepEqual(r.reviewUnconfirmed.map(i => i.title), ['C'])
    assert.equal(r.reviewFixedVerifiedByQa, true)
    assert.equal(r.openBlockingIssues.length, 0)
  },
  async 'parallel builders are isolated and merged before review'() {
    const { result: r, calls } = await run({ ...base, parallel: true }, team())
    assert.deepEqual(calls.slice(0, 3), ['build:leo[worktree]', 'build:rafa[worktree]', 'build:merge'])
    assert.deepEqual(r.workstreamBranches, ['mandate/x--leo-1', 'mandate/x--rafa-2'])
    assert.equal(r.outcome, 'qa-passed')
  },
  async 'a failed merge stops before review'() {
    const { result: r, calls } = await run({ ...base, parallel: true }, team({ merge: { status: 'blocked', summary: 'conflict', verification: '' } }))
    assert.equal(r.outcome, 'build-blocked')
    assert.equal(r.blocked[0].agent, 'merge')
    assert.ok(!calls.some(c => c.startsWith('review:')))
  },
  async 'one workstream is never isolated'() {
    const { calls } = await run({ ...base, workstreams: [base.workstreams[0]], parallel: true }, team())
    assert.deepEqual(calls.filter(c => c.startsWith('build:')), ['build:leo'])
  },
  async 'without QA, fixed review issues are not reported as open'() {
    const { result: r } = await run({ ...base, qa: false }, team())
    assert.equal(r.outcome, 'built-and-reviewed')
    assert.equal(r.openBlockingIssues.length, 0)
    assert.deepEqual(r.reviewFixed.map(i => i.title), ['A'])
    assert.equal(r.reviewFixedVerifiedByQa, false)
  },
  async 'a fix that does not finish stops the run before QA'() {
    const { result: r, calls } = await run(base, team({ fix: { status: 'blocked', summary: 'x', verification: '', question: 'why' } }))
    assert.equal(r.outcome, 'fix-blocked')
    assert.equal(r.blocked[0].question, 'why')
    assert.deepEqual(r.openBlockingIssues.map(i => i.title), ['A'])
    assert.ok(!calls.some(c => c.startsWith('qa:')))
  },
  async 'a review lens that does not return is reported'() {
    const { result: r } = await run(base, team({ review: null }))
    assert.deepEqual(r.reviewIncomplete, ['correctness'])
  },
  async 'the fix loop stops at the round limit'() {
    const { result: r, calls } = await run(base, team({ qa: { verdict: 'FAIL', risk: 'low-risk', issues: [issue('Z', 'High')] } }))
    assert.equal(r.outcome, 'qa-failed')
    assert.equal(r.fixRounds, 2)
    assert.equal(calls.filter(c => c.startsWith('qa:')).length, 3)
    assert.deepEqual(r.openBlockingIssues.map(i => i.title), ['Z'])
  },
  async 'a QA failure with nothing blocking does not loop'() {
    const { result: r, calls } = await run(base, team({ qa: { verdict: 'FAIL', risk: 'low-risk', issues: [issue('M', 'Medium')] } }))
    assert.equal(r.outcome, 'qa-failed')
    assert.equal(calls.filter(c => c.startsWith('qa:')).length, 1)
  },
}

;(async () => {
  let failed = 0
  for (const [name, fn] of Object.entries(cases)) {
    try { await fn(); console.log(`ok   ${name}`) } catch (e) { failed++; console.log(`FAIL ${name}\n     ${e.message}`) }
  }
  process.exit(failed ? 1 : 0)
})()
