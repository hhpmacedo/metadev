export const meta = {
  name: 'deliver',
  description: 'Build a mandate from its design, review the diff independently, run QA, and loop fixes until QA passes or the round limit is reached',
  whenToUse: 'Checkpoint 3 of a mandate, after design.md is approved. Pass mandateDir, branch, testTarget and workstreams as args.',
  phases: [
    { title: 'Build', detail: 'one builder per workstream, in design order' },
    { title: 'Review', detail: 'independent reviewers read the diff' },
    { title: 'QA', detail: 'Teresa tests against requirements' },
    { title: 'Fix', detail: 'owners fix blocking issues, Teresa re-verifies' },
  ],
}

// ---- input ----------------------------------------------------------------

const input = typeof args === 'string' ? JSON.parse(args) : args || {}
const mandateDir = input.mandateDir
const branch = input.branch
const testTarget = input.testTarget || 'not given - start the project dev server yourself and say how you did it'
const workstreams = Array.isArray(input.workstreams) ? input.workstreams : []
const runParallel = input.parallel === true
const runQa = input.qa !== false
const maxFixRounds = Number.isInteger(input.maxFixRounds) ? input.maxFixRounds : 2

const BUILDERS = ['diego', 'leo', 'rafa']
if (!mandateDir || !branch) throw new Error('deliver: args.mandateDir and args.branch are required')
if (!workstreams.length) throw new Error('deliver: args.workstreams must list at least one workstream')
for (const w of workstreams) {
  if (!BUILDERS.includes(w.agent)) throw new Error(`deliver: workstream agent must be one of ${BUILDERS.join(', ')} (got "${w.agent}")`)
  if (!w.scope) throw new Error('deliver: every workstream needs a scope')
}

// ---- schemas --------------------------------------------------------------

const BUILD = {
  type: 'object',
  properties: {
    status: { type: 'string', enum: ['done', 'blocked', 'needs-decision'] },
    summary: { type: 'string' },
    verification: { type: 'string', description: 'commands run and what they showed' },
    deviations: { type: 'string' },
    question: { type: 'string', description: 'the exact blocker or decision needed, empty if none' },
  },
  required: ['status', 'summary', 'verification'],
}

const ISSUES = {
  type: 'object',
  properties: {
    issues: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title: { type: 'string' },
          severity: { type: 'string', enum: ['Critical', 'High', 'Medium', 'Low'] },
          where: { type: 'string', description: 'file:line, URL or screen' },
          evidence: { type: 'string', description: 'steps to reproduce, or the code path that fails' },
          owner: { type: 'string', enum: BUILDERS },
        },
        required: ['title', 'severity', 'where', 'evidence', 'owner'],
      },
    },
  },
  required: ['issues'],
}

const QA = {
  type: 'object',
  properties: {
    verdict: { type: 'string', enum: ['PASS', 'FAIL'] },
    risk: { type: 'string', enum: ['low-risk', 'high-risk'] },
    riskReason: { type: 'string' },
    notTested: { type: 'string' },
    issues: ISSUES.properties.issues,
  },
  required: ['verdict', 'risk', 'issues'],
}

const VERDICT = {
  type: 'object',
  properties: { real: { type: 'boolean' }, reason: { type: 'string' } },
  required: ['real', 'reason'],
}

// ---- helpers --------------------------------------------------------------

const blocking = issues => issues.filter(i => i.severity === 'Critical' || i.severity === 'High')
const owners = BUILDERS.filter(b => workstreams.some(w => w.agent === b))
const ownerOf = issue => (owners.includes(issue.owner) ? issue.owner : owners[0])
const list = issues => issues.map((i, n) => `${n + 1}. [${i.severity}] ${i.title}\n   Where: ${i.where}\n   Evidence: ${i.evidence}`).join('\n')

const buildPrompt = w => `Mandate folder: ${mandateDir}. Branch: ${branch} (check it out; create it from main if it does not exist).
Your workstream, as assigned in design.md: ${w.scope}
${w.paths && w.paths.length ? `You own these paths: ${w.paths.join(', ')}. Do not edit files outside them.` : ''}
${workstreams.length > 1 ? `Other workstreams on this mandate: ${workstreams.filter(o => o !== w).map(o => `${o.agent} - ${o.scope}`).join('; ')}. Leave their files alone.` : ''}
Build it, verify it, commit on the branch, and update delivery.md.`

// ---- Build ----------------------------------------------------------------

phase('Build')
const build = w => agent(buildPrompt(w), { label: `build:${w.agent}`, phase: 'Build', agentType: `metadev:${w.agent}`, schema: BUILD })
let builds
if (runParallel && workstreams.length > 1) {
  builds = await parallel(workstreams.map(w => () => build(w)))
} else {
  builds = []
  for (const w of workstreams) {
    const r = await build(w)
    builds.push(r)
    if (!r || r.status !== 'done') break // later workstreams depend on this one
  }
}

