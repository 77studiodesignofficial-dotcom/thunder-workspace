#!/bin/bash
# cron-end-of-day.sh - 工作日结束检查
# 运行时间: 工作日 18:00

echo "=== $(date) 工作日总结 ===" >> ~/.openclaw/cron-logs/eod.log

# 1. 今日记忆更新
cd /Users/titen/.openclaw/workspace
echo "今日文件变更:" >> ~/.openclaw/cron-logs/eod.log
git diff --name-only >> ~/.openclaw/cron-logs/eod.log 2>/dev/null || echo "无变更" >> ~/.openclaw/cron-logs/eod.log

echo "" >> ~/.openclaw/cron-logs/eod.log

# 2. 明日提醒（基于 MEMORY.md 中的待办）
echo "待办事项:" >> ~/.openclaw/cron-logs/eod.log
grep "\- \[ \]" MEMORY.md >> ~/.openclaw/cron-logs/eod.log 2>/dev/null || echo "查看 MEMORY.md 了解待办" >> ~/.openclaw/cron-logs/eod.log

echo "---" >> ~/.openclaw/cron-logs/eod.log
