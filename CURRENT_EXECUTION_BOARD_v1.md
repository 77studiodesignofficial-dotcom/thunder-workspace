# CURRENT_EXECUTION_BOARD_v1

> 用途：汇总 2026-03-15 当前阶段的执行状态，明确哪些事项已完成、哪些正在观察、哪些可并行推进、哪些暂不应动，以及历史待办如何排序。

---

# 0. Current Phase

当前阶段应统一描述为：

> **首批极窄 cron direct-delivery bypass 补丁已落地并已加载，72H 观察进行中；同时，执行治理中的 overtime-without-status 缺陷已被制度化补丁处理，并进入后续真实任务验证阶段。**

这意味着当前不是"大范围继续改"的阶段，而是：
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
- 已把"超时未主动回状态"正式归类为：
  - `overtime-without-status`
  - 执行闭环失败
- 已新增治理补丁：
  - `EXECUTION_OVERTIME_RESPONSE_PATCH_v1.md`
- 已把 overtime 补丁接入治理链：
  - `EXECUTION_GOVERNANCE_STACK_v1.md`
  - `EXECUTION_COMPLIANCE_CHECKLIST_v1.md`
  - `EXECUTION_BEHAVIOR_VALIDATION_v1.md`

## 1.3 Capability补齐（阶段1完成）
- **Notion API 配置完成**：
  - 通过 Chrome Browser Relay 完成 Notion 登录
  - 创建 Integration: `OpenClaw-Integration`
  - 关联工作空间: `77Studio's Space`
  - API Token 已配置到 OpenClaw `env.NOTION_API_KEY`
  - `openclaw skills list` 显示 notion skill: **✓ ready**
- **Gemini CLI & ClawHub CLI 安装完成**：
  - `@google/gemini-cli@0.33.1` 全局安装成功
  - `clawhub@0.8.0` 全局安装成功
  - 两个 skill 均显示 **✓ ready**
- **Apple Notes & Reminders CLI 安装完成**：
  - `memo` (Apple Notes CLI) 通过 Homebrew 安装成功
  - `remindctl` (Apple Reminders CLI) 通过 Homebrew 安装成功
  - 两个 skill 均显示 **✓ ready**
  - 当前可用技能: **11/51**
- **DALL-E (openai-image-gen)**：
  - 需要 Python 3.10+，当前系统为 3.9.6
  - 暂时无法使用

## 1.4 Continuity
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

## P-3 `web_search` 宿主绑定 / Kimi 搜索验证问题（下一批）
### Current status
- **blocked / deferred-after-observation**

### What is already done
- 已创建专属 Moonshot/Kimi API key：`openclaw-kimi-search`
- 已写入 Gateway 配置：
  - `tools.web.search.enabled = true`
  - `tools.web.search.provider = "kimi"`
  - `tools.web.search.kimi.apiKey = <configured>`
- 已完成 Gateway 重载
- 已确认：当前聊天中的 `functions.web_search` 仍返回 `missing_perplexity_api_key`

### Current judgment
- 这不是 key / schema / reload 问题
- 当前最可信解释是：**当前会话里的 `functions.web_search` 调用面，没有命中本机 Gateway 最新 search runtime snapshot**

### Trigger to resume
- **默认触发**：72H 观察拿到第一轮阶段结论后立即进入下一批处理
- **提前升级触发**：如果未来 24-48 小时内需要可靠 `web_search`，则提前升级为近期项

### Acceptance criteria
1. 当 `tools.web.search.provider = "kimi"` 且 `tools.web.search.kimi.apiKey` 已配置时，`web_search(...)` 不再返回 `missing_perplexity_api_key`
2. 至少完成一次明确命中 Kimi provider 的 smoke test
3. 明确说明当前 `web_search` 到底是否读本机 Gateway config；若不是，给出正确验证入口或最窄修复点

### Priority
- 高于一般 API 补齐 / workflow polish
- 低于当前 cron first-batch 72H 观察主线

### Recommendation
- **不在今晚继续深挖；默认放入 72H 第一轮结论后的 next batch**

---

## P-4 Claude 调用链 / 代理线路整治预研（已归档）
### Final status
- **resolved-via-alternative**

### Resolution summary
- Claude CLI 因区域限制无法登录
- Claude Desktop App 已登录，可作为手动替代
- **关键发现**：OpenClaw 已配置 Codex 为主模型，当前正在使用 `openai-codex/gpt-5.4`
- 无需继续追求 Claude CLI 自动化，Codex 已满足 coding-agent 需求

### Alternative in place
- **主模型**: `openai-codex/gpt-5.4` (OAuth 认证)
- **备用**: `moonshotcn/kimi-k2.5`
- **手动 Claude**: Desktop App 作为补充

### Closed at
- 2026-03-16 11:20 PDT

