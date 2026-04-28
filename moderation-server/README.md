# FixMyCity Photo Moderation Server

AI-powered photo moderation API for validating civic issue reports before submission to FixMyCity.

## Overview

This Node.js/Express server uses **OpenAI Vision API** to analyze photos for:
- ✅ Civic relevance (is this actually a pothole/graffiti/etc.?)
- ✅ Face detection (blocking selfies/portraits)
- ✅ Image quality (rejecting blurry/dark photos)
- ✅ Spam detection (rejecting unrelated content)

## Architecture

```
FixMyCity App (Flutter)
    ↓
Report Photo (base64)
    ↓
Supabase Edge Function (TypeScript/Deno)
    ↓
This Server (Node.js/Express + OpenAI Vision)
    ↓
Response: {allow, score, reason}
    ↓
App: Accept or Reject Photo
```

## Quick Start (Local Development)

### Prerequisites
- Node.js 18+
- OpenAI API key (from https://platform.openai.com/api-keys)

### Setup

```bash
cd moderation-server
npm install
```

### Environment Variables

Create `.env`:
```
OPENAI_API_KEY=sk-your-key-here
PORT=3000
NODE_ENV=development
```

### Run Locally

```bash
npm start          # Production mode
npm run dev        # Development with auto-reload
```

Test health endpoint:
```bash
curl http://localhost:3000/health
```

## API Endpoints

### POST /moderate-photo

Analyzes a photo for civic relevance and safety.

**Request:**
```json
{
  "imageBase64": "base64-encoded-image-data",
  "category": "pothole",
  "description": "Large pothole on Main Street",
  "mimeType": "image/jpeg"
}
```

**Response:**
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

**Reason Codes:**
- `ALLOWED_BY_VISION` - Photo passed all checks
- `CONTAINS_FACE` - Human face detected
- `NOT_CIVIC_RELEVANT` - Doesn't show reported issue
- `POOR_IMAGE_QUALITY` - Too blurry/dark/unclear
- `LOW_RELEVANCE_SCORE` - Score below threshold
- `PARSE_ERROR` - Error parsing AI response
- `SERVER_ERROR` - Internal server error

### GET /health

Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-04-27T..."
}
```

### POST /moderate-photo-lightweight

Fallback endpoint using only basic heuristics (no OpenAI).

## Deployment

### Render (Production)

Follow [RENDER_DEPLOYMENT.md](./RENDER_DEPLOYMENT.md) for step-by-step instructions.

**TL;DR:**
1. Sign up at render.com
2. Create new Web Service
3. Set `OPENAI_API_KEY` environment variable
4. Deploy
5. Get URL: `https://fixmycity-moderation.onrender.com`
6. Configure in Supabase: `supabase secrets set MODERATION_PROVIDER_URL=https://fixmycity-moderation.onrender.com/moderate-photo`

### Docker (Optional)

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## Testing

### Local Testing with cURL

```bash
# Prepare a test image
base64 -i test-photo.jpg > test-photo.b64

# Make request
curl -X POST http://localhost:3000/moderate-photo \
  -H "Content-Type: application/json" \
  -d @request.json
```

### Integration with Supabase Edge Function

The Supabase Edge Function (`supabase/functions/moderate-report-photo/`) calls this endpoint automatically when `MODERATION_PROVIDER_URL` is set.

```typescript
const response = await fetch(
  Deno.env.get('MODERATION_PROVIDER_URL'),
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      imageBase64,
      category,
      description,
      mimeType,
    }),
  }
);
```

## Monitoring

### Render Logs
- Dashboard: https://dashboard.render.com
- Monitor for errors, latency, and quota usage

### Supabase Analytics
- Table: `report_moderation_events`
- View: Decision history, scores, rejection reasons
- Query:
  ```sql
  SELECT 
    allowed, 
    reason_code, 
    reason_message, 
    COUNT(*) 
  FROM report_moderation_events 
  GROUP BY allowed, reason_code 
  ORDER BY COUNT(*) DESC;
  ```

## Cost Estimates

| Operation | Cost |
|-----------|------|
| OpenAI Vision (per image) | $0.005-0.01 |
| Render Free Tier (750 hrs/month) | $0 |
| Render Paid Tier (always-on) | $15-30/month |

## Configuration

### Photo Approval Thresholds

In `server.js`, adjust these to tune moderation strictness:

```javascript
// Line ~140: Relevance threshold
parsed.relevanceScore >= 0.6  // Increase for stricter, decrease for lenient

// Line ~160: Vision checks
const allow =
  parsed.isCivicRelevant &&          // Must be about civic issue
  !parsed.containsFace &&             // No human faces allowed
  parsed.isQualityAcceptable &&       // Must be clear
  parsed.relevanceScore >= 0.6;       // Score threshold
```

## Troubleshooting

### OpenAI Errors
- **401 Unauthorized**: Check API key (no spaces, valid key)
- **429 Rate Limited**: OpenAI quota exceeded, upgrade account or retry later
- **400 Bad Request**: Invalid image format or prompt

### Network Issues
- **Connection Timeout**: Render service down or network blocked
- **CORS Errors**: Ensure CORS middleware is enabled (it is by default)

### Slow Responses
- First request after deploy ~2-3s (cold start)
- Subsequent requests ~1-1.5s (Vision API latency)
- Normal for this use case; consider caching for known spam patterns

## Future Enhancements

- [ ] Response caching for identical images (duplicate detection)
- [ ] Batch processing for multiple photos
- [ ] Custom models per category (pothole-specific model)
- [ ] Fallback providers (Google Cloud Vision, AWS Rekognition)
- [ ] Webhook notifications for high-confidence rejections
- [ ] Dashboard for reviewing borderline cases

## License

Part of FixMyCity App - same license as parent project

## Support

For issues:
1. Check Render dashboard logs
2. Check Supabase function logs
3. Test locally: `npm start` then curl health endpoint
4. Review RENDER_DEPLOYMENT.md troubleshooting section
