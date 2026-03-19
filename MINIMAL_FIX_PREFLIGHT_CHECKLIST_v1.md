# MINIMAL_FIX_PREFLIGHT_CHECKLIST_v1

> 目的：在真正执行 `MINIMAL_FIX_PLAN_v1` 前，先把关键控制点核清，避免再次变成救火式误改。

---

# 0. 当前目标

在不大修 OpenClaw 内核的前提下，优先为以下问题做最小修复准备：

1. **H1**：主会话过重 / compaction 超时 / snapshot fallback
2. **H3**：queue / lane / retry / fallback 收口异常
3. **H4**：日报 / 周报发送主体错位

当前阶段：**只核对，不改动。**

---

# 1. Preflight-1：当前日报 / 周报实际走哪个 delivery path？

## 要核对的问题
- `daily-comprehensive-briefing`
- `weekly-review`
- （可选一起核）`end-of-day`

这些任务当前完成后，结果到底是：

### A
直接通过目标 bot / 目标 delivery path 送达

### B
先回到主 assistant 会话，再由主 assistant 转写 / 回复给 Boss

## 需要确认的证据
- cron job 的 delivery 配置
- 当前 provider / account / to / channel 映射
- 实际日志里对应的发送路径
- 主会话是否接到了这类自动结果并进行了可见回复

## 核对完成标准
能明确回答：
> 这三类自动任务现在到底是“独立 bot 发送”，还是“卷入主 assistant 回复链”。

---

# 2. Preflight-2：Assistant bot 在现网中对应哪个身份？

## 要核对的问题
Boss 的设计要求是：
- 日报和周报由 **Assistant bot** 发送

但要真正落地，必须核清：

- 当前 Assistant bot 在现网配置中对应哪个 bot / provider / account
- 当前主 assistant 使用的又是哪个 bot / provider / account
- 两者是否其实是同一个 Telegram bot，只是路径不同
- 如果不是同一个，它们怎么区分

## 需要确认的证据
- 当前 Telegram/provider 相关配置
- 账号映射
- 现有 delivery/accountId/channel/to 的组合

## 核对完成标准
能明确回答：
> “Assistant bot” 在系统里到底是哪一个发送身份，和当前主 assistant 的发送身份是否一致。

---

# 3. Preflight-3：自动任务结果为什么会卷入主会话？

## 要核对的问题
如果自动汇报结果最终进入主 assistant 会话，需要分清是哪个层导致：

### A
任务 prompt / 任务设计本身就在要求主 assistant 整理并回复

### B
cron 的 announce / relay 机制把结果转回主会话

### C
delivery 配置本身就在使用主会话路由

### D
runtime completion event 被主会话接住后再次对外回复

## 需要确认的证据
- job 的 payload.message
- job 的 delivery 配置
- runtime completion 交付路径
- 日志里主会话是否承接了 cron 结果

## 核对完成标准
能明确回答：
> 自动汇报“进入主会话”的根本原因在哪一层：任务设计、announce 机制、delivery 配置，还是 completion relay。

---

# 4. Preflight-4：timeout / snapshot fallback 后正文外发的控制点在哪？

## 要核对的问题
如果系统在：
- `embedded run timeout`
- `using current snapshot`
- compaction failed
之后仍然对外发正文，那么要找到控制点在哪：

### A
agent runtime 自身会继续产出用户可见结果

### B
announce / completion relay 会把 fallback 结果继续发出

### C
主 assistant 收到 completion event 后再次手动转写给用户

## 需要确认的证据
- timeout 时段对应的 gateway 日志
- runtime completion 事件路径
- 用户侧回复是否来自自动 relay，还是来自主 assistant 二次加工

## 核对完成标准
能明确回答：
> 如果要实现“timeout / snapshot fallback 后不再继续正文外发”，真正应该拦在哪一层。

---

# 5. Preflight-5：retry 重复外发正文的控制点在哪？

## 要核对的问题
如果出现：
- `delivery failed`
- `retrying`
- 同一 runId 多次 error end

到底是哪一层在把重复内容再次发向用户：

### A
delivery retry 本身

### B
announce retry

### C
completion relay 重入

### D
主 assistant 会话再次接到并回复

## 需要确认的证据
- 同一 runId 的完整错误 / 重试时间线
- 对应的 sendMessage 时间线
- 该时间段是否有主 assistant 明确回复行为

## 核对完成标准
能明确回答：
> 如果要实现“retry 达阈值后不再重复正文外发”，应该修改哪一层策略，而不是拍脑袋全拦。

---

# 6. Preflight-6：主会话是否需要建立“高负荷任务隔离规则”？

## 要核对的问题
当前主会话是否已经承担了过多高负荷任务，例如：
- 长日志排障
- 多步系统调查
- 长文复盘
- 多图分析
- 大量上下文连续追问

## 需要确认的证据
- 主会话 overflow / compaction / timeout 的发生频率
- 同时期任务类型
- 是否有更适合放到隔离子会话的工作持续留在主会话执行

## 核对完成标准
能明确回答：
> 主会话是否已经到达“必须建立高负荷任务隔离规则”的程度。

---

# 7. 执行门槛

只有在下面条件至少满足 4/6 时，才建议进入最小修复执行：

- 已明确日报 / 周报当前实际 delivery path
- 已明确 Assistant bot 的现网身份映射
- 已明确自动结果卷入主会话的根层原因
- 已明确 timeout / snapshot fallback 后正文外发的控制点
- 已明确 retry 重复外发的控制点
- 已确认主会话高负荷隔离规则确有必要

如果不足 4/6，继续核对，不要贸然改。

---

# 8. 核对完成后的下一步

完成本清单后，再进入：

## `MINIMAL_FIX_EXECUTION_PLAN_v1`
内容只包含：
- 要改哪一层
- 每层改什么
- 为什么改
- 验收标准是什么

在此之前，不建议直接下手改动。
