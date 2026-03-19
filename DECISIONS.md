# DECISIONS.md

## 2026-03-07
### 安全策略 v1.0
- 浏览器安全：轻量增强
- 弹窗拦截、下载隔离、敏感 API 阻止
- 信息汇报默认脱敏，Boss 明确要求时可详细汇报

## 2026-03-08
### 运维机制建立
- 建立 thunder-dashboard 统一监控入口
- 建立四大故障处理器
- 建立晨报 / 日结 / 周报三类 cron

## 2026-03-09
### 沟通协议更新
- 收到消息先回复“收到”
- 目的：降低等待焦虑，提升对话可感知性

### 多模型调度策略
- 主模型：openai-codex/gpt-5.4
- 主力编码：glm-coding/glm-4.7
- 高复杂编码/推理：glm-coding/glm-5
- cron / 轻任务：openai/gpt-4o-mini
- API 兜底：zai/glm-5 / moonshot/kimi-k2.5

### GLM Coding Plan 接入
- 普通 zai provider 不消耗 Coding 套餐额度
- 正确接法为 OpenAI-compatible coding base URL
- 已验证 glm-coding/glm-4.7 与 glm-coding/glm-5 成功消耗套餐额度
