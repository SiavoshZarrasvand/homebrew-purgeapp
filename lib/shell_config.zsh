# purgeapp/lib/shell_config.zsh
# Safe line-based shell configuration file cleanup

typeset -ga SHELL_CONFIG_FILES
SHELL_CONFIG_FILES=(
  "$HOME/.zprofile"
  "$HOME/.zshrc"
  "$HOME/.bash_profile"
  "$HOME/.bashrc"
  "$HOME/.config/fish/config.fish"
  "$HOME/.profile"
)

# Find matching shell configuration lines
# Usage: shell_config_find "pattern"
shell_config_find() {
  local pattern="$1"
  local -a found_configs=()

  local cfg
  for cfg in "${SHELL_CONFIG_FILES[@]}"; do
    if [[ -f "$cfg" ]]; then
      if grep -E -q "$pattern" "$cfg" 2>/dev/null; then
        found_configs+=("$cfg")
      fi
    fi
  done

  print -l "${found_configs[@]}"
}

# Safely remove lines matching pattern from a shell config file without overwriting unrelated content
# Usage: shell_config_remove_line "file_path" "pattern" "dry_run"
shell_config_remove_line() {
  local cfg_file="$1"
  local pattern="$2"
  local dry_run="${3:-no}"

  if [[ ! -f "$cfg_file" ]]; then
    return 1
  fi

  if [[ "$dry_run" == "yes" ]]; then
    return 0
  fi

  local tmp_file="${cfg_file}.tmp.$$"
  grep -E -v "$pattern" "$cfg_file" > "$tmp_file" 2>/dev/null
  
  if [[ -s "$tmp_file" || ! -s "$cfg_file" ]]; then
    mv "$tmp_file" "$cfg_file"
    return 0
  else
    # If the file became 0 bytes because every line matched, keep an empty file or clean up
    mv "$tmp_file" "$cfg_file"
    return 0
  fi
}
