#!/bin/bash
# .claude/skills/playwright-scenarios/references/assert-outcome.sh
#
# Verify a scenario reached its declared outcome.
#
# Reads the `# Outcome:` line from the scenario script, parses key=value
# assertions, and runs them against the current playwright-cli session.
# Exits 0 when every assertion passes, non-zero otherwise.
#
# Supported keys (space-separated on the # Outcome: line):
#   url=<glob>            page.url() must match the glob (Playwright glob:
#                         ** any chars incl. /, * any chars excl. /, ? one char)
#   text="<literal>"      the literal text must be visible on the page
#   storage=<key>         localStorage must contain <key> with a non-empty value
#
# Quote text values with double quotes if they contain spaces.
# Unknown keys are logged as a warning and skipped — additions to this DSL
# are intended to be additive and won't break existing scenarios.
#
# Usage:
#   bash assert-outcome.sh <scenario.sh>
#
# Example outcome line inside a scenario:
#   # Outcome: url=**/dashboard text="Welcome" storage=auth_token

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-outcome.sh
source "$SCRIPT_DIR/lib-outcome.sh"

SCENARIO="${1:?scenario script path required}"

if [ ! -f "$SCENARIO" ]; then
  echo "ERROR: $SCENARIO not found" >&2
  exit 2
fi

OUTCOME_LINE=$(grep -m1 -E '^#\s*Outcome:' "$SCENARIO" | sed -E 's/^#\s*Outcome:\s*//')

if [ -z "$OUTCOME_LINE" ]; then
  echo "ERROR: $SCENARIO has no '# Outcome:' header" >&2
  exit 2
fi

# Tokenize: split on whitespace but keep quoted values intact.
declare -a ASSERTIONS=()
while IFS= read -r tok; do
  [ -n "$tok" ] && ASSERTIONS+=("$tok")
done < <(printf '%s' "$OUTCOME_LINE" | awk '{
  while (match($0, /[a-z_]+="[^"]*"|[a-z_]+=[^[:space:]]+/)) {
    print substr($0, RSTART, RLENGTH);
    $0 = substr($0, RSTART + RLENGTH);
  }
}')

if [ ${#ASSERTIONS[@]} -eq 0 ]; then
  echo "ERROR: '# Outcome:' line is empty in $SCENARIO" >&2
  exit 2
fi

FAILED=0

# Wrap a JS expression so the result is emitted on a sentinel-prefixed line.
# This shields callers from playwright-cli warnings or deprecation notices
# that would otherwise be picked up by a naive `tail -1`.
run_js() {
  local body="$1"
  playwright-cli run-code "async page => {
    let __r;
    try { __r = await (async () => { $body })(); }
    catch (e) { __r = false; }
    console.log('__OUTCOME_RESULT__:' + JSON.stringify(__r));
  }" 2>/dev/null | extract_sentinel
}

for assertion in "${ASSERTIONS[@]}"; do
  KEY="${assertion%%=*}"
  VAL="${assertion#*=}"
  # Strip surrounding quotes if present.
  VAL="${VAL%\"}"
  VAL="${VAL#\"}"

  case "$KEY" in
    url)
      RE=$(glob_to_regex "$VAL")
      ACTUAL=$(run_js "return page.url();")
      # ACTUAL arrives JSON-encoded (a quoted string); strip the outer quotes
      # before regex comparison.
      ACTUAL="${ACTUAL%\"}"
      ACTUAL="${ACTUAL#\"}"
      if ! printf '%s' "$ACTUAL" | grep -qE "$RE"; then
        echo "FAIL url: expected glob '$VAL' (regex $RE), got '$ACTUAL'" >&2
        FAILED=1
      fi
      ;;
    text)
      JSVAL=$(js_string "$VAL")
      VISIBLE=$(run_js "return await page.getByText($JSVAL).first().isVisible();")
      if [ "$VISIBLE" != "true" ]; then
        echo "FAIL text: '$VAL' not visible on page" >&2
        FAILED=1
      fi
      ;;
    storage)
      JSVAL=$(js_string "$VAL")
      PRESENT=$(run_js "const v = await page.evaluate(k => localStorage.getItem(k), $JSVAL); return v != null && v !== '';")
      if [ "$PRESENT" != "true" ]; then
        echo "FAIL storage: localStorage['$VAL'] missing or empty" >&2
        FAILED=1
      fi
      ;;
    *)
      echo "WARN: unknown outcome key '$KEY' (skipped)" >&2
      ;;
  esac
done

exit "$FAILED"
