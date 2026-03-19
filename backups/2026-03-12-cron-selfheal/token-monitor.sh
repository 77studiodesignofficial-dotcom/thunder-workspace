#!/bin/bash
# token-monitor.sh - Token / Provider 状态监控（保守审计版）
# 每小时检查一次
# 当前策略：只做观测、记录与阈值/异常标记；不自动切换 fallback，不直接外发消息

set -u

LOG_DIR="$HOME/.openclaw/fault-handlers"
LOG_FILE="$LOG_DIR/token-monitor.log"
AUDIT_FILE="$LOG_DIR/audit-critical.log"
STATE_FILE="$HOME/.openclaw/.provider_status"
mkdir -p "$LOG_DIR"

SAFE_MODE="${SAFE_MODE:-1}"
DRY_RUN="${DRY_RUN:-0}"

TS() { date '+%Y-%m-%dT%H:%M:%S%z'; }
log_line() { local file="$1"; shift; echo "ts=$(TS) $* safe_mode=$SAFE_MODE dry_run=$DRY_RUN" >> "$file"; }
log_info() { log_line "$LOG_FILE" "level=INFO task=token-monitor $*"; }
log_warn() { log_line "$LOG_FILE" "level=WARN task=token-monitor $*"; }
log_error() { log_line "$LOG_FILE" "level=ERROR task=token-monitor $*"; }
log_critical() { log_line "$AUDIT_FILE" "level=CRITICAL task=token-monitor $*"; }

log_info "action=start target=providers reason=scheduled result=running"
source "$HOME/.openclaw/.env.skill" 2>/dev/null || true

MOONSHOT_TEST="unknown"
if [ -n "${MOONSHOT_API_KEY:-}" ]; then
  MOONSHOT_TEST=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://api.moonshot.cn/v1/models" \
    -H "Authorization: Bearer ${MOONSHOT_API_KEY}" \
    --max-time 5)
else
  MOONSHOT_TEST="missing_key"
fi

ZHIPU_TEST="unknown"
if [ -n "${ZHIPU_API_KEY:-}" ]; then
  ZHIPU_TEST=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://open.bigmodel.cn/api/paas/v4/models" \
    -H "Authorization: Bearer ${ZHIPU_API_KEY}" \
    --max-time 5)
else
  ZHIPU_TEST="missing_key"
fi

printf 'moonshot=%s\nzhipu=%s\n' "$MOONSHOT_TEST" "$ZHIPU_TEST" > "$STATE_FILE"

if [ "$MOONSHOT_TEST" = "429" ]; then
  log_error "action=probe target=moonshot reason=http_429 result=quota_exhausted"
  log_critical "action=detect target=moonshot reason=quota_exhausted result=manual_fallback_decision_required"
elif [ "$MOONSHOT_TEST" = "200" ]; then
  log_info "action=probe target=moonshot reason=models_endpoint result=healthy"
elif [ "$MOONSHOT_TEST" = "missing_key" ]; then
  log_warn "action=probe target=moonshot reason=missing_api_key result=skipped"
else
  log_warn "action=probe target=moonshot reason=models_endpoint result=http_${MOONSHOT_TEST}"
fi

if [ "$ZHIPU_TEST" = "200" ]; then
  log_info "action=probe target=zhipu reason=models_endpoint result=healthy"
elif [ "$ZHIPU_TEST" = "missing_key" ]; then
  log_warn "action=probe target=zhipu reason=missing_api_key result=skipped"
else
  log_warn "action=probe target=zhipu reason=models_endpoint result=http_${ZHIPU_TEST}"
fi

log_info "action=finish target=providers reason=probe_complete result=state_written"
exit 0
