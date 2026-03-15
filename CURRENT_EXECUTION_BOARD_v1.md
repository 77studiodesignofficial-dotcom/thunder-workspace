# CURRENT_EXECUTION_BOARD_v1

> 用途：汇总 2026-03-15 当前阶段的执行状态，明确哪些事项已完成、哪些正在观察、哪些可并行推进、哪些暂不应动，以及历史待办如何排序。

---

# 0. Current Phase

当前阶段应统一描述为：

> **首批极窄 cron direct-delivery bypass 补丁已落地并已加载，72H 观察进行中；同时，执行治理中的 overtime-without-status 缺陷已被制度化补丁处理，并进入后续真实任务验证阶段。**

这意味着当前不是“大范围继续改”的阶段，而是：
- 主线进入观察与验证
- 副线只推进低风险收口和历史待办

---

# 1. Completed Today

## 1.1 Minimal-fix mainline
- 已确认最窄控制点为 **cron delivery 的 direct-vs-announce 分支**
- 已形成实施文档链：
  - `MINIMAL_FIX_IMPLEMENTATION_DRAFT_v2.md`
  - `MINIMAL_FIX_IMPLEMENTATION_PLAN_v2.md`
  - `MINIMAL_FIX_PATCH_CONDITION_ADDENDUM_v1.md`
- 已落下首批极窄补丁：
  - runtime file: `/usr/local/lib/node_modules/openclaw/dist/gateway-cli-B7fBU7gD.js`
- 首批 allowlist job：
  - `daily-comprehensive-briefing`
  - `end-of-day`
  - `weekly-review`
- 已完成本地语法检查
- 已完成 Gateway 重载
- 已完成最小运行验证检查
- 已新增 72H 观察清单：
  - `MINIMAL_FIX_72H_OBSERVATION_CHECKLIST_v1.md`

## 1.2 Execution-governance mainline
- 已把“超时未主动回状态”正式归类为：
  - `overtime-without-status`
  - 执行闭环失败
- 已新增治理补丁：
  - `EXECUTION_OVERTIME_RESPONSE_PATCH_v1.md`
- 已把 overtime 补丁接入治理链：
  - `EXECUTION_GOVERNANCE_STACK_v1.md`
  - `EXECUTION_COMPLIANCE_CHECKLIST_v1.md`
  - `EXECUTION_BEHAVIOR_VALIDATION_v1.md`

## 1.3 Continuity
- 已持续更新：
  - `memory/2026-03-15.md`

---

# 2. In Observation / Active Watch

## 2.1 72H patch observation
主线正在观察：
- `daily-comprehensive-briefing`
- `end-of-day`
- `weekly-review`

观察重点：
- delivery correctness
- bypass evidence
- output quality / finalization safety
- main-session contamination

## 2.2 Governance behavior validation
当前治理补丁也处于真实任务验证阶段，重点观察：
- 是否按承诺时间边界主动回报
- 工具失败是否及时转成用户可见状态事件
- 是否显式选择 execute / wait / downgrade / stop

---

# 3. Parallelizable Now

这些事项现在可以并行推进，且不会显著污染主线观察信号。

## P-1 Assistant bot canonical mapping 收口
### Why
- 现网 sender authority 证据已基本指向 `@TitenLi_bot`
- 但工作区历史文件仍存在 `@thunder_ai_bot` 与新表达混杂

### Value
- 降低后续 sender / routing 讨论的歧义
- 为第二批身份/路由问题做更干净的 preflight 收口

### Risk
- 低

### Recommendation
- **可立即并行**

---

## P-2 Workspace Git commit
### Why
- 今天有一批重要状态已经形成：补丁、观察清单、治理补丁、治理链补链

### Value
- 固化工作成果
- 降低回退/恢复时的信息散失风险

### Risk
- 低

### Recommendation
- **可立即并行**

---

## P-3 Brave Search API Key 评估 / 补齐
### Why
- 历史待办中仍未完成
- 会影响 `web_search` 的实用性

### Value
- 提升研究/搜索能力

### Risk
- 低到中（涉及配置）

### Recommendation
- **可并行，但低于 P-1 / P-2**

---

## P-4 Observation run record template（可选）
### Why
- 72H 清单已完成，但若补一个“每次 run 怎么记”的简版记录表，会让后续记录更快

### Value
- 降低 run-level 验证摩擦

### Risk
- 低

### Recommendation
- **可做，但优先级不高**

---

# 4. Do Not Expand Yet

这些事现在不应主动扩做，否则会污染观察窗口或扩大 blast radius。

## D-1 不要扩大 cron bypass 范围
- 不要把 allowlist 扩成更广 announce bypass
- 先看首批 72H 观察结果

## D-2 不要现在改共享 completion machinery
- 不碰通用 subagent completion machinery
- 不碰主会话通用 injected completion handling

## D-3 不要现在改更广 sender identity / routing 实现层
- 当前应先观察首批补丁
- 第二批身份/路由修复仍需谨慎收口

## D-4 不要把 overtime 治理继续膨胀成纯文档工程
- 当前规则已经足够
- 现在应靠真实任务验证，而不是继续堆规则文件

---

# 5. Historical Backlog

以下是仍未完成、但当前不一定都是主线阻塞项的历史待办。

## B-1 Brave Search API Key 配置
- 状态：未完成
- 阻塞程度：低
- 是否主线关键：否

## B-2 workspace Git commit
- 状态：未完成
- 阻塞程度：低
- 是否主线关键：否，但对固化今天成果有帮助

## B-3 其他 API 按需配置
- Gemini API Key
- Notion API Key
- OpenAI API Key（DALL-E）
- 状态：未完成
- 阻塞程度：低

## B-4 automation workflow polish
- 状态：持续项
- 阻塞程度：低到中

## B-5 feedback mode tuning
- 状态：持续项
- 阻塞程度：低到中

## B-6 Harness constraint refinement
- 状态：持续项
- 阻塞程度：中

---

# 6. Recommended Priority Order

## Main thread
### M-1
继续 **72H 观察 + 下一次目标 cron 触发后的 run-level 验证**

## Parallel thread
### P-1
Assistant bot canonical mapping 收口

### P-2
workspace Git commit

### P-3
Brave Search API Key 评估 / 补齐

### P-4
其他低风险 backlog（仅在不干扰观察的前提下）

---

# 7. Operating Rule For The Next Step

下一步选择任务时，遵循以下原则：

1. **主线不再扩改，只观察和验证**
2. **并行项只做低风险收口/固化/补齐**
3. **任何会污染观察信号的实现层变更，暂缓**
4. **任何超过 10–15 分钟的并行任务，都要继续遵守 overtime patch 的状态义务**

---

# 8. One-Line Summary

> 当前最合理的执行节奏是：主线进入 72H 观察与 run-level 验证，副线只推进低风险收口和历史待办，其中最值得并行的是 Assistant bot canonical mapping 收口与 workspace Git commit。
