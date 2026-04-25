# claude-skill-playwright-scenarios

A Claude Code skill for accumulating and reusing E2E browser automation scenarios with playwright-cli.

## Overview

Once installed, Claude Code saves browser automation scenarios as reusable shell scripts. The next time you request the same operation, Claude runs the saved script directly — no re-investigation needed.

**Scenarios accumulate in `.claude/skills/playwright-scenarios/scenarios/`.**

## Installation

Copy `.claude/skills/playwright-scenarios/` into your project:

```bash
cp -r .claude/skills/playwright-scenarios/ /path/to/your-project/.claude/skills/playwright-scenarios/
```

### Add allowed-tools to settings.json

Add the following to `.claude/settings.json` or `.claude/settings.local.json`:

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

## Usage

Load the skill and describe your task in natural language:

```
/playwright-scenarios Log in to the app and save the session
/playwright-scenarios Fill out the contact form and submit it
/playwright-scenarios Take a screenshot of http://localhost:3000
```

## How scenario accumulation works

1. When given a task, Claude first checks `scenarios/README.md` for an existing scenario
2. If a match is found, Claude runs the saved script directly
3. If no match is found, Claude performs the task with playwright-cli and saves it as `scenarios/<name>.sh`
4. The scenario list in `scenarios/README.md` is updated automatically

The next time you request the same operation, it runs instantly without re-investigation.

## Handling broken scripts

If a saved script breaks due to UI or routing changes, Claude does **not** delete it.
Instead, Claude uses `playwright-cli snapshot` to inspect the current state, updates the script to match, and re-runs it.

See [references/troubleshooting.md](.claude/skills/playwright-scenarios/references/troubleshooting.md) for details.

## Requirements

- [playwright-cli](https://github.com/microsoft/playwright) installed and available in PATH
- [Claude Code](https://claude.ai/code) CLI

## License

MIT — see [LICENSE](./LICENSE).
