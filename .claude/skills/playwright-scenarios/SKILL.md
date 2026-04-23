---
name: playwright-scenarios
description: playwright-cliを使ったE2Eシナリオを蓄積・再利用するスキル。ログイン・フォーム操作・ナビゲーションなどのブラウザ操作を自動化し、シナリオをスクリプトとして保存して再利用する。
allowed-tools: Bash(playwright-cli *), Bash(bash *), Read, Write, Glob
---

# playwright-scenarios スキル

playwright-cli を使ったブラウザ操作シナリオを蓄積・再利用します。
同じ操作を毎回ゼロから実行するのではなく、スクリプトとして保存して次回以降は即座に実行します。

## タスク受信時のフロー（必須）

### Step 1: 既存シナリオを検索する

タスクを受け取ったとき、**必ず最初に**シナリオ一覧を確認する：

```bash
cat .claude/skills/playwright-scenarios/scenarios/README.md
```

タスク内容とシナリオ名・説明が一致する（または近似する）場合は Step 2-A へ。
見つからない場合は Step 2-B へ。

### Step 2-A: シナリオがあった場合

そのまま実行（引数が必要なら調整）：

```bash
bash .claude/skills/playwright-scenarios/scenarios/<名前>.sh [引数]
```

実行中にエラーが発生した場合は **Step 2-A-fix** へ。

### Step 2-A-fix: スクリプトが失敗したとき（実装変更への対応）

UIの変更・URLの変更・フォーム構造の変更などにより、過去のスクリプトが動作しなくなることがある。
**スクリプトを削除せず**、現在の状態に合わせて修正すること。

詳細な診断・修正手順: [references/troubleshooting.md](references/troubleshooting.md)

**基本フロー:**
1. `playwright-cli snapshot` で現在のDOM状態を確認する
2. `playwright-cli screenshot` で画面を視覚的に確認する
3. 変更箇所を特定して `.claude/skills/playwright-scenarios/scenarios/<名前>.sh` を修正する
4. 変更箇所にコメントで `# Updated: <理由>` を記録する
5. スクリプトを再実行して成功を確認する

### Step 2-B: シナリオがなかった場合

playwright-cli でブラウザ操作を実行しながら、同時にスクリプトを作成する：

1. playwright-cli でタスクを実行する
2. `scenarios/<動詞>-<対象>.sh` としてスクリプトを作成する（[シナリオの書き方](references/scenario-guide.md)参照）
3. スクリプトを実行可能にする: `chmod +x .claude/skills/playwright-scenarios/scenarios/<名前>.sh`
4. `scenarios/README.md` のシナリオ一覧テーブルを更新する

## スクリプトの書き方規則

- セッションファイルのデフォルト: `/tmp/playwright-scenarios/session.json`
- スクリーンショットのデフォルト保存先: `/tmp/playwright-scenarios/`
- `BASE_URL` を第1引数で受け取る（デフォルト値は設定してよい）
- `SESSION_FILE` を第2引数で受け取る（省略可）
- スクリプト先頭に `#!/bin/bash` と使い方コメントを書く
- `set -e` を使い、エラーで即座に終了させる

詳細: [シナリオの書き方ガイド](references/scenario-guide.md)

## リファレンス

- [シナリオの書き方ガイド](references/scenario-guide.md) — テンプレート・命名規則・引数規則
- [セッション管理](references/session-management.md) — state-save/state-load の使い方
- [よく使うパターン](references/common-patterns.md) — ログイン・フォーム操作・ナビゲーション
- [トラブルシューティング](references/troubleshooting.md) — スクリプト失敗時の診断・修正フロー
