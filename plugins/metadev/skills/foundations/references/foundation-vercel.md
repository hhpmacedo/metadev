# Foundation: Vercel

- **Last validated:** 2026-11-18, checked against the Vercel documentation (vercel.com/docs) and the `--help` output of Vercel CLI 66.2.0 by an automated documentation check. Not yet confirmed in a live project.
- **Versions checked:** Vercel CLI 66.2.0 (`npm view vercel version`, `npx vercel --version`); Vercel platform documentation pages last updated between July and September 2026
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** Vercel CLI commands, project configuration, deployment and preview behaviour, environment variable scopes, URL access protection, function time limits, rollback by promotion
- **Does not cover:** Next.js framework behaviour, Supabase (see `foundation-supabase-cli.md` and `foundation-supabase.md`), CI workflows (see `foundation-github-actions.md`), any one project's URLs or variables (project `knowledge/foundations/`)

## CLI

The CLI is run through `npx vercel`; it is not assumed to be installed globally. All commands below are as documented for CLI 66.2.0.

| Command | What it does |
| --- | --- |
| `npx vercel` | Deploys the current directory to a preview deployment (`deploy` is the default command) |
| `npx vercel --prod` | Deploys to production (shorthand for `--environment production`) |
| `npx vercel --force` | Forces a new deployment without the build cache (`--with-cache` keeps the cache while still forcing) |
| `npx vercel ls` | Lists deployments of the linked project and their status (`ls` is an alias of `list`; 20 per page by default; `--status` and `--environment` filter) |
| `npx vercel inspect <deployment-id-or-url>` | Shows information about one deployment. `--logs` prints its build logs, `--wait` blocks until it completes, `--json` includes each function's maximum duration (`timeout`) |
| `npx vercel logs --deployment <deployment-id-or-url>` | Shows runtime logs (functions, middleware) filtered to one deployment. Since CLI 64.0.0 the command is a query, not a stream: by default the latest 100 records from the last 30 minutes, widened with `--since`. A positional deployment argument is deprecated; CLI 65.12.0 and later still accept it and print a warning. `--follow` is deprecated and no longer streams. The help text states "Team-owned projects only" |
| `npx vercel env ls --environment production` | Lists the environment variables set for the Production environment (`ls` is an alias of `list`). `--environment` needs CLI 64.6.0 or later; the older positional form `env ls production` is deprecated and in 66.2.0 still works with a warning |
| `npx vercel env add VARIABLE_NAME --environment production` | Adds an environment variable to the Production environment (prompts for the value, or takes it from stdin or `--value`). Without `--environment` it prompts for the environments; several can be given comma-separated. Variables added to Production, Preview or a custom environment are stored as Secret (write-only after saving) by default, those added to Development as Config (readable); `--type config` or `--type secret` sets it explicitly. The positional form `env add NAME production` is deprecated |
| `npx vercel env pull [file]` | Writes the project's Development environment variables to a local file (default `.env.local`); `--environment` selects another environment. If the file exists, pulled values are merged into it and local-only entries are kept |
| `npx vercel rollback <deployment-id-or-url>` | Instant Rollback: points the production domains back at a deployment that has previously served production, without rebuilding |
| `npx vercel promote <deployment-id-or-url>` | Makes an existing deployment the current production deployment. A deployment built for Production (for example a staged one) is promoted without a rebuild; a deployment built for Preview is rebuilt as a new production deployment, after a confirmation prompt (`--yes` skips it). Promoting also undoes a rollback |

## Project configuration

