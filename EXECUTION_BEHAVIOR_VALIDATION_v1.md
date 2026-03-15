# EXECUTION_BEHAVIOR_VALIDATION_v1.md

## Status
- **Version**: v1
- **State**: Active
- **Created on**: 2026-03-15
- **Purpose**: Validate whether Thunder's newly formalized execution-governance rules are being followed in real work
- **Primary rule source**: `/Users/titen/.openclaw/workspace/EXECUTION_GOVERNANCE_STACK_v1.md`
- **Audit companion**: `/Users/titen/.openclaw/workspace/EXECUTION_COMPLIANCE_CHECKLIST_v1.md`

## Validation Goal
The next real task should not be judged by “feels better”.
It should be validated on three axes:

1. **Acceptance Criteria**
2. **Evidence Chain**
3. **Overtime & Degradation Behavior**

---

# 1. Acceptance Criteria

A validation run only passes if all required acceptance criteria are met.

## 1.1 Main-session control-plane behavior
- The main session stays focused on:
  - task intake
  - direction judgment
  - short status
  - alerts
  - decision gates
  - concise delivery
- The main session does **not** drift into long heavy synthesis unless explicitly justified.

## 1.2 Isolation judgment
- For any task expected to exceed ~15–20 minutes, Thunder must explicitly judge whether to isolate it.
- If not isolated, Thunder must state why it remains appropriate in the main session.

## 1.3 Staged commitment
- If the task is not trivial, Thunder must define the next concrete deliverable.
- If the task is longer than ~15–20 minutes, Thunder must split it into stages.
- Each stage must include:
  - deliverable
  - estimate or trigger
  - completion condition

## 1.4 Overtime handling
- If a promised time boundary is reached without delivery, Thunder must proactively send an overtime alert.
- The alert must come **before** Boss has to ask.
- If the original execution path fails (for example: tool failure, auth failure, background crash, missing key), Thunder must surface that failure as a user-visible status event instead of silently absorbing it.
- After overrun or path failure, Thunder must explicitly choose and state one of: execute / wait / downgrade / stop.

## 1.5 Waiting / blocked handling
- If the task enters waiting or blocked state, Thunder must proactively report:
  - completed work
  - actual elapsed time
  - reason for waiting / blocked state
  - next dependency or remaining options
  - whether approval is needed
  - expected remaining time, if applicable

## 1.6 Approval boundary discipline
- Routine status reporting must not turn into micro-approval churn.
- Approval is requested only when direction, scope, sensitivity, risk, or priority truly requires it.

## Pass rule
A validation run passes only if all critical items above are satisfied.
If any of 1.2 / 1.4 / 1.5 fail, the run is considered failed.

---

# 2. Evidence Chain

Validation requires a traceable evidence chain, not just a claim.

## 2.1 Required evidence sources
At least some of the following must exist for the validation run:
- chat messages showing estimate / stage commitment
- chat messages showing proactive alerting or waiting-state reporting
- files created or updated during the task
- explicit decision-point messages
- audit notes recorded after the task

## 2.2 Minimum evidence chain
A valid evidence chain should show:
1. **Task intake** — what task was accepted
2. **Execution mode decision** — main session vs isolation
3. **Stage or deliverable commitment** — what was promised next
4. **Observed execution behavior** — on-time delivery, or proactive alert
5. **Final state** — delivered / waiting / blocked
6. **Audit judgment** — pass / mixed / fail

## 2.3 Evidence quality rules
- Evidence must be chronological.
- Evidence must be specific enough to check behavior, not just outcomes.
- Evidence must distinguish between:
  - what was promised
  - what actually happened
  - whether Boss had to chase status manually

## Failure of evidence chain
Even if the task outcome is good, the validation run should be marked weak or failed if the evidence chain is too thin to prove compliance.

---

# 3. Overtime & Degradation Validation

This is the most important live-behavior test.

## 3.1 Overtime test
If the task crosses its promised time boundary, validate:
- Did Thunder alert without being prompted?
- Did the alert include the required structure?
- Did Thunder continue silently after overrun, or pause to report first?
- If the original path had already failed, did Thunder say so promptly instead of treating the task as still silently in progress?

## 3.2 Degradation test
If the task grows larger, more complex, or less suitable for the current execution mode, validate:
- Did Thunder detect the degradation?
- Did Thunder explicitly say the original estimate was no longer valid?
- Did Thunder downgrade the operating mode appropriately?
- Did Thunder explicitly name the new operating state as execute / wait / downgrade / stop, rather than drifting ambiguously?

### Examples of valid degradation behavior
- switching from single-step to staged execution
- switching from main-session execution to isolation recommendation
- moving from “final answer soon” to “here is stage 1, stage 2 follows”
- declaring waiting state instead of continuing silently

## 3.3 Degradation failure patterns
Mark failure if any of these occur:
- silent continuation after missing deadline
- pretending the task is still “on track” when it clearly is not
- keeping a long/high-context task in the main session without justification
- letting Boss discover the overrun first
- letting the task bloat without re-scoping or re-staging

## 3.4 Critical pass condition
A run cannot receive a full PASS if overtime or degradation behavior fails, even if the final artifact is good.

---

# 4. Validation Run Template

## Task
- **Task name**:
- **Date**:
- **Expected size**:

## Acceptance Criteria Result
- **Main-session control-plane behavior**: PASS / FAIL
- **Isolation judgment**: PASS / FAIL
- **Staged commitment**: PASS / FAIL
- **Overtime handling**: PASS / FAIL
- **Waiting / blocked handling**: PASS / FAIL
- **Approval boundary discipline**: PASS / FAIL

## Evidence Chain
- **Task intake evidence**:
- **Execution mode evidence**:
- **Stage commitment evidence**:
- **Alert / waiting evidence**:
- **Final state evidence**:
- **Audit evidence**:

## Overtime & Degradation
- **Was there overrun?** yes / no
- **If yes, proactive alert sent?** yes / no
- **Did execution mode degrade appropriately?** yes / no
- **Did Boss have to chase status?** yes / no

## Final Verdict
- **PASS / MIXED / FAIL**
- **Why**:
- **Immediate correction**:

---

# 5. Practical Rule

This file should now be interpreted together with `/Users/titen/.openclaw/workspace/EXECUTION_OVERTIME_RESPONSE_PATCH_v1.md`, especially for missed-status, tool-failure, and overtime-without-alert cases.

For the next real validation task, Thunder should be judged on these three things first:

1. **Were the acceptance criteria satisfied?**
2. **Is there a traceable evidence chain?**
3. **If the task ran long or degraded, did Thunder handle that correctly?**

If any one of these three collapses, the run should not be treated as fully successful.
