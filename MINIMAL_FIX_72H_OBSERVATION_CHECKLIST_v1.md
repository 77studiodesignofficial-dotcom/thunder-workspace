# MINIMAL_FIX_72H_OBSERVATION_CHECKLIST_v1

> 用途：为首批极窄 cron direct-delivery bypass 补丁提供统一的 72H 观察与验证口径。

---

# 0. Scope

本观察清单只覆盖首批 allowlist patch：
- `daily-comprehensive-briefing`
- `end-of-day`
- `weekly-review`

不用于判定：
- 非目标 cron 行为
- 通用 announce/completion machinery 质量
- Assistant bot identity/routing 的全量问题是否彻底解决

---

# 1. Observation Goal

72H 观察的目标不是“证明系统完美”，而是回答 4 个实际问题：

1. 目标业务 cron job 是否成功命中 bypass
2. 命中后是否减少主会话回流/污染
3. 目标消息是否仍然正确、完整、按预期送达
4. 是否引入新的副作用（早发、误发、重复发、文本质量退化）

---

# 2. Per-Run Verification Card

每次目标 job 运行后，按下列 4 类检查。

## 2.1 Delivery correctness
检查：
- 是否投递到正确频道
- 是否投递到正确目标（`6935067397`）
- 是否只有一条预期业务消息
- 是否没有明显漏发

判定：
- 全部满足 → PASS
- 有重复/漏发/错投 → FAIL

## 2.2 Bypass evidence
检查：
- 日志中是否出现 `direct-delivery bypass active for <job.name>`
- 是否没有出现同类旧 completion relay / 主会话改写特征

判定：
- 有 bypass 标记且无旧回流特征 → PASS
- 无 bypass 标记但行为仍正常 → HOLD（可能未命中条件，需继续查）
- 明显仍走旧回流链 → FAIL（对该 job 而言）

## 2.3 Output quality / finalization safety
检查：
- 文本是否像最终用户可见正文
- 是否出现中间态/过程态文本
- 是否出现“还没收口”的内容
- 是否出现本应抑制却被外发的内容

判定：
- 文本 final、独立、可投递 → PASS
- 轻微风格退化但不影响业务 → WARN
- 中间态/未收口/错误抑制 → FAIL

## 2.4 Main-session contamination
检查：
- 该 job 运行后，主会话是否还出现旧式 completion relay 注入
- 是否再出现同类“自动结果扩写成主对话”的症状

判定：
- 未见回流/污染 → PASS
- 证据不足 → HOLD
- 明显仍发生回流 → FAIL

---

# 3. Global 72H Success Criteria

72H 窗口结束时，若满足以下条件，可判定首批补丁阶段性成功：

## 3.1 Core success
- 3 个目标 job 中，至少已观察到主要运行样本
- 目标 job 未出现明显错投/漏发/重复发
- 至少有明确证据显示目标 job 命中 bypass 或不再表现出旧回流症状
- 主会话污染症状下降或在目标 job 上消失

## 3.2 Safety success
- 未出现中间态直发
- 未出现 suppression 语义破坏
- 未出现非目标 announce 行为回归

若以上全部成立：
> 判定为 **72H PASS（first-batch patch accepted）**

---

# 4. Warning Conditions

以下情况记为 WARN，不立即回滚，但要重点盯：

- 个别 run 未命中 bypass，但最终外发仍正确
- 文本风格有轻微变化，但仍是 final user-facing message
- 日志证据不完整，但未见用户面症状
- 单次异常无法确认是否来自本补丁

处理：
- 继续观察
- 补日志/证据
- 不立即扩大补丁范围

---

# 5. Immediate FAIL / Pause Conditions

只要出现以下任一情况，应视为需要立即暂停观察并评估回滚：

1. **重复发送明显增加**
2. **目标 job 错投到错误频道/对象**
3. **出现中间态/未收口文本直发**
4. **本应抑制的内容被发出**
5. **目标 job 仍稳定回流主会话，且症状未下降**
6. **非目标 announce 行为被补丁误伤**
7. **Gateway / Telegram delivery 出现与补丁时间点高度相关的新异常**

若命中以上任一项：
> 进入 **PAUSE / rollback evaluation**

---

# 6. Evidence Chain Requirements

每次关键 run 至少收集 3 类证据中的 2 类：

## A. Runtime/log evidence
例如：
- bypass active 日志
- direct delivery 成功日志
- 无旧回流迹象的运行日志

## B. Delivery evidence
例如：
- Telegram 实际送达结果
- 是否只出现一条业务消息
- 是否仍由预期 sender authority 发出

## C. Session-behavior evidence
例如：
- 主会话是否出现 completion relay 注入
- 是否仍出现自动扩写成主对话的模式

原则：
> **没有证据链的“感觉正常”，不能算完整 PASS。**

---

# 7. Per-Job Tracking Template

建议每个目标 job 至少记录一条如下条目：

## Job
- name:
- run time:

## Result
- delivery correctness: PASS / WARN / FAIL
- bypass evidence: PASS / HOLD / FAIL
- output quality: PASS / WARN / FAIL
- main-session contamination: PASS / HOLD / FAIL

## Evidence
- log:
- delivery:
- session behavior:

## Decision
- accepted for observation continuation
- warn and continue
- pause and investigate

---

# 8. Rollback Evaluation Rule

是否回滚，不以“看起来不舒服”判定，而以这三项优先：

1. **验收标准**：目标消息是否仍然正确送达
2. **证据链**：是否有足够证据证明 bypass 引发了坏行为
3. **超时与降级**：若出问题，是否能以窄范围回退到旧 announce 行为

如果：
- 业务正确性失败
- 且证据链指向本补丁
- 且风险正在持续

则：
> 回滚首批 cron-specific bypass branch

---

# 9. Recommended Observation Rhythm

在 72H 内，优先盯这几次触发：
- 下一次 `daily-comprehensive-briefing`
- 下一次 `weekly-review`
- 下一次 `end-of-day`

每次触发后都不要直接下结论，而是：
1. 先看送达
2. 再看日志
3. 再看主会话是否被污染
4. 最后判 PASS/WARN/FAIL

---

# 10. One-Line Summary

> 72H 观察不是看“有没有消息发出去”，而是看目标 cron job 是否在不再污染主会话的前提下，仍然正确、单次、最终态地完成用户投递。
