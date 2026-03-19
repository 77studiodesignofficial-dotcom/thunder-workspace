# ROOT_CAUSE_VALIDATION_CHECKLIST_v1

> 目的：先验证并排序根因，不直接修复。聚焦这次“重复同一条 → 卡住 → 不推进 → 最后无回应”的主因判定。

---

# 1. 当前候选假设

## H1
**主会话过重 / compaction 超时 / snapshot fallback 导致旧内容重复复用**

## H3
**lane / queue / busy / retry / fallback 状态没有正确收口，导致流程卡死**

## H4
**日报 / 周报发送主体错位：本应由 Assistant bot 发送，却卷入主 assistant 路径**

## H2
**双发送权 / 时区 / 幂等不足，是背景结构问题，不一定是本次直接主因**

---

# 2. 验证顺序

按以下顺序验证，避免把结构问题和直接触发因混为一谈：

1. **H1**：先看主会话是否真实过载，并进入 timeout + snapshot fallback
2. **H3**：再看 queue / lane / retry / fallback 是否放大问题
3. **H4**：再核对发送主体是否偏离原始设计
4. **H2**：最后确认它到底是主因还是背景放大器

---

# 3. H1 验证清单

## 要验证的问题
是否存在这条链：

> 主会话上下文过重  
> → compaction / embedded run timeout  
> → using current snapshot  
> → 旧内容重复  
> → 用户看到同一条反复出现

## H1-1：主会话是否发生上下文溢出
### 需要证据
- `model_context_window_exceeded`
- `context-overflow-diag`
- `Auto-compaction failed`
- sessionKey 指向 `agent:main:telegram:direct:6935067397`

### 支持 H1 的判断
如果这些都发生在主 Telegram 会话上，说明主会话真实过载，而不是泛化风险。

### 反证
如果这类日志主要发生在其他 session，则削弱 H1。

## H1-2：是否出现 timeout 后 fallback 到 current snapshot
### 需要证据
成对出现：
- `embedded run timeout`
- `using current snapshot: timed out during compaction`

### 支持 H1 的判断
如果在同一 session、同一时间窗内连续出现多次，说明 fallback 已经成为重复性的回退模式。

### 反证
如果只有 timeout，没有 snapshot fallback，则 H1 不完整。

## H1-3：fallback 后是否出现密集外发
### 需要现象
在 timeout + snapshot fallback 之后，短时间内出现：
- 多条连续 `sendMessage ok`
- 时间间隔极短
- 用户侧观察到“同一条/相似内容重复”

### 支持 H1 的判断
如果时间顺序能对齐：
1. timeout
2. using current snapshot
3. 多次 sendMessage
则 H1 大幅增强。

### 反证
如果 timeout 后根本没有发消息，而重复消息出现在别的时间段，H1 需要降权。

## H1-4：compaction 是否连续失败
### 需要证据
- `Full summarization failed`
- `Partial summarization also failed`
- usage limit / rate limit / summarization failed

### 支持 H1 的判断
如果 compaction 自己就持续失败，说明系统无法把上下文压下去，会话会继续恶化。

### 反证
如果 compaction 大多成功，H1 就更像偶发支线。

## H1 判定标准
### 高优先级成立
满足以下 3 条以上：
- 主会话 context overflow 明确存在
- embedded run timeout + using current snapshot 成对重复出现
- fallback 后紧跟密集 sendMessage / 用户侧重复
- compaction 连续失败

### 中等成立
满足 2 条，且时间线能对齐。

### 不成立
只有“上下文很长”的猜测，没有明确超时 / fallback / 对外发送链证据。

---

# 4. H3 验证清单

## 要验证的问题
是否存在这条链：

> 某次 timeout / announce 异常后  
> → queue / lane / busy 状态没收口  
> → 系统还以为前一件事没结束  
> → 后续任务不推进  
> → 最后用户看到“卡住”和沉默

## H3-1：是否存在 lane 堵塞
### 需要证据
- `lane wait exceeded`
- `queueAhead=...`
- `waitedMs=...`

### 支持 H3 的判断
如果主会话 lane 明确出现长等待和排队，说明“后续不推进”是队列真实堵塞。

### 反证
如果从未出现 lane 等待异常，H3 需要降级。

## H3-2：是否存在 announce / delivery failed 后继续重试
### 需要证据
- `cron announce delivery failed`
- `transient failure, retrying`
- 同一 runId 多次 error end

### 支持 H3 的判断
如果同一 run / 同一任务在失败后反复重试，说明状态收口可能不干净，H3 很可能是放大器。

### 反证
失败后立刻终止，没有重试/重入痕迹，则 H3 较弱。

## H3-3：是否存在同一 runId 多次结束/报错
### 需要证据
同一个 runId：
- 多次 `embedded run agent end`
- 多次 `isError=true`
- 时间上呈递增重试模式

