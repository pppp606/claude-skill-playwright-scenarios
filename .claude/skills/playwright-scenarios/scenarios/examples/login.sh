#!/bin/bash
# .claude/skills/playwright-scenarios/scenarios/examples/login.sh
#
# サンプル: ログインしてセッションを保存する
#
# このファイルはサンプル実装です。実際のプロジェクトで使う場合は、
# scenarios/ 直下にコピーして要素ID・URLをプロジェクトに合わせて修正してください。
#
# 注意: playwright-cli の要素ID（e1, e2 など）は操作のたびに変わります。
#       実際に使う前に `playwright-cli snapshot` でIDを確認してください。
#
# 使い方:
#   bash examples/login.sh <BASE_URL> [SESSION_FILE] [USERNAME] [PASSWORD]
#
# 例:
#   bash examples/login.sh http://localhost:3000
#   bash examples/login.sh http://localhost:3000 /tmp/myapp/session.json
#   bash examples/login.sh http://localhost:3000 /tmp/myapp/session.json admin secret
#
# 完了後:
#   セッションが SESSION_FILE に保存される
#   以降のシナリオで playwright-cli state-load <SESSION_FILE> で利用可能

set -e

BASE_URL="${1:?BASE_URLを指定してください（例: http://localhost:3000）}"
SESSION_FILE="${2:-/tmp/playwright-scenarios/session.json}"
USERNAME="${3:-}"
PASSWORD="${4:-}"
SCREENSHOT_DIR="/tmp/playwright-scenarios"

mkdir -p "$SCREENSHOT_DIR"
mkdir -p "$(dirname "$SESSION_FILE")"

echo "=== ログインシナリオ（サンプル） ==="
echo "BASE_URL: $BASE_URL"
echo "SESSION_FILE: $SESSION_FILE"

# ログインページを開く
# プロジェクトに合わせてURLパスを変更してください
playwright-cli open "$BASE_URL/login"
playwright-cli snapshot

# --- ここからプロジェクト固有の設定 ---
# snapshot の出力で実際の eXX 番号を確認してから入力してください
#
# 例（プロジェクトによって番号が異なります）:
#   playwright-cli fill e1 "$USERNAME"   # ユーザー名/メールフィールド
#   playwright-cli fill e2 "$PASSWORD"   # パスワードフィールド
#   playwright-cli click e3              # ログインボタン
#
# ユーザー名が未指定の場合は空のまま（各プロジェクトでデフォルト値を設定してください）
if [ -n "$USERNAME" ]; then
  playwright-cli fill e1 "$USERNAME"
fi
if [ -n "$PASSWORD" ]; then
  playwright-cli fill e2 "$PASSWORD"
fi
playwright-cli click e3
# --- ここまでプロジェクト固有の設定 ---

# セッションを保存
playwright-cli state-save "$SESSION_FILE"

# ログイン後のページをスクリーンショット
playwright-cli screenshot --filename="$SCREENSHOT_DIR/login-result.png"

echo ""
echo "=== 完了 ==="
echo "セッション: $SESSION_FILE"
echo "スクリーンショット: $SCREENSHOT_DIR/login-result.png"
echo ""
echo "次のシナリオで使う場合:"
echo "  playwright-cli state-load $SESSION_FILE"
