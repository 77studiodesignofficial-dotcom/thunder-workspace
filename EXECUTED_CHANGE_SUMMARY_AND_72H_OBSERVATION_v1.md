# EXECUTED_CHANGE_SUMMARY_AND_72H_OBSERVATION_v1

> 目的：记录本次已实际落地的第一批保守止血变更，并定义接下来 72 小时观察窗口的验收指标。

---

# 1. 本次已执行变更摘要

## 1.1 已更新的业务 cron job
已修改以下 OpenClaw 内建 cron job：
- `daily-comprehensive-briefing`
- `end-of-day`
- `weekly-review`

### 本次统一收紧的规则
- **只输出单条最终用户可见正文**
- **不再扩写成主会话对话**
- 如果同一业务日期 / 业务周已成功发送，则输出：
  - `skipped_duplicate(message_key=...)`
- 如果上下文 / 快照状态不可靠，则输出：
  - `failed_safe(job_name=..., reason=unsafe_context)`
- **禁止额外脚本、curl、Bot 直发形成重复发送**
- 保持业务消息只经由 **OpenClaw 内建 cron delivery** 路径发送

### 额外收紧
- `weekly-review`：额外强调**控制长度**，避免超长周报造成上下文和交付压力
- `weekly-review`：`timeoutSeconds` 已收紧到 `90`

---

## 1.2 已落地的主会话治理规则
已更新工作区规范文件：
- `AGENTS.md`

### 新增治理原则
在主 Telegram 会话中，不再默认长跑以下任务：
- 长日志排障
- 大规模文件 / 代码扫描
- 多步根因调查
- 长链路高上下文综合

### 改为
- 优先放到隔离子会话 / 子代理中执行
- 主会话主要承接：
  - 状态更新
  - 结论
  - 建议
  - 决策点

---

## 1.3 已完成备份
快照备份已建立：
- `/Users/titen/.openclaw/workspace/backups/2026-03-13-minimal-fix/jobs.before.minimal-fix.json`

---

# 2. 本次变更对应的任务状态

## 已实际落地
- **Task 4**：建立主会话高负荷任务隔离规则 ✅
- **Task 1**：自动结果不再继续污染主会话 ✅（以 cron payload 约束和交付边界形式落地）

## 已部分落地（策略层）
- **Task 3**：retry 达阈值后禁止重复正文外发 ◐
- **Task 2**：timeout / snapshot fallback 后禁止正文外发 ◐

说明：
当前 Task 2 / Task 3 已通过 job prompt / safe-fail 规则 / 输出约束做了第一层止血，
但尚未完成更底层运行时交付链的“硬拦截”。

---

# 3. 72 小时观察窗口

## 观察目的
验证第一批保守止血动作是否有效降低以下核心症状：
- 重复同一条消息
- 卡在某条后不推进
- 最后无回应
- 主会话上下文持续膨胀

## 观察窗口
- **开始时间**：本次最小修复落地后
- **观察时长**：72 小时

---

# 4. 核心观察指标

## 4.1 用户侧指标
### 通过标准
- 不再出现**同一条业务消息短时间重复发送**
- 不再明显出现**卡在某条消息后无回应**
- 晨报 / 日结 / 周报不再表现为“继续卷进主会话多轮扩写”

### 重点关注
- `daily-comprehensive-briefing`
- `end-of-day`
- `weekly-review`

---

## 4.2 日志侧指标
### 通过标准
- `using current snapshot` 之后，不再紧跟用户可见正文外发
- `retrying` 不再对应多条近似正文消息
- `lane wait exceeded` 出现频率下降
- 主 Telegram 会话的：
  - `model_context_window_exceeded`
  - `Auto-compaction failed`
  - `embedded run timeout`
  出现频率下降

---

## 4.3 周报专项指标
由于 `weekly-review` 曾出现：
- `Error: cron: job execution timed out`

因此需专项观察：
- 收紧长度与 timeout 后，周报是否仍超时
- 周报失败时是否能安全收口为 `failed_safe(...)`
- 周报是否仍触发重复正文外发

---

# 5. 验收判定

## 可判定为“本批止血有效”
如果 72 小时内满足：
- 无明显重复业务消息
- 无明显“卡在同一条后沉默”
- 自动汇报不再持续污染主会话
- 相关 timeout / overflow / lane 堵塞指标下降

## 可判定为“仍需进一步深入修复”
如果仍出现：
- 业务消息重复发送
- timeout 后疑似旧内容继续外发
- 周报仍反复超时 / 重试 / 卡住
- 主会话继续被自动汇报显著污染

---

# 6. 下一阶段预留项

## 第二批（尚未执行）
- 恢复日报 / 周报到 **Assistant bot** 的正确发送主体

## 前置条件
- Assistant bot 身份映射明确
- 当前 routing / path 对齐明确

在此之前，不建议直接切换发送主体。
