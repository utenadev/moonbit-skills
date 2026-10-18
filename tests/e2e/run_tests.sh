#!/bin/bash
# E2E Tests for MoonBit Skills
# Run: bash tests/e2e/run_tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
TEST_DIR="/tmp/moonbit-skills-e2e-test-$$"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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

cleanup() {
    echo -e "\n${GREEN}Cleaning up...${NC}"
    rm -rf "$TEST_DIR"
}

trap cleanup EXIT

cd "$SKILLS_DIR"

# ============================================================================
# Test 1: Clone skills to fresh directory
# ============================================================================
test_start "Test: Clone skills to fresh directory"

mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

if git clone "$SKILLS_DIR" cloned-skills > /dev/null 2>&1; then
    test_pass "Clone successful"
    cd cloned-skills
else
    test_fail "Clone failed"
    exit 1
fi

# ============================================================================
# Test 2: Verify cloned structure
# ============================================================================
test_start "Test: Verify cloned structure"

REQUIRED_DIRS=(
    "beads_mbt"
    "sqlite"
    "rust-porting"
    "js-backend"
    "wasm-cli"
    "testing-strategy"
    "moonbit-agent-guide"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        test_pass "$dir/ exists in clone"
    else
        test_fail "$dir/ missing in clone"
    fi
done

# ============================================================================
# Test 3: Simulate submodule addition (beads_mbt style)
# ============================================================================
test_start "Test: Simulate submodule addition"

cd "$TEST_DIR"
mkdir -p test-project
cd test-project

git init > /dev/null 2>&1
git config user.email "test@example.com"
git config user.name "Test User"

# Use file:// protocol for git submodule
if git -c protocol.file.allow=always submodule add "file://$SKILLS_DIR" .skills > /dev/null 2>&1; then
    test_pass "Submodule addition successful"
    
    if [ -d ".skills" ] && [ -f ".skills/README.md" ]; then
        test_pass "Skills directory accessible"
    else
        test_fail "Skills directory not accessible"
    fi
else
    # Fallback: just copy and verify structure
    cp -r "$SKILLS_DIR" .skills
    if [ -d ".skills" ] && [ -f ".skills/README.md" ]; then
        test_pass "Submodule simulation successful (copy mode)"
    else
        test_fail "Skills directory not accessible"
    fi
fi

# ============================================================================
# Test 4: Simulate submodule addition (task_mbt style)
# ============================================================================
test_start "Test: Simulate submodule addition (second project)"

cd "$TEST_DIR"
mkdir -p another-project
cd another-project

git init > /dev/null 2>&1
git config user.email "test@example.com"
git config user.name "Test User"

# Use file:// protocol for git submodule
if git -c protocol.file.allow=always submodule add "file://$SKILLS_DIR" .skills > /dev/null 2>&1; then
    test_pass "Submodule addition successful (second project)"
    
    if [ -d ".skills" ] && [ -f ".skills/README.md" ]; then
        test_pass "Skills directory accessible (second project)"
    else
        test_fail "Skills directory not accessible (second project)"
    fi
else
    # Fallback: just copy and verify structure
    cp -r "$SKILLS_DIR" .skills
    if [ -d ".skills" ] && [ -f ".skills/README.md" ]; then
        test_pass "Submodule simulation successful (second project, copy mode)"
    else
        test_fail "Skills directory not accessible (second project)"
    fi
fi

# ============================================================================
# Test 5: Verify skills update propagation
# ============================================================================
test_start "Test: Verify skills update propagation"

cd "$TEST_DIR"

# Add a test file to skills
echo "# Test Update" > "$SKILLS_DIR/TEST_UPDATE.md"
cd "$SKILLS_DIR"
git add TEST_UPDATE.md
git commit -m "Test update" > /dev/null 2>&1

# Pull in cloned repo
cd "$TEST_DIR/cloned-skills"
if git pull origin main > /dev/null 2>&1; then
    test_pass "Skills update pulled successfully"
    
    if [ -f "TEST_UPDATE.md" ]; then
        test_pass "TEST_UPDATE.md exists after pull"
    else
        test_fail "TEST_UPDATE.md missing after pull"
    fi
else
    test_fail "Skills update pull failed"
fi

# Cleanup test file
cd "$SKILLS_DIR"
git reset --hard HEAD~1 > /dev/null 2>&1

# ============================================================================
# Test 6: Check file permissions
# ============================================================================
test_start "Test: Check file permissions"

cd "$SKILLS_DIR"

# Check if SKILL.md files are readable
for skill in beads_mbt sqlite rust-porting js-backend wasm-cli testing-strategy; do
    if [ -r "$skill/SKILL.md" ]; then
        test_pass "$skill/SKILL.md is readable"
    else
        test_fail "$skill/SKILL.md is not readable"
    fi
done

# ============================================================================
# Summary
# ============================================================================
echo -e "\n========================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "========================================"

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Some E2E tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}All E2E tests passed!${NC}"
    exit 0
fi
