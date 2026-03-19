# CHANGE_TASK_SHEET_v1

> 目的：把 `MINIMAL_FIX_EXECUTION_PLAN_v1` 进一步压成可落地任务单，作为真正实施前的执行清单。

---

# 0. 当前范围

当前仅覆盖第一批保守止血动作，不包含尚未核清的 Assistant bot 身份切换。

## 本批目标
1. 自动结果不再继续污染主会话
2. timeout / snapshot fallback 后禁止正文外发
3. retry 达阈值后禁止重复正文外发
4. 建立主会话高负荷任务隔离规则

## 暂缓目标
- 日报 / 周报切回 Assistant bot 身份

---

# 1. Task 1 — 自动结果不再继续污染主会话

## 类型
流程规则变更

## 适用对象
- `daily-comprehensive-briefing`
- `end-of-day`
- `weekly-review`

## 变更内容
建立统一规则：
> 自动任务结果默认不再作为主会话正文继续展开、延续、扩写。

## 预期收益
- 降低主会话上下文膨胀
- 缓解 H1（主会话过重 / compaction 超时 / snapshot fallback）

## 风险
低

## 回滚思路
如效果不佳，可恢复“主会话承接自动结果”的旧流程，但原则上不建议轻易回滚。

---

# 2. Task 2 — timeout / snapshot fallback 后禁止正文外发

## 类型
失败策略变更

## 触发信号
- `embedded run timeout`
- `using current snapshot`
- `Auto-compaction failed`
- `Full summarization failed`
- `Partial summarization also failed`

## 变更内容
将上述信号定义为“正文外发阻断信号”：
> 一旦命中，不再继续向用户自动发送正文结果。

仅允许：
- 内部失败记录
- 或极简失败状态

## 预期收益
- 切断旧内容 / 异常 fallback 结果继续外发
- 直接缓解重复同一条的风险

## 风险
中低（代价是部分自动任务会直接失败而非勉强给出内容）

## 回滚思路
如发现过于保守，可先收窄为仅对 `using current snapshot` 阻断，再观察其他失败信号。

---

# 3. Task 3 — retry 达阈值后禁止重复正文外发

## 类型
重试策略变更

## 触发条件
- `delivery failed + retrying`
- 同一 runId 多次 error
- `lane wait exceeded` 持续且伴随交付异常

## 变更内容
建立“用户可见正文外发阈值”：
> 达到阈值后，只允许内部重试，不允许继续对用户发送近似相同正文。

## 预期收益
- 把“重复 + 卡住”降级为“失败一次并收口”

## 风险
低

## 回滚思路
可放宽阈值，但不建议恢复到允许近似正文重复外发的旧模式。

---

# 4. Task 4 — 建立主会话高负荷任务隔离规则

## 类型
工作流治理变更

## 变更内容
以下任务默认不在主 Telegram 会话长跑：
- 长日志排障
- 大规模文件 / 代码扫描
- 多轮根因调查
- 高上下文长链路推理

改为：
> 优先在隔离子会话 / 独立执行链中完成，再把结论回传主会话。

## 预期收益
- 降低主会话 context overflow
- 降低 compaction / timeout / fallback 复发概率

## 风险
低

## 回滚思路
若隔离成本过高，可缩小任务范围，但不建议取消隔离原则。

---

# 5. Task 5 — 日报 / 周报切回 Assistant bot

## 类型
发送主体修正

## 当前状态
暂缓，不执行

## 暂缓原因
当前仍缺：
- Assistant bot 身份映射
- 当前 routing / path 对齐

## 当前动作
保留为第二批任务，待身份映射核清后再执行。

---

# 6. 执行优先级

## 第一批（准备执行）
1. Task 2
2. Task 3
3. Task 1
4. Task 4

## 第二批（暂缓）
5. Task 5

---

# 7. 本批验收标准

## 用户侧
- 不再出现同一条内容短时间重复发送
- 不再明显出现“卡在某条之后没回应”
- 自动汇报不再持续污染主会话

## 日志侧
- `using current snapshot` 后不再跟正文外发
- `retrying` 不再对应多条相似消息
- `lane wait exceeded` 下降
- 主会话 overflow / compaction failure 下降
