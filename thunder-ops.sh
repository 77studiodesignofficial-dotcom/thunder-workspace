#!/bin/bash
# thunder-ops.sh - Thunder 运维监控脚本
# 用于健康检查、超时控制和故障恢复

# 配置
MAX_EXEC_TIME=60  # 最大执行时间（秒）
BROWSER_TIMEOUT=15000  # 浏览器操作超时（毫秒）
HEALTH_LOG="$HOME/.openclaw/health-check.log"

# 颜色输出
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

# 健康检查
health_check() {
    echo "=== Thunder 健康检查 $(date) ===" | tee -a "$HEALTH_LOG"
    
    # 检查 1: OpenClaw 状态
    echo -n "OpenClaw 状态: " | tee -a "$HEALTH_LOG"
    if openclaw --version &>/dev/null; then
        version=$(openclaw --version)
        green "✅ $version" | tee -a "$HEALTH_LOG"
    else
        red "❌ 异常" | tee -a "$HEALTH_LOG"
    fi
    
    # 检查 2: 凭证系统
    echo -n "凭证系统: " | tee -a "$HEALTH_LOG"
    if [[ -f "$HOME/.openclaw/.env.skill" ]]; then
        key_count=$(grep -c "API_KEY\|TOKEN" "$HOME/.openclaw/.env.skill" 2>/dev/null || echo 0)
        green "✅ $key_count 个凭证已配置" | tee -a "$HEALTH_LOG"
    else
        yellow "⚠️  未配置" | tee -a "$HEALTH_LOG"
    fi
    
    # 检查 3: 僵尸进程
    echo -n "后台进程: " | tee -a "$HEALTH_LOG"
    zombie_count=$(ps aux | grep -c "openclaw\|thunder" 2>/dev/null || echo 0)
    if [[ $zombie_count -gt 5 ]]; then
        yellow "⚠️  $zombie_count 个进程（建议清理）" | tee -a "$HEALTH_LOG"
    else
        green "✅ 正常 ($zombie_count)" | tee -a "$HEALTH_LOG"
    fi
    
    # 检查 4: 网络连接
    echo -n "网络状态: " | tee -a "$HEALTH_LOG"
    if curl -s --max-time 5 https://api.telegram.org >/dev/null 2>&1; then
        green "✅ 正常" | tee -a "$HEALTH_LOG"
    else
        red "❌ 异常" | tee -a "$HEALTH_LOG"
    fi
    
    echo "" | tee -a "$HEALTH_LOG"
}

# 清理僵尸进程
cleanup() {
    echo "🧹 清理僵尸进程..."
    
    # 查找超时进程
    ps aux | grep -E "(browser|exec).*openclaw" | grep -v grep | while read line; do
        pid=$(echo "$line" | awk '{print $2}')
        time=$(echo "$line" | awk '{print $10}')
        
        # 如果运行超过 5 分钟，终止
        if [[ "$time" =~ ^[0-9]+:[0-9]+:[0-9]+$ ]]; then
            echo "  终止长时间运行进程: $pid"
            kill "$pid" 2>/dev/null || true
        fi
    done
    
    green "✅ 清理完成"
}

# 带超时的安全执行
safe_exec() {
    local cmd="$1"
    local timeout_sec="${2:-$MAX_EXEC_TIME}"
    
    echo "⏱️  执行命令（超时: ${timeout_sec}s）: $cmd"
    
    timeout "$timeout_sec" bash -c "$cmd" 2>&1
    local exit_code=$?
    
    if [[ $exit_code -eq 124 ]]; then
        red "⚠️  命令超时（${timeout_sec}秒）"
        return 1
    elif [[ $exit_code -ne 0 ]]; then
        red "❌ 命令失败（退出码: $exit_code）"
        return 1
    else
        green "✅ 命令成功"
        return 0
    fi
}

# 主入口
case "$1" in
    health)
        health_check
        ;;
    cleanup)
        cleanup
        ;;
    exec)
        shift
        safe_exec "$@"
        ;;
    monitor)
        # 后台监控模式
        while true; do
            health_check >> "$HEALTH_LOG" 2>&1
            sleep 300  # 每 5 分钟检查一次
        done
        ;;
    *)
        echo "Thunder 运维工具"
        echo ""
        echo "用法:"
        echo "  ./thunder-ops.sh health          # 健康检查"
        echo "  ./thunder-ops.sh cleanup         # 清理僵尸进程"
        echo "  ./thunder-ops.sh exec '命令' 60  # 带超时的安全执行"
        echo "  ./thunder-ops.sh monitor         # 后台监控模式"
        ;;
esac
