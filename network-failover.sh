#!/bin/bash
# network-failover.sh - 网络掉线检测（保守审计版）
# 每30秒检查一次
# 当前策略：只做网络探测、状态落盘、结构化日志；不直接外发消息，不自动重启主服务

set -u

LOG_DIR="$HOME/.openclaw/fault-handlers"
LOG_FILE="$LOG_DIR/network.log"
AUDIT_FILE="$LOG_DIR/audit-critical.log"
STATE_FILE="$HOME/.openclaw/.network_status"
PENDING_FILE="$HOME/.openclaw/.pending_messages"
mkdir -p "$LOG_DIR"

SAFE_MODE="${SAFE_MODE:-1}"
DRY_RUN="${DRY_RUN:-0}"

TS() { date '+%Y-%m-%dT%H:%M:%S%z'; }
log_line() { local file="$1"; shift; echo "ts=$(TS) $* safe_mode=$SAFE_MODE dry_run=$DRY_RUN" >> "$file"; }
log_info() { log_line "$LOG_FILE" "level=INFO task=network-failover $*"; }
log_warn() { log_line "$LOG_FILE" "level=WARN task=network-failover $*"; }
log_error() { log_line "$LOG_FILE" "level=ERROR task=network-failover $*"; }
log_critical() { log_line "$AUDIT_FILE" "level=CRITICAL task=network-failover $*"; }

PREV_STATE="unknown"
if [ -f "$STATE_FILE" ]; then
  PREV_STATE="$(cat "$STATE_FILE" 2>/dev/null || echo unknown)"
fi

log_info "action=start target=network reason=scheduled result=running previous_state=$PREV_STATE"

if curl -s --max-time 5 "https://api.telegram.org" > /dev/null 2>&1; then
  echo "ONLINE" > "$STATE_FILE"
  if [ "$PREV_STATE" = "OFFLINE" ]; then
    PENDING_COUNT=0
    if [ -f "$PENDING_FILE" ] && [ -s "$PENDING_FILE" ]; then
      PENDING_COUNT=$(wc -l < "$PENDING_FILE" | tr -d ' ')
    fi
    log_warn "action=recovered target=network reason=probe_success result=online_again pending_messages=$PENDING_COUNT"
    log_critical "action=post_check target=network reason=state_transition_offline_to_online result=recovered pending_messages=$PENDING_COUNT"
  else
    log_info "action=probe target=network reason=telegram_api_reachable result=online"
  fi
else
  echo "OFFLINE" > "$STATE_FILE"
  if [ "$PREV_STATE" = "ONLINE" ]; then
    log_error "action=probe target=network reason=telegram_api_unreachable result=offline_transition"
    log_critical "action=detect target=network reason=state_transition_online_to_offline result=manual_observe_required"
  else
    log_warn "action=probe target=network reason=telegram_api_unreachable result=offline"
  fi
fi

CURRENT_STATE="$(cat "$STATE_FILE" 2>/dev/null || echo unknown)"
log_info "action=finish target=network reason=probe_complete result=$CURRENT_STATE"
exit 0
