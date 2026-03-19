# FAULT_HANDLER_ACCEPTANCE_CHECKLIST

> 目的：作为 2026-03-12 故障处理器整改后的最终验收清单，确认脚本、调度、日志、运行模式与风险边界都已落地。

## 一、脚本完整性验收
- [ ] `ghost-process-cleanup.sh` 存在且为最新保守审计版
- [ ] `network-failover.sh` 存在且为最新保守审计版
- [ ] `token-monitor.sh` 存在且为最新保守审计版
- [ ] `fault-handler-controller.sh` 存在且可正常调用
- [ ] 四个脚本均通过 `bash -n` 语法检查

---

## 二、运行模式验收
- [ ] `~/.openclaw/fault-handlers.env` 已存在
- [ ] 当前默认值为：
  - [ ] `SAFE_MODE=1`
  - [ ] `DRY_RUN=0`
- [ ] `fault-handler-controller.sh status` 能显示当前模式
- [ ] 各脚本日志已带 `safe_mode` / `dry_run` 字段

---

## 三、日志与审计验收
- [ ] 统一日志目录为 `~/.openclaw/fault-handlers/`
- [ ] 下列文件已正常写入：
  - [ ] `ghost-process.log`
  - [ ] `network.log`
  - [ ] `token-monitor.log`
  - [ ] `audit-critical.log`
  - [ ] `cron.log`
- [ ] 结构化字段至少包含：
  - [ ] `ts`
  - [ ] `level`
  - [ ] `task`
  - [ ] `action`
  - [ ] `target`
  - [ ] `reason`
  - [ ] `result`
- [ ] 高风险事件会进入 `audit-critical.log`

---

## 四、行为边界验收
### ghost-process-cleanup
- [ ] 单实例时只记录正常状态
- [ ] 多实例时只审计、不自动 kill 主 Gateway
- [ ] 高风险候选会写入 `audit-critical.log`

### network-failover
- [ ] 只做探测与状态落盘
- [ ] 网络切换会写日志
- [ ] 不直接调用 Telegram Bot 外发消息
- [ ] 不自动重启主服务

### token-monitor
- [ ] 只做 provider 状态观测
- [ ] 会写入 `~/.openclaw/.provider_status`
- [ ] 不自动切换 fallback
- [ ] 不直接外发消息

---

## 五、调度层验收
- [ ] `crontab -l` 中故障处理器三条任务仍存在
- [ ] 三条任务仍指向：
  - [ ] `fault-handler-controller.sh ghost`
  - [ ] `fault-handler-controller.sh token`
  - [ ] `fault-handler-controller.sh network`
- [ ] cron 汇总日志已重定向到：
  - [ ] `~/.openclaw/fault-handlers/cron.log`
- [ ] 无重复、冲突或失效 cron 条目

---

## 六、观测验收（建议连续 3–5 天）
- [ ] 未再出现脚本误杀主 Gateway 的迹象
- [ ] 未再出现因故障处理器导致的异常 SIGTERM 证据
- [ ] `ghost-process.log` 持续稳定
- [ ] `network.log` 能正确记录状态切换
- [ ] `token-monitor.log` 能正确记录 provider 探测结果
- [ ] `audit-critical.log` 仅在状态切换或高风险事件时写入

---

## 七、文档验收
- [ ] `AUTOMATION_TASK_MATRIX_v1.md` 已生成
- [ ] `FAILURE_HANDLING_RULES_v1.md` 已生成
- [ ] `AUDIT_LOGGING_STANDARD_v1.md` 已生成
- [ ] `FAULT_HANDLER_CHANGELOG_2026-03-12.md` 已生成
- [ ] `FAULT_HANDLER_OPERATING_MODE.md` 已生成
- [ ] `FAULT_HANDLER_ACCEPTANCE_CHECKLIST.md` 已生成

---

## 八、最终验收结论
满足以下条件可判定“本轮整改通过”：
- [ ] 脚本已安全化
- [ ] 日志已统一
- [ ] 审计已可用
- [ ] 运行模式已可控
- [ ] cron 已闭环
- [ ] 连续观察期内无新的误伤证据

---

## 九、后续建议
- [ ] 3–5 天后做一次复盘
- [ ] 再决定是否保留长期 `SAFE_MODE=1`
- [ ] 如要启用更主动恢复，必须先做受控验证
