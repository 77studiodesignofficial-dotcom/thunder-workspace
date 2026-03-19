# GAP_INVESTIGATION_SEQUENCE_v1

> 目的：把 `PREFLIGHT_GAP_CLOSURE_PLAN_v1` 进一步压成顺序化调查步骤。只做调查与判定，不直接改动。

---

# 0. 当前调查目标

优先补齐 4 个阻塞执行的缺口：

1. 自动结果为什么卷入主会话
2. timeout / snapshot fallback 后正文外发控制点在哪
3. retry 重复外发正文控制点在哪
4. Assistant bot 身份映射是什么

---

# 1. 调查顺序总览

严格按以下顺序进行：

## Step A
**先查自动结果卷入主会话的根层原因**

## Step B
**再查 timeout / snapshot fallback 后正文外发控制点**

## Step C
**再查 retry 重复外发正文控制点**

## Step D
**最后查 Assistant bot 身份映射**

原因：A/B/C 直接决定这次“重复 → 卡住 → 沉默”的止血点；D 决定 H4 的主体修正。

---

# 2. Step A — 自动结果为什么卷入主会话

## 要回答的问题
自动任务结果进入主会话，到底是哪一层导致的：

- A1. 任务 prompt / payload 设计本身
- A2. cron announce / relay 机制
- A3. delivery 配置本身
- A4. runtime completion event 被主 assistant 二次接住并回复

## 先查什么
1. 相关 job 的 payload/message
2. job 的 delivery 配置
3. runtime completion event 是否会送回主会话
4. 主会话是否在任务完成后做了可见回复

## 查到了算什么
### 如果发现是 payload / prompt 设计导致
说明控制点在**任务设计层**。

### 如果发现是 announce / relay 导致
说明控制点在**cron 交付层**。

### 如果发现是主 assistant 再次转写导致
说明控制点在**completion relay / 主会话承接层**。

## 查不到怎么办
如果无法单层坐实，就按“**task design + relay 双层叠加**”暂存，不直接改。

---

# 3. Step B — timeout / snapshot fallback 后正文外发控制点

## 要回答的问题
系统在：
- `embedded run timeout`
- `using current snapshot`
- compaction failed
之后，正文为什么还能继续发给用户？

## 先查什么
1. timeout 时段的 gateway 日志时间线
2. 对应 completion / announce 事件时间线
3. 用户可见 sendMessage 时间线
4. 主 assistant 是否在该时段做了二次输出

## 查到了算什么
### 如果正文直接由 runtime / announce 发出
控制点在**自动交付链**。

### 如果正文来自主 assistant 二次回复
控制点在**主会话承接层**。

### 如果两者都参与
主控制点优先放在**更靠前的一层**，避免后层被动兜底。

## 查不到怎么办
如果无法完全坐实对象链，就先按“**timeout / using current snapshot 之后禁止自动正文外发**”作为保守规则。

---

# 4. Step C — retry 重复外发正文控制点

## 要回答的问题
重复外发到底是谁在推动：

- C1. delivery retry
- C2. announce retry
- C3. completion relay 重入
- C4. 主 assistant 二次回复

## 先查什么
1. 单个 runId 的完整错误 / retry 时间线
2. 该时间窗内的 sendMessage 时间线
3. 主会话是否在同时间窗也进行了回复

## 查到了算什么
### 如果重复消息紧跟 retry 事件出现
控制点倾向于 **delivery / announce retry**。

### 如果 retry 后由主 assistant 才出现用户可见正文
控制点倾向于 **主会话承接层**。

### 如果两边都有
优先拦**最前面的自动外发层**。

## 查不到怎么办
如果对象链不完整，就先按保守原则：
> retry 达阈值后，只允许内部重试，不允许继续重复正文外发。

---

# 5. Step D — Assistant bot 身份映射

## 要回答的问题
“Assistant bot” 在现网里到底是谁：

- 哪个 bot
- 哪个 accountId
- 哪个 provider / channel / to 映射
- 与当前主 assistant 的发送身份是否同一对象

## 先查什么
1. Telegram / provider / account 配置
2. 当前自动消息实际用的发送身份
3. 主 assistant 回复链使用的发送身份
4. 是否存在同 bot 不同 path，还是不同 bot 不同 path

## 查到了算什么
### 如果是同 bot 不同 path
修复重点是**路由隔离**，不是换 bot。

### 如果是不同 bot
修复重点是**把日报/周报切回正确 bot/account**。

## 查不到怎么办
如果现网配置暂时无法完全识别，不要直接切换发送主体；先保持 H4 为“待核实但高优先”。

---

# 6. 调查完成后的判定模板

## A. 自动结果卷入主会话原因
- 结论：{task design / relay / delivery / completion relay / 混合}

## B. timeout 后正文外发控制点
- 结论：{runtime / announce / completion relay / 主 assistant / 混合}

## C. retry 重复外发控制点
- 结论：{delivery retry / announce retry / completion relay / 主 assistant / 混合}

## D. Assistant bot 身份映射
- 结论：{已明确 / 部分明确 / 未明确}

---

# 7. 进入执行阶段的门槛

只有当下面至少 3 项完成时，才建议进入 `MINIMAL_FIX_EXECUTION_PLAN_v1`：

- 已定位自动结果卷入主会话的主控制层
- 已定位 timeout 后正文外发的主控制层
- 已定位 retry 重复外发的主控制层
- 已明确 Assistant bot 的现网身份映射

其中，前 3 项优先级高于第 4 项。

---

# 8. 当前调查纪律

- 不把“高概率”说成“已坐实”
- 不在控制点未定位前就盲改
- 可以先形成保守策略结论，但不要冒充为对象级铁证
- 一切以减少主会话污染、切断重复外发链为优先
