# GitHub CLI 安装与认证指南

## 步骤 1：安装（Boss 执行）

在本地终端执行：
```bash
brew install gh
```

**验证安装成功**：
```bash
gh --version
# 应显示类似：gh version 2.x.x (2026-...)
```

---

## 步骤 2：认证（Boss 执行）

安装完成后，执行：
```bash
gh auth login
```

**按提示操作**：
1. 选择 **GitHub.com**
2. 选择 **HTTPS** 或 **SSH**（推荐 HTTPS，更简单）
3. 选择 **Login with a web browser**
4. 浏览器会打开 GitHub 授权页面
5. 登录 GitHub 账号（如未登录）
6. 点击 **Authorize github**
7. 复制显示的验证码，粘贴回终端

**验证认证成功**：
```bash
gh auth status
# 应显示：✓ Logged in to github.com as YOUR_USERNAME
```

---

## 步骤 3：通知 Thunder

认证完成后，在 Telegram 发送消息：
```
GitHub CLI 安装完成，用户名是：xxx
```

**Thunder 将执行**：
1. 验证 gh CLI 可用性
2. 测试基础功能（gh repo list 等）
3. 配置到 OpenClaw 凭证系统（可选）
4. 解锁 GitHub 相关 Skill

---

## 常见问题

**Q: 浏览器授权失败？**
A: 尝试选择 **Paste an authentication token** 方式：
- 访问 https://github.com/settings/tokens
- 生成新 Token（classic），勾选 **repo** 权限
- 复制 Token 粘贴到终端

**Q: 需要哪些权限？**
A: 基础使用需要：
- repo（访问仓库）
- read:org（读取组织信息，可选）
- workflow（管理 GitHub Actions，可选）

**Q: 安装后 gh 命令找不到？**
A: 尝试刷新 shell：
```bash
source ~/.zshrc  # 或 ~/.bashrc
# 或重启终端
```

---

**状态**: ⏳ 等待 Boss 执行步骤 1-2
**预计时间**: 5-10 分钟
**阻塞任务**: GitHub 集成、代码管理自动化、gh-issues Skill
