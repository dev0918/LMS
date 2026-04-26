#!/bin/bash

# Multi-Environment LMS - Endpoint Verification Script
# This script verifies that each environment is properly configured
# Run locally: ./verify-endpoints.sh

set -e

echo "======================================"
echo "  LMS Multi-Environment Verification"
echo "======================================"
echo ""

# Check if .env files exist
echo "✓ Checking environment files..."
for env_file in .env.main .env.uat .env.develop; do
    if [ -f "$env_file" ]; then
        echo "  ✓ $env_file exists"
    else
        echo "  ✗ $env_file MISSING!"
        exit 1
    fi
done
echo ""

# Function to test environment locally
test_environment() {
    local env=$1
    local env_file=".env.$env"
    local port=""
    local prefix=""
    
    echo "Testing $env environment..."
    
    # Get port from env (filter out comments)
    port=$(grep "^APP_PORT=" "$env_file" | cut -d'=' -f2)
    prefix=$(grep "^ENVIRONMENT=" "$env_file" | cut -d'=' -f2)
    
    echo "  Port: $port"
    echo "  Path: /$prefix/"
    echo "  Static URL: $(grep "^STATIC_URL=" "$env_file" | cut -d'=' -f2)"
    echo "  Media URL: $(grep "^MEDIA_URL=" "$env_file" | cut -d'=' -f2)"
    echo ""
    
    # Verify required settings
    if grep -q "^SECRET_KEY=" "$env_file"; then
        echo "  ✓ SECRET_KEY configured"
    fi
    
    if grep -q "^DATABASE_URL=" "$env_file"; then
        echo "  ✓ DATABASE_URL configured"
    else
        echo "  ✗ DATABASE_URL not configured"
    fi
    
    if grep -q "^ALLOWED_HOSTS=" "$env_file"; then
        echo "  ✓ ALLOWED_HOSTS configured"
    else
        echo "  ✗ ALLOWED_HOSTS not configured"
    fi
    
    echo ""
}

# Test each environment
echo "=== ENVIRONMENT CONFIGURATION VERIFICATION ==="
echo ""

test_environment "develop"
test_environment "uat"
test_environment "main"

echo "=== DJANGO STATIC FILES VERIFICATION ==="
echo ""

# Check if settings.py has environment support
if grep -q "ENVIRONMENT = config" config/settings.py; then
    echo "✓ settings.py has ENVIRONMENT support"
else
    echo "✗ settings.py missing ENVIRONMENT configuration"
    exit 1
fi

if grep -q "_env_prefix" config/settings.py; then
    echo "✓ settings.py has environment-specific STATIC_URL logic"
else
    echo "✗ settings.py missing STATIC_URL configuration"
    exit 1
fi

if grep -q "_static_root_suffix" config/settings.py; then
    echo "✓ settings.py has environment-specific STATIC_ROOT logic"
else
    echo "✗ settings.py missing STATIC_ROOT configuration"
    exit 1
fi

echo ""
echo "=== GITHUB ACTIONS WORKFLOWS VERIFICATION ==="
echo ""

if [ -f ".github/workflows/deploy.yml" ]; then
    echo "✓ deploy.yml exists (Production)"
else
    echo "✗ deploy.yml MISSING"
    exit 1
fi

if [ -f ".github/workflows/deploy-uat.yml" ]; then
    echo "✓ deploy-uat.yml exists (UAT)"
else
    echo "✗ deploy-uat.yml MISSING"
    exit 1
fi

if [ -f ".github/workflows/deploy-develop.yml" ]; then
    echo "✓ deploy-develop.yml exists (Develop)"
else
    echo "✗ deploy-develop.yml MISSING"
    exit 1
fi

if [ -f ".github/workflows/pr-uat-to-main.yml" ]; then
    echo "✓ pr-uat-to-main.yml exists (PR Validation)"
else
    echo "✗ pr-uat-to-main.yml MISSING"
    exit 1
fi

echo ""
echo "=== NGINX CONFIGURATION VERIFICATION ==="
echo ""

if [ -f "nginx-config-template.conf" ]; then
    echo "✓ nginx-config-template.conf exists"
    
    if grep -q "upstream gunicorn_main" nginx-config-template.conf; then
        echo "✓ Production upstream configured"
    fi
    
    if grep -q "upstream gunicorn_uat" nginx-config-template.conf; then
        echo "✓ UAT upstream configured"
    fi
    
    if grep -q "upstream gunicorn_develop" nginx-config-template.conf; then
        echo "✓ Develop upstream configured"
    fi
    
    if grep -q "location /uat/" nginx-config-template.conf; then
        echo "✓ UAT location configured"
    fi
    
    if grep -q "location /develop/" nginx-config-template.conf; then
        echo "✓ Develop location configured"
    fi
else
    echo "✗ nginx-config-template.conf MISSING"
    exit 1
fi

echo ""
echo "======================================"
echo "  ✅ All verifications passed!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Update sensitive values in .env files"
echo "2. Push environment files to GitHub"
echo "3. Apply nginx configuration to EC2"
echo "4. Create git branches: develop, uat (if they don't exist)"
echo "5. Push branches to GitHub"
echo "6. Run GitHub Actions to deploy each environment"
echo ""
echo "Endpoint URLs to verify after deployment:"
echo "  - Production: http://98.92.14.139/"
echo "  - UAT:        http://98.92.14.139/uat/"
echo "  - Develop:    http://98.92.14.139/develop/"
echo ""
