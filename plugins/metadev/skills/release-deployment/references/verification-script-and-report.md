# Verification script and delivery report templates

Used by the `release-deployment` skill. Replace every `<placeholder>`. The commands are described in `foundation-vercel.md` and `foundation-supabase-cli.md` (plugin, `foundations` skill); check there for claims marked unverified before relying on a command.

## Verification script

Save as `scripts/deploy-verify-<feature>.sh`.

```bash
#!/bin/bash
# Deployment verification for <project> <feature>
# Date: YYYY-MM-DD
# Verified by: <role>

set -e  # Exit on error

echo "=== Database Migrations ==="
npx supabase migration list --remote

echo ""
echo "=== Environment Variables ==="
npx vercel env ls --environment production

echo ""
echo "=== External Resources ==="
# Check storage buckets
npx supabase storage ls ss:/// --remote --experimental

# Check a specific bucket exists
if npx supabase storage ls ss:/// --remote --experimental | grep -q "<bucket-name>"; then
  echo "OK: storage bucket '<bucket-name>' exists"
else
  echo "MISSING: storage bucket '<bucket-name>'"
  exit 1
fi

echo ""
echo "=== Health Check ==="
curl -sf https://<public-production-url>/api/health || {
  echo "FAILED: health check"
  exit 1
}

echo ""
echo "=== Deployment Verification Complete ==="
```

## Logged-in smoke test record

```markdown
### Authenticated Smoke Test

1. Logged in as <test account>
2. Navigated to <page>
3. Performed core action: <what was created or changed>
4. Verified the result appears in <where>
5. Verified the result persists after page refresh
6. Result: PASS
```

## Delivery report section

```markdown
## Deployment Verification

**Environment:** Production (<public-production-url>)
**Date:** YYYY-MM-DD
**Verified by:** <role>

### Database
- [ ] All migrations applied (script: `npx supabase migration list --remote`)
- [ ] Schema matches code expectations (verified: <tables created>)

### Environment Variables
- [ ] All required variables set (script: `npx vercel env ls --environment production`)
- [ ] Verified: <list key variables, names only, never values>

### External Resources
- [ ] Storage buckets created: <bucket names>
- [ ] Third-party services configured: <service names>

### Build and Deployment
- [ ] Hosting deployment successful
- [ ] Build logs clean (no warnings or errors)

### Smoke Test
- [ ] Application loads at production URL
- [ ] Health endpoint returns 200: `/api/health`
- [ ] Core authenticated flow works: <describe test>

### Risks Assessed
- [ ] <Risk 1>: <quantified verdict>
- [ ] <Risk 2>: <quantified verdict>

### Rollback
- [ ] Rollback procedure documented (if applicable): <link>

### Script
Deployment verification script saved at: `scripts/deploy-verify-<feature>.sh`
```

## Short checklist

For a small release where the full report is more than the change deserves:

```markdown
- [ ] All database migrations applied to production
- [ ] All environment variables set in production
- [ ] All external resources created (storage, DNS, API keys)
- [ ] Production build succeeds (deployment successful)
- [ ] Smoke test: application loads
- [ ] Smoke test: core user flow works end-to-end
- [ ] Deployment state documented in delivery report
- [ ] Rollback procedure documented (if applicable)
```
