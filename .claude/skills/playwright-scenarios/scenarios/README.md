# シナリオ一覧

このディレクトリに蓄積されたE2Eシナリオスクリプトの一覧です。
新しいシナリオを追加したとき、このテーブルを更新してください。

## シナリオ

| ファイル | 説明 | 引数 |
|---------|------|------|
| examples/login.sh | ログインしてセッション保存（サンプル実装） | BASE_URL [SESSION_FILE] |

## 新しいシナリオを追加するとき

1. `scenarios/<動詞>-<対象>.sh` を作成する（[シナリオの書き方ガイド](../references/scenario-guide.md)参照）
2. `chmod +x scenarios/<名前>.sh` で実行可能にする
3. このテーブルに行を追加する

## セッションを使うシナリオの連携

認証が必要なシナリオは、先にログインシナリオでセッションを保存してから実行します：

```bash
# 1. ログインしてセッション保存
bash .claude/skills/playwright-scenarios/scenarios/login.sh http://localhost:3000

# 2. 認証済みセッションで他のシナリオを実行
bash .claude/skills/playwright-scenarios/scenarios/<名前>.sh http://localhost:3000
```
