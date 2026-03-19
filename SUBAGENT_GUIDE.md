# Subagent 使用指南

## 什么是 Subagent

Subagent 是 OpenClaw 的长期运行代理，可以：
- 在后台独立执行任务
- 不阻塞主会话
- 完成后自动通知
- 支持超时和并行

## 使用场景

### 场景 1：长时间任务
```bash
# 代码审查（可能需要30分钟）
openclaw subagent spawn \
  --task "审查 openclaw 仓库最近一周的 PR，总结变更和影响" \
  --timeout 1800
```

### 场景 2：监控任务
```bash
# 持续监控（后台运行）
openclaw subagent spawn \
  --task "监控 ~/.openclaw/cron-logs/ 目录，有新内容时发送摘要" \
  --background
```

### 场景 3：并行处理
```bash
# 同时分析多个文件
for file in *.md; do
  openclaw subagent spawn --task "分析 $file 并提取关键信息"
done
```

## 状态检查

```bash
# 查看运行中的 subagent
openclaw subagent list

# 查看特定 subagent 日志
openclaw subagent logs <id>

# 终止 subagent
openclaw subagent kill <id>
```

## 当前状态
✅ 功能可用，等待业务需求触发
