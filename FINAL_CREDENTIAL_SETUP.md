# OpenClaw 凭证管理 - 最终方案

## 🎯 方案概述

采用 **双模式设计**：
- **开发模式** (`.env` 文件)：便利，适合日常使用
- **生产模式** (Keychain)：安全，适合敏感环境

---

## 📁 文件结构

```
~/.openclaw/
├── .env.skill              # 开发模式凭证存储
├── .mode                   # 当前模式配置
├── openclaw-cred-hub-v2.sh       # 凭证管理脚本
└── openclaw-skill-wrapper-v2.sh  # Skill 执行脚本
```

---

## 🚀 快速配置（Boss 手动执行）

### 步骤 1：创建 .env 文件（开发模式）

```bash
# 创建凭证文件
cat > ~/.openclaw/.env.skill << 'EOF'
export MOONSHOT_API_KEY='sk-kRmUsMw579tgEAz7PVsszu9pzdt8NZMGF5ZBfB9jgLGG4klw'
EOF

# 设置权限（仅本人可读）
chmod 600 ~/.openclaw/.env.skill

# 设置开发模式
echo "export OPENCLAW_CRED_MODE=envfile" > ~/.openclaw/.mode
```

### 步骤 2：验证配置

```bash
cd /Users/titen/.openclaw/workspace

# 列出凭证
./openclaw-cred-hub-v2.sh list

# 测试有效性
./openclaw-cred-hub-v2.sh test
```

### 步骤 3：使用 Skill

```bash
# 天气查询（无需 Key）
./openclaw-skill-wrapper-v2.sh weather Shanghai

# Moonshot 对话
./openclaw-skill-wrapper-v2.sh llm "你好，我是 Boss Titen"

# 内容总结
./openclaw-skill-wrapper-v2.sh summarize "https://example.com/article"

# 翻译
./openclaw-skill-wrapper-v2.sh translate "Hello World" "中文"

# 代码生成
./openclaw-skill-wrapper-v2.sh code "写一个快速排序算法"
```

---

## 📋 Moonshot 作为通用 Key 的能力

| 功能 | 命令 | 状态 |
|------|------|------|
| 通用对话 | `llm "问题"` | ✅ 支持 |
| 内容总结 | `summarize "URL/文本"` | ✅ 支持 |
| 翻译 | `translate "文本" "目标语言"` | ✅ 支持 |
| 代码生成 | `code "需求"` | ✅ 支持 |
| 天气查询 | `weather "城市"` | ✅ 无需 Key |
| GitHub 操作 | `github "命令"` | ✅ 使用 gh CLI |
| Notion 操作 | `notion "搜索"` | ❌ 需单独配置 |
| 图片生成 | - | ❌ 不支持 |
| 语音转文字 | - | ❌ 不支持 |

**结论**：Moonshot 可覆盖 80% 文本类需求

---

## 🔐 添加其他 API Key

当需要其他 Key 时，执行：

```bash
# 进入工作目录
cd /Users/titen/.openclaw/workspace

# 添加 Gemini Key
./openclaw-cred-hub-v2.sh store GEMINI_API_KEY "AIza..."

# 添加 Notion Key
./openclaw-cred-hub-v2.sh store NOTION_API_KEY "ntn_..."

# 添加 OpenAI Key
./openclaw-cred-hub-v2.sh store OPENAI_API_KEY "sk-..."

# 验证
./openclaw-cred-hub-v2.sh list
./openclaw-cred-hub-v2.sh test
```

---

## 🛡️ 安全说明

### 开发模式 (.env 文件)
- ✅ 便利：无需 Touch ID，后台执行无障碍
- ⚠️ 风险：凭证存储在文件系统中
- 🔒 缓解：文件权限 600，仅本人可读

### 生产模式 (Keychain)
- ✅ 安全：Touch ID / 密码保护
- ❌ 限制：后台执行会阻塞等待验证
- 💡 适用：手动操作、敏感生产环境

### 切换模式
```bash
# 切换到开发模式
./openclaw-cred-hub-v2.sh switch envfile

# 切换到生产模式
./openclaw-cred-hub-v2.sh switch keychain
```

---

## 📝 与 OpenClaw 集成

在 OpenClaw 中直接调用：

```bash
# 方式 1：直接执行
/Users/titen/.openclaw/workspace/openclaw-skill-wrapper-v2.sh llm "你的问题"

# 方式 2：先加载凭证环境
source ~/.openclaw/.env.skill
/Users/titen/.openclaw/workspace/openclaw-skill-wrapper-v2.sh llm "你的问题"

# 方式 3：创建别名（推荐）
alias oclaw='/Users/titen/.openclaw/workspace/openclaw-skill-wrapper-v2.sh'
oclaw llm "你好"
```

---

## ⚠️ 后续需配置的 API

根据实际工作需求，可能需要：

| API | 用途 | 优先级 |
|-----|------|--------|
| **Gemini** | summarize CLI 原生支持 | 中 |
| **Notion** | 知识库管理 | 中 |
| **OpenAI** | DALL-E 图片生成 | 低 |
| **GitHub** | gh CLI 认证 | 低（已支持 gh auth）|

**当需要时，Thunder 会提醒 Boss 配置。**

---

## ✅ 当前状态确认

| 组件 | 状态 | 说明 |
|------|------|------|
| Moonshot API Key | ✅ 有效 | 已存储在 Keychain |
| .env 文件 | ⚠️ 待创建 | 需 Boss 手动执行上述步骤 |
| 凭证管理脚本 | ✅ 就绪 | openclaw-cred-hub-v2.sh |
| Skill 包装器 | ✅ 就绪 | openclaw-skill-wrapper-v2.sh |
| Weather | ✅ 可用 | 无需配置 |
| 通用 LLM | ⚠️ 待激活 | 需创建 .env 文件 |

---

## 🎯 Boss 下一步

**请执行以下命令完成配置**：

```bash
# 1. 创建凭证文件
cat > ~/.openclaw/.env.skill << 'EOF'
export MOONSHOT_API_KEY='sk-kRmUsMw579tgEAz7PVsszu9pzdt8NZMGF5ZBfB9jgLGG4klw'
EOF
chmod 600 ~/.openclaw/.env.skill

# 2. 设置开发模式
echo "export OPENCLAW_CRED_MODE=envfile" > ~/.openclaw/.mode

# 3. 验证
cd /Users/titen/.openclaw/workspace
./openclaw-skill-wrapper-v2.sh llm "配置完成测试"
```

**完成后，所有基于 Moonshot 的 Skill 将立即可用。**
