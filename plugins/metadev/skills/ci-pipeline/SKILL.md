---
name: ci-pipeline
description: Designing or repairing a CI/CD pipeline so that it fails only on real problems, gives feedback fast and tells the developer what to fix. Use when adding the first automated check to a repo, adding a check after a gap was found, or fixing a pipeline that is slow, flaky or ignored.
user-invocable: false
---

# CI Pipeline

A good outcome is a small pipeline that people trust: when it goes red something is actually wrong, the message says what, and it finishes quickly enough that nobody is tempted to skip it.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-github-actions.md` (plugin, `foundations` skill) | Where workflows live, trigger types, path filters, the build-check workflow shape, scheduled runs |
| Project `knowledge/foundations/foundation-infrastructure.md` | Optional. Production URL, if the pipeline includes a scheduled production check |

The project's install, build and test commands are read from its `package.json` and README, not from a foundation.

## Required context

- Required: the problem the check must catch. Name a real failure that happened or a gap the team identified, not a general wish for "more CI".
- Required: the repo's existing workflows in `.github/workflows/` and how they have behaved (pass rate, duration, whether people re-run or bypass them).
- Required: the project's build and test commands, and that they pass locally.
- Optional: the branch and PR conventions of the repo (which branch is protected, what triggers a deployment).

## Approach

1. **Start with one workflow that checks one important thing.** Pipelines start minimal and earn complexity through real need. For most projects the first check is "the application installs, builds and its tests pass" on every PR to the main branch.
2. **Pick the trigger from the purpose.**

   | Purpose | Trigger |
   | --- | --- |
   | Validation before merge: structural checks, build, tests | `pull_request` |
   | Post-merge checks, deployment triggers | `push` to the main branch |
   | Audits and one-off operations | `workflow_dispatch` |
   | Periodic environment or production checks | `schedule` |

3. **Scope it with path filters** so a documentation-only change does not wait for an application build. Limit the build check to the source directories and the dependency manifest.
4. **Write the build check.** Use the lockfile install and the dependency cache; both keep it fast and reproducible.

   ```yaml
   name: Build Check
   on:
     pull_request:
       branches: [main]
       paths:
         - 'src/**'
         - 'package.json'

   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v7
         - uses: actions/setup-node@v7
           with:
             node-version: '24'   # match the project's own Node version; 20 is end of life
             cache: 'npm'
         - run: npm ci
         - run: npm run build
         - run: npm test
   ```

5. **Add structural checks only for structure the repo really depends on.** A shell loop that confirms required files exist, or that files of a given kind have the expected header, is cheap and catches broken conventions before merge. Each one must print which file failed and what is missing:

   ```yaml
   - name: Check required files
     run: |
       for dir in <parent>/*/; do
         if [ ! -f "$dir/<required-file>" ]; then
           echo "ERROR: $dir missing <required-file>"
           exit 1
         fi
       done
   ```

6. **Make every failure message say what is wrong and how to fix it.** The developer should not need to read the workflow file to understand a red check.
7. **Keep validation under two minutes.** Measure the run time after the first few runs. If it is slower, cache, narrow the path filter, or move the slow part to a post-merge or scheduled workflow.
8. **Deal with flaky tests at once.** A test that fails intermittently is worse than no test, because it teaches people to re-run and ignore red. Fix it or remove it.
9. **Remember what a merge does.** Where the hosting project deploys automatically from the main branch, every merge is a production deployment. The PR checks are the last gate, so they must cover what you would not want in production.
10. **Prove the check works in both directions.** Open a PR that should pass and confirm it is green; push a commit that breaks the thing being checked and confirm it goes red with a clear message. Then remove the breaking commit.
11. **Add the next check only when a gap is identified**, for example by a retrospective or an incident. Record in the PR which real problem the new check would have caught.

## Done means

- The workflow file is in `.github/workflows/` and runs on the intended trigger.
- A passing PR shows the check green; a deliberately broken commit shows it red, and the failure message names the problem.
- The validation run completes in under two minutes (read the duration from the run page).
- No check in the pipeline has failed intermittently on unchanged code.
- Each check can be traced to a real problem it catches, stated in the PR that added it.
- No secret appears in the workflow file or its logs.

## Anti-patterns

- **A check that cries wolf.** A pipeline step that fails on things that are not problems gets ignored and then removed, and takes the useful checks' credibility with it. Every check must earn its place by catching actual issues.
- **A slow pipeline.** Slow pipelines get skipped. Speed is part of correctness here.
- **Vague failures.** "Validation failed" sends the developer hunting. Print the file and the fix.
- **Keeping a flaky test "for coverage".** Fix it or remove it.
- **Building the full pipeline up front.** Lint, type-check, end-to-end tests, audits and deployment gates added on day one, before any of them has caught anything, produce noise and maintenance. Adopt incrementally.
- **Treating a green pipeline as a delivered release.** The pipeline proves the code builds. Production still has to be verified; see the `release-deployment` skill.