### What is already known
- 当前主机上的 Claude CLI 已安装：`/usr/local/bin/claude`
- 版本已确认：`2.1.62 (Claude Code)`
- `claude --help` 可正常执行
- 最小非交互调用当前失败：`Not logged in · Please run /login`

### Historical judgment
- 昨天/本轮已识别到 `Claude CLI 未登录` 这一层阻塞
- 但尚未把问题完整上升为正式的"Claude 调用链 / 代理线路整治"问题单
- 当前已补齐该归纳：这条线不应只看登录，还应后续评估长期 Claude 调用链

### Candidate tracks after login
1. 直接恢复 Claude CLI 作为 coding-agent 通道
2. 评估是否需要替代调用链 / 代理线路
3. 将 `ccswitch` 作为候选辅助工具评估（当前仅知其定位为 `Claude Code configuration switcher - Git-based context management CLI`）

### Waiting on
- **Boss 先完成 Claude 登录，再决定下一步**

### Acceptance criteria for next stage
1. `claude --print 'ping' --permission-mode bypassPermissions` 成功
2. 明确是否继续走直接 Claude CLI，还是进入代理线路整治/替代调用链评估
3. 若评估 `ccswitch`，需明确它是配置切换辅助层还是实际调用链组成部分

### Priority
- 低于当前 cron 72H 观察主线
- 可作为观察窗口中的并行准备项

---

## P-5 选项指代确认机制优化（待讨论）
### Current status
- **pending-discussion**

### Problem Statement
用户指代"选项 X"时，发生理解混淆：
- 用户的"选项3"被误解为"理解 B"
- 澄清消息结构混乱（"理解 A/B" vs "选项 1/2/3"）
- 导致执行错误方向

### Observed Failure (2026-03-16)
- 用户说"先做选项3，再回头测试新能力"
- 我理解为"理解 B = 回到主线"
- 实际用户意思是"选项3 = 阶段3 (Python/DALL-E)"
- 延迟 10+ 分钟才澄清正确理解

### Open Questions
1. 如何区分"选项列表编号"和"理解方案字母"？
2. 用户说"选项X"时，复述确认的最佳格式？
3. 多选项场景下，如何防止指代歧义？

### Recommendation
- **单独拎出深入讨论**
- 不在治理文档中强制固化
- 待讨论出清晰规则后再纳入

---

## P-6 GitHub / 外部 Skills 接入与安全门控预研
### Current status
- **planned-parallel-research**

### What is already confirmed
- GitHub CLI (`gh`) 已登录且可用
- 当前 GitHub 账号：`77studiodesignofficial-dotcom`
- 权限 scopes 已确认：`repo`, `read:org`, `workflow`, `gist`
- `gh api user` 返回正常，说明基础 GitHub API 访问链路可用
- OpenClaw 当前具备的 skills 能力更偏向：`list / info / check`
- 当前未确认存在官方的一键式 `GitHub URL -> 安全安装技能` 受控产品化链路

### Core judgment
- **GitHub 接口已对接，基础访问链路是通的**
- **外部 skills 获取代码本身大体顺畅，但安全、标准化、可审计的接入流程尚未系统化**
- 当前已有的安全能力更偏向：
  1. exec approvals / allowlist / ask / security modes
  2. security audit
  3. skill readiness / info / missing requirements 检查
- 当前尚未证明已具备完整的：
  - 外部 skill 自动恶意代码扫描
  - 仓库签名/信任来源验证
  - 安装前标准隔离执行与风险评分流水线

### Scope
1. GitHub / ClawHub / 外部来源 skill 的标准接入路径梳理
2. 接入前检查清单
3. 权限收敛基线（deny / allowlist / ask）
4. 最小隔离验证流程

### Acceptance criteria
1. 明确外部 skill 的标准接入流程，不再依赖临场判断
2. 明确一份接入前安全检查清单
3. 明确默认权限基线与需要人工批准的高风险动作
4. 能把"可获取代码"与"可安全接入执行面"区分清楚

### Priority
- 低于当前 cron 72H 观察主线
- 可作为观察窗口中的并行治理准备项
- 高于一般性 backlog 整理

### Recommendation
- 先做治理与流程设计，再考虑实际引入外部 skill

---

## P-6 Observation run record template（可选）
### Why
- 72H 清单已完成，但若补一个"每次 run 怎么记"的简版记录表，会让后续记录更快

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
### 已完成 (2026-03-16)
- ✅ ~~Notion API Key~~
- ✅ ~~Gemini CLI~~
- ✅ ~~ClawHub CLI~~
- ✅ ~~Apple Notes/Reminders CLI~~
- ⏸️ ~~Notion 报告写入~~ **挂起 (2026-03-17)** - Notion API/UI 同步问题，待后续处理
- ❌ ~~nano-banana-pro~~ **放弃**（免费额度耗尽，无法预期重置时间）
- 🔄 **图像生成替代方案**（待决策）：
  - 方案A：DALL-E（需 OpenAI 充值）
  - 方案B：Stability AI（免费额度申请）
  - 方案C：本地 Diffusion 模型（需 GPU）

