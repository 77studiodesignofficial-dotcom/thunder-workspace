# OpenClaw 凭证集成方案

## 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                     OpenClaw Skill 调用                      │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              openclaw-skill-wrapper.sh                      │
│         (自动注入凭证 + Skill 路由)                          │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              openclaw-cred-hub.sh                           │
│         (凭证管理中心)                                       │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              opencred-keychain.sh                           │
│         (macOS Keychain 存储)                               │
└─────────────────────────────────────────────────────────────┘
```

## 快速开始

### 1. 列出当前凭证
```bash
./openclaw-cred-hub.sh list
```

### 2. 存储新凭证
```bash
./openclaw-cred-hub.sh store GEMINI_API_KEY "AIza..."
./openclaw-cred-hub.sh store NOTION_API_KEY "ntn_..."
./openclaw-cred-hub.sh store OPENAI_API_KEY "sk-..."
```

### 3. 测试所有凭证
```bash
./openclaw-cred-hub.sh test
```

### 4. 使用 Skill（凭证自动注入）
```bash
# Weather（无需凭证）
./openclaw-skill-wrapper.sh weather Beijing

# Moonshot（自动使用 MOONSHOT_API_KEY）
./openclaw-skill-wrapper.sh moonshot "写一段Python代码"

# 内容总结（自动使用 GEMINI_API_KEY 或后备到 MOONSHOT）
./openclaw-skill-wrapper.sh summarize "https://example.com"

# Notion 搜索（自动使用 NOTION_API_KEY）
./openclaw-skill-wrapper.sh notion "项目计划"
```

## 与 OpenClaw 集成

### 方式一：直接调用（推荐）

在 OpenClaw 中配置工具调用：

```json
{
  "skill": "custom-command",
  "command": "/Users/titen/.openclaw/workspace/openclaw-skill-wrapper.sh",
  "env": {
    "MOONSHOT_API_KEY": "$(/Users/titen/.openclaw/workspace/opencred-keychain.sh read MOONSHOT_API_KEY)"
  }
}
```

### 方式二：环境变量注入

```bash
# 在 OpenClaw 会话开始前加载凭证
eval $(/Users/titen/.openclaw/workspace/openclaw-cred-hub.sh load)

# 现在所有 Skill 都可以直接使用环境变量
summarize "https://example.com"
```

## 已配置凭证

| 凭证名 | 状态 | 用途 |
|--------|------|------|
| MOONSHOT_API_KEY | ✅ 有效 | Moonshot API (Kimi 模型) |
| GEMINI_API_KEY | ⚠️ 未配置 | Google Gemini |
| NOTION_API_KEY | ⚠️ 未配置 | Notion API |
| OPENAI_API_KEY | ⚠️ 未配置 | OpenAI API |

## 安全特性

1. **Touch ID 保护**：每次读取凭证需指纹/密码验证
2. **内存不留存**：凭证仅在运行时注入，不写入磁盘
3. **自动过期**：Keychain 1小时后自动锁定
4. **访问日志**：所有凭证读取都记录在系统日志中

## 扩展 Skill

如需添加新 Skill，编辑 `openclaw-skill-wrapper.sh`，在 `case` 语句中添加：

```bash
mynewskill)
    export MY_API_KEY=$(/Users/titen/.openclaw/workspace/opencred-keychain.sh read MY_API_KEY)
    # 调用逻辑
    ;;
```

## 故障排除

### Keychain 锁定
```bash
# 重新解锁
security unlock-keychain openclaw-vault.keychain
```

### 凭证读取失败
```bash
# 检查 Keychain 状态
./opencred-keychain.sh list
```

### 环境变量未生效
```bash
# 使用 source 方式加载
source <(./openclaw-cred-hub.sh load)
```
