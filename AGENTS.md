# Agent Instructions: homebrew-purgeapp

## House rules: read first

Read `../../agent-docs/AGENTS.md` before starting any work. It is the shared foundation across all repos: conventions (commit messages, how work lands, local CI) expected to be followed, plus templates for build plans, beads, and reviews.

Purgeapp specific overrides & details:
- **Stack**: Zsh CLI application + Homebrew Ruby formula (`Formula/purgeapp.rb`).
- **Tests**: Run `zsh tests/test_runner.zsh`.
- **Releases**: Managed via `./release.sh`.
- **Landing work**: Per `../../agent-docs/conventions/landing-work.md`, work on branches, verify tests pass, then merge locally.
- **Issue tracking**: Beads only (`bd`).
