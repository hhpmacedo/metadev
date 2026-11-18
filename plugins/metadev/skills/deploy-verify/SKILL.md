---
name: deploy-verify
description: Run the deployment verification checklist against a project or URL - reachability, build status, migrations, environment variables, core user flow, console and network errors, load time. Use when asked to verify a deployment, check production health, or before a mandate is called delivered.
argument-hint: "[project name or deployment URL]"
---

# Deployment Verification

Run a comprehensive deployment verification for the specified project.

## Instructions

1. The target is: $ARGUMENTS (if empty, ask for the project name or deployment URL).
2. Identify the project from its `CLAUDE.md` (Live URL under Project Status) or use the URL directly.
3. This checklist only reads. Do not apply migrations or change environment variables here; that belongs to the `release-deployment` technique, with approval.

## Verification Checklist

Execute each check and report pass/fail:

### Infrastructure

- [ ] **Deployment accessible:** Fetch the production URL, verify HTTP 200
- [ ] **No SSO gate:** Verify the public alias URL is accessible (not Vercel SSO-protected)
- [ ] **Build status:** Check `npx vercel ls` for latest deployment status

### Database (if Supabase project)

- [ ] **Migrations current:** Compare local and remote with `npx supabase migration list` (see `foundation-supabase-cli.md`)
- [ ] **Tables exist:** Verify expected tables are present

### Environment

- [ ] **Required env vars:** Check `npx vercel env ls` for expected environment variables
- [ ] **No exposed secrets:** Verify no API keys in client-side JavaScript (view page source)

### Functional

- [ ] **Core flow works:** Use browser tools, if the session has them, to execute the primary user flow end-to-end
- [ ] **No console errors:** Check browser console for errors on the main page
- [ ] **API endpoints respond:** Test key API routes return expected status codes

### Performance

- [ ] **Page loads under 3s:** Measure initial page load time
- [ ] **No broken resources:** Check for 404s on CSS, JS, images

## Output

Report each check as PASS, FAIL or NOT CHECKED (with the reason), with the command or request used. Provide overall verdict: Deployment Healthy or Issues Found (with specifics).
