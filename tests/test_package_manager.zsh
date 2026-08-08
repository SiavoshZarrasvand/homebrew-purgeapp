#!/usr/bin/env zsh
# Unit tests for generic package manager discovery and removal interface

SCRIPT_DIR="${0:A:h}"
REPO_DIR="${SCRIPT_DIR:h}"

source "${REPO_DIR}/lib/package_manager.zsh"

assert_true() {
  if ! eval "$1"; then
    echo "Assertion failed: $1" >&2
    exit 1
  fi
}

echo "  Testing package manager detection..."
# Test detection function returns integer 0 or 1 without crashing
pkg_manager_detect "uv" || true
pkg_manager_detect "pipx" || true

echo "  Testing package manager cache cleaning dry-run..."
TEST_CACHE_DIR=$(mktemp -d "/tmp/uv_cache_test.XXXXXX")
touch "${TEST_CACHE_DIR}/awsappleconnect.whl"

# Dry run removal should leave file intact
pkg_manager_remove "uv_cache" "${TEST_CACHE_DIR}/awsappleconnect.whl" "yes"
assert_true '[[ -f "${TEST_CACHE_DIR}/awsappleconnect.whl" ]]'

# Execution removal should delete file
pkg_manager_remove "uv_cache" "${TEST_CACHE_DIR}/awsappleconnect.whl" "no"
assert_true '[[ ! -f "${TEST_CACHE_DIR}/awsappleconnect.whl" ]]'

rm -rf "$TEST_CACHE_DIR"

echo "Package manager interface tests passed."
