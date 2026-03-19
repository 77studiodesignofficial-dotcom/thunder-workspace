# Thunder 故障预案设计文档

## 故障1：Token 消耗完了

### 检测机制
```bash
# 监控脚本：检查 API 额度
#!/bin/bash
# token-monitor.sh

MOONSHOT_USAGE=$(curl -s https://api.moonshot.cn/v1/usage \
  -H "Authorization: Bearer $MOONSHOT_API_KEY" | jq '.used_percent')

if [ "$MOONSHOT_USAGE" -gt 80 ]; then
  # 发送预警
  ./telegram-bot.sh "⚠️ Moonshot Token 已使用 ${MOONSHOT_USAGE}%"
fi

if [ "$MOONSHOT_USAGE" -gt 95 ]; then
  # 切换到备用模型
  echo "BACKUP_MODEL=zhipu" > ~/.openclaw/.fallback
  ./telegram-bot.sh "🔴 Moonshot Token 耗尽，已切换至智谱 GLM"
fi
```

### 预警阈值
| 使用率 | 动作 |
|--------|------|
| 80% | 发送 Telegram 预警 |
| 90% | 启用省流模式（简化回复）|
| 95% | 自动切换备用模型 |
| 100% | 仅使用免费模型（GLM-4-Flash）|

### 降级策略
```
主模型不可用 → 自动切换至备用
├── Moonshot 耗尽 → 智谱 GLM
├── 智谱耗尽 → 其他备用 API
└── 全部耗尽 → 纯本地工具（无 AI）
```

---

## 故障2：网络掉线了

### 检测机制
```bash
# network-check.sh

if ! curl -s --max-time 5 https://api.telegram.org > /dev/null; then
  echo "NETWORK_DOWN" > ~/.openclaw/.network_status
  
  # 本地记录待发送消息
  echo "[$(date)] 消息内容..." >> ~/.openclaw/.pending_messages
  
  # 尝试本地处理（无需网络）
  ./local-mode.sh
fi
```

### 离线模式功能
```
网络正常时：
├── AI 对话（Moonshot/智谱）
├── 网络搜索
└── 远程 API 调用

网络断开时（降级）：
├── ✅ 本地文件操作
├── ✅ 本地代码执行
├── ✅ 缓存数据查询
├── ❌ AI 对话（不可用）
└── ❌ 网络搜索（不可用）
```

### 自动恢复
```bash
# 后台监控进程
while true; do
  if curl -s --max-time 5 https://api.telegram.org > /dev/null; then
    # 网络恢复，发送缓存的消息
    if [ -f ~/.openclaw/.pending_messages ]; then
      ./telegram-bot.sh "🌐 网络已恢复，补发离线期间消息："
      cat ~/.openclaw/.pending_messages | ./telegram-bot.sh
      rm ~/.openclaw/.pending_messages
    fi
  fi
  sleep 30
done
```

---

## 故障3：Telegram 文本字数限制

### Telegram 限制
- 单条消息：**4096 字符**
- 超过则发送失败

### 解决方案：自动分段
```bash
#!/bin/bash
# smart-send.sh

MESSAGE="$1"
MAX_LENGTH=4000  # 留余量

if [ "${#MESSAGE}" -le "$MAX_LENGTH" ]; then
  # 直接发送
  curl -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${MESSAGE}"
else
  # 分段发送
  echo "$MESSAGE" | fold -s -w $MAX_LENGTH | while read -r chunk; do
    curl -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
      -d "chat_id=${CHAT_ID}" \
      -d "text=${chunk}...(续)"
    sleep 0.5  # 避免频率限制
  done
  
  # 或发送文件
  echo "$MESSAGE" > /tmp/long_message.txt
  curl -X POST "https://api.telegram.org/bot${TOKEN}/sendDocument" \
    -F "chat_id=${CHAT_ID}" \
    -F "document=@/tmp/long_message.txt" \
    -F "caption=消息较长，以文件形式发送"
fi
```

### 智能选择策略
```
消息长度 < 1000 字符 → 正常发送
消息长度 1000-4000 → 分段发送（标记 1/3, 2/3...）
消息长度 > 4000 → 自动转为文件发送
包含代码/表格 → 优先文件发送（保留格式）
```

