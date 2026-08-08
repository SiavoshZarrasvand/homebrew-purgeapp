#!/usr/bin/env zsh
# Unit tests for core engine, artifact classification, critical path protection, custom-paths removal

SCRIPT_DIR="${0:A:h}"
REPO_DIR="${SCRIPT_DIR:h}"

source "${REPO_DIR}/lib/artifact.zsh"
source "${REPO_DIR}/lib/shell_config.zsh"
source "${REPO_DIR}/lib/core.zsh"

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

echo "  Testing critical path protections..."
assert_true 'is_critical_path "/"'
assert_true 'is_critical_path "/System"'
assert_true 'is_critical_path "/Library"'
assert_true 'is_critical_path "/Applications"'
assert_true 'is_critical_path "$HOME"'
assert_true 'is_critical_path "$HOME/Documents"'
assert_false 'is_critical_path "/Applications/DummyApp.app"'
assert_false 'is_critical_path "$HOME/Library/Application Support/DummyApp"'

echo "  Testing user code exclusion..."
assert_true 'is_user_code "$HOME/Documents/Github/myrepo"'
assert_true 'is_user_code "$HOME/Documents/GitHub/apple/appleconnect"'
assert_true 'is_user_code "$HOME/Projects/appleconnect-client"'
assert_false 'is_user_code "$HOME/Library/Application Support/AppleConnect"'
assert_false 'is_user_code "/Library/Frameworks/AppleConnect.framework"'

echo "  Testing protected system path identification..."
assert_true 'is_protected_system "/Library/Apple/System/Library/Receipts/com.apple.pkg.AppleConnect.plist"'
assert_false 'is_protected_system "$HOME/Library/Caches/AppleConnect"'

echo "  Testing custom-paths elimination regression check..."
# Assert APP_CUSTOM_PATHS is not declared or used anywhere in core scripts
if grep -rn "APP_CUSTOM_PATHS" "${REPO_DIR}/lib" "${REPO_DIR}/plugins" "${REPO_DIR}/purgeapp" 2>/dev/null; then
  echo "Error: APP_CUSTOM_PATHS still exists in codebase!" >&2
  exit 1
fi

echo "  Testing CLI dry-run execution safety..."
# Create a dummy temporary directory to simulate dry-run
TEST_TMP_DIR=$(mktemp -d "/tmp/purgeapp_test.XXXXXX")
mkdir -p "${TEST_TMP_DIR}/Library/Application Support/TestApp"
touch "${TEST_TMP_DIR}/Library/Application Support/TestApp/data.txt"

# Run default_remove_strategy with dry_run="yes"
default_remove_strategy "${TEST_TMP_DIR}/Library/Application Support/TestApp" "directory" "rm_dir" "yes" >/dev/null 2>&1

# Assert that file still exists after dry-run
assert_true '[[ -d "${TEST_TMP_DIR}/Library/Application Support/TestApp" ]]'

# Clean up test temp dir
rm -rf "$TEST_TMP_DIR"

echo "Core engine tests passed."
