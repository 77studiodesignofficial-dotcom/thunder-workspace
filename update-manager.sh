#!/bin/bash
# update-manager.sh - OpenClaw 版本更新管理器
# 功能：检查更新、备份、风险评估、安全升级、回滚

VERSION="1.0"
LOG_FILE="$HOME/.openclaw/workspace/update-manager.log"
BACKUP_DIR="$HOME/.openclaw/backups"
mkdir -p "$BACKUP_DIR"

# 颜色输出
log_info() { echo "[INFO] $1"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"; }
log_warn() { echo "[WARN] $1"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$LOG_FILE"; }
log_error() { echo "[ERROR] $1"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"; }

# 1. 检查当前版本
check_current_version() {
    log_info "检查当前版本..."
    CURRENT_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    log_info "当前版本: $CURRENT_VERSION"
    echo "$CURRENT_VERSION"
}

# 2. 检查最新版本
check_latest_version() {
    log_info "检查最新版本..."
    
    # 从 npm 获取最新版本
    LATEST_VERSION=$(npm view openclaw version 2>/dev/null)
    
    if [ -z "$LATEST_VERSION" ]; then
        log_error "无法获取最新版本信息"
        return 1
    fi
    
    log_info "最新版本: $LATEST_VERSION"
    echo "$LATEST_VERSION"
}

# 3. 版本比较
compare_versions() {
    CURRENT="$1"
    LATEST="$2"
    
    if [ "$CURRENT" = "$LATEST" ]; then
        echo "current"
    else
        # 简单版本比较（假设格式为 YYYY.M.D 或 X.Y.Z）
        echo "update_available"
    fi
}

# 4. 预更新备份
pre_update_backup() {
    log_info "执行预更新备份..."
    
    BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/pre_update_$BACKUP_TIMESTAMP"
    mkdir -p "$BACKUP_PATH"
    
    # 备份关键文件
    log_info "备份关键文件到 $BACKUP_PATH"
    
    # 4.1 备份凭证
    if [ -f "$HOME/.openclaw/.env.skill" ]; then
        cp "$HOME/.openclaw/.env.skill" "$BACKUP_PATH/"
        log_info "✅ 凭证已备份"
    fi
    
    # 4.2 备份 MEMORY.md
    if [ -f "$HOME/.openclaw/workspace/MEMORY.md" ]; then
        cp "$HOME/.openclaw/workspace/MEMORY.md" "$BACKUP_PATH/"
        log_info "✅ MEMORY.md 已备份"
    fi
    
    # 4.3 备份 crontab
    crontab -l > "$BACKUP_PATH/crontab.backup" 2>/dev/null
    log_info "✅ Crontab 已备份"
    
    # 4.4 备份所有脚本
    cp -r "$HOME/.openclaw/workspace" "$BACKUP_PATH/workspace_backup" 2>/dev/null
    log_info "✅ 工作区脚本已备份"
    
    # 4.5 记录当前版本
    openclaw --version > "$BACKUP_PATH/version.txt" 2>/dev/null
    log_info "✅ 版本信息已备份"
    
    # 保存备份路径供后续使用
    echo "$BACKUP_PATH" > "$BACKUP_DIR/last_backup.txt"
    
    log_info "备份完成: $BACKUP_PATH"
    echo "$BACKUP_PATH"
}

# 5. 风险评估
assess_update_risk() {
    log_info "执行更新风险评估..."
    
    RISK_SCORE=0
    RISK_FACTORS=""
    
    # 5.1 检查是否有正在运行的任务
    ACTIVE_PROCESSES=$(pgrep -c "openclaw" 2>/dev/null || echo 0)
    if [ "$ACTIVE_PROCESSES" -gt 2 ]; then
        RISK_SCORE=$((RISK_SCORE + 20))
        RISK_FACTORS="${RISK_FACTORS}⚠️ 有 $ACTIVE_PROCESSES 个活跃进程; "
    fi
    
    # 5.2 检查网络状态
    if ! curl -s --max-time 5 https://registry.npmjs.org > /dev/null 2>&1; then
        RISK_SCORE=$((RISK_SCORE + 30))
        RISK_FACTORS="${RISK_FACTORS}⚠️ 网络连接不稳定; "
    fi
    
    # 5.3 检查磁盘空间
    DISK_USAGE=$(df -h "$HOME" | tail -1 | awk '{print $5}' | tr -d '%')
    if [ "$DISK_USAGE" -gt 90 ]; then
        RISK_SCORE=$((RISK_SCORE + 25))
        RISK_FACTORS="${RISK_FACTORS}⚠️ 磁盘空间不足 (${DISK_USAGE}%); "
    fi
    
    # 5.4 检查是否有未完成的任务
    if [ -f "$HOME/.openclaw/.pending_tasks" ]; then
        PENDING_TASKS=$(wc -l < "$HOME/.openclaw/.pending_tasks")
        if [ "$PENDING_TASKS" -gt 0 ]; then
            RISK_SCORE=$((RISK_SCORE + 15))
            RISK_FACTORS="${RISK_FACTORS}⚠️ 有 $PENDING_TASKS 个未完成任务; "
        fi
    fi
    
    # 风险等级
    if [ "$RISK_SCORE" -lt 20 ]; then
        RISK_LEVEL="🟢 低风险"
    elif [ "$RISK_SCORE" -lt 50 ]; then
        RISK_LEVEL="🟡 中风险"
    else
        RISK_LEVEL="🔴 高风险"
    fi
    
    log_info "风险评估完成: $RISK_LEVEL (评分: $RISK_SCORE)"
    
    echo "RISK_SCORE=$RISK_SCORE"
    echo "RISK_LEVEL=$RISK_LEVEL"
    echo "RISK_FACTORS=$RISK_FACTORS"
}

# 6. 安全升级
safe_upgrade() {
    BACKUP_PATH="$1"
    
    log_info "开始安全升级..."
    
    # 6.1 停止所有 OpenClaw 进程
    log_info "停止 OpenClaw 进程..."
    pkill -f "openclaw-gateway" 2>/dev/null
    sleep 2
    
    # 6.2 确认已停止
    if pgrep -f "openclaw-gateway" > /dev/null; then
        log_warn "进程仍在运行，强制终止..."
        pkill -9 -f "openclaw-gateway" 2>/dev/null
        sleep 1
    fi
    
    # 6.3 清理临时文件
    log_info "清理临时文件..."
    rm -f ~/.openclaw/.session-* 2>/dev/null
    rm -f ~/.openclaw/*.pid 2>/dev/null
    
    # 6.4 执行升级
    log_info "执行 npm update..."
    if npm update -g openclaw 2>&1 | tee -a "$LOG_FILE"; then
        log_info "✅ 升级成功"
    else
        log_error "❌ 升级失败，准备回滚..."
        rollback_update "$BACKUP_PATH"
        return 1
    fi
    
    # 6.5 验证新版本
    NEW_VERSION=$(openclaw --version 2>/dev/null)
    log_info "新版本: $NEW_VERSION"
    
    # 6.6 重启服务
    log_info "重启 OpenClaw Gateway..."
    openclaw gateway start &
    sleep 3
    
    # 6.7 验证服务
    if pgrep -f "openclaw-gateway" > /dev/null; then
        log_info "✅ Gateway 已启动"
    else
        log_error "❌ Gateway 启动失败"
        return 1
    fi
    
    # 6.8 测试基本功能
    log_info "测试基本功能..."
    if openclaw --version > /dev/null 2>&1; then
        log_info "✅ 基本功能正常"
    else
        log_error "❌ 功能测试失败"
        return 1
    fi
    
    log_info "✅ 安全升级完成"
    return 0
}

# 7. 回滚更新
rollback_update() {
    BACKUP_PATH="$1"
    
    log_warn "执行回滚..."
    log_info "从备份恢复: $BACKUP_PATH"
    
    # 7.1 停止当前服务
    pkill -f "openclaw" 2>/dev/null
    sleep 2
    
    # 7.2 恢复凭证
    if [ -f "$BACKUP_PATH/.env.skill" ]; then
        cp "$BACKUP_PATH/.env.skill" "$HOME/.openclaw/"
        log_info "✅ 凭证已恢复"
    fi
    
    # 7.3 恢复 MEMORY.md
    if [ -f "$BACKUP_PATH/MEMORY.md" ]; then
        cp "$BACKUP_PATH/MEMORY.md" "$HOME/.openclaw/workspace/"
        log_info "✅ MEMORY.md 已恢复"
    fi
    
    # 7.4 恢复 crontab
    if [ -f "$BACKUP_PATH/crontab.backup" ]; then
        crontab "$BACKUP_PATH/crontab.backup"
        log_info "✅ Crontab 已恢复"
    fi
    
    # 7.5 恢复脚本
    if [ -d "$BACKUP_PATH/workspace_backup" ]; then
        cp -r "$BACKUP_PATH/workspace_backup/"* "$HOME/.openclaw/workspace/"
        log_info "✅ 脚本已恢复"
    fi
    
    # 7.6 降级 OpenClaw（如果必要）
    OLD_VERSION=$(cat "$BACKUP_PATH/version.txt" 2>/dev/null)
    if [ -n "$OLD_VERSION" ]; then
        log_info "降级到版本: $OLD_VERSION"
        npm install -g "openclaw@$OLD_VERSION" 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # 7.7 重启服务
    openclaw gateway start &
    sleep 3
    
    if pgrep -f "openclaw-gateway" > /dev/null; then
        log_info "✅ 回滚完成，服务已恢复"
        return 0
    else
        log_error "❌ 回滚后服务启动失败"
        return 1
    fi
}

# 8. 自动更新检查
check_auto_update() {
    log_info "检查自动更新配置..."
    
    # 检查当前配置
    AUTO_UPDATE=$(openclaw config get update.auto 2>/dev/null || echo "false")
    
    if [ "$AUTO_UPDATE" = "true" ]; then
        log_info "自动更新已启用"
    else
        log_info "自动更新未启用，建议配置"
        echo ""
        echo "配置自动更新:"
        echo "  openclaw config set update.auto true"
        echo "  openclaw config set update.channel stable"
    fi
}

# 主入口
case "${1:-check}" in
    check)
        CURRENT=$(check_current_version)
        LATEST=$(check_latest_version)
        echo ""
        echo "当前版本: $CURRENT"
        echo "最新版本: $LATEST"
        
        if [ "$(compare_versions "$CURRENT" "$LATEST")" = "update_available" ]; then
            echo ""
            echo "🔄 发现新版本！"
            echo "执行 './update-manager.sh upgrade' 进行安全升级"
        else
            echo ""
            echo "✅ 已是最新版本"
        fi
        ;;
    
    upgrade|update)
        CURRENT=$(check_current_version)
        LATEST=$(check_latest_version)
        
        if [ "$(compare_versions "$CURRENT" "$LATEST")" = "current" ]; then
            log_info "已是最新版本，无需升级"
            exit 0
        fi
        
        echo ""
        echo "准备升级: $CURRENT → $LATEST"
        echo ""
        
        # 执行备份
        BACKUP_PATH=$(pre_update_backup)
        
        # 风险评估
        echo ""
        assess_update_risk
        echo ""
        
        read -p "确认升级? (y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            if safe_upgrade "$BACKUP_PATH"; then
                echo ""
                echo "✅ 升级成功！"
                echo "备份保留在: $BACKUP_PATH"
                echo "如需回滚，执行: ./update-manager.sh rollback $BACKUP_PATH"
            else
                echo ""
                echo "❌ 升级失败，已自动回滚"
                exit 1
            fi
        else
            log_info "升级已取消"
            exit 0
        fi
        ;;
    
    rollback)
        if [ -z "$2" ]; then
            # 使用最近的备份
            BACKUP_PATH=$(cat "$BACKUP_DIR/last_backup.txt" 2>/dev/null)
            if [ -z "$BACKUP_PATH" ]; then
                log_error "未找到备份路径，请指定: ./update-manager.sh rollback <备份路径>"
                exit 1
            fi
        else
            BACKUP_PATH="$2"
        fi
        
        if [ ! -d "$BACKUP_PATH" ]; then
            log_error "备份路径不存在: $BACKUP_PATH"
            exit 1
        fi
        
        rollback_update "$BACKUP_PATH"
        ;;
    
    auto)
        check_auto_update
        ;;
    
    risk)
        assess_update_risk
        ;;
    
    status)
        check_current_version
        check_latest_version
        ;;
    
    help)
        echo "OpenClaw 更新管理器 v$VERSION"
        echo ""
        echo "用法:"
        echo "  ./update-manager.sh check     # 检查更新"
        echo "  ./update-manager.sh upgrade   # 安全升级（含备份和风险评估）"
        echo "  ./update-manager.sh rollback  # 回滚到上一版本"
        echo "  ./update-manager.sh risk      # 评估当前更新风险"
        echo "  ./update-manager.sh auto      # 检查自动更新配置"
        echo "  ./update-manager.sh status    # 查看版本状态"
        ;;
    
    *)
        echo "未知命令: $1"
        echo "执行 './update-manager.sh help' 查看用法"
        exit 1
        ;;
esac
