#!/bin/bash
# smart-send.sh - Telegram 智能发送（自动处理字数限制）
# 使用方法: ./smart-send.sh "消息内容"

MESSAGE="$1"
MAX_LENGTH=4000
BOT_TOKEN="8687796735:AAE0QUUNrQxqbmBffSwdL0Aa8i_98hwJ1j0"
CHAT_ID="6935067397"

if [ -z "$MESSAGE" ]; then
    echo "用法: ./smart-send.sh '消息内容'"
    exit 1
fi

# 检查网络状态
if [ -f "$HOME/.openclaw/.network_status" ]; then
    NETWORK_STATUS=$(cat "$HOME/.openclaw/.network_status")
    if [ "$NETWORK_STATUS" = "OFFLINE" ]; then
        # 网络离线，缓存消息
        echo "[$(date)] $MESSAGE" >> "$HOME/.openclaw/.pending_messages"
        echo "⚠️ 网络离线，消息已缓存"
        exit 0
    fi
fi

# 检查消息长度
MESSAGE_LENGTH=${#MESSAGE}

if [ "$MESSAGE_LENGTH" -le "$MAX_LENGTH" ]; then
    # 直接发送
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${MESSAGE}" \
        -d "parse_mode=HTML" > /dev/null 2>&1
    echo "✅ 已发送 (${MESSAGE_LENGTH} 字符)"
else
    # 消息过长，分段发送
    echo "⚠️ 消息过长 (${MESSAGE_LENGTH} 字符)，分段发送..."
    
    # 计算分段数
    TOTAL_CHUNKS=$(( (MESSAGE_LENGTH + MAX_LENGTH - 1) / MAX_LENGTH ))
    
    # 使用 fold 分段
    CHUNK_NUM=1
    echo "$MESSAGE" | fold -s -w $MAX_LENGTH | while read -r chunk; do
        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
            -d "chat_id=${CHAT_ID}" \
            -d "text=${chunk}...(${CHUNK_NUM}/${TOTAL_CHUNKS})" \
            -d "parse_mode=HTML" > /dev/null 2>&1
        
        CHUNK_NUM=$((CHUNK_NUM + 1))
        sleep 0.5  # 避免频率限制
    done
    
    echo "✅ 分段发送完成 (${TOTAL_CHUNKS} 段)"
fi
