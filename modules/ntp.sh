#!/bin/bash
# Module: Time Synchronization Hardening
# Description: Configures secure and accurate time synchronization settings

LOG_FILE="/var/log/hardening_script.log"
BACKUP_SUFFIX=".bak"
CHRONY_CONF="/etc/chrony/chrony.conf"
TIMESYNC_SERVICE="systemd-timesyncd"

echo "Starting Time Synchronization Hardening..." >> "$LOG_FILE"

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

# Install and configure chrony
log "Installing chrony for time synchronization."
if apt-get install -y chrony &>> "$LOG_FILE"; then
  log "chrony installed successfully."
else
  log "Failed to install chrony. Check the logs for details."
  exit 1
fi

# Backup chrony configuration file
backup_file "$CHRONY_CONF"

# Configure chrony with secure settings
cat > "$CHRONY_CONF" <<EOF
# Chrony configuration for secure time synchronization
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst

# Allow NTP traffic from localhost only
allow 127.0.0.1
allow ::1

# Log statistics for monitoring
log measurements statistics tracking
EOF
log "Updated $CHRONY_CONF with secure NTP server settings."

# Restart chrony to apply changes
log "Restarting chrony service."
if systemctl restart chrony &>> "$LOG_FILE"; then
  log "chrony restarted successfully."
else
  log "Failed to restart chrony. Check the logs for details."
  exit 1
fi

# Disable systemd-timesyncd if active
if systemctl is-active --quiet "$TIMESYNC_SERVICE"; then
  systemctl stop "$TIMESYNC_SERVICE" &>> "$LOG_FILE" && log "Stopped $TIMESYNC_SERVICE."
fi
if systemctl is-enabled --quiet "$TIMESYNC_SERVICE"; then
  systemctl disable "$TIMESYNC_SERVICE" &>> "$LOG_FILE" && log "Disabled $TIMESYNC_SERVICE."
fi

log "Time Synchronization Hardening completed."
