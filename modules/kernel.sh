#!/bin/bash
# Module: Kernel Hardening
# Description: Applies kernel-level hardening using sysctl parameters

LOG_FILE="/var/log/hardening_script.log"
BACKUP_SUFFIX=".bak"
SYSCTL_CONF="/etc/sysctl.conf"

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
  if sysctl -w "$key=$value"; then
    log "Applied sysctl parameter: $key=$value"
  else
    log "Failed to apply sysctl parameter: $key=$value"
  fi
}

# Backup sysctl configuration
backup_file "$SYSCTL_CONF"

# Kernel Hardening Parameters
params=(
  "kernel.randomize_va_space=2"
  "kernel.yama.ptrace_scope=2"
  "fs.suid_dumpable=0"
  "net.ipv4.ip_forward=0"
  "net.ipv4.conf.all.send_redirects=0"
  "net.ipv4.conf.default.send_redirects=0"
  "net.ipv4.conf.all.accept_redirects=0"
  "net.ipv4.conf.default.accept_redirects=0"
  "net.ipv4.conf.all.secure_redirects=0"
  "net.ipv4.conf.default.secure_redirects=0"
  "net.ipv4.conf.all.log_martians=1"
  "net.ipv4.conf.default.log_martians=1"
  "net.ipv4.tcp_syncookies=1"
  "net.ipv6.conf.all.disable_ipv6=1"
  "net.ipv6.conf.default.disable_ipv6=1"
  "net.ipv6.conf.all.forwarding=0"
  "net.ipv6.conf.default.forwarding=0"
  "net.ipv4.icmp_echo_ignore_broadcasts=1"
  "net.ipv4.icmp_ignore_bogus_error_responses=1"
  "net.ipv4.conf.all.rp_filter=1"
  "net.ipv4.conf.default.rp_filter=1"
  "net.ipv6.conf.all.accept_ra=0"
  "net.ipv6.conf.default.accept_ra=0"
  "net.ipv4.conf.all.accept_source_route=0"
  "net.ipv4.conf.default.accept_source_route=0"
  "net.ipv6.conf.all.accept_source_route=0"
  "net.ipv6.conf.default.accept_source_route=0"
  "fs.protected_hardlinks=1"
  "fs.protected_symlinks=1"
  "kernel.kptr_restrict=2"
  "kernel.dmesg_restrict=1"
  "net.ipv4.tcp_timestamps=0"
  "net.ipv4.tcp_syncookies=1"
  "net.ipv4.conf.all.rp_filter=1"
  "net.ipv4.conf.default.rp_filter=1"
  "net.ipv4.conf.all.log_martians=1"
  "net.ipv4.conf.default.log_martians=1"
  "net.ipv4.icmp_echo_ignore_broadcasts=1"
  "net.ipv4.icmp_ignore_bogus_error_responses=1"
  "net.ipv4.conf.all.accept_source_route=0"
  "net.ipv4.conf.default.accept_source_route=0"
)

for param in "${params[@]}"; do
  IFS="=" read -r key value <<< "$param"
  apply_sysctl_param "$key" "$value"
done

log "Kernel hardening parameters applied."

echo "Kernel Hardening Completed."
