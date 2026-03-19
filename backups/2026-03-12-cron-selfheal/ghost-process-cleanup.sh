#!/bin/bash
# ghost-process-cleanup.sh - 幽灵进程自动清理（保守审计版）
# 当前策略：默认只审计，不自动 kill OpenClaw Gateway，避免误伤主服务

set -u

LOG_DIR="$HOME/.openclaw/fault-handlers"
LOG_FILE="$LOG_DIR/ghost-process.log"
AUDIT_FILE="$LOG_DIR/audit-critical.log"
mkdir -p "$LOG_DIR"

SAFE_MODE="${SAFE_MODE:-1}"
DRY_RUN="${DRY_RUN:-0}"

TS() {
  date '+%Y-%m-%dT%H:%M:%S%z'
}

log_line() {
  local file="$1"
  shift
  echo "ts=$(TS) $* safe_mode=$SAFE_MODE dry_run=$DRY_RUN" >> "$file"
}

log_info() { log_line "$LOG_FILE" "level=INFO task=ghost-process-cleanup $*"; }
log_warn() { log_line "$LOG_FILE" "level=WARN task=ghost-process-cleanup $*"; }
log_error() { log_line "$LOG_FILE" "level=ERROR task=ghost-process-cleanup $*"; }
log_critical() { log_line "$AUDIT_FILE" "level=CRITICAL task=ghost-process-cleanup $*"; }

get_gateway_candidates() {
  pgrep -fal '/usr/local/lib/node_modules/openclaw/dist/index.js gateway|openclaw-gateway' 2>/dev/null || true
}

log_info "action=start target=scan reason=scheduled result=running"
CANDIDATES="$(get_gateway_candidates)"

if [ -z "$CANDIDATES" ]; then
  log_warn "action=scan target=gateway reason=no_process_found result=zero_candidates"
  exit 0
fi

PROCESS_COUNT=$(printf '%s\n' "$CANDIDATES" | sed '/^$/d' | wc -l | tr -d ' ')
log_info "action=scan target=gateway reason=process_enumeration result=candidates_found count=$PROCESS_COUNT"

if [ "$PROCESS_COUNT" -le 1 ]; then
  log_info "action=finish target=gateway reason=single_instance result=normal count=$PROCESS_COUNT"
  exit 0
fi

log_warn "action=detect target=gateway reason=multiple_candidates result=manual_review_required count=$PROCESS_COUNT"

printf '%s\n' "$CANDIDATES" | while IFS= read -r line; do
  [ -z "$line" ] && continue
  PID="$(printf '%s' "$line" | awk '{print $1}')"
  CMD="$(printf '%s' "$line" | cut -d' ' -f2-)"

  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    log_critical "action=pre_kill target=gateway pid=$PID reason=multiple_candidates_detected result=skipped_manual_confirmation_required cmd=\"$CMD\""
    if [ "$SAFE_MODE" = "1" ] || [ "$DRY_RUN" = "1" ]; then
      log_warn "action=skip target=gateway pid=$PID reason=conservative_mode result=no_kill"
    else
      log_critical "action=blocked target=gateway pid=$PID reason=unsafe_mode_not_implemented result=manual_change_required"
      log_error "action=blocked target=gateway pid=$PID reason=unsafe_mode_not_implemented result=no_kill"
    fi
  else
    log_error "action=inspect target=gateway pid=${PID:-unknown} reason=stale_candidate result=unavailable"
  fi
done

POST_COUNT="$(get_gateway_candidates | sed '/^$/d' | wc -l | tr -d ' ')"
log_info "action=post_check target=gateway reason=conservative_mode result=unchanged count=$POST_COUNT"
exit 0
