#!/usr/bin/env bash

LOG_FILE="/root/cni.log"
MONITOR_DIR="/run/cni-monitored-interfaces"
TRACING_BIN="/usr/local/bin/tracing"

handle_error() {
  local exit_code="$?"
  local message="Error occurred (exit code: $exit_code) at line ${BASH_LINENO[0]} in function ${FUNCNAME[0]}: $BASH_COMMAND"
  date +"%Y-%m-%d %H:%M:%S" >> "$LOG_FILE"
  echo "ERROR: $message" >> "$LOG_FILE"
}
trap handle_error ERR

start_tracing() {
  local iface="$1"
  local PID_FILE="/run/tracing-$iface.pid"

  if [ -e "$PID_FILE" ]; then
    echo "Tracing process for $iface already exists." >> "$LOG_FILE"
    return
  fi

  echo "Starting tracing for interface: $iface" >> "$LOG_FILE"
  RUST_LOG=info nohup "$TRACING_BIN" --iface "$iface" > "/root/cni-tracing-$iface.log" 2>&1 &
  echo $! > "$PID_FILE"
  echo "Tracing process for $iface started with PID: $(cat "$PID_FILE")" >> "$LOG_FILE"
}

stop_tracing() {
  local iface="$1"
  local pid_file="/run/tracing-$iface.pid"

  if [ ! -e "$pid_file" ]; then
    echo "No tracing process found for interface: $iface" >> "$LOG_FILE"
    return
  fi

  local PID=$(cat "$pid_file")
  echo "Stopping tracing process for interface: $iface (PID: $PID)" >> "$LOG_FILE"
  kill -15 "$PID"
  sleep 1
  if ps -p "$PID" > /dev/null; then
    echo "Tracing process for $iface did not terminate gracefully. Sending SIGKILL." >> "$LOG_FILE"
    kill -9 "$PID"
  fi
  rm -f "$pid_file"
  echo "Tracing process for $iface stopped." >> "$LOG_FILE"
}

for iface_file in "$MONITOR_DIR"/*; do
  iface=$(basename "$iface_file")
  start_tracing "$iface"
done

inotifywait -m -q -e create,delete "$MONITOR_DIR" |
  while read -r event file; do
    iface=$(basename "$file")
    case "$event" in
      CREATE)
        start_tracing "$iface"
        ;;
      DELETE)
        stop_tracing "$iface"
        ;;
    esac
  done
