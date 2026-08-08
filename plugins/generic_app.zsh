# purgeapp/plugins/generic_app.zsh
# Generic application discovery plugin (fallback for standard macOS .app bundles and leftovers)

plugin_generic_app_info() {
  echo "generic_app|Generic macOS application discovery plugin|Generic"
}

plugin_generic_app_discover() {
  local app_raw="$1"
  local app_name="${app_raw%.app}"
  local app_lower="${app_name:l}"
  local -a inventory=()

  add_item() {
    local ipath="$1"
    local itype="$2"
    local iclass="$3"
    local ireason="$4"
    local istrat="$5"

    [[ -z "$ipath" ]] && return
    
    # Safety classification checks
    if is_critical_path "$ipath"; then
      inventory+=("${ipath}|${itype}|PROTECTED|Critical system path|none")
      return
    fi

    if is_user_code "$ipath"; then
      inventory+=("${ipath}|${itype}|USER_CODE|User code repository|none")
      return
    fi

    if is_protected_system "$ipath"; then
      inventory+=("${ipath}|${itype}|PROTECTED|Protected system location|none")
      return
    fi

    inventory+=("${ipath}|${itype}|${iclass}|${ireason}|${istrat}")
  }

  # 1. App bundle
  local app_bundle=""
  local bundle_id=""

  if [[ -d "/Applications/${app_name}.app" ]]; then
    app_bundle="/Applications/${app_name}.app"
  elif [[ -d "$HOME/Applications/${app_name}.app" ]]; then
    app_bundle="$HOME/Applications/${app_name}.app"
  fi

  if [[ -n "$app_bundle" ]]; then
    add_item "$app_bundle" "application" "SAFE" "Application bundle" "rm_dir"
    bundle_id=$(defaults read "${app_bundle}/Contents/Info" CFBundleIdentifier 2>/dev/null)
    bundle_id="${bundle_id## }"
    bundle_id="${bundle_id%% }"
  fi

  # 2. Executable in PATH
  local cli_path
  cli_path=$(whence -p "$app_name" 2>/dev/null)
  [[ -z "$cli_path" ]] && cli_path=$(whence -p "$app_lower" 2>/dev/null)

  if [[ -n "$cli_path" ]]; then
    add_item "$cli_path" "symlink" "SAFE" "CLI executable" "rm_file"
    if [[ -L "$cli_path" ]]; then
      local target_resolved="${cli_path:A}"
      if [[ -e "$target_resolved" ]]; then
        add_item "$target_resolved" "file" "SAFE" "Resolved CLI binary target" "rm_file"
      fi
    fi
  fi

  # 3. Standard User Library locations
  local -a user_dirs=(
    "$HOME/Library/Application Support/$app_name"
    "$HOME/Library/Application Support/$app_lower"
    "$HOME/Library/Caches/$app_name"
    "$HOME/Library/Caches/$app_lower"
    "$HOME/Library/Logs/$app_name"
    "$HOME/Library/Logs/$app_lower"
    "$HOME/Library/Saved Application State/${app_lower}.savedState"
    "$HOME/Library/WebKit/$app_lower"
    "$HOME/Library/Cookies/${app_lower}.binarycookies"
    "$HOME/Library/HTTPStorages/$app_lower"
  )

  local udir
  for udir in "${user_dirs[@]}"; do
    if [[ -e "$udir" ]]; then
      local itype="directory"
      [[ -f "$udir" ]] && itype="file"
      local iclass="SAFE"
      [[ "$udir" == *"/Caches/"* ]] && iclass="CACHE"
      add_item "$udir" "$itype" "$iclass" "User Library leftover" "rm_dir"
    fi
  done

  # 4. Scoped User Library locations (Anchored vs Unanchored Group Containers)
  local f
  for f in "$HOME/Library/Preferences/com.${app_lower}."*(N) \
           "$HOME/Library/Preferences/${app_name}"*(N) \
           "$HOME/Library/Containers/com.${app_lower}"*(N) \
           "$HOME/Library/Group Containers/group.com.${app_lower}"*(N) \
           "$HOME/Library/Group Containers/group.${app_lower}"*(N) \
           "$HOME/Library/Caches/com.${app_lower}."*(N) \
           "$HOME/Library/LaunchAgents/com.${app_lower}."*(N); do
    if [[ -e "$f" ]]; then
      local itype="directory"
      [[ -f "$f" ]] && itype="file"
      local strat="rm_dir"
      [[ "$f" == *"/LaunchAgents/"* ]] && strat="unload_launch_agent"
      add_item "$f" "$itype" "SAFE" "Anchored User Library leftover" "$strat"
    fi
  done

  # Check Group Containers for unanchored substring matches
  for f in "$HOME/Library/Group Containers/"*"${app_lower}"*(N); do
    if [[ -e "$f" ]]; then
      local bname="${f:t}"
      # If match is anchored to group.com.<app> or group.<app> or exact bundle_id, skip (already handled or will be handled by bundle_id)
      if [[ "$bname" == "group.com.${app_lower}"* || "$bname" == "group.${app_lower}"* ]]; then
        continue
      fi
      if [[ -n "$bundle_id" && "$bname" == *"${bundle_id}"* ]]; then
        continue
      fi
      # Unanchored substring matches in Group Containers MUST be demoted to UNKNOWN (reported only, not auto-removable)
      add_item "$f" "directory" "UNKNOWN" "Unanchored Group Container substring match" "none"
    fi
  done

  # Bundle ID anchored matches
  if [[ -n "$bundle_id" ]]; then
    for f in "$HOME/Library/Preferences/${bundle_id}"*(N) \
             "$HOME/Library/Containers/${bundle_id}"*(N) \
             "$HOME/Library/Group Containers/"*"${bundle_id}"*(N) \
             "$HOME/Library/Group Containers/group.${bundle_id}"*(N) \
             "$HOME/Library/Caches/${bundle_id}"*(N) \
             "$HOME/Library/LaunchAgents/${bundle_id}."*(N); do
      if [[ -e "$f" ]]; then
        local itype="directory"
        [[ -f "$f" ]] && itype="file"
        local strat="rm_dir"
        [[ "$f" == *"/LaunchAgents/"* ]] && strat="unload_launch_agent"
        add_item "$f" "$itype" "SAFE" "Bundle ID anchored leftover" "$strat"
      fi
    done
  fi

  # 5. System Library locations
  for f in "/Library/LaunchAgents/com.${app_lower}."*(N) \
           "/Library/LaunchDaemons/com.${app_lower}."*(N) \
           "/Library/PrivilegedHelperTools/com.${app_lower}"*(N) \
           "/Library/Application Support/${app_name}" \
           "/Library/Application Support/${app_lower}"; do
    if [[ -e "$f" ]]; then
      local itype="directory"
      [[ -f "$f" ]] && itype="file"
      local strat="rm_dir"
      [[ "$f" == *"/LaunchAgents/"* ]] && strat="unload_launch_agent"
      [[ "$f" == *"/LaunchDaemons/"* ]] && strat="unload_launch_daemon"
      add_item "$f" "$itype" "SAFE" "System Library leftover" "$strat"
    fi
  done

  print -l "${inventory[@]}"
}

