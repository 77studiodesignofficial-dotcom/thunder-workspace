# 智谱 GLM 方案C - 零成本试用配置指南

## 配置步骤

### 步骤1：注册智谱账号（Boss执行）

1. 访问 https://bigmodel.cn/
2. 点击右上角"登录/注册"
3. 使用手机号注册
4. 完成实名认证（如需）

### 步骤2：获取 API Key（Boss执行）

1. 登录后进入控制台 https://bigmodel.cn/console/overview
2. 左侧菜单 → "API Keys"
3. 点击 "创建新的 API Key"
4. 复制生成的 Key（格式：开头通常是数字，很长一串）

### 步骤3：提供 Key 给我

在 Telegram 发送消息：
```
智谱 API Key: xxxxxxxxxxxxxxxxxxxxxxx
```

### 步骤4：我自动完成配置

收到 Key 后，我将自动执行：
- ✅ 存储到凭证系统（.env.skill + Keychain）
- ✅ 测试 API 连接
- ✅ 创建智谱 Skill 包装器
- ✅ 配置模型切换逻辑
- ✅ 发送测试消息验证

---

## 方案C 配置详情

### 可用模型

| 模型 | 价格 | 用途 |
|------|------|------|
| GLM-4-Flash-250414 | **免费** | 日常文本、简单代码 |
| GLM-Z1-Flash | **免费** | 推理任务、数学计算 |
| CogView-3 | 按需付费 | 图片生成（可选） |

### 使用限制（需确认）

免费模型通常有：
- RPM（每分钟请求数）限制，如 3-10 次/分钟
- 每日/每月总调用量上限
- 并发数限制

**建议**：注册后查看控制台的"额度管理"页面确认具体限制。

---

## 使用方式

配置完成后，使用方法：

### 方式1：直接调用
```bash
./openclaw-skill-wrapper-v2.sh zhipu "你的问题"
```

### 方式2：自动切换（与Moonshot共存）
```
Boss: "写一个Python爬虫"
Thunder: 自动识别为代码任务 → 调用 GLM-4-Flash → 返回结果

Boss: "分析这张图片"
Thunder: 检测到图片 → 调用 GLM-4V → 返回分析
```

### 方式3：Boss指定
```
Boss: "用智谱分析这个"
Thunder: 明确使用智谱API

Boss: "用Moonshot总结"
Thunder: 明确使用Moonshot API
```

---

## 后续升级路径

试用满意后，可随时升级：

```
方案C（免费）
    ↓ 满意
方案B（性价比）- 增加 GLM-4-Air + GLM-5-Code
    ↓ 需要更强能力
方案A（专业级）- 增加 GLM-5 + GLM-4.6V + CogView-3
```

---

**请 Boss 现在访问 https://bigmodel.cn/ 注册并获取 API Key。**
