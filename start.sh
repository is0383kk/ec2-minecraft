#!/usr/bin/env bash
set -Eeuo pipefail

SERVER_DIR="/home/minecraft/server"
JAR="paper-26.1.2-22.jar"
PIPE="$SERVER_DIR/mc_stdin.pipe"
PIDFILE="$SERVER_DIR/mc_server.pid"

cd "$SERVER_DIR"

if [[ -f "$PIDFILE" ]]; then
    OLD_PID="$(cat "$PIDFILE" || true)"
    if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Minecraft server is already running. PID: $OLD_PID"
        exit 1
    fi
    rm -f "$PIDFILE"
fi

rm -f "$PIPE"
mkfifo "$PIPE"
chmod 600 "$PIPE"

cleanup() {
    exec 3>&- 2>/dev/null || true
    rm -f "$PIPE" "$PIDFILE"
}
trap cleanup EXIT

# FIFOを開いたままにして、Minecraft側stdinがEOFにならないようにする
exec 3<>"$PIPE"

java -Xms512M -Xmx1200M -jar "$JAR" nogui < "$PIPE" &
MC_PID=$!

echo "$MC_PID" > "$PIDFILE"

wait "$MC_PID"
