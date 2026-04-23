# セッション管理

playwright-cli はログイン状態などのブラウザセッションをファイルに保存・復元できます。

## セッションの保存

```bash
# デフォルトパスに保存
playwright-cli state-save

# パスを指定して保存
playwright-cli state-save /tmp/playwright-scenarios/session.json
```

保存されるもの: Cookie、LocalStorage、SessionStorage

## セッションの復元

```bash
playwright-cli state-load /tmp/playwright-scenarios/session.json
```

復元後は認証済み状態でページを操作できます。

## シナリオでの使い方

### ログインしてセッション保存（login シナリオ）

```bash
playwright-cli open "$BASE_URL/login"
playwright-cli fill e1 "$USERNAME"
playwright-cli fill e2 "$PASSWORD"
playwright-cli click e3
playwright-cli state-save "$SESSION_FILE"
echo "セッション保存: $SESSION_FILE"
```

### 保存済みセッションを使って操作（他のシナリオ）

```bash
playwright-cli open "$BASE_URL"
playwright-cli state-load "$SESSION_FILE"
playwright-cli goto "$BASE_URL/dashboard"
playwright-cli snapshot
```

## セッションファイルのパス規則

このスキルでは以下のデフォルトパスを使用します：

- デフォルト: `/tmp/playwright-scenarios/session.json`
- プロジェクト固有: 引数 `SESSION_FILE` で上書き可能

## セッションの有効期限

セッションファイルはブラウザのCookieをそのまま保存するため、サーバー側のセッション有効期限に依存します。セッション切れエラーが発生した場合はログインシナリオを再実行してください。

```bash
bash .claude/skills/playwright-scenarios/scenarios/login.sh "$BASE_URL" "$SESSION_FILE"
```
