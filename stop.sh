#!/usr/bin/env bash
set -Eeuo pipefail

SERVER_DIR="/home/minecraft/server"
PIPE="$SERVER_DIR/mc_stdin.pipe"
PIDFILE="$SERVER_DIR/mc_server.pid"

if [[ ! -f "$PIDFILE" ]]; then
    echo "PID file not found. Server may not be running."
    exit 0
fi

MC_PID="$(cat "$PIDFILE")"

if ! kill -0 "$MC_PID" 2>/dev/null; then
    echo "Minecraft server process is not running. Cleaning up stale files."
    rm -f "$PIDFILE" "$PIPE"
    exit 0
fi

if [[ ! -p "$PIPE" ]]; then
    echo "FIFO not found: $PIPE"
    exit 1
fi

echo "stop" > "$PIPE"
echo "Stop command sent to Minecraft server."

# systemdのExecStopは、停止要求だけでなく実際の終了まで待つのが重要
for i in {1..180}; do
    if ! kill -0 "$MC_PID" 2>/dev/null; then
        echo "Minecraft server stopped."
        exit 0
    fi
    sleep 1
done

echo "Minecraft server did not stop within 180 seconds."
exit 1
