# purgeapp/plugins/homebrew.zsh
# Homebrew dedicated plugin implementation

plugin_homebrew_info() {
  echo "homebrew|Homebrew package manager and ecosystem|Homebrew"
}

plugin_homebrew_discover() {
  local target="$1"
  local -a inventory=()

  add_item() {
    local ipath="$1"
    local itype="$2"
    local iclass="$3"
    local ireason="$4"
    local istrat="$5"

    [[ -z "$ipath" ]] && return
    inventory+=("${ipath}|${itype}|${iclass}|${ireason}|${istrat}")
  }

  # Helper to check if a Homebrew root is an Apple-internal fork/tap installation
  is_apple_internal_brew() {
    local broot="$1"
    if [[ -d "${broot}/Library/Taps/apple" || \
          -d "${broot}/Library/Taps/apple-internal" || \
          -d "${broot}/Library/Taps/apple-core" ]]; then
      return 0
    fi
    return 1
  }

  # 1. Main Homebrew Installation Directories
  local -a brew_install_roots=(
    "/opt/homebrew"
    "/usr/local/Homebrew"
    "~/.brew"
    "/home/linuxbrew/.linuxbrew"
  )

  local has_apple_internal="no"
  local broot
  for broot in "${brew_install_roots[@]}"; do
    eval "resolved_broot=\"$broot\""
    if [[ -d "$resolved_broot" ]]; then
      if is_apple_internal_brew "$resolved_broot"; then
        has_apple_internal="yes"
        add_item "$resolved_broot" "directory" "SAFE" "Apple-internal Homebrew installation root (Removable fork)" "rm_dir"
      else
        # Official upstream Homebrew root is classified as PROTECTED from wholesale deletion
        add_item "$resolved_broot" "directory" "PROTECTED" "Official upstream Homebrew installation root (Protected)" "none"
      fi
    fi
  done

  # 2. Intel Homebrew Standalone Directories in /usr/local if not full /usr/local
  local cellar_class="PROTECTED"
  local cellar_strat="none"
  if [[ "$has_apple_internal" == "yes" ]]; then
    cellar_class="SAFE"
    cellar_strat="rm_dir"
  fi

  if [[ -d "/usr/local/Cellar" ]]; then
    add_item "/usr/local/Cellar" "directory" "$cellar_class" "Homebrew Intel Cellar" "$cellar_strat"
  fi
  if [[ -d "/usr/local/Caskroom" ]]; then
    add_item "/usr/local/Caskroom" "directory" "$cellar_class" "Homebrew Intel Caskroom" "$cellar_strat"
  fi
  if [[ -L "/usr/local/bin/brew" || -f "/usr/local/bin/brew" ]]; then
    if [[ "$has_apple_internal" == "yes" ]]; then
      add_item "/usr/local/bin/brew" "symlink" "SAFE" "Apple-internal Homebrew executable symlink" "rm_file"
    else
      add_item "/usr/local/bin/brew" "symlink" "PROTECTED" "Official Homebrew executable symlink" "none"
    fi
  fi

  # 3. Caches & Logs & Configs (Disposable caches remain disposable)
  local -a brew_caches=(
    "$HOME/.cache/Homebrew"
    "$HOME/Library/Caches/Homebrew"
    "$HOME/Library/Logs/Homebrew"
    "$HOME/.homebrew"
    "/var/tmp/homebrew"
    "/tmp/homebrew"
    "/private/tmp/homebrew"
    "/private/var/tmp/homebrew"
  )

  local bcache
  for bcache in "${brew_caches[@]}"; do
    if [[ -e "$bcache" ]]; then
      add_item "$bcache" "cache" "CACHE" "Homebrew disposable cache/logs" "clean_cache"
    fi
  done

  # 4. Shell Integration
  # Only remove shell integration when the Homebrew install it points at is
  # actually being removed (Apple-internal). Leaving an official install in
  # place but stripping its shellenv line would break the user's PATH for
  # software we just classified as PROTECTED.
  local -a matching_configs
  matching_configs=($(shell_config_find "brew shellenv"))

  local cfg
  for cfg in "${matching_configs[@]}"; do
    if [[ "$has_apple_internal" == "yes" ]]; then
      add_item "$cfg" "shell_config" "SAFE" "Homebrew shell environment initialization line" "clean_shell_config:brew shellenv"
    else
      add_item "$cfg" "shell_config" "PROTECTED" "Shell integration for official Homebrew install (left in place)" "none"
    fi
  done

  print -l "${inventory[@]}"
}

plugin_homebrew_classify() {
  local item_path="$1"
  local type="$2"
  local current_class="$3"

  if is_critical_path "$item_path"; then
    echo "PROTECTED"
    return
  fi

  echo "$current_class"
}

plugin_homebrew_remove() {
  local item_path="$1"
  local type="$2"
  local strat="$3"
  local dry_run="${4:-no}"

  default_remove_strategy "$item_path" "$type" "$strat" "$dry_run"
}

plugin_homebrew_verify() {
  local target="$1"
  local rediscovered
  rediscovered=$(plugin_homebrew_discover "$target")

  local remaining=0
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local item_path="" type="" class="" reason="" strat=""
    IFS='|' read -r item_path type class reason strat <<< "$line"
    if [[ "$class" == "SAFE" || "$class" == "CACHE" ]]; then
      (( remaining++ ))
    fi
  done <<< "$rediscovered"

  if [[ $remaining -eq 0 ]]; then
    echo "REMOVED"
  else
    echo "STILL_PRESENT"
  fi
}
