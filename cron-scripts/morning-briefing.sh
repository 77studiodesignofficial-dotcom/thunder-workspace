#!/bin/bash
# cron-morning-briefing.sh - 每日晨报
# 运行时间: 每天 8:00

mkdir -p ~/.openclaw/cron-logs

echo "=== $(date) 每日晨报 ===" >> ~/.openclaw/cron-logs/morning.log

# 1. 天气查询
curl -s "wttr.in/Beijing?format=%l:+%c+%t,+%w+wind,+%h+humidity" >> ~/.openclaw/cron-logs/morning.log
echo "" >> ~/.openclaw/cron-logs/morning.log

# 2. 检查 workspace git 状态
cd /Users/titen/.openclaw/workspace
git status --short >> ~/.openclaw/cron-logs/morning.log 2>/dev/null || echo "Git 状态检查完成" >> ~/.openclaw/cron-logs/morning.log

echo "晨报生成完成" >> ~/.openclaw/cron-logs/morning.log
echo "---" >> ~/.openclaw/cron-logs/morning.log
