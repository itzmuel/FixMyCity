#!/bin/bash

# Quick Render Deployment Script for FixMyCity Moderation Server
# Usage: bash render-deploy.sh

set -e

echo "=========================================="
echo "FixMyCity Moderation Server - Render Deploy"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "[1/5] Checking prerequisites..."
if ! command -v git &> /dev/null; then
  echo -e "${RED}✗ Git not found. Please install git.${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Git found${NC}"

# Get OpenAI API Key
echo ""
echo "[2/5] OpenAI API Key"
echo "You need an OpenAI API key to use Vision. Get it at: https://platform.openai.com/api-keys"
read -sp "Enter your OpenAI API key (sk-...): " OPENAI_API_KEY
echo ""

if [[ ! $OPENAI_API_KEY =~ ^sk- ]]; then
  echo -e "${RED}✗ Invalid API key format (should start with 'sk-')${NC}"
  exit 1
fi
echo -e "${GREEN}✓ API key accepted${NC}"

# Get GitHub repo info
echo ""
echo "[3/5] GitHub Repository"
echo "Render will deploy from your GitHub repo. Make sure you've pushed the moderation-server/ folder."
read -p "Enter your GitHub repo URL (e.g., https://github.com/user/fixmycity): " GITHUB_REPO

if [[ ! $GITHUB_REPO =~ ^https://github.com ]]; then
  echo -e "${RED}✗ Invalid GitHub URL${NC}"
  exit 1
fi
echo -e "${GREEN}✓ GitHub repo: $GITHUB_REPO${NC}"

# Get Render API key
echo ""
echo "[4/5] Render API Key"
echo "Sign up at https://render.com/dashboard/api-keys and create a new API key"
read -sp "Enter your Render API key: " RENDER_API_KEY
echo ""

if [ -z "$RENDER_API_KEY" ]; then
  echo -e "${RED}✗ Render API key is empty${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Render API key accepted${NC}"

# Deploy
echo ""
echo "[5/5] Creating Render service..."
echo ""

RENDER_RESPONSE=$(curl -s -X POST https://api.render.com/v1/services \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "fixmycity-moderation",
    "ownerId": "me",
    "type": "web_service",
    "environmentSlug": "node",
    "buildCommand": "",
    "startCommand": "npm start",
    "region": "ohio",
    "plan": "free",
    "envVars": [
      {
        "key": "OPENAI_API_KEY",
        "value": "'$OPENAI_API_KEY'"
      },
      {
        "key": "NODE_ENV",
        "value": "production"
      }
    ],
    "repo": "'$GITHUB_REPO'",
    "branch": "main",
    "rootDir": "moderation-server"
  }')

SERVICE_ID=$(echo $RENDER_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
SERVICE_URL=$(echo $RENDER_RESPONSE | grep -o '"serviceUrl":"[^"]*' | cut -d'"' -f4)

if [ -z "$SERVICE_ID" ]; then
  echo -e "${RED}✗ Failed to create service. Response:${NC}"
  echo "$RENDER_RESPONSE"
  exit 1
fi

echo -e "${GREEN}✓ Service created!${NC}"
echo ""
echo "=========================================="
echo "Deployment Started"
echo "=========================================="
echo "Service ID: $SERVICE_ID"
echo "Service URL: $SERVICE_URL"
echo ""
echo "Next steps:"
echo "1. Go to https://dashboard.render.com to monitor deployment"
echo "2. Wait for status to turn 'Live' (usually 5-10 minutes)"
echo "3. Test: curl $SERVICE_URL/health"
echo ""
echo "Then configure Supabase:"
echo "  npx supabase secrets set MODERATION_PROVIDER_URL=$SERVICE_URL/moderate-photo"
echo ""