### 支持 H3 的判断
这说明流程并不是“一次失败就结束”，而是某种状态未闭环，或有重复尝试/重复消费。

### 反证
每个 runId 都只出现一次，H3 就弱很多。

## H3-4：沉默期是否对应内部阻塞
### 需要现象
在用户感知沉默的时段，日志里是否有：
- lane wait exceeded
- timeout
- retry
- delivery failed
而不是完全空白

### 支持 H3 的判断
如果沉默期不是“系统没收到”，而是“系统忙着失败/等待/重试”，H3 成立。

### 反证
如果沉默期日志完全平静，可能要怀疑别的层。

## H3 判定标准
### 高优先级成立
满足以下 3 条以上：
- lane wait exceeded 明确出现
- announce/delivery failed 明确出现
- 同一 runId 多次 error/retry
- 沉默期可对齐到阻塞/重试日志

### 中等成立
只看到部分阻塞和重试，但时间线不够完整。

### 不成立
没有 queue/lane/retry 证据，只有“用户感觉卡”。

---

# 5. H4 验证清单

## 要验证的问题
是否存在这条偏离设计的情况：

> 原本日报 / 周报应该由 Assistant bot 发  
> 但实际结果进入了主 assistant 对话路径  
> 从而污染主会话上下文并增加卡死风险

## H4-1：确认原始设计
### 已知前提
Boss 已明确补充：
- **日报和周报应由 Assistant bot 发送**

## H4-2：确认现网实际投递路径
### 需要现象
任务完成后，消息是：
- 由 bot 独立投递
还是
- 通过主 assistant 普通回复链发给 Boss

### 支持 H4 的判断
如果 cron 结果被主 assistant 直接接住、改写、回复给 Boss，而不是走独立 bot delivery，则发送主体错位成立。

### 反证
如果本来就是 Assistant bot 独立发送，则 H4 不成立。

## H4-3：确认错位是否污染主会话
### 需要证据
- cron 结果进入主对话上下文
- 主会话继续围绕这些自动消息展开
- 导致主会话 message count / compaction 压力增加

### 支持 H4 的判断
如果自动汇报消息不是“外部投递”，而是“内化成主会话内容”，H4 会增强 H1。

### 反证
如果 bot 投递和主会话上下文完全隔离，H4 就弱。

## H4 判定标准
### 成立
满足以下 2 条：
- 原始设计要求 Assistant bot 发
- 实际投递进入主 assistant 路径

### 强成立
再加一条：
- 这种错位明显加重了主会话上下文压力

---

# 6. H2 验证清单

## 要验证的问题
H2 是不是这次直接主因，还是只是背景问题。

## H2-1：是否有同一时间窗的双链路实际出手
### 需要证据
同一类消息、同一时间窗内，既有：
- system cron 脚本发送证据
又有：
- OpenClaw cron delivery 证据

### 支持 H2 为主因
如果能抓到同一类消息的双链路实际同时发出，H2 升级。

### 反证
如果异常时段主要是主会话 timeout/fallback，而没有 shell cron 出手证据，H2 降级。

## H2-2：时区错误是否能解释“卡住”
### 判断方法
时区不一致可以解释：
- 何时发错
- 哪天算 business_date

但通常解释不了“卡在同一条消息不推进”。

### 当前意义
如果核心问题是卡死，H2 更像背景问题，不像主因。

## H2 判定标准
### 作为主因成立
需要拿到：
- 双链路同时发
- 且该双发直接对应用户观察到的重复

### 作为背景问题成立
只要确认：
- system cron 和 OpenClaw cron 都曾具备发送权
- 时区曾不一致
- 幂等不足

---

# 7. 最终判定规则

## 组合 A
- H1 高成立
- H3 中高成立
- H4 成立
- H2 仅背景成立

### 结论
本次事故主因是**主会话上下文 / 压缩 / 回退链路问题**，发送主体错位和状态收口异常为重要放大器，双发送权只是背景脆弱性，不是第一主因。

## 组合 B
- H2 高成立
- H1/H3 证据弱

### 结论
本次问题主要是双发送权和调度结构冲突。

## 组合 C
- H1 高成立
- H3 高成立
- H2 也高成立

### 结论
这是多层叠加事故，但“卡住”主因仍优先归到 H1/H3，H2 负责放大复杂度。

---

# 8. 当前临时排序（基于现有证据）

1. **H1**
2. **H3**
3. **H4**
4. **H2**

即：更像是主会话过重 + timeout/fallback + 状态收口异常，而不是单纯的 cron 双发送。

---

# 9. 使用说明

- 本文件用于**根因验证和讨论**，不是修复方案。
- 未拿到对象级证据前，不要把“高概率”说成“已坐实”。
- 若后续补到更强日志（payload 指纹、queue item 生命周期、delivery path 配置），应更新为 v2。
