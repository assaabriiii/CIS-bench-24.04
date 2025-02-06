#!/bin/bash
# Module: UFW Hardening
# Description: Configures UFW firewall for secure operations on Ubuntu 24.04

LOG_FILE="/var/log/hardening_script.log"
BACKUP_SUFFIX=".bak"

echo "Starting UFW Hardening..."

# Logging function to record actions
log() {
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Backup function to create backups of configuration files
backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cp "$file" "${file}${BACKUP_SUFFIX}" && log "Backup created for $file"
  else
    log "File $file not found, skipping backup."
  fi
}

# Backup UFW configuration files (optional but recommended)
UFW_DEFAULT="/etc/default/ufw"
UFW_CONF="/etc/ufw/ufw.conf"
backup_file "$UFW_DEFAULT"
backup_file "$UFW_CONF"

# Set default policies for UFW as per hardening guidelines
log "Setting default policies..."
ufw default deny incoming && log "Default policy for incoming traffic set to DENY."
ufw default allow outgoing && log "Default policy for outgoing traffic set to ALLOW."

# Allow SSH connections to ensure remote access remains available
log "Allowing SSH connections..."
ufw allow ssh && log "Allowed SSH connections."

# Additional service rules can be added as needed:
# For example, to allow HTTP and HTTPS traffic, uncomment these lines:
# log "Allowing HTTP traffic..."
# ufw allow http && log "Allowed HTTP traffic."
# log "Allowing HTTPS traffic..."
# ufw allow https && log "Allowed HTTPS traffic."

# Enable UFW logging to capture firewall events
log "Enabling logging..."
ufw logging on && log "UFW logging enabled."

# Enable UFW; the '--force' flag bypasses interactive confirmation
log "Enabling UFW firewall..."
ufw --force enable && log "UFW firewall enabled."

# Output the current UFW status to the log
log "UFW status:"
ufw status verbose | tee -a "$LOG_FILE"

echo "UFW Hardening Completed."
