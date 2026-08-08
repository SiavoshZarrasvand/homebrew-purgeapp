# purgeapp/plugins/appleconnect.zsh
# AppleConnect dedicated plugin implementation

plugin_appleconnect_info() {
  echo "appleconnect|AppleConnect corporate application and developer tooling|AppleConnect"
}

plugin_appleconnect_discover() {
  local target="$1"
  local -a inventory=()

  # Helper to record discovered artifact
  add_item() {
    local ipath="$1"
    local itype="$2"
    local iclass="$3"
    local ireason="$4"
    local istrat="$5"

    [[ -z "$ipath" ]] && return
    inventory+=("${ipath}|${itype}|${iclass}|${ireason}|${istrat}")
  }

  # 1. Running Processes
  local -a target_processes=(
    "AppleConnectAgent"
    "com.apple.ist.ds.appleconnect.menu"
    "com.apple.ist.ds.appleconnect"
    "AppleConnect"
  )
  local proc
  for proc in "${target_processes[@]}"; do
    if pgrep -x "$proc" >/dev/null 2>&1 || pgrep -f "$proc" >/dev/null 2>&1; then
      add_item "$proc" "process" "SAFE" "Running AppleConnect process" "kill_process"
    fi
  done

  # 2. LaunchAgents
  local f
  for f in "$HOME/Library/LaunchAgents/com.apple.ist.ds.appleconnect"*(N) \
           "/Library/LaunchAgents/com.apple.ist.ds.appleconnect"*(N); do
    if [[ -e "$f" ]]; then
      add_item "$f" "launch_agent" "SAFE" "AppleConnect LaunchAgent plist" "unload_launch_agent"
    fi
  done

  # 3. LaunchDaemons
  for f in "/Library/LaunchDaemons/com.apple.ist.ds.appleconnect"*(N); do
    if [[ -e "$f" ]]; then
      add_item "$f" "launch_daemon" "SAFE" "AppleConnect LaunchDaemon plist" "unload_launch_daemon"
    fi
  done

  # 4. Privileged Helper Tools
  for f in "/Library/PrivilegedHelperTools/com.apple.ist.ds.appleconnect"*(N); do
    if [[ -e "$f" ]]; then
      add_item "$f" "privileged_helper" "SAFE" "AppleConnect Privileged Helper Tool" "rm_file"
    fi
  done

  # 5. Application Support
  local app_supp
  for app_supp in "/Library/Application Support/AppleConnect" \
                   "$HOME/Library/Application Support/AppleConnect" \
                   "$HOME/Library/Application Support/com.apple.ist.ds.appleconnect"*(N); do
    if [[ -e "$app_supp" ]]; then
      add_item "$app_supp" "directory" "SAFE" "AppleConnect Application Support" "rm_dir"
    fi
  done

  # 6. Frameworks
  local fw
  for fw in "/Library/Frameworks/AppleConnect.framework" \
            "/Library/Frameworks/AppleConnectClient.framework" \
            "/Library/Frameworks/AppleConnectDefaults.framework" \
            "/Library/Frameworks/AppleConnectPrivate.framework" \
            "/Library/Frameworks/AppleConnectServices.framework" \
            "/Library/Frameworks/AppleConnect"*.framework(N); do
    if [[ -e "$fw" ]]; then
      add_item "$fw" "framework" "SAFE" "AppleConnect Framework bundle" "rm_dir"
    fi
  done

  # 7. Kerberos Plugins
  local kplugin
  for kplugin in "/Library/KerberosPlugins/KerberosFrameworkPlugins/AppleConnectLocate.bundle" \
                 "/Library/KerberosPlugins/GSSAPI/AppleConnectGSSCredentialSelector.bundle"; do
    if [[ -e "$kplugin" ]]; then
      add_item "$kplugin" "directory" "SAFE" "AppleConnect Kerberos Plugin bundle" "rm_dir"
    fi
  done

  # 8. User-level State & Preferences
  local user_item
  for user_item in "$HOME/Library/Application Scripts/com.apple.ist.ds.appleconnect"*(N) \
                   "$HOME/Library/Containers/com.apple.ist.ds.appleconnect"*(N) \
                   "$HOME/Library/Group Containers/"*"appleconnect"*(N) \
                   "$HOME/Library/Preferences/com.apple.ist.ds.appleconnect"*(N) \
                   "$HOME/Library/HTTPStorages/com.apple.ist.ds.appleconnect"*(N) \
                   "$HOME/Library/Caches/com.apple.ist.ds.appleconnect"*(N) \
                   "$HOME/Library/Saved Application State/com.apple.ist.ds.appleconnect"*.savedState(N); do
    if [[ -e "$user_item" ]]; then
      local itype="directory"
      [[ -f "$user_item" ]] && itype="file"
      add_item "$user_item" "$itype" "SAFE" "AppleConnect user preferences/container" "rm_dir"
    fi
  done

  # 9. Package-manager Artifacts (Python awsappleconnect via uv/pipx/pip)
  if pkg_manager_detect "uv"; then
    local uv_tool_env="$HOME/.local/share/uv/tools/awsappleconnect"
    if [[ -d "$uv_tool_env" ]]; then
      add_item "$uv_tool_env" "package_manager_artifact" "PACKAGE" "Installed uv tool awsappleconnect" "uninstall_package:uv_tool"
    fi
  fi

  if pkg_manager_detect "pipx"; then
    local pipx_env="$HOME/.local/pipx/venvs/awsappleconnect"
    if [[ -d "$pipx_env" ]]; then
      add_item "$pipx_env" "package_manager_artifact" "PACKAGE" "Installed pipx environment awsappleconnect" "uninstall_package:pipx_env"
    fi
  fi

  # 10. Package Caches
  local cache_item
  if [[ -d "$HOME/.cache/uv" ]]; then
    for cache_item in "$HOME/.cache/uv"/*"appleconnect"*(N) \
                      "$HOME/.cache/uv"/*/*"appleconnect"*(N); do
      if [[ -e "$cache_item" ]]; then
        add_item "$cache_item" "cache" "CACHE" "Disposable uv package cache" "clean_cache:uv_cache"
      fi
    done
  fi

  # 11. Package Receipts (SIP protected system receipts)
  local receipt
  for receipt in "/Library/Apple/System/Library/Receipts/com.apple.pkg.AppleConnect."*(N) \
                 "/var/db/receipts/com.apple.pkg.AppleConnect."*(N); do
    if [[ -e "$receipt" ]]; then
      add_item "$receipt" "package" "PROTECTED" "System AppleConnect Package Receipt (SIP Protected)" "none"
    fi
  done

  # 12. User code repos check (checking top-level folders under user code roots)
  local repo_match
  for repo_match in "$HOME/Documents/Github"/*"appleconnect"*(N) \
                     "$HOME/Documents/GitHub"/*"appleconnect"*(N) \
                     "$HOME/Projects"/*"appleconnect"*(N) \
                     "$HOME/Developer"/*"appleconnect"*(N); do
    if [[ -e "$repo_match" ]]; then
      add_item "$repo_match" "directory" "USER_CODE" "User source repository containing AppleConnect code" "none"
    fi
  done

  print -l "${inventory[@]}"
}

plugin_appleconnect_classify() {
  local item_path="$1"
  local type="$2"
  local current_class="$3"

  if is_user_code "$item_path"; then
    echo "USER_CODE"
    return
  fi

  if is_protected_system "$item_path"; then
    echo "PROTECTED"
    return
  fi

  echo "$current_class"
}

plugin_appleconnect_remove() {
  local item_path="$1"
  local type="$2"
  local strat="$3"
  local dry_run="${4:-no}"

  default_remove_strategy "$item_path" "$type" "$strat" "$dry_run"
}

plugin_appleconnect_verify() {
  local target="$1"
  local rediscovered
  rediscovered=$(plugin_appleconnect_discover "$target")

  local remaining_safe=0
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local item_path="" type="" class="" reason="" strat=""
    IFS='|' read -r item_path type class reason strat <<< "$line"
    if [[ "$class" == "SAFE" || "$class" == "CACHE" || "$class" == "PACKAGE" ]]; then
      (( remaining_safe++ ))
    fi
  done <<< "$rediscovered"

  if [[ $remaining_safe -eq 0 ]]; then
    echo "REMOVED"
  else
    echo "STILL_PRESENT"
  fi
}
