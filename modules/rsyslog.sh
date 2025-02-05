#!/bin/bash
# Module: System Log Hardening
# Description: Configures logging settings to ensure secure and reliable system logging

LOG_FILE="/var/log/hardening_script.log"
RSYSLOG_CONF="/etc/rsyslog.conf"
RSYSLOG_D_DIR="/etc/rsyslog.d"

echo "Starting System Log Hardening..." >> "$LOG_FILE"

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

# Ensure rsyslog is installed
log "Installing rsyslog if not already installed."
if apt-get install -y rsyslog &>> "$LOG_FILE"; then
  log "rsyslog installed successfully."
else
  log "Failed to install rsyslog. Check the logs for details."
  exit 1
fi

# Backup existing rsyslog configuration
backup_file "$RSYSLOG_CONF"

# Update rsyslog configuration for secure logging
cat > "$RSYSLOG_CONF" <<EOF
# rsyslog configuration for secure logging
module(load="imuxsock")
module(load="imklog")

*.* /var/log/messages
auth,authpriv.* /var/log/auth.log
kern.* /var/log/kern.log
daemon.* /var/log/daemon.log
syslog.* /var/log/syslog
EOF
log "Updated $RSYSLOG_CONF with secure logging settings."

# Restrict access to log files
log "Restricting access to system log files."
chmod -R go-rwx /var/log/*
log "Permissions updated for /var/log directory and its contents."

# Restart rsyslog to apply changes
log "Restarting rsyslog service."
if systemctl restart rsyslog &>> "$LOG_FILE"; then
  log "rsyslog restarted successfully."
else
  log "Failed to restart rsyslog. Check the logs for details."
fi

log "System Log Hardening completed."
