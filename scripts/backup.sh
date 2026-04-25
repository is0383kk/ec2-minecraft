#!/usr/bin/env bash
set -Eeuo pipefail

# サーバーのファイルが格納されているディレクトリ
SERVER_DIR="/home/minecraft/server"
# サーバーへコマンドを送るための名前付きパイプ(FIFO)のパス
PIPE="$SERVER_DIR/mc_stdin.pipe"
# 実行中サーバーのプロセスIDを保存するファイルのパス
PIDFILE="$SERVER_DIR/mc_server.pid"

# バックアップの保存先ディレクトリ
BACKUP_DIR="/home/minecraft/backups"
# 最新バックアップの出力先ファイルパス
BACKUP_FILE="$BACKUP_DIR/minecraft-latest.tar.gz"
# バックアップ作成中の一時ファイルパス（完了後に正式ファイルへ置き換える）
BACKUP_TMP="$BACKUP_DIR/minecraft-latest.tar.gz.tmp"
# 同時実行を防ぐためのロックファイルパス
LOCKFILE="$BACKUP_DIR/backup.lock"

mkdir -p "$BACKUP_DIR"

# ロックファイルをFD9に開き、排他ロックを取得する
# 取得できなければ別のバックアップが実行中なのでスキップする
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "Another backup is already running. Skipping."
    exit 0
fi

# FIFOにコマンドを1行送信するヘルパー関数
send_cmd() {
    local cmd="$1"
    printf '%s\n' "$cmd" > "$PIPE"
}

# PIDファイルが存在しない場合はサーバーが起動していないと判断してスキップする
if [[ ! -f "$PIDFILE" ]]; then
    echo "PID file not found. Server may not be running. Skipping backup."
    exit 0
fi

MC_PID="$(cat "$PIDFILE")"

# PIDファイルはあるがプロセスが存在しない場合もスキップする
if ! kill -0 "$MC_PID" 2>/dev/null; then
    echo "Minecraft server process is not running. Skipping backup."
    exit 0
fi

# FIFOが存在しない場合はコマンドを送れないためエラーで終了する
if [[ ! -p "$PIPE" ]]; then
    echo "FIFO not found: $PIPE"
    exit 1
fi

# save-off済みかどうかを示すフラグ（0:未実行、1:実行済み）
SAVE_OFF=0

# スクリプト終了時にsave-offが残ったままにならないよう、save-onを送信する
cleanup() {
    if [[ "$SAVE_OFF" -eq 1 ]]; then
        echo "Re-enabling world saving..."
        send_cmd "save-on" || true
    fi
}
trap cleanup EXIT

# ワールドへの書き込みを一時停止してバックアップ中のデータ不整合を防ぐ
echo "Disabling world saving..."
send_cmd "save-off"
SAVE_OFF=1

# メモリ上のワールドデータをディスクに書き出す
echo "Flushing world data..."
send_cmd "save-all flush"

# save-all flush の完了をFIFOだけでは直接検知できないため少し待つ
sleep 10

echo "Creating backup..."

# 前回の一時ファイルが残っていれば削除する
rm -f "$BACKUP_TMP"

tar \
  --exclude="./mc_stdin.pipe" \
  --exclude="./mc_server.pid" \
  --exclude="./logs" \
  --exclude="./backup.lock" \
  -C "$SERVER_DIR" \
  -czf "$BACKUP_TMP" \
  .

# 一時ファイルを正式なバックアップファイルへアトミックに置き換える
mv -f "$BACKUP_TMP" "$BACKUP_FILE"

# ワールドへの書き込みを再開する
echo "Re-enabling world saving..."
send_cmd "save-on"
SAVE_OFF=0

echo "Backup completed: $BACKUP_FILE"
