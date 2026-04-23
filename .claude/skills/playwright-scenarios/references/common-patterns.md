# よく使うパターン

playwright-cli でよく使うブラウザ操作パターンをまとめます。
スクリプト作成時の参考にしてください。

## ページを開いてスナップショット確認

要素の参照ID（`eXX`）を確認するためのパターン。

```bash
playwright-cli open "$BASE_URL/path"
playwright-cli snapshot
# → スナップショットで eXX の番号を確認してから操作する
```

## ログイン（フォーム入力 → クリック → セッション保存）

```bash
playwright-cli open "$BASE_URL/login"
playwright-cli snapshot  # フォームの eXX 番号を確認

playwright-cli fill e1 "$USERNAME"   # ユーザー名フィールド
playwright-cli fill e2 "$PASSWORD"   # パスワードフィールド
playwright-cli click e3              # ログインボタン

playwright-cli state-save "$SESSION_FILE"
echo "セッション保存: $SESSION_FILE"
```

## フォーム送信

```bash
playwright-cli open "$BASE_URL/contact"
playwright-cli snapshot

playwright-cli fill e1 "山田太郎"          # テキスト入力
playwright-cli fill e2 "taro@example.com" # メール入力
playwright-cli select e3 "inquiry"         # セレクトボックス
playwright-cli check e4                    # チェックボックス
playwright-cli click e5                    # 送信ボタン

playwright-cli snapshot  # 送信後の状態を確認
playwright-cli screenshot --filename="$SCREENSHOT_DIR/form-submitted.png"
```

## ナビゲーションとスクリーンショット

```bash
playwright-cli open "$BASE_URL"
playwright-cli goto "$BASE_URL/dashboard"
playwright-cli screenshot --filename="$SCREENSHOT_DIR/dashboard.png"
```

## 認証済みセッションで操作

```bash
playwright-cli open "$BASE_URL"
playwright-cli state-load "$SESSION_FILE"
playwright-cli goto "$BASE_URL/protected-page"
playwright-cli snapshot
```

## 要素のテキストを取得

```bash
playwright-cli open "$BASE_URL/page"
playwright-cli snapshot  # eXX 番号を確認
playwright-cli eval "el => el.textContent" e5
```

## ページタイトルの確認

```bash
playwright-cli open "$BASE_URL"
playwright-cli eval "document.title"
```

## ダイアログ（確認ダイアログ）への対応

```bash
playwright-cli click e7              # ダイアログを開くボタン
playwright-cli dialog-accept         # OK をクリック
# または
playwright-cli dialog-dismiss        # キャンセルをクリック
```

## 検索フォームで検索して結果をクリック

```bash
playwright-cli open "$BASE_URL/search"
playwright-cli fill e1 "$QUERY"
playwright-cli press Enter
playwright-cli snapshot  # 検索結果の eXX 番号を確認
playwright-cli click e10  # 最初の検索結果をクリック
playwright-cli screenshot --filename="$SCREENSHOT_DIR/search-result.png"
```

## スクロール

```bash
playwright-cli mousewheel 0 500   # 下にスクロール
playwright-cli mousewheel 0 -500  # 上にスクロール
```
