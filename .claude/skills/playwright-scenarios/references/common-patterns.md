# Common Patterns

Common browser automation patterns using `playwright-cli run-code`.
Use these as a reference when writing new scenario scripts.

All interactions use stable CSS selectors or Playwright locators — not `eXX` element IDs.

## Open a page and inspect the DOM

```bash
playwright-cli open "$BASE_URL/path"
playwright-cli snapshot
# → use the snapshot to identify selectors, then write run-code
```

## Login (fill form → submit → save session)

```bash
playwright-cli open "$BASE_URL"

playwright-cli run-code "async page => {
  await page.goto('${BASE_URL}/login');

  await page.fill('input[name=email]', '${USERNAME}');
  await page.fill('input[name=password]', '${PASSWORD}');
  await page.click('button[type=submit]');

  // Wait for redirect after successful login
  await page.waitForURL('**/', { timeout: 10000 });

  // Save session (cookies + localStorage + sessionStorage)
  await page.context().storageState({ path: '${SESSION_FILE}' });
  return 'Login successful';
}"
```

## Form submission

```bash
playwright-cli run-code "async page => {
  await page.goto('${BASE_URL}/contact');

  await page.fill('input[name=name]', 'John Doe');
  await page.fill('input[name=email]', 'john@example.com');
  await page.selectOption('select[name=category]', 'inquiry');
  await page.check('input[name=agree]');
  await page.click('button[type=submit]');

  // Wait for confirmation
  await page.waitForSelector('.success-message');
}"

playwright-cli screenshot --filename="$SCREENSHOT_DIR/form-submitted.png"
```

## Navigation and screenshot

```bash
playwright-cli open "$BASE_URL"

playwright-cli run-code "async page => {
  await page.goto('${BASE_URL}/dashboard');
  await page.waitForLoadState('networkidle');
}"

playwright-cli screenshot --filename="$SCREENSHOT_DIR/dashboard.png"
```

## Operate with an authenticated session

```bash
playwright-cli open "$BASE_URL"
playwright-cli state-load "$SESSION_FILE"

playwright-cli run-code "async page => {
  await page.goto('${BASE_URL}/protected-page');
  await page.waitForLoadState('networkidle');
}"

playwright-cli snapshot
```

## Get element text

```bash
playwright-cli run-code "async page => {
  const text = await page.locator('h1').textContent();
  return text;
}"
```

## Check the page title or URL

```bash
playwright-cli run-code "async page => {
  return { title: await page.title(), url: page.url() };
}"
```

## Handle a confirmation dialog

```bash
playwright-cli run-code "async page => {
  page.once('dialog', dialog => dialog.accept());
  await page.click('button.delete');
  await page.waitForSelector('.deleted-confirmation');
}"
```

## Search and click a result

```bash
playwright-cli run-code "async page => {
  await page.goto('${BASE_URL}/search');
  await page.fill('input[name=q]', '${QUERY}');
  await page.press('input[name=q]', 'Enter');
  await page.waitForSelector('.search-results');

  // Click the first result
  await page.locator('.search-result-item').first().click();
  await page.waitForLoadState('networkidle');
}"

playwright-cli screenshot --filename="$SCREENSHOT_DIR/search-result.png"
```

## Scroll

```bash
playwright-cli run-code "async page => {
  await page.evaluate(() => window.scrollBy(0, 500));   // scroll down
  await page.evaluate(() => window.scrollBy(0, -500));  // scroll up
}"
```

## Wait for an element to appear or disappear

```bash
playwright-cli run-code "async page => {
  await page.waitForSelector('.loading', { state: 'hidden' });  // wait until hidden
  await page.waitForSelector('.content', { state: 'visible' }); // wait until visible
}"
```

## Using role-based or text-based selectors (more readable)

```bash
playwright-cli run-code "async page => {
  // By role
  await page.getByRole('button', { name: 'Log in' }).click();

  // By label
  await page.getByLabel('Email').fill('user@example.com');

  // By placeholder
  await page.getByPlaceholder('Search...').fill('query');

  // By text
  await page.getByText('Submit').click();
}"
```
