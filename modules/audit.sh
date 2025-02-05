#!/bin/bash
# Module: Audit Hardening
# Description: Configures auditing and logging settings for enhanced security

LOG_FILE="/var/log/hardening_script.log"
BACKUP_SUFFIX=".bak"
AUDIT_RULES_FILE="/etc/audit/audit.rules"
AUDITD_CONF="/etc/audit/auditd.conf"

echo "Starting Audit Hardening..." >> "$LOG_FILE"

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

# Install and configure auditd
log "Installing auditd and setting up audit rules."
if apt-get install -y auditd &>> "$LOG_FILE"; then
  log "auditd installed successfully."
else
  log "Failed to install auditd. Check the logs for details."
  exit 1
fi

# Backup existing configuration files
backup_file "$AUDIT_RULES_FILE"
backup_file "$AUDITD_CONF"

# Configure audit rules
cat > "$AUDIT_RULES_FILE" <<EOF

## Remove any existing rules
-D

## Buffer Size
## Feel free to increase this if the machine panic's
-b 8192

## Failure Mode
## Possible values are 0 (silent), 1 (printk, print a failure message),
## and 2 (panic, halt the system).
-f 1

## Audit the audit logs.
## successful and unsuccessful attempts to read information from the
## audit records; all modifications to the audit trail
-w /var/log/audit/ -k auditlog

## Auditd configuration
## modifications to audit configuration that occur while the audit
## collection functions are operating.
-w /etc/audit/ -p wa -k auditconfig
-w /etc/libaudit.conf -p wa -k auditconfig
-w /etc/audisp/ -p wa -k audispconfig

## Monitor for use of audit management tools
-w /sbin/auditctl -p x -k audittools
-w /sbin/auditd -p x -k audittools

## special files
-a exit,always -F arch=b32 -S mknod -S mknodat -k specialfiles
-a exit,always -F arch=b64 -S mknod -S mknodat -k specialfiles

## Mount operations
-a exit,always -F arch=b32 -S mount -S umount -S umount2 -k mount
-a exit,always -F arch=b64 -S mount -S umount2 -k mount

## changes to the time
##
-a exit,always -F arch=b32 -S adjtimex -S settimeofday -S clock_settime -k time
-a exit,always -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time

## Use stunnel
-w /usr/sbin/stunnel -p x -k stunnel

## cron configuration & scheduled jobs
-w /etc/cron.allow -p wa -k cron
-w /etc/cron.deny -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /etc/cron.daily/ -p wa -k cron
-w /etc/cron.hourly/ -p wa -k cron
-w /etc/cron.monthly/ -p wa -k cron
-w /etc/cron.weekly/ -p wa -k cron
-w /etc/crontab -p wa -k cron
-w /var/spool/cron/crontabs/ -k cron

## user, group, password databases
-w /etc/group -p wa -k etcgroup
-w /etc/passwd -p wa -k etcpasswd
-w /etc/gshadow -k etcgroup
-w /etc/shadow -k etcpasswd
-w /etc/security/opasswd -k opasswd

## monitor usage of passwd
-w /usr/bin/passwd -p x -k passwd_modification

#Monitor for use of tools to change group identifiers
-w /usr/sbin/groupadd -p x -k group_modification
-w /usr/sbin/groupmod -p x -k group_modification
-w /usr/sbin/addgroup -p x -k group_modification
-w /usr/sbin/useradd -p x -k user_modification
-w /usr/sbin/usermod -p x -k user_modification
-w /usr/sbin/adduser -p x -k user_modification

## login configuration and information
-w /etc/login.defs -p wa -k login
-w /etc/securetty -p wa -k login
-w /var/log/faillog -p wa -k login
-w /var/log/lastlog -p wa -k login
-w /var/log/tallylog -p wa -k login

## network configuration
-w /etc/hosts -p wa -k hosts
-w /etc/network/ -p wa -k network

## system startup scripts
-w /etc/inittab -p wa -k init
-w /etc/init.d/ -p wa -k init
-w /etc/init/ -p wa -k init

