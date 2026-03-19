#!/bin/bash
# openclaw-keepalive.sh - 防止系统休眠，保持 OpenClaw 在线
# 使用方法：./openclaw-keepalive.sh

LOG="$HOME/.openclaw/keepalive.log"

echo "[$(date)] 启动 OpenClaw 防休眠守护" >> "$LOG"

# 检查 Gateway 是否运行
if ! pgrep -f "openclaw-gateway" > /dev/null; then
    echo "[$(date)] Gateway 未运行，启动中..." >> "$LOG"
    openclaw gateway start >> "$LOG" 2>&1 &
    sleep 3
fi

# 保持系统活跃（防止休眠）
echo "[$(date)] 启动 caffeinate 守护（防止系统休眠）" >> "$LOG"
caffeinate -dimsu &

echo "[$(date)] ✅ 防休眠守护已启动" >> "$LOG"
echo "系统将在您关闭笔记本盖子时保持运行"
