#!/bin/bash
# Module: Service Hardening
# Description: Disables and removes unnecessary services for enhanced security

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

remove_service() {
  local service="$1"
  log "Disabling and removing service: $service"

  # Stop the service if active
  if systemctl is-active --quiet "$service"; then
    validate_change "systemctl stop \"$service\"" \
      "$service stopped successfully." \
      "Failed to stop $service."
  fi

  # Disable the service if enabled
  if systemctl is-enabled --quiet "$service"; then
    validate_change "systemctl disable \"$service\"" \
      "$service disabled successfully." \
      "Failed to disable $service."
  fi

  # Remove the service package if installed
  if dpkg -l | grep -q "^ii.*$service"; then
    validate_change "apt-get purge -y \"$service\"" \
      "$service removed successfully." \
      "Failed to remove $service."
  else
    log "$service is not installed. Skipping removal."
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

SERVICES_TO_REMOVE=(
  "autofs" "avahi-daemon" "isc-dhcp-server" "bind9" "dnsmasq" "slapd"
  "dovecot-imapd" "dovecot-pop3d" "nfs-kernel-server" "ypserv" "cups"
  "rpcbind" "rsync" "samba" "snmpd" "tftpd-hpa" "squid" "apache2"
  "nginx" "xinetd" "xserver-common" "postfix" "nis" "rsh-client"
  "talk" "telnet" "inetutils-telnet" "ldap-utils" "ftp" "tnftp" "lp"
  "bluez" "gdm3" "whoopsie" "snapd"
)

for service in "${SERVICES_TO_REMOVE[@]}"; do
  remove_service "$service"
done

log "Service hardening completed."
