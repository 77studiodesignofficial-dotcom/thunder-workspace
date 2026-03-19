#!/bin/bash
# install-crontab.sh - 自动安装 Thunder crontab

echo "=== Thunder Crontab 自动安装脚本 ==="
echo ""

# 1. 备份现有 crontab
echo "1. 备份现有 crontab..."
crontab -l > ~/.crontab.backup.$(date +%Y%m%d%H%M) 2>/dev/null
echo "   ✅ 已备份到 ~/.crontab.backup.$(date +%Y%m%d%H%M)"
echo ""

# 2. 准备新的 crontab 内容
echo "2. 准备 crontab 内容..."
cat > /tmp/thunder-crontab.tmp << 'EOF'
# ============================================
# Thunder 运维系统定时任务
# 安装时间: $(date)
# ============================================

# 故障处理器 - 幽灵进程清理（每5分钟）
*/5 * * * * $HOME/.openclaw/workspace/fault-handler-controller.sh ghost >> $HOME/.openclaw/workspace/fault-handlers/cron.log 2>&1

# 故障处理器 - Token监控（每小时）
0 * * * * $HOME/.openclaw/workspace/fault-handler-controller.sh token >> $HOME/.openclaw/workspace/fault-handlers/cron.log 2>&1

# 故障处理器 - 网络检测（每分钟）
* * * * * $HOME/.openclaw/workspace/fault-handler-controller.sh network >> $HOME/.openclaw/workspace/fault-handlers/cron.log 2>&1

# 优化版日报（每天9:00）
0 9 * * * $HOME/.openclaw/workspace/optimized-daily-briefing.sh

# 周报（每周日20:00）
0 20 * * 0 $HOME/.openclaw/workspace/weekly-report.sh

# ============================================
EOF

echo "   ✅ 内容已准备"
echo ""

# 3. 添加到现有 crontab（保留已有任务）
echo "3. 安装到 crontab..."
(crontab -l 2>/dev/null; cat /tmp/thunder-crontab.tmp) | crontab -
echo "   ✅ 已安装"
echo ""

# 4. 验证
echo "4. 验证安装结果..."
echo "   当前 crontab 内容:"
echo "   ---"
crontab -l | grep -E "(Thunder|ghost|token|network|briefing|weekly)" | head -10
echo "   ---"
echo ""

# 5. 清理临时文件
rm /tmp/thunder-crontab.tmp

echo "✅ 安装完成！"
echo ""
echo "Thunder 运维系统将在以下时间自动运行:"
echo "  • 每5分钟: 幽灵进程清理"
echo "  • 每小时: Token监控"
echo "  • 每分钟: 网络检测"
echo "  • 每天9:00: 优化版日报"
echo "  • 每周日20:00: 周报"
