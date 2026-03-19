# Telegram Bot 配置指南

## 创建 Bot 步骤（需 Boss 手动操作）

### 步骤 1：与 BotFather 对话
1. 在 Telegram 搜索 `@BotFather`
2. 发送 `/newbot`
3. 按提示输入 Bot 名称和用户名
4. 保存返回的 API Token

### 步骤 2：配置到 OpenClaw
```bash
# 存储 Token
./openclaw-cred-hub-v2.sh store TELEGRAM_BOT_TOKEN "your_token_here"
```

### 步骤 3：测试
```bash
# 发送测试消息
./openclaw-skill-wrapper-v2.sh telegram "测试消息"
```

## Bot 能力
- 接收 Boss 消息并处理
- 主动发送通知（如 Cron 任务结果）
- 支持命令（如 /status, /weather）

## 状态
⏳ 等待 Boss 创建 Bot 并提供 Token
