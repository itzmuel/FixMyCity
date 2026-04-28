# Render Deployment Checklist

Use this checklist to track your deployment progress.

## Pre-Deployment

- [ ] You have an **OpenAI API key** from https://platform.openai.com/api-keys
  - Account has payment method set up
  - Account has available credits
- [ ] You have a **GitHub account** with your fixmycity_app repo
- [ ] You have a **Render account** from https://render.com
- [ ] Your `moderation-server/` folder is pushed to GitHub (in main branch or feature branch)

## Deployment Steps

### Option A: Manual Dashboard Deployment (Recommended First Time)

- [ ] Step 1: Get OpenAI API key
- [ ] Step 2: Push moderation-server/ to GitHub
- [ ] Step 3: Create new Web Service on Render dashboard
  - [ ] Connected to GitHub repo
  - [ ] Selected `moderation-server` folder
  - [ ] Set Build Command to empty
  - [ ] Set Start Command to `npm start`
- [ ] Step 4: Add environment variables in Render
  - [ ] `OPENAI_API_KEY` = your key from Step 1
  - [ ] `NODE_ENV` = `production`
- [ ] Step 5: Wait for deployment to complete
  - Check Build Logs and Runtime Logs
  - Status should be "Live" (green)
- [ ] Step 6: Test health endpoint
  ```
  https://fixmycity-moderation.onrender.com/health
  ```
  Should see: `{"status":"ok","timestamp":"..."}`
- [ ] Step 7: Copy your Render service URL

### Option B: Script Deployment (Faster After Setup)

- [ ] Bash script (macOS/Linux):
  ```bash
  bash moderation-server/render-deploy.sh
  ```
- [ ] PowerShell script (Windows):
  ```powershell
  .\moderation-server\render-deploy.ps1
  ```

## Post-Deployment

- [ ] Render URL is working (test `/health` endpoint)
- [ ] Run Supabase secrets setup:
  ```powershell
  npx --yes supabase@2.95.5 secrets set MODERATION_PROVIDER_URL=https://fixmycity-moderation.onrender.com/moderate-photo
  ```
- [ ] Verify secrets are set:
  ```powershell
  npx --yes supabase@2.95.5 secrets list
  ```
  Should show: `MODERATION_PROVIDER_URL | https://fixmycity-moderation.onrender.com/moderate-photo`
- [ ] Redeploy Supabase function:
  ```powershell
  npx --yes supabase@2.95.5 functions deploy moderate-report-photo
  ```

## Testing in Your App

- [ ] Run Flutter app in debug mode
- [ ] Navigate to Report → Photo upload
- [ ] Try uploading:
  - [ ] A civic photo (pothole, graffiti, etc.) → Should ACCEPT
  - [ ] A selfie/face → Should REJECT
  - [ ] A blurry photo → Should REJECT
  - [ ] Unrelated photo → Should REJECT
- [ ] Check that moderation works (takes ~1-1.5s per photo)

## Monitoring

- [ ] Check Render logs: https://dashboard.render.com/services → fixmycity-moderation → Logs
- [ ] Check Supabase function logs: https://supabase.com/dashboard/project/npjldteeehkkoegbzlgb/functions/moderate-report-photo
- [ ] Query analytics: Check `report_moderation_events` table for decisions

## Troubleshooting

- [ ] If deployment fails, check Build Logs for errors
- [ ] If service won't start, check Runtime Logs
- [ ] If photos not being moderated, check:
  - Render service is "Live"
  - Supabase secrets are set correctly
  - Edge Function was redeployed after setting secrets
- [ ] If getting OpenAI errors:
  - Verify API key is correct
  - Check account has credits
  - Try health endpoint: `https://fixmycity-moderation.onrender.com/health`

## Estimated Timeline

| Task | Time |
|------|------|
| Get OpenAI API key | 5 min |
| Push to GitHub | 2 min |
| Create Render service | 3 min |
| Configure env vars | 2 min |
| Wait for build | 5-10 min |
| Test deployment | 5 min |
| Set Supabase secrets | 2 min |
| Redeploy function | 3 min |
| **Total** | **~30 minutes** |

## Cost Summary

| Service | Cost |
|---------|------|
| Render (Free tier) | $0/month |
| OpenAI Vision (per photo) | ~$0.005-0.01 |
| Supabase (included in existing plan) | Already paid |

---

**Questions?** See [RENDER_DEPLOYMENT.md](./RENDER_DEPLOYMENT.md) for detailed troubleshooting.