const stuck = workstreams.map((w, i) => ({ w, r: builds[i] })).filter(x => !x.r || x.r.status !== 'done')
if (stuck.length) {
  return {
    outcome: 'build-blocked',
    blocked: stuck.map(x => ({ agent: x.w.agent, scope: x.w.scope, status: x.r ? x.r.status : 'not-run-or-failed', question: x.r ? x.r.question || x.r.summary : '' })),
    builds,
  }
}

// ---- Review (independent of the builders) ---------------------------------

phase('Review')
const LENSES = [
  { key: 'correctness', ask: 'logic errors, unhandled states, race conditions, and any place the code does not do what design.md and requirements.md say' },
  { key: 'failure-and-security', ask: 'swallowed errors and silent fallbacks, missing input validation, missing authorization checks, secrets in code, injection paths, and irreversible or unsafe migrations' },
]
const reviewed = await pipeline(
  LENSES,
  lens => agent(
    `Review the diff of branch ${branch} against main (git diff main...${branch}) for ${lens.ask}.
Read ${mandateDir}/requirements.md and ${mandateDir}/design.md for intent. You did not write this code; look for where it is wrong.
Report only defects you can point to in the diff, with the code path or input that triggers them. Style preferences are not defects.
Set owner to the builder whose workstream contains the file: ${workstreams.map(w => `${w.agent} (${w.scope})`).join('; ')}.`,
    { label: `review:${lens.key}`, phase: 'Review', schema: ISSUES },
  ),
  found => parallel(blocking(found.issues).map(issue => () =>
    agent(
      `A reviewer reported this defect on branch ${branch}:\n${list([issue])}\nTry to show it is NOT a real defect: read the code, follow the path, and run it if you can. Answer real=true only if you could confirm it.`,
      { label: `verify:${issue.title.slice(0, 40)}`, phase: 'Review', schema: VERDICT },
    ).then(v => (v && v.real ? issue : null)))),
)
let open = reviewed.filter(Boolean).flat().filter(Boolean)
log(`Review: ${open.length} confirmed blocking issue(s)`)

// ---- QA and fix loop ------------------------------------------------------

const fix = (owner, issues, round) => agent(
  `Mandate folder: ${mandateDir}. Branch: ${branch}.
These confirmed issues are in your workstream. Fix each one, add a test that would have caught it, verify, commit, and note the fixes in delivery.md.
${list(issues)}`,
  { label: `fix:${owner}:r${round}`, phase: 'Fix', agentType: `metadev:${owner}`, schema: BUILD },
)
const fixAll = async (issues, round) => {
  // one owner at a time: fixes may touch neighbouring code
  for (const owner of owners) {
    const mine = issues.filter(i => ownerOf(i) === owner)
    if (mine.length) await fix(owner, mine, round)
  }
}

let qa = null
let round = 0
if (open.length) {
  phase('Fix')
  await fixAll(open, 0)
}

if (runQa) {
  while (true) {
    phase('QA')
    qa = await agent(
      `Mandate folder: ${mandateDir}. Branch: ${branch}. Test target: ${testTarget}
${round === 0
    ? 'Test the build against requirements.md and design.md, then write qa-report.md.'
    : `This is re-test round ${round}. First verify these issues are fixed (reproduce the original, confirm the fix, check nearby regressions), then re-run the main flow, and update qa-report.md.\n${list(open)}`}
${round === 0 && open.length ? `Code review found and the builders fixed these before you started; confirm they hold:\n${list(open)}` : ''}
Set each issue's owner to the builder whose workstream it belongs to: ${workstreams.map(w => `${w.agent} (${w.scope})`).join('; ')}.`,
      { label: `qa:r${round}`, phase: 'QA', agentType: 'metadev:teresa', schema: QA },
    )
    if (!qa) return { outcome: 'qa-did-not-run', builds, reviewIssues: open }
    open = blocking(qa.issues)
    if (qa.verdict === 'PASS' && !open.length) break
    if (round >= maxFixRounds) {
      log(`QA still failing after ${round} fix round(s); stopping for the owner`)
      break
    }
    round += 1
    phase('Fix')
    await fixAll(open, round)
  }
}

return {
  outcome: !runQa ? 'built-and-reviewed' : qa.verdict === 'PASS' && !open.length ? 'qa-passed' : 'qa-failed',
  fixRounds: round,
  risk: qa ? qa.risk : 'not-assessed',
  riskReason: qa ? qa.riskReason || '' : '',
  notTested: qa ? qa.notTested || '' : 'QA was not run',
  openBlockingIssues: open,
  otherIssues: qa ? qa.issues.filter(i => !blocking([i]).length) : [],
  builds,
}
