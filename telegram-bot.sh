#!/bin/bash
# telegram-bot.sh - Telegram Bot 发送脚本

BOT_TOKEN="8687796735:AAE0QUUNrQxqbmBffSwdL0Aa8i_98hwJ1j0"
CHAT_ID="${1:-6935067397}"  # 默认使用 Boss 的 Chat ID
MESSAGE="$2"

if [ -z "$MESSAGE" ]; then
    echo "用法: ./telegram-bot.sh [CHAT_ID] '消息内容'"
    echo "示例: ./telegram-bot.sh 6935067397 'Hello from Thunder'"
    exit 1
fi

# 发送消息
curl -s -X POST \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${MESSAGE}" \
    -d "parse_mode=Markdown" 2>&1
