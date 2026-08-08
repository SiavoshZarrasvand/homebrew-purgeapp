# purgeapp/lib/artifact.zsh
# Artifact management, classification, and safety checks

# Critical system paths that must never be deleted under any circumstances
typeset -ga CRITICAL_PATHS
CRITICAL_PATHS=(
  "/"
  "/Applications"
  "/Library"
  "/System"
  "/Users"
  "/Volumes"
  "/bin"
  "/sbin"
  "/usr"
  "/var"
  "/etc"
  "/private"
  "/private/etc"
  "/private/var"
  "/tmp"
  "/private/tmp"
  "$HOME"
  "$HOME/Applications"
  "$HOME/Library"
  "$HOME/Desktop"
  "$HOME/Documents"
  "$HOME/Downloads"
  "$HOME/Movies"
  "$HOME/Music"
  "$HOME/Pictures"
)

# User code root paths where user source repositories live
typeset -ga USER_CODE_ROOTS
USER_CODE_ROOTS=(
  "$HOME/Documents/Github"
  "$HOME/Documents/GitHub"
  "$HOME/Projects"
  "$HOME/Developer"
  "$HOME/src"
  "$HOME/code"
  "$HOME/workspace"
)

# Check if a path is a critical system path
is_critical_path() {
  local target_path="${1:A}"
  target_path="${target_path%/}"

  if [[ -z "$target_path" || "$target_path" == "/" ]]; then
    return 0
  fi

  local cp
  for cp in "${CRITICAL_PATHS[@]}"; do
    local resolved_cp="${cp:A}"
    resolved_cp="${resolved_cp%/}"
    if [[ "$target_path" == "$resolved_cp" ]]; then
      return 0
    fi
  done

  return 1
}

# Check if a path is located within a user code directory / source code repository
is_user_code() {
  local target_path="${1:A}"
  target_path="${target_path%/}"

  local uroot
  for uroot in "${USER_CODE_ROOTS[@]}"; do
    local resolved_uroot="${uroot:A}"
    resolved_uroot="${resolved_uroot%/}"
    if [[ -n "$resolved_uroot" && ( "$target_path" == "$resolved_uroot" || "$target_path" == "$resolved_uroot"/* ) ]]; then
      return 0
    fi
  done

  # If path is strictly inside HOME (excluding Library, .cache, etc.) and contains a .git folder in its hierarchy
  if [[ "$target_path" == "$HOME/"* && "$target_path" != "$HOME/Library"* && "$target_path" != "$HOME/.cache"* ]]; then
    local parent_dir="$target_path"
    while [[ -n "$parent_dir" && "$parent_dir" != "/" && "$parent_dir" != "$HOME" ]]; do
      if [[ -d "${parent_dir}/.git" ]]; then
        return 0
      fi
      parent_dir="${parent_dir:h}"
    done
  fi

  return 1
}

# Check if path is a SIP / system protected receipt or system path
is_protected_system() {
  local target_path="${1:A}"
  
  if [[ "$target_path" == "/Library/Apple/System/Library/Receipts"* || \
        "$target_path" == "/System/"* || \
        "$target_path" == "/usr/bin/"* || \
        "$target_path" == "/usr/sbin/"* || \
        "$target_path" == "/var/db/receipts/com.apple.pkg."* ]]; then
    return 0
  fi
  return 1
}

# Format artifact type for display
format_artifact_type() {
  local atype="$1"
  case "$atype" in
    process)                  echo "Process" ;;
    launch_agent)             echo "LaunchAgent" ;;
    launch_daemon)            echo "LaunchDaemon" ;;
    privileged_helper)        echo "PrivilegedHelper" ;;
    framework)                echo "Framework" ;;
    application)              echo "Application" ;;
    package)                  echo "Package" ;;
    package_manager_artifact) echo "PackageManager" ;;
    cache)                    echo "Cache" ;;
    directory)                echo "Directory" ;;
    file)                     echo "File" ;;
    symlink)                  echo "Symlink" ;;
    shell_config)             echo "ShellConfig" ;;
    *)                        echo "$atype" ;;
  esac
}
