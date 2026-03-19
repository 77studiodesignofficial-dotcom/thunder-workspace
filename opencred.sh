#!/bin/bash
# opencred.sh - 极简凭证管理器
# 存储位置: ~/.openclaw/.vault/
# 主密钥: ~/.openclaw/.vault/.master.key (由用户妥善保管)

VAULT_DIR="${HOME}/.openclaw/.vault"
MASTER_KEY_FILE="${VAULT_DIR}/.master.key"

# 初始化保险库
init_vault() {
    mkdir -p "${VAULT_DIR}"
    if [[ ! -f "${MASTER_KEY_FILE}" ]]; then
        # 生成 256-bit 主密钥
        openssl rand -base64 32 > "${MASTER_KEY_FILE}"
        chmod 600 "${MASTER_KEY_FILE}"
        echo "✅ 保险库已初始化"
        echo "🔑 主密钥位置: ${MASTER_KEY_FILE}"
        echo "⚠️  请备份此密钥，丢失后无法恢复凭证！"
    fi
}

# 存储凭证
store_cred() {
    local name="$1"
    local value="$2"
    local key=$(cat "${MASTER_KEY_FILE}")
    
    # AES-256-GCM 加密
    echo "${value}" | openssl enc -aes-256-cbc -a -salt -pbkdf2 -pass pass:"${key}" \
        > "${VAULT_DIR}/${name}.enc"
    
    echo "✅ 已存储: ${name}"
}

# 读取凭证
read_cred() {
    local name="$1"
    local key=$(cat "${MASTER_KEY_FILE}")
    
    if [[ ! -f "${VAULT_DIR}/${name}.enc" ]]; then
        echo "❌ 凭证不存在: ${name}" >&2
        return 1
    fi
    
    openssl enc -aes-256-cbc -d -a -pbkdf2 -pass pass:"${key}" \
        -in "${VAULT_DIR}/${name}.enc" 2>/dev/null
}

# 列出所有凭证
list_creds() {
    ls -1 "${VAULT_DIR}"/*.enc 2>/dev/null | while read f; do
        basename "$f" .enc
    done
}

# 删除凭证
delete_cred() {
    local name="$1"
    rm -f "${VAULT_DIR}/${name}.enc"
    echo "🗑️  已删除: ${name}"
}

# 导出为环境变量
export_env() {
    local prefix="${1:-OPENCLAW}"
    for f in "${VAULT_DIR}"/*.enc; do
        [[ -f "$f" ]] || continue
        local name=$(basename "$f" .enc)
        local value=$(read_cred "$name")
        export "${prefix}_${name}=${value}"
    done
    echo "✅ 已导出所有凭证到环境变量"
}

# 主入口
case "$1" in
    init) init_vault ;;
    store) store_cred "$2" "$3" ;;
    read) read_cred "$2" ;;
    list) list_creds ;;
    delete) delete_cred "$2" ;;
    export) export_env "$2" ;;
    *)
        echo "用法: $0 {init|store <name> <value>|read <name>|list|delete <name>|export}"
        exit 1
        ;;
esac
