#!/bin/bash
# Module: File Permissions Hardening
# Description: Configures secure file permissions for critical system files and directories

LOG_FILE="/var/log/hardening_script.log"

echo "Starting File Permissions Hardening..." >> "$LOG_FILE"

log() {
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Set secure permissions for sensitive files
secure_permissions() {
  local file="$1"
  local owner="$2"
  local group="$3"
  local permissions="$4"

  if [[ -e "$file" ]]; then
    chown "$owner":"$group" "$file" && chmod "$permissions" "$file" && log "Updated permissions for $file."
  else
    log "$file not found. Skipping."
  fi
}

# Critical files to secure
secure_permissions "/etc/passwd" "root" "root" 644
secure_permissions "/etc/shadow" "root" "shadow" 640
secure_permissions "/etc/group" "root" "root" 644
secure_permissions "/etc/gshadow" "root" "shadow" 640
secure_permissions "/etc/hosts" "root" "root" 644
secure_permissions "/etc/issue" "root" "root" 644
secure_permissions "/etc/issue.net" "root" "root" 644
secure_permissions "/etc/motd" "root" "root" 644

# Secure sensitive directories
secure_permissions "/root" "root" "root" 700
secure_permissions "/var/log" "root" "root" 750

log "File Permissions Hardening completed."
