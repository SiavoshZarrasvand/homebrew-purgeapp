#!/usr/bin/env zsh
# purgeapp test runner

set -e

SCRIPT_DIR="${0:A:h}"
TEST_DIR="${SCRIPT_DIR}"
REPO_DIR="${TEST_DIR:h}"

export PURGEAPP_TESTING=1

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

echo ""
echo "${BOLD}Running purgeapp Test Suite...${RESET}"
echo ""

TOTAL_PASSED=0
TOTAL_FAILED=0

run_test_file() {
  local test_file="$1"
  echo "${BOLD}Executing ${test_file:t}...${RESET}"
  
  if zsh "$test_file"; then
    echo "  ${GREEN}✓ Passed${RESET}"
  else
    echo "  ${RED}✗ Failed${RESET}"
    (( TOTAL_FAILED++ ))
  fi
}

for tf in "$TEST_DIR"/test_*.zsh(N); do
  if [[ "$tf:t" != "test_runner.zsh" ]]; then
    run_test_file "$tf"
  fi
done

echo ""
echo "────────────────────────────────────────"
if [[ $TOTAL_FAILED -eq 0 ]]; then
  echo "${GREEN}${BOLD}ALL TESTS PASSED!${RESET}"
  exit 0
else
  echo "${RED}${BOLD}SOME TESTS FAILED!${RESET} Failed suites: ${TOTAL_FAILED}"
  exit 1
fi
