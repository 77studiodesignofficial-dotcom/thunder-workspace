# 掉线问题专项分析与解决方案

## 问题定性：掉线 vs 响应延迟

| 问题类型 | 现象 | 之前机制是否适用 |
|---------|------|----------------|
| **响应延迟** | 收到消息，但回复慢（27分钟） | ✅ 超时机制有效 |
| **掉线** | 完全无响应，会话中断 | ❌ 需要新机制 |

**结论**：之前建立的运维机制只解决了"慢"，没解决"断"。

---

## 掉线的根本原因分析

### OpenClaw 架构理解

```
┌─────────────────────────────────────────────────────────┐
│                    掉线可能位置                          │
├─────────────────────────────────────────────────────────┤
│  1. Gateway 层（最可能）                                │
│     • 守护进程崩溃                                      │
│     • 内存泄漏导致重启                                  │
│     • 长时间无活动断开                                  │
│                                                         │
│  2. 网络层                                              │
│     • 网络波动                                          │
│     • Telegram 连接中断                                 │
│     • 防火墙/代理问题                                   │
│                                                         │
│  3. 认证层                                              │
│     • Token 过期                                        │
│     • 会话超时                                          │
│                                                         │
│  4. 系统层                                              │
│     • 系统休眠                                          │
│     • 资源耗尽（OOM）                                   │
└─────────────────────────────────────────────────────────┘
```

### 最可能原因：Gateway 会话超时

**OpenClaw Gateway 默认行为**:
- 如果长时间（可能是几小时）没有消息活动
- Gateway 可能会关闭空闲会话
- 这就是"掉线"的本质

**验证方法**:
```bash
# 检查 Gateway 日志
openclaw gateway logs

# 检查会话状态
openclaw session list
```

---

## 解决方案：双重保障机制

### 第一层：心跳保活（预防掉线）

**原理**: 定期发送轻量级消息，保持会话活跃

**实现**:
```bash
# 创建心跳脚本
#!/bin/bash
# heartbeat.sh - 每30分钟发送一次心跳

HEARTBEAT_FILE="$HOME/.openclaw/.heartbeat"
LAST_HEARTBEAT=$(cat "$HEARTBEAT_FILE" 2>/dev/null || echo 0)
NOW=$(date +%s)
DIFF=$((NOW - LAST_HEARTBEAT))

# 如果超过30分钟没有心跳，发送一个
if [ $DIFF -gt 1800 ]; then
    # 通过 Telegram Bot 发送隐形心跳
    # 或者写入文件让 Cron 任务感知
    echo $NOW > "$HEARTBEAT_FILE"
fi
```

**问题**: 需要外部触发器（如 Cron），但 Cron 本身也可能受 Gateway 状态影响

### 第二层：掉线自动检测与恢复

**更可靠的方案：双向心跳**

```
Boss 端                    Thunder 端
   │                           │
   │◄──── 定期发送心跳 ────────┤
   │                           │
   │──── 确认收到 ────────────►│
   │                           │
   │◄──── 超过X分钟无心跳 ────┤
   │                           │
   │──── 判断为掉线 ─────────►│
   │                           │
   │◄──── 自动重启/通知 ──────┤
```

**但问题是**: 如果 Thunder 掉线，谁来执行恢复？

### 第三层：外部监控（最可靠）

**需要外部系统监控 OpenClaw 状态**:

```bash
# 系统级监控脚本（由 macOS 定时任务执行）
# 独立于 OpenClaw，即使 Gateway 崩溃也能运行

#!/bin/bash
# /Users/titen/.openclaw/monitor.sh

if ! pgrep -f "openclaw-gateway" > /dev/null; then
    # Gateway 崩溃，尝试重启
    openclaw gateway restart
    
    # 发送告警
    curl -X POST "https://api.telegram.org/bot.../sendMessage" \
        -d "chat_id=..." \
        -d "text=⚠️ Thunder 检测到掉线，已尝试自动重启"
fi
```

**激活方式**:
```bash
# 添加到 crontab（系统级，独立于 OpenClaw）
*/5 * * * * /Users/titen/.openclaw/monitor.sh
```

---

## 立即可执行的方案

### 方案A：最小可行方案（推荐先实施）

**步骤1：创建掉线检测脚本**