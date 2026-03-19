# MEMORY.md - Thunder 的长期记忆

## 我是谁
- **名称**: Thunder
- **角色**: Titen 的 CEO（执行助理）
- **emoji**: ⚡
- **创建时间**: 2026-03-07

## 关于 Boss
- **姓名**: Titen
- **关系**: 专业高效的工作伙伴关系
- **工作风格**: 目标导向，重视系统性解决方案
- **当前项目**: OpenClaw 生态建设、Harness Engineering 实践

## 沟通协议（2026-03-09 更新）
- **即时确认**: 收到消息先回复"收到"，再执行任务
- **原因**: Boss 随时在线，避免等待焦虑

## 关键决策记录

### 2026-03-18（第11周）
- **Fallback 链更新**：GPT-5.4 → GLM-5 → Kimi（GLM 优先于 Kimi）
- **Token 监控**：创建 `token-monitor.sh`，待安装 crontab
- **健康检查降频**：30分钟 → 2小时
- **Cron 任务修复**：三个报告任务统一使用 `glm-coding/glm-4.7`，简化 prompt

### 2026-03-08（第10周复盘）
- **Harness 理论体系确立**: 从控制论/代理理论/系统论/认知科学角度完成深层研究
- **运维体系全面建设**: thunder-dashboard统一入口 + 四大故障处理器 + 三层报告体系
- **故障预案设计**: Token耗尽/网络掉线/字数限制/幽灵进程 四大场景全覆盖
- **Cron任务最终配置**: 晨报9:00/日结18:00/周报周日20:00，等待手动安装crontab

### 2026-03-07
- **Harness 协作模式确立**: 三层递进（设立规则→释放能力→执行业务）
- **约束层级定义**: 🟢只读 🟡交互 🟠输入 🔴敏感
- **试运行启动**: 预判式自主 + 标准反馈 + 单次修正
- **凭证管理**: 双模式（开发.env/生产Keychain），Moonshot API 已配置

## 工作模式
- **Phase 1**: 设立规则 ✅ 已完成
- **Phase 2**: 释放能力 ✅ 已完成
- **Phase 3**: 执行业务 ✅ 已完成
- **Phase 4**: 运维保障 ✅ 已建立（等待crontab安装生效）

## 运维机制（2026-03-08 完善）

### 统一监控入口
- **工具**: thunder-dashboard.sh
- **命令**: status(摘要) / health(诊断) / logs(日志) / report(报告) / fix(修复)

### 故障处理器（四大预案）
- **幽灵进程**: 每5分钟检查；2026-03-12 起默认保守模式，仅审计不自动 kill 主 Gateway
- **Token监控**: 每小时检查；2026-03-12 起以观测/记录为主，不自动切换 fallback
- **网络故障**: 每分钟检测；2026-03-12 起仅做探测、状态落盘与审计，不直接外发消息或重启主服务
- **字数限制**: 超长消息自动分段或转文件发送
- **统一运行模式**: 新增 `~/.openclaw/fault-handlers.env`，默认 `SAFE_MODE=1`、`DRY_RUN=0`
- **统一日志目录**: `~/.openclaw/fault-handlers/`，新增 `audit-critical.log` 与统一 `cron.log`

### 故障处理
- **事件-001**: 27分钟延迟响应（已记录，已修复）
- **根因**: 浏览器操作无超时保护
- **修复**: 所有操作强制设置 timeoutMs/timeout

### 健康检查
- **工具**: thunder-ops.sh
- **频率**: 每次任务前执行
- **内容**: OpenClaw状态、凭证系统、僵尸进程、网络状态

### 超时标准
- **浏览器操作**: 15,000ms（15秒）
- **简单命令**: 30秒
- **网络请求**: 30秒
- **复杂任务**: 120秒
- **长时任务**: 使用 background 模式

### 监控告警
- **响应时间 > 30秒**: 自动发送进度汇报
- **响应时间 > 60秒**: 报警并尝试恢复
- **健康检查异常**: 立即清理并修复

## 安全策略配置（2026-03-07 最终版）

### 决策1：Cron 任务权限
- **选择**: A - 保持现状
- **说明**: 全功能运行，接受风险，追求便利
- **状态**: 3个任务已启用（晨报/日结/周报）

### 决策2：浏览器安全
- **选择**: B - 轻量级增强
- **具体规则**:
  - ✅ 信任 macOS 基础安全（Gatekeeper/XProtect/SIP）
  - 🚫 弹窗：一律拦截并汇报 Boss
  - ⏸️ 下载：保存到隔离目录，扫描后汇报
  - 📢 跨域跳转：汇报目标域名
  - 🚫 敏感 API（摄像头/麦克风/位置）：直接阻止

### 决策3：信息汇报敏感度
- **选择**: B + 例外机制
- **脱敏规则**:
  - 🔴 凭证类：只显示前缀（sk-xxx...xxx）
  - 🟠 路径类：泛化目录名（~/Documents/[项目名]）
  - 🟠 通信类：脱敏发送者身份（[外部投资者]）
  - 🟡 行为类：透明汇报
- **例外机制**: Boss 指令"详细汇报 xxx"时提供完整信息

### 生效时间
- **生效日期**: 2026-03-07
- **审核周期**: 每月审查一次，根据实际运行情况调整

## 能力完善状态

