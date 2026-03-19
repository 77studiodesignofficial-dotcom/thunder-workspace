#!/bin/bash
set -euo pipefail

CFG="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
LOG_FILE="$HOME/.openclaw/logs/kimi-websearch-sync.log"
TMP_BODY="/tmp/kimi_websearch_probe_$$.json"
DRY_RUN=0

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $*" | tee -a "$LOG_FILE"
}

if ! command -v jq >/dev/null 2>&1; then
  log "ERROR: jq not found"
  exit 1
fi

if [[ ! -f "$CFG" ]]; then
  log "ERROR: config not found: $CFG"
  exit 1
fi

# Priority: explicit web_search key in config > env KIMI_API_KEY > env MOONSHOT_API_KEY
KEY_FROM_CFG="$(jq -r '.tools.web.search.kimi.apiKey // empty' "$CFG")"
API_KEY="${KEY_FROM_CFG:-${KIMI_API_KEY:-${MOONSHOT_API_KEY:-}}}"

if [[ -z "$API_KEY" ]]; then
  log "SKIP: no Kimi key available"
  exit 0
fi

CURRENT_BASE="$(jq -r '.tools.web.search.kimi.baseUrl // "https://api.moonshot.ai/v1"' "$CFG")"
CURRENT_MODEL="$(jq -r '.tools.web.search.kimi.model // ""' "$CFG")"

probe_status() {
  local base_url="$1"
  local code
  code=$(curl -sS -m 10 -o "$TMP_BODY" -w "%{http_code}" \
    -H "Authorization: Bearer $API_KEY" \
    "${base_url%/}/models" || echo "000")
  echo "$code"
}

CN_BASE="https://api.moonshot.cn/v1"
AI_BASE="https://api.moonshot.ai/v1"

CN_CODE="$(probe_status "$CN_BASE")"
AI_CODE="$(probe_status "$AI_BASE")"

DESIRED_BASE=""
if [[ "$CN_CODE" == "200" && "$AI_CODE" != "200" ]]; then
  DESIRED_BASE="$CN_BASE"
elif [[ "$AI_CODE" == "200" && "$CN_CODE" != "200" ]]; then
  DESIRED_BASE="$AI_BASE"
elif [[ "$AI_CODE" == "200" && "$CN_CODE" == "200" ]]; then
  # both valid: keep current to avoid flip-flop
  if [[ "$CURRENT_BASE" == "$CN_BASE" || "$CURRENT_BASE" == "$AI_BASE" ]]; then
    DESIRED_BASE="$CURRENT_BASE"
  else
    DESIRED_BASE="$AI_BASE"
  fi
else
  log "SKIP: both endpoints invalid (cn=$CN_CODE, ai=$AI_CODE); keep current=$CURRENT_BASE"
  exit 0
fi

if [[ "$DESIRED_BASE" == "$CURRENT_BASE" ]]; then
  log "OK: endpoint unchanged ($CURRENT_BASE) [cn=$CN_CODE ai=$AI_CODE]"
  exit 0
fi

BACKUP="$CFG.kimi-sync.$(date +%Y%m%d-%H%M%S).bak"
cp "$CFG" "$BACKUP"

if [[ "$DRY_RUN" == "1" ]]; then
  log "DRY-RUN: would switch baseUrl $CURRENT_BASE -> $DESIRED_BASE [cn=$CN_CODE ai=$AI_CODE], backup=$BACKUP"
  rm -f "$BACKUP"
  exit 0
fi

TMP_CFG="$(mktemp)"
NOW_ISO="$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"

jq --arg base "$DESIRED_BASE" --arg now "$NOW_ISO" '
  .tools.web.search.enabled = true
  | .tools.web.search.provider = "kimi"
  | .tools.web.search.kimi.baseUrl = $base
  | (.tools.web.search.kimi.model //= "moonshot-v1-128k")
  | .meta.lastTouchedAt = $now
' "$CFG" > "$TMP_CFG"

mv "$TMP_CFG" "$CFG"
chmod 600 "$CFG"

if openclaw gateway restart >/tmp/openclaw_gateway_restart_kimi_sync.log 2>&1; then
  NEW_MODEL="$(jq -r '.tools.web.search.kimi.model // empty' "$CFG")"
  log "SWITCHED: $CURRENT_BASE -> $DESIRED_BASE [cn=$CN_CODE ai=$AI_CODE] model=${NEW_MODEL:-$CURRENT_MODEL} backup=$BACKUP"
else
  log "ERROR: gateway restart failed; backup at $BACKUP"
  exit 1
fi