### 受阻项及替换方案
| 受阻能力 | 受阻原因 | 替换方案 | 状态 |
|---------|---------|---------|------|
| **DALL-E** | OpenAI 账单限制 | 1. nano-banana-pro (Gemini) ⏸️<br>2. Stability AI API (调研中)<br>3. 本地 Diffusion 模型 (调研中) | 待决策 |
| **ElevenLabs** | 需付费 $5/月 | 1. **OpenAI TTS** (已配置，可直接使用)<br>2. macOS `say` 命令 (离线)<br>3. Google Cloud TTS (调研中) | 推荐方案1 |
| **web_search** | 配置未生效 | 1. 修复 Kimi provider (P-3)<br>2. Tavily API (需 wrapper)<br>3. Brave API (需申请 key) | P-3 跟踪 |

### 推荐优先级
1. ✅ ~~立即使用: OpenAI TTS~~ **已启用并测试成功 (2026-03-16 15:50)**
2. **明日测试**: nano-banana-pro 图像生成
3. **调研中**: Stability AI、本地模型

### 下一步决策
- [ ] 是否启用 OpenAI TTS 作为默认语音合成？
- [ ] 是否申请 Stability AI API Key（免费额度）？
- [ ] 是否部署本地 Diffusion 模型（需要 GPU 资源）？

---

## B-4 浏览器使用优化方案（待决策）

### 当前问题
- Chrome Browser Relay 需要用户保持标签页在前台
- 页面加载/跳转时经常需要等待
- OAuth/MFA 流程需要频繁切换 tab
- 用户同时使用 Chrome 时会互相干扰

### 优化方案对比

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **A. 专用 Chrome Profile** | 隔离性好，不影响用户日常使用 | 仍需 Relay，基础问题存在 | 高频浏览器操作 |
| **B. API 优先策略** | 无需浏览器，最稳定 | 并非所有服务都有 API | 数据查询、配置管理 |
| **C. Playwright 直连** | 无需 Relay，更稳定 | 需要额外配置，可能需用户授权 | 自动化测试、批量操作 |
| **D. 截图+指导模式** | 用户完全掌控，零干扰 | 效率最低，需要人工配合 | 敏感操作、一次性任务 |

### 推荐组合策略
1. **默认**: API 优先（如 Notion API 替代网页操作）
2. **OAuth 必需时**: 专用 Chrome Profile
3. **批量/重复操作**: 评估 Playwright 直连
4. **敏感/复杂操作**: 截图+指导模式

### 待决策
- [ ] 是否为 OpenClaw 创建专用 Chrome Profile？
- [ ] 是否授权使用 Playwright 直接控制浏览器（无需 Relay）？
- [ ] 哪些场景必须坚持 API 优先，禁止使用浏览器？

---

## B-5 automation workflow polish
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
`web_search` 宿主绑定 / Kimi 搜索验证问题（72H 第一轮结论后进入 next batch；若 24-48h 内需要可靠 web_search，则提前升级）

### P-4
Claude 调用链 / 代理线路整治预研（待登录后决策）

### P-5
选项指代确认机制优化（待讨论）

### P-6
GitHub / 外部 Skills 安全框架 ✅ **已批准**
- 文档: `GITHUB_EXTERNAL_SKILLS_SECURITY_FRAMEWORK_v1.md`
- 批准时间: 2026-03-18 04:33 PDT
- Phase 1 待执行: skill-review 脚本、隔离环境、skill-registry

### P-7
AI术语与知识点汇总（搁置，待技术问题解决后执行）

### P-8
Subagent 通信技术限制问题（明日排查）
- **现象**: `sessions_spawn` 成功但 `sessions_send` 返回 `visibility=tree` 限制
- **影响**: 无法向子代理发送指令，长时任务隔离受阻
- **明日行动**: 
  1. 检查 Gateway `tools.sessions.visibility` 配置
  2. 验证子会话 `54bac769-...` 状态
  3. 测试替代通信方式（`subagents steer` 等）
  4. 确认正确的 subagent 使用流程

### P-9
其他低风险 backlog（仅在不干扰观察的前提下）

---

# 7. Operating Rule For The Next Step

下一步选择任务时，遵循以下原则：

1. **主线不再扩改，只观察和验证**
2. **并行项只做低风险收口/固化/补齐**
3. **任何会污染观察信号的实现层变更，暂缓**
4. **任何超过 10-15 分钟的并行任务，都要继续遵守 overtime patch 的状态义务**

---

# 8. One-Line Summary

> 当前最合理的执行节奏是：主线进入 72H 观察与 run-level 验证，副线只推进低风险收口和历史待办，其中最值得并行的是 Assistant bot canonical mapping 收口与 workspace Git commit。
