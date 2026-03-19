#!/bin/bash
# openclaw-skill-wrapper.sh - Skill 执行包装器
# 自动注入 Keychain 凭证到 Skill 执行环境

SKILL_NAME="$1"
shift

# 从 Keychain 加载凭证
MOONSHOT_API_KEY=$(/Users/titen/.openclaw/workspace/opencred-keychain.sh read MOONSHOT_API_KEY 2>/dev/null || echo "")
GEMINI_API_KEY=$(/Users/titen/.openclaw/workspace/opencred-keychain.sh read GEMINI_API_KEY 2>/dev/null || echo "")
NOTION_API_KEY=$(/Users/titen/.openclaw/workspace/opencred-keychain.sh read NOTION_API_KEY 2>/dev/null || echo "")
OPENAI_API_KEY=$(/Users/titen/.openclaw/workspace/opencred-keychain.sh read OPENAI_API_KEY 2>/dev/null || echo "")

# 根据 Skill 类型执行相应命令
case "$SKILL_NAME" in
    moonshot|kimi)
        # 直接调用 Moonshot API
        curl -s https://api.moonshot.cn/v1/chat/completions \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $MOONSHOT_API_KEY" \
            -d '{
                "model": "kimi-k2.5",
                "messages": [{"role": "user", "content": "'"$*"'"}],
                "max_tokens": 2000
            }' | jq -r '.choices[0].message.content // .choices[0].message.reasoning_content // "API 调用失败"'
        ;;
    
    llm|ai|ask)
        # 通用 LLM 调用（优先 OpenAI，后备 Moonshot）
        if [[ -n "$OPENAI_API_KEY" ]]; then
            curl -s https://api.openai.com/v1/chat/completions \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $OPENAI_API_KEY" \
                -d '{
                    "model": "gpt-4o-mini",
                    "messages": [{"role": "user", "content": "'"$*"'"}],
                    "max_tokens": 2000
                }' | jq -r '.choices[0].message.content // "API 调用失败"'
        else
            # 后备到 Moonshot
            curl -s https://api.moonshot.cn/v1/chat/completions \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $MOONSHOT_API_KEY" \
                -d '{
                    "model": "moonshot-v1-8k",
                    "messages": [{"role": "user", "content": "'"$*"'"}],
                    "max_tokens": 2000
                }' | jq -r '.choices[0].message.content // "API 调用失败"'
        fi
        ;;
    
    summarize|summary)
        # 使用 Moonshot 作为通用 LLM 进行总结
        echo "📝 使用 Moonshot 进行内容总结..."
        
        CONTENT="$1"
        
        # 如果是 URL，获取内容
        if [[ "$CONTENT" =~ ^https?:// ]]; then
            CONTENT=$(curl -sL "$CONTENT" 2>/dev/null | head -c 8000 || echo "")
        fi
        
        # 构建总结提示
        PROMPT="请对以下内容进行简洁总结，提炼核心要点：

${CONTENT}

请用中文回复，格式：
📌 核心观点：
• 要点1
• 要点2
• 要点3"
        
        curl -s https://api.moonshot.cn/v1/chat/completions \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $MOONSHOT_API_KEY" \
            -d '{
                "model": "moonshot-v1-128k",
                "messages": [{"role": "user", "content": "'"${PROMPT}"'"}],
                "max_tokens": 1000
            }' | jq -r '.choices[0].message.content // "总结失败"'
        ;;
    
    translate)
        # 翻译功能
        TEXT="$1"
        TARGET_LANG="${2:-中文}"
        
        PROMPT="请将以下内容翻译成${TARGET_LANG}：${TEXT}"
        
        curl -s https://api.moonshot.cn/v1/chat/completions \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $MOONSHOT_API_KEY" \
            -d '{
                "model": "moonshot-v1-8k",
                "messages": [{"role": "user", "content": "'"${PROMPT}"'"}],
                "max_tokens": 2000
            }' | jq -r '.choices[0].message.content // "翻译失败"'
        ;;
    
    code)
        # 代码生成
        PROMPT="请编写代码：'"$*"'

要求：
1. 代码简洁高效
2. 包含必要注释
3. 解释关键逻辑"
        
        curl -s https://api.moonshot.cn/v1/chat/completions \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $MOONSHOT_API_KEY" \
            -d '{
                "model": "kimi-k2.5",
                "messages": [{"role": "user", "content": "'"${PROMPT}"'"}],
                "max_tokens": 4000
            }' | jq -r '.choices[0].message.content // "代码生成失败"'
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
    
    weather)
        curl -s "wttr.in/${*:-Beijing}?format=%l:+%c+%t,+%w+wind,+%h+humidity"
        ;;
    
    github)
        gh "$@"
        ;;
    
    *)
        echo "未知 Skill: $SKILL_NAME"
        echo ""
        echo "可用 Skill:"
        echo "  通用 LLM:    moonshot, kimi, llm, ai, ask"
        echo "  内容处理:    summarize, summary, translate, code"
        echo "  生产力:      notion, github"
        echo "  工具:        weather"
        echo ""
        echo "Moonshot 作为通用 Key: 已支持 llm/summarize/translate/code"
        exit 1
        ;;
esac
