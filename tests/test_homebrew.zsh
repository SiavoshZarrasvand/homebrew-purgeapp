#!/usr/bin/env zsh
# Unit tests for Homebrew plugin discovery, classification, and safe shell config line removal

SCRIPT_DIR="${0:A:h}"
REPO_DIR="${SCRIPT_DIR:h}"

source "${REPO_DIR}/lib/artifact.zsh"
source "${REPO_DIR}/lib/package_manager.zsh"
source "${REPO_DIR}/lib/shell_config.zsh"
source "${REPO_DIR}/lib/core.zsh"
source "${REPO_DIR}/plugins/homebrew.zsh"

assert_true() {
  if ! eval "$1"; then
    echo "Assertion failed: $1" >&2
    exit 1
  fi
}

echo "  Testing Homebrew safe shell config line removal..."
# Create temporary shell profile file with user content and brew shellenv line
TEST_PROFILE=$(mktemp "/tmp/zprofile_test.XXXXXX")
cat << 'EOF' > "$TEST_PROFILE"
# User zprofile configuration
export PATH="$HOME/bin:$PATH"
eval "$(/opt/homebrew/bin/brew shellenv)"
export ALIAS_NAME="myalias"
EOF

# Verify grep detects brew shellenv line
if ! grep -q "brew shellenv" "$TEST_PROFILE"; then
  echo "Error: Test profile setup failed." >&2
  exit 1
fi

# Execute safe line removal
shell_config_remove_line "$TEST_PROFILE" "brew shellenv" "no"

# Assert brew line is removed
if grep -q "brew shellenv" "$TEST_PROFILE"; then
  echo "Error: brew shellenv line was NOT removed!" >&2
  exit 1
fi

# Assert user configuration lines are preserved intact
assert_true 'grep -q "export PATH=\"\$HOME/bin:\$PATH\"" "$TEST_PROFILE"'
assert_true 'grep -q "export ALIAS_NAME=\"myalias\"" "$TEST_PROFILE"'

# Clean up
rm -f "$TEST_PROFILE"

echo "  Testing Homebrew plugin discovery..."
local raw_inv
raw_inv=$(plugin_homebrew_discover "homebrew")
assert_true '[[ -n "$raw_inv" ]]'

echo "Homebrew plugin tests passed."
