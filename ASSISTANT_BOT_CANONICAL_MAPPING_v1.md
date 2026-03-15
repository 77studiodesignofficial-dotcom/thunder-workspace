# ASSISTANT_BOT_CANONICAL_MAPPING_v1

> 用途：对当前工作区中“Assistant bot / Telegram sender / runtime sender authority”的混杂表述做一次最小、可执行的统一收口。

---

# 0. Why This File Exists

当前工作区存在两类表述并存：
- `@TitenLi_bot`
- `@thunder_ai_bot`

在最小修复、sender/routing、cron delivery、main-session contamination 讨论中，如果不先统一口径，后续结论容易继续混淆。

本文件的目标不是回溯所有历史，而是定义：

> **当前阶段，在最小修复与运行时 sender authority 讨论中，应该采用什么 canonical mapping。**

---

# 1. Canonical Current Mapping

## 1.1 Current runtime sender authority
当前运行时 sender authority 应统一按以下口径引用：

> **Current runtime Telegram sender authority = `@TitenLi_bot`**

该口径适用于：
- 当前 OpenClaw Gateway 运行时
- 当前 Telegram provider 启动日志
- 当前 cron / delivery / sender authority 讨论

---

## 1.2 “Assistant bot” in current minimal-fix context
在当前最小修复上下文中：

> **“Assistant bot” 默认指当前运行时实际对外发送的 Telegram sender authority，即 `@TitenLi_bot`。**

除非文档明确标注“historical”或“legacy reference”，否则不要再把 “Assistant bot” 写成模糊匿名概念。

---

# 2. Historical / Legacy Mapping

## 2.1 `@thunder_ai_bot`
`@thunder_ai_bot` 当前应视为：

> **historical / legacy reference**

它可以保留在：
- 历史配置记录
- 早期 MEMORY.md 记忆
- 旧阶段的 bot 创建/配置背景

但在当前 sender authority / runtime routing / minimal-fix decision 讨论中：

> **不应默认把它当作 current runtime identity。**

---

# 3. Usage Rule For Future Documents

后续文档若讨论：
- 当前 Telegram sender
- 当前 cron 外发主体
- 当前 runtime sender authority
- 当前 Assistant bot 行为

应优先写成：

- **current runtime sender authority (`@TitenLi_bot`)**

若必须提到旧 bot，则写成：

- **historical / legacy bot reference (`@thunder_ai_bot`)**

避免再使用以下模糊写法：
- “Assistant bot” 但不指明是哪一个
- “the bot” 但不区分 runtime current vs historical config record

---

# 4. What Is Confirmed vs Not Yet Confirmed

## 4.1 Confirmed
以下结论可视为当前已确认：

- 当前 Gateway / Telegram provider 启动口径对应 `@TitenLi_bot`
- 当前 sender authority 讨论应以 `@TitenLi_bot` 为准
- 当前最小修复的首批补丁并未主动切换 sender identity
- `@thunder_ai_bot` 在当前阶段更像历史遗留表述，而非当前运行时主口径

## 4.2 Not yet fully closed
以下事项仍不应误写成“已彻底闭环”：

- 所有历史文档是否都已完成统一清账
- 更深层的 sender identity / routing 实现机制是否已完全清晰
- 第二批身份/路由修复是否还需要进一步 runtime-level preflight

所以当前更准确的表达是：

> **current runtime identity mapping is operationally settled, but full historical/document cleanup is not yet complete.**

---

# 5. Decision Rule

在后续讨论中，如果目标是：
- 当前修复判断
- 当前行为验证
- 当前 sender/routing preflight

则使用：

> `@TitenLi_bot`

如果目标是：
- 历史来源说明
- 旧配置记录解释
- 早期能力搭建背景

则可引用：

> `@thunder_ai_bot`（并明确标记 historical / legacy）

---

# 6. Scope Boundary

本文件 **不** 宣称：
- 所有 bot 相关问题都已解决
- sender/routing 第二批修复已可直接实施
- 当前 runtime identity 之外的所有历史记录都已自动统一

本文件只提供：

> **一个当前可执行、可引用、可减少歧义的 canonical mapping。**

---

# 7. One-Line Summary

> 在当前最小修复和运行时 sender authority 讨论里，`@TitenLi_bot` 应作为 canonical current runtime identity；`@thunder_ai_bot` 仅作为 historical / legacy reference 使用。
