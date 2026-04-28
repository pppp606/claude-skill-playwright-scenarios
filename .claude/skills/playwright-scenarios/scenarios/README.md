# Scenarios

A list of accumulated E2E scenario scripts in this directory.
Update this table whenever you add a new scenario.

## Scenario list

| File | Description | Arguments |
|------|-------------|-----------|
| examples/login.sh | Log in and save session (sample implementation) | BASE_URL [SESSION_FILE] |

## Adding a new scenario

1. Create `scenarios/<verb>-<target>.sh` (see [Scenario Writing Guide](../references/scenario-guide.md))
2. Make it executable: `chmod +x scenarios/<name>.sh`
3. Add a row to the table above
4. Run it once successfully so `.last-pass/<name>.json` is written

## .last-pass/

Each successful run writes a per-machine anchor to `.last-pass/<name>.json`
(gitignored). The auto-fix gate uses this anchor to decide whether a later
failure is intentional drift or a regression. See [Intent Detection](../references/intent-detection.md).

## Chaining scenarios with a session

For scenarios that require authentication, save the session with a login scenario first:

```bash
# 1. Log in and save the session
bash .claude/skills/playwright-scenarios/scenarios/login.sh http://localhost:3000

# 2. Run another scenario using the saved session
bash .claude/skills/playwright-scenarios/scenarios/<name>.sh http://localhost:3000
```
