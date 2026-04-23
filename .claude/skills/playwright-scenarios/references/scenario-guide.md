# シナリオの書き方ガイド

## 命名規則

`<動詞>-<対象>.sh` の形式で命名する。

```
login.sh                   # ログイン
logout.sh                  # ログアウト
submit-contact-form.sh     # お問い合わせフォームを送信
follow-user.sh             # ユーザーをフォロー
search-and-click-result.sh # 検索して結果をクリック
```

## スクリプトテンプレート

```bash
#!/bin/bash
# .claude/skills/playwright-scenarios/scenarios/<名前>.sh
#
# 説明: <このスクリプトが何をするか1行で>
#
# 使い方:
#   bash <名前>.sh <BASE_URL> [SESSION_FILE]
#
# 例:
#   bash <名前>.sh http://localhost:3000
#   bash <名前>.sh http://localhost:3000 /tmp/myapp/session.json
#
# 完了後:
#   <完了後の状態を記述（例: セッションが SESSION_FILE に保存される）>

set -e

BASE_URL="${1:?BASE_URLを指定してください（例: http://localhost:3000）}"
SESSION_FILE="${2:-/tmp/playwright-scenarios/session.json}"
SCREENSHOT_DIR="/tmp/playwright-scenarios"

mkdir -p "$SCREENSHOT_DIR"

echo "=== <シナリオ名> ==="

# ここに playwright-cli コマンドを記述
playwright-cli open "$BASE_URL"
playwright-cli snapshot

# ...操作...

echo ""
echo "=== 完了 ==="
```

## 引数規則

| 引数 | 変数名 | 必須 | 説明 |
|-----|--------|------|------|
| 第1引数 | `BASE_URL` | 必須 | アクセス先のベースURL（例: `http://localhost:3000`） |
| 第2引数 | `SESSION_FILE` | 任意 | セッション保存先（デフォルト: `/tmp/playwright-scenarios/session.json`） |

- `BASE_URL` は `:?` でエラーメッセージ付きの必須チェックを行う
- プロジェクト固有のデフォルトURLを設定してもよい（`${1:-http://localhost:3000}`）

## エラー処理

- `set -e` を先頭に記述し、playwright-cli コマンドが失敗したらスクリプトを終了させる
- ユーザー向けのエラーメッセージは `echo "ERROR: ..." >&2` で標準エラーに出力する

## シナリオ保存後の手順

1. 実行可能にする:
   ```bash
   chmod +x .claude/skills/playwright-scenarios/scenarios/<名前>.sh
   ```

2. `scenarios/README.md` のテーブルに追記する:
   ```markdown
   | <名前>.sh | <説明> | BASE_URL [SESSION_FILE] |
   ```
