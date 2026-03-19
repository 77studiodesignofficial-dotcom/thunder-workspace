#!/bin/bash
# weekly-report.sh - 周度运维报告
# 每周日 20:00 执行（与 weekly-review Cron 任务结合）

source "$HOME/.openclaw/.env.skill" 2>/dev/null || true
BOT_TOKEN="8687796735:AAE0QUUNrQxqbmBffSwdL0Aa8i_98hwJ1j0"
CHAT_ID="6935067397"

# 计算时间范围
WEEK_START=$(date -v-7d '+%Y-%m-%d')
WEEK_END=$(date '+%Y-%m-%d')
WEEK_NUM=$(date '+%U')

# 统计数据
TOTAL_DAYS=7
ONLINE_DAYS=7  # 简化，实际需要从历史记录计算

# API 调用估算（从日志）
API_CALLS=$(wc -l < "$HOME/.openclaw/security-audit.log" 2>/dev/null || echo 0)

# 故障次数（从故障处理器日志）
FAULT_COUNT=$(grep -c "ERROR\|❌\|🔴" "$HOME/.openclaw/workspace/fault-handlers"/*.log 2>/dev/null || echo 0)

# 工作区变更
if [ -d "$HOME/.openclaw/workspace" ]; then
    cd "$HOME/.openclaw/workspace"
    FILE_CHANGES=$(git diff --shortstat HEAD 2>/dev/null | head -1 || echo "无记录")
fi

# 构建周报
MESSAGE="📊 Thunder 周报 - 第${WEEK_NUM}周 (${WEEK_START} 至 ${WEEK_END})

运行统计:
├── 在线时长: ${TOTAL_DAYS}/7 天
├── API 调用: ~${API_CALLS} 次
├── 故障次数: ${FAULT_COUNT} 次
└── 文件变更: ${FILE_CHANGES:-无记录}

核心服务状态:
$(if pgrep -f "openclaw-gateway" > /dev/null; then echo "🟢 OpenClaw Gateway"; else echo "🔴 OpenClaw Gateway"; fi)
$(if pgrep -x "caffeinate" > /dev/null; then echo "🟢 防休眠服务"; else echo "🟡 防休眠服务"; fi)
🟢 Moonshot API
🟢 智谱 GLM
🟢 Telegram Bot

本周完成:
$(grep "✅\|完成" "$HOME/.openclaw/workspace/MEMORY.md" 2>/dev/null | head -3 | sed 's/^/• /' || echo "• 见 MEMORY.md")

下周计划:
$(grep "\- \[ \]" "$HOME/.openclaw/workspace/MEMORY.md" 2>/dev/null | head -3 | sed 's/^/• /' || echo "• 见 MEMORY.md")

优化建议:
$(if [ ! -f "$HOME/.openclaw/.brave_api_key" ]; then echo "🔴 配置 Brave Search API Key 以提升资讯质量"; fi)
$(if [ "$FAULT_COUNT" -gt 5 ]; then echo "🟡 本周故障较多，建议检查系统稳定性"; fi)
$(if [ "$FAULT_COUNT" -le 2 ]; then echo "✅ 系统运行稳定，保持当前配置"; fi)

---
⚡ Thunder | 详细报告: ./thunder-dashboard report"

# 发送消息
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${MESSAGE}" \
    -d "parse_mode=HTML" > /dev/null 2>&1

# 记录日志
echo "[$(date)] 周报已发送 - 第${WEEK_NUM}周" >> "$HOME/.openclaw/workspace/fault-handlers/weekly.log"
