#!/usr/bin/env bash
set -euo pipefail

STATUS=OK
ISSUES=()

add_issue() {
  local level="$1"
  local msg="$2"
  ISSUES+=("[$level] $msg")
  if [[ "$level" == "FAIL" ]]; then
    STATUS=FAIL
  elif [[ "$STATUS" == "OK" ]]; then
    STATUS=WARN
  fi
}

echo "== OpenClaw Healthcheck =="
echo "time: $(date '+%F %T %Z')"
echo

echo "-- Gateway status --"
GW_STATUS=$(openclaw gateway status --no-color 2>&1 || true)
echo "$GW_STATUS"
if ! grep -q "Runtime: running" <<<"$GW_STATUS"; then
  add_issue FAIL "Gateway runtime is not reported as running"
fi
if ! grep -q "RPC probe: ok" <<<"$GW_STATUS"; then
  add_issue FAIL "Gateway RPC probe is not ok"
fi

echo
echo "-- Channel status --"
CH_STATUS=$(openclaw channels status --no-color 2>&1 || true)
echo "$CH_STATUS"
if ! grep -q "Telegram default" <<<"$CH_STATUS"; then
  add_issue FAIL "Telegram channel status missing"
fi
if ! grep -q "running" <<<"$CH_STATUS"; then
  add_issue FAIL "Telegram channel is not running"
fi

echo
echo "-- Health probe --"
HEALTH_JSON=$(openclaw health --json 2>/dev/null || true)
if [[ -n "$HEALTH_JSON" ]]; then
  echo "$HEALTH_JSON"
  if ! grep -q '"ok": true' <<<"$HEALTH_JSON"; then
    add_issue FAIL "OpenClaw health probe not ok"
  fi
  if grep -q '"probe": {[^}]*"ok": true' <<<"$HEALTH_JSON"; then
    :
  fi
  if grep -q '"running": false' <<<"$HEALTH_JSON"; then
    add_issue WARN "Health JSON contains channel/account entries marked running=false despite probe success; verify channel runtime semantics"
  fi
else
  add_issue WARN "openclaw health --json returned no output"
fi

echo
echo "-- Config trust boundary --"
CFG=$(python3 - <<'PY'
import json, pathlib
p=pathlib.Path('/Users/titen/.openclaw/openclaw.json')
obj=json.loads(p.read_text())
tg=obj.get('channels',{}).get('telegram',{})
print('dmPolicy=' + str(tg.get('dmPolicy')))
print('allowFrom=' + str(tg.get('allowFrom')))
print('proxy=' + str(tg.get('proxy')))
PY
)
echo "$CFG"
if ! grep -q "dmPolicy=allowlist" <<<"$CFG"; then
  add_issue FAIL "Telegram dmPolicy is not allowlist"
fi
if ! grep -q "6935067397" <<<"$CFG"; then
  add_issue WARN "Boss allowlist id not found in Telegram config"
fi

echo
echo "-- State dir perms --"
PERM=$(stat -f '%Sp %N' /Users/titen/.openclaw 2>&1 || true)
echo "$PERM"
if ! grep -q '^drwx------ ' <<<"$PERM"; then
  add_issue FAIL "State dir permissions are not 700"
fi

echo
echo "-- Proxy chain --"
PPROXY=$(launchctl print gui/$(id -u)/com.titen.pproxy7890 2>&1 || true)
if grep -q "state = running" <<<"$PPROXY"; then
  echo "pproxy: running"
else
  echo "$PPROXY"
  add_issue WARN "pproxy launch agent is not running"
fi
HTTP_CODE=$(curl -I -L -m 12 -sS -o /dev/null -w '%{http_code}' https://api.openai.com/v1/models || true)
echo "openai_probe_http_code=$HTTP_CODE"
if [[ "$HTTP_CODE" != "401" && "$HTTP_CODE" != "200" ]]; then
  add_issue WARN "OpenAI probe returned unexpected code: $HTTP_CODE"
fi

echo
echo "-- Recent actionable log signals --"
LOG_OUT=$(python3 - <<'PY'
from pathlib import Path
import re
p = Path(f"/tmp/openclaw/openclaw-{__import__('datetime').datetime.now().strftime('%Y-%m-%d')}.log")
if not p.exists():
    print('NO_LOG_FILE')
    raise SystemExit
patterns = [
    re.compile(r'session file locked', re.I),
    re.compile(r'rate limit', re.I),
    re.compile(r'timed out', re.I),
    re.compile(r'server_error', re.I),
    re.compile(r'FailoverError', re.I),
]
ignore = [
    re.compile(r'Other gateway-like services detected', re.I),
    re.compile(r'Cleanup hint:', re.I),
    re.compile(r'Recommendation: run a single gateway', re.I),
    re.compile(r'If you need multiple gateways', re.I),
    re.compile(r'com\.titen\.pproxy7890', re.I),
]
lines = p.read_text(errors='ignore').splitlines()[-300:]
out=[]
for line in lines:
    if any(r.search(line) for r in ignore):
        continue
    if any(r.search(line) for r in patterns):
        out.append(line)
for line in out[-20:]:
    print(line)
PY
)
if [[ "$LOG_OUT" == "NO_LOG_FILE" || -z "$LOG_OUT" ]]; then
  echo "No recent actionable warning/error lines"
else
  echo "$LOG_OUT"
  add_issue WARN "Recent actionable warning/error patterns found in gateway log"
fi

echo
echo "== Summary =="
echo "status=$STATUS"
if ((${#ISSUES[@]})); then
  printf '%s\n' "issues:"
  printf '  %s\n' "${ISSUES[@]}"
else
  echo "issues: none"
fi
