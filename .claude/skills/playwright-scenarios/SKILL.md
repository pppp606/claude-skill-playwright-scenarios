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

Past scripts may break due to UI changes, URL changes, or form structure changes.
**Do not delete the script** — update it to match the current state.

Detailed diagnosis and fix steps: [references/troubleshooting.md](references/troubleshooting.md)

**Basic flow:**
1. Run `playwright-cli snapshot` to inspect the current DOM state
2. Run `playwright-cli screenshot` to visually confirm the current page
3. Identify the changes and update `.claude/skills/playwright-scenarios/scenarios/<name>.sh`
4. Add a comment `# Updated: <reason>` at each changed line
5. Re-run the script and confirm it succeeds

### Step 2-B: No scenario found

Execute the task with playwright-cli while simultaneously creating a script:

1. Perform the task using playwright-cli
2. Save the script as `scenarios/<verb>-<target>.sh` (see [Scenario Writing Guide](references/scenario-guide.md))
3. Make it executable: `chmod +x .claude/skills/playwright-scenarios/scenarios/<name>.sh`
4. Update the scenario list table in `scenarios/README.md`

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
- [Session Management](references/session-management.md) — how to use state-save/state-load
- [Common Patterns](references/common-patterns.md) — login, form submission, navigation
- [Troubleshooting](references/troubleshooting.md) — diagnosing and fixing broken scripts
