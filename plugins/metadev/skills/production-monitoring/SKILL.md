---
name: production-monitoring
description: Giving a deployed application a health endpoint and a scheduled check that goes red when production is down, and knowing where to look for evidence when it does. Use when a project reaches production without a health check, when setting up periodic production checks, or when deciding what to watch after a release.
user-invocable: false
---

# Production Monitoring

A good outcome is that a broken production is noticed by a check rather than by a user: one endpoint that answers "is the application up and can it reach its database", and one scheduled job that asks that question and fails loudly.

## Required foundations

| Foundation | What you need from it |
| --- | --- |
| `foundation-github-actions.md` (plugin, `foundations` skill) | Scheduled workflows and cron syntax |
| `foundation-vercel.md` (plugin, `foundations` skill) | The commit SHA variable available at runtime, reading function logs, which URLs are publicly reachable |
| `foundation-supabase.md` (plugin, `foundations` skill) | How the client reads a table, and which key the health query should use |
| Project `knowledge/foundations/foundation-infrastructure.md` | The public production URL |

If the public production URL is unknown, stop and return `needs-decision`. A check pointed at a login-gated deployment URL will fail, or pass, for the wrong reason.

## Required context

- Required: the public production URL.
- Required: how the application reaches its database (which client, which key), and a small table the health query can read.
- Optional: after a release, the risks that were quantified during the release, to know what is worth watching.

## Approach

1. **Add a health endpoint that tests a real dependency.** Returning 200 unconditionally only proves the function runs. Query the database, and return 503 when the query fails so that monitors can rely on the status code alone.

   ```typescript
   // /api/health.ts
   export async function GET() {
     try {
       // Check database connectivity
       const { error } = await supabase.from('_health').select('count').limit(1);
       if (error) throw error;

       return Response.json({
         status: 'healthy',
         timestamp: new Date().toISOString(),
         version: process.env.VERCEL_GIT_COMMIT_SHA?.slice(0, 7) || 'unknown',
       });
     } catch (error) {
       return Response.json(
         { status: 'unhealthy', error: error.message },
         { status: 503 }
       );
     }
   }
   ```

   The `_health` table in the example must exist and be readable by the key the endpoint uses; create it in a migration or point the query at an existing small table.
2. **Include the deployed version in the response.** The short commit SHA tells you at a glance which build is serving, which settles "did the deployment actually go out" during a release or a rollback.
3. **Confirm the endpoint on the public address**: 200 with the expected version when healthy.
4. **Add a scheduled check** that requests the endpoint and fails the job on anything other than 200:

   ```yaml
   name: Production Health Check
   on:
     schedule:
       - cron: '0 9 * * 1-5'  # Weekdays at 9am

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
5. **Use the same endpoint in release verification.** The verification script in the `release-deployment` skill calls it, so the release check and the periodic check agree on what "healthy" means.
6. **After a release, watch the things you measured.** Each risk assessed during the release has a constraint and a threshold (for example a function time limit and the input size at which it would be reached). Those thresholds are what to re-check; an unquantified "keep an eye on it" is not a monitoring plan.
7. **When a check fails, gather evidence before changing anything**: the health response body, the function logs for the deployment (`npx vercel logs <deployment-url>`), the migration status and the deployment listing. Then follow the evidence-first debugging practice in the `team-standards` skill. If a recent release is the cause and a rollback plan exists, see the `deployment-rollback` skill.

## Done means

- `curl -s -o /dev/null -w "%{http_code}" https://<public-production-url>/api/health` prints 200.
- The response body includes a status, a timestamp and the deployed commit SHA, and the SHA matches the latest production deployment.
- With the database dependency made to fail in a local or preview environment, the endpoint returns 503.
- The scheduled workflow exists, has run at least once (trigger it manually if needed) and passed.

## Anti-patterns

- **A health endpoint that checks nothing.** If it cannot go red when the database is unreachable, it adds no information.
- **Pointing the check at a deployment-specific URL.** Those may require a platform login. Use the public alias or custom domain.
- **"To monitor" with no measurement.** State the constraint, the measured value and the threshold at which to look again.
- **Adding many scheduled checks at once.** The same rule as for any pipeline applies: a check that cries wolf gets ignored. Start with one that catches a real outage.
