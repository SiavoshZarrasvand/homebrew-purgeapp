# 🧹 purgeapp

**Plugin-based discovery and uninstall system for macOS applications and software ecosystems.**

`purgeapp` is an application-aware discovery and removal system. Unlike traditional uninstallers or blind path-deletion scripts, `purgeapp` uses dedicated plugins to discover application artifacts across processes, LaunchAgents, LaunchDaemons, Privileged Helpers, Frameworks, User/System Library containers, package managers, and shell configurations.

---

## Features

- **Plugin Architecture**: Application-specific plugins (`appleconnect`, `homebrew`) teach `purgeapp` how to locate and verify artifacts dynamically.
- **Discovery First**: Discovers and classifies artifacts into `Safe to Remove`, `Disposable Caches`, `Package Manager Artifacts`, `Protected System Artifacts`, and `User Code`.
- **Safety Model**: Never deletes user source code repositories (e.g. `~/Documents/Github/**`) or critical macOS system directories. SIP-protected system receipts are identified and reported safely.
- **Dry-Run Mode**: Inspect the complete inventory before deleting anything.
- **Safe Shell Configuration**: Removes target shell initialization lines cleanly without altering unrelated user shell profile code.

---

## Install

```bash
brew tap SiavoshZarrasvand/purgeapp
brew install purgeapp
```

---

## Usage

```bash
purgeapp [options] <target>
```

### Examples

```bash
# Uninstall AppleConnect application & corporate developer artifacts
purgeapp appleconnect

# Remove Homebrew installation & shell integrations
purgeapp homebrew

# Uninstall standard macOS application
purgeapp Workpuls

# List available plugins
purgeapp list
```

### Dry Run (Recommended)

Preview the discovered inventory without making any changes:

```bash
purgeapp appleconnect --dry-run
purgeapp homebrew --dry-run
```

### Options

```bash
  -d, --dry-run    Show discovery inventory without deleting anything
  -y, --yes        Auto-confirm deletion prompts
  -v, --version    Print version
  -h, --help       Show help message
```

---

## Plugin System & Architecture

`purgeapp` uses a structured discovery lifecycle:

```text
Plugin -> Discovery -> Inventory -> Classification -> Confirmation -> Removal -> Verification
```

### Custom Paths Removal

Arbitrary `custom-paths` deletion was completely removed in v4.0.0. `purgeapp` relies exclusively on application-aware discovery plugins rather than user-provided file deletion lists.

---

## License

MIT © [Siavosh Zarrasvand](https://github.com/SiavoshZarrasvand)