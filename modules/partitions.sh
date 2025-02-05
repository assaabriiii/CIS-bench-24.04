#!/bin/bash
# Module: Secure Temporary Partitions
# Description: Secures temporary partitions (/tmp, /var/tmp, /dev/shm) by mounting them with restrictive options

LOG_FILE="/var/log/hardening_script.log"
FSTAB_FILE="/etc/fstab"
TMP_OPTIONS="nodev,nosuid,noexec"
VAR_TMP_OPTIONS="nodev,nosuid,noexec"
DEV_SHM_OPTIONS="nodev,nosuid,noexec"

log() {
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cp "$file" "${file}.bak" && log "Backup created for $file."
  else
    log "File $file not found, skipping backup."
  fi
}

secure_partition() {
  local partition="$1"
  local options="$2"

  log "Securing $partition with options: $options."

  # Check if the partition is already in /etc/fstab
  if grep -q "^$partition" "$FSTAB_FILE"; then
    log "$partition entry found in $FSTAB_FILE. Ensuring restrictive mount options."
    sed -i "/^$partition/ s/defaults.*/defaults,$options/" "$FSTAB_FILE"
  else
    log "$partition not found in $FSTAB_FILE. Adding entry."
    echo "tmpfs $partition tmpfs defaults,$options 0 0" >> "$FSTAB_FILE"
  fi

  # Remount the partition with the updated options
  log "Remounting $partition with restrictive options."
  if mount -o remount "$partition" &>> "$LOG_FILE"; then
    log "$partition remounted successfully with $options options."
  else
    log "Failed to remount $partition. Check logs for details."
    exit 1
  fi
}

log "Starting Secure Temporary Partitions Configuration..."

# Backup fstab configuration
backup_file "$FSTAB_FILE"

# Secure each temporary partition
secure_partition "/tmp" "$TMP_OPTIONS"
secure_partition "/var/tmp" "$VAR_TMP_OPTIONS"
secure_partition "/dev/shm" "$DEV_SHM_OPTIONS"

log "Secure Temporary Partitions Configuration completed."
