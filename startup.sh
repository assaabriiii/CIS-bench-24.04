#!/bin/bash
# Startup Script Selector with Dialog
# Description: Provides a dialog-based interface to select and run specific scripts or all scripts
# Ensure dialog is installed
if ! command -v dialog &> /dev/null; then
    echo "dialog could not be found, installing..."
    sudo apt-get update && sudo apt-get install -y dialog
fi
LOG_FILE="/var/log/startup_script_selector.log"
SCRIPT_DIR="./modules"

log() {
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

run_script() {
  local script="$1"
  log "Running $script..."
  if bash "$SCRIPT_DIR/$script"; then
    log "$script completed successfully."
  else
    log "$script failed. Check the logs for details."
  fi
}

run_all_scripts() {
  log "Running all scripts in $SCRIPT_DIR..."
  for script in "$SCRIPT_DIR"/*.sh; do
    run_script "$(basename "$script")"
  done
}

show_menu() {
  local scripts=("Run All")
  while IFS= read -r script; do
    scripts+=("$(basename "$script")")
  done < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name "*.sh")

  local menu_items=()
  for i in "${!scripts[@]}"; do
    menu_items+=($i "${scripts[$i]}")
  done

  local choice
  choice=$(dialog --clear --title "Startup Script Selector" \
    --menu "Choose a script to run:" 20 70 30 \
    "${menu_items[@]}" 2>&1 >/dev/tty)

  clear
  if [[ -z "$choice" ]]; then
    echo "No selection made. Exiting." | tee -a "$LOG_FILE"
    exit 0
  fi

  if [[ "${scripts[$choice]}" == "Run All" ]]; then
    run_all_scripts
  else
    run_script "${scripts[$choice]}"
  fi
}

log "Starting Startup Script Selector..."
show_menu
log "Startup Script Selector completed."