A typical Next.js project needs little or no `vercel.json`. When present it looks like this:

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs"
}
```

Each of these three properties overrides the corresponding Project Settings value (Build Command, Output Directory, Framework Preset).

## Deployments

- When a project is connected to a Git repository, every merge or push to the production branch (usually `main`; a project setting) creates a production deployment, and its production domains are assigned to it automatically unless auto-assignment has been turned off.
- Every push to any other branch creates a preview deployment with a generated URL; a pull request is previewed through the deployments of its branch. A pull request from a fork needs authorization from a team member before it is deployed.
- Previous deployments are kept only for the retention period. The default is 30 days on Hobby and Pro for every deployment type; on Enterprise it is 1 year for production and 180 days for pre-production. Regardless of age, a deployment with a production alias is kept, as are the last 3 (Hobby) or last 20 (Pro, Enterprise) ready production deployments. (Source: vercel.com/docs/deployment-retention)
- Reverting production to an earlier deployment is an Instant Rollback (`vercel rollback` or the dashboard). It reassigns the production domains to the existing deployment without rebuilding; the reassignment "usually finishes within seconds". Only deployments that previously served a production domain are eligible. On Hobby only the immediately previous production deployment can be rolled back to; on Pro and Enterprise any eligible deployment.
- After a rollback, auto-assignment of production domains is turned off: new pushes to the production branch do not go live until a deployment is promoted (`vercel promote` or the dashboard), which re-enables auto-assignment.
- A rolled-back deployment runs with the environment variables it was built with; later changes to variables are not applied to it.
- Only one rollback or promotion runs per project at a time.
- The documentation states that a deployment that has already been promoted cannot be promoted again and must be rolled back to instead. Whether `vercel promote` rejects a previously current deployment in every case is unverified (unverified: the rollback page also describes `promote` as the way to undo a rollback, and it was not run against a live project).
- A stale build cache sometimes causes build failures. `npx vercel --force` rebuilds without the cache; setting the project variable `VERCEL_FORCE_NO_BUILD_CACHE=1` does the same for Git-triggered builds.
- Vercel gives no guaranteed or typical duration for an automatic deployment after a push. It depends on the project's build. `vercel inspect --wait` and `vercel promote`/`vercel rollback` wait 3 minutes by default (`--timeout`); that is a CLI wait limit, not a build time.

## URL access

- New projects start with Deployment Protection set to Standard Protection with Vercel Authentication, unless the team has set a different default. Standard Protection, All Deployments protection and Vercel Authentication are included on Hobby, Pro and Enterprise. (Source: vercel.com/docs/deployments/environments, vercel.com/docs/deployment-protection/usage-and-pricing)
- Standard Protection protects every URL except the production domains. Protected URLs include preview URLs, Git branch URLs and the unique generated deployment URL of every deployment, including the production deployment's own generated URL. An unauthenticated visitor to a protected URL is redirected to a Vercel login, not shown the application.
- Under Standard Protection the production domains stay public: custom domains assigned to production, and the project's production `.vercel.app` domain listed in its domain settings. Whether the generated production URL of the form `<project>-<scope>.vercel.app` counts as a production domain is unverified (unverified: the documentation does not say which class it falls in).
- With the All Deployments scope, every URL is protected, including the production custom domain. With protection disabled, generated URLs are public. A legacy scope exists that leaves all up-to-date production URLs unprotected.
- `VERCEL_URL` and `VERCEL_BRANCH_URL` hold generated URLs and so point at protected addresses under Standard Protection. `VERCEL_PROJECT_PRODUCTION_URL` holds a production domain (the shortest custom domain, or the `.vercel.app` domain if there is none).
- `npx vercel curl <path-or-url>` requests a protected deployment using the project's Protection Bypass for Automation secret.
- A project can have both a custom domain and a `.vercel.app` domain. One domain can be set to redirect to another in the project's domain settings.

## Environment variables

- Each variable is applied to one or more environments: Production, Preview, Development, and any custom environments. A variable is available only in the environments it was applied to. A Preview variable can be limited to one Git branch, and then overrides the general Preview value for that branch.
- A change to a variable applies only to new deployments. Existing deployments, including one reached by rollback, keep the values they were built with.
- Secrets for deployed environments are stored in Vercel (dashboard or `vercel env add`), not in the repository. Local development uses `.env.local`, which `vercel env pull` creates from the Development environment.
- The total size of all variables is limited to 64 KB per deployment on every plan; functions on the Edge runtime are limited to 5 KB per variable. (Source: vercel.com/docs/environment-variables)
- `VERCEL_GIT_COMMIT_SHA` is available at both build time and runtime in deployments triggered from Git and holds the full commit SHA. It is present only while the project setting "Enable access to System Environment Variables" is on, and it is not set in local development.
- `VERCEL_ENV` is `production`, `preview` or `development`. In a custom environment it is `preview`; `VERCEL_TARGET_ENV` holds the custom environment's name.

## Function time limits

With fluid compute, which is enabled by default for projects created since 23 April 2025, on the Node.js, Bun and Python runtimes (source: vercel.com/docs/functions/limitations and vercel.com/docs/functions/configuring-functions/duration, page dated 2026-08-24):

| Plan | Default maximum duration | Highest configurable |
| --- | --- | --- |
| Hobby | 300 seconds | 300 seconds |
| Pro | 300 seconds | 800 seconds (1800 seconds in beta, per function, on supported Node.js, Bun and Python versions) |
| Enterprise | 300 seconds | 800 seconds (1800 seconds in beta, same conditions) |

- The limits for a project with fluid compute turned off are unverified (unverified: the current documentation pages give figures only for fluid compute).
- A function on the Edge runtime must begin sending a response within 25 seconds and can then stream for up to 300 seconds.
- The limit is configured per function with `maxDuration`: `export const maxDuration = <seconds>` in a Next.js App Router route file (Next.js 13.5 or later), `export const config = { maxDuration }` in Pages Router and plain Node.js API routes, or the `functions` object in `vercel.json` (glob pattern to `maxDuration`). A project-wide default is set in the dashboard under Settings, Functions, Function Max Duration, or with a `vercel.json` glob. Values above 800 seconds can only be set per function.
- An invocation that runs longer than its limit is terminated and the request receives a 504 with the error `FUNCTION_INVOCATION_TIMEOUT`. Long operations such as parsing or generating large files are the usual candidates.
- `vercel inspect <deployment-url> --json` lists the maximum duration each function of a deployment runs with, as `timeout`.

## Known problems

| Problem | Detail |
| --- | --- |
| Login page instead of the app | The URL is a protected generated URL (preview, branch or deployment-specific). The production custom domain or production `.vercel.app` domain is public under Standard Protection. |
| Build fails with no code change | Possibly a stale build cache. Rebuild with `--force`. |
| Feature works in preview, fails in production | A variable is applied to the Preview environment but not to Production, or the reverse. |
| A changed variable has no effect | Variable changes apply only to new deployments; the running deployment keeps its values until a redeploy. |
| New pushes do not reach production | A rollback turned off auto-assignment of production domains; it stays off until a deployment is promoted. |

## Carried over from other sources

- A variable that is set locally in `.env.local` but not applied to the deployed environment is simply absent there (`undefined` in Node.js). Vercel does not check for it at build or startup, so it usually shows up as a silent failure of the feature that needs it. (from `coding-standards.md`; unverified: the absence of any platform check is inferred from the documentation, which describes none)
- Vendor lock-in and cost at scale are the usual objections to the platform; it suits frontends, Next.js and serverless functions. (from `tech-selection-guide.md`; unverified: an opinion, not a checkable platform fact)

## Validation notes (2026-11-18)

- Sources:
  - `npx vercel --help` and `--help` for `deploy`, `list`, `inspect`, `logs`, `logs runtime`, `env`, `env ls`, `env add`, `env pull`, `env update`, `env remove`, `promote`, `rollback`, `redeploy`, `pull`, `curl`, `alias` (CLI 66.2.0); the deprecation handling of positional environment arguments was read from the installed CLI 66.2.0 package
  - https://vercel.com/docs/cli/deploy, https://vercel.com/docs/cli/list, https://vercel.com/docs/cli/inspect, https://vercel.com/docs/cli/logs, https://vercel.com/docs/cli/env, https://vercel.com/docs/cli/promote, https://vercel.com/docs/cli/rollback
  - https://vercel.com/docs/functions/configuring-functions/duration, https://vercel.com/docs/functions/limitations, https://vercel.com/docs/fluid-compute, https://vercel.com/docs/errors/FUNCTION_INVOCATION_TIMEOUT
  - https://vercel.com/docs/deployment-protection, https://vercel.com/docs/deployment-protection/usage-and-pricing, https://vercel.com/docs/deployment-protection/methods-to-protect-deployments/vercel-authentication, https://vercel.com/docs/deployments/generated-urls, https://vercel.com/docs/deployments/environments
  - https://vercel.com/docs/environment-variables, https://vercel.com/docs/environment-variables/system-environment-variables
  - https://vercel.com/docs/instant-rollback, https://vercel.com/docs/deployments/promoting-a-deployment, https://vercel.com/docs/deployment-retention, https://vercel.com/docs/git, https://vercel.com/docs/project-configuration/vercel-json, https://vercel.com/docs/deployments/troubleshoot-a-build, https://vercel.com/docs/domains/working-with-domains/add-a-domain
- Corrected:
  - `vercel logs <deployment-url>` -> `vercel logs --deployment <deployment-id-or-url>`; positional deployment deprecated, command is a time-window query (default last 30 minutes, 100 records), no longer a stream
  - `vercel env ls production` -> `vercel env ls --environment production`; positional environment deprecated (still accepted with a warning in 66.2.0)
  - `vercel env add VARIABLE_NAME production` -> `vercel env add VARIABLE_NAME --environment production`; added that Production and Preview variables default to the write-only Secret type
  - Rollback "by promoting an earlier deployment" -> reverting to a deployment that already served production is `vercel rollback` (Instant Rollback); `vercel promote` is for staged production deployments, rebuilds preview-built deployments, and undoes a rollback
  - Added the rollback conditions the old claim omitted: Hobby can only roll back to the immediately previous production deployment; a rollback turns off auto-assignment of production domains; a rolled-back deployment keeps its old environment variables
  - "Previous deployments are kept" -> kept for the retention period (default 30 days on Hobby and Pro), with the stated exceptions
  - "Under a minute" for promotion -> documented as "usually finishes within seconds", no rebuild
  - "Each pull request gets its own preview deployment" -> every push to a non-production branch creates a preview deployment
  - Automatic deployment "about 2 to 3 minutes" -> removed; no platform figure exists
  - Deployment URLs "may be protected" -> protected by default on new projects on all plans (Standard Protection with Vercel Authentication); production domains public; All Deployments scope protects production too
  - "Which domain is primary is a project setting" -> one domain can be set to redirect to another
  - "A variable set in one scope is not available in the others" -> a variable can be applied to several environments; custom environments and branch-specific Preview variables exist; changes reach only new deployments
  - `VERCEL_GIT_COMMIT_SHA` "available at runtime" -> build and runtime, only with system environment variables enabled, not in local development
  - Function timeout Hobby 10 seconds, Pro 60 seconds -> default 300 seconds on all plans with fluid compute; maximum 300 seconds on Hobby, 800 seconds on Pro and Enterprise (1800 seconds in beta); configured with `maxDuration`
  - "Terminated" on timeout -> terminated with a 504 `FUNCTION_INVOCATION_TIMEOUT`
  - Known problem "Use the alias or custom domain" -> names the production custom domain or production `.vercel.app` domain
- Still unverified:
  - Whether `vercel promote` rejects a deployment that was previously current: two documentation pages disagree and no live project was used
  - Whether the generated `<project>-<scope>.vercel.app` production URL is public under Standard Protection: not stated in the documentation
  - Function duration limits with fluid compute turned off: not given on the current documentation pages
  - What the CLI's "Team-owned projects only" note on `vercel logs` excludes: stated in the help text, not explained in the documentation
  - Silent failure of a missing variable: no platform check is documented, but the behaviour was not observed
  - Vendor lock-in and cost remark: an opinion
  - None of the commands was run against a linked project; only help output and documentation were checked
