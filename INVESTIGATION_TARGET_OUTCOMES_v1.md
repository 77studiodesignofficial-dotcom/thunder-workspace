# INVESTIGATION_TARGET_OUTCOMES_v1

> 目的：定义调查阶段的明确终点，避免无限继续做框架而不进入执行。完成本文件中的目标后，即可判断是否进入 `MINIMAL_FIX_EXECUTION_PLAN_v1`。

---

# 0. 当前阶段目标

当前不是继续扩展假设，而是把调查收敛到可以执行的结论：

1. 自动结果为什么卷入主会话
2. timeout / snapshot fallback 后正文外发控制点在哪
3. retry 重复外发正文控制点在哪
4. Assistant bot 的现网身份映射是什么

---

# 1. Target Outcome A — 自动结果卷入主会话

## 需要拿到的最终结论
必须能给出下面三种结论之一：

### A1
**主要由任务设计 / payload 导致**

### A2
**主要由 cron announce / relay / delivery 机制导致**

### A3
**主要由主 assistant 承接 completion event 后再次回复导致**

如果无法单点定位，允许使用：

### A4
**双层叠加：任务设计 + relay，或 relay + 主 assistant 承接**

## 何时算完成
只要能明确指出“主控制层”在哪，就算完成。

## 如果查不到
采用保守替代结论：
> 自动结果至少不应继续作为主会话正文展开，先在流程层切断污染。

---

# 2. Target Outcome B — timeout / snapshot fallback 后正文外发控制点

## 需要拿到的最终结论
必须能给出下面三种结论之一：

### B1
**正文由自动交付链直接外发**

### B2
**正文由主 assistant 在 completion event 后二次转写外发**

### B3
**两者叠加，但主控制点在前置自动交付链**

## 何时算完成
只要能明确“应该优先拦哪一层”，就算完成。

## 如果查不到
采用保守替代结论：
> 命中 `embedded run timeout` / `using current snapshot` / compaction failed 后，自动任务禁止继续正文外发。

---

# 3. Target Outcome C — retry 重复外发正文控制点

## 需要拿到的最终结论
必须能给出下面四种结论之一：

### C1
**delivery retry 是主控制点**

### C2
**announce / relay retry 是主控制点**

### C3
**主 assistant 二次承接才是主控制点**

### C4
**混合触发，但最前面的自动外发层应优先收紧**

## 何时算完成
只要能区分：
- 哪些是内部重试
- 哪些会变成用户可见重复外发

就算完成。

## 如果查不到
采用保守替代结论：
> retry 达阈值后，只允许内部重试，不允许继续重复正文外发。

---

# 4. Target Outcome D — Assistant bot 身份映射

## 需要拿到的最终结论
必须能给出下面两种结论之一：

### D1
**同一个 bot，不同 delivery / routing path**

### D2
**不同 bot / account，需要把日报和周报切回正确 bot**

## 何时算完成
只要能明确：
- 当前主 assistant 用的是什么身份
- Assistant bot 用的是什么身份
- 两者是“同 bot 不同 path”还是“不同 bot”

就算完成。

## 如果查不到
保留 H4 为高优先待核实，不直接切发送主体。

---

# 5. 调查阶段的收敛条件

满足以下条件时，视为调查阶段完成：

- A 已完成
- B 已完成
- C 已完成
- D 至少达到“部分明确”

其中：
- A / B / C 是进入最小修复的硬门槛
- D 是高优先但可在必要时以保守方式暂缓精确切换

---

# 6. 进入执行阶段的触发条件

只要满足：
- A、B、C 全部完成
- D 明确或可安全暂缓

即可进入：

## `MINIMAL_FIX_EXECUTION_PLAN_v1`

执行阶段只允许围绕：
1. 切断自动结果污染主会话
2. 禁止 timeout / snapshot fallback 后继续正文外发
3. 收紧 retry 导致的重复正文外发
4. 在身份映射明确后，恢复日报/周报的 Assistant bot 路径

---

# 7. 当前调查纪律

- 不继续扩张假设集合
- 不在 A/B/C 未完成前进入盲改
- 如果对象级证据不足，允许采用保守规则，但必须标明“这是保守策略，不是铁证结论”
- 目标是尽快让调查收敛到可执行，而不是把框架无限细化
