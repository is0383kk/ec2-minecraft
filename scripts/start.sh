#!/usr/bin/env bash
set -Eeuo pipefail

# サーバーのファイルが格納されているディレクトリ
SERVER_DIR="/home/minecraft/server"
# 起動するPaperMCのJARファイル名
JAR="paper-26.1.2-22.jar"
# サーバーへコマンドを送るための名前付きパイプ(FIFO)のパス
PIPE="$SERVER_DIR/mc_stdin.pipe"
# 実行中サーバーのプロセスIDを保存するファイルのパス
PIDFILE="$SERVER_DIR/mc_server.pid"

cd "$SERVER_DIR"

# PIDファイルが存在する場合、すでにサーバーが起動しているか確認する
if [[ -f "$PIDFILE" ]]; then
    OLD_PID="$(cat "$PIDFILE" || true)"
    # PIDファイルに記載されたプロセスが生きていれば二重起動を防ぐ
    if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Minecraft server is already running. PID: $OLD_PID"
        exit 1
    fi
    # プロセスが存在しない場合は古いPIDファイルを削除する
    rm -f "$PIDFILE"
fi

# 古いパイプが残っていれば削除し、新しいFIFOを作成する
rm -f "$PIPE"
mkfifo "$PIPE"
# オーナーのみ読み書き可能にする
chmod 600 "$PIPE"

# スクリプト終了時にパイプとPIDファイルを削除するクリーンアップ関数
cleanup() {
    exec 3>&- 2>/dev/null || true
    rm -f "$PIPE" "$PIDFILE"
}
trap cleanup EXIT

# FIFOを開いたままにして、Minecraft側stdinがEOFにならないようにする
exec 3<>"$PIPE"

# MinecraftサーバーをFIFOをstdinとして起動し、バックグラウンドで実行する
java -Xms512M -Xmx1200M -jar "$JAR" nogui < "$PIPE" &
MC_PID=$!

# 起動したプロセスのPIDをファイルに保存する
echo "$MC_PID" > "$PIDFILE"

# サーバープロセスが終了するまで待機する
wait "$MC_PID"
