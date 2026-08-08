# purgeapp/lib/package_manager.zsh
# Generic package manager abstraction for uv, pip, pipx, etc.

# Detect if a package manager CLI tool is available
pkg_manager_detect() {
  local pm="$1"
  if whence -p "$pm" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Find installed packages matching target across available package managers
pkg_manager_find() {
  local target_pkg="$1"
  local -a found_items=()

  # 1. uv tool / pip detection
  if pkg_manager_detect "uv"; then
    # Check uv cache directories for target_pkg
    local uv_cache_dir="$HOME/.cache/uv"
    if [[ -d "$uv_cache_dir" ]]; then
      local match
      for match in "$uv_cache_dir"/**/*"${target_pkg}"*(N); do
        found_items+=("uv_cache:$match")
      done
    fi

    # Check uv tool environments
    local uv_tool_dir="$HOME/.local/share/uv/tools/${target_pkg}"
    if [[ -d "$uv_tool_dir" ]]; then
      found_items+=("uv_tool:$uv_tool_dir")
    fi
  fi

  # 2. pipx detection
  if pkg_manager_detect "pipx"; then
    local pipx_app_dir="$HOME/.local/pipx/venvs/${target_pkg}"
    if [[ -d "$pipx_app_dir" ]]; then
      found_items+=("pipx_env:$pipx_app_dir")
    fi
  fi

  # Output found entries space-separated or array
  print -l "${found_items[@]}"
}

# Uninstall a package manager package or clean package manager cache
pkg_manager_remove() {
  local pm_type="$1"
  local target_path="$2"
  local dry_run="${3:-no}"

  case "$pm_type" in
    uv_tool)
      if [[ "$dry_run" == "yes" ]]; then
        return 0
      fi
      if pkg_manager_detect "uv"; then
        local pkg_name="${target_path:t}"
        uv tool uninstall "$pkg_name" >/dev/null 2>&1
      fi
      if [[ -d "$target_path" ]]; then
        /bin/rm -rf -- "$target_path" 2>/dev/null
      fi
      ;;
    uv_cache)
      if [[ "$dry_run" == "yes" ]]; then
        return 0
      fi
      if [[ -e "$target_path" ]]; then
        /bin/rm -rf -- "$target_path" 2>/dev/null
      fi
      ;;
    pipx_env)
      if [[ "$dry_run" == "yes" ]]; then
        return 0
      fi
      if pkg_manager_detect "pipx"; then
        local pkg_name="${target_path:t}"
        pipx uninstall "$pkg_name" >/dev/null 2>&1
      fi
      if [[ -d "$target_path" ]]; then
        /bin/rm -rf -- "$target_path" 2>/dev/null
      fi
      ;;
    *)
      if [[ "$dry_run" != "yes" && -e "$target_path" ]]; then
        /bin/rm -rf -- "$target_path" 2>/dev/null
      fi
      ;;
  esac

  if [[ ! -e "$target_path" ]]; then
    return 0
  else
    return 1
  fi
}
