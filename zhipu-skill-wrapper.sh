#!/bin/bash
# zhipu-skill-wrapper.sh - 智谱 GLM Skill 执行包装器
# 方案C：零成本试用 - 使用免费模型 GLM-4-Flash

ZHIPU_API_KEY="${ZHIPU_API_KEY:-2802ae35afa8495aa7c9b67fb9868ce5.8hoClVLHKF25yy4t}"
ZHIPU_BASE_URL="https://open.bigmodel.cn/api/paas/v4"

# 颜色输出
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

# 调用智谱 API
call_zhipu() {
    local model="$1"
    local messages="$2"
    local max_tokens="${3:-2000}"
    
    if [[ -z "$ZHIPU_API_KEY" ]]; then
        red "❌ 未配置 ZHIPU_API_KEY"
        return 1
    fi
    
    curl -s -X POST \
        "${ZHIPU_BASE_URL}/chat/completions" \
        -H "Authorization: Bearer ${ZHIPU_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"${model}\",
            \"messages\": ${messages},
            \"max_tokens\": ${max_tokens},
            \"temperature\": 0.7
        }" 2>/dev/null
}

# 主入口
case "$1" in
    test|status)
        echo "🧪 测试智谱 API 连接..."
        result=$(call_zhipu "glm-4-flash" '[{"role":"user","content":"你好，简单回复：智谱API测试成功"}]' 50)
        
        if echo "$result" | grep -q "choices"; then
            green "✅ 智谱 API 连接正常"
            echo ""
            echo "可用免费模型："
            echo "  • GLM-4-Flash - 通用对话"
            echo "  • GLM-Z1-Flash - 推理任务"
            echo ""
            echo "回复内容："
            echo "$result" | jq -r '.choices[0].message.content // "解析失败"' 2>/dev/null || echo "$result"
        else
            red "❌ API 连接失败"
            echo "错误信息："
            echo "$result" | jq '.' 2>/dev/null || echo "$result"
            return 1
        fi
        ;;
    
    chat|ask)
        shift
        prompt="$*"
        
        if [[ -z "$prompt" ]]; then
            red "❌ 请输入提示内容"
            echo "用法: ./zhipu-skill-wrapper.sh chat '你的问题'"
            exit 1
        fi
        
        yellow "🤖 智谱 GLM-4-Flash 思考中..."
        
        # 转义特殊字符
        prompt_escaped=$(echo "$prompt" | jq -Rs '.[:-1]')
        
        result=$(call_zhipu "glm-4-flash" "[{\"role\": \"user\", \"content\": ${prompt_escaped}}]" 2000)
        
        if echo "$result" | grep -q "choices"; then
            content=$(echo "$result" | jq -r '.choices[0].message.content // empty' 2>/dev/null)
            if [[ -n "$content" ]]; then
                echo "$content"
            else
                red "⚠️  返回内容为空"
                echo "$result" | jq '.' 2>/dev/null
            fi
        else
            red "❌ 调用失败"
            echo "$result" | jq '.error.message // .' 2>/dev/null || echo "$result"
        fi
        ;;
    
    reasoning|reason)
        shift
        prompt="$*"
        
        if [[ -z "$prompt" ]]; then
            red "❌ 请输入提示内容"
            exit 1
        fi
        
        yellow "🧠 智谱 GLM-Z1-Flash 推理中..."
        
        prompt_escaped=$(echo "$prompt" | jq -Rs '.[:-1]')
        
        result=$(call_zhipu "glm-z1-flash" "[{\"role\": \"user\", \"content\": ${prompt_escaped}}]" 2000)
        
        if echo "$result" | grep -q "choices"; then
            content=$(echo "$result" | jq -r '.choices[0].message.content // empty' 2>/dev/null)
            reasoning=$(echo "$result" | jq -r '.choices[0].message.reasoning_content // empty' 2>/dev/null)
            
            if [[ -n "$reasoning" ]]; then
                echo "💭 推理过程："
                echo "$reasoning"
                echo ""
            fi
            
            echo "📝 最终答案："
            echo "$content"
        else
            red "❌ 调用失败"
            echo "$result" | jq '.error.message // .' 2>/dev/null
        fi
        ;;
    
    code|programming)
        shift
        prompt="$*"
        
        if [[ -z "$prompt" ]]; then
            red "❌ 请输入编程需求"
            exit 1
        fi
        
        yellow "💻 智谱 GLM-4-Flash 编程中..."
        
        full_prompt="请编写代码：${prompt}

要求：
1. 代码简洁高效
2. 包含必要注释
3. 解释关键逻辑
4. 使用最佳实践"
        
        prompt_escaped=$(echo "$full_prompt" | jq -Rs '.[:-1]')
        
        result=$(call_zhipu "glm-4-flash" "[{\"role\": \"user\", \"content\": ${prompt_escaped}}]" 3000)
        
        if echo "$result" | grep -q "choices"; then
            echo "$result" | jq -r '.choices[0].message.content // "生成失败"' 2>/dev/null
        else
            red "❌ 调用失败"
        fi
        ;;
    
    help|*)
        echo "智谱 GLM Skill 包装器 - 方案C（零成本试用）"
        echo ""
        echo "用法:"
        echo "  ./zhipu-skill-wrapper.sh test              # 测试API连接"
        echo "  ./zhipu-skill-wrapper.sh chat '问题'       # 通用对话（GLM-4-Flash）"
        echo "  ./zhipu-skill-wrapper.sh reasoning '问题'  # 推理任务（GLM-Z1-Flash）"
        echo "  ./zhipu-skill-wrapper.sh code '需求'       # 代码生成"
        echo ""
        echo "模型说明："
        echo "  • GLM-4-Flash: 免费，日常对话和简单代码"
        echo "  • GLM-Z1-Flash: 免费，推理和数学任务"
        echo ""
        echo "所有模型均来自智谱 bigmodel.cn，零成本试用"
        ;;
esac
