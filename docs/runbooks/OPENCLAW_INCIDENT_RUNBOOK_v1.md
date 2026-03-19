# OpenClaw Incident Runbook v1

Updated: 2026-03-10

## Purpose
Provide a repeatable first-response playbook for common OpenClaw failures.

---

## 1. First response sequence
When Boss reports that OpenClaw is slow, silent, or broken:

1. ACK immediately
   - 收到，开始排查。
2. Treat maintenance as isolated work by default.
3. Run baseline healthcheck:
   - `bin/openclaw-healthcheck.sh`
4. Classify the issue:
   - Gateway / channel / model / session / proxy
5. Report a short progress update with:
   - current state
   - strongest evidence
   - next action

---

## 2. Gateway failure
### Symptoms
- no replies
- `openclaw gateway status` not running
- RPC probe not ok

### Checks
- `openclaw gateway status --no-color`
- `launchctl print gui/$(id -u)/ai.openclaw.gateway`
- recent gateway log tail

### Initial action
- verify config path
- verify launch agent state
- restart only after confirming evidence

### Success criteria
- Runtime: running
- RPC probe: ok

---

## 3. Telegram channel failure
### Symptoms
- bot silent though gateway is up
- channel status not running
- probe problems / polling issues / 409 conflict

### Checks
- `openclaw channels status --no-color`
- `openclaw health --json`
- gateway log search for telegram / conflict / polling

### Initial action
- confirm token/config loaded
- confirm only one polling consumer is active
- restart channel/gateway if needed after evidence capture

### Success criteria
- Telegram status shows running + polling
- probe ok
- Boss can receive/send test message

---

## 4. Model/provider failure
### Symptoms
- timeout
- server_error
- failover error
- long silence during runs

### Checks
- `bin/openclaw-healthcheck.sh`
- gateway logs for `timed out`, `server_error`, `FailoverError`
- verify proxy chain and provider reachability

### Initial action
- identify whether failure is main model only or shared
- verify fallback viability
- send degraded-status update instead of going silent

### Success criteria
- at least one provider path is usable
- user receives visible status updates

---

## 5. Session lock / context bloat
### Symptoms
- `session file locked`
- long-running or stuck replies
- repeated maintenance detail in main chat

### Checks
- inspect recent logs
- inspect active session pattern
- confirm whether the task should be split out

### Initial action
- move work to isolated maintenance context
- summarize back to Boss instead of copying raw logs
- reset or rotate the affected task path if needed

### Success criteria
- main session stays concise
- lock/conflict symptoms stop recurring

---

## 6. Proxy / network chain failure
### Symptoms
- provider unreachable
- HTTP timeout
- gateway healthy but model calls fail

### Checks
- launchctl state for pproxy
- upstream proxy availability
- simple curl probe to provider endpoints

### Initial action
- identify which hop failed
- verify environment inheritance for gateway
- restore the minimum viable path before broader changes

### Success criteria
- provider reachability restored
- gateway can use proxy path successfully

---

## 7. Reporting format
When reporting to Boss, prefer this structure:
- State
- Evidence
- Action
- Conclusion

Example:
- 状态：Gateway 在线，但模型链路异常。
- 证据：healthcheck 出现 provider timeout，Telegram polling 正常。
- 动作：正在检查代理链和 fallback 可用性。
- 结论：当前不是网关故障，属于模型侧降级问题。
