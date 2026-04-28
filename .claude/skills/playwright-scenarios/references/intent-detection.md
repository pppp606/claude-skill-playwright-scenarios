# Intent detection

When a saved scenario fails, the skill must decide whether to auto-fix the script
or refuse and surface the failure as a likely regression. Auto-fixing a regression
silently rewrites the scenario to match broken app behavior — this hides bugs.

This file defines the gate that runs **before** any fix in [troubleshooting.md](./troubleshooting.md).

## Outcomes of the gate

| Verdict | Meaning | Action |
|---|---|---|
| `INTENTIONAL` | The failing element/route was deliberately changed in app code since the scenario last passed. | Auto-fix the scenario. Annotate each change with `# Updated: <reason> (per <SHA>: "<msg>")`. |
| `REGRESSION SUSPECTED` | App code changed since last pass, but the failing element/route was **not** directly touched. The break is a likely side effect. | **Do not modify the scenario.** Report suspect commits to the user. |
| `ENVIRONMENTAL` | No relevant app code changed since last pass. The break is data, infra, or external service related. | **Do not modify the scenario.** Report as likely env/data issue. |
| `UNVERIFIED` | No `last-pass` anchor exists, or the scenario itself was edited since last pass. | Ask the user before auto-fixing. |

## Inputs the gate consumes

- `scenarios/.last-pass/<name>.json` — `{ "sha": "<HEAD>", "at": "<ISO>", "branch": "<name>" }` written by the scenario tail on success.
- The scenario's header metadata:
  - `# Outcome:` — success conditions (parsed by [assert-outcome.sh](./assert-outcome.sh)).
  - `# AppPaths:` (optional) — comma-separated paths to narrow git-log search.
  - `# AppRepo:` (optional) — path to the app repo if it differs from the scenario repo. Falls back to `APP_REPO_PATH` env, then current repo.
- The error message from the failed run (extract failure artifacts: selector tokens, URL path, expected text).
- Console / network errors captured during the run (`playwright-cli console`, `playwright-cli network`).

## Decision flow

Run the steps in order. The first step that produces a verdict wins.

### Step 0 — Runtime sanity (highest priority)

If the failing run produced any of:

- A JavaScript exception in `playwright-cli console`
- An HTTP 5xx on the route under test in `playwright-cli network`
- A page returning a server error template

→ Verdict: `REGRESSION SUSPECTED`. Stop. Do not run any pickaxe analysis — the app
itself is erroring, not the selectors.

```bash
playwright-cli console | grep -iE 'error|exception|uncaught'
playwright-cli network | grep -E ' (5[0-9]{2}) '
```

### Step 1 — Flake guard

Re-run the scenario once. If it passes on retry, treat as flake. Update last-pass
and proceed normally. Only failures that reproduce on retry continue to Step 2.

### Step 2 — Self-edit check

If the scenario script itself was edited since the last-pass anchor, the anchor
is meaningless (the user may have already adjusted the scenario by hand).

```bash
git log <last-pass-sha>..HEAD -- .claude/skills/playwright-scenarios/scenarios/<name>.sh
```

→ If non-empty: Verdict: `UNVERIFIED`. Ask the user.

### Step 3 — Resolve the last-pass anchor

```bash
SHA=$(jq -r .sha scenarios/.last-pass/<name>.json)
AT=$(jq -r .at  scenarios/.last-pass/<name>.json)
BRANCH=$(jq -r .branch scenarios/.last-pass/<name>.json)
```

Validate the anchor:

```bash
# Is the SHA still reachable from HEAD?
if git merge-base --is-ancestor "$SHA" HEAD 2>/dev/null; then
  ANCHOR="$SHA"
elif [ -n "$BRANCH" ] && [ "$BRANCH" != "$(git branch --show-current)" ]; then
  # Branch switch: walk from the merge-base of the two branches
  ANCHOR=$(git merge-base "$BRANCH" HEAD)
else
  # Rebase/squash invalidated SHA — fall back to timestamp
  ANCHOR=$(git log --since="$AT" --reverse --format=%H | head -1)^ 2>/dev/null || ANCHOR=""
fi
```

If `ANCHOR` is empty or the file `scenarios/.last-pass/<name>.json` is missing:
→ Verdict: `UNVERIFIED`. Ask the user.

### Step 4 — Pickaxe with multiple tokens (OR, not AND)

