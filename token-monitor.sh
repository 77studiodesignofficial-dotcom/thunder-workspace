#!/bin/bash
# Token Monitor - 监控三个 AI 平台的 Token 余额
# 创建时间: 2026-03-18
# 用法: ./token-monitor.sh [--alert]

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.openclaw/openclaw.json"
LOG_DIR="$HOME/.openclaw/logs"
LOG_FILE="$LOG_DIR/token-monitor.log"
STATE_FILE="$HOME/.openclaw/token-state.json"
ALERT_THRESHOLD_PERCENT=20  # 低于 20% 时告警

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 确保日志目录存在
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 从配置文件提取 API Key
extract_api_key() {
    local provider="$1"
    if command -v jq &> /dev/null; then
        # 尝试多个可能的路径
        local key=""
        key=$(jq -r ".models.providers.\"$provider\".apiKey // empty" "$CONFIG_FILE" 2>/dev/null)
        if [ -z "$key" ] || [ "$key" = "null" ]; then
            key=$(jq -r ".models.providers.$provider.apiKey // empty" "$CONFIG_FILE" 2>/dev/null)
        fi
        echo "$key"
    else
        # 简单的正则提取（无 jq 时）
        grep -o "\"$provider\"[^}]*apiKey[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$CONFIG_FILE" 2>/dev/null | \
            sed 's/.*apiKey[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1 || echo ""
    fi
}

# 查询 OpenAI 余额
check_openai() {
    local api_key="$1"
    
    if [ -z "$api_key" ]; then
        echo '{"status":"error","message":"API Key not found"}'
        return
    fi
    
    log "查询 OpenAI 使用情况..."
    
    # OpenAI Usage API
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer $api_key" \
        "https://api.openai.com/v1/usage" 2>/dev/null || echo -e "\n000")
    
    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        # OpenAI 返回的是使用量，不是余额
        # 格式化输出
        echo "{\"status\":\"ok\",\"provider\":\"openai\",\"data\":$body}"
    else
        echo "{\"status\":\"error\",\"provider\":\"openai\",\"code\":$http_code,\"message\":\"Failed to fetch\"}"
    fi
}

# 查询 Moonshot 余额
check_moonshot() {
    local api_key="$1"
    
    if [ -z "$api_key" ]; then
        echo '{"status":"error","message":"API Key not found"}'
        return
    fi
    
    log "查询 Moonshot 余额..."
    
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer $api_key" \
        "https://api.moonshot.cn/v1/users/me/balance" 2>/dev/null || echo -e "\n000")
    
    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        echo "{\"status\":\"ok\",\"provider\":\"moonshot\",\"data\":$body}"
    else
        echo "{\"status\":\"error\",\"provider\":\"moonshot\",\"code\":$http_code,\"message\":\"Failed to fetch\"}"
    fi
}

# 查询 GLM Coding 余额
check_glm_coding() {
    local api_key="$1"
    
    if [ -z "$api_key" ]; then
        echo '{"status":"error","message":"API Key not found"}'
        return
    fi
    
    log "查询 GLM Coding 余额..."
    
    # GLM Coding 的余额查询 API - 多个可能的端点
    local endpoints=(
        "https://open.bigmodel.cn/api/paas/v4/balance"
        "https://open.bigmodel.cn/api/coding/paas/v4/balance"
        "https://open.bigmodel.cn/api/paas/v4/account/balance"
    )
    
    for endpoint in "${endpoints[@]}"; do
        local response
        response=$(curl -s -w "\n%{http_code}" \
            -H "Authorization: Bearer $api_key" \
            "$endpoint" 2>/dev/null || echo -e "\n000")
        
        local http_code=$(echo "$response" | tail -1)
        local body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ]; then
            echo "{\"status\":\"ok\",\"provider\":\"glm-coding\",\"endpoint\":\"$endpoint\",\"data\":$body}"
            return
        fi
    done
    
    # 所有端点都失败，返回最后一个响应
    echo "{\"status\":\"error\",\"provider\":\"glm-coding\",\"code\":$http_code,\"message\":\"所有 API 端点均不可用，请检查智谱官方文档\"}"
}

