# OpenClaw Governance Plan

Updated: 2026-03-10

## Default governance rules

### Trust boundary
- OpenClaw is operated as a private executive assistant for Boss only.
- Telegram direct-message access must be restricted to Boss or an explicit allowlist.
- Open access (`dmPolicy=open` with wildcard allowFrom) is not allowed as a steady-state configuration.

### Execution boundary
- All OpenClaw maintenance / troubleshooting / inspection / repair-validation tasks default to isolated execution.
- Main chat should stay focused on delegation and decisions, not accumulate deep maintenance context.

### Stability rules
- Prefer system fixes over repeated firefighting.
- Health must be judged at the business level, not only by process liveness.
- Failures should degrade visibly with ACK / progress / failure reporting, not go silent.

### Security hygiene
- The OpenClaw state directory should remain private to the local user.
- Changes to trust boundaries, channel access, proxies, and service configuration should be backed up before modification.
