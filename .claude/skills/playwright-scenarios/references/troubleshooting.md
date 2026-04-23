# トラブルシューティング

保存済みシナリオスクリプトが失敗した場合の診断・修正フロー（Step 2-A-fix）です。

UIの変更・URLの変更・フォーム構造の変更などにより、過去のスクリプトが動作しなくなることがあります。
**スクリプトを削除せず**、現在の状態に合わせて修正してください。

## Step 2-A-fix フロー

### 1. エラー内容を確認する

playwright-cli のエラーメッセージを読み、原因を特定します。

```bash
# 現在のDOM状態を確認（要素IDの変化を確認）
playwright-cli snapshot

# 画面を視覚的に確認
playwright-cli screenshot --filename=/tmp/playwright-scenarios/debug.png
```

### 2. 原因を特定して修正する

スクリプトを削除せず、現在の画面状態に合わせて要素参照・URLを更新します。

```bash
# スクリプトを編集
# 変更箇所に以下のコメントを追記する:
# Updated: <理由（例: ログインボタンのIDがe23→e31に変わった）>
```

### 3. 修正後に再実行して確認する

```bash
bash .claude/skills/playwright-scenarios/scenarios/<名前>.sh "$BASE_URL"
```

成功したら `scenarios/README.md` の説明も必要に応じて更新します。

---

## よくある失敗パターンと対処

### 要素IDが変わった（`fill e19` → `fill e23`）

**症状:** `Error: Element not found: e19` のようなエラー

**対処:**
1. `playwright-cli snapshot` で現在のDOM状態を確認
2. 対象フィールドの新しいIDを特定
3. スクリプトの `eXX` を新しい番号に更新

```bash
# 修正例
# playwright-cli fill e19 "$USERNAME"  # Updated: ID変更 e19→e23
playwright-cli fill e23 "$USERNAME"
```

### URLが変わった（ルーティング変更）

**症状:** ページが404になる、またはリダイレクトされて操作が失敗する

**対処:**
1. `playwright-cli open "$BASE_URL"` で実際のURLを確認
2. スクリプトのURLパスを更新

```bash
# 修正例
# playwright-cli open "$BASE_URL/login"  # Updated: /login → /auth/login に変更
playwright-cli open "$BASE_URL/auth/login"
```

### フォームの構造が変わった（フィールド追加/削除）

**症状:** 送信が成功しない、またはバリデーションエラーが出る

**対処:**
1. `playwright-cli snapshot` で全 `input` 要素を確認
2. 新しいフィールドへの入力を追加、不要になったフィールドを削除

### ログインフローが変わった（2段階認証追加など）

**症状:** ログイン後に追加のステップが現れてセッション保存前に止まる

**対処:**
1. `playwright-cli snapshot` で追加されたUIを確認
2. 手動で操作しながら新しいフローをキャプチャ
3. スクリプトに新しいステップを追加

### セッションが切れている

**症状:** 認証済みページにアクセスするとログインページにリダイレクトされる

**対処:** ログインシナリオを再実行してセッションを更新する

```bash
bash .claude/skills/playwright-scenarios/scenarios/login.sh "$BASE_URL" "$SESSION_FILE"
```

---

## デバッグに役立つコマンド

```bash
# 現在のDOMスナップショットを取得
playwright-cli snapshot

# スクリーンショットを撮る
playwright-cli screenshot --filename=/tmp/playwright-scenarios/debug.png

# ページのURLとタイトルを確認
playwright-cli eval "location.href"
playwright-cli eval "document.title"

# コンソールエラーを確認
playwright-cli console

# ネットワークリクエストを確認
playwright-cli network
```
