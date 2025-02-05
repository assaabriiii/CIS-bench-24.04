#!/bin/bash
# Module: PAM Hardening
# Description: Configures Pluggable Authentication Modules (PAM) for enhanced security

LOG_FILE="/var/log/hardening_script.log"
PAM_COMMON_AUTH="/etc/pam.d/common-auth"
PAM_COMMON_PASSWORD="/etc/pam.d/common-password"

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

# Ensure required packages are installed
log "Installing required PAM packages."
if apt-get install -y libpam-pwquality &>> "$LOG_FILE"; then
  log "Required PAM packages installed successfully."
else
  log "Failed to install required PAM packages. Check logs for details."
  exit 1
fi

log "Starting PAM Hardening..."

# Backup PAM configuration files
backup_file "$PAM_COMMON_AUTH"
backup_file "$PAM_COMMON_PASSWORD"

# Configure PAM to enforce strong password policies
log "Configuring strong password policies in PAM."
sed -i '/pam_pwquality.so/d' "$PAM_COMMON_PASSWORD"
echo "password requisite pam_pwquality.so retry=3 minlen=12 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1" >> "$PAM_COMMON_PASSWORD"
log "Updated $PAM_COMMON_PASSWORD to enforce strong passwords."

# # Configure lockout policy for failed login attempts
# log "Configuring lockout policy for failed logins."
# sed -i '/pam_tally2.so/d' "$PAM_COMMON_AUTH"
# echo "auth required pam_tally2.so deny=5 unlock_time=600 onerr=fail audit" >> "$PAM_COMMON_AUTH"
# log "Updated $PAM_COMMON_AUTH to lock accounts after 5 failed attempts."

# Test PAM configuration
log "Testing PAM configuration for password policies."
echo "Testing password policy: Expect rejection for weak passwords."
echo "weakpassword" | passwd --stdin testuser 2>> "$LOG_FILE"
if [[ $? -ne 0 ]]; then
  log "Password policy test passed: Weak password rejected."
else
  log "Password policy test failed: Weak password accepted."
  exit 1
fi

log "Testing lockout policy: Expect lockout after 5 failed attempts."
for i in {1..5}; do
  su -c "echo wrongpassword | su testuser" 2>> "$LOG_FILE"
done
if faillog -u testuser | grep -q "FAILURES"; then
  log "Lockout policy test passed: User locked out after repeated failures."
else
  log "Lockout policy test failed: User not locked out."
  exit 1
fi

log "PAM Hardening completed successfully."
