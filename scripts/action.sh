#!/system/bin/sh
# =============================================================================
# MagiskSSH Action Script — Quick Service Toggle
# Called by KernelSU Manager as the module "action" button handler.
#
# Behavior: toggle sshd on/off; toast current status.
# =============================================================================

# Derive MODDIR from this script's own location
MODDIR=${0%/*}
export MODDIR

SSHDIR="/data/adb/ssh"

PID_FILE="${SSHDIR}/sshd.pid"
INIT_SCRIPT="${MODDIR}/opensshd.init"
SSHD_BIN="/system/bin/sshd"
SSHD_CONFIG="${SSHDIR}/sshd_config"
LOG_FILE="${SSHDIR}/sshd.log"
NO_AUTOSTART="${SSHDIR}/no-autostart"

# --- Helpers -----------------------------------------------------------------

get_pid() {
  if [ -f "$PID_FILE" ]; then
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      echo "$pid"
      return 0
    fi
  fi
  pidof sshd 2>/dev/null | awk '{print $1}'
}

toast() {
  # ksud toast support (KernelSU >= 0.6.6)
  if command -v ksud >/dev/null 2>&1; then
    ksud toast "$1" 2>/dev/null || true
  fi
  echo "$1"
}

start_sshd() {
  if [ -x "$INIT_SCRIPT" ]; then
    "$INIT_SCRIPT" start >/dev/null 2>&1
  elif [ -x "$SSHD_BIN" ]; then
    "$SSHD_BIN" -f "$SSHD_CONFIG" -E "$LOG_FILE" >/dev/null 2>&1
  else
    toast "ERROR: sshd binary not found"
    exit 1
  fi
}

stop_sshd() {
  local pid
  pid=$(get_pid)
  if [ -x "$INIT_SCRIPT" ]; then
    "$INIT_SCRIPT" stop >/dev/null 2>&1
  elif [ -n "$pid" ]; then
    kill "$pid" 2>/dev/null
    sleep 1
    pid=$(get_pid)
    [ -n "$pid" ] && kill -9 "$pid" 2>/dev/null
  fi
}

# --- Toggle ------------------------------------------------------------------

pid=$(get_pid)

if [ -n "$pid" ]; then
  # Service is running → stop it and disable autostart
  stop_sshd
  sleep 1
  pid=$(get_pid)
  if [ -z "$pid" ]; then
    toast "SSH stopped"
  else
    toast "SSH stop failed (pid still: ${pid})"
    exit 1
  fi
else
  # Service is stopped → start it and re-enable autostart
  start_sshd
  sleep 1
  pid=$(get_pid)
  if [ -n "$pid" ]; then
    # Extract port for display
    port=$(grep -i "^Port " "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}')
    [ -z "$port" ] && port="22"
    toast "SSH started on port ${port} (pid ${pid})"
  else
    toast "SSH start failed"
    exit 1
  fi
fi
