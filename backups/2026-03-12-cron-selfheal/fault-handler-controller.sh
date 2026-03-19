#!/bin/bash
# fault-handler-controller.sh - 故障处理统一控制器
# 由 crontab 调用，分发到各处理模块

BASE_DIR="$HOME/.openclaw/workspace"
LOG_DIR="$HOME/.openclaw/fault-handlers"
ENV_FILE="$HOME/.openclaw/fault-handlers.env"
mkdir -p "$LOG_DIR"

# 全局安全开关（可被环境变量覆盖）
SAFE_MODE="${SAFE_MODE:-1}"
DRY_RUN="${DRY_RUN:-0}"
if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi
export SAFE_MODE DRY_RUN

case "$1" in
    ghost)
        "$BASE_DIR/ghost-process-cleanup.sh" >> "$LOG_DIR/ghost-process.log" 2>&1
        ;;
    token)
        "$BASE_DIR/token-monitor.sh" >> "$LOG_DIR/token-monitor.log" 2>&1
        ;;
    network)
        "$BASE_DIR/network-failover.sh" >> "$LOG_DIR/network.log" 2>&1
        ;;
    status)
        echo "=== Thunder 故障处理器状态 ==="
        echo ""
        echo "SAFE_MODE=$SAFE_MODE"
        echo "DRY_RUN=$DRY_RUN"
        echo "ENV_FILE=$ENV_FILE"
        echo ""
        echo "1. 幽灵进程清理:"
        tail -5 "$LOG_DIR/ghost-process.log" 2>/dev/null || echo "  暂无日志"
        echo ""
        echo "2. Token 监控:"
        tail -5 "$LOG_DIR/token-monitor.log" 2>/dev/null || echo "  暂无日志"
        echo ""
        echo "3. 网络故障转移:"
        tail -5 "$LOG_DIR/network.log" 2>/dev/null || echo "  暂无日志"
        echo ""
        echo "4. 高风险审计日志:"
        tail -5 "$LOG_DIR/audit-critical.log" 2>/dev/null || echo "  暂无日志"
        echo ""
        echo "5. 运行中的处理器:"
        pgrep -f "fault-handler" | wc -l | xargs echo "  进程数:"
        ;;
    install)
        echo "=== 安装故障处理器到 crontab ==="
        crontab -l > "$HOME/.crontab.backup.$(date +%Y%m%d)" 2>/dev/null || true
        (
            crontab -l 2>/dev/null | grep -v "fault-handler-controller.sh" | grep -v "# Thunder 故障处理器"
            echo "# Thunder 故障处理器（每5分钟）"
            echo "*/5 * * * * $BASE_DIR/fault-handler-controller.sh ghost >> $LOG_DIR/cron.log 2>&1"
            echo "# Thunder Token 监控（每小时）"
            echo "0 * * * * $BASE_DIR/fault-handler-controller.sh token >> $LOG_DIR/cron.log 2>&1"
            echo "# Thunder 网络检测（每分钟）"
            echo "* * * * * $BASE_DIR/fault-handler-controller.sh network >> $LOG_DIR/cron.log 2>&1"
        ) | crontab -
        echo "✅ 已安装到 crontab"
        echo ""
        echo "当前 crontab:"
        crontab -l | grep -E "(ghost|token|network|# Thunder)"
        ;;
    uninstall)
        crontab -l 2>/dev/null | grep -v "fault-handler-controller" | crontab -
        echo "✅ 已从 crontab 移除"
        ;;
    *)
        echo "Thunder 故障处理器控制器"
        echo ""
        echo "用法:"
        echo "  ./fault-handler-controller.sh ghost     # 执行幽灵进程清理"
        echo "  ./fault-handler-controller.sh token     # 执行 Token 监控"
        echo "  ./fault-handler-controller.sh network   # 执行网络检测"
        echo "  ./fault-handler-controller.sh status    # 查看状态"
        echo "  ./fault-handler-controller.sh install   # 安装到 crontab"
        echo "  ./fault-handler-controller.sh uninstall # 从 crontab 移除"
        ;;
esac
