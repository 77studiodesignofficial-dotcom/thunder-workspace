#!/bin/bash
# openclaw-with-creds.sh - 自动注入凭证的 OpenClaw 包装器
# 使用方法: ./openclaw-with-creds.sh <command>
# 示例: ./openclaw-with-creds.sh summarize "https://example.com"

VAULT_SCRIPT="/Users/titen/.openclaw/workspace/opencred-keychain.sh"

# 导出所有凭证到临时环境文件
TEMP_ENV=$(mktemp)
trap "rm -f ${TEMP_ENV}" EXIT

# 从 Keychain 读取所有凭证并导出
for name in $(${VAULT_SCRIPT} list); do
    value=$(${VAULT_SCRIPT} read "${name}")
    export "${name}=${value}"
done

# 执行原始命令
exec "$@"
