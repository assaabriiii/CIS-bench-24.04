#!/bin/bash
# Module: AppArmor Setup
# Description: Installs and configures AppArmor for Mandatory Access Control

LOG_FILE="/var/log/hardening_script.log"
BACKUP_SUFFIX=".bak"

log() {
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cp "$file" "${file}${BACKUP_SUFFIX}" && log "Backup created for $file"
  else
    log "File $file not found, skipping backup."
  fi
}

validate_change() {
  local cmd="$1"
  local success_msg="$2"
  local failure_msg="$3"

  if eval "$cmd" &>> "$LOG_FILE"; then
    log "$success_msg"
  else
    log "$failure_msg"
  fi
}

install_apparmor() {
  log "Installing AppArmor and utilities..."
  validate_change "apt-get update -y && apt-get install -y apparmor apparmor-utils" \
    "AppArmor installed successfully." \
    "Failed to install AppArmor. Check log for details."
}

configure_grub_for_apparmor() {
  local grub_file="/etc/default/grub"
  backup_file "$grub_file"

  if ! grep -q "apparmor=1 security=apparmor" "$grub_file"; then
    validate_change "sed -i '/^GRUB_CMDLINE_LINUX=/ s/\"$/ apparmor=1 security=apparmor\"/' \"$grub_file\" && update-grub" \
      "AppArmor configuration added to GRUB and GRUB updated successfully." \
      "Failed to configure GRUB for AppArmor."
  else
    log "AppArmor is already configured in GRUB."
  fi
}

set_profiles_to_complain_mode() {
  log "Setting AppArmor profiles to complain mode..."
  local profiles
  profiles=$(apparmor_status | awk '/profiles are loaded/{print $1}' 2>> "$LOG_FILE")

  if [[ -z "$profiles" ]]; then
    log "No active AppArmor profiles found."
  else
    for profile in $(apparmor_status | awk '/enforce/{print $NF}' 2>> "$LOG_FILE"); do
      validate_change "aa-complain \"$profile\"" \
        "Set $profile to complain mode." \
        "Failed to set $profile to complain mode."
    done
  fi
}

# Main Execution
install_apparmor
configure_grub_for_apparmor
set_profiles_to_complain_mode

log "AppArmor setup completed."
