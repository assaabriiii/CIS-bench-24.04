#!/bin/bash
# Module: Filesystem Configuration
# Description: Disables unnecessary filesystems for enhanced security

LOG_FILE="/var/log/hardening_script.log"
BACKUP_SUFFIX=".bak"
DISABLED_FS_CONF="/etc/modprobe.d/disabled-fs.conf"
MODPROBE_CONF="/etc/modprobe.d/modprobe.conf"
FILESYSTEMS=("cramfs" "freevxfs" "hfs" "hfsplus" "overlayfs" "squashfs" "udf" "jffs2" "usb-storage")

echo "Starting Filesystem Configuration..."

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

# Ensure configuration files exist
backup_file "$DISABLED_FS_CONF"
backup_file "$MODPROBE_CONF"

touch "$DISABLED_FS_CONF"
touch "$MODPROBE_CONF"

# Disable and blacklist filesystems
for FS in "${FILESYSTEMS[@]}"; do
  echo "install $FS /bin/false" >> "$DISABLED_FS_CONF"
  echo "blacklist $FS" >> "$MODPROBE_CONF"
  log "Disabled and blacklisted filesystem: $FS"
done

# Unload filesystem modules from the kernel
for FS in "${FILESYSTEMS[@]}"; do
  if lsmod | grep -q "^$FS"; then
    if modprobe -r "$FS"; then
      log "Unloaded filesystem module: $FS"
    else
      log "Failed to unload filesystem module: $FS"
    fi
  else
    log "Filesystem module $FS is not loaded."
  fi
done

# Notify user of completion
echo "Filesystem Configuration Completed."