---

## 故障4：升级导致的"幽灵服务"打架

### 现象
- 升级后旧进程未清理
- 新旧版本同时运行
- 资源冲突，行为异常

### 预防机制：升级前清理
```bash
#!/bin/bash
# safe-upgrade.sh

echo "🧹 升级前清理..."

# 1. 停止所有 OpenClaw 相关进程
pkill -f "openclaw-gateway"
pkill -f "openclaw"
sleep 2

# 2. 确认清理完成
if pgrep -f "openclaw" > /dev/null; then
  echo "⚠️  仍有残留进程，强制终止..."
  pkill -9 -f "openclaw"
fi

# 3. 清理临时文件
rm -f ~/.openclaw/.session-*
rm -f ~/.openclaw/*.pid

# 4. 备份配置
cp ~/.openclaw/.env.skill ~/.openclaw/.env.skill.backup.$(date +%Y%m%d)

# 5. 执行升级
echo "⬆️  开始升级..."
npm install -g openclaw@latest

# 6. 验证新版本
openclaw --version

# 7. 重启服务
openclaw gateway start

echo "✅ 升级完成"
```

### 健康检查：进程唯一性
```bash
#!/bin/bash
# process-check.sh

PROCESS_COUNT=$(pgrep -f "openclaw-gateway" | wc -l)

if [ "$PROCESS_COUNT" -gt 1 ]; then
  echo "🚨 检测到 $PROCESS_COUNT 个 Gateway 进程（应该只有1个）"
  
  # 保留最新的，终止其他的
  NEWEST_PID=$(pgrep -f "openclaw-gateway" | tail -1)
  pgrep -f "openclaw-gateway" | grep -v "$NEWEST_PID" | xargs kill -9
  
  ./telegram-bot.sh "⚠️ 检测到幽灵进程，已自动清理"
fi
```

### 启动时自检
```bash
# 在 Thunder 启动时执行

# 检查是否有其他 Thunder 实例运行
if [ -f ~/.openclaw/.thunder.pid ]; then
  OLD_PID=$(cat ~/.openclaw/.thunder.pid)
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "⚠️  已有 Thunder 实例运行 (PID: $OLD_PID)"
    echo "终止旧实例..."
    kill "$OLD_PID"
    sleep 2
  fi
fi

# 记录当前 PID
echo $$ > ~/.openclaw/.thunder.pid
```

---

## 综合监控面板

建议创建一个统一监控脚本：

```bash
#!/bin/bash
# thunder-health-dashboard.sh

echo "=== Thunder 健康监控面板 ==="
echo "时间: $(date)"
echo ""

# 1. Token 状态
echo "💰 Token 状态:"
grep -E "MOONSHOT|ZHIPU" ~/.openclaw/.env.skill | cut -d= -f1

echo ""

# 2. 网络状态  
echo "🌐 网络状态:"
if curl -s --max-time 3 https://api.telegram.org > /dev/null; then
  echo "  ✅ 正常"
else
  echo "  ❌ 断开"
fi

echo ""

# 3. 进程状态
echo "🔧 进程状态:"
echo "  Gateway: $(pgrep -c openclaw-gateway) 个"
echo "  Caffeinate: $(pgrep -c caffeinate) 个"
echo "  Thunder: $(pgrep -c thunder) 个"

echo ""

# 4. 系统资源
echo "💻 系统资源:"
echo "  CPU: $(top -l 1 | grep "CPU usage" | awk '{print $3}')"
echo "  内存: $(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')"

echo ""

# 5. 最后活跃时间
if [ -f ~/.openclaw/.last-active ]; then
  echo "⏱️  最后活跃: $(stat -f %Sm ~/.openclaw/.last-active)"
fi
```

---

## 实施优先级

| 优先级 | 故障 | 实施难度 | 影响 |
|--------|------|---------|------|
| 🔴 高 | Token 耗尽 | 中 | 服务不可用 |
| 🔴 高 | 幽灵进程 | 低 | 服务异常 |
| 🟡 中 | 网络掉线 | 中 | 功能受限 |
| 🟢 低 | 字数限制 | 低 | 体验下降 |

**建议实施顺序**：幽灵进程 → Token 监控 → 网络离线 → 字数限制
