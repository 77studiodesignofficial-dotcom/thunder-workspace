# IMPLEMENTATION_ACTION_QUEUE_v1

> 目的：把 `IMPLEMENTATION_DECISION_MATRIX_v1` 转成正式实施前的动作队列。仅覆盖本批 4 个任务：Task 4、Task 1、Task 3、Task 2。

---

# 0. 本批动作范围

## 立即执行
- **Task 4**：建立主会话高负荷任务隔离规则
- **Task 1**：自动结果不再继续污染主会话

## 保守执行
- **Task 3**：retry 达阈值后禁止重复正文外发
- **Task 2**：timeout / snapshot fallback 后禁止正文外发

## 暂缓
- **Task 5**：日报 / 周报切回 Assistant bot

---

# 1. Action Q1 — 主会话高负荷任务隔离规则生效

## 对应任务
Task 4

## 执行顺序
第 1 位

## 执行动作
建立明确规则：
> 长日志排障、大规模扫描、多轮根因调查、高上下文长链路推理，不再默认在主 Telegram 会话长跑。

改为：
> 优先在隔离子会话 / 独立执行链中完成，再将结论回传主会话。

## 执行前检查
- 已确认主会话发生过 overflow / compaction / timeout
- 已确认该规则属于低风险流程治理动作

## 执行后验证
- 后续复杂调查不再默认继续堆在主会话
- 主会话更多只承接结论 / 决策点

## 回滚触发条件
- 如果隔离规则严重影响正常沟通效率

## 回滚方式
- 缩小隔离任务范围，而不是完全取消隔离原则

---

# 2. Action Q2 — 自动结果不再继续污染主会话

## 对应任务
Task 1

## 执行顺序
第 2 位

## 执行动作
对以下自动任务建立统一交付边界：
- `daily-comprehensive-briefing`
- `end-of-day`
- `weekly-review`

规则：
> 自动结果默认不再继续作为主会话正文展开、扩写、承接。

## 执行前检查
- 已确认自动结果卷入主会话是当前问题放大因素
- 已确认这项动作不依赖 Assistant bot 身份切换

## 执行后验证
- 自动汇报结果不再默认延续成主会话对话正文
- 主会话注入的自动内容下降

## 回滚触发条件
- 如果自动结果完全失去可读性或严重影响使用习惯

## 回滚方式
- 恢复部分主会话承接，但仅限摘要，不恢复全文承接

---

# 3. Action Q3 — retry 达阈值后禁止重复正文外发

## 对应任务
Task 3

## 执行顺序
第 3 位

## 执行动作
建立保守规则：
> 当出现 `delivery failed + retrying`、同一 runId 多次 error、或 `lane wait exceeded` 持续伴随交付异常时，只允许内部重试，不允许继续重复对用户外发近似正文。

## 执行前检查
- 已确认 retry / delivery failed / 同 runId 多次 error 现象存在
- 已确认当前目标是止血，不是保留最大正文产出率

## 执行后验证
- retry 仍可能存在，但用户侧不再看到多次近似相同正文
- 问题表现从“重复刷屏 + 卡住”降级为“失败一次并收口”

## 回滚触发条件
- 如果发现收口过早，导致大量原本可恢复任务都直接失败

## 回滚方式
- 放宽正文外发阈值，但不恢复无限接近重复正文的行为

---

# 4. Action Q4 — timeout / snapshot fallback 后禁止正文外发

## 对应任务
Task 2

## 执行顺序
第 4 位

## 执行动作
建立保守阻断规则：
当命中以下任一信号：
- `embedded run timeout`
- `using current snapshot`
- `Auto-compaction failed`
- `Full summarization failed`
- `Partial summarization also failed`

则：
> 不再继续向用户自动外发正文结果。

最多允许：
- 极简失败状态
- 或内部失败记录

## 执行前检查
- 已确认 timeout / snapshot fallback 是当前最强主假设链的一部分
- 已确认本动作先按保守策略落地，而非追求对象级精准控制点

## 执行后验证
- `using current snapshot` 后不再紧跟疑似旧内容正文外发
- timeout / fallback 不再对应重复同一条内容

## 回滚触发条件
- 如果自动任务成功率显著下降，且证据表明阻断过宽

## 回滚方式
- 缩窄阻断信号范围，优先只保留 `using current snapshot` 和 `Auto-compaction failed`

---

# 5. 执行后的统一观察窗口

建议保留 **72 小时观察窗口**，重点看：

## 用户侧
- 是否仍出现同一条消息短时间重复发送
- 是否仍出现“卡在某条消息后无回应”
- 自动汇报是否仍持续污染主会话

## 日志侧
- `using current snapshot` 后是否仍出现正文外发
- `retrying` 是否仍对应多条近似消息
- `lane wait exceeded` 是否下降
- 主会话 `model_context_window_exceeded` / compaction failure 是否下降

---

# 6. 进入第二批的条件

只有在以下条件满足时，才进入 Task 5：
- Assistant bot 身份映射明确
- 当前 routing / path 对齐明确
- 第一批止血动作已完成且观察结果稳定
