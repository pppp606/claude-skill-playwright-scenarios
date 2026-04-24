# Request Mocking in Scenarios

Use request mocking to stub external APIs (payments, geocoding, third-party auth) while exercising real local flows.

## When to mock (and when not to)

- **Mock**: third-party services you don't control (Stripe, Google Maps, OAuth callbacks), slow or rate-limited endpoints, error states that are hard to reproduce on the live service
- **Don't mock**: your own local services — calling them for real catches integration regressions that a mock would hide

## Prefer `page.route()` inside `run-code`

Inside a scenario script, set up routes with `page.route()` via `run-code` rather than the CLI `playwright-cli route` command:

- `page.route()` keeps the mock inline with the scenario code — the registration is attached to the page object, so it's visible to anyone reading the script and travels with the scenario when copied.
- `playwright-cli route` is out-of-band session state. It persists across subsequent `playwright-cli` calls until `unroute` is run or the browser is closed, which can leak into the next scenario running against the same browser session.

Either way, routes only fully go away when the browser is closed (`playwright-cli close`). If scenarios share a long-running browser session, call `page.unroute()` at the end of `run-code` or `playwright-cli close` at the end of the script when the mock is no longer needed.

## Scenario script template

```bash
#!/bin/bash
# .claude/skills/playwright-scenarios/scenarios/<name>.sh
#
# Description: <flow that depends on mocked external APIs>
#
# Usage:
#   bash <name>.sh <BASE_URL> [SESSION_FILE]

set -e

BASE_URL="${1:?BASE_URL is required (e.g. http://localhost:3000)}"
SESSION_FILE="${2:-/tmp/playwright-scenarios/session.json}"
SCREENSHOT_DIR="/tmp/playwright-scenarios"

mkdir -p "$SCREENSHOT_DIR"
mkdir -p "$(dirname "$SESSION_FILE")"

echo "=== <scenario name> ==="

playwright-cli open "$BASE_URL"

playwright-cli run-code "async page => {
  // Mock the external API — attached to the page object
  await page.route('**/api/payments/charge', route => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ id: 'mock_txn_001', status: 'succeeded' }),
    });
  });

  // Real flow against local services
  await page.goto('${BASE_URL}/checkout');
  await page.fill('input[name=card]', '4242424242424242');
  await page.click('button[type=submit]');
  await page.waitForSelector('.payment-success');
}"

playwright-cli screenshot --filename="$SCREENSHOT_DIR/checkout-mocked.png"

echo ''
echo '=== Done ==='
```

## Cleanup note for CLI `route`

If a script deliberately uses the CLI `route` command (e.g., to keep routes active across multiple `run-code` blocks), it **must** unroute at the end to avoid cross-contaminating the next scenario:

```bash
playwright-cli route "**/api/payments/**" --body='{"status":"succeeded"}'

# ... run your flow ...

playwright-cli unroute  # remove all routes
```

## Error-state scenarios

Mocking is the most reliable way to exercise error paths. One template:

```bash
playwright-cli run-code "async page => {
  await page.route('**/api/search', route =>
    route.fulfill({ status: 500, body: 'Internal Server Error' })
  );

  await page.goto('${BASE_URL}/search');
  await page.fill('input[name=q]', 'anything');
  await page.press('input[name=q]', 'Enter');
  await page.waitForSelector('.error-message');
}"
```
