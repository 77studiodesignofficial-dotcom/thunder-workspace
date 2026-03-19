# GITHUB_EXTERNAL_SKILLS_SECURITY_FRAMEWORK_v1.md

## P-6 GitHub/外部 Skills 安全门控预研

**状态**: 进行中  
**创建时间**: 2026-03-18 04:15 PDT  
**目标**: 建立外部 skill 安全接入的治理框架

---

## 一、现状分析

### 1.1 当前技能生态

**内置 Skills (9个已就绪)**:
- coding-agent, gh-issues, github, healthcheck, skill-creator, weather
- notion, gemini, clawhub (今日新增)
- apple-notes, apple-reminders (今日新增)

**技能来源分类**:
| 来源 | 数量 | 信任级别 | 示例 |
|------|------|----------|------|
| OpenClaw 内置 | 11 | ⭐⭐⭐ 高 | coding-agent, weather |
| 官方 CLI 集成 | 4 | ⭐⭐⭐ 高 | memo, remindctl |
| npm/brew 安装 | 2 | ⭐⭐ 中 | gemini, clawhub |
| 外部 GitHub | 0 | ⭐ 待评估 | 潜在风险来源 |

### 1.2 当前安全基线

**已配置**:
- ✅ Exec 权限模式: ask/allowlist/deny
- ✅ Security audit 工具
- ✅ Skills check/readiness 验证

**缺失**:
- ❌ 外部 skill 审查流程
- ❌ Skill 来源验证机制
- ❌ 运行时隔离沙箱
- ❌ 供应链风险扫描

---

## 二、安全风险评估

### 2.1 外部 Skill 风险矩阵

| 风险类型 | 严重性 | 可能性 | 说明 |
----------|--------|--------|------|
| **恶意代码执行** | 🔴 高 | 中 | Skill 中包含恶意脚本 |
| **凭证窃取** | 🔴 高 | 中 | 读取 ~/.env, API keys |
| **数据外泄** | 🔴 高 | 低 | 发送数据到外部服务器 |
| **权限提升** | 🟡 中 | 低 | 利用漏洞获取更高权限 |
| **供应链污染** | 🟡 中 | 中 | 依赖项包含漏洞 |
| **拒绝服务** | 🟢 低 | 低 | 资源耗尽攻击 |

### 2.2 攻击场景示例

**场景 1: 恶意 SKILL 安装**
```
攻击者发布 skill: "advanced-coding-agent"
用户安装后执行: 窃取 ~/.openclaw/.env
                  发送 API keys 到远程服务器
```

**场景 2: 供应链攻击**
```
合法 skill 依赖恶意 npm 包
安装时: 执行 postinstall 脚本
        植入后门
```

**场景 3: 配置劫持**
```
skill 修改 ~/.zshrc 或 ~/.bashrc
添加: alias openclaw=' malicious-wrapper'
长期窃取所有操作
```

---

## 三、安全门控方案设计

### 3.1 分级接入模型

```
Level 1: 内置 Skills (OpenClaw 官方)
         └── 自动信任，完整权限

Level 2: 验证 Skills (知名作者/组织)
         └── 快速审查，标准权限

Level 3: 社区 Skills (GitHub 开源)
         └── 深度审查，受限权限

Level 4: 未知 Skills (未经验证)
         └── 沙箱运行，只读权限
```

### 3.2 审查流程 (Level 3/4 Skills)

**阶段 1: 静态分析 (5-10分钟)**
```
□ 检查 SKILL.md 完整性
□ 审查 scripts/ 目录所有代码
□ 检查 package.json / requirements.txt 依赖
□ 搜索危险模式: curl|bash, eval, exec, rm -rf
□ 检查网络请求 (fetch, axios, requests)
```

**阶段 2: 依赖审计 (5分钟)**
```
□ npm audit / pip check
□ 检查已知漏洞 (CVE 数据库)
□ 验证依赖来源 (非私人 registry)
```

**阶段 3: 行为测试 (隔离环境)**
```
□ 在临时 workspace 首次运行
□ 监控文件系统访问 (fs-monitor)
□ 监控网络请求 (net-monitor)
□ 检查环境变量读取
□ 验证输出符合预期
```

**阶段 4: 权限收敛**
```
□ 根据行为测试设置最小权限
□ 配置 exec allowlist (仅必要命令)
□ 设置文件访问限制 (workspace-only)
□ 禁用网络访问 (如不需要)
```

### 3.3 安全检查清单

