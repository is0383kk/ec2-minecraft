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

# サーバーディレクトリをtar.gzに圧縮してバックアップを作成する関数
backup_server() {
    echo "Creating backup..."

    mkdir -p "$BACKUP_DIR"

    # 前回の一時ファイルが残っていれば削除する
    rm -f "$BACKUP_TMP"

    tar \
      --exclude="./mc_stdin.pipe" \
      --exclude="./mc_server.pid" \
      -C "$SERVER_DIR" \
      -czf "$BACKUP_TMP" \
      .

    # 一時ファイルを正式なバックアップファイルへアトミックに置き換える
    mv -f "$BACKUP_TMP" "$BACKUP_FILE"

    echo "Backup completed: $BACKUP_FILE"
}

# PIDファイルが存在しない場合、サーバーはすでに停止していると判断する
if [[ ! -f "$PIDFILE" ]]; then
    echo "PID file not found. Server may not be running."

    # すでに停止済みの場合でも、必要なら現在のファイルをバックアップする
    backup_server
    exit 0
fi

MC_PID="$(cat "$PIDFILE")"

# PIDファイルはあるがプロセスが存在しない場合は残骸ファイルを削除する
if ! kill -0 "$MC_PID" 2>/dev/null; then
    echo "Minecraft server process is not running. Cleaning up stale files."
    rm -f "$PIDFILE" "$PIPE"

    backup_server
    exit 0
fi

# FIFOが存在しない場合はコマンドを送れないためエラーで終了する
if [[ ! -p "$PIPE" ]]; then
    echo "FIFO not found: $PIPE"
    exit 1
fi

# FIFOにstopコマンドを送信してMinecraftサーバーを正常停止させる
echo "stop" > "$PIPE"
echo "Stop command sent to Minecraft server."

# サーバーが停止するまで最大180秒間1秒ごとに確認する
for i in {1..180}; do
    if ! kill -0 "$MC_PID" 2>/dev/null; then
        echo "Minecraft server stopped."

        rm -f "$PIDFILE" "$PIPE"

        backup_server
        exit 0
    fi
    sleep 1
done

# 180秒以内に停止しなかった場合はエラーで終了する
echo "Minecraft server did not stop within 180 seconds."
echo "Backup was not created because the server may still be running."
exit 1
