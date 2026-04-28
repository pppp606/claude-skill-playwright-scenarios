#!/bin/bash
# .claude/skills/playwright-scenarios/scenarios/examples/login.sh
#
# Sample: Log in and save the session
#
# This is a sample implementation. To use it in your project, copy it to
# scenarios/ and adjust the selectors and URL path to match your application.
#
# NOTE: this script lives at scenarios/examples/login.sh, so the two paths
# below (LAST_PASS_DIR and the assert-outcome.sh invocation) walk up one
# extra level. If you copy this file to scenarios/login.sh, change them to:
#   LAST_PASS_DIR="$SCRIPT_DIR/.last-pass"
#   bash "$SCRIPT_DIR/../references/assert-outcome.sh" "${BASH_SOURCE[0]}"
#
# Outcome: url=**/ storage=auth_token
# AppPaths: app/login/, components/auth/
# TrustLevel: unverified
#
# Usage:
#   bash examples/login.sh <BASE_URL> [SESSION_FILE] [USERNAME] [PASSWORD]
#
# Examples:
#   bash examples/login.sh http://localhost:3000
#   bash examples/login.sh http://localhost:3000 /tmp/myapp/session.json
#   bash examples/login.sh http://localhost:3000 /tmp/myapp/session.json admin secret
#
# After completion:
#   Session is saved to SESSION_FILE
#   Other scenarios can restore it with: playwright-cli state-load <SESSION_FILE>

set -e

BASE_URL="${1:?BASE_URL is required (e.g. http://localhost:3000)}"
SESSION_FILE="${2:-/tmp/playwright-scenarios/session.json}"
USERNAME="${3:-}"
PASSWORD="${4:-}"
SCREENSHOT_DIR="/tmp/playwright-scenarios"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAST_PASS_DIR="$SCRIPT_DIR/../.last-pass"
SCENARIO_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

mkdir -p "$SCREENSHOT_DIR"
mkdir -p "$(dirname "$SESSION_FILE")"

echo "=== Login scenario (sample) ==="
echo "BASE_URL: $BASE_URL"
echo "SESSION_FILE: $SESSION_FILE"

playwright-cli open "$BASE_URL"

playwright-cli run-code "async page => {
  // Navigate to the login page — adjust the path to match your project
  await page.goto('${BASE_URL}/login');

  // Fill credentials using stable CSS selectors (not eXX element IDs)
  // Adjust these selectors to match your project's login form.
  // Tips: run \`playwright-cli snapshot\` first to inspect the form structure.
  //
  // Alternative selector styles:
  //   await page.getByLabel('Email').fill('${USERNAME}');
  //   await page.getByRole('button', { name: 'Log in' }).click();
  if ('${USERNAME}') await page.fill('input[name=email]', '${USERNAME}');
  if ('${PASSWORD}') await page.fill('input[name=password]', '${PASSWORD}');
  await page.click('button[type=submit]');

  // Wait for successful login — adjust the URL pattern to match your project
  await page.waitForURL('**/', { timeout: 10000 });

  // Save session (cookies + localStorage + sessionStorage)
  await page.context().storageState({ path: '${SESSION_FILE}' });
  return 'Login successful';
}"

playwright-cli screenshot --filename="$SCREENSHOT_DIR/login-result.png"

# Verify the declared outcome and record last-pass on success.
bash "$SCRIPT_DIR/../../references/assert-outcome.sh" "${BASH_SOURCE[0]}"

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
echo "Session: $SESSION_FILE"
echo "Screenshot: $SCREENSHOT_DIR/login-result.png"
echo ""
echo "To use this session in another scenario:"
echo "  playwright-cli state-load $SESSION_FILE"
