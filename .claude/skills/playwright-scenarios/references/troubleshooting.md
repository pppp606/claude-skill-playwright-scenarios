# Troubleshooting

This is the diagnosis and fix flow (Step 2-A-fix) for when a saved scenario script fails.

Scripts may break due to UI changes, URL changes, or form structure changes.
**Do not delete the script** — update it to match the current state.

## Step 2-A-fix flow

### 1. Identify the error

Read the playwright-cli error message to determine the cause.

```bash
# Inspect the current DOM state (check for element ID changes)
playwright-cli snapshot

# Visually confirm the current page
playwright-cli screenshot --filename=/tmp/playwright-scenarios/debug.png
```

### 2. Locate and fix the issue

Update the script's element references or URLs to match the current page state.

```bash
# Edit the script and annotate each changed line:
# Updated: <reason (e.g. login button ID changed from e23 to e31)>
```

### 3. Re-run and confirm

```bash
bash .claude/skills/playwright-scenarios/scenarios/<name>.sh "$BASE_URL"
```

If successful, update the description in `scenarios/README.md` if needed.

---

## Common failure patterns and fixes

### Element ID changed (`fill e19` → `fill e23`)

**Symptom:** Error like `Error: Element not found: e19`

**Fix:**
1. Run `playwright-cli snapshot` to inspect the current DOM
2. Identify the new ID for the target field
3. Update the `eXX` references in the script

```bash
# playwright-cli fill e19 "$USERNAME"  # Updated: ID changed e19→e23
playwright-cli fill e23 "$USERNAME"
```

### URL changed (routing change)

**Symptom:** Page returns 404 or redirects unexpectedly, causing actions to fail

**Fix:**
1. Open the base URL and check the actual current URL
2. Update the URL path in the script

```bash
# playwright-cli open "$BASE_URL/login"  # Updated: /login → /auth/login
playwright-cli open "$BASE_URL/auth/login"
```

### Form structure changed (fields added or removed)

**Symptom:** Submission fails or shows validation errors

**Fix:**
1. Run `playwright-cli snapshot` to inspect all `input` elements
2. Add inputs for new fields; remove actions for deleted fields

### Login flow changed (e.g. 2FA added)

**Symptom:** An additional step appears after login before the session can be saved

**Fix:**
1. Run `playwright-cli snapshot` to inspect the new UI
2. Walk through the new flow manually and capture the steps
3. Add the new steps to the script

### Session expired

**Symptom:** Accessing an authenticated page redirects to the login page

**Fix:** Re-run the login scenario to refresh the session:

```bash
bash .claude/skills/playwright-scenarios/scenarios/login.sh "$BASE_URL" "$SESSION_FILE"
```

---

## Useful debugging commands

```bash
# Take a DOM snapshot
playwright-cli snapshot

# Take a screenshot
playwright-cli screenshot --filename=/tmp/playwright-scenarios/debug.png

# Check the current URL and page title
playwright-cli eval "location.href"
playwright-cli eval "document.title"

# Check console errors
playwright-cli console

# Inspect network requests
playwright-cli network
```