plugin_generic_app_classify() {
  local item_path="$1"
  local type="$2"
  local current_class="$3"

  if is_user_code "$item_path"; then
    echo "USER_CODE"
    return
  fi
  if is_critical_path "$item_path"; then
    echo "PROTECTED"
    return
  fi
  if is_protected_system "$item_path"; then
    echo "PROTECTED"
    return
  fi

  # Demote unanchored Group Containers matches to UNKNOWN
  if [[ "$item_path" == "$HOME/Library/Group Containers/"* ]]; then
    local bname="${item_path:t}"
    if [[ "$current_class" != "SAFE" || ("$bname" != "group.com."* && "$bname" != "group."*) ]]; then
      # If not explicitly anchored to group.com or group., demote to UNKNOWN
      echo "UNKNOWN"
      return
    fi
  fi

  echo "$current_class"
}

plugin_generic_app_remove() {
  local item_path="$1"
  local type="$2"
  local strat="$3"
  local dry_run="${4:-no}"

  default_remove_strategy "$item_path" "$type" "$strat" "$dry_run"
}

plugin_generic_app_verify() {
  local app_raw="$1"
  local redis
  redis=$(plugin_generic_app_discover "$app_raw")
  
  local count=0
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local item_path="" type="" class="" reason="" strat=""
    IFS='|' read -r item_path type class reason strat <<< "$line"
    if [[ "$class" == "SAFE" || "$class" == "CACHE" ]]; then
      (( count++ ))
    fi
  done <<< "$redis"

  if [[ $count -eq 0 ]]; then
    echo "REMOVED"
  else
    echo "STILL_PRESENT"
  fi
}
