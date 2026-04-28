import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import OpenAI from 'openai';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Middleware
app.use(cors());
app.use(express.json({ limit: '20mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

/**
 * Main photo moderation endpoint
 * 
 * Expected request body:
 * {
 *   "imageBase64": "base64-encoded-image",
 *   "category": "pothole|streetlight|graffiti|sidewalk|illegal_dumping|other",
 *   "description": "user-provided description",
 *   "mimeType": "image/jpeg|image/png|image/webp"
 * }
 * 
 * Response:
 * {
 *   "allow": boolean,
 *   "score": 0-1,
 *   "reason": "Human-readable reason",
 *   "reasonCode": "REASON_CODE_ENUM",
 *   "details": {
 *     "hasObjectsOfInterest": boolean,
 *     "containsFace": boolean,
 *     "isRelevantToCivic": boolean,
 *     "confidenceLevel": "high|medium|low"
 *   }
 * }
 */
app.post('/moderate-photo', async (req, res) => {
  try {
    const { imageBase64, category, description, mimeType } = req.body;

    // Validate request
    if (!imageBase64) {
      return res.status(400).json({
        allow: false,
        score: 0,
        reason: 'Missing imageBase64',
        reasonCode: 'INVALID_REQUEST',
      });
    }

    if (!category) {
      return res.status(400).json({
        allow: false,
        score: 0,
        reason: 'Missing category',
        reasonCode: 'INVALID_REQUEST',
      });
    }

    // Call OpenAI Vision API with vision model
    const visionResponse = await openai.chat.completions.create({
      model: 'gpt-4-vision-preview',
      max_tokens: 300,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: buildModerationPrompt(category, description),
            },
            {
              type: 'image_url',
              image_url: {
                url: `data:${mimeType || 'image/jpeg'};base64,${imageBase64}`,
              },
            },
          ],
        },
      ],
    });

    // Parse OpenAI response
    const response = parseModerationResponse(
      visionResponse.choices[0].message.content,
      category
    );

    return res.json(response);
  } catch (error) {
    console.error('Error in moderation endpoint:', error);

    // Return server error but indicate local fallback should be used
    return res.status(500).json({
      allow: false,
      score: 0.5,
      reason: 'Server moderation error - please use local fallback',
      reasonCode: 'SERVER_ERROR',
      details: {
        error: error.message,
      },
    });
  }
});

/**
 * Build the prompt for OpenAI Vision to analyze civic photo relevance
 */
function buildModerationPrompt(category, description) {
  return `Analyze this photo for a civic issue reporting app. Respond with ONLY valid JSON (no markdown, no code blocks).

Category: ${category}
User Description: "${description || 'No description provided'}"

Evaluate and respond with EXACTLY this JSON structure (valid JSON only, no extras):
{
  "isCivicRelevant": boolean (true if photo clearly shows the reported civic issue),
  "containsFace": boolean (true if a human face is prominently visible),
  "hasObjectsOfInterest": boolean (true if photo shows the relevant infrastructure/issue),
  "isQualityAcceptable": boolean (true if photo is clear and properly framed),
  "relevanceScore": number (0-1, higher = more relevant to civic issue),
  "confidence": "high" | "medium" | "low",
  "reason": "Brief reason for decision"
}

For category "${category}": Look for signs of the specific civic issue type. Reject if the photo appears to be a selfie, portrait, screenshot, or unrelated content. Reject if face is visible.`;
}

/**
 * Parse OpenAI Vision response into structured moderation decision
 */
function parseModerationResponse(content, category) {
  try {
    // Extract JSON from response (handle cases where it's wrapped in markdown)
    let jsonStr = content;
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      jsonStr = jsonMatch[0];
    }

    const parsed = JSON.parse(jsonStr);

    // Determine allow/deny based on Vision analysis
    const allow =
      parsed.isCivicRelevant &&
      !parsed.containsFace &&
      parsed.isQualityAcceptable &&
      parsed.relevanceScore >= 0.6;

    let reasonCode = 'ALLOWED_BY_VISION';
    let reason = 'Photo approved by AI moderation';

    if (parsed.containsFace) {
      reasonCode = 'CONTAINS_FACE';
      reason = 'Photo contains visible human face';
    } else if (!parsed.isCivicRelevant) {
      reasonCode = 'NOT_CIVIC_RELEVANT';
      reason = 'Photo does not appear to show the reported civic issue';
    } else if (!parsed.isQualityAcceptable) {
      reasonCode = 'POOR_IMAGE_QUALITY';
      reason = 'Photo quality is too low (blurry, dark, or unclear)';
    } else if (parsed.relevanceScore < 0.6) {
      reasonCode = 'LOW_RELEVANCE_SCORE';
      reason = `Relevance score too low: ${parsed.relevanceScore.toFixed(2)}`;
    }

    return {
      allow,
      score: parsed.relevanceScore || 0.5,
      reason,
      reasonCode,
      details: {
        hasObjectsOfInterest: parsed.hasObjectsOfInterest,
        containsFace: parsed.containsFace,
        isRelevantToCivic: parsed.isCivicRelevant,
        confidenceLevel: parsed.confidence,
      },
    };
  } catch (error) {
    console.error('Error parsing Vision response:', error, 'Content:', content);
    return {
      allow: false,
      score: 0.5,
      reason: 'Error parsing AI response - using local fallback',
      reasonCode: 'PARSE_ERROR',
      details: {
        error: error.message,
      },
    };
  }
}

/**
 * Alternative lightweight endpoint (fallback for testing)
 * Returns a pass/fail based on basic heuristics if OpenAI fails
 */
app.post('/moderate-photo-lightweight', (req, res) => {
  try {
    const { category, description } = req.body;

    // Very basic heuristics - this would be your local fallback
    const isLikelySpam =
      !description ||
      description.length < 10 ||
      description.toLowerCase().includes('test') ||
      description.toLowerCase().includes('selfie');

    return res.json({
      allow: !isLikelySpam,
      score: isLikelySpam ? 0.2 : 0.7,
      reason: isLikelySpam
        ? 'Description too vague or likely spam'
        : 'Basic heuristic check passed',
      reasonCode: isLikelySpam ? 'LIKELY_SPAM' : 'LIGHTWEIGHT_PASS',
      details: {
        hasObjectsOfInterest: !isLikelySpam,
        containsFace: false,
        isRelevantToCivic: !isLikelySpam,
        confidenceLevel: 'low',
      },
    });
  } catch (error) {
    return res.status(500).json({
      allow: false,
      score: 0,
      reason: 'Error in lightweight moderation',
      reasonCode: 'SERVER_ERROR',
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    availableEndpoints: ['/health', '/moderate-photo', '/moderate-photo-lightweight'],
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message,
  });
});

app.listen(port, () => {
  console.log(`Photo moderation server listening on port ${port}`);
  console.log(`Health check: http://localhost:${port}/health`);
});
