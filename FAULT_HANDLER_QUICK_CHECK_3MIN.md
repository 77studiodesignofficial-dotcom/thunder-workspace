# FAULT_HANDLER_QUICK_CHECK_3MIN

> 目的：用 3 分钟快速确认 fault handlers 在观察期内是否稳定、可解释、无误伤迹象。

## 1. 看运行模式（30 秒）
执行：
```bash
~/workspace/fault-handler-controller.sh status
```
确认：
- `SAFE_MODE=1`
- `DRY_RUN=0`
- 能正常看到 ghost / network / token / audit 日志摘要

如果不满足：
- 先不要继续放开任何自动动作
- 先查 `~/.openclaw/fault-handlers.env`

---

## 2. 看高风险日志（30 秒）
执行：
```bash
tail -20 ~/.openclaw/fault-handlers/audit-critical.log
```
重点看：
- 是否出现新的 `pre_kill`
- 是否出现异常 `detect`
- 是否有不认识的高风险动作

理想状态：
- 只有少量可解释的状态切换记录
- 没有新的误杀/异常终止迹象

---

## 3. 看 cron 汇总日志（30 秒）
执行：
```bash
tail -20 ~/.openclaw/fault-handlers/cron.log
```
重点看：
- 三个处理器是否仍在正常触发
- 是否有明显报错
- 是否有脚本路径失效/权限问题

理想状态：
- cron 正常触发
- 无连续报错

---

## 4. 看三个处理器状态（60 秒）
执行：
```bash
tail -10 ~/.openclaw/fault-handlers/ghost-process.log

tail -10 ~/.openclaw/fault-handlers/network.log

tail -10 ~/.openclaw/fault-handlers/token-monitor.log
```

分别确认：

### ghost-process
- 大多数时候是 `count=1`
- 没有进入危险 kill 动作

### network
- 有网络波动时能记录
- 没有连带触发激进行为

### token-monitor
- 能正常记录 provider 探测结果
- 没有异常切换动作

---

## 5. 最后做一句判断（30 秒）
问自己 3 个问题：
1. 有没有新的误伤主 Gateway 迹象？
2. 有没有无法解释的高风险动作？
3. fault handlers 当前是否仍在保守模式稳定运行？

如果答案是：
- **没有 / 没有 / 是**
  - 结论：继续观察，维持当前配置
- 只要有任一项异常
  - 结论：暂停进一步放开，先排查再动

---

## 推荐巡检频率
- 观察期前 3 天：每天 1 次
- 如果期间出现波动：当天追加 1 次
- 连续平稳后：降为按需检查

---

## 当前默认结论模板
可直接复用：

- 巡检完成：fault handlers 仍处于 `SAFE_MODE=1`、`DRY_RUN=0`，三类处理器均正常触发，未见新的误杀或异常高风险动作，继续维持当前观察配置。

如异常时：
- 巡检完成：发现新的异常记录，当前不建议放开自动动作，建议先做定向排查。
