# OpenClaw Failure / Degradation Policy

Updated: 2026-03-10

## Goal
Avoid silent failure. When the system is slow, degraded, or partially unavailable, Boss must still receive a clear status signal.

## Response policy

### 1. Immediate ACK
For delegated work, acknowledge quickly.
Recommended style:
- 收到，开始处理。
- 收到，正在排查。
- 收到，已进入隔离维护流程。

### 2. Progress update threshold
If meaningful work is still running:
- At ~30s: send a short progress update.
- At ~60s: explicitly report degradation or blocking dependency.

### 3. Failure visibility
If the main model / provider / network path fails:
- Do not go silent.
- Send a concise degraded-status reply.
- Mention whether retry / fallback / manual intervention is in progress.

Recommended style:
- 收到，主链路异常，正在切换备用路径。
- 收到，系统仍在线，但模型服务异常；我继续降级处理并回报结果。
- 收到，本次任务失败，原因是上游模型服务错误；我可以继续重试或改走备用方案。

### 4. Maintenance isolation
All OpenClaw maintenance / troubleshooting / inspection / repair-validation tasks should default to isolated execution so the main session remains clean.

### 5. Business-level health definition
The system is healthy only if all are true:
- Gateway RPC is reachable
- Telegram channel is running
- Telegram probe is OK
- Main model path is reachable
- At least one fallback path is viable
- State dir permissions remain private
- No active evidence of sustained session-lock / timeout bursts

### 6. Escalation rule
If repeated failures continue after fallback attempts:
- Report clearly that the task is blocked
- Stop pretending progress is normal
- Ask for approval before risky remediation

## Operational use
Use `bin/openclaw-healthcheck.sh` as the baseline read-only inspection entrypoint before or during maintenance.
