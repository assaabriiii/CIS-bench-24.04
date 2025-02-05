#!/bin/bash
# Module: System Integrity Monitoring
# Description: Installs and configures AIDE (Advanced Intrusion Detection Environment) to monitor system integrity

LOG_FILE="/var/log/integrity_monitoring.log"
AIDE_CONF="/etc/aide/aide.conf"
AIDE_DB="/var/lib/aide/aide.db"
AIDE_DB_NEW="/var/lib/aide/aide.db.new"

log() {
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

log "Starting System Integrity Monitoring Setup..."

# Install AIDE if not already installed
log "Installing AIDE package."
if apt-get install -y aide aide-common &>> "$LOG_FILE"; then
  log "AIDE installed successfully."
else
  log "Failed to install AIDE. Check logs for details."
  exit 1
fi

# Backup existing AIDE configuration
if [[ -f "$AIDE_CONF" ]]; then
  cp "$AIDE_CONF" "${AIDE_CONF}.bak" && log "Backup created for $AIDE_CONF."
else
  log "$AIDE_CONF not found. Proceeding with default configuration."
fi

# Initialize AIDE database
log "Initializing AIDE database. This may take some time."
aideinit &>> "$LOG_FILE"
if [[ $? -eq 0 ]]; then
  mv "$AIDE_DB_NEW" "$AIDE_DB" && log "AIDE database initialized and saved."
else
  log "Failed to initialize AIDE database. Check logs for details."
  exit 1
fi

# Schedule regular integrity checks using cron
CRON_JOB="/usr/local/bin/aide_check.sh"
cat > "$CRON_JOB" <<EOF
#!/bin/bash
LOG_FILE="/var/log/aide_check.log"
aide --check &>> "\$LOG_FILE"
EOF
chmod +x "$CRON_JOB"

if ! crontab -l 2>/dev/null | grep -q "$CRON_JOB"; then
  (crontab -l 2>/dev/null; echo "0 3 * * * $CRON_JOB") | crontab -
  log "Scheduled daily AIDE check at 3 AM."
else
  log "AIDE check is already scheduled in crontab."
fi

log "System Integrity Monitoring Setup completed."
