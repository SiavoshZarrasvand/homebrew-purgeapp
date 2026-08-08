#!/usr/bin/env zsh
# Unit tests for generic_app.zsh plugin: discovery, Group Containers safety, classification

SCRIPT_DIR="${0:A:h}"
REPO_DIR="${SCRIPT_DIR:h}"

source "${REPO_DIR}/lib/artifact.zsh"
source "${REPO_DIR}/lib/package_manager.zsh"
source "${REPO_DIR}/lib/shell_config.zsh"
source "${REPO_DIR}/lib/core.zsh"
source "${REPO_DIR}/plugins/generic_app.zsh"

assert_true() {
  if ! eval "$1"; then
    echo "Assertion failed: $1" >&2
    exit 1
  fi
}

assert_false() {
  if eval "$1"; then
    echo "Assertion failed (expected false): $1" >&2
    exit 1
  fi
}

echo "  Testing Group Containers unanchored match demotion..."
# Create temporary unanchored Group Container matching app name (e.g., 'myapp')
TEST_GC_DIR="$HOME/Library/Group Containers/shared.org.company.myapp.data"
mkdir -p "$TEST_GC_DIR"

# Run discovery for 'myapp'
local raw_inv
raw_inv=$(plugin_generic_app_discover "myapp")

# Assert that the unanchored Group Container match is NOT classified as SAFE
local gc_line
gc_line=$(echo "$raw_inv" | grep "$TEST_GC_DIR" || true)

if [[ -n "$gc_line" ]]; then
  local item_path="" type="" class="" reason="" strat=""
  IFS='|' read -r item_path type class reason strat <<< "$gc_line"
  
  if [[ "$class" == "SAFE" ]]; then
    echo "Error: Unanchored Group Container match $TEST_GC_DIR was classified as SAFE!" >&2
    rm -rf "$TEST_GC_DIR"
    exit 1
  fi
  assert_true '[[ "$class" == "UNKNOWN" ]]'
fi

# Clean up temporary dir
rm -rf "$TEST_GC_DIR"

echo "  Testing Group Containers anchored match classification..."
# Create anchored Group Container
TEST_GC_ANCHORED="$HOME/Library/Group Containers/group.com.myapp"
mkdir -p "$TEST_GC_ANCHORED"

raw_inv=$(plugin_generic_app_discover "myapp")
gc_line=$(echo "$raw_inv" | grep "$TEST_GC_ANCHORED" || true)

if [[ -n "$gc_line" ]]; then
  local item_path="" type="" class="" reason="" strat=""
  IFS='|' read -r item_path type class reason strat <<< "$gc_line"
  assert_true '[[ "$class" == "SAFE" ]]'
fi

rm -rf "$TEST_GC_ANCHORED"

echo "  Testing generic_app verification lifecycle..."
local v_status
v_status=$(plugin_generic_app_verify "myapp")
assert_true '[[ "$v_status" == "REMOVED" || "$v_status" == "STILL_PRESENT" ]]'

echo "generic_app plugin tests passed."
