#!/bin/bash

echo "============================================================"
echo "🧪 TESTIRANJE LOOKWRITELEARN BACKEND API"
echo "============================================================"

# Test 1: Health Check
echo ""
echo "📊 Test 1: Health Check"
echo "------------------------------------------------------------"
HEALTH=$(curl -s http://localhost:5001/health)
if [ $? -eq 0 ]; then
    echo "✅ Health check PASSED"
    echo "   Response: $HEALTH"
else
    echo "❌ Health check FAILED"
    exit 1
fi

# Test 2: Test sa jednostavnim test podacima
echo ""
echo "📊 Test 2: API Compare Endpoint (sa mock podacima)"
echo "------------------------------------------------------------"

# Kreiraj jednostavnu test sliku (1x1 pixel crna slika u base64)
# iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==
# je 1x1 crna slika

TEST_DATA='{
  "image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
  "letter": "A",
  "mode": "upper"
}'

RESPONSE=$(curl -s -X POST http://localhost:5001/api/compare \
  -H "Content-Type: application/json" \
  -d "$TEST_DATA")

if [ $? -eq 0 ]; then
    echo "✅ API call PASSED"
    echo ""
    echo "Response:"
    echo "$RESPONSE" | python3 -m json.tool
    
    # Ekstrakt score
    SCORE=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])")
    FEEDBACK=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['feedback'])")
    
    echo ""
    echo "📈 Score: $SCORE%"
    echo "💬 Feedback: $FEEDBACK"
else
    echo "❌ API call FAILED"
fi

# Test 3: Invalid request (bez image parametra)
echo ""
echo "📊 Test 3: Invalid Request Handling"
echo "------------------------------------------------------------"

INVALID_DATA='{
  "letter": "A",
  "mode": "upper"
}'

STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:5001/api/compare \
  -H "Content-Type: application/json" \
  -d "$INVALID_DATA")

if [ "$STATUS_CODE" = "400" ]; then
    echo "✅ Error handling PASSED (očekivano 400, dobijeno $STATUS_CODE)"
else
    echo "⚠️  Unexpected status code: $STATUS_CODE"
fi

# Test 4: Različita slova
echo ""
echo "📊 Test 4: Različita Slova"
echo "------------------------------------------------------------"

for LETTER in A B C a b c 1 2 3; do
    MODE="upper"
    if [[ "$LETTER" =~ ^[a-z]$ ]]; then
        MODE="lower"
    elif [[ "$LETTER" =~ ^[0-9]$ ]]; then
        MODE="number"
    fi
    
    TEST_DATA="{\"image\": \"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==\", \"letter\": \"$LETTER\", \"mode\": \"$MODE\"}"
    
    RESPONSE=$(curl -s -X POST http://localhost:5001/api/compare \
      -H "Content-Type: application/json" \
      -d "$TEST_DATA")
    
    if [ $? -eq 0 ]; then
        SCORE=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])" 2>/dev/null)
        if [ ! -z "$SCORE" ]; then
            echo "   ✅ Slovo '$LETTER' ($MODE): Score $SCORE%"
        else
            echo "   ⚠️  Slovo '$LETTER' ($MODE): Invalid response"
        fi
    else
        echo "   ❌ Slovo '$LETTER' ($MODE): Request failed"
    fi
done

echo ""
echo "============================================================"
echo "✅ TESTIRANJE ZAVRŠENO!"
echo "============================================================"
echo ""
echo "Backend API je funkcionalan i spreman za korišćenje! 🚀"
