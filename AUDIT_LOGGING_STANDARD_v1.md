# AUDIT_LOGGING_STANDARD_v1

> 目标：为 OpenClaw 自动化体系建立统一、可追踪、适合故障排查的审计日志标准。

## 1. 适用对象

适用于以下任务与脚本：
- cron 主链路任务（晨报 / 日结 / 周报）
- 健康检查
- 故障处理器
- 任何会执行 kill / restart / config 变更 / 外发消息的自动化脚本

---

## 2. 审计日志总原则

### 原则 1：关键动作必须留下证据
尤其是以下动作：
- kill
- pkill
- restart
- launchctl 相关控制
- config 修改
- 外发消息
- 自动重试

### 原则 2：日志要回答 5 个问题
每条关键日志尽量回答：
1. 什么时候发生
2. 谁触发的
3. 对哪个目标发生
4. 为什么发生
5. 结果是什么

### 原则 3：机器可读 + 人可读
- 推荐统一单行结构化字段
- 同时保留简短自然语言描述

### 原则 4：先记录，再执行高风险动作
对于 kill / restart / config 变更：
- 先写“准备执行”日志
- 再执行动作
- 最后写“执行结果”日志

---

## 3. 推荐最小字段集

每条关键日志至少包含：
- `ts`：时间戳
- `task`：任务名
- `level`：INFO / WARN / ERROR / CRITICAL
- `action`：要执行或已执行的动作
- `target`：目标对象
- `reason`：触发原因
- `result`：结果

推荐扩展字段：
- `pid`：目标进程 ID
- `cmd`：目标命令行
- `attempt`：第几次尝试
- `correlation`：同一任务的关联 ID
- `duration_ms`：耗时

---

## 4. 日志级别定义

## INFO
普通流程记录：
- 任务开始
- 任务完成
- 一次探测成功
- 正常发送完成

## WARN
需要关注但未构成事故：
- 单次超时
- 一次自动重试
- 网络波动
- 旁路任务失败

## ERROR
已经影响交付或功能：
- 主链路任务失败
- 配置错误
- provider 不支持动作
- 连续失败

## CRITICAL
影响主服务稳定性或存在误伤风险：
- kill 主 Gateway
- 异常 SIGTERM
- 重复实例冲突
- 配置变更导致服务异常

---

## 5. 关键动作日志模板

## 5.1 任务开始
示例：
`ts=2026-03-12T00:00:00-07:00 level=INFO task=end-of-day action=start target=cron reason=scheduled result=running`

## 5.2 自动重试
示例：
`ts=2026-03-12T00:00:40-07:00 level=WARN task=end-of-day action=retry target=model-provider reason=upstream_timeout attempt=1 result=pending`

## 5.3 高风险动作：准备 kill
示例：
`ts=2026-03-12T00:01:10-07:00 level=CRITICAL task=ghost-process-cleanup action=pre_kill target=gateway pid=19563 reason=duplicate_instance_detected cmd="openclaw ... gateway --port 18789" result=planned`

## 5.4 高风险动作：kill 结果
示例：
`ts=2026-03-12T00:01:11-07:00 level=CRITICAL task=ghost-process-cleanup action=kill target=gateway pid=19563 reason=duplicate_instance_detected result=skipped_manual_confirmation_required`

## 5.5 主链路失败
示例：
`ts=2026-03-12T00:02:00-07:00 level=ERROR task=daily-briefing action=finish target=cron reason=provider_error result=failed`

## 5.6 主链路恢复
示例：
`ts=2026-03-12T00:02:20-07:00 level=INFO task=daily-briefing action=finish target=cron reason=retry_success result=recovered`

---

## 6. 特殊规则

## kill / restart / config 类动作
必须记录三段：
1. `pre_action`
2. `action_result`
3. `post_check`

### 示例流程
- pre_restart：准备重启，原因是什么
- restart_result：是否成功执行
- post_check：服务是否恢复、PID 是否变化、端口是否监听

---

## 7. 存储建议

### 日志位置建议
- 主链路任务日志：统一放到一个 automation 日志目录
- 故障处理脚本日志：统一放到一个 fault-handlers 日志目录
- 高风险动作审计：单独放 `audit-critical.log`

### 命名建议
- `automation-main.log`
- `fault-handlers.log`
- `audit-critical.log`

### 避免的问题
- 每个脚本各写各的、分散难查
- 没有统一字段，导致无法串时间线
- 只有报错没有动作前记录

---

## 8. 最低执行标准（v1）

当前阶段，至少落实：
- 所有主链路任务：开始/完成/失败/重试 四类日志
- 所有高风险脚本：pre_action + result + post_check
- 所有 kill / restart：必须记录 PID、命令行、原因
- 所有连续失败：必须有聚合摘要

---

## 9. 推荐下一步落地

1. 给 `ghost-process-cleanup.sh` 增加 pre_kill / skipped / confirmed / result 日志
2. 给 cron 主链路增加 start / retry / fail / recovered 日志
3. 新增一个统一审计日志文件用于记录高风险动作
4. 后续如需要，再升级为 JSONL 结构化日志
