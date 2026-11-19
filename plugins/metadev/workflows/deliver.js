export const meta = {
  name: 'deliver',
  description: 'Build a mandate from its design, review the diff independently, run QA, and loop fixes until QA passes or the round limit is reached',
  whenToUse: 'Checkpoint 3 of a mandate, after design.md is approved. Pass mandateDir, branch, testTarget and workstreams as args; designReview and security when the mandate has a design spec or touches auth, payments or personal data.',
  phases: [
    { title: 'Build', detail: 'one builder per workstream, in design order; parallel builders each get their own worktree and are merged afterwards' },
    { title: 'Review', detail: 'independent reviewers read the diff; Sasha joins them when security is set' },
    { title: 'QA', detail: 'Teresa tests against requirements' },
    { title: 'Design review', detail: 'Vera compares the build with the design spec, once, when designReview is set' },
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
const designReview = input.designReview === true
const security = input.security === true
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

const DESIGN = {
  type: 'object',
  properties: {
    verdict: { type: 'string', enum: ['matches spec', 'changes needed'] },
    notSeen: { type: 'string', description: 'screens, widths or states that could not be compared, and why; empty if none' },
    issues: ISSUES.properties.issues,
  },
  required: ['verdict', 'issues'],
}

const VERDICT = {
  type: 'object',
  properties: { real: { type: 'boolean' }, reason: { type: 'string' } },
  required: ['real', 'reason'],
}

// ---- helpers --------------------------------------------------------------

const blocking = issues => issues.filter(i => i.severity === 'Critical' || i.severity === 'High')
const minor = issues => issues.filter(i => i.severity !== 'Critical' && i.severity !== 'High')
const owners = BUILDERS.filter(b => workstreams.some(w => w.agent === b))
const ownerOf = issue => (owners.includes(issue.owner) ? issue.owner : owners[0])
const list = issues => issues.map((i, n) => `${n + 1}. [${i.severity}] ${i.title}\n   Where: ${i.where}\n   Evidence: ${i.evidence}`).join('\n')
const isolated = runParallel && workstreams.length > 1
const mandateName = mandateDir.replace(/\/+$/, '').split('/').pop()
const screensDir = `docs/qa/${mandateName}/screens`
const ownersLine = workstreams.map(w => `${w.agent} (${w.scope})`).join('; ')
const workBranch = i => `${branch}--${workstreams[i].agent}-${i + 1}`

const buildPrompt = (w, i) => `Mandate folder: ${mandateDir}.
${isolated
    ? `You are in your own git worktree, because other builders are working at the same time. Create the branch ${workBranch(i)} from ${branch} here (from main if ${branch} does not exist) and commit only on it. Do not check out ${branch} itself. The worktree is a fresh checkout: files that are not tracked by git, such as installed dependencies and local environment files, are not in it.`
    : `Branch: ${branch} (check it out; create it from main if it does not exist).`}
Your workstream, as assigned in design.md: ${w.scope}
${w.paths && w.paths.length ? `You own these paths: ${w.paths.join(', ')}. Do not edit files outside them.` : ''}
${workstreams.length > 1 ? `Other workstreams on this mandate: ${workstreams.filter(o => o !== w).map(o => `${o.agent} - ${o.scope}`).join('; ')}. Leave their files alone.` : ''}
Build it, verify it, commit on the branch, and update delivery.md${isolated ? ' by adding a section for your workstream only' : ''}.`

// state that every exit reports
let builds = []
let round = 0
let qa = null
let open = [] // blocking issues not yet fixed
let reviewFixed = [] // confirmed review issues the builders fixed
let reviewMinor = [] // Medium and Low review findings; reported, not fixed here
let reviewUnconfirmed = [] // blocking review findings that verification did not confirm
let reviewIncomplete = [] // review lenses that did not return
let design = null // Vera's review of the build, when it ran
let designMinor = []

const result = (outcome, extra) => ({
  outcome,
  fixRounds: round,
  risk: qa ? qa.risk : 'not-assessed',
  riskReason: qa ? qa.riskReason || '' : '',
  notTested: qa ? qa.notTested || '' : 'QA was not run',
  openBlockingIssues: open,
  otherIssues: [
    ...reviewMinor.map(i => ({ ...i, source: 'review' })),
    ...(qa ? minor(qa.issues).map(i => ({ ...i, source: 'qa' })) : []),
    ...designMinor.map(i => ({ ...i, source: 'design' })),
  ],
  securityReview: !security ? 'not-requested' : reviewIncomplete.includes('security') ? 'did-not-run' : 'done',
  designReview: !designReview ? 'not-requested' : design ? { verdict: design.verdict, notSeen: design.notSeen || '' } : 'did-not-run',
  reviewFixed,
  reviewFixedVerifiedByQa: Boolean(qa) && reviewFixed.length > 0,
  reviewUnconfirmed,
  reviewIncomplete,
  workstreamBranches: isolated ? workstreams.map((w, i) => workBranch(i)) : [],
  builds,
  ...extra,
})

// ---- Build ----------------------------------------------------------------

phase('Build')
const build = (w, i) => agent(buildPrompt(w, i), {
  label: `build:${w.agent}`, phase: 'Build', agentType: `metadev:${w.agent}`, schema: BUILD,
  ...(isolated ? { isolation: 'worktree' } : {}),
})
if (isolated) {
  builds = await parallel(workstreams.map((w, i) => () => build(w, i)))
} else {
  for (let i = 0; i < workstreams.length; i++) {
    const r = await build(workstreams[i], i)
    builds.push(r)
    if (!r || r.status !== 'done') break // later workstreams depend on this one
  }
}

const stuck = workstreams.map((w, i) => ({ w, r: builds[i] })).filter(x => !x.r || x.r.status !== 'done')
if (stuck.length) {
  return result('build-blocked', {
    blocked: stuck.map(x => ({ agent: x.w.agent, scope: x.w.scope, status: x.r ? x.r.status : 'not-run-or-failed', question: x.r ? x.r.question || x.r.summary : '' })),
  })
}

if (isolated) {
  const merged = await agent(
    `Builders worked in parallel, each on its own branch in its own git worktree. From the main working tree, bring their work together on ${branch} (create it from main if it does not exist).
Merge these branches into ${branch}, one at a time, in this order: ${workstreams.map((w, i) => `${workBranch(i)} (${w.agent} - ${w.scope})`).join('; ')}.
If ${mandateDir}/delivery.md conflicts, keep every workstream's section. If any other file conflicts, abort that merge and return status "blocked", naming the files and the two branches: the workstreams were not parallel-safe, and resolving product code is not your job.
After the last merge, run the project's build and tests on ${branch} and report what they showed. If they fail, return status "blocked" with the failure. Do not edit product code. Leave the workstream branches and worktrees in place.`,
    { label: 'build:merge', phase: 'Build', schema: BUILD },
  )
  if (!merged || merged.status !== 'done') {
    return result('build-blocked', {
      blocked: [{ agent: 'merge', scope: `merge of the workstream branches into ${branch}`, status: merged ? merged.status : 'not-run-or-failed', question: merged ? merged.question || merged.summary : '' }],
    })
  }
}

// ---- Review (independent of the builders) ---------------------------------

phase('Review')
const diffReview = ask => `Review the diff of branch ${branch} against main (git diff main...${branch}) for ${ask}.
Read ${mandateDir}/requirements.md and ${mandateDir}/design.md for intent. You did not write this code; look for where it is wrong.
Report only defects you can point to in the diff, with the code path or input that triggers them. Style preferences are not defects.
Set owner to the builder whose workstream contains the file: ${ownersLine}.`
const LENSES = [
  { key: 'correctness', prompt: diffReview('logic errors, unhandled states, race conditions, and any place the code does not do what design.md and requirements.md say') },
  { key: 'failure-and-security', prompt: diffReview('swallowed errors and silent fallbacks, missing input validation, missing authorization checks, secrets in code, injection paths, and irreversible or unsafe migrations') },
]
if (security) {
  LENSES.push({
    key: 'security',
    agentType: 'metadev:sasha',
    prompt: `Scope: a diff. Mandate folder: ${mandateDir}. Review what branch ${branch} changes against main (git diff main...${branch}), and the existing code it relies on for authentication, authorization and data access.
Read requirements.md and design.md for what the change is meant to do and what data it touches. To demonstrate a finding, use: ${testTarget}
Write your report as your contract says, and return every finding as an issue with your severity. Set owner to the builder whose workstream contains the file: ${ownersLine}.`,
  })
}
const reviewed = await pipeline(
  LENSES,
  lens => agent(lens.prompt, { label: `review:${lens.key}`, phase: 'Review', schema: ISSUES, ...(lens.agentType ? { agentType: lens.agentType } : {}) }),
  async found => {
    const verdicts = await parallel(blocking(found.issues).map(issue => () =>
      agent(
        `A reviewer reported this defect on branch ${branch}:\n${list([issue])}\nTry to show it is NOT a real defect: read the code, follow the path, and run it if you can. Answer real=true only if you could confirm it.`,
        { label: `verify:${issue.title.slice(0, 40)}`, phase: 'Review', schema: VERDICT },
      ).then(v => ({ issue, verdict: v }))))
    return { minor: minor(found.issues), verdicts: verdicts.filter(Boolean) }
  },
)
reviewed.forEach((r, n) => {
  if (!r) { reviewIncomplete.push(LENSES[n].key); return }
  reviewMinor.push(...r.minor)
  for (const { issue, verdict } of r.verdicts) {
    if (verdict && verdict.real) open.push(issue)
    else reviewUnconfirmed.push({ ...issue, reason: verdict ? verdict.reason : 'the verification did not return' })
  }
})
log(`Review: ${open.length} confirmed blocking issue(s), ${reviewUnconfirmed.length} not confirmed, ${reviewMinor.length} Medium or Low reported without a fix`)
if (reviewIncomplete.length) log(`Review lens did not return: ${reviewIncomplete.join(', ')}. The diff was not reviewed for it.`)

// ---- QA and fix loop ------------------------------------------------------

const fix = (owner, issues, n) => agent(
  `Mandate folder: ${mandateDir}. Branch: ${branch}.
These confirmed issues are in your workstream. Fix each one, add a test that would have caught it, verify, commit, and note the fixes in delivery.md.
${list(issues)}`,
  { label: `fix:${owner}:r${n}`, phase: 'Fix', agentType: `metadev:${owner}`, schema: BUILD },
)
// Returns the fixes that did not finish; an empty list means every owner reported done.
const fixAll = async (issues, n) => {
  const failed = []
  // one owner at a time: fixes may touch neighbouring code
  for (const owner of owners) {
    const mine = issues.filter(i => ownerOf(i) === owner)
    if (!mine.length) continue
    const r = await fix(owner, mine, n)
    if (!r || r.status !== 'done') {
      failed.push({ agent: owner, status: r ? r.status : 'not-run-or-failed', question: r ? r.question || r.summary : '', issues: mine })
    }
  }
  return failed
}

if (open.length) {
  phase('Fix')
  const failed = await fixAll(open, 0)
  if (failed.length) return result('fix-blocked', { blocked: failed })
  reviewFixed = open
  open = []
}

if (runQa) {
  while (true) {
    phase('QA')
    qa = await agent(
      `Mandate folder: ${mandateDir}. Branch: ${branch}. Test target: ${testTarget}
${round === 0
    ? 'Test the build against requirements.md and design.md, then write qa-report.md.'
    : `This is re-test round ${round}. First verify these issues are fixed (reproduce the original, confirm the fix, check nearby regressions), then re-run the main flow, and update qa-report.md.\n${list(open)}`}
${round === 0 && reviewFixed.length ? `Code review found and the builders fixed these before you started; confirm they hold:\n${list(reviewFixed)}` : ''}
${designReview && !design ? `Vera will review the interface against the design spec from your screenshots. Save one of each screen in scope at 375, 768 and 1280 pixels wide, and of each empty, loading, error and success state you reach, under ${screensDir}/, named by screen, state and width. If you have no browser tools, say so under what was not tested.` : ''}
Set each issue's owner to the builder whose workstream it belongs to: ${ownersLine}.`,
      { label: `qa:r${round}`, phase: 'QA', agentType: 'metadev:teresa', schema: QA },
    )
    if (!qa) return result('qa-did-not-run')
    open = blocking(qa.issues)
    // Vera reviews once, the first time the build is sound enough to look at
    if (designReview && !design && !qa.issues.some(i => i.severity === 'Critical')) {
      phase('Design review')
      design = await agent(
        `Mandate folder: ${mandateDir}. Branch: ${branch}. Review the built interface against the design spec in design.md.
Teresa saved screenshots under ${screensDir}/; read them, and read the component code on the branch for the states and widths they do not show. Say in notSeen what you could not compare.
Write the review to docs/design/${mandateName}-review.md, and return each difference as an issue with the severity your contract gives.
Set each issue's owner to the builder whose workstream it belongs to: ${ownersLine}.`,
        { label: 'design-review', phase: 'Design review', agentType: 'metadev:vera', schema: DESIGN },
      )
      if (design) {
        designMinor = minor(design.issues)
        open = [...open, ...blocking(design.issues)]
      } else {
        log('Design review did not return; the build was not compared with the design spec')
      }
    }
    if (qa.verdict === 'PASS' && !open.length) break
    if (!open.length) {
      log('QA failed without a Critical or High issue; there is nothing for a builder to fix, so stopping for the owner')
      break
    }
    if (round >= maxFixRounds) {
      log(`QA still failing after ${round} fix round(s); stopping for the owner`)
      break
    }
    round += 1
    phase('Fix')
    const failed = await fixAll(open, round)
    if (failed.length) return result('fix-blocked', { blocked: failed })
  }
}

return result(!runQa ? 'built-and-reviewed' : qa.verdict === 'PASS' && !open.length ? 'qa-passed' : 'qa-failed')
