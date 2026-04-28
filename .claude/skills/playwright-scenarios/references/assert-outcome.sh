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
#   url=<glob>            page.url() must match the glob
#   text="<literal>"      the literal text must be visible on the page
#   storage=<key>         localStorage must contain <key> with a non-empty value
#
# Quote text values with double quotes if they contain spaces.
#
# Usage:
#   bash assert-outcome.sh <scenario.sh>
#
# Example outcome line inside a scenario:
#   # Outcome: url=**/dashboard text="Welcome" storage=auth_token

set -e

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

for assertion in "${ASSERTIONS[@]}"; do
  KEY="${assertion%%=*}"
  VAL="${assertion#*=}"
  # Strip surrounding quotes if present.
  VAL="${VAL%\"}"
  VAL="${VAL#\"}"

  case "$KEY" in
    url)
      ACTUAL=$(playwright-cli run-code "async page => { return page.url(); }" 2>/dev/null | tail -1)
      if ! printf '%s' "$ACTUAL" | grep -qE "$(printf '%s' "$VAL" | sed -e 's|\*\*|.*|g' -e 's|\*|[^/]*|g')"; then
        echo "FAIL url: expected '$VAL', got '$ACTUAL'" >&2
        FAILED=1
      fi
      ;;
    text)
      VISIBLE=$(playwright-cli run-code "async page => {
        try { return await page.getByText('${VAL//\'/\\\'}').first().isVisible(); }
        catch (e) { return false; }
      }" 2>/dev/null | tail -1)
      if [ "$VISIBLE" != "true" ]; then
        echo "FAIL text: '$VAL' not visible on page" >&2
        FAILED=1
      fi
      ;;
    storage)
      PRESENT=$(playwright-cli run-code "async page => {
        const v = await page.evaluate(k => localStorage.getItem(k), '${VAL//\'/\\\'}');
        return v != null && v !== '';
      }" 2>/dev/null | tail -1)
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
