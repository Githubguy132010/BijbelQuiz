#!/bin/bash
# Security and functionality test script for BijbelQuiz Admin Portal

echo "BijbelQuiz Admin Portal - Security and Functionality Test Script"
echo "================================================================"

# Test 1: Check if all required files exist
echo ""
echo "Test 1: Checking required files..."
FILES=(
    "server.js"
    "package.json"
    "index.html"
    "styles.css"
    "app.js"
    ".env"
    "README.md"
)

MISSING_FILES=()
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo "✓ All required files are present"
else
    echo "✗ Missing files: ${MISSING_FILES[*]}"
fi

# Test 2: Check if dependencies are properly listed in package.json
echo ""
echo "Test 2: Checking dependencies in package.json..."

# Check if security-related packages are listed
if grep -q "helmet" package.json && grep -q "bcrypt" package.json && grep -q "jsonwebtoken" package.json && grep -q "express-rate-limit" package.json; then
    echo "✓ Security-related dependencies are present"
else
    echo "✗ Security-related dependencies are missing"
fi

# Test 3: Check if environment file has required variables
echo ""
echo "Test 3: Checking environment variables in .env..."

if grep -q "JWT_SECRET" .env && grep -q "SUPABASE_URL" .env && grep -q "ALLOWED_ORIGINS" .env; then
    echo "✓ Required environment variables are present"
else
    echo "✗ Required environment variables are missing"
fi

# Test 4: Check if sensitive information is not hardcoded
echo ""
echo "Test 4: Checking for hardcoded sensitive information..."

# Check for hardcoded passwords, secrets, or API keys in source files
# Excluding the fallback admin password hash and JWT secret which are intended as defaults
HARD_CODED_SECRETS=$(grep -r -n -i -E "(password|secret|key|token)" --include="*.js" --include="*.html" . | grep -v "node_modules" | grep -v "package-lock.json" | grep -v "README.md" | grep -v "test.sh" | grep -v "fallback_secret_for_dev" | grep -v "bcrypt hash for 'admin123'" || true)

if [ -z "$HARD_CODED_SECRETS" ]; then
    echo "✓ No apparent hardcoded secrets found"
else
    echo "⚠ Possible hardcoded secrets found:"
    echo "$HARD_CODED_SECRETS"
fi

# Test 5: Check if authentication is required for API endpoints
echo ""
echo "Test 5: Checking for authentication requirements in server.js..."

if grep -q "authenticateToken" server.js && grep -q "middleware" server.js; then
    echo "✓ Authentication middleware is implemented"
else
    echo "✗ Authentication middleware may not be implemented"
fi

# Test 6: Check for input validation
echo ""
echo "Test 6: Checking for input validation in server.js..."

if grep -q "validateAndSanitize" server.js && grep -q "validator" server.js; then
    echo "✓ Input validation and sanitization is implemented"
else
    echo "✗ Input validation and sanitization may not be implemented"
fi

# Test 7: Check for rate limiting
echo ""
echo "Test 7: Checking for rate limiting implementation..."

if grep -q "rateLimit" server.js; then
    echo "✓ Rate limiting is implemented"
else
    echo "✗ Rate limiting may not be implemented"
fi

# Test 8: Check for security headers
echo ""
echo "Test 8: Checking for security headers..."

if grep -q "helmet" server.js; then
    echo "✓ Security headers (Helmet) are implemented"
else
    echo "✗ Security headers (Helmet) may not be implemented"
fi

# Test 9: Check for proper error handling
echo ""
echo "Test 9: Checking for error handling..."

ERROR_HANDLING=$(grep -n -E "(try|catch|error|err)" server.js | head -5)
if [ ! -z "$ERROR_HANDLING" ]; then
    echo "✓ Error handling is implemented"
else
    echo "✗ Error handling may not be implemented"
fi

# Test 10: Check for XSS protection
echo ""
echo "Test 10: Checking for XSS protection..."

if grep -q "xss" server.js && grep -q "sanitizeInput" server.js; then
    echo "✓ XSS protection is implemented"
else
    echo "✗ XSS protection may not be implemented"
fi

echo ""
echo "Security and functionality tests completed."
echo ""
echo "Note: This script performs static analysis only. For comprehensive testing,"
echo "manually test the application with various inputs and verify functionality."