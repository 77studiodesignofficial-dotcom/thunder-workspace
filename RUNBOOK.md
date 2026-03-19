# RUNBOOK.md

## Purpose
标准运行手册：记录常见故障、排查步骤、恢复动作与检查清单。

## Health Checklist
- Gateway 是否运行正常
- Telegram 通道是否正常
- Browser relay 是否可用
- Cron 是否有连续错误
- 模型授权是否正常
- memory_search 是否可用

## Incident Format
### 标题
- 现象：
- 影响：
- 根因：
- 临时修复：
- 永久修复：
- 复查项：

## Common Incidents

### 1. Gateway 重启 / 断联
- 检查：`openclaw status`
- 检查：`openclaw logs`
- 如服务配置异常，执行 doctor / repair

### 2. Cron 投递失败
- 检查目标 channel 与 chatId
- 检查 cron payload model 是否有效
- 检查上次 lastError

### 3. 模型授权失效
- 检查：`openclaw models status`
- 检查 auth-profiles.json
- 对 OAuth 模型检查过期时间

### 4. memory_search 不可用
- 检查 embedding/provider 配置
- 检查 memory plugin 状态
- 检查是否能恢复索引 / provider
