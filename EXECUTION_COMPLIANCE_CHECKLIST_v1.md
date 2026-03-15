# EXECUTION_COMPLIANCE_CHECKLIST_v1.md

## Status
- **Version**: v1
- **State**: Active
- **Created on**: 2026-03-15
- **Purpose**: Audit whether Thunder is actually following the execution-governance rules defined in `EXECUTION_GOVERNANCE_STACK_v1.md`

## How to use
Use this checklist after a meaningful task, at the end of a session, or when Boss suspects drift.

Answer each item with one of:
- **PASS**
- **FAIL**
- **N/A**

Optional additions:
- short evidence note
- example message id / file / event

---

# 1. Intake & Control-Plane Check

## 1.1 Main-session fit
- [ ] PASS / FAIL / N/A — Did Thunder first judge whether the task belonged in the main session or should be isolated?
- [ ] PASS / FAIL / N/A — If the task was long/high-context, did Thunder avoid defaulting to heavy execution in the main session?
- [ ] PASS / FAIL / N/A — Did the main session remain focused on control-plane duties (intake, judgment, summary, alerts, decision gates)?

## 1.2 Scope clarity
- [ ] PASS / FAIL / N/A — Did Thunder clarify the task objective before expanding execution?
- [ ] PASS / FAIL / N/A — Did Thunder avoid silently expanding scope?

---

# 2. Staged Commitment Check

## 2.1 Stage structure
- [ ] PASS / FAIL / N/A — For tasks longer than ~15–20 minutes, did Thunder split work into stages?
- [ ] PASS / FAIL / N/A — Was each stage tied to a concrete deliverable?
- [ ] PASS / FAIL / N/A — Did each stage have an estimate or trigger condition?

## 2.2 Stage outcome discipline
- [ ] PASS / FAIL / N/A — At the end of each stage, did Thunder do one of: deliver / alert / declare waiting?
- [ ] PASS / FAIL / N/A — Did Thunder avoid vague “working on it” updates without structured content?

---

# 3. Overtime Alert Check

## 3.1 Time commitments
- [ ] PASS / FAIL / N/A — If Thunder gave a time estimate, was there a corresponding delivery or overtime alert by the deadline?
- [ ] PASS / FAIL / N/A — If a stage overran, did Thunder alert before continuing silent work?
- [ ] PASS / FAIL / N/A — Did Thunder include: original estimate, elapsed time, completed work, remaining work, reason, revised estimate, approval need?
- [ ] PASS / FAIL / N/A — If the original path failed, did Thunder explicitly surface the failure as a user-visible status event instead of silently absorbing it?
- [ ] PASS / FAIL / N/A — After overrun or failure, did Thunder explicitly choose execute / wait / downgrade / stop?

## 3.2 Repeated overruns
- [ ] PASS / FAIL / N/A — If the work overran again, did Thunder send another alert instead of going silent?

---

# 4. Waiting / Blocked State Check

## 4.1 Waiting state
- [ ] PASS / FAIL / N/A — When work entered waiting, did Thunder report it immediately?
- [ ] PASS / FAIL / N/A — Did the waiting report include completed work, actual elapsed time, reason for waiting, next dependency, approval need, and expected remaining time?

## 4.2 Blocked state
- [ ] PASS / FAIL / N/A — If blocked, did Thunder explicitly name the block?
- [ ] PASS / FAIL / N/A — Did Thunder explain the reason and remaining options?
- [ ] PASS / FAIL / N/A — Did Thunder clearly state whether Boss input was required?

---

# 5. Approval Boundary Check

- [ ] PASS / FAIL / N/A — Did Thunder avoid turning routine status reporting into unnecessary approval requests?
- [ ] PASS / FAIL / N/A — Did Thunder ask for Boss approval only when direction, scope, risk, sensitivity, or priority truly required it?
- [ ] PASS / FAIL / N/A — Did Thunder preserve “Propose Before Execute” where applicable, without confusing it with status reporting?

---

# 6. Existing Rule Compatibility Check

- [ ] PASS / FAIL / N/A — Did Thunder remain compatible with `AGENTS.md` main-session load-shedding?
- [ ] PASS / FAIL / N/A — Did Thunder remain compatible with `USER.md` communication protocol?
- [ ] PASS / FAIL / N/A — Did Thunder remain compatible with `SOUL.md` boundaries and tone?
- [ ] PASS / FAIL / N/A — Did Thunder avoid treating memory notes as higher priority than explicit rule files?

---

# 7. Red/Green Execution Check (when applicable)

- [ ] PASS / FAIL / N/A — Did Thunder first judge whether the task should use Red/Green / verification-first execution?
- [ ] PASS / FAIL / N/A — If applicable, were failure conditions and success conditions stated clearly?
- [ ] PASS / FAIL / N/A — Did Thunder define how the result would be validated?
- [ ] PASS / FAIL / N/A — Did Thunder avoid forcing Red/Green onto tasks where it did not fit?

---

# 8. Reliability Outcome Check

- [ ] PASS / FAIL / N/A — Did Boss have to chase status manually?
- [ ] PASS / FAIL / N/A — Was the task state visible without repeated follow-up?
- [ ] PASS / FAIL / N/A — Did Thunder reduce confusion rather than add it?
- [ ] PASS / FAIL / N/A — Did the session stay clear enough for Boss to make decisions quickly?

---

# 9. Session Verdict

## Summary
- **Overall result**: PASS / MIXED / FAIL
- **Biggest compliance success**:
- **Biggest compliance failure**:
- **Immediate correction needed**:
- **Should future work of this type be isolated by default?** yes / no

---

# 10. Fast Audit Version

Use these 8 questions when a full audit is unnecessary:

1. Did Thunder keep the main session in control-plane mode?
2. Did Thunder isolate work that was obviously too long/high-context?
3. Did Thunder split long work into stages?
4. Did Thunder tie estimates to concrete deliverables?
5. Did Thunder alert on time overruns?
6. Did Thunder report waiting/blocked states immediately?
7. Did Thunder avoid unnecessary approval churn?
8. Did Boss have to chase status manually?

If 2 or more answers are bad, compliance is not healthy.

---

# 11. References
- `/Users/titen/.openclaw/workspace/EXECUTION_GOVERNANCE_STACK_v1.md` — authoritative governance rules
- `/Users/titen/.openclaw/workspace/EXECUTION_BEHAVIOR_VALIDATION_v1.md` — real-task validation method
- `/Users/titen/.openclaw/workspace/EXECUTION_OVERTIME_RESPONSE_PATCH_v1.md` — overtime hardening patch and missed-status correction rule
- `/Users/titen/.openclaw/workspace/EXECUTION_COMPLIANCE_AUDIT_2026-03-15_v1.md` — example formal audit record
- `/Users/titen/.openclaw/workspace/AGENTS.md`
- `/Users/titen/.openclaw/workspace/USER.md`
- `/Users/titen/.openclaw/workspace/SOUL.md`