## library search paths
-w /etc/ld.so.conf -p wa -k libpath

## local time zone
-w /etc/localtime -p wa -k localtime

## kernel parameters
-w /etc/sysctl.conf -p wa -k sysctl

## modprobe configuration
-w /etc/modprobe.conf -p wa -k modprobe

## pam configuration
-w /etc/pam.d/ -p wa -k pam
-w /etc/security/limits.conf -p wa  -k pam
-w /etc/security/pam_env.conf -p wa -k pam
-w /etc/security/namespace.conf -p wa -k pam
-w /etc/security/namespace.init -p wa -k pam

## postfix configuration
-w /etc/aliases -p wa -k mail
-w /etc/postfix/ -p wa -k mail

## ssh configuration
-w /etc/ssh/sshd_config -k sshd

## changes to hostname
-a exit,always -F arch=b32 -S sethostname -k hostname
-a exit,always -F arch=b64 -S sethostname -k hostname

## changes to issue
-w /etc/issue -p wa -k etcissue
-w /etc/issue.net -p wa -k etcissue

## this was to noisy currently.
# log all commands executed by an effective id of 0 aka root.
-a exit,always -F arch=b64 -F euid=0 -S execve -k rootcmd
-a exit,always -F arch=b32 -F euid=0 -S execve -k rootcmd

## Capture all failures to access on critical elements
-a exit,always -F arch=b64 -S open -F dir=/etc -F success=0 -k unauthedfileacess
-a exit,always -F arch=b64 -S open -F dir=/bin -F success=0 -k unauthedfileacess
-a exit,always -F arch=b64 -S open -F dir=/sbin -F success=0 -k unauthedfileacess
-a exit,always -F arch=b64 -S open -F dir=/usr/bin -F success=0 -k unauthedfileacess
-a exit,always -F arch=b64 -S open -F dir=/usr/sbin -F success=0 -k unauthedfileacess
-a exit,always -F arch=b64 -S open -F dir=/var -F success=0 -k unauthedfileacess
-a exit,always -F arch=b64 -S open -F dir=/home -F success=0 -k unauthedfileacess
-a exit,always -F arch=b64 -S open -F dir=/srv -F success=0 -k unauthedfileacess

## Monitor for use of process ID change (switching accounts) applications
-w /bin/su -p x -k priv_esc
-w /usr/bin/sudo -p x -k priv_esc
-w /etc/sudoers -p rw -k priv_esc

## Monitor usage of commands to change power state
-w /sbin/shutdown -p x -k power
-w /sbin/poweroff -p x -k power
-w /sbin/reboot -p x -k power
-w /sbin/halt -p x -k power

## Change os sys administrators
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d -p wa -k scope

## elevated proviliges
-a always,exit -F arch=b64 -C euid!=uid -F auid!=unset -S execve -k user_emulation
-a always,exit -F arch=b32 -C euid!=uid -F auid!=unset -S execve -k user_emulation

## Modify Network Environment
-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/networks -p wa -k system-locale
-w /etc/network/ -p wa -k system-locale

## Session Initiation
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session

# Login and logout
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock -p wa -k logins

## Changes on the MAC Policy
-w /etc/apparmor/ -p wa -k MAC-policy
-w /etc/apparmor.d/ -p wa -k MAC-policy

## Make the configuration immutable
-e 2

EOF
log "Updated $AUDIT_RULES_FILE with basic audit rules."

# Update auditd configuration for logging
sed -i 's/^num_logs.*/num_logs = 10/' "$AUDITD_CONF"
sed -i 's/^max_log_file.*/max_log_file = 20/' "$AUDITD_CONF"
sed -i 's/^max_log_file_action.*/max_log_file_action = keep_logs/' "$AUDITD_CONF"
log "Updated $AUDITD_CONF for enhanced logging."

# Restart auditd to apply changes
log "Restarting auditd to apply changes."
if systemctl restart auditd &>> "$LOG_FILE"; then
  log "auditd restarted successfully."
else
  log "Failed to restart auditd. Check the logs for details."
fi

log "Audit Hardening completed."
