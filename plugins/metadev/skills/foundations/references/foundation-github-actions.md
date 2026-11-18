# Foundation: GitHub Actions

- **Last validated:** 2026-11-18, checked against the GitHub Actions documentation (workflow syntax, events that trigger workflows), the `actions/checkout`, `actions/setup-node` and `actions/runner-images` repositories, and the Node.js release schedule by an automated documentation check. Not yet confirmed in a live project.
- **Versions checked:** `actions/checkout` v7.0.1, `actions/setup-node` v7.1.0, `ubuntu-latest` = Ubuntu 24.04 runner image 20261111.370.1, Node.js release lines 22, 24 and 26, npm 11.19.1 (`npm ci` help), curl 8.5.0
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** workflow file location, triggers, path filters, the Node build-check job, scheduled jobs, how a step fails
- **Does not cover:** hosting-side deployment (see `foundation-vercel.md`), database tooling (see `foundation-supabase-cli.md`), branch protection and repository settings, any one project's workflows (project `knowledge/foundations/`)

## Workflow files

- Workflows are YAML files in `.github/workflows/` in the repository, with a `.yml` or `.yaml` extension.
- A workflow has a `name`, an `on` block (triggers) and one or more `jobs`. Each job names a runner (`runs-on: ubuntu-latest`) and a list of `steps`.
- `ubuntu-latest` is Ubuntu 24.04 as of 2026-11-18. An `ubuntu-26.04` image exists but `ubuntu-latest` does not point to it yet.
- A step either uses a published action (`uses:`) or runs shell commands (`run:`).
- A `run` step fails when its shell exits non-zero. On Linux runners the default shell is `bash -e {0}`, so the script stops at the first command that returns non-zero and the step fails with that exit code. `-o pipefail` is added only when the step sets `shell: bash` explicitly.
- `exit 1` after an `echo` is the way a script step reports a failure with a message.

## Triggers

| Trigger | When it runs | Typical use |
| --- | --- | --- |
| `pull_request` | On PRs targeting the listed branches | Validation before merge: structural checks, build, tests |
| `push` (to `main`) | After a merge or direct push | Post-merge checks, deployment triggers |
| `workflow_dispatch` | When started manually | Audits, one-off operations |
| `schedule` | On a cron schedule | Periodic environment parity or production health checks |

- `pull_request` and `push` accept a `branches` filter and a `paths` filter. With `paths`, the workflow runs when at least one changed file matches one of the patterns.
- `paths-ignore` is the inverse: the workflow does not run when every changed file matches one of its patterns. `paths` and `paths-ignore` cannot both be used for the same event in one workflow (the same holds for `branches` and `branches-ignore`).
- Path filters are not evaluated for pushes of tags.
- `schedule` takes a five-field POSIX cron expression. `'0 9 * * 1-5'` is 09:00 Monday to Friday.
- Schedules run in UTC by default. A schedule entry accepts an optional `timezone` key next to `cron`, holding an IANA timezone name (for example `timezone: "America/New_York"`), and the cron expression is then read in that timezone.
- The shortest schedule interval is once every 5 minutes.
- Scheduled runs can be delayed when GitHub Actions is under high load, and under sufficiently high load some queued runs are dropped. The start of every hour is a high-load time, which applies to `'0 9 * * 1-5'`.
- A scheduled workflow runs only from the workflow file on the default branch.
- In a public repository, scheduled workflows are disabled automatically after 60 days without repository activity.

## Node build-check job

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
          node-version: '26'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - run: npm test
```

| Element | Fact |
| --- | --- |
| `actions/checkout@v7` | Checks out the repository into the runner. v7 is the current major version (v7.0.1). v4 is three majors behind; it still receives releases (v4.4.0, July 2026). v5 and later run on the Node 24 action runtime and need Actions Runner v2.327.1 or newer, which matters only on self-hosted runners. From v7, checkout refuses fork pull request code under `pull_request_target` and `workflow_run` unless `allow-unsafe-pr-checkout: true` is set; the `pull_request` trigger used here is not affected. |
| `actions/setup-node@v7` | Installs the requested Node version; `cache: 'npm'` caches the npm download cache between runs. v7 is the current major version (v7.1.0). Since v6, caching is also switched on without the `cache` input when `package.json` names npm in `packageManager` or `devEngines.packageManager`; `package-manager-cache: false` turns that off. v7 no longer exports a placeholder `NODE_AUTH_TOKEN`, which affects only jobs that set `registry-url`. |
| `node-version: '26'` | Node 26 is the Active LTS line (LTS since 2026-10-28, end of life 2029-04-30). Node 24 and Node 22 are in Maintenance LTS (end of life 2028-04-30 and 2027-04-30). Node 20 reached end of life on 2026-04-30. Without `setup-node`, `ubuntu-latest` provides Node 22 (22.23.4 in image 20261111.370.1). |
| `npm ci` | Requires an existing lockfile, installs exactly what it specifies, and exits with an error if the lockfile and `package.json` disagree |

## Scheduled HTTP check

```yaml
name: Production Health Check
on:
  schedule:
    - cron: '0 9 * * 1-5'

