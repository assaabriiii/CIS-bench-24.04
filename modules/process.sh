#!/bin/bash
# Module: Process Hardening
# Description: Configures kernel parameters and removes unnecessary packages for process-level hardening

LOG_FILE="/var/log/hardening_script.log"
BACKUP_SUFFIX=".bak"
SYSCTL_CONF="/etc/sysctl.conf"

echo "Starting Process Hardening..." >> "$LOG_FILE"

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

apply_sysctl_param() {
  local key="$1"
  local value="$2"
  if ! grep -q "^$key" "$SYSCTL_CONF"; then
    echo "$key = $value" >> "$SYSCTL_CONF"
  else
    sed -i "s/^$key.*/$key = $value/" "$SYSCTL_CONF"
  fi
  if sysctl -w "$key=$value" &>> "$LOG_FILE"; then
    log "Applied sysctl parameter: $key = $value"
  else
    log "Failed to apply sysctl parameter: $key = $value"
  fi
}

# Backup sysctl configuration
backup_file "$SYSCTL_CONF"

# Kernel Parameters for Process Hardening
params=(
  "kernel.randomize_va_space=2"
  "kernel.yama.ptrace_scope=2"
  "fs.suid_dumpable=0"
)

for param in "${params[@]}"; do
  IFS="=" read -r key value <<< "$param"
  apply_sysctl_param "$key" "$value"
done

# Uninstall unnecessary packages
PACKAGES_TO_REMOVE=("prelink" "apport")
for package in "${PACKAGES_TO_REMOVE[@]}"; do
  if dpkg-query -s "$package" &>> "$LOG_FILE"; then
    apt-get purge -y "$package" &>> "$LOG_FILE" && log "Removed $package successfully."
  else
    log "$package is not installed, skipping removal."
  fi
done

# Disable unnecessary services
SERVICES_TO_DISABLE=("apport")
for service in "${SERVICES_TO_DISABLE[@]}"; do
  if systemctl is-active --quiet "$service"; then
    systemctl stop "$service" &>> "$LOG_FILE" && log "Stopped $service."
  fi
  if systemctl is-enabled --quiet "$service"; then
    systemctl disable "$service" &>> "$LOG_FILE" && log "Disabled $service."
  fi
done

log "Process Hardening completed."
