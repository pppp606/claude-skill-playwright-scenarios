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
mkdir -p "$(dirname "$SESSION_FILE")"

echo "=== <scenario name> ==="

playwright-cli open "$BASE_URL"

playwright-cli run-code "async page => {
  await page.goto('${BASE_URL}/path');

  // Target elements with CSS selectors, roles, or text — never eXX IDs
  await page.fill('input[name=email]', 'value');
  await page.click('button[type=submit]');
  await page.waitForURL('**/expected-path');
}"

playwright-cli screenshot --filename="$SCREENSHOT_DIR/result.png"

echo ""
echo "=== Done ==="
```

## Why run-code instead of fill/click/select?

`playwright-cli fill e19 "value"` uses element IDs (`eXX`) that change on every page render.
A script saved today may fail tomorrow because `e19` no longer exists.

`playwright-cli run-code` uses Playwright's stable selectors:
- CSS selectors: `input[name=email]`, `button[type=submit]`, `.submit-btn`
- Role selectors: `page.getByRole('button', { name: 'Log in' })`
- Text selectors: `page.getByText('Submit')`

These are tied to the actual DOM structure, not a transient render ID.

## Argument rules

| Argument | Variable | Required | Description |
|----------|----------|----------|-------------|
| 1st | `BASE_URL` | Yes | Base URL to access (e.g. `http://localhost:3000`) |
| 2nd | `SESSION_FILE` | No | Session save path (default: `/tmp/playwright-scenarios/session.json`) |

- Use `:?` for `BASE_URL` to enforce the requirement with an error message
- Shell variables are expanded inside double-quoted `run-code` strings: `"async page => { ... '${BASE_URL}' ... }"`

## Session saving inside run-code

Use `page.context().storageState()` to save the session from within `run-code`:

```bash
playwright-cli run-code "async page => {
  // ... login actions ...
  await page.context().storageState({ path: '${SESSION_FILE}' });
  return 'Session saved';
}"
```

## Error handling

- Add `set -e` at the top so the script exits immediately if any command fails
- Write user-facing error messages to stderr: `echo "ERROR: ..." >&2`
- Use `try/catch` inside `run-code` for recoverable errors

## After saving a scenario

1. Make it executable:
   ```bash
   chmod +x .claude/skills/playwright-scenarios/scenarios/<name>.sh
   ```

2. Add a row to `scenarios/README.md`:
   ```markdown
   | <name>.sh | <description> | BASE_URL [SESSION_FILE] |
   ```
