#!/bin/bash

# Test script za LookWriteLearn Standalone Mode
# Proverava da li su svi template-i na mestu i da li aplikacija radi

echo "🔍 Testing LookWriteLearn Standalone Mode..."
echo ""

# 1. Check assets structure
echo "1️⃣ Proveravam assets strukturu..."
UPPERCASE_COUNT=$(find assets/templates/uppercase -name "*.png" 2>/dev/null | wc -l)
LOWERCASE_COUNT=$(find assets/templates/lowercase -name "*.png" 2>/dev/null | wc -l)
NUMBERS_COUNT=$(find assets/templates/numbers -name "*.png" 2>/dev/null | wc -l)

echo "   Uppercase templates: $UPPERCASE_COUNT (expected: 260)"
echo "   Lowercase templates: $LOWERCASE_COUNT (expected: 260)"
echo "   Numbers templates: $NUMBERS_COUNT (expected: 100)"

TOTAL=$((UPPERCASE_COUNT + LOWERCASE_COUNT + NUMBERS_COUNT))
echo "   ✅ Total templates: $TOTAL (expected: 620)"

if [ $TOTAL -lt 620 ]; then
    echo "   ⚠️  Warning: Missing templates!"
fi

echo ""

# 2. Check pubspec.yaml assets
echo "2️⃣ Proveravam pubspec.yaml..."
if grep -q "assets/templates/uppercase/A/" pubspec.yaml; then
    echo "   ✅ Assets properly declared in pubspec.yaml"
else
    echo "   ❌ Assets NOT declared in pubspec.yaml"
fi

echo ""

# 3. Check services
echo "3️⃣ Proveravam servise..."
if [ -f "lib/services/template_loader.dart" ]; then
    echo "   ✅ template_loader.dart exists"
else
    echo "   ❌ template_loader.dart missing"
fi

if [ -f "lib/services/template_matcher.dart" ]; then
    echo "   ✅ template_matcher.dart exists"
else
    echo "   ❌ template_matcher.dart missing"
fi

echo ""

# 4. Run Flutter analyze
echo "4️⃣ Running Flutter analyze..."
flutter analyze --no-pub 2>&1 | grep -E "(error|warning)" | head -5
if [ $? -eq 0 ]; then
    echo "   ⚠️  Some issues found (check above)"
else
    echo "   ✅ No critical issues"
fi

echo ""

# 5. Check dependencies
echo "5️⃣ Proveravam dependencies..."
if grep -q "image:" pubspec.yaml; then
    echo "   ✅ image package installed"
else
    echo "   ❌ image package missing"
fi

if grep -q "google_fonts:" pubspec.yaml; then
    echo "   ✅ google_fonts package installed"
else
    echo "   ❌ google_fonts package missing"
fi

echo ""

# 6. App size estimate
echo "6️⃣ Procena veličine aplikacije..."
TEMPLATE_SIZE=$(du -sh assets/templates 2>/dev/null | awk '{print $1}')
echo "   Templates size: $TEMPLATE_SIZE"

echo ""
echo "✅ Test završen!"
echo ""
echo "Za pokretanje aplikacije:"
echo "  flutter run -d macos     (macOS)"
echo "  flutter run -d chrome    (Web)"
echo "  flutter run              (default device)"

