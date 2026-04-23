# Common Patterns

Common browser automation patterns with playwright-cli.
Use these as a reference when writing new scenario scripts.

## Open a page and inspect the snapshot

Use this to discover element reference IDs (`eXX`) before interacting.

```bash
playwright-cli open "$BASE_URL/path"
playwright-cli snapshot
# → check the eXX numbers in the snapshot before acting
```

## Login (fill form → click → save session)

```bash
playwright-cli open "$BASE_URL/login"
playwright-cli snapshot  # confirm eXX numbers for the form fields

playwright-cli fill e1 "$USERNAME"   # username field
playwright-cli fill e2 "$PASSWORD"   # password field
playwright-cli click e3              # login button

playwright-cli state-save "$SESSION_FILE"
echo "Session saved: $SESSION_FILE"
```

## Form submission

```bash
playwright-cli open "$BASE_URL/contact"
playwright-cli snapshot

playwright-cli fill e1 "John Doe"             # text input
playwright-cli fill e2 "john@example.com"     # email input
playwright-cli select e3 "inquiry"            # select box
playwright-cli check e4                       # checkbox
playwright-cli click e5                       # submit button

playwright-cli snapshot  # confirm state after submission
playwright-cli screenshot --filename="$SCREENSHOT_DIR/form-submitted.png"
```

## Navigation and screenshot

```bash
playwright-cli open "$BASE_URL"
playwright-cli goto "$BASE_URL/dashboard"
playwright-cli screenshot --filename="$SCREENSHOT_DIR/dashboard.png"
```

## Operate with an authenticated session

```bash
playwright-cli open "$BASE_URL"
playwright-cli state-load "$SESSION_FILE"
playwright-cli goto "$BASE_URL/protected-page"
playwright-cli snapshot
```

## Get element text

```bash
playwright-cli open "$BASE_URL/page"
playwright-cli snapshot  # find the eXX number
playwright-cli eval "el => el.textContent" e5
```

## Check the page title

```bash
playwright-cli open "$BASE_URL"
playwright-cli eval "document.title"
```

## Handle a confirmation dialog

```bash
playwright-cli click e7          # button that opens the dialog
playwright-cli dialog-accept     # click OK
# or
playwright-cli dialog-dismiss    # click Cancel
```

## Search and click a result

```bash
playwright-cli open "$BASE_URL/search"
playwright-cli fill e1 "$QUERY"
playwright-cli press Enter
playwright-cli snapshot  # find eXX number for the first result
playwright-cli click e10
playwright-cli screenshot --filename="$SCREENSHOT_DIR/search-result.png"
```

## Scroll

```bash
playwright-cli mousewheel 0 500   # scroll down
playwright-cli mousewheel 0 -500  # scroll up
```
