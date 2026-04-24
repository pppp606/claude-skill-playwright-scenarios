# Troubleshooting

This is the diagnosis and fix flow (Step 2-A-fix) for when a saved scenario script fails.

Scripts may break due to UI changes, URL changes, or form structure changes.
**Do not delete the script** — update it to match the current state.

## Step 2-A-fix flow

### 1. Identify the error

Read the playwright-cli error message to determine the cause.

```bash
# Take a DOM snapshot to inspect the current page structure
playwright-cli snapshot

# Visually confirm the current page
playwright-cli screenshot --filename=/tmp/playwright-scenarios/debug.png

# Get the raw HTML for deeper inspection
playwright-cli run-code "async page => { return await page.content() }"

# Check the current URL (confirm you're on the right page)
playwright-cli run-code "async page => { return page.url() }"
```

### 2. Locate and fix the issue

Update the selectors or URLs in the script to match the current page state.

```bash
# Edit the script and annotate each changed line:
# Updated: <reason (e.g. selector changed from input[name=email] to input[type=email])>
```

### 3. Re-run and confirm

```bash
bash .claude/skills/playwright-scenarios/scenarios/<name>.sh "$BASE_URL"
```

If successful, update the description in `scenarios/README.md` if needed.

---

## Common failure patterns and fixes

### Selector no longer matches

**Symptom:** `Error: locator.fill: Error: strict mode violation` or timeout waiting for element

**Fix:**
1. Run `playwright-cli snapshot` to inspect the current DOM
2. Identify the new selector for the target element
3. Update the selector in the `run-code` block

```bash
# playwright-cli run-code "async page => { await page.fill('input[name=email]', ...) }"
# Updated: attribute changed from name=email to type=email
playwright-cli run-code "async page => { await page.fill('input[type=email]', ...) }"
```

### URL changed (routing change)

**Symptom:** `waitForURL` times out, or page navigates to an unexpected URL

**Fix:**
1. Check the actual URL after the action: `playwright-cli run-code "async page => { return page.url() }"`
2. Update the URL path or `waitForURL` pattern in the script

```bash
# await page.waitForURL('**/dashboard');
# Updated: dashboard moved to /home
# await page.waitForURL('**/home');
```

### Form structure changed (fields added or removed)

**Symptom:** Form submits with validation errors, or a required field is missing

**Fix:**
1. Run `playwright-cli snapshot` to see all current form fields
2. Add `page.fill()` for new required fields; remove calls for deleted fields

### Login flow changed (e.g. 2FA added)

**Symptom:** `waitForURL` times out after clicking submit — an extra step appeared

**Fix:**
1. Run `playwright-cli snapshot` after clicking submit to see the new UI
2. Add the new step to the `run-code` block

```bash
playwright-cli run-code "async page => {
  // ... existing login steps ...
  await page.click('button[type=submit]');

  // Updated: 2FA step added
  await page.waitForSelector('input[name=otp]');
  await page.fill('input[name=otp]', '${OTP_CODE}');
  await page.click('button[type=submit]');

  await page.waitForURL('**/', { timeout: 10000 });
  await page.context().storageState({ path: '${SESSION_FILE}' });
}"
```

### Session expired

**Symptom:** Accessing a protected page redirects to the login page

**Fix:** Re-run the login scenario to refresh the session:

```bash
bash .claude/skills/playwright-scenarios/scenarios/login.sh "$BASE_URL" "$SESSION_FILE"
```

---

## Useful debugging commands

```bash
# Take a DOM snapshot (visual overview of the page structure)
playwright-cli snapshot

# Take a screenshot
playwright-cli screenshot --filename=/tmp/playwright-scenarios/debug.png

# Get the raw HTML
playwright-cli run-code "async page => { return await page.content() }"

# Check the current URL and title
playwright-cli run-code "async page => { return { url: page.url(), title: await page.title() } }"

# List all input fields on the page
playwright-cli run-code "async page => {
  return await page.evaluate(() =>
    Array.from(document.querySelectorAll('input, select, textarea')).map(el => ({
      tag: el.tagName,
      type: el.type,
      name: el.name,
      id: el.id,
      placeholder: el.placeholder
    }))
  );
}"

# Check console errors
playwright-cli console

# Inspect network requests
playwright-cli network
```

## Tracing (full timeline of actions)

When `snapshot` and `screenshot` don't reveal where a multi-step `run-code` block failed, record a trace: it captures every action, DOM snapshots at each step, and the network timeline, all replayable offline.

```bash
playwright-cli tracing-start

# ... run the failing scenario (or just the failing block) ...

playwright-cli tracing-stop --filename=/tmp/playwright-scenarios/trace.zip

# Replay the trace
npx playwright show-trace /tmp/playwright-scenarios/trace.zip
```

## Video recording (for dynamic issues)

For flash toasts, scroll-triggered layout bugs, or animations that `screenshot` can't capture, record a video:

```bash
playwright-cli video-start
# ... reproduce the issue ...
playwright-cli video-stop /tmp/playwright-scenarios/debug.webm
```
