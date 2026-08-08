# purgeapp/lib/core.zsh
# Core engine for plugin loading, execution, inventory rendering, confirmation, removal, and verification

VERSION="4.0.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

typeset -A REGISTERED_PLUGINS

# Discover and source all available plugin files in plugins directory
load_plugins() {
  local plugins_dir="$1"
  if [[ ! -d "$plugins_dir" ]]; then
    return
  fi

  local plugin_file
  for plugin_file in "$plugins_dir"/*.zsh(N); do
    if [[ -f "$plugin_file" ]]; then
      source "$plugin_file"
      local plugin_basename="${plugin_file:t:r}"
      REGISTERED_PLUGINS[$plugin_basename]="$plugin_file"
    fi
  done
}

# Print list of available plugins
list_plugins() {
  echo "${BOLD}purgeapp${RESET} v${VERSION} — available plugins:"
  echo ""
  local p
  for p in ${(k)REGISTERED_PLUGINS}; do
    if [[ "$p" != "generic_app" ]]; then
      echo "  ${BOLD}${p}${RESET}"
    fi
  done
  echo ""
}

# Main entrypoint for execution
run_purgeapp() {
  local target_raw=""
  local dry_run="no"
  local auto_yes="no"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_usage
        exit 0
        ;;
      -v|--version)
        echo "purgeapp v${VERSION}"
        exit 0
        ;;
      -d|--dry-run)
        dry_run="yes"
        shift
        ;;
      -y|--yes)
        auto_yes="yes"
        shift
        ;;
      list)
        list_plugins
        exit 0
        ;;
      *)
        if [[ -z "$target_raw" ]]; then
          target_raw="$1"
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$target_raw" ]]; then
    echo "${RED}Error:${RESET} No target app or plugin provided."
    show_usage
    exit 1
  fi

  local target_name="${target_raw%.app}"
  local target_lower="${target_name:l}"
  local selected_plugin=""

  # Select plugin if registered, otherwise fallback to generic_app plugin
  if [[ -n "${REGISTERED_PLUGINS[$target_lower]}" ]]; then
    selected_plugin="$target_lower"
  else
    selected_plugin="generic_app"
  fi

  echo ""
  echo "${BOLD}${BLUE}purgeapp${RESET} v${VERSION} — purging ${BOLD}${target_name}${RESET} (plugin: ${selected_plugin})"
  if [[ "$dry_run" == "yes" ]]; then
    echo "${YELLOW}  Dry-run mode (no files will be deleted)${RESET}"
  fi
  echo ""

  # Phase 1: Discovery
  local discover_func="plugin_${selected_plugin}_discover"
  local classify_func="plugin_${selected_plugin}_classify"
  local remove_func="plugin_${selected_plugin}_remove"
  local verify_func="plugin_${selected_plugin}_verify"

  if ! typeset -f "$discover_func" >/dev/null; then
    echo "${RED}Error:${RESET} Plugin ${selected_plugin} does not implement discover()."
    exit 1
  fi

  # Artifact arrays for classification inventory
  local -a artifacts_safe=()
  local -a artifacts_cache=()
  local -a artifacts_package=()
  local -a artifacts_unknown=()
  local -a artifacts_protected=()
  local -a artifacts_user_code=()

  # Execute plugin discovery (returns formatted artifact strings: "item_path|type|classification|reason|strategy")
  local raw_inventory
  raw_inventory=$($discover_func "$target_name")

  if [[ -z "$raw_inventory" ]]; then
    echo "No leftover files, processes, or configurations found for ${target_name}."
    echo ""
    exit 0
  fi

  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    
    local item_path="" type="" class="" reason="" strat=""
    IFS='|' read -r item_path type class reason strat <<< "$line"

    # Execute plugin classify hook if available to re-evaluate/refine classification
    if typeset -f "$classify_func" >/dev/null; then
      class=$($classify_func "$item_path" "$type" "$class")
    fi

    # Enforce global safety checks (Critical Paths & User Code Protection)
    if is_critical_path "$item_path"; then
      artifacts_protected+=("$line")
      continue
    fi

    if is_user_code "$item_path"; then
      artifacts_user_code+=("$line")
      continue
    fi

    if is_protected_system "$item_path"; then
      artifacts_protected+=("$line")
      continue
    fi

    case "$class" in
      SAFE)       artifacts_safe+=("$line") ;;
      CACHE)      artifacts_cache+=("$line") ;;
      PACKAGE)    artifacts_package+=("$line") ;;
      UNKNOWN)    artifacts_unknown+=("$line") ;;
      PROTECTED)  artifacts_protected+=("$line") ;;
      USER_CODE)  artifacts_user_code+=("$line") ;;
      *)          artifacts_safe+=("$line") ;;
    esac
  done <<< "$raw_inventory"

  # Phase 2: Render Structured Inventory
  render_inventory "Safe to Remove" "${artifacts_safe[@]}"
  render_inventory "Disposable Caches" "${artifacts_cache[@]}"
  render_inventory "Package Manager Artifacts" "${artifacts_package[@]}"
  render_inventory "Protected / System Artifacts (Will NOT be deleted)" "${artifacts_protected[@]}"
  render_inventory "User Code & Repositories (Ignored)" "${artifacts_user_code[@]}"
  render_inventory "Unknown / Unverified Matches (Reported only)" "${artifacts_unknown[@]}"

  local total_removable=$(( ${#artifacts_safe[@]} + ${#artifacts_cache[@]} + ${#artifacts_package[@]} ))

  if [[ $total_removable -eq 0 ]]; then
    echo "${YELLOW}No removable artifacts identified.${RESET}"
    echo ""
    exit 0
  fi

  if [[ "$dry_run" == "yes" ]]; then
    echo "${YELLOW}Dry-run completed. No actions were performed.${RESET}"
    echo ""
    exit 0
  fi

  # Phase 3: Interactive Confirmation
  if [[ "$auto_yes" != "yes" ]]; then
    echo -n "Are you sure you want to permanently delete these ${total_removable} artifacts? (y/N): "
    read -r response
    if [[ "$response" != "y" && "$response" != "Y" ]]; then
      echo "Aborted."
      echo ""
      exit 0
    fi
    echo ""
  fi

  # Phase 4: Removal Execution
  echo "${BOLD}Executing removal strategies...${RESET}"
  local removed_count=0
  local failed_count=0
  local -a failed_items=()

  local -a items_to_remove=(${artifacts_safe[@]} ${artifacts_cache[@]} ${artifacts_package[@]})

  local item
  for item in "${items_to_remove[@]}"; do
    local item_path="" type="" class="" reason="" strat=""
    IFS='|' read -r item_path type class reason strat <<< "$item"

    local result=1
    if typeset -f "$remove_func" >/dev/null; then
      result=$($remove_func "$item_path" "$type" "$strat" "$dry_run")
    else
      result=$(default_remove_strategy "$item_path" "$type" "$strat" "$dry_run")
    fi

    if [[ $result -eq 0 ]]; then
      echo "  ${GREEN}✓${RESET} Removed [$(format_artifact_type "$type")]: $item_path"
      (( removed_count++ ))
    else
      echo "  ${RED}✗${RESET} Failed [$(format_artifact_type "$type")]: $item_path"
      failed_items+=("$item_path")
      (( failed_count++ ))
    fi
  done
  echo ""

  # Phase 5: Verification & Post-Purge Check
  echo "${BOLD}Verifying removal...${RESET}"
  local v_status="REMOVED"
  if typeset -f "$verify_func" >/dev/null; then
    v_status=$($verify_func "$target_name")
  else
    if [[ $failed_count -gt 0 ]]; then
      v_status="STILL_PRESENT"
    else
      v_status="REMOVED"
    fi
  fi

  # Phase 6: Final Report
  echo "────────────────────────────────────────"
  if [[ $failed_count -eq 0 && ${#artifacts_protected[@]} -eq 0 ]]; then
    echo "${GREEN}${BOLD}✅ Purge completed successfully!${RESET} Total removed: ${removed_count}"
  elif [[ $failed_count -eq 0 && ${#artifacts_protected[@]} -gt 0 ]]; then
    echo "${GREEN}${BOLD}✅ Purge completed with protected items skipped.${RESET} Total removed: ${removed_count}  Protected: ${#artifacts_protected[@]}"
    echo "Protected system artifacts remain untouched as expected."
  else
    echo "${YELLOW}${BOLD}⚠  Purge completed with issues.${RESET} Removed: ${removed_count}  Failed: ${failed_count}"
    echo ""
    echo "${YELLOW}Failed items:${RESET}"
    for f in "${failed_items[@]}"; do
      echo "  $f"
    done
  fi
  echo ""
}

# Default removal strategy execution
default_remove_strategy() {
  local item_path="$1"
  local type="$2"
  local strat="$3"
  local dry_run="${4:-no}"

  if [[ "$dry_run" == "yes" ]]; then
    return 0
  fi

  local strat_cmd="${strat%%:*}"
  local strat_arg=""
  if [[ "$strat" == *":"* ]]; then
    strat_arg="${strat#*:}"
  fi

  case "$strat_cmd" in
    kill_process)
      if pgrep -x "$item_path" >/dev/null 2>&1 || pgrep -f "$item_path" >/dev/null 2>&1; then
        pkill -x "$item_path" 2>/dev/null || pkill -f "$item_path" 2>/dev/null
        sleep 0.5
        if pgrep -x "$item_path" >/dev/null 2>&1 || pgrep -f "$item_path" >/dev/null 2>&1; then
          sudo pkill -9 -f "$item_path" 2>/dev/null
        fi
      fi
      if ! pgrep -f "$item_path" >/dev/null 2>&1; then return 0; else return 1; fi
      ;;
    unload_launch_agent)
      launchctl bootout "gui/$UID" "$item_path" 2>/dev/null || launchctl unload "$item_path" 2>/dev/null
      /bin/rm -f -- "$item_path" 2>/dev/null || sudo /bin/rm -f -- "$item_path" 2>/dev/null
      if [[ ! -e "$item_path" ]]; then return 0; else return 1; fi
      ;;
    unload_launch_daemon)
      sudo launchctl bootout system "$item_path" 2>/dev/null || sudo launchctl unload "$item_path" 2>/dev/null
      sudo /bin/rm -f -- "$item_path" 2>/dev/null
      if [[ ! -e "$item_path" ]]; then return 0; else return 1; fi
      ;;
    uninstall_package|clean_cache)
      local pm_type="${strat_arg:-$type}"
      pkg_manager_remove "$pm_type" "$item_path" "$dry_run"
      return $?
      ;;
    clean_shell_config)
      local pattern="${strat_arg:-$type}"
      shell_config_remove_line "$item_path" "$pattern" "$dry_run"
      return $?
      ;;
    rm_dir|rm_file|*)
      if [[ ! -e "$item_path" && ! -L "$item_path" ]]; then
        return 0
      fi
      /bin/rm -rf -- "$item_path" 2>/dev/null
      if [[ -e "$item_path" || -L "$item_path" ]]; then
        sudo /bin/rm -rf -- "$item_path" 2>/dev/null
      fi
      if [[ ! -e "$item_path" && ! -L "$item_path" ]]; then return 0; else return 1; fi
      ;;
  esac
}

# Helper to render formatted inventory section
render_inventory() {
  local title="$1"
  shift
  local -a items=("$@")

  [[ ${#items[@]} -eq 0 ]] && return

  echo "${BOLD}${title}:${RESET}"
  local item
  for item in "${items[@]}"; do
    local item_path="" type="" class="" reason="" strat=""
    IFS='|' read -r item_path type class reason strat <<< "$item"
    local tfmt=$(format_artifact_type "$type")
    echo "  • [${tfmt}] ${item_path} ${YELLOW}(${reason})${RESET}"
  done
  echo ""
}

show_usage() {
  echo ""
  echo "${BOLD}purgeapp${RESET} v${VERSION} — plugin-based discovery & uninstall system"
  echo ""
  echo "${BOLD}Usage:${RESET}"
  echo "  purgeapp [options] <target>"
  echo "  purgeapp list"
  echo "  purgeapp appleconnect"
  echo "  purgeapp homebrew"
  echo "  purgeapp Workpuls"
  echo ""
  echo "${BOLD}Options:${RESET}"
  echo "  -d, --dry-run    Show discovery inventory without removing anything"
  echo "  -y, --yes        Auto-confirm deletion prompts"
  echo "  -v, --version    Print version"
  echo "  -h, --help       Show this help message"
  echo ""
}