# 格式化输出结果
format_result() {
    local json="$1"
    
    # 跳过日志行
    json=$(echo "$json" | grep -E '^\{' | tail -1)
    
    local provider=$(echo "$json" | jq -r '.provider // "unknown"' 2>/dev/null || echo "unknown")
    local status=$(echo "$json" | jq -r '.status // "unknown"' 2>/dev/null || echo "unknown")
    
    if [ "$status" = "ok" ]; then
        case "$provider" in
            "openai")
                # OpenAI 返回使用量数据
                local total_tokens=$(echo "$json" | jq -r '.data.total_tokens // "N/A"' 2>/dev/null)
                echo -e "${GREEN}✅ OpenAI${NC}: 使用量已获取 (总 tokens: $total_tokens)"
                ;;
            "moonshot")
                local balance=$(echo "$json" | jq -r '.data.data.available_balance // .data.data.total_balance // "N/A"' 2>/dev/null)
                local cash=$(echo "$json" | jq -r '.data.data.cash_balance // "N/A"' 2>/dev/null)
                echo -e "${GREEN}✅ Moonshot${NC}: 可用余额 ¥$balance (现金: ¥$cash)"
                ;;
            "glm-coding")
                local balance=$(echo "$json" | jq -r '.data.balance // .data.data.balance // "N/A"' 2>/dev/null)
                local tokens=$(echo "$json" | jq -r '.data.totalTokens // .data.data.totalTokens // "N/A"' 2>/dev/null)
                echo -e "${GREEN}✅ GLM Coding${NC}: 余额 $tokens tokens (¥$balance)"
                ;;
            *)
                echo -e "${GREEN}✅ $provider${NC}: 数据已获取"
                ;;
        esac
    else
        local message=$(echo "$json" | jq -r '.message // "Unknown error"' 2>/dev/null)
        local code=$(echo "$json" | jq -r '.code // ""' 2>/dev/null)
        echo -e "${RED}❌ $provider${NC}: $message (HTTP $code)"
    fi
}

# 保存状态到文件
save_state() {
    local openai_result="$1"
    local moonshot_result="$2"
    local glm_result="$3"
    
    # 清理日志行，只保留 JSON
    local openai_json=$(echo "$openai_result" | grep -E '^\{' | tail -1)
    local moonshot_json=$(echo "$moonshot_result" | grep -E '^\{' | tail -1)
    local glm_json=$(echo "$glm_result" | grep -E '^\{' | tail -1)
    
    cat > "$STATE_FILE" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "openai": ${openai_json:-"{}"},
  "moonshot": ${moonshot_json:-"{}"},
  "glmCoding": ${glm_json:-"{}"}
}
EOF
    log "状态已保存到 $STATE_FILE"
}

# 发送告警（通过 Telegram）
send_alert() {
    local message="$1"
    
    # 尝试使用 OpenClaw 的消息发送功能
    if [ -f "$HOME/.openclaw/.env.skill" ]; then
        # 从配置中提取 Telegram Bot Token 和 Chat ID
        local bot_token=$(grep "TELEGRAM_BOT_TOKEN" "$HOME/.openclaw/.env.skill" 2>/dev/null | cut -d'=' -f2)
        local chat_id=$(grep "TELEGRAM_CHAT_ID" "$HOME/.openclaw/.env.skill" 2>/dev/null | cut -d'=' -f2)
        
        if [ -n "$bot_token" ] && [ -n "$chat_id" ]; then
            curl -s -X POST "https://api.telegram.org/bot$bot_token/sendMessage" \
                -d "chat_id=$chat_id" \
                -d "text=⚠️ Token 余额告警%0A%0A$message" \
                -d "parse_mode=HTML" > /dev/null 2>&1
            log "告警已发送到 Telegram"
        fi
    fi
}

# 主函数
main() {
    local alert_mode=false
    
    if [ "$1" = "--alert" ] || [ "$1" = "-a" ]; then
        alert_mode=true
    fi
    
    echo ""
    echo "========================================"
    echo "  Token Monitor - AI 平台余额监控"
    echo "  时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""
    
    # 提取 API Keys
    local openai_key=$(extract_api_key "openai")
    local moonshot_key=$(extract_api_key "moonshot")
    local glm_key=$(extract_api_key "glm-coding")
    
    # 检查各平台
    local openai_result=$(check_openai "$openai_key")
    local moonshot_result=$(check_moonshot "$moonshot_key")
    local glm_result=$(check_glm_coding "$glm_key")
    
    # 输出结果
    format_result "$openai_result"
    format_result "$moonshot_result"
    format_result "$glm_result"
    
    # 保存状态
    save_state "$openai_result" "$moonshot_result" "$glm_result"
    
    # 告警检查（如果启用）
    if $alert_mode; then
        local alert_messages=""
        
        # 检查 Moonshot 余额
        local moonshot_balance=$(echo "$moonshot_result" | jq -r '.data.data.total_balance // 0' 2>/dev/null)
        if [ "$(echo "$moonshot_balance < 10" | bc 2>/dev/null || echo 0)" = "1" ]; then
            alert_messages+="Moonshot 余额不足: ¥$moonshot_balance\n"
        fi
        
        # 检查 GLM 余额（如果有具体数值）
        # 这里需要根据实际 API 返回调整
        
        if [ -n "$alert_messages" ]; then
            send_alert "$alert_messages"
        fi
    fi
    
    echo ""
    echo "========================================"
    
    # 返回 JSON 供程序调用
    if [ "$1" = "--json" ]; then
        echo "{\"openai\":$openai_result,\"moonshot\":$moonshot_result,\"glmCoding\":$glm_result}"
    fi
}

# 运行
main "$@"
