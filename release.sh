#!/usr/bin/env zsh

# release.sh — tag a release, compute SHA256, update formula, push everything
# Usage: ./release.sh 1.0.2

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

GITHUB_USER="SiavoshZarrasvand"
REPO="homebrew-purgeapp"
FORMULA="Formula/purgeapp.rb"
SCRIPT="purgeapp"

# ── Validate argument ─────────────────────────────────────────────────────────
VERSION="$1"
if [[ -z "$VERSION" ]]; then
  echo "${RED}Error:${RESET} No version provided."
  echo "Usage: ./release.sh <version>   e.g. ./release.sh 1.0.2"
  exit 1
fi

VERSION="${VERSION#v}"
TAG="v${VERSION}"
TARBALL_URL="https://github.com/${GITHUB_USER}/${REPO}/archive/refs/tags/${TAG}.tar.gz"

echo ""
echo "${BOLD}🚀 Releasing purgeapp ${TAG}${RESET}"
echo ""

# ── Clean working tree check ──────────────────────────────────────────────────
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "${RED}Error:${RESET} Uncommitted changes present. Commit or stash them first."
  exit 1
fi

# ── Check tag doesn't already exist ──────────────────────────────────────────
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "${RED}Error:${RESET} Tag ${TAG} already exists. To redo it:"
  echo "  git tag -d ${TAG} && git push origin :refs/tags/${TAG}"
  exit 1
fi

# ── Step 1: Bump version in script, commit, tag, push ────────────────────────
# The tag is created first so GitHub generates the tarball from the
# correct commit. The formula is updated AFTER because we need the
# tarball SHA256, which only exists once the tag is live.
echo "${BOLD}Step 1: Bumping version in script...${RESET}"
sed -i '' "s/^VERSION=.*/VERSION=\"${VERSION}\"/" "$SCRIPT"
git add "$SCRIPT"
git commit -m "Bump version to ${VERSION}"
git push origin main
echo "  ${GREEN}✓${RESET} Pushed"

echo "${BOLD}Step 2: Creating tag ${TAG}...${RESET}"
git tag "$TAG"
git push origin "$TAG"
echo "  ${GREEN}✓${RESET} Tag pushed — GitHub is generating the tarball"

# ── Step 2: Wait for tarball, compute SHA256 ─────────────────────────────────
echo "${BOLD}Step 3: Fetching SHA256...${RESET}"
sleep 5

SHA=""
for attempt in {1..10}; do
  echo "  Attempt ${attempt}/10..."
  HTTP=$(curl -sL -o /dev/null -w "%{http_code}" "$TARBALL_URL")
  if [[ "$HTTP" == "200" ]]; then
    SHA=$(curl -sL "$TARBALL_URL" | shasum -a 256 | awk '{print $1}')
    [[ -n "$SHA" ]] && break
  fi
  sleep 3
done

if [[ -z "$SHA" ]]; then
  echo "${RED}Error:${RESET} Could not fetch tarball. Try manually:"
  echo "  curl -L ${TARBALL_URL} | shasum -a 256"
  exit 1
fi

echo "  ${GREEN}✓${RESET} SHA256: ${SHA}"

# ── Step 3: Update formula on main ───────────────────────────────────────────
# Brew reads the formula from main, not from the tag — so updating
# the formula after tagging is correct and intentional.
echo "${BOLD}Step 4: Updating formula...${RESET}"
python3 - "$FORMULA" "$TAG" "$SHA" "$VERSION" <<'PYEOF'
import sys, re

formula_path, tag, sha, version = sys.argv[1:]

with open(formula_path, 'r') as f:
    content = f.read()

content = re.sub(r'refs/tags/v[\d.]+\.tar\.gz', f'refs/tags/{tag}.tar.gz', content)
content = re.sub(r'sha256 "[^"]+"', f'sha256 "{sha}"', content)
content = re.sub(r'version "[\d.]+"', f'version "{version}"', content)

with open(formula_path, 'w') as f:
    f.write(content)
PYEOF

echo "  ${GREEN}✓${RESET} Updated — verifying:"
grep -E "^\s*(url|sha256|version)" "$FORMULA"

git add "$FORMULA"
git commit -m "Release ${TAG}: update formula url, sha256, version"
git push origin main
echo "  ${GREEN}✓${RESET} Formula pushed to main"

echo ""
echo "${GREEN}${BOLD}✅ Done! purgeapp ${TAG} is live.${RESET}"
echo ""
echo "Fresh install:"
echo "  ${BOLD}brew tap SiavoshZarrasvand/purgeapp && brew install purgeapp${RESET}"
echo ""
echo "Upgrade if already installed:"
echo "  ${BOLD}brew upgrade purgeapp${RESET}"
echo ""