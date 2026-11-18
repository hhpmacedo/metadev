# Foundation: GitHub Actions

- **Last validated:** not re-validated since February 2026 (carried over from `skills/devops/references/devops-patterns.md`)
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** workflow file location, triggers, path filters, the Node build-check job, scheduled jobs, how a step fails
- **Does not cover:** hosting-side deployment (see `foundation-vercel.md`), database tooling (see `foundation-supabase-cli.md`), branch protection and repository settings, any one project's workflows (project `knowledge/foundations/`)

## Workflow files

- Workflows are YAML files in `.github/workflows/` in the repository.
- A workflow has a `name`, an `on` block (triggers) and one or more `jobs`. Each job names a runner (`runs-on: ubuntu-latest`) and a list of `steps`.
- A step either uses a published action (`uses:`) or runs shell commands (`run:`).
- A `run` step fails when its shell exits non-zero. `exit 1` after an `echo` is the way a script step reports a failure with a message.

## Triggers

| Trigger | When it runs | Typical use |
| --- | --- | --- |
| `pull_request` | On PRs targeting the listed branches | Validation before merge: structural checks, build, tests |
| `push` (to `main`) | After a merge or direct push | Post-merge checks, deployment triggers |
| `workflow_dispatch` | When started manually | Audits, one-off operations |
| `schedule` | On a cron schedule | Periodic environment parity or production health checks |

- `pull_request` and `push` accept a `branches` filter and a `paths` filter. With `paths`, the workflow runs only when a changed file matches one of the patterns.
- `schedule` takes a five-field cron expression. `'0 9 * * 1-5'` is 09:00 on weekdays. Schedules are evaluated in UTC (unverified in the source, which says only "Weekdays at 9am").

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
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - run: npm test
```

| Element | Fact |
| --- | --- |
| `actions/checkout@v4` | Checks out the repository into the runner (unverified whether v4 is still the current major version) |
| `actions/setup-node@v4` | Installs the requested Node version; `cache: 'npm'` caches the npm download cache between runs (unverified whether v4 is still the current major version) |
| `node-version: '20'` | The Node version recorded in the source (unverified whether Node 20 is still a supported release line) |
| `npm ci` | Installs exactly what the lockfile specifies and fails if the lockfile and `package.json` disagree |

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

- `curl -s -o /dev/null -w "%{http_code}"` prints only the HTTP status code.
- `curl -sf <url>` exits non-zero on an HTTP error status, which fails the step without an explicit comparison.

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
