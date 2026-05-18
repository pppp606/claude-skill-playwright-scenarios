---
name: playwright-scenarios
description: A Claude Code skill for accumulating and reusing E2E browser automation scenarios with playwright-cli. Automates browser interactions like login, form submission, and navigation, then saves them as reusable scripts.
allowed-tools: Bash(playwright-cli *), Bash(bash *), Read, Write, Glob
---

# playwright-scenarios skill

Accumulates and reuses browser automation scenarios built with playwright-cli.
Instead of executing the same operations from scratch every time, saves them as scripts for instant reuse.

## Required flow when receiving a task

### Step 1: Search for existing scenarios

When receiving a task, **always start** by checking the scenario list:

```bash
cat .claude/skills/playwright-scenarios/scenarios/README.md
```

If the task matches an existing scenario name or description, proceed to Step 2-A.
Otherwise, proceed to Step 2-B.

### Step 2-A: Scenario found

Run it directly (adjust arguments as needed):

```bash
bash .claude/skills/playwright-scenarios/scenarios/<name>.sh [args]
```

If an error occurs during execution, proceed to **Step 2-A-fix**.

### Step 2-A-fix: Script failed (handling implementation changes)

Past scripts may break due to two very different causes, and the response must
differ:

- **Intentional app change** (UI redesign, route rename, field renamed): the
  scenario is stale and should be auto-fixed.
- **Regression / side effect** (an unrelated change broke the feature, JS error,
  500 response, lockfile bump): the scenario is **correct**, the app is broken.
  Auto-fixing the scenario here would silently hide the bug.

**Always run the [intent check](references/intent-detection.md) before editing
the scenario.** Start with the deterministic helper:

```bash
bash .claude/skills/playwright-scenarios/references/detect-intent.sh \
  .claude/skills/playwright-scenarios/scenarios/<name>.sh
```

Then combine its output with Step 0 (runtime sanity), the pickaxe search,
classification, and bias rules in [intent-detection.md](references/intent-detection.md)
to land on one of four verdicts:

| Verdict | Action |
|---|---|
| `INTENTIONAL` | Proceed with the fix flow below. |
| `REGRESSION SUSPECTED` | **Do not modify the script.** Report the suspect commits to the user and stop. |
| `ENVIRONMENTAL` | **Do not modify the script.** Report as likely env/data issue. |
| `UNVERIFIED` | Ask the user before auto-fixing. |

Detailed diagnosis and fix steps: [references/troubleshooting.md](references/troubleshooting.md)

**Fix flow (only when verdict is `INTENTIONAL`):**
1. Run `playwright-cli snapshot` to inspect the current DOM state
2. Run `playwright-cli screenshot` to visually confirm the current page
3. Identify the changes and update `.claude/skills/playwright-scenarios/scenarios/<name>.sh`
4. Add a comment `# Updated: <reason> (per <SHA>: "<msg>")` at each changed line, citing the commit the intent check matched
5. Re-run the script. The tail will run [assert-outcome.sh](references/assert-outcome.sh) — if the declared `# Outcome:` no longer holds, escalate to the user even though the intent check said `INTENTIONAL`.

### Step 2-B: No scenario found

Execute the task with playwright-cli. Then decide **what (if anything) to save** — see [Scenario granularity](#scenario-granularity) below.

1. Perform the task using playwright-cli
2. **Identify the reusable boundary.** Save only the prefix that a future task would replay verbatim. If nothing in the task is reusable (one-off bug repro, PR-specific verification, exploratory inspection), **skip saving entirely** — go to step 6.
3. Save the reusable prefix as `scenarios/<verb>-<target>.sh` (see [Scenario Writing Guide](references/scenario-guide.md))
4. Make it executable: `chmod +x .claude/skills/playwright-scenarios/scenarios/<name>.sh`
5. Update the scenario list table in `scenarios/README.md`
6. Continue with the task-specific tail using `playwright-cli` directly. Do not save the tail.

## Scenario granularity

A scenario covers **a reusable operation**, not "everything done this session." Most tasks split:

```
[ reusable prefix ]  →  [ task-specific tail ]
 login / navigate /      verification clicks,
 seed / open page        task-specific assertions,
                         exploratory inspection
```

**Save the prefix. Discard the tail.** The prefix ends the moment the page/data is ready for inspection — before any task-specific clicking or assertion. A good prefix scenario terminates with a screenshot and a `# Outcome:` that matches the resulting URL/state.

**When nothing is reusable**, skip saving. A non-replayable scenario only adds noise to `scenarios/README.md`.

**Compose, don't duplicate.** A new prefix scenario can chain an earlier one as its first step (`bash login.sh "$BASE_URL" "$SESSION_FILE"`) instead of re-implementing it.

**Naming hints for prefix scenarios:**

| Prefix | Use for | Example |
|---|---|---|
| `login-*` / `login.sh` | Session creation | `login.sh` |
| `goto-*` | Navigation to a stable URL | `goto-user-profile.sh` |
| `open-*` | Multi-step navigation (clicks, dialogs) | `open-post-create-dialog.sh` |
| `seed-*` | Data preparation via the app | `seed-test-post.sh` |

Avoid `verify-*` / `test-*` / `check-*` — these imply assertions, which belong to the task tail.

See [Scenario Writing Guide → Scenario granularity](references/scenario-guide.md#scenario-granularity) for what-to-save / what-not-to-save tables and a composition example.

## Script writing rules

- Default session file: `/tmp/playwright-scenarios/session.json`
- Default screenshot directory: `/tmp/playwright-scenarios/`
- Accept `BASE_URL` as the first argument (a default value is allowed)
- Accept `SESSION_FILE` as the second argument (optional)
- Start scripts with `#!/bin/bash` and a usage comment
- Use `set -e` to exit immediately on error
- **Do not use `playwright-cli fill/click/select` with `eXX` element IDs** — they change on every render
- **Use `playwright-cli run-code "async page => { ... }"` for all browser interactions** — target elements with CSS selectors, roles, or text
- Save sessions with `page.context().storageState({ path: '...' })` inside `run-code`

Details: [Scenario Writing Guide](references/scenario-guide.md)

## References

- [Scenario Writing Guide](references/scenario-guide.md) — templates, naming conventions, argument rules
- [Intent Detection](references/intent-detection.md) — gate that decides whether a failed scenario is auto-fixable or a likely regression
- [Session Management](references/session-management.md) — how to use state-save/state-load
- [Common Patterns](references/common-patterns.md) — login, form submission, navigation
- [Request Mocking](references/request-mocking.md) — stubbing external APIs inside scenarios
- [Troubleshooting](references/troubleshooting.md) — diagnosing and fixing broken scripts
