# Foundation: Vercel

- **Last validated:** not re-validated since February 2026 (carried over from `skills/devops/references/devops-patterns.md`)
- **Review cadence:** every 3 months, and whenever the tool has a major release
- **Covers:** Vercel CLI commands, project configuration, deployment and preview behaviour, environment variable scopes, URL access protection, function time limits, rollback by promotion
- **Does not cover:** Next.js framework behaviour, Supabase (see `foundation-supabase-cli.md` and `foundation-supabase.md`), CI workflows (see `foundation-github-actions.md`), any one project's URLs or variables (project `knowledge/foundations/`)

## CLI

The CLI is run through `npx vercel`; it is not assumed to be installed globally.

| Command | What it does |
| --- | --- |
| `npx vercel` | Deploys the current directory to a preview deployment |
| `npx vercel --prod` | Deploys to production |
| `npx vercel --force` | Deploys without using the build cache |
| `npx vercel ls` | Lists recent deployments and their status |
| `npx vercel inspect <deployment-url>` | Shows the status and details of one deployment |
| `npx vercel logs <deployment-url>` | Shows function logs for a deployment |
| `npx vercel env ls production` | Lists the names of environment variables set for the Production scope |
| `npx vercel env add VARIABLE_NAME production` | Adds an environment variable to the Production scope (prompts for the value) |
| `npx vercel promote <deployment-url>` | Makes an existing deployment the production deployment |

## Project configuration

A typical Next.js project needs little or no `vercel.json`. When present it looks like this:

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs"
}
```

## Deployments

- When a project is connected to a GitHub repository, every push to the main branch triggers an automatic production deployment. Every merge to main is therefore a production deployment.
- Each pull request gets its own preview deployment with an auto-generated URL.
- Previous deployments are kept. Promoting an earlier deployment to production is near-instant (under a minute) and does not rebuild.
- A stale build cache sometimes causes build failures. `npx vercel --force` rebuilds without the cache.
- An automatic deployment after a push typically completes in about 2 to 3 minutes for a small site (unverified; depends on the project).

## URL access

- Deployment-specific `.vercel.app` URLs may be protected by Vercel authentication (SSO): an unauthenticated request gets a login page, not the application.
- The project's alias domain (the stable `<project>.vercel.app` name) or a custom domain is the publicly reachable address.
- A project can have both a custom domain and an auto-generated alias; which one is primary is a project setting.

## Environment variables

- Variables are scoped to three environments: Production, Preview and Development. A variable set in one scope is not available in the others.
- Secrets for deployed environments are stored in Vercel (dashboard or `vercel env add`), not in the repository. Local development uses `.env.local`.
- `VERCEL_GIT_COMMIT_SHA` is available at runtime in deployments made from Git and holds the full commit SHA of the deployed build.

## Function time limits

| Plan | Function timeout |
| --- | --- |
| Hobby | 10 seconds (unverified; Vercel has changed default and maximum durations since this was recorded) |
| Pro | 60 seconds (unverified; same reason) |

A request that runs longer than the limit is terminated. Long operations such as parsing or generating large files are the usual candidates.

## Known problems

| Problem | Detail |
| --- | --- |
| Login page instead of the app | The URL is a protected deployment URL. Use the alias or custom domain. |
| Build fails with no code change | Possibly a stale build cache. Rebuild with `--force`. |
| Feature works in preview, fails in production | A variable is set for the Preview scope but not for Production, or the reverse. |

## Carried over from other sources

- A variable that is set locally in `.env.local` but missing in the deployed environment usually shows up as a silent failure of the feature that needs it, not as a build or startup error. (from `coding-standards.md`)
- Vendor lock-in and cost at scale are the usual objections to the platform; it suits frontends, Next.js and serverless functions. (from `tech-selection-guide.md`)
