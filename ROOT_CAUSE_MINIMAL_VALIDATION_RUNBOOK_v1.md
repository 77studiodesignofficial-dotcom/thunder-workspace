# ROOT_CAUSE_MINIMAL_VALIDATION_RUNBOOK_v1

> 目的：把 `ROOT_CAUSE_VALIDATION_CHECKLIST_v1.md` 压缩成最小可执行验证步骤。只做核验，不做修复。

---

# 0. 结论目标

要回答的不是“系统哪里都可能有问题”，而是：

> 这次“重复同一条 → 卡住 → 不推进 → 最后无回应”的**最可能主因**，到底是不是：
>
> 1. **H1**：主会话过重 / compaction 超时 / snapshot fallback
> 2. **H3**：queue / lane / retry / fallback 收口异常
> 3. **H4**：日报 / 周报发送主体错位
> 4. **H2**：双发送权 / 时区 / 幂等不足（背景问题）

---

# 1. 最小执行顺序

严格按这个顺序看：

1. **先验证 H1**
2. **再验证 H3**
3. **再验证 H4**
4. **最后确认 H2 是主因还是背景**

不要跳步，不要一开始就去改配置。

---

# 2. Step 1 — 验证 H1（主会话过重 / timeout / snapshot fallback）

## 目标
确认主 Telegram 会话是否真实发生了：

> context overflow  
> → compaction 失败  
> → embedded run timeout  
> → using current snapshot  
> → 紧接着密集 sendMessage

## 要看的日志关键词
- `agent:main:telegram:direct:6935067397`
- `model_context_window_exceeded`
- `Auto-compaction failed`
- `embedded run timeout`
- `using current snapshot`
- `Full summarization failed`
- `Partial summarization also failed`

## 判定标准
### H1 强成立
如果同时看到：
- 主会话 context overflow
- timeout + using current snapshot 成对重复出现
- compaction 连续失败
- timeout 后短时间内出现密集 sendMessage

### H1 中等成立
如果只看到其中 2-3 项，但时间线对得上。

### H1 暂不成立
如果没有主会话 overflow，也没有 snapshot fallback。

## 当前已知状态
- **已部分坐实**：主会话 overflow、compaction 失败、timeout、snapshot fallback 均已见到
- **还差最后一步**：把用户侧重复文本和内部 sendMessage 更精确对齐

---

# 3. Step 2 — 验证 H3（queue / lane / retry / 收口异常）

## 目标
确认系统是否并不是“发不出来”，而是：

> timeout / delivery failed 后  
> → lane 堵塞 / retry / 状态没收口  
> → 后续任务不推进

## 要看的日志关键词
- `lane wait exceeded`
- `queueAhead=`
- `cron announce delivery failed`
- `retrying`
- 同一 `runId` 的多次 `embedded run agent end`

## 判定标准
### H3 强成立
如果同时看到：
- lane wait exceeded
- queueAhead 明确 > 0
- announce delivery failed / retrying
- 同一 runId 多次 error end

### H3 中等成立
如果有堵塞和重试迹象，但缺少同一 runId 的完整链。

### H3 暂不成立
如果没有 lane/queue/retry 证据。

## 当前已知状态
- **已部分坐实**：lane wait exceeded、announce delivery failed、retrying、同 runId 多次 error 都见过
- **还差最后一步**：确认哪一个对象/任务没有正确收口

---

# 4. Step 3 — 验证 H4（发送主体错位）

## 目标
确认日报/周报是否偏离了原始设计：

> 本应由 Assistant bot 发送  
> 但实际卷入主 assistant 对话链

## 需要核对的事实
- Boss 的原始要求：**日报和周报由 Assistant bot 发送**
- 现网实际：这些自动消息是否通过主 assistant 回复链发出

## 判定标准
### H4 成立
如果同时满足：
- 原始设计要求 Assistant bot 发
- 实际自动消息由主 assistant 对话链送达

### H4 强成立
再加一条：
- 这些自动消息明显增加了主会话上下文负担

### H4 暂不成立
如果最终查明这些消息本来就是独立 bot path，不污染主会话。

## 当前已知状态
- **已坐实前提**：Boss 已明确补充原始设定
- **高疑似成立**：现象上 cron 结果确实卷进了主 assistant 回复链
- **还差最后一步**：查 delivery path / bot 身份配置

---

# 5. Step 4 — 验证 H2（双发送权 / 时区 / 幂等）

## 目标
确认 H2 是不是这次“卡住”的主因，还是只是系统背景问题。

## 要核对的事实
- 过去是否同时存在：
  - system cron 业务发送脚本
  - OpenClaw cron 业务发送 job
- 时区是否曾不一致
- 幂等是否最初未明确落地

## 判定标准
### H2 作为主因成立
需要直接抓到：
- 同类消息在同一时间窗内被双链路实际同时发出
- 且这正对应用户看到的重复消息

### H2 作为背景问题成立
只要确认：
- 双发送权曾存在
- 时区曾不一致
- 幂等曾不足

## 当前已知状态
- **背景问题已坐实**
- **直接主因尚未坐实**

---

# 6. 当前临时排序（基于已有证据）

1. **H1** — 最像直接主因
2. **H3** — 最像放大器 / 伴生机制
3. **H4** — 很可能加重主会话污染
4. **H2** — 已成立的背景结构问题

---

# 7. 何时可以进入修复阶段

只有在下面条件满足时，才建议进入“最小修复”：

- H1 至少中等成立
- H3 至少中等成立
- H4 至少完成 delivery path 核对
- H2 已明确降级为背景问题或被证明只是放大器

如果这些还没满足，不要贸然大改配置。

---

# 8. 最终输出模板

完成验证后，可直接用下面模板汇报：

## 验证结论
- H1：{强成立 / 中等成立 / 暂不成立}
- H3：{强成立 / 中等成立 / 暂不成立}
- H4：{成立 / 强成立 / 暂不成立}
- H2：{主因 / 背景问题 / 待定}

## 当前最可能根因
- {一句话结论}

## 仍缺失的关键证据
- {1-3 条}

## 是否建议进入最小修复
- {是 / 否}
- 原因：{一句话}