#### A. 代码审查清单
- [ ] 无硬编码凭证 (API keys, tokens)
- [ ] 无外部网络请求 (除非功能必需)
- [ ] 无文件系统越界访问 (限制在 workspace)
- [ ] 无 shell 注入风险 (exec, eval, system)
- [ ] 无隐藏依赖 (git submodule, 远程脚本)

#### B. 行为审查清单
- [ ] 首次运行监控通过
- [ ] 无异常网络流量
- [ ] 无敏感文件读取 (~/.ssh, ~/.env)
- [ ] 输出符合 SKILL.md 描述
- [ ] 无僵尸进程残留

#### C. 维护审查清单
- [ ] 作者身份可验证 (GitHub 账号, 邮箱)
- [ ] 项目活跃维护 (最近 6 个月有更新)
- [ ] 有 issue/PR 响应记录
- [ ] 许可证明确 (MIT/Apache/GPL)

### 3.4 权限收敛基线

**默认最小权限 (Level 4)**:
```json
{
  "exec": {
    "mode": "deny",
    "allowlist": []
  },
  "filesystem": {
    "read": ["~/workspace/*"],
    "write": ["~/workspace/*"],
    "deny": ["~/.openclaw/*", "~/.ssh/*", "~/.env*"]
  },
  "network": {
    "mode": "deny"
  }
}
```

**根据审查结果逐步放开**:
- 需要执行命令 → 添加到 allowlist
- 需要网络访问 → 开启特定域名
- 需要读取配置 → 显式授权文件路径

---

## 四、最小隔离验证流程

### 4.1 隔离环境设置

```bash
# 创建临时测试 workspace
mkdir -p /tmp/skill-test-$(date +%s)
cd /tmp/skill-test-$(date +%s)

# 设置只读环境变量
export OPENCLAW_WORKSPACE=/tmp/skill-test-$(date +%s)
export PATH=/usr/local/bin:/usr/bin  # 最小 PATH
unset HOME  # 防止读取真实 home
```

### 4.2 运行时监控

```bash
# 使用 strace/dtruss 监控系统调用
# 使用 lsof 监控文件访问
# 使用 nettop/netstat 监控网络

# 示例: dtruss 监控文件访问
dtruss -f -t open openclaw skill run <skill-name> 2>&1 | grep -E "^open|\.env|config"
```

### 4.3 验证通过标准

| 检查项 | 通过标准 | 失败处理 |
--------|----------|----------|
| 文件访问 | 仅 workspace 内 | 拒绝安装 |
| 网络请求 | 无或符合预期 | 询问授权 |
| 命令执行 | 仅 allowlist 内 | 拒绝执行 |
| 执行时间 | < 60 秒 | 超时 kill |
| 资源使用 | CPU < 50%, 内存 < 500MB | 资源限制 |

---

## 五、实施路线图

### Phase 1: 基础设施 (本周)
- [ ] 创建 skill-review 脚本
- [ ] 设置隔离测试环境
- [ ] 建立 skill-registry 清单

### Phase 2: 流程建立 (下周)
- [ ] 制定审查 SOP
- [ ] 建立 skill 分级标签
- [ ] 培训使用审查清单

### Phase 3: 持续运营 (长期)
- [ ] 定期审计已安装 skills
- [ ] 监控 skill 运行时行为
- [ ] 更新威胁情报库

---

## 六、决策建议

### 短期 (立即执行)
1. **禁止直接安装外部 GitHub skills**
   - 仅通过官方渠道 (clawhub, npm, brew)
   
2. **建立技能白名单**
   - 当前 15 个已验证 skills → 白名单
   - 新 skills → 强制审查流程

3. **启用最严格 exec 模式**
   - `security: ask`
   - `ask: always`

### 中期 (本周)
1. 完成 Phase 1 基础设施
2. 测试审查流程
3. 文档化并培训

### 长期 (持续)
1. 建立技能评分体系
2. 社区贡献审查工具
3. 自动化安全扫描

---

## 附录

### A. 参考资源
- OpenClaw 官方安全指南: https://docs.openclaw.ai/security
- npm 安全最佳实践: https://docs.npmjs.com/security
- SLSA 供应链安全框架: https://slsa.dev/

### B. 工具推荐
- `npm audit`: 依赖漏洞扫描
- `semgrep`: 静态代码分析
- `trivy`: 容器/文件系统扫描
- `strace/dtruss`: 系统调用监控

---

**编制**: Thunder (OpenClaw AI Assistant)  
**审核**: ✅ 已批准 (2026-03-18 04:33 PDT)
**状态**: Phase 1 待执行  
**版本**: v1.0-draft
