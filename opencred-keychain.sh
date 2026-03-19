#!/bin/bash
# opencred-keychain.sh - macOS Keychain 凭证管理
# 利用系统 Keychain，支持 Touch ID / 密码解锁

KEYCHAIN="openclaw-vault"

# 初始化（创建专用 Keychain）
init_keychain() {
    security create-keychain -p "" "${KEYCHAIN}.keychain" 2>/dev/null || true
    security list-keychains -s "${KEYCHAIN}.keychain" ~/Library/Keychains/login.keychain-db
    security set-keychain-settings "${KEYCHAIN}.keychain" -t 3600 -l  # 1小时后锁定
    echo "✅ Keychain '${KEYCHAIN}' 已配置"
    echo "💡 可在 '钥匙串访问' 中查看"
}

# 存储凭证
store_cred() {
    local name="$1"
    local value="$2"
    
    # 删除旧值（如果存在）
    security delete-generic-password -s "openclaw" -a "${name}" "${KEYCHAIN}.keychain" 2>/dev/null || true
    
    # 添加新值
    security add-generic-password -s "openclaw" -a "${name}" -w "${value}" \
        -U "${KEYCHAIN}.keychain"
    
    echo "✅ 已存储: ${name}"
}

# 读取凭证（会触发 Touch ID / 密码）
read_cred() {
    local name="$1"
    security find-generic-password -s "openclaw" -a "${name}" -w \
        "${KEYCHAIN}.keychain" 2>/dev/null
}

# 列出所有凭证
list_creds() {
    security dump-keychain "${KEYCHAIN}.keychain" 2>/dev/null | \
        grep -A1 "openclaw" | grep "acct" | cut -d'"' -f4
}

# 导出为环境变量文件
export_env_file() {
    local output="${1:-.env.openclaw}"
    echo "# OpenClaw Environment Variables" > "${output}"
    echo "# Generated: $(date)" >> "${output}"
    echo "" >> "${output}"
    
    for name in $(list_creds); do
        local value=$(read_cred "${name}")
        echo "export ${name}='${value}'" >> "${output}"
    done
    
    chmod 600 "${output}"
    echo "✅ 已导出到: ${output}"
    echo "⚠️  此文件包含明文密钥，使用后请删除！"
}

# 主入口
case "$1" in
    init) init_keychain ;;
    store) store_cred "$2" "$3" ;;
    read) read_cred "$2" ;;
    list) list_creds ;;
    export) export_env_file "$2" ;;
    *)
        echo "用法: $0 {init|store <name> <value>|read <name>|list|export [file]}"
        exit 1
        ;;
esac
