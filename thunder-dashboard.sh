#!/bin/bash
# thunder-dashboard.sh - Thunder 统一运维监控面板
# 使用: ./thunder-dashboard [status|health|logs|report|fix]

VERSION="2.0"
LOG_DIR="$HOME/.openclaw/workspace/fault-handlers"
mkdir -p "$LOG_DIR"

# 颜色输出（禁用，避免兼容性问题）
# 使用 emoji 代替颜色

# 获取状态图标
get_status_icon() {
    if [ "$1" -eq 0 ]; then
        echo "🟢"
    elif [ "$1" -eq 1 ]; then
        echo "🟡"
    else
        echo "🔴"
    fi
}

# 1. 生成给 Boss 看的状态报告
show_status() {
    echo "⚡ Thunder 系统状态 - $(date '+%Y-%m-%d %H:%M')"
    echo ""
    
    # 计算健康度
    HEALTH_SCORE=100
    GATEWAY_STATUS=0
    CAFFEINATE_STATUS=0
    API_STATUS=0
    ERROR_STATUS=0
    
    # 检查 Gateway
    if pgrep -f "openclaw-gateway" > /dev/null; then
        GATEWAY_STATUS=0
        GATEWAY_TIME=$(ps -o etime= -p $(pgrep -f "openclaw-gateway") 2>/dev/null | tr -d ' ')
    else
        GATEWAY_STATUS=2
        GATEWAY_TIME="离线"
        HEALTH_SCORE=$((HEALTH_SCORE - 30))
    fi
    
    # 检查 caffeinate
    if pgrep -x "caffeinate" > /dev/null; then
        CAFFEINATE_STATUS=0
    else
        CAFFEINATE_STATUS=1
        HEALTH_SCORE=$((HEALTH_SCORE - 10))
    fi
    
    # 检查 APIs
    source "$HOME/.openclaw/.env.skill" 2>/dev/null || true
    API_COUNT=0
    [ -n "$MOONSHOT_API_KEY" ] && API_COUNT=$((API_COUNT + 1))
    [ -n "$ZHIPU_API_KEY" ] && API_COUNT=$((API_COUNT + 1))
    [ -n "$TELEGRAM_BOT_TOKEN" ] && API_COUNT=$((API_COUNT + 1))
    
    if [ "$API_COUNT" -ge 3 ]; then
        API_STATUS=0
    else
        API_STATUS=1
        HEALTH_SCORE=$((HEALTH_SCORE - 15))
    fi
    
    # 检查今日异常（从日志统计）
    TODAY_ERRORS=$(grep "$(date '+%a %b %d')" "$LOG_DIR"/*.log 2>/dev/null | grep -c "ERROR\|❌\|🔴" 2>/dev/null || echo 0)
    TODAY_ERRORS=$(echo "$TODAY_ERRORS" | head -1)
    if [ -z "$TODAY_ERRORS" ] || [ "$TODAY_ERRORS" -eq 0 ]; then
        ERROR_STATUS=0
        TODAY_ERRORS=0
    else
        ERROR_STATUS=1
        HEALTH_SCORE=$((HEALTH_SCORE - TODAY_ERRORS * 5))
    fi
    
    # 确保健康度不为负
    [ "$HEALTH_SCORE" -lt 0 ] && HEALTH_SCORE=0
    
    # 显示健康度
    if [ "$HEALTH_SCORE" -ge 90 ]; then
        echo "整体健康度: 🟢 $HEALTH_SCORE/100"
    elif [ "$HEALTH_SCORE" -ge 70 ]; then
        echo "整体健康度: 🟡 $HEALTH_SCORE/100"
    else
        echo "整体健康度: 🔴 $HEALTH_SCORE/100"
    fi
    echo ""
    
    # 核心服务状态
    echo "核心服务:"
    echo "  $(get_status_icon $GATEWAY_STATUS) Gateway: ${GATEWAY_TIME:+运行中 ($GATEWAY_TIME)}"
    echo "  $(get_status_icon $CAFFEINATE_STATUS) 防休眠: $([ $CAFFEINATE_STATUS -eq 0 ] && echo '运行中' || echo '未运行')"
    echo "  $(get_status_icon $API_STATUS) APIs: $API_COUNT/3 已配置"
    echo "  $(get_status_icon $ERROR_STATUS) 今日异常: $TODAY_ERRORS 次"
    echo ""
    
    # 待处理事项（从 MEMORY.md 提取）
    echo "待处理事项:"
    if [ -f "$HOME/.openclaw/workspace/MEMORY.md" ]; then
        grep "\- \[ \]" "$HOME/.openclaw/workspace/MEMORY.md" 2>/dev/null | head -3 | while read line; do
            echo "  🔴 $(echo "$line" | sed 's/- \[ \] //')"
        done
    fi
    echo ""
    
    # 资源消耗（估算）
    echo "资源消耗:"
    echo "  💰 APIs: 智谱 GLM 免费 | Moonshot 正常"
    echo "  💾 磁盘: $(du -sh ~/.openclaw 2>/dev/null | awk '{print $1}')"
    echo ""
    
    # 建议
    echo "建议:"
    if [ "$HEALTH_SCORE" -ge 90 ]; then
        echo "  ✅ 系统运行良好，保持当前配置"
    elif [ $CAFFEINATE_STATUS -ne 0 ]; then
        echo "  ⚠️ 建议启动 caffeinate 防止休眠"
    else
        echo "  ⚠️ 建议查看详细日志排查问题"
    fi
}

# 2. 详细健康检查
show_health() {
    echo "🔍 详细健康检查"
    echo ""
    
    # 系统信息
    echo "系统信息:"
    echo "  时间: $(date)"
    echo "  主机: $(hostname)"
    echo "  用户: $(whoami)"
    echo ""
    
    # 进程检查
    echo "进程状态:"
    echo "  openclaw-gateway: $(pgrep -c "openclaw-gateway" 2>/dev/null || echo 0) 个"
    echo "  caffeinate: $(pgrep -c "caffeinate" 2>/dev/null || echo 0) 个"
    echo "  node: $(pgrep -c "node" 2>/dev/null || echo 0) 个"
    echo ""
    
    # 凭证检查
    echo "凭证状态:"
    source "$HOME/.openclaw/.env.skill" 2>/dev/null || true
    [ -n "$MOONSHOT_API_KEY" ] && echo "  ✅ Moonshot API" || echo "  ❌ Moonshot API"
    [ -n "$ZHIPU_API_KEY" ] && echo "  ✅ 智谱 API" || echo "  ❌ 智谱 API"
    [ -n "$TELEGRAM_BOT_TOKEN" ] && echo "  ✅ Telegram Bot" || echo "  ❌ Telegram Bot"
    [ -n "$GITHUB_TOKEN" ] && echo "  ✅ GitHub CLI" || echo "  ⚠️ GitHub CLI (gh auth)"
    echo ""
    
    # 日志检查
    echo "最近日志:"
    ls -lt "$LOG_DIR"/*.log 2>/dev/null | head -3 | while read line; do
        echo "  $line"
    done
    echo ""
    
    # 网络测试
    echo "网络测试:"
    if curl -s --max-time 3 https://api.telegram.org > /dev/null; then
        echo "  ✅ Telegram API"
    else
        echo "  ❌ Telegram API"
    fi
    
    if curl -s --max-time 3 https://api.moonshot.cn > /dev/null; then
        echo "  ✅ Moonshot API"
    else
        echo "  ❌ Moonshot API"
    fi
}

# 3. 查看日志
show_logs() {
    echo "📋 最近日志 (最后20行)"
    echo ""
    
    for log in "$LOG_DIR"/*.log; do
        if [ -f "$log" ]; then
            echo "$(basename "$log"):"
            tail -5 "$log" 2>/dev/null | sed 's/^/  /'
            echo ""
        fi
    done
}

# 4. 生成报告
show_report() {
    echo "📊 Thunder 运维报告"
    echo "生成时间: $(date)"
    echo ""
    
    show_status
    echo ""
    echo "---"
    echo ""
    show_health
}

# 5. 一键修复
auto_fix() {
    echo "🔧 自动修复"
    echo ""
    
    # 修复1: 启动 caffeinate
    if ! pgrep -x "caffeinate" > /dev/null; then
        echo "启动 caffeinate..."
        caffeinate -dimsu &
        sleep 2
        if pgrep -x "caffeinate" > /dev/null; then
            echo "✅ caffeinate 已启动"
        else
            echo "❌ caffeinate 启动失败"
        fi
    else
        echo "✅ caffeinate 已在运行"
    fi
    
    # 修复2: 清理僵尸进程
    echo ""
    echo "清理僵尸进程..."
    "$HOME/.openclaw/workspace/ghost-process-cleanup.sh" 2>/dev/null || echo "清理脚本未找到"
    
    # 修复3: 检查 Gateway
    if ! pgrep -f "openclaw-gateway" > /dev/null; then
        echo ""
        echo "启动 Gateway..."
        openclaw gateway start &
    fi
    
    echo ""
    echo "✅ 自动修复完成"
}

# 主入口
case "${1:-status}" in
    status)
        show_status
        ;;
    health)
        show_health
        ;;
    logs)
        show_logs
        ;;
    report)
        show_report
        ;;
    fix)
        auto_fix
        ;;
    *)
        echo "Thunder Dashboard v$VERSION"
        echo ""
        echo "用法:"
        echo "  ./thunder-dashboard status    # 查看状态摘要（给 Boss）"
        echo "  ./thunder-dashboard health    # 详细健康检查"
        echo "  ./thunder-dashboard logs      # 查看最近日志"
        echo "  ./thunder-dashboard report    # 生成完整报告"
        echo "  ./thunder-dashboard fix       # 一键修复常见问题"
        ;;
esac
