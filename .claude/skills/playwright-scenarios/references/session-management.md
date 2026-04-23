# Session Management

playwright-cli can save and restore browser sessions (login state, cookies, etc.) to a file.

## Saving a session

```bash
# Save to the default path
playwright-cli state-save

# Save to a specific path
playwright-cli state-save /tmp/playwright-scenarios/session.json
```

What gets saved: cookies, LocalStorage, SessionStorage

## Restoring a session

```bash
playwright-cli state-load /tmp/playwright-scenarios/session.json
```

After restoring, you can interact with pages as an authenticated user.

## Usage in scenarios

### Login and save session (login scenario)

```bash
playwright-cli open "$BASE_URL/login"
playwright-cli fill e1 "$USERNAME"
playwright-cli fill e2 "$PASSWORD"
playwright-cli click e3
playwright-cli state-save "$SESSION_FILE"
echo "Session saved: $SESSION_FILE"
```

### Use a saved session in another scenario

```bash
playwright-cli open "$BASE_URL"
playwright-cli state-load "$SESSION_FILE"
playwright-cli goto "$BASE_URL/dashboard"
playwright-cli snapshot
```

## Session file path convention

This skill uses the following default path:

- Default: `/tmp/playwright-scenarios/session.json`
- Project-specific: can be overridden via the `SESSION_FILE` argument

## Session expiry

Session files store browser cookies as-is, so they depend on the server-side session expiry.
If you get an authentication error, re-run the login scenario to refresh the session:

```bash
bash .claude/skills/playwright-scenarios/scenarios/login.sh "$BASE_URL" "$SESSION_FILE"
```