Extract failure artifacts from the error message. For a selector like
`input[name=email]`, derive several tokenized variants and OR the search:

| Failure artifact | Tokens to search |
|---|---|
| `input[name=email]` | `name=.?email`, `email`, plus the page URL |
| `button[type=submit]` | `type=.?submit`, the button label if known |
| URL `/login` | `/login`, `login` |
| Expected text `'Welcome'` | `Welcome` (also try the i18n key if guessable) |

Search each token across `<AppPaths>` (or the whole repo minus `scenarios/`,
`tests/`, `.claude/` if `# AppPaths:` is unset):

```bash
APP_PATHS=${APP_PATHS:-"."}
for token in "${TOKENS[@]}"; do
  git -C "$APP_REPO" log "$ANCHOR..HEAD" --pickaxe-regex -G "$token" \
    --format='%h %s' -- $APP_PATHS
done | sort -u
```

OR the hits together. Any commit appearing for any token is a candidate.

### Step 5 — Classify

- **Direct hit**: at least one candidate commit touches the failing element/route.
  → Verdict: `INTENTIONAL`. Auto-fix. Annotate each change with the matching
  commit's SHA + first-line message.

- **No artifact hit, but app changed**: no token matched, but `<AppPaths>` plus
  lockfiles (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Gemfile.lock`,
  `Cargo.lock`, `go.sum`, etc.) or root-level config (`next.config.*`,
  `tsconfig.json`, `vite.config.*`, `middleware.*`, `.env*`) changed since
  anchor.
  → Verdict: `REGRESSION SUSPECTED`. Do **not** modify the scenario. Report:

  ```
  Scenario "<name>" failed. The failing form/route was not directly modified
  since the last successful run, but these commits may have caused a side
  effect:
    abc1234  chore(deps): bump react to 19.2
    def5678  refactor: extract auth context
  Treat as a regression and investigate before re-running.
  ```

  ```bash
  CHANGED_PATHS=$(git -C "$APP_REPO" log "$ANCHOR..HEAD" --name-only --format= | sort -u)
  echo "$CHANGED_PATHS" | grep -E '(lock\.json|lock\.yaml|\.lock|\.sum|next\.config|tsconfig|vite\.config|middleware|\.env)'
  ```

- **Nothing changed at all** since anchor in `<AppPaths>`, lockfiles, or config:
  → Verdict: `ENVIRONMENTAL`. Do **not** modify the scenario. Report as
  likely data/env/external-service issue.

### Step 6 — Commit prefix as bias, not gate

Conventional Commit prefixes are **only used to break ties** when Step 5 is
ambiguous (e.g., a candidate commit touches `<AppPaths>` but not the exact
artifact tokens). Bias direction:

| Prefix | Bias |
|---|---|
| `feat:`, `refactor:`, `ui:`, `style(ui):` | +1 toward `INTENTIONAL` |
| `fix:`, `revert:`, `chore(deps):`, `perf:` | no bias |

Never gate on prefix alone — repos that don't use Conventional Commits get
reasonable behavior because the prefix only acts as a tiebreaker.

### Step 7 — Outcome verification (post-fix only)

After auto-fix completes, re-run the scenario and run [assert-outcome.sh](./assert-outcome.sh)
on its `# Outcome:` declaration. If the outcome assertion fails, **escalate to
the user even if Step 5 said `INTENTIONAL`** — the auto-fix produced a green
script that no longer satisfies the declared goal, which is a stronger signal
than git history.

## Handling cross-repo apps

If `# AppRepo:` or `APP_REPO_PATH` is set, run all `git` commands with
`-C "$APP_REPO"`. If unset and `BASE_URL` is non-localhost (i.e., scenario
targets a deployed environment with no local repo), downgrade the verdict to
`UNVERIFIED` and ask the user — git history isn't accessible.

## Reporting templates

When the verdict is **not** `INTENTIONAL`, do not edit the scenario. Print:

```
Scenario: <name>
Verdict:  <REGRESSION SUSPECTED | ENVIRONMENTAL | UNVERIFIED>
Failure:  <one-line summary of the playwright-cli error>
Anchor:   <last-pass SHA> (<at>) on <branch>
Evidence:
  <suspect commits, or "no app changes since anchor", or "no last-pass record">
Action:   The scenario was NOT modified. Investigate before re-running.
```
