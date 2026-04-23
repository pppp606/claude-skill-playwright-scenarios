# claude-skill-playwright-scenarios

playwright-cli を使ったブラウザ操作シナリオを蓄積・再利用するための Claude Code スキルです。

## 概要

このスキルを導入すると、Claude Code が playwright-cli を使って操作したブラウザのシナリオをスクリプトとして保存します。同じ操作を再度依頼すると、調査なしでスクリプトをそのまま実行します。

**シナリオは `.claude/skills/playwright-scenarios/scenarios/` に蓄積されます。**

## インストール

`.claude/skills/playwright-scenarios/` をプロジェクトのリポジトリにコピーします。

```bash
cp -r .claude/skills/playwright-scenarios/ /path/to/your-project/.claude/skills/playwright-scenarios/
```

### `settings.json` に allowed-tools を追加

`.claude/settings.json` または `.claude/settings.local.json` に以下を追加：

```json
{
  "permissions": {
    "allow": [
      "Bash(playwright-cli *)",
      "Bash(bash *)"
    ]
  }
}
```

## 使い方

スキルをロードしてから自然言語でタスクを伝えるだけです。

```
/playwright-scenarios ログインページでログインしてセッションを保存してください
/playwright-scenarios フォームに名前とメールを入力して送信してください
/playwright-scenarios http://localhost:3000 のトップページをスクリーンショットしてください
```

## シナリオが蓄積される仕組み

1. タスクを受け取ると、まず `scenarios/README.md` で既存シナリオを検索します
2. 一致するシナリオがあれば、そのスクリプトをそのまま実行します
3. なければ playwright-cli で操作を実行し、`scenarios/<名前>.sh` として保存します
4. `scenarios/README.md` のシナリオ一覧を更新します

次回同じ操作を依頼すると、ゼロから調査せずにスクリプトを直接実行します。

## 前提条件

- playwright-cli がインストール済み
- Claude Code CLI

## ライセンス

MIT
