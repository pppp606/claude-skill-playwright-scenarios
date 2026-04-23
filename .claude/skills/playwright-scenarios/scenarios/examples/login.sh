#!/bin/bash
# .claude/skills/playwright-scenarios/scenarios/examples/login.sh
#
# Sample: Log in and save the session
#
# This is a sample implementation. To use it in your project, copy it to
# scenarios/ and adjust the element IDs and URL to match your application.
#
# Note: playwright-cli element IDs (e1, e2, etc.) change with each page render.
#       Always run `playwright-cli snapshot` to confirm the current IDs before use.
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

mkdir -p "$SCREENSHOT_DIR"
mkdir -p "$(dirname "$SESSION_FILE")"

echo "=== Login scenario (sample) ==="
echo "BASE_URL: $BASE_URL"
echo "SESSION_FILE: $SESSION_FILE"

# Open the login page
# Update the URL path to match your project
playwright-cli open "$BASE_URL/login"
playwright-cli snapshot

# --- Project-specific section ---
# Check the snapshot output to find the actual eXX numbers for your project.
#
# Example (IDs vary by project):
#   playwright-cli fill e1 "$USERNAME"   # username/email field
#   playwright-cli fill e2 "$PASSWORD"   # password field
#   playwright-cli click e3              # login button
#
# If USERNAME or PASSWORD are not provided, the fields are left empty.
# Set project-specific defaults here if needed.
if [ -n "$USERNAME" ]; then
  playwright-cli fill e1 "$USERNAME"
fi
if [ -n "$PASSWORD" ]; then
  playwright-cli fill e2 "$PASSWORD"
fi
playwright-cli click e3
# --- End project-specific section ---

# Save the session
playwright-cli state-save "$SESSION_FILE"

# Take a screenshot of the post-login page
playwright-cli screenshot --filename="$SCREENSHOT_DIR/login-result.png"

echo ""
echo "=== Done ==="
echo "Session: $SESSION_FILE"
echo "Screenshot: $SCREENSHOT_DIR/login-result.png"
echo ""
echo "To use this session in another scenario:"
echo "  playwright-cli state-load $SESSION_FILE"