jobs:
  health:
    runs-on: ubuntu-latest
    steps:
      - name: Check production health
        run: |
          response=$(curl -s -o /dev/null -w "%{http_code}" https://<public-production-url>/api/health)
          if [ "$response" != "200" ]; then
            echo "UNHEALTHY: Production returned $response"
            exit 1
          fi
          echo "HEALTHY: Production is up"
```

- This schedule fires at 09:00 UTC, Monday to Friday, because no `timezone` is set.
- `curl -s -o /dev/null -w "%{http_code}"` prints only the HTTP status code.
- When curl cannot connect at all, it exits non-zero (and prints `000`). Under the default `bash -e` shell the step then fails on the `response=` line with curl's exit code, before the `UNHEALTHY` message is printed. The `UNHEALTHY` branch is reached when the server answers with a status other than 200.
- `curl -sf <url>` exits non-zero (exit code 22) on an HTTP error status, which fails the step without an explicit comparison.

## Structural check step

A shell loop in a `run` step can enforce repository conventions, for example that each directory of a given kind contains a required file, or that files of a given kind begin with YAML frontmatter:

```yaml
- name: Check frontmatter
  run: |
    for file in <dir>/*.md; do
      if ! head -1 "$file" | grep -q "^---"; then
        echo "ERROR: $file missing frontmatter"
        exit 1
      fi
    done
```

## Limits recorded by the team

| Item | Value |
| --- | --- |
| Target duration for PR validation checks | Under 2 minutes (a team target, not a platform limit) |

## Validation notes (2026-11-18)

- Sources:
  - https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
  - https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
  - https://github.com/actions/checkout (README and releases v5.0.0, v6.0.0, v7.0.0, v7.0.1)
  - https://github.com/actions/setup-node (README and releases v5.0.0, v6.0.0, v7.0.0, v7.1.0)
  - https://github.com/actions/runner-images (README and `images/ubuntu/Ubuntu2404-Readme.md`)
  - https://github.com/nodejs/Release (`schedule.json`) and https://nodejs.org/dist/index.json
  - `npm help ci` (npm 11.19.1), `curl --help all` and `man curl` (curl 8.5.0), and a local run of the health-check script under `bash -e`
- Corrected:
  - `actions/checkout@v4` "(unverified whether v4 is still the current major version)" -> `actions/checkout@v7`; v7 is current.
  - `actions/setup-node@v4` "(unverified whether v4 is still the current major version)" -> `actions/setup-node@v7`; v7 is current; automatic npm caching since v6 stated.
  - `node-version: '20'` "(unverified whether Node 20 is still a supported release line)" -> `'26'`; Node 20 reached end of life on 2026-04-30; Active LTS is 26, Maintenance LTS is 24 and 22; the runner image default is 22.
  - "Schedules are evaluated in UTC (unverified ...)" -> UTC by default, with an optional per-entry `timezone` key.
  - "`'0 9 * * 1-5'` is 09:00 on weekdays" -> 09:00 UTC unless `timezone` is set, and at a high-load time (start of the hour).
  - "With `paths`, the workflow runs only when a changed file matches" -> kept, with `paths-ignore`, the both-cannot-be-used rule and the tag exception added.
  - "A `run` step fails when its shell exits non-zero" -> kept, with the default shell (`bash -e {0}`, no `pipefail`) stated.
  - Scheduled HTTP check: added that a connection failure fails the step on the `curl` line, without the `UNHEALTHY` message.
  - `npm ci` "fails if the lockfile and `package.json` disagree" -> kept, with the lockfile requirement added.
  - Added, because existing schedule claims depend on them: 5-minute minimum interval, delay and dropping under load, default-branch rule, 60-day disabling in public repositories.
- Still unverified: none. Nothing in this file was run in a live workflow.
