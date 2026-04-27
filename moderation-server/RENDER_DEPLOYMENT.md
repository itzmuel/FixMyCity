# Render Deployment Steps for FixMyCity Photo Moderation Server

This guide walks through deploying the Node.js photo moderation API to Render.

---

## Prerequisites

1. **Render Account**: Sign up at https://render.com
2. **GitHub Repository**: Push the `moderation-server/` folder to your GitHub repo (recommended) OR upload directly to Render
3. **OpenAI API Key**: From https://platform.openai.com/api-keys (requires paid account with credits)
4. **Supabase Project**: Already linked in your local workspace (npjldteeehkkoegbzlgb)

---

## Step 1: Get Your OpenAI API Key

1. Go to https://platform.openai.com/account/api-keys
2. Click **"Create new secret key"**
3. Copy the key (starts with `sk-`)
4. Save it securely—you'll need it in Step 5

**Note**: Ensure your OpenAI account has:
- A payment method set up (Vision API requires paid tier)
- Enough credits (test requests use ~$0.01 each)

---

## Step 2: Prepare Your Code Repository

**Option A: Using GitHub (Recommended)**

1. In your workspace, create a new branch:
   ```powershell
   git checkout -b add/moderation-server
   ```

2. Add the moderation server to version control:
   ```powershell
   git add moderation-server/
   git commit -m "Add Render moderation server for photo validation"
   ```

3. Push to GitHub:
   ```powershell
   git push origin add/moderation-server
   ```

4. Go to your GitHub repo and create a Pull Request (or merge to main)

**Option B: Direct Upload**

- Skip GitHub and upload via Render's web interface (see Step 4)

---

## Step 3: Create a New Web Service on Render

1. Go to https://dashboard.render.com
2. Click **"New +"** → **"Web Service"**
3. Choose your deployment source:

   **If using GitHub:**
   - Select **"GitHub"**
   - Authorize Render to access your GitHub repo
   - Select the repository containing `fixmycity_app`
   - Select the branch (main or your feature branch)
   - Render will auto-detect the `package.json`

   **If uploading directly:**
   - Select **"Public Git Repository"**
   - Enter: `https://github.com/YOUR_USERNAME/YOUR_REPO.git`

4. **Service Settings**:
   - **Name**: `fixmycity-moderation` (or similar)
   - **Environment**: `Node`
   - **Region**: Select closest to your users (e.g., `US Ohio` for North America)
   - **Branch**: `main` (or your feature branch)
   - **Build Command**: Leave empty (Render auto-runs `npm install`)
   - **Start Command**: `npm start`

5. Click **"Create Web Service"**

---

## Step 4: Configure Environment Variables

1. In Render dashboard, go to your new service: **fixmycity-moderation**
2. Click **"Environment"** on the left sidebar
3. Add the following environment variables:

   | Key | Value |
   |-----|-------|
   | `OPENAI_API_KEY` | Paste your key from Step 1 (starts with `sk-`) |
   | `NODE_ENV` | `production` |
   | `PORT` | `3000` (Render assigns this automatically) |

4. Click **"Save"** after each addition

---

## Step 5: Deploy

1. Render will automatically start building when you save environment variables
2. Monitor the **Build Logs** tab:
   - ✅ **Success**: Logs show `npm start` running, then service becomes **Live**
   - ❌ **Failed**: Check error message, usually missing env vars or npm package issues

3. Once **Live**, click the URL at the top to test:

   ```
   https://fixmycity-moderation.onrender.com/health
   ```

   You should see:
   ```json
   {"status":"ok","timestamp":"2026-04-27T..."}
   ```

---

## Step 6: Test the Moderation Endpoint

Use Postman or curl to test:

```bash
curl -X POST https://fixmycity-moderation.onrender.com/moderate-photo \
  -H "Content-Type: application/json" \
  -d '{
    "imageBase64": "YOUR_BASE64_IMAGE_HERE",
    "category": "pothole",
    "description": "Large pothole on Main Street",
    "mimeType": "image/jpeg"
  }'
```

**Response** (if successful):
```json
{
  "allow": true,
  "score": 0.85,
  "reason": "Photo approved by AI moderation",
  "reasonCode": "ALLOWED_BY_VISION",
  "details": {
    "hasObjectsOfInterest": true,
    "containsFace": false,
    "isRelevantToCivic": true,
    "confidenceLevel": "high"
  }
}
```

---

## Step 7: Get Your Deployment URL

1. In Render dashboard, find your service URL at the top:
   ```
   https://fixmycity-moderation.onrender.com
   ```

2. Copy this URL—you'll need it in the next step

---

## Step 8: Configure Supabase Secrets

Run these commands in your terminal (in the workspace root):

```powershell
# Set the moderation provider URL
npx --yes supabase@2.95.5 secrets set MODERATION_PROVIDER_URL=https://fixmycity-moderation.onrender.com/moderate-photo

# Optional: If you want to add an API key for authentication (not required for now)
# npx --yes supabase@2.95.5 secrets set MODERATION_PROVIDER_API_KEY=your-optional-key
```

**Verify secrets are set:**
```powershell
npx --yes supabase@2.95.5 secrets list
```

You should see:
```
MODERATION_PROVIDER_URL | https://fixmycity-moderation.onrender.com/moderate-photo
```

---

## Step 9: Redeploy Supabase Edge Function

Since you updated secrets, redeploy the function:

```powershell
npx --yes supabase@2.95.5 functions deploy moderate-report-photo
```

This will pick up the new `MODERATION_PROVIDER_URL` secret.

---

## Step 10: End-to-End Testing

1. **Run your Flutter app** in debug mode
2. **Navigate to Report → Photo upload screen**
3. **Pick a photo** (test with both civic and non-civic images)
4. **Check logs**:
   - Render: https://dashboard.render.com/services → fixmycity-moderation → Logs
   - Supabase: Dashboard → Edge Functions → moderate-report-photo → Logs

---

## Troubleshooting

### Service Won't Build
- Check **Build Logs** for missing dependencies
- Verify `moderation-server/package.json` is at root level, not in a subdirectory
- Ensure `node` version is 18+

### 502 Error / Service Won't Start
- Check **Runtime Logs** for errors
- Verify `OPENAI_API_KEY` is set correctly (no spaces, starts with `sk-`)
- Test endpoint locally: `npm start` then `curl http://localhost:3000/health`

### OpenAI API Errors
- Verify API key is valid (test at https://platform.openai.com/account/billing)
- Ensure account has payment method and credits available
- Check rate limits haven't been exceeded

### Photos Still Blocked After Render Deployment
- Check Render logs for Vision API responses
- Verify Edge Function can reach Render URL (no firewall blocks)
- Test Render endpoint directly with sample base64 image
- Check Supabase logs for network errors

---

## Performance Notes

- **First request**: ~2-3s (cold start)
- **Warm requests**: ~1-1.5s per photo (Vision API latency)
- **Render free tier**: Up to 750 compute hours/month (sufficient for testing)
- **Cost**: ~$0.005-0.01 per photo at Vision API rates

---

## Optional: Upgrade to Production Plan

For production, consider Render's **Paid Plan**:
- Always-on availability
- Better performance
- More concurrent requests
- Custom domains

Estimated cost: **$15-30/month** depending on traffic.

---

## Next Steps After Deployment

1. ✅ Photo rejections now use Render + OpenAI Vision
2. ⏳ Monitor analytics: Check `report_moderation_events` table for patterns
3. ⏳ Tune thresholds based on real data
4. ⏳ Test with production photos before public launch
