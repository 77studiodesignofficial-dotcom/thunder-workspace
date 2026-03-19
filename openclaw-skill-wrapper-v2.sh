#!/bin/bash
# openclaw-skill-wrapper-v2.sh - Skill 执行包装器 v2
# 支持从 .env 文件自动加载凭证，无需 Touch ID

SKILL_NAME="$1"
shift

# 优先从 .env 文件加载凭证（开发模式）
ENV_FILE="${HOME}/.openclaw/.env.skill"
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# 后备：尝试从 Keychain 加载（如果 .env 没有）
if [[ -z "${MOONSHOT_API_KEY:-}" ]]; then
    MOONSHOT_API_KEY=$(/Users/titen/.openclaw/workspace/opencred-keychain.sh read MOONSHOT_API_KEY 2>/dev/null || echo "")
fi
if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    GEMINI_API_KEY=$(/Users/titen/.openclaw/workspace/opencred-keychain.sh read GEMINI_API_KEY 2>/dev/null || echo "")
fi
if [[ -z "${NOTION_API_KEY:-}" ]]; then
    NOTION_API_KEY=$(/Users/titen/.openclaw/workspace/opencred-keychain.sh read NOTION_API_KEY 2>/dev/null || echo "")
fi
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    OPENAI_API_KEY=$(/Users/titen/.openclaw/workspace/opencred-keychain.sh read OPENAI_API_KEY 2>/dev/null || echo "")
fi

# 通用 LLM 调用（优先 Moonshot）
llm_moonshot() {
    local prompt="$1"
    local model="${2:-moonshot-v1-8k}"
    local max_tokens="${3:-2000}"
    
    if [[ -z "$MOONSHOT_API_KEY" ]]; then
        echo "❌ 未配置 MOONSHOT_API_KEY"
        echo "   运行: ./openclaw-cred-hub-v2.sh store MOONSHOT_API_KEY 'sk-...'"
        exit 1
    fi
    
    curl -s https://api.moonshot.cn/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $MOONSHOT_API_KEY" \
        -d "{
            \"model\": \"${model}\",
            \"messages\": [{\"role\": \"user\", \"content\": $(echo "$prompt" | jq -Rs .)}],
            \"max_tokens\": ${max_tokens}
        }" | jq -r '.choices[0].message.content // "API 调用失败"'
}

# 根据 Skill 类型执行
case "$SKILL_NAME" in
    moonshot|kimi|llm|ai)
        llm_moonshot "$*"
        ;;
    
    summarize|summary)
        echo "📝 Moonshot 正在总结..."
        CONTENT="$1"
        
        # 如果是 URL，获取内容
        if [[ "$CONTENT" =~ ^https?:// ]]; then
            CONTENT=$(curl -sL "$CONTENT" 2>/dev/null | head -c 10000 || echo "")
            if [[ -z "$CONTENT" ]]; then
                echo "❌ 无法获取 URL 内容"
                exit 1
            fi
        fi
        
        PROMPT="请对以下内容进行简洁总结，提炼核心要点：

${CONTENT}

格式：
📌 核心观点：
• 要点1
• 要点2
• 要点3"
        
        llm_moonshot "$PROMPT" "moonshot-v1-128k" 1500
        ;;
    
    translate)
        TEXT="$1"
        TARGET="${2:-中文}"
        PROMPT="将以下内容翻译成${TARGET}：${TEXT}"
        llm_moonshot "$PROMPT" "moonshot-v1-8k" 2000
        ;;
    
    code|编程)
        PROMPT="编写代码：$*

要求：
1. 代码简洁高效
2. 包含必要注释
3. 解释关键逻辑"
        llm_moonshot "$PROMPT" "kimi-k2.5" 4000
        ;;
    
    weather)
        CITY="${1:-Beijing}"
        curl -s "wttr.in/${CITY}?format=%l:+%c+%t,+%w+wind,+%h+humidity"
        ;;
    
    github)
        gh "$@"
        ;;
    
    notion)
        if [[ -z "$NOTION_API_KEY" ]]; then
            echo "❌ 未配置 NOTION_API_KEY"
            exit 1
        fi
        curl -s https://api.notion.com/v1/search \
            -H "Authorization: Bearer $NOTION_API_KEY" \
            -H "Notion-Version: 2025-09-03" \
            -H "Content-Type: application/json" \
            -d '{"query": "'"$*"'"}' | jq '.'
        ;;
    
    *)
        echo "未知 Skill: $SKILL_NAME"
        echo ""
        echo "可用 Skill:"
        echo "  通用 LLM:  moonshot, kimi, llm, ai, ask"
        echo "  内容处理:  summarize, translate, code"
        echo "  工具:      weather, github, notion"
        exit 1
        ;;
esac
