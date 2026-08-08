#!/usr/bin/env zsh
# Unit tests for AppleConnect plugin discovery, classification, user code exclusion, and verification

SCRIPT_DIR="${0:A:h}"
REPO_DIR="${SCRIPT_DIR:h}"

source "${REPO_DIR}/lib/artifact.zsh"
source "${REPO_DIR}/lib/package_manager.zsh"
source "${REPO_DIR}/lib/shell_config.zsh"
source "${REPO_DIR}/lib/core.zsh"
source "${REPO_DIR}/plugins/appleconnect.zsh"

assert_true() {
  if ! eval "$1"; then
    echo "Assertion failed: $1" >&2
    exit 1
  fi
}

echo "  Testing AppleConnect classification hook..."
local class_user_code
class_user_code=$(plugin_appleconnect_classify "$HOME/Documents/Github/apple/appleconnect_src" "directory" "SAFE")
if [[ "$class_user_code" != "USER_CODE" ]]; then
  echo "Error: AppleConnect plugin failed to classify source code repository as USER_CODE (got $class_user_code)" >&2
  exit 1
fi

local class_protected
class_protected=$(plugin_appleconnect_classify "/Library/Apple/System/Library/Receipts/com.apple.pkg.AppleConnect.plist" "package" "SAFE")
if [[ "$class_protected" != "PROTECTED" ]]; then
  echo "Error: AppleConnect plugin failed to classify system receipt as PROTECTED (got $class_protected)" >&2
  exit 1
fi

echo "  Testing AppleConnect verification lifecycle..."
# Run verification against current machine state
local v_status
v_status=$(plugin_appleconnect_verify "appleconnect")
assert_true '[[ "$v_status" == "REMOVED" || "$v_status" == "STILL_PRESENT" ]]'

echo "AppleConnect plugin tests passed."
