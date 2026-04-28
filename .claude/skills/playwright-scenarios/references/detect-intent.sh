#!/bin/bash
# .claude/skills/playwright-scenarios/references/detect-intent.sh
#
# Deterministic part of the intent-detection gate (Step 2 + Step 3).
#
# Reads a scenario script + its sibling .last-pass/<name>.json and resolves
# the anchor SHA against the current HEAD. Emits a key=value report on stdout
# that the runbook in intent-detection.md (Steps 4-7) consumes.
#
# Step 0 (runtime sanity from playwright-cli console/network) and Steps 4-7
# (pickaxe, classification, bias, outcome verification) remain in the runbook
# because they require a live session or model-driven analysis.
#
# Dependencies:
#   - git
#   - jq (optional; an awk fallback handles flat 3-key JSON when jq is absent)
#
# Usage:
#   bash detect-intent.sh <scenario.sh>
#
# Exit codes:
#   0  anchor resolved; proceed with Step 4
#   3  UNVERIFIED (no anchor, self-edit since anchor, or anchor unreachable)
#   2  argument or file error

set -e

SCENARIO="${1:?scenario script path required}"

if [ ! -f "$SCENARIO" ]; then
  echo "ERROR: $SCENARIO not found" >&2
  exit 2
fi

SCENARIO_DIR=$(cd "$(dirname "$SCENARIO")" && pwd)
SCENARIO_NAME=$(basename "$SCENARIO" .sh)
LAST_PASS="$SCENARIO_DIR/.last-pass/$SCENARIO_NAME.json"

# --- Header metadata -------------------------------------------------------

extract_header() {
  # $1 = key (e.g. AppPaths). Reads up to the first non-comment line.
  awk -v k="$1" '
    !/^#/ && NF { exit }
    /^#[[:space:]]*[A-Za-z]+:/ {
      sub(/^#[[:space:]]*/, "")
      n = index($0, ":")
      key = substr($0, 1, n - 1)
      val = substr($0, n + 1)
      sub(/^[[:space:]]+/, "", val)
      sub(/[[:space:]]+$/, "", val)
      if (key == k) { print val; exit }
    }
  ' "$SCENARIO"
}

APP_PATHS=$(extract_header "AppPaths")
APP_REPO=$(extract_header "AppRepo")

# Fall back to APP_REPO_PATH env, then current directory.
if [ -z "$APP_REPO" ]; then
  APP_REPO="${APP_REPO_PATH:-}"
fi
if [ -z "$APP_REPO" ]; then
  APP_REPO=$(pwd)
fi

# --- last-pass anchor parsing ---------------------------------------------

if [ ! -f "$LAST_PASS" ]; then
  cat <<EOF
SCENARIO=$SCENARIO_NAME
VERDICT=UNVERIFIED
REASON=no-last-pass-anchor
EOF
  exit 3
fi

# Read a flat JSON value. Prefer jq; fall back to awk for {"k":"v",...} shapes.
read_json_field() {
  local file="$1" field="$2"
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg f "$field" '.[$f] // empty' "$file"
    return
  fi
  awk -v f="$field" '
    BEGIN { RS = ""; FS = "" }
    {
      # Strip leading/trailing braces and split on ","
      gsub(/^[[:space:]]*\{/, "")
      gsub(/\}[[:space:]]*$/, "")
      n = split($0, parts, /,/)
      for (i = 1; i <= n; i++) {
        p = parts[i]
        # Match "key":"value"
        if (match(p, /"[^"]+"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
          kv = substr(p, RSTART, RLENGTH)
          sep = index(kv, ":")
          k = substr(kv, 1, sep - 1)
          v = substr(kv, sep + 1)
          gsub(/^[[:space:]]*"|"[[:space:]]*$/, "", k)
          gsub(/^[[:space:]]*"|"[[:space:]]*$/, "", v)
          if (k == f) { print v; exit }
        }
      }
    }
  ' "$file"
}

SHA=$(read_json_field "$LAST_PASS" sha)
AT=$(read_json_field "$LAST_PASS" at)
BRANCH=$(read_json_field "$LAST_PASS" branch)

if [ -z "$SHA" ]; then
  cat <<EOF
SCENARIO=$SCENARIO_NAME
VERDICT=UNVERIFIED
REASON=last-pass-missing-sha
EOF
  exit 3
fi

# --- Step 2: self-edit check ---------------------------------------------

# Use the scenario's path relative to APP_REPO if it falls inside; otherwise
# use the absolute path. git log silently produces nothing for paths outside
# the repo, which is fine — that just means no self-edits to detect.
if SELF_EDITS=$(git -C "$APP_REPO" log "${SHA}..HEAD" --format=%h -- "$SCENARIO" 2>/dev/null) \
   && [ -n "$SELF_EDITS" ]; then
  cat <<EOF
SCENARIO=$SCENARIO_NAME
VERDICT=UNVERIFIED
REASON=scenario-edited-since-anchor
SELF_EDITS=$(printf '%s' "$SELF_EDITS" | tr '\n' ',' | sed 's/,$//')
EOF
  exit 3
fi

# --- Step 3: anchor resolution -------------------------------------------

ANCHOR=""
ANCHOR_SOURCE=""

if git -C "$APP_REPO" merge-base --is-ancestor "$SHA" HEAD 2>/dev/null; then
  ANCHOR="$SHA"
  ANCHOR_SOURCE=sha
elif [ -n "$BRANCH" ] \
  && [ "$BRANCH" != "$(git -C "$APP_REPO" branch --show-current 2>/dev/null)" ]; then
  MB=$(git -C "$APP_REPO" merge-base "$BRANCH" HEAD 2>/dev/null || true)
  if [ -n "$MB" ]; then
    ANCHOR="$MB"
    ANCHOR_SOURCE=merge-base
  fi
fi

# Timestamp-parent fallback (rebased history). Resolve in two steps so we
# never produce a literal "^" when the timestamp returns nothing.
if [ -z "$ANCHOR" ] && [ -n "$AT" ]; then
  FIRST=$(git -C "$APP_REPO" log --since="$AT" --reverse --format=%H 2>/dev/null | head -1)
  if [ -n "$FIRST" ]; then
    PARENT=$(git -C "$APP_REPO" rev-parse "${FIRST}^" 2>/dev/null || true)
    if [ -n "$PARENT" ]; then
      ANCHOR="$PARENT"
      ANCHOR_SOURCE=timestamp-parent
    fi
  fi
fi

if [ -z "$ANCHOR" ]; then
  cat <<EOF
SCENARIO=$SCENARIO_NAME
VERDICT=UNVERIFIED
REASON=anchor-unreachable
LAST_PASS_SHA=$SHA
LAST_PASS_AT=$AT
LAST_PASS_BRANCH=$BRANCH
EOF
  exit 3
fi

# --- Success report -------------------------------------------------------

cat <<EOF
SCENARIO=$SCENARIO_NAME
ANCHOR=$ANCHOR
ANCHOR_SOURCE=$ANCHOR_SOURCE
APP_REPO=$APP_REPO
APP_PATHS=$APP_PATHS
LAST_PASS_SHA=$SHA
LAST_PASS_AT=$AT
LAST_PASS_BRANCH=$BRANCH
EOF
exit 0
