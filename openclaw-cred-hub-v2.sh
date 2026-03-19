#!/bin/bash
# openclaw-cred-hub-v2.sh - 双模式凭证管理中心
# 开发模式: .env 文件（便利）
# 生产模式: Keychain（安全）

set -euo pipefail

VAULT_SCRIPT="/Users/titen/.openclaw/workspace/opencred-keychain.sh"
ENV_FILE="${HOME}/.openclaw/.env.skill"
MODE="${OPENCLAW_CRED_MODE:-keychain}"  # keychain | envfile

red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

show_help() {
    cat << 'EOF'
OpenClaw 凭证中心 v2.0 - 双模式管理

模式选择（设置环境变量 OPENCLAW_CRED_MODE）：
  keychain  - 使用 macOS Keychain（安全，需 Touch ID）
  envfile   - 使用 .env 文件（便利，开发推荐）

命令:
    list                    列出所有凭证
    store <name> <key>      存储新凭证（根据模式）
    load                    导出所有凭证为环境变量
    test                    测试所有凭证有效性
    switch <mode>           切换模式 (keychain/envfile)
    help                    显示此帮助

快速开始:
    # 切换到开发模式（推荐日常使用）
    ./openclaw-cred-hub-v2.sh switch envfile
    
    # 存储凭证
    ./openclaw-cred-hub-v2.sh store MOONSHOT_API_KEY "sk-..."
    
    # 加载到当前 shell
    eval $(./openclaw-cred-hub-v2.sh load)

EOF
}

get_mode() {
    if [[ -f "$ENV_FILE" ]] && [[ "$MODE" == "envfile" ]]; then
        echo "envfile"
    else
        echo "keychain"
    fi
}

list_creds() {
    local mode=$(get_mode)
    echo "=== 已存储凭证 [模式: $mode] ==="
    
    if [[ "$mode" == "envfile" ]]; then
        if [[ -f "$ENV_FILE" ]]; then
            grep "^export" "$ENV_FILE" 2>/dev/null | sed 's/export /  ✅ /' | cut -d'=' -f1
        else
            yellow "  暂无凭证"
        fi
    else
        $VAULT_SCRIPT list 2>/dev/null | while read name; do
            echo "  ✅ ${name}"
        done || yellow "  Keychain 锁定或为空"
    fi
}

store_cred() {
    local name="$1"
    local value="$2"
    local mode=$(get_mode)
    
    if [[ "$mode" == "envfile" ]]; then
        # 开发模式：写入 .env 文件
        mkdir -p "$(dirname "$ENV_FILE")"
        chmod 700 "$(dirname "$ENV_FILE")"
        
        # 删除旧值
        if [[ -f "$ENV_FILE" ]]; then
            grep -v "^export ${name}=" "$ENV_FILE" > "${ENV_FILE}.tmp" || true
            mv "${ENV_FILE}.tmp" "$ENV_FILE"
        fi
        
        # 添加新值
        echo "export ${name}='${value}'" >> "$ENV_FILE"
        chmod 600 "$ENV_FILE"
        green "✅ 已存储到 .env: $name"
    else
        # 生产模式：Keychain
        $VAULT_SCRIPT store "$name" "$value"
        green "✅ 已存储到 Keychain: $name"
    fi
}

load_creds() {
    local mode=$(get_mode)
    
    if [[ "$mode" == "envfile" ]]; then
        if [[ -f "$ENV_FILE" ]]; then
            cat "$ENV_FILE"
        fi
    else
        $VAULT_SCRIPT list 2>/dev/null | while read name; do
            value=$($VAULT_SCRIPT read "$name" 2>/dev/null || echo "")
            if [[ -n "$value" ]]; then
                echo "export ${name}='${value}'"
            fi
        done
    fi
}

test_creds() {
    echo "=== 测试凭证有效性 ==="
    
    # 加载凭证
    local temp_env=$(mktemp)
    load_creds > "$temp_env"
    source "$temp_env"
    rm -f "$temp_env"
    
    # 测试 MOONSHOT
    if [[ -n "${MOONSHOT_API_KEY:-}" ]]; then
        if curl -s https://api.moonshot.cn/v1/models \
            -H "Authorization: Bearer $MOONSHOT_API_KEY" 2>/dev/null | grep -q "kimi"; then
            green "  ✅ MOONSHOT_API_KEY: 有效"
        else
            red "  ❌ MOONSHOT_API_KEY: 无效"
        fi
    else
        yellow "  ⚠️  MOONSHOT_API_KEY: 未配置"
    fi
    
    # 其他 Key 同理...
    for key in GEMINI_API_KEY NOTION_API_KEY OPENAI_API_KEY; do
        if [[ -n "${!key:-}" ]]; then
            green "  ✅ ${key}: 已配置"
        else
            yellow "  ⚠️  ${key}: 未配置"
        fi
    done
}

switch_mode() {
    local new_mode="$1"
    
    if [[ "$new_mode" == "envfile" ]]; then
        echo "export OPENCLAW_CRED_MODE=envfile" > "${HOME}/.openclaw/.mode"
        green "✅ 已切换到开发模式 (.env 文件)"
        echo "   凭证将存储在: $ENV_FILE"
        echo "   建议：此模式适合开发，生产环境请用 keychain 模式"
    elif [[ "$new_mode" == "keychain" ]]; then
        echo "export OPENCLAW_CRED_MODE=keychain" > "${HOME}/.openclaw/.mode"
        green "✅ 已切换到生产模式 (Keychain)"
        echo "   凭证将存储在: macOS Keychain"
        echo "   特点：Touch ID 保护，更安全"
    else
        red "❌ 未知模式: $new_mode"
        echo "   可用模式: envfile, keychain"
        exit 1
    fi
}

# 加载模式配置
if [[ -f "${HOME}/.openclaw/.mode" ]]; then
    source "${HOME}/.openclaw/.mode"
fi

case "${1:-help}" in
    list) list_creds ;;
    store) store_cred "$2" "$3" ;;
    load) load_creds ;;
    test) test_creds ;;
    switch) switch_mode "$2" ;;
    help|*) show_help ;;
esac
