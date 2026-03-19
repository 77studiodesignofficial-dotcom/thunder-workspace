#!/bin/bash
# optimized-daily-briefing.sh - 优化版每日晨报
# 精简格式，标准详细程度

source "$HOME/.openclaw/.env.skill" 2>/dev/null || true
BOT_TOKEN="8687796735:AAE0QUUNrQxqbmBffSwdL0Aa8i_98hwJ1j0"
CHAT_ID="6935067397"
LOG_FILE="$HOME/.openclaw/workspace/fault-handlers/briefing.log"

# 生成年月日
DATE_STR=$(date '+%Y年%m月%d日')
WEEKDAY=$(date '+%A')

# 获取健康度
HEALTH_SCORE=100
if ! pgrep -f "openclaw-gateway" > /dev/null; then
    HEALTH_SCORE=$((HEALTH_SCORE - 30))
fi
if ! pgrep -x "caffeinate" > /dev/null; then
    HEALTH_SCORE=$((HEALTH_SCORE - 10))
fi
[ "$HEALTH_SCORE" -lt 0 ] && HEALTH_SCORE=0

if [ "$HEALTH_SCORE" -ge 90 ]; then
    HEALTH_ICON="🟢"
elif [ "$HEALTH_SCORE" -ge 70 ]; then
    HEALTH_ICON="🟡"
else
    HEALTH_ICON="🔴"
fi

# 检查昨日变更
if [ -d "$HOME/.openclaw/workspace" ]; then
    CHANGES=$(cd "$HOME/.openclaw/workspace" && git status --short 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CHANGES" -gt 0 ]; then
        CHANGE_TEXT="$CHANGES 个文件未提交"
    else
        CHANGE_TEXT="无变更"
    fi
else
    CHANGE_TEXT="工作区正常"
fi

# 统计待办（从 MEMORY.md）
TODOS=$(grep "\- \[ \]" "$HOME/.openclaw/workspace/MEMORY.md" 2>/dev/null | wc -l | tr -d ' ')

# 构建消息
MESSAGE="📅 Thunder 日报 - ${DATE_STR} ${WEEKDAY}

健康度: ${HEALTH_ICON} ${HEALTH_SCORE}/100
$(if pgrep -f "openclaw-gateway" > /dev/null; then echo "🟢 Gateway: 运行中"; else echo "🔴 Gateway: 离线"; fi)
$(if pgrep -x "caffeinate" > /dev/null; then echo "🟢 防休眠: 运行中"; else echo "🟡 防休眠: 未运行"; fi)

工作区:
├── 昨日变更: ${CHANGE_TEXT}
└── 待办事项: ${TODOS} 项

$(if [ -f "$HOME/.openclaw/.network_status" ] && [ "$(cat "$HOME/.openclaw/.network_status")" = "OFFLINE" ]; then echo "⚠️ 当前网络: 离线（缓存模式）"; fi)

今日建议:
$(if [ "$HEALTH_SCORE" -lt 70 ]; then echo "🔴 系统健康度较低，建议执行 ./thunder-dashboard fix"; elif [ ! -f "$HOME/.openclaw/.brave_api_key" ]; then echo "🟡 建议配置 Brave Search API Key 以启用资讯搜索"; elif [ "$CHANGES" -gt 10 ]; then echo "🟡 建议提交工作区文件至 Git"; else echo "✅ 系统运行良好，无需特别操作"; fi)

---
⚡ Thunder | 详细状态: ./thunder-dashboard status"

# 发送消息（使用智能分段）
MESSAGE_LENGTH=${#MESSAGE}
if [ "$MESSAGE_LENGTH" -le 4000 ]; then
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${MESSAGE}" \
        -d "parse_mode=HTML" > /dev/null 2>&1
else
    # 分段发送
    echo "$MESSAGE" | fold -s -w 4000 | head -1 | while read -r chunk; do
        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
            -d "chat_id=${CHAT_ID}" \
            -d "text=${chunk}..." > /dev/null 2>&1
    done
fi

# 记录日志
echo "[$(date)] 晨报已发送" >> "$LOG_FILE"
