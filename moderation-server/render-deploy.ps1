# Quick Render Deployment Script for FixMyCity Moderation Server (Windows PowerShell)
# Usage: .\render-deploy.ps1

Write-Host "=========================================="
Write-Host "FixMyCity Moderation Server - Render Deploy" -ForegroundColor Cyan
Write-Host "=========================================="
Write-Host ""

# Check prerequisites
Write-Host "[1/5] Checking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "✗ Git not found. Please install git." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Git found" -ForegroundColor Green

# Get OpenAI API Key
Write-Host ""
Write-Host "[2/5] OpenAI API Key" -ForegroundColor Yellow
Write-Host "You need an OpenAI API key to use Vision. Get it at: https://platform.openai.com/api-keys"
$OPENAI_API_KEY = Read-Host "Enter your OpenAI API key (sk-...)" -AsSecureString
$OPENAI_API_KEY_PLAIN = [System.Net.NetworkCredential]::new("", $OPENAI_API_KEY).Password

if (-not ($OPENAI_API_KEY_PLAIN -match "^sk-")) {
    Write-Host "✗ Invalid API key format (should start with 'sk-')" -ForegroundColor Red
    exit 1
}
Write-Host "✓ API key accepted (hidden for security)" -ForegroundColor Green

# Get GitHub repo info
Write-Host ""
Write-Host "[3/5] GitHub Repository" -ForegroundColor Yellow
Write-Host "Render will deploy from your GitHub repo. Make sure you've pushed the moderation-server/ folder."
$GITHUB_REPO = Read-Host "Enter your GitHub repo URL (e.g., https://github.com/user/fixmycity)"

if (-not ($GITHUB_REPO -match "https://github.com")) {
    Write-Host "✗ Invalid GitHub URL" -ForegroundColor Red
    exit 1
}
Write-Host "✓ GitHub repo: $GITHUB_REPO" -ForegroundColor Green

# Get Render API key
Write-Host ""
Write-Host "[4/5] Render API Key" -ForegroundColor Yellow
Write-Host "Sign up at https://render.com/dashboard/api-keys and create a new API key"
$RENDER_API_KEY = Read-Host "Enter your Render API key" -AsSecureString
$RENDER_API_KEY_PLAIN = [System.Net.NetworkCredential]::new("", $RENDER_API_KEY).Password

if ([string]::IsNullOrEmpty($RENDER_API_KEY_PLAIN)) {
    Write-Host "✗ Render API key is empty" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Render API key accepted (hidden for security)" -ForegroundColor Green

# Deploy
Write-Host ""
Write-Host "[5/5] Creating Render service..." -ForegroundColor Yellow
Write-Host ""

$payload = @{
    name = "fixmycity-moderation"
    ownerId = "me"
    type = "web_service"
    environmentSlug = "node"
    buildCommand = ""
    startCommand = "npm start"
    region = "ohio"
    plan = "free"
    envVars = @(
        @{
            key = "OPENAI_API_KEY"
            value = $OPENAI_API_KEY_PLAIN
        },
        @{
            key = "NODE_ENV"
            value = "production"
        }
    )
    repo = $GITHUB_REPO
    branch = "main"
    rootDir = "moderation-server"
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-WebRequest -Uri "https://api.render.com/v1/services" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $RENDER_API_KEY_PLAIN"
            "Content-Type" = "application/json"
        } `
        -Body $payload -ErrorAction Stop

    $responseJson = $response.Content | ConvertFrom-Json
    $SERVICE_ID = $responseJson.id
    $SERVICE_URL = $responseJson.serviceUrl
    
    if ([string]::IsNullOrEmpty($SERVICE_ID)) {
        Write-Host "✗ Failed to create service. Response:" -ForegroundColor Red
        Write-Host $response.Content
        exit 1
    }

    Write-Host "✓ Service created!" -ForegroundColor Green
} catch {
    Write-Host "✗ Error creating service:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Deployment Started" -ForegroundColor Green
Write-Host "=========================================="
Write-Host "Service ID: $SERVICE_ID"
Write-Host "Service URL: $SERVICE_URL"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Go to https://dashboard.render.com to monitor deployment"
Write-Host "2. Wait for status to turn 'Live' (usually 5-10 minutes)"
Write-Host "3. Test: curl $SERVICE_URL/health"
Write-Host ""
Write-Host "Then configure Supabase:"
Write-Host "  npx supabase secrets set MODERATION_PROVIDER_URL=$SERVICE_URL/moderate-photo"
Write-Host ""
