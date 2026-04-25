#!/usr/bin/env bash
set -Eeuo pipefail

MINECRAFT_USER="${MINECRAFT_USER:-minecraft}"
MINECRAFT_GROUP="${MINECRAFT_GROUP:-minecraft}"

SERVER_DIR="${SERVER_DIR:-/home/minecraft/server}"
BACKUP_DIR="${BACKUP_DIR:-/home/minecraft/backups}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"
SERVICES_DIR="$REPO_DIR/services"

START_SERVICE_NAME="minecraft.service"
BACKUP_SERVICE_NAME="minecraft-backup.service"
BACKUP_TIMER_NAME="minecraft-backup.timer"

START_SERVICE_SRC="$SERVICES_DIR/$START_SERVICE_NAME"
BACKUP_SERVICE_SRC="$SERVICES_DIR/$BACKUP_SERVICE_NAME"
BACKUP_TIMER_SRC="$SERVICES_DIR/$BACKUP_TIMER_NAME"

# typo 互換: minecrat.service が存在する場合も拾う
if [[ ! -f "$START_SERVICE_SRC" && -f "$SERVICES_DIR/minecrat.service" ]]; then
    echo "WARNING: services/minecrat.service found. Installing it as minecraft.service."
    START_SERVICE_SRC="$SERVICES_DIR/minecrat.service"
fi

need_file() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "ERROR: required file not found: $path" >&2
        exit 1
    fi
}

need_dir() {
    local path="$1"
    if [[ ! -d "$path" ]]; then
        echo "ERROR: required directory not found: $path" >&2
        exit 1
    fi
}

if [[ "${EUID}" -ne 0 ]]; then
    echo "Re-running with sudo..."
    exec sudo \
      MINECRAFT_USER="$MINECRAFT_USER" \
      MINECRAFT_GROUP="$MINECRAFT_GROUP" \
      SERVER_DIR="$SERVER_DIR" \
      BACKUP_DIR="$BACKUP_DIR" \
      bash "$0" "$@"
fi

need_dir "$SCRIPTS_DIR"
need_dir "$SERVICES_DIR"

need_file "$SCRIPTS_DIR/start.sh"
need_file "$SCRIPTS_DIR/stop.sh"
need_file "$SCRIPTS_DIR/backup.sh"

need_file "$START_SERVICE_SRC"
need_file "$BACKUP_SERVICE_SRC"
need_file "$BACKUP_TIMER_SRC"

echo "Installing Minecraft server configuration..."
echo "Repo:        $REPO_DIR"
echo "User:        $MINECRAFT_USER"
echo "Server dir:  $SERVER_DIR"
echo "Backup dir:  $BACKUP_DIR"

if ! id "$MINECRAFT_USER" >/dev/null 2>&1; then
    echo "Creating user: $MINECRAFT_USER"
    adduser --disabled-password --gecos "" "$MINECRAFT_USER"
fi

if ! getent group "$MINECRAFT_GROUP" >/dev/null 2>&1; then
    echo "Creating group: $MINECRAFT_GROUP"
    groupadd "$MINECRAFT_GROUP"
fi

install -d -o "$MINECRAFT_USER" -g "$MINECRAFT_GROUP" -m 0755 "$SERVER_DIR"
install -d -o "$MINECRAFT_USER" -g "$MINECRAFT_GROUP" -m 0755 "$BACKUP_DIR"

echo "Installing scripts..."
install -o "$MINECRAFT_USER" -g "$MINECRAFT_GROUP" -m 0755 "$SCRIPTS_DIR/start.sh"  "$SERVER_DIR/start.sh"
install -o "$MINECRAFT_USER" -g "$MINECRAFT_GROUP" -m 0755 "$SCRIPTS_DIR/stop.sh"   "$SERVER_DIR/stop.sh"
install -o "$MINECRAFT_USER" -g "$MINECRAFT_GROUP" -m 0755 "$SCRIPTS_DIR/backup.sh" "$SERVER_DIR/backup.sh"

echo "Installing systemd service files..."
install -o root -g root -m 0644 "$START_SERVICE_SRC"  "/etc/systemd/system/$START_SERVICE_NAME"
install -o root -g root -m 0644 "$BACKUP_SERVICE_SRC" "/etc/systemd/system/$BACKUP_SERVICE_NAME"
install -o root -g root -m 0644 "$BACKUP_TIMER_SRC"   "/etc/systemd/system/$BACKUP_TIMER_NAME"

echo "Reloading systemd..."
systemctl daemon-reload

echo "Enabling services..."
systemctl enable "$START_SERVICE_NAME"
systemctl enable --now "$BACKUP_TIMER_NAME"

echo "Checking systemd unit files..."
systemctl cat "$START_SERVICE_NAME" >/dev/null
systemctl cat "$BACKUP_SERVICE_NAME" >/dev/null
systemctl cat "$BACKUP_TIMER_NAME" >/dev/null

echo
echo "Installation completed."
echo
echo "Next commands:"
echo "  sudo systemctl start minecraft.service"
echo "  sudo systemctl status minecraft.service"
echo "  sudo systemctl status minecraft-backup.timer"
echo "  sudo journalctl -u minecraft.service -f"
