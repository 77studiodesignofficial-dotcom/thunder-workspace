# CRON_INCIDENT_REMEDIATION_INDEX_v1

> 目的：为本次“重复发送同一条信息后卡住、无法推进、最后无回应”的排查与第一批止血修复建立统一索引页，方便后续复盘、交接与继续推进第二批修复。

---

# 1. 事件主题

本次工作围绕以下核心问题展开：

> **为什么系统会在重复发送同一条信息后卡住，停滞在那条信息无法进行下一步，最后直接没有回应？**

在本轮处理中，已形成以下阶段性结论：
- 当前最强主假设为：**主会话过重 / compaction 超时 / snapshot fallback（H1）**
- 重要放大器为：**queue / lane / retry / fallback 收口异常（H3）**
- 需要继续补齐的结构问题为：**发送主体错位（H4）**
- 已确认但当前不视为第一直接主因的背景问题为：**双发送权 / 时区 / 幂等不足（H2）**

---

# 2. 核心文档索引

## A. 根因验证与调查阶段

### 1) `ROOT_CAUSE_VALIDATION_CHECKLIST_v1.md`
用途：根因验证总清单，定义 H1 / H3 / H4 / H2 的支持证据、反证和成立标准。

### 2) `ROOT_CAUSE_MINIMAL_VALIDATION_RUNBOOK_v1.md`
用途：把验证框架压成最小可执行顺序，明确先验 H1，再验 H3/H4/H2。

### 3) `MINIMAL_FIX_PREFLIGHT_CHECKLIST_v1.md`
用途：进入修复前必须核对的关键问题清单。

### 4) `GAP_INVESTIGATION_SEQUENCE_v1.md`
用途：把 preflight 中未补齐的缺口压成顺序化调查步骤。

### 5) `INVESTIGATION_TARGET_OUTCOMES_v1.md`
用途：定义调查阶段何时算收敛，避免无限继续做框架。

### 6) `INVESTIGATION_OUTCOME_MATRIX_v1`（对话中形成，未单独落盘）
用途：对 A/B/C/D 四个调查终点做当前版本裁决。

---

## B. 最小修复与执行准备阶段

### 7) `MINIMAL_FIX_EXECUTION_PLAN_v1.md`
用途：定义第一批保守止血动作，不触碰尚未核清的 Assistant bot 身份切换。

### 8) `CHANGE_TASK_SHEET_v1.md`
用途：把执行计划压成可落地任务单。

### 9) `IMPLEMENTATION_MAPPING_v1`（对话中形成，未单独落盘）
用途：区分各任务属于流程层、策略层、交付层还是身份路由层。

### 10) `IMPLEMENTATION_DECISION_MATRIX_v1`（对话中形成，未单独落盘）
用途：给每个任务定状态：立即执行 / 保守执行 / 暂缓。

### 11) `IMPLEMENTATION_ACTION_QUEUE_v1.md`
用途：把第一批 4 个任务排成正式动作队列，明确顺序、检查点、验证点和回滚条件。

---

## C. 已执行变更与观察阶段

### 12) `EXECUTED_CHANGE_SUMMARY_AND_72H_OBSERVATION_v1.md`
用途：记录本次已实际落地的第一批变更，以及 72 小时观察指标。

### 13) `OBSERVATION_LOG_TEMPLATE_72H_v1.md`
用途：72 小时观察期的逐次事件记录模板。

---

# 3. 本次已实际执行的变更

## 已落地
- 已更新 3 个 OpenClaw 内建 cron job：
  - `daily-comprehensive-briefing`
  - `end-of-day`
  - `weekly-review`
- 已统一收紧输出边界：
  - 只输出单条最终可投递正文
  - 不再扩写成主会话对话
  - 支持 `skipped_duplicate(...)`
  - 支持 `failed_safe(...)`
  - 禁止额外脚本 / curl / Bot 直发形成重复发送
- `weekly-review` 已收紧长度要求，`timeoutSeconds` 降至 `90`
- 已更新 `AGENTS.md`：新增主会话高负荷任务隔离规则
- 已建立快照备份：
  - `/Users/titen/.openclaw/workspace/backups/2026-03-13-minimal-fix/jobs.before.minimal-fix.json`

## 已部分落地（但仍非运行时硬拦截）
- timeout / snapshot fallback 后禁止正文外发
- retry 达阈值后禁止重复正文外发

说明：
当前这两项已通过 cron payload 约束、输出边界和 safe-fail 规则做了第一层止血，但尚未完成更底层运行时交付链的硬性拦截。

---

# 4. 当前阶段结论

## 已确定
- 第一批保守止血已进入实际生效状态
- 当前最关键的不是继续扩方案，而是观察 72 小时窗口内症状是否下降

## 仍待继续
- `Assistant bot` 身份映射
- 日报 / 周报恢复到正确发送主体（第二批）
- 如第一批观察失败，则继续深入 runtime 控制点

---

# 5. 推荐的后续顺序

## 当前先做
1. 使用 `OBSERVATION_LOG_TEMPLATE_72H_v1.md` 记录 72 小时内相关事件
2. 对照 `EXECUTED_CHANGE_SUMMARY_AND_72H_OBSERVATION_v1.md` 做验收

## 之后再做
3. 开启第二批准备：核清 `Assistant bot` 身份映射
4. 在身份映射明确后，推进日报 / 周报切回正确发送主体

---

# 6. 一句话总览

> 本次事件已从“现象讨论”推进到“第一批止血已执行 + 72 小时观察期已开启”；当前最佳动作是先观察疗效，再准备第二批发送主体修正。
