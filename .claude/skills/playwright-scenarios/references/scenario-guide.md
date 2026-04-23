# Scenario Writing Guide

## Naming convention

Use the format `<verb>-<target>.sh`.

```
login.sh                   # log in
logout.sh                  # log out
submit-contact-form.sh     # submit a contact form
follow-user.sh             # follow a user
search-and-click-result.sh # search and click a result
```

## Script template

```bash
#!/bin/bash
# .claude/skills/playwright-scenarios/scenarios/<name>.sh
#
# Description: <one-line description of what this script does>
#
# Usage:
#   bash <name>.sh <BASE_URL> [SESSION_FILE]
#
# Examples:
#   bash <name>.sh http://localhost:3000
#   bash <name>.sh http://localhost:3000 /tmp/myapp/session.json
#
# After completion:
#   <describe the resulting state, e.g. session saved to SESSION_FILE>

set -e

BASE_URL="${1:?BASE_URL is required (e.g. http://localhost:3000)}"
SESSION_FILE="${2:-/tmp/playwright-scenarios/session.json}"
SCREENSHOT_DIR="/tmp/playwright-scenarios"

mkdir -p "$SCREENSHOT_DIR"

echo "=== <scenario name> ==="

# playwright-cli commands go here
playwright-cli open "$BASE_URL"
playwright-cli snapshot

# ...actions...

echo ""
echo "=== Done ==="
```

## Argument rules

| Argument | Variable | Required | Description |
|----------|----------|----------|-------------|
| 1st | `BASE_URL` | Yes | Base URL to access (e.g. `http://localhost:3000`) |
| 2nd | `SESSION_FILE` | No | Session save path (default: `/tmp/playwright-scenarios/session.json`) |

- Use `:?` for `BASE_URL` to enforce the requirement with an error message
- A project-specific default URL is allowed (e.g. `${1:-http://localhost:3000}`)

## Error handling

- Add `set -e` at the top so the script exits immediately if a playwright-cli command fails
- Write user-facing error messages to stderr: `echo "ERROR: ..." >&2`

## After saving a scenario

1. Make it executable:
   ```bash
   chmod +x .claude/skills/playwright-scenarios/scenarios/<name>.sh
   ```

2. Add a row to `scenarios/README.md`:
   ```markdown
   | <name>.sh | <description> | BASE_URL [SESSION_FILE] |
   ```
