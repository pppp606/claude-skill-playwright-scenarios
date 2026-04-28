#!/bin/bash
# .claude/skills/playwright-scenarios/references/lib-outcome.sh
#
# Sourceable helpers shared by assert-outcome.sh and detect-intent.sh.
# Pure functions; no side effects beyond stdout.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib-outcome.sh"

# glob_to_regex <glob>
#
# Convert a URL glob into an anchored extended regex.
#   **  -> .*        (matches across "/")
#   *   -> [^/]*     (matches within a path segment)
#   ?   -> [^/]      (single non-slash character; never a regex quantifier)
# Every other regex metacharacter is escaped, so dots and query-string "?"
# in real URLs cannot become accidental regex specials.
# The output is anchored with ^ and $.
glob_to_regex() {
  local g="$1" out="^" i ch next
  local len=${#g}
  for ((i = 0; i < len; i++)); do
    ch="${g:i:1}"
    case "$ch" in
      '*')
        next="${g:i+1:1}"
        if [ "$next" = '*' ]; then
          out+='.*'
          i=$((i + 1))
        else
          out+='[^/]*'
        fi
        ;;
      '?')
        out+='[^/]'
        ;;
      '.'|'\'|'^'|'$'|'+'|'('|')'|'{'|'}'|'['|']'|'|')
        out+='\'"$ch"
        ;;
      *)
        out+="$ch"
        ;;
    esac
  done
  printf '%s$' "$out"
}

# js_string <value>
#
# Emit a JSON string literal (double-quoted, escaped) suitable for direct
# embedding in JavaScript source. Escapes \ " newline CR tab; everything else
# is passed through. The result includes its own surrounding double quotes,
# so callers should NOT wrap it in additional quotes.
js_string() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '"%s"' "$s"
}

# extract_sentinel
#
# Read stdin, keep only lines that start with the sentinel
# "__OUTCOME_RESULT__:", and emit the payload of the LAST such line.
# Defends against playwright-cli printing trailing warnings or deprecation
# notices that would otherwise be picked up by a naive `tail -1`.
extract_sentinel() {
  awk '
    /^__OUTCOME_RESULT__:/ { last = substr($0, length("__OUTCOME_RESULT__:") + 1) }
    END { if (last != "") print last }
  '
}
