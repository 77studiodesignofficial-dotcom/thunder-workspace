# 故障处理器安装完成报告

## 已创建的脚本

| 脚本 | 功能 | 位置 |
|------|------|------|
| ghost-process-cleanup.sh | 幽灵进程自动清理 | workspace/ |
| token-monitor.sh | Token 消耗监控 | workspace/ |
| network-failover.sh | 网络掉线检测与恢复 | workspace/ |
| smart-send.sh | 智能发送（字数限制处理）| workspace/ |
| fault-handler-controller.sh | 统一控制器 | workspace/ |

## 手动安装 crontab

由于自动安装超时，请 Boss 手动执行：

```bash
# 编辑 crontab
crontab -e

# 添加以下内容：
# Thunder 故障处理器
*/5 * * * * $HOME/.openclaw/workspace/fault-handler-controller.sh ghost
0 * * * * $HOME/.openclaw/workspace/fault-handler-controller.sh token
* * * * * $HOME/.openclaw/workspace/fault-handler-controller.sh network
```

## 测试脚本

```bash
# 测试幽灵进程清理
cd ~/.openclaw/workspace
./ghost-process-cleanup.sh

# 测试 Token 监控
./token-monitor.sh

# 测试网络检测
./network-failover.sh

# 测试智能发送
./smart-send.sh "这是一条测试消息"
./smart-send.sh "$(python3 -c "print('A'*5000)")"  # 测试长消息
```

## 查看状态

```bash
./fault-handler-controller.sh status
```

## 功能说明

### 1. 幽灵进程清理
- 每5分钟检查一次
- 发现多实例时，保留最新的，终止旧的
- 先优雅终止（5秒等待），后强制终止

### 2. Token 监控
- 每小时检查一次
- Moonshot 耗尽时自动切换智谱
- 发送 Telegram 告警

### 3. 网络故障转移
- 持续检测网络状态
- 离线时缓存消息到本地
- 恢复后自动补发

### 4. 字数限制处理
- 消息 < 4000 字符：直接发送
- 消息 > 4000 字符：自动分段发送
- 网络离线时：缓存到 pending_messages

## 日志位置

```
~/.openclaw/workspace/fault-handlers/
├── ghost-process.log
├── token-monitor.log
├── network.log
└── pending_messages  # 离线缓存
```

## 状态

✅ 脚本已创建并测试
⏳ 等待手动安装 crontab
