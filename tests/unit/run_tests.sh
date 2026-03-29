#!/bin/bash
# Unit Tests for MoonBit Skills
# Run: bash tests/unit/run_tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

# Helper functions
test_start() {
    echo -e "\n${GREEN}▶${NC} $1"
}

test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++)) || true
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++)) || true
}

cd "$SKILLS_DIR"

# ============================================================================
# Test 1: Check required directories exist
# ============================================================================
test_start "Test: Required skill directories exist"

REQUIRED_SKILLS=(
    "beads_mbt"
    "sqlite"
    "rust-porting"
    "js-backend"
    "wasm-cli"
    "testing-strategy"
    "mcp-gemini-cli"
)

for skill in "${REQUIRED_SKILLS[@]}"; do
    if [ -d "$skill" ]; then
        test_pass "$skill/ directory exists"
    else
        test_fail "$skill/ directory missing"
    fi
done

# ============================================================================
# Test 2: Check SKILL.md files exist
# ============================================================================
test_start "Test: SKILL.md files exist"

SKILLS_WITH_DOCS=(
    "beads_mbt"
    "sqlite"
    "rust-porting"
    "js-backend"
    "wasm-cli"
    "testing-strategy"
    "mcp-gemini-cli"
)

for skill in "${SKILLS_WITH_DOCS[@]}"; do
    if [ -f "$skill/SKILL.md" ]; then
        test_pass "$skill/SKILL.md exists"
    else
        test_fail "$skill/SKILL.md missing"
    fi
done

# ============================================================================
# Test 3: Check SKILL.md file size (not empty)
# ============================================================================
test_start "Test: SKILL.md files are not empty"

for skill in "${SKILLS_WITH_DOCS[@]}"; do
    if [ -f "$skill/SKILL.md" ]; then
        size=$(wc -c < "$skill/SKILL.md")
        if [ "$size" -gt 100 ]; then
            test_pass "$skill/SKILL.md has content ($size bytes)"
        else
            test_fail "$skill/SKILL.md is too small ($size bytes)"
        fi
    fi
done

# ============================================================================
# Test 4: Check testing-strategy sub-files
# ============================================================================
test_start "Test: testing-strategy sub-files exist"

TESTING_FILES=(
    "SKILL.md"
    "wasi-testing.md"
    "native-testing.md"
    "snapshot.md"
    "quickcheck.md"
)

for file in "${TESTING_FILES[@]}"; do
    if [ -f "testing-strategy/$file" ]; then
        test_pass "testing-strategy/$file exists"
    else
        test_fail "testing-strategy/$file missing"
    fi
done

# ============================================================================
# Test 5: Check LICENSE file
# ============================================================================
test_start "Test: LICENSE file exists"

if [ -f "LICENSE" ]; then
    test_pass "LICENSE exists"
else
    test_fail "LICENSE missing"
fi

# ============================================================================
# Test 6: Check README.md
# ============================================================================
test_start "Test: README.md exists and has content"

if [ -f "README.md" ]; then
    test_pass "README.md exists"
    
    # Check for required sections
    if grep -q "MoonBit" "README.md"; then
        test_pass "README.md mentions MoonBit"
    else
        test_fail "README.md should mention MoonBit"
    fi
    
    if grep -q "skills" "README.md"; then
        test_pass "README.md mentions skills"
    else
        test_fail "README.md should mention skills"
    fi
else
    test_fail "README.md missing"
fi

# ============================================================================
# Test 7: Check for broken internal links (basic check)
# ============================================================================
test_start "Test: Check for obvious broken links"

# Check testing-strategy/SKILL.md for internal links
if [ -f "testing-strategy/SKILL.md" ]; then
    if grep -q "\./wasi-testing.md" "testing-strategy/SKILL.md"; then
        test_pass "testing-strategy/SKILL.md has internal links"
    else
        test_fail "testing-strategy/SKILL.md should have internal links"
    fi
fi

# ============================================================================
# Summary
# ============================================================================
echo -e "\n========================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "========================================"

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}All unit tests passed!${NC}"
    exit 0
fi
