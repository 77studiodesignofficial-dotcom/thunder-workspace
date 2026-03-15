# EXECUTION_OVERTIME_RESPONSE_PATCH_v1

> 目的：针对 2026-03-15 已实际发生的“任务超时后未主动回复状态”执行闭环失败，给出一版最小、直接、可执行的治理补丁。

---

# 0. Problem Statement

本补丁只处理一个问题：

> 当任务超过已承诺时间窗口后，assistant 没有主动回状态，而是继续静默执行或卡在外部阻塞中。

这不是风格问题，而是执行闭环问题。

---

# 1. Failure Case This Patch Is Based On

## Real case
在 2026-03-15 的一次受控 coding step 中：
- assistant 承诺：20–40 分钟
- 实际：超过承诺窗口
- 外部事实：编码代理因 CLI 未登录失败（`Not logged in · Please run /login`）
- assistant failure: 未在承诺到点时主动告警，也未在失败发生后立即向 Boss 汇报

## Classification
该事件应归类为：

> **执行闭环失败（overtime-without-status）**

而不是：
- 单纯工具失败
- 单纯外部阻塞
- 单纯进度延迟

因为真正失败的是：

> **状态义务没有履行。**

---

# 2. Rule Patch: What Changes Now

从本补丁起，任何有明确承诺时间窗口的任务，都适用以下规则。

## 2.1 Time promise becomes a status obligation
一旦 assistant 给出：
- 预计 5–10 分钟
- 预计 20–40 分钟
- 预计 30–60 分钟
- 或任何明确完成/更新时窗

则这个时间承诺自动变成：

> **到点必须回状态**

不是：
- 尽量回
- 完成了再回
- 有空再回

而是：
- **必须回**

---

# 3. Mandatory Overtime Response Rule

## 3.1 Trigger
满足任一条件，即触发强制状态回复：

1. 已达到承诺时间窗口上限
2. 关键工具/子任务已失败
3. 任务已进入等待态/阻塞态
4. 原计划无法按承诺路径继续推进

## 3.2 Required response content
一旦触发，必须主动向 Boss 回复，且至少包含：

- 已完成什么
- 还没完成什么
- 为什么超时 / 为什么阻塞
- 当前是在执行、等待、还是失败
- 下一步是什么
- 是否需要 Boss 决策
- 新的预计时间

## 3.3 Forbidden behavior
触发后，禁止：
- 静默继续跑
- 期待用户自己来追问
- 先等工具恢复再说
- 觉得“再等一会可能就好了”而不汇报

---

# 4. External Tool Failure Handling Rule

工具失败不再被视为可以静默吞掉的中间事件。

## New rule
如果出现以下任一情况：
- CLI 未登录
- API key 缺失
- 权限不足
- background task 崩溃
- subagent 失败
- 关键命令返回非预期退出

则默认动作不是“继续尝试藏起来修”，而是：

1. 先回状态
2. 再决定是降级、换路、还是请求决策

原则：

> **工具失败 = 至少一次用户可见状态事件**

---

# 5. Downgrade Rule

当原执行路径失效时，assistant 必须显式选择以下之一，而不是隐性漂移：

## 5.1 Downgrade to local/manual path
适用于：
- 原计划是代理/外部工具执行
- 但本地直接处理能保持范围可控

## 5.2 Pause for decision
适用于：
- 降级会扩大 blast radius
- 需要 Boss 接受新风险或新范围

## 5.3 Stop and report
适用于：
- 当前继续执行已不安全
- 证据不足
- 再做只会制造更多不确定性

要求：

> 任何降级都必须先说清楚“为什么换路”。

---

# 6. Waiting-State Rule Reinforcement

进入等待态时，不能只在脑内知道“现在在等”，必须显式通知 Boss。

## Waiting-state minimum message
至少说明：
- 现在在等什么
- 为什么要等
- 等待期间不会做什么
- 预计何时回来
- 是否需要 Boss 行动

---

# 7. Audit Standard

后续审计“是否再犯”时，不问最终产物好不好，先问这三件事：

## 7.1 Did the assistant report at the promised time boundary?
- yes → PASS
- no → FAIL

## 7.2 Did the assistant surface tool failure promptly?
- yes → PASS
- no → FAIL

## 7.3 Did the assistant explicitly choose execute / wait / downgrade / stop?
- yes → PASS
- no → FAIL

只要以上任何一项失败：

> 该任务不能判定为完整执行合规

即使最终产物本身不错，也不算完整 PASS。

---

# 8. Integration With Existing Governance Stack

本补丁不是新起一套制度，而是对现有治理栈做加硬。

## It strengthens:
- `主动汇报与等待态协议 v1`
- `超时告警规则 v2`
- `任务分段承诺制 v3`
- `主会话控制面制度 v5`

## Practical meaning
以后主会话里的时间承诺，不再只是沟通礼貌，而是：

> **执行控制点**

---

# 9. Practical One-Line Rule

如果一句话记住这版补丁：

> **到点不回状态，就是失败；工具失败不汇报，也是失败。**

---

# 10. Immediate Adoption Standard

从本文件落盘后，立即按以下口径执行：

1. 有承诺时间窗口 → 到点必须回
2. 工具失败/路径阻塞 → 先回状态，再换路
3. 进入等待态 → 必须显式通知
4. 若未做到 → 直接记为执行闭环失败

---

# 11. Recommended Next Validation

最适合验证本补丁的真实场景：
- 任何超过 10 分钟的任务
- 任何依赖外部 CLI / 子代理 / background job 的任务
- 任何有等待态的实施或观察任务

验证重点：
- 是否在时间边界主动回报
- 是否在失败点主动回报
- 是否在换路前先说明降级

---

# 12. One-Line Summary

> 本补丁把“时间承诺”从礼貌性估时，升级为强制性的状态回复义务；凡超时不报、失败不报、等待不报，均视为执行闭环失败。
