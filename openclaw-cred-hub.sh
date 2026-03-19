#!/bin/bash
# openclaw-cred-hub.sh - OpenClaw 统一凭证中心
# 自动从 Keychain 加载凭证并注入到 Skill 执行环境

set -euo pipefail

VAULT_SCRIPT="/Users/titen/.openclaw/workspace/opencred-keychain.sh"
ENV_EXPORT_FILE="${HOME}/.openclaw/.env.skill"

# 颜色输出
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

# 显示帮助
show_help() {
    cat << 'EOF'
OpenClaw 凭证中心 - 统一管理和注入 Skill 所需 API Key

用法:
    ./openclaw-cred-hub.sh <命令> [参数]

命令:
    list                列出所有已存储的凭证
    store <name> <key>  存储新凭证
    load                加载所有凭证到当前 shell（source 使用）
    run <skill-args>    在凭证注入环境下运行 Skill 命令
    test                测试所有已配置凭证的有效性
    help                显示此帮助

示例:
    # 列出凭证
    ./openclaw-cred-hub.sh list

    # 存储 Gemini API Key
    ./openclaw-cred-hub.sh store GEMINI_API_KEY "AIza..."

    # 在凭证环境下运行 summarize
    ./openclaw-cred-hub.sh run summarize "https://example.com"

    # 加载凭证到当前 shell（用于手动执行）
    eval $(./openclaw-cred-hub.sh load)

EOF
}

# 列出凭证
list_creds() {
    echo "=== 已存储凭证 ==="
    if $VAULT_SCRIPT list 2>/dev/null | grep -q .; then
        $VAULT_SCRIPT list | while read name; do
            value=$($VAULT_SCRIPT read "$name" 2>/dev/null | head -c 10)
            echo "  ✅ ${name}: ${value}..."
        done
    else
        yellow "  暂无凭证"
    fi
}

# 存储凭证
store_cred() {
    local name="$1"
    local value="$2"
    $VAULT_SCRIPT store "$name" "$value"
    green "✅ 凭证已存储: $name"
}

# 生成导出语句（供 source 使用）
load_creds() {
    # 清理旧文件
    > "$ENV_EXPORT_FILE"
    chmod 600 "$ENV_EXPORT_FILE"
    
    $VAULT_SCRIPT list 2>/dev/null | while read name; do
        value=$($VAULT_SCRIPT read "$name" 2>/dev/null)
        if [[ -n "$value" ]]; then
            echo "export ${name}='${value}'"
        fi
    done
}

# 在凭证环境下运行命令
run_with_creds() {
    # 创建临时环境文件
    local temp_env=$(mktemp)
    trap "rm -f $temp_env" EXIT
    
    load_creds > "$temp_env"
    
    # 显示加载的凭证
    echo "=== 已加载凭证 ==="
    grep "^export" "$temp_env" | sed 's/export /  🗝️  /' | cut -d= -f1
    echo ""
    
    # 执行命令
    green "=== 执行命令 ==="
    env -i $(cat "$temp_env" | xargs) "$@"
}

# 测试凭证有效性
test_creds() {
    echo "=== 测试凭证有效性 ==="
    
    # 测试 MOONSHOT_API_KEY
    if $VAULT_SCRIPT read MOONSHOT_API_KEY >/dev/null 2>&1; then
        local key=$($VAULT_SCRIPT read MOONSHOT_API_KEY)
        if curl -s https://api.moonshot.cn/v1/models \
            -H "Authorization: Bearer $key" \
            | grep -q "kimi-k2.5"; then
            green "  ✅ MOONSHOT_API_KEY: 有效"
        else
            red "  ❌ MOONSHOT_API_KEY: 无效或过期"
        fi
    else
        yellow "  ⚠️  MOONSHOT_API_KEY: 未配置"
    fi
    
    # 测试 GEMINI_API_KEY
    if $VAULT_SCRIPT read GEMINI_API_KEY >/dev/null 2>&1; then
        local key=$($VAULT_SCRIPT read GEMINI_API_KEY)
        if curl -s "https://generativelanguage.googleapis.com/v1/models?key=$key" \
            | grep -q "gemini"; then
            green "  ✅ GEMINI_API_KEY: 有效"
        else
            red "  ❌ GEMINI_API_KEY: 无效或过期"
        fi
    else
        yellow "  ⚠️  GEMINI_API_KEY: 未配置"
    fi
    
    # 测试 NOTION_API_KEY
    if $VAULT_SCRIPT read NOTION_API_KEY >/dev/null 2>&1; then
        local key=$($VAULT_SCRIPT read NOTION_API_KEY)
        if curl -s https://api.notion.com/v1/users/me \
            -H "Authorization: Bearer $key" \
            -H "Notion-Version: 2025-09-03" \
            | grep -q "type"; then
            green "  ✅ NOTION_API_KEY: 有效"
        else
            red "  ❌ NOTION_API_KEY: 无效或过期"
        fi
    else
        yellow "  ⚠️  NOTION_API_KEY: 未配置"
    fi
    
    # 测试 OPENAI_API_KEY
    if $VAULT_SCRIPT read OPENAI_API_KEY >/dev/null 2>&1; then
        local key=$($VAULT_SCRIPT read OPENAI_API_KEY)
        if curl -s https://api.openai.com/v1/models \
            -H "Authorization: Bearer $key" \
            | grep -q "gpt"; then
            green "  ✅ OPENAI_API_KEY: 有效"
        else
            red "  ❌ OPENAI_API_KEY: 无效或过期"
        fi
    else
        yellow "  ⚠️  OPENAI_API_KEY: 未配置"
    fi
}

# 主入口
case "${1:-help}" in
    list) list_creds ;;
    store) store_cred "$2" "$3" ;;
    load) load_creds ;;
    run) shift; run_with_creds "$@" ;;
    test) test_creds ;;
    help|*) show_help ;;
esac
