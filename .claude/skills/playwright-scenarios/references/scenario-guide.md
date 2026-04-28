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
# Outcome: url=**/expected-path
# AppPaths: app/<feature>/, components/<feature>/
# AppRepo:  (optional) /absolute/path/to/app/repo if it differs from this repo
# TrustLevel: unverified
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAST_PASS_DIR="$SCRIPT_DIR/.last-pass"
SCENARIO_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

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

# Verify the declared outcome and record last-pass on success.
bash "$SCRIPT_DIR/../references/assert-outcome.sh" "${BASH_SOURCE[0]}"

mkdir -p "$LAST_PASS_DIR"
TMP=$(mktemp "$LAST_PASS_DIR/.${SCENARIO_NAME}.XXXXXX")
printf '{"sha":"%s","at":"%s","branch":"%s"}\n' \
  "$(git rev-parse HEAD 2>/dev/null || echo unknown)" \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  "$(git branch --show-current 2>/dev/null || echo unknown)" \
  > "$TMP"
mv "$TMP" "$LAST_PASS_DIR/$SCENARIO_NAME.json"

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

## Header metadata

Every scenario declares a small header that the auto-fix gate consumes:

| Header | Required | Meaning |
|---|---|---|
| `# Outcome:` | yes | Success conditions verified by [assert-outcome.sh](./assert-outcome.sh). Currently supports `url=<glob>`, `text="<literal>"`, `storage=<key>`. Unknown keys log a `WARN` and are skipped — additions to this DSL are intended to be additive and won't break existing scenarios. |
| `# AppPaths:` | recommended | Comma-separated paths used to narrow the git-log search when classifying failures. If omitted, the gate searches the whole repo minus `scenarios/`, `tests/`, `.claude/`. |
| `# AppRepo:` | optional | Absolute path to the app repo when scenarios live outside it. Falls back to `APP_REPO_PATH` env, then the current repo. |
| `# TrustLevel: unverified` | starting state | Set on a new scenario; remove (or leave — it's informational) once the first successful run writes a `last-pass` anchor. |

The gate is documented in [intent-detection.md](./intent-detection.md). Without
a `# Outcome:` header, the scenario tail will fail to assert success and no
last-pass anchor will be written, leaving the scenario `UNVERIFIED` forever.

## last-pass anchor

The tail of the template writes `scenarios/.last-pass/<name>.json` on success.
This file is the reference point used by the auto-fix gate to decide whether a
later failure is INTENTIONAL, REGRESSION SUSPECTED, or ENVIRONMENTAL. It is
gitignored — last-pass is per-machine state, not shared across the team.

> **Adopting this skill in another repo?** The skill's own `.gitignore` only
> covers this repository. In your project, add the path
> `.claude/skills/playwright-scenarios/scenarios/.last-pass/` to your repo's
> `.gitignore` so anchors stay out of source control.

## After saving a scenario

1. Make it executable:
   ```bash
   chmod +x .claude/skills/playwright-scenarios/scenarios/<name>.sh
   ```

2. Add a row to `scenarios/README.md`:
   ```markdown
   | <name>.sh | <description> | BASE_URL [SESSION_FILE] |
   ```

3. Run it once successfully so the `.last-pass/<name>.json` anchor is written.
   Until that file exists, the scenario is treated as `UNVERIFIED` and any
   future failure will fall back to user confirmation rather than auto-fix.