### ✅ 已完成
- [x] **Cron 定时任务配置**
  - daily-comprehensive-briefing: 每天 9:00（综合晨报：工作区 + AI/OpenClaw 资讯）
  - end-of-day: 工作日 18:00（日结：回顾今日 + 提醒明日）
  - weekly-review: 每周日 20:00（周报：整理本周学习成果）
- [x] **MEMORY.md 跨会话记忆系统**
- [x] **Subagent 长期运行能力**

### ✅ 已完成
- [x] **GitHub CLI 安装与认证**
  - 账号: 77studiodesignofficial-dotcom
  - 权限: repo, read:org, workflow, gist
  - 状态: 已可用
- [x] **Telegram Bot 创建与配置**
  - Bot 名称: Thunder
  - 用户名: @thunder_ai_bot
  - Token: 8687796735:AAE0QUUNrQxqbmBffSwdL0Aa8i_98hwJ1j0
  - 状态: Token 已存储，配置完成
- [x] **智谱 GLM API 接入（方案C）**
  - API Key: 2802ae35...（已存储）
  - 模型: GLM-4-Flash（免费）, GLM-Z1-Flash（免费）
  - 状态: ✅ 已配置，测试成功
  - 用途: 与 Moonshot 双轨运行
- [ ] **其他 API 按需配置**
  - Gemini API Key（summarize CLI 用）
  - Notion API Key（知识库管理）
  - OpenAI API Key（DALL-E 图片生成）

### 🔄 持续优化
- [ ] 自动化工作流打磨
- [ ] 反馈模式调优
- [ ] Harness 约束细化

### 📋 待办事项
- [x] Token 分配管理方案设计（双订阅池 + 单API池）
- [ ] **手动安装 Token 监控 crontab**（2026-03-18 新增）
  - 命令：`crontab /tmp/thunder-crontab`
  - 或手动添加：`0 */6 * * * /Users/titen/.openclaw/workspace/token-monitor.sh --alert`
  - 原因：crontab 命令在 exec 环境执行超时（macOS 安全限制）

## 多模型与额度调度策略（2026-03-09）

### 资源池划分
- **订阅池**:
  - `openai-codex/gpt-5.4`：最高质量决策、复杂规划、Boss高价值直聊
  - `glm-coding/glm-4.7`：主力编码模型、普通复杂度 coding task
  - `glm-coding/glm-5`：高复杂度编码、复杂推理、关键中文任务
- **API池**:
  - `openai/gpt-4o-mini`：快响应、cron、轻量任务、日常确认
  - `zai/glm-5`：GLM Coding 套餐异常时的 API 兜底
  - `moonshot/kimi-k2.5`：保留 API 充值模式，作为备用中文长文本/备用通道

### 调度原则
- **Boss复杂对话** → `gpt-5.4`
- **Boss简单确认/状态回复** → `gpt-4o-mini`
- **普通编码任务** → `glm-coding/glm-4.7`
- **高复杂编码/攻关** → `glm-coding/glm-5`
- **中文复杂任务** → `glm-coding/glm-5`
- **cron/自动任务** → 默认 `gpt-4o-mini`
- **中文高质量总结** → `glm-coding/glm-4.7`

### 使用纪律
- GPT-5.4 不用于 cron、低价值确认、机械整理
- GLM Coding 套餐内部分层：普通任务优先 4.7，复杂任务再上 5
- Kimi 保持 API 模式，不作为主链路
- OpenAI 订阅异常 → 切 `glm-coding/glm-5`
- GLM Coding 套餐异常 → 切 `zai/glm-5`

### 已落地配置
- 默认主模型：`openai-codex/gpt-5.4`
- fallback：`openai/gpt-4o-mini` → `zai/glm-5`
- 已新增 `glm-coding` provider，接入 `https://open.bigmodel.cn/api/coding/paas/v4`
- 已验证 `glm-coding/glm-4.7` 与 `glm-coding/glm-5` 均成功消耗 GLM Coding Pro 套餐额度
- 三个 cron 任务已切换为 `openai/gpt-4o-mini`，避免静默消耗高价值订阅额度

## 重要文件位置
```
~/workspace/
├── thunder-dashboard.sh             # ⭐ 统一监控入口
├── optimized-daily-briefing.sh      # ⭐ 优化日报
├── weekly-report.sh                 # ⭐ 周报生成
├── fault-handler-controller.sh      # 故障处理器控制器
├── ghost-process-cleanup.sh         # 幽灵进程清理
├── token-monitor.sh                 # Token监控
├── network-failover.sh              # 网络故障转移
├── smart-send.sh                    # 智能发送
├── openclaw-skill-wrapper-v2.sh     # Skill执行
├── openclaw-cred-hub-v2.sh          # 凭证管理
├── HARNESS_ENGINEERING_DEEP_DIVE.md # Harness研究
├── OPERATIONS_PLAN_v2.md            # 运维规划
├── DISASTER_RECOVERY_PLAN.md        # 故障预案
├── SECURITY_POLICY_v1.0.md          # 安全策略
└── SETUP_COMPLETE_REPORT.md         # 配置报告

~/.openclaw/
├── .env.skill                       # API Keys
└── .mode                            # 凭证模式
```

## 会话连续性
> 每次会话我会读取此文件恢复记忆。
> 如需让我记住重要信息，请说"记住：..."
