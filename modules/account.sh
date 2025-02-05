#!/bin/bash
# Module: Account Security Hardening
# Description: Configures user accounts for enhanced security

LOG_FILE="/var/log/hardening_script.log"
BACKUP_SUFFIX=".bak"

echo "Starting Account Security Hardening..." >> "$LOG_FILE"

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

# Lock unnecessary system accounts
log "Locking unnecessary system accounts."
for account in $(awk -F: '($3 < 1000 && $1 != "root") {print $1}' /etc/passwd); do
  usermod -L "$account" &>> "$LOG_FILE" && log "Locked account: $account."
done

# Ensure no accounts have empty passwords
log "Checking for accounts with empty passwords."
for user in $(awk -F: '($2 == "" && $3 >= 1000) {print $1}' /etc/shadow); do
  passwd -l "$user" &>> "$LOG_FILE" && log "Locked user with empty password: $user."
done

# Enforce strong password policies in /etc/login.defs
LOGIN_DEFS="/etc/login.defs"
backup_file "$LOGIN_DEFS"
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' "$LOGIN_DEFS"
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' "$LOGIN_DEFS"
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' "$LOGIN_DEFS"
if ! grep -q "^ENCRYPT_METHOD" "$LOGIN_DEFS"; then
  echo "ENCRYPT_METHOD SHA512" >> "$LOGIN_DEFS"
else
  sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/' "$LOGIN_DEFS"
fi
log "Updated $LOGIN_DEFS with secure password policies."

# Expire passwords for inactive accounts
log "Expiring passwords for inactive accounts."
for user in $(awk -F: '($3 >= 1000) {print $1}' /etc/passwd); do
  chage --inactive 30 "$user" &>> "$LOG_FILE" && log "Set password expiration for $user."
done

log "Account Security Hardening completed."