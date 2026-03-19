# MINIMAL_FIX_EXECUTION_PLAN_v1

> 目的：进入第一批保守型最小修复执行，只针对当前已足够支撑的止血动作落计划，不触碰尚未核清的 Assistant bot 身份切换。

---

# 0. 执行边界

## 本批执行目标
1. **自动结果不再继续污染主会话正文**
2. **timeout / snapshot fallback 后禁止正文外发**
3. **retry 达阈值后禁止重复正文外发**
4. **建立主会话高负荷任务隔离规则**

## 本批明确不做
- 不直接切日报 / 周报到 Assistant bot 身份
- 不大改 OpenClaw 内核
- 不重构全部 cron 架构
- 不把未坐实的对象级推断当成铁证修改依据

---

# 1. Execution Item A — 切断自动结果继续污染主会话

## 要改哪一层
**流程层 / 交付原则层**

## 变更内容
对以下自动任务统一建立规则：
- `daily-comprehensive-briefing`
- `end-of-day`
- `weekly-review`

规则为：
> 自动任务结果应优先作为独立交付结果处理，不再默认继续作为主会话正文展开、扩写或承接。

## 目的
减少主会话上下文持续膨胀，降低 H1（主会话过重 / compaction 超时 / snapshot fallback）的复发概率。

## 预期阻断链
- 自动任务结果进入主会话
- 主会话被持续污染
- 上下文继续变重
- compaction / timeout 风险上升

## 验收标准
- 自动任务完成后，不再出现“主 assistant 继续把自动正文当作普通对话延展”的默认行为
- 主会话自动注入内容明显减少
- 后续主会话 context overflow / compaction 压力下降

---

# 2. Execution Item B — timeout / snapshot fallback 后禁止正文外发

## 要改哪一层
**前置自动交付链（优先） + 主会话承接层（兜底）**

## 变更内容
当自动任务命中以下任一条件时：
- `embedded run timeout`
- `using current snapshot`
- `Auto-compaction failed`
- `Full summarization failed`
- `Partial summarization also failed`

则该次自动任务进入：
> **失败 / 待人工核对 / 内部记录**

并执行规则：
> **禁止继续对用户自动外发正文结果**

必要时最多允许：
- 一条极简失败状态
- 或仅保留内部日志/状态记录

## 目的
切断“旧 snapshot / 异常 fallback 结果继续对外输出”的风险链。

## 预期阻断链
- timeout / fallback 发生
- 旧内容被继续当作新结果外发
- 用户看到重复内容
- 主会话被进一步污染 / 卡住

## 验收标准
- 命中上述异常后，不再紧跟用户可见正文外发
- `using current snapshot` 后不再出现疑似旧内容重复发送
- 用户侧重复同一条内容的概率显著下降

---

# 3. Execution Item C — retry 达阈值后禁止重复正文外发

## 要改哪一层
**自动外发层 / retry 策略层**

## 变更内容
对 cron / announce / 自动汇报链建立保守收口规则：

当出现以下任一模式：
- `delivery failed` + `retrying`
- 同一 `runId` 多次 `embedded run agent end ... isError=true`
- `lane wait exceeded` 持续出现并伴随自动交付异常

则：
> **只允许内部重试，不允许继续重复向用户外发近似正文内容**

达到阈值后：
> **直接失败收口**，而不是继续刷正文。

## 目的
避免 H3（queue / lane / retry / 收口异常）把局部故障放大成“重复 + 卡住 + 沉默”。

## 预期阻断链
- delivery / announce 失败
- retry 继续尝试
- 相似正文反复外发
- 用户侧看到重复 / 系统继续堵塞

## 验收标准
- retry 仍可存在，但用户侧不再看到多次相似正文重复出现
- 故障表现从“重复刷屏 + 卡死”降级为“失败一次并收口”
- 同一 runId 的异常不再对应多条相似用户可见消息

---

# 4. Execution Item D — 建立主会话高负荷任务隔离规则

## 要改哪一层
**工作流规则层 / 会话治理层**

## 变更内容
建立主会话默认限制：

以下任务不再默认在主 Telegram 会话长跑：
- 长日志排障
- 大规模文件 / 代码扫描
- 多轮根因复盘
- 高上下文连续诊断
- 长链路系统调查

改为：
> 优先在隔离子会话 / 独立执行链中完成，再把结论回传主会话。

## 目的
降低主会话成为“事故汇聚点”的概率，减少 H1 再次触发。

## 预期阻断链
- 主会话持续承接高负荷任务
- context 快速变重
- compaction / timeout / fallback 增加
- 重复 / 卡住问题更容易再现

## 验收标准
- 主会话后续不再持续承接高负荷排障长跑任务
- 复杂任务逐步转移到隔离链路
- 主会话 token / compaction 压力明显缓和

---

# 5. 执行顺序

## 第一优先：先止血
1. **Execution Item B** — timeout / snapshot fallback 后禁止正文外发
2. **Execution Item C** — retry 达阈值后禁止重复正文外发

## 第二优先：再减压
3. **Execution Item A** — 切断自动结果继续污染主会话
4. **Execution Item D** — 建立主会话高负荷任务隔离规则

原因：
- B/C 直接针对“重复 + 卡住”主症状链
- A/D 负责减少主会话再次进入坏状态

---

# 6. 执行后验收窗口

建议以 **72 小时观察窗口** 评估本批止血效果，重点看：

## 用户侧指标
- 是否还出现同一条消息短时间重复发送
- 是否还出现“卡在某条消息后无回应”
- 自动汇报是否还继续污染主会话

## 日志侧指标
- `using current snapshot` 后是否仍有正文外发
- `retrying` 是否仍对应多条相似用户可见消息
- `lane wait exceeded` 是否下降
- 主 Telegram 会话的 `model_context_window_exceeded` / compaction failure 是否下降

---

# 7. 第二批执行（暂缓）

以下动作保留到身份映射核清之后再做：

## Execution Item E — 恢复日报 / 周报到 Assistant bot 正确发送主体

### 前置条件
- Assistant bot 身份映射已明确
- 当前主 assistant 与 Assistant bot 的 routing 关系已核清

### 当前状态
- **目标明确**
- **执行条件未完全满足**

---

# 8. 当前执行纪律

- 本文件是**最小修复执行计划**，不是内核重构方案
- 先优先落地保守止血，再评估是否需要更深层改动
- 若执行过程中发现控制点与当前判断不一致，应停止并回到 preflight / investigation 重新定位
