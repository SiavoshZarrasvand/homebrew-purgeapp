# 🧹 purgeapp

**Completely remove a macOS app and all its leftover files — in one command.**

Most uninstallers only delete the `.app` bundle. `purgeapp` hunts down and removes everything: preferences, caches, logs, launch agents, daemons, containers, and support files — even if the app was already manually deleted.

---

## Install

```bash
brew tap SiavoshZarrasvand/purgeapp
brew install purgeapp
```

---

## Usage

```bash
purgeapp <AppName>
```

All of these work:

```bash
purgeapp Workpuls
purgeapp Workpuls.app
purgeapp "pgAdmin 4"
purgeapp pgAdmin\ 4.app
```

### Dry run first (recommended)

See exactly what will be removed before deleting anything:

```bash
purgeapp --dry-run Workpuls
```

### Options

```bash
purgeapp --dry-run    # Preview without deleting
purgeapp --yes        # Auto-confirm deletion prompts
purgeapp --version    # Print version
purgeapp --help       # Show help
```

---

## What it removes

| Location | Example |
|---|---|
| App bundle | `/Applications/Workpuls.app` |
| App Support | `~/Library/Application Support/workpuls*` |
| Preferences | `~/Library/Preferences/com.workpuls.*` |
| Caches | `~/Library/Caches/com.workpuls.*` |
| Logs | `~/Library/Logs/workpuls*` |
| Containers | `~/Library/Containers/com.workpuls*` |
| Group Containers | `~/Library/Group Containers/*workpuls*` |
| Launch Agents | `~/Library/LaunchAgents/com.workpuls.*` |
| System Launch Agents | `/Library/LaunchAgents/com.workpuls.*` |
| System Launch Daemons | `/Library/LaunchDaemons/com.workpuls.*` |
| Privileged Helpers | `/Library/PrivilegedHelperTools/com.workpuls.*` |
| Saved App State | `~/Library/Saved Application State/` |
| WebKit storage | `~/Library/WebKit/` |
| Cookies | `~/Library/Cookies/` |

---

## Works even if you already deleted the app

If you dragged the `.app` to Trash manually, `purgeapp` skips the bundle and continues cleaning up all the leftover files.

---

## Notes

- By default, `purgeapp` scans all matching candidates first, shows the list to the user, and prompts for confirmation before deleting anything.
- Some files under `/Library/PrivilegedHelperTools` are SIP-protected and cannot be removed by any tool without disabling System Integrity Protection. `purgeapp` will clearly report these.
- `purgeapp` tries removal without `sudo` first, then retries with `sudo` for system paths automatically.

---

## Contributing Custom App Paths

If a specific macOS application saves leftover files to custom directories outside of standard user/system library paths, you can contribute to the built-in paths registry inside the [purgeapp](purgeapp) script:

1. Open `purgeapp` and locate the `APP_CUSTOM_PATHS` associative array.
2. Add your application name in lowercase along with the paths (separated by spaces if multiple):
   ```zsh
   APP_CUSTOM_PATHS+=(
     [myapp]="$HOME/.myapp /usr/local/var/myapp"
   )
   ```
3. Submit a Pull Request to this repository!

---

## Upgrade

```bash
brew update && brew upgrade purgeapp
```

---

## Uninstall purgeapp itself

```bash
brew uninstall purgeapp
brew untap SiavoshZarrasvand/purgeapp
```

---

## License

MIT © [Siavosh Zarrasvand](https://github.com/SiavoshZarrasvand)