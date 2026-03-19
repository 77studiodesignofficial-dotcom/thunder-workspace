# FAULT_HANDLER_CHANGELOG_2026-03-12

> 目的：记录 2026-03-12 对 Thunder 故障处理链路的整改内容、原因与当前状态。

## 1. 背景

本次整改来自一次 Gateway 中断排查：
- OpenClaw Gateway 在故障窗口内两次收到 `SIGTERM`
- 现有证据未证明是 Telegram 或 OpenClaw 自身崩溃
- 故障处理脚本存在“匹配不够严格 + 带副作用动作”的结构性风险

因此，本轮整改目标是：
- 收紧自动化脚本的危险动作边界
- 增强审计能力
- 建立统一日志与运行模式控制

---

## 2. 本次改动概览

### 已整改脚本
- `ghost-process-cleanup.sh`
- `network-failover.sh`
- `token-monitor.sh`
- `fault-handler-controller.sh`

### 已新增文档
- `AUTOMATION_TASK_MATRIX_v1.md`
- `FAILURE_HANDLING_RULES_v1.md`
- `AUDIT_LOGGING_STANDARD_v1.md`
- `FAULT_HANDLER_CHANGELOG_2026-03-12.md`
- `FAULT_HANDLER_OPERATING_MODE.md`

### 已新增配置
- `~/.openclaw/fault-handlers.env`

---

## 3. 具体整改内容

## 3.1 ghost-process-cleanup.sh
### 旧行为
- 使用较宽松的进程匹配方式
- 检测到多个候选进程时会执行 kill / kill -9
- 缺少高风险动作审计日志

### 新行为
- 默认仅审计，不自动 kill 主 Gateway
- 检测到多个候选进程时：
  - 记录结构化日志
  - 写入 `audit-critical.log`
  - 标记为需要人工确认
- 增加 `SAFE_MODE` / `DRY_RUN` 字段进入日志

### 效果
- 显著降低误杀主 Gateway 风险
- 故障窗口可追溯

---

## 3.2 network-failover.sh
### 旧行为
- 直接调用 Telegram Bot API 外发消息
- 网络恢复时会尝试补发离线消息
- 通知链路与凭证硬编码耦合

### 新行为
- 只做网络探测、状态落盘、结构化日志
- 网络状态切换写入审计日志
- 不再直接外发消息
- 不自动重启主服务

### 效果
- 降低脚本副作用
- 使网络检测回归“观测型”职责

---

## 3.3 token-monitor.sh
### 旧行为
- 发现 `429` 时自动写 fallback 状态
- 直接调用 Telegram Bot API 发告警
- 观测与自动切换混在一起

### 新行为
- 只检查 provider 状态
- 将结果落盘到 `~/.openclaw/.provider_status`
- 记录异常，但不自动切换 fallback
- 不直接外发消息

### 效果
- 避免误判后触发错误切换
- 将“检测”与“决策”分离

---

## 3.4 fault-handler-controller.sh
### 旧行为
- 日志目录分散
- 未统一注入全局运行模式
- `status` 视图信息有限

### 新行为
- 统一日志目录到 `~/.openclaw/fault-handlers`
- 读取 `~/.openclaw/fault-handlers.env`
- 注入全局开关：
  - `SAFE_MODE`
  - `DRY_RUN`
- `status` 新增运行模式与审计日志展示

### 效果
- 运行模式可控
- 脚本行为更一致
- 故障排查更集中

---

## 4. 日志与调度整改

### 日志统一
当前关键日志位于：
- `~/.openclaw/fault-handlers/ghost-process.log`
- `~/.openclaw/fault-handlers/network.log`
- `~/.openclaw/fault-handlers/token-monitor.log`
- `~/.openclaw/fault-handlers/audit-critical.log`
- `~/.openclaw/fault-handlers/cron.log`

### crontab 修正
已将故障处理器 cron 汇总日志重定向到：
- `~/.openclaw/fault-handlers/cron.log`

---

## 5. 当前默认运行模式

当前默认配置：
- `SAFE_MODE=1`
- `DRY_RUN=0`

解释：
- 处于保守模式
- 允许真实探测与记录
- 不允许激进自动动作

---

## 6. 当前已解决的问题

- 高风险脚本默认不再直接对主 Gateway 做破坏性动作
- 故障处理器日志不再分散在工作区和隐藏目录之间
- 观测、告警、自动决策之间的边界更清晰
- 后续若再出现异常，更容易建立时间线

---

## 7. 仍待后续完善

- 是否需要清理 crontab 中历史注释块
- 是否要给 fault-handlers 增加统一 changelog / runbook 入口
- 是否要将日志进一步升级为 JSONL
- 是否要对健康检查输出增加对 `SAFE_MODE` 状态的显示

---

## 8. 结论

本次整改的核心方向不是“增强自动恢复”，而是：

> **先让故障处理器变得可解释、可控、可审计，再决定是否恢复更激进的自动动作。**

当前状态适合作为稳定运行基线继续观察。 
