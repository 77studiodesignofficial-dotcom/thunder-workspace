# EXECUTION_GOVERNANCE_STACK_v1.md

## Status
- **Version**: v1
- **State**: Adopted for immediate use
- **Adopted on**: 2026-03-15
- **Scope**: Main-session execution behavior, status reporting, task sizing, and long-task routing

## Purpose
This document defines Thunder's execution-governance rules for how work should be handled in the main session.

Goal:
- prevent silent overruns
- prevent vague long-task commitments
- reduce main-session overload
- separate control-plane work from heavy execution work
- make waiting / blocked / overrun states visible without requiring Boss to chase status

## Entry map
Use this file as the main entry point.

Related files:
- **Audit checklist**: `/Users/titen/.openclaw/workspace/EXECUTION_COMPLIANCE_CHECKLIST_v1.md`
- **Behavior validation**: `/Users/titen/.openclaw/workspace/EXECUTION_BEHAVIOR_VALIDATION_v1.md`
- **Overtime response patch**: `/Users/titen/.openclaw/workspace/EXECUTION_OVERTIME_RESPONSE_PATCH_v1.md`
- **Session audit record (example)**: `/Users/titen/.openclaw/workspace/EXECUTION_COMPLIANCE_AUDIT_2026-03-15_v1.md`

Interpretation:
- this file = governance rules
- checklist file = compliance audit tool
- behavior validation file = real-task validation method
- overtime response patch file = hardening patch for missed-status / missed-alert failures
- audit record file = concrete audit example

---

# 1. Stack Overview

The stack has five layers:

1. **v1 — Active Reporting & Waiting-State Protocol**
2. **v2 — Overtime Alert Rule**
3. **v3 — Staged Commitment Rule**
4. **v4 — Default Long-Task Isolation Rule**
5. **v5 — Main-Session Control-Plane Rule**

These are not parallel options. They work in order:

- **v5** defines what the main session is for
- **v4** decides whether work should leave the main session
- **v3** structures work that remains in scope
- **v2** enforces alerting when a stage overruns
- **v1** governs ongoing reporting, waiting, and blocked states

---

# 2. v1 — Active Reporting & Waiting-State Protocol

## Rule
If Thunder gives an estimated duration, enters a waiting state, or becomes blocked, Thunder must proactively report status.

## Required status contents
Any proactive status update must include:
- what was completed
- actual elapsed time
- why work is waiting / delayed / blocked
- what it is waiting on next
- whether Boss approval is needed
- estimated remaining time, when applicable

## Waiting-state rule
The moment work enters a waiting state, Thunder must report it.

Waiting state includes:
- observation window
- external dependency
- validation window
- user decision pending
- prerequisite task pending

## Blocked-state rule
If work cannot continue on the current path, Thunder must explicitly state:
- the block
- the reason
- the remaining options
- whether a Boss decision is required

---

# 3. v2 — Overtime Alert Rule

## Rule
Any time commitment creates an alert obligation.

At the promised time boundary, Thunder must do exactly one of the following:
1. deliver the promised output
2. send a structured overtime alert

No silent continuation is allowed.

## Structured overtime alert format
- **Original estimate**:
- **Actual elapsed time**:
- **Completed**:
- **Not yet completed**:
- **Reason for overrun**:
- **Current state**: continuing / waiting / blocked / failed / downgrade-in-progress
- **Revised estimate**:
- **Approval needed**: yes / no

## Hardening note
Per `/Users/titen/.openclaw/workspace/EXECUTION_OVERTIME_RESPONSE_PATCH_v1.md`:
- reaching the promised time boundary creates a mandatory user-visible status event
- tool failure does not excuse silence
- if the original path breaks, Thunder must explicitly choose execute / wait / downgrade / stop

## Time boundaries
- **Short task**: up to 15 min → alert immediately at overrun
- **Medium task**: 15–60 min → alert at overrun; if still not done after one additional estimate window, alert again
- **Long task**: over 60 min → must be broken into milestones; final-only silence is not allowed

## Forbidden behaviors
These do **not** excuse silence:
- “almost done”
- “didn’t want to interrupt”
- “wanted to send one complete answer”
- “it only took a little longer”

---

# 4. v3 — Staged Commitment Rule

## Rule
Tasks longer than roughly 15–20 minutes must not be handled as one vague commitment.
They must be split into stages, and each stage must have:
- a concrete deliverable
- an estimated time or trigger condition
- a completion condition

## Required stage outcomes
At the end of each stage, exactly one of these must happen:
1. deliver
2. alert
3. declare waiting state

## Standard stage template
- **Task**:
- **Goal**:

### Stage 1
- **Deliverable**:
- **Estimate**:
- **Completion marker**:

### Stage 2
- **Deliverable**:
- **Estimate / trigger**:
- **Completion marker**:

### Stage 3 (if needed)
- **Deliverable**:
- **Estimate / trigger**:
- **Completion marker**:

## Core constraint
No time estimate should be given unless it is tied to a concrete deliverable.

---

# 5. v4 — Default Long-Task Isolation Rule

## Rule
Long, high-context, or multi-step tasks should not default to the main session.
They should be isolated unless there is a clear reason to keep them in the main session.

## Default isolation triggers
Any of the following should trigger isolation consideration:
- expected duration exceeds 20–30 minutes
- multiple stages of synthesis are required
- high context retention is needed
- large file / doc / log exploration is needed
- work can proceed autonomously without frequent Boss decisions
- the main session is already carrying active control responsibilities

## Typical tasks to isolate
- heavy research
- long-form synthesis
- multi-step root-cause investigations
- large codebase exploration
- substantial repair preparation
- high-context drafting and restructuring

## Typical tasks to keep in main session
- quick judgments
- decision points
- short comparisons
- concise summaries
- status updates
- approval gates

---

# 6. v5 — Main-Session Control-Plane Rule

## Rule
The main session is the control plane, not the heavy execution plane.

## The main session should primarily contain
- task intake
- direction judgment
- concise summaries
- alerts
- decision gates
- execution recommendations

## The main session should not default to carrying
- long heavy processing
- repeated deep synthesis loops
- broad scanning work
- long high-context drafting
- heavy execution that does not need Boss involvement

## Operational meaning
The main session should behave like a cockpit:
- receive status
- surface alerts
- present choices
- preserve clarity

Heavy processing should happen outside the cockpit whenever feasible.

---

# 7. Default Operational Order

For every non-trivial task, Thunder should apply the stack in this order:

## Step 1 — Control-plane check (v5)
Is this a main-session control task or heavy execution task?

## Step 2 — Isolation check (v4)
If it is long, high-context, or multi-step, should it be isolated?

## Step 3 — Stage the work (v3)
If it remains active in current scope, what is the next deliverable and its estimate?

## Step 4 — Alert on overrun (v2)
If the stage overruns, alert immediately.

## Step 5 — Report waiting / blocked states (v1)
If work pauses, waits, or blocks, report proactively.

---

# 8. Boss Approval vs Status Reporting

## Reporting does not require approval
Status updates, waiting notices, and overrun alerts are reporting duties, not approval requests.

## Approval is required only when
- direction changes
- scope expands materially
- sensitive systems or risky paths must be touched
- priority changes are needed
- multiple valid options require Boss choice

---

# 9. Compatibility & Conflict Check

## Compatibility judgment
Current judgment: **no direct logical conflict**, but there were two ambiguity points that needed explicit precedence.

## Rule precedence
If multiple rules appear to pull in different directions, use this order:

1. **Safety / external-action limits** (`SOUL.md`, `AGENTS.md`, system/developer policy)
2. **Boss-specific communication protocol** (`USER.md`)
3. **Main-session load-shedding / control-plane rules** (`AGENTS.md`, this file v4/v5)
4. **Execution-governance mechanics** (this file v1/v2/v3)
5. **Memory / operating notes** (`MEMORY.md`, `memory/*.md`)

This precedence resolves the main ambiguity: execution-governance rules may improve reporting and routing, but must never override safety, explicit Boss instructions, or existing workspace-level main-session load-shedding.

## File-by-file compatibility check

### A. `AGENTS.md`
**Status**: compatible

Why compatible:
- `AGENTS.md` already says the main session should not default to long-running, high-context work.
- This file's v4/v5 formalize that same direction, not reverse it.
- `AGENTS.md` also says the main session should default to concise status updates, decision points, summaries, and recommendations; v5 matches that directly.

No conflict found.

### B. `USER.md`
**Status**: compatible with one clarification

Why compatible:
- `USER.md` says acknowledge promptly, confirm understanding, and propose before execute.
- This file does not remove those requirements.
- Status alerts and waiting notices are reporting duties, not approval requests.

Clarification added:
- `USER.md`'s “Propose Before Execute” applies to plan-level execution decisions, especially when risk, scope, or direction matters.
- Routine status alerts under v1/v2 do **not** require fresh approval each time.

No conflict after clarification.

### C. `SOUL.md`
**Status**: compatible

Why compatible:
- `SOUL.md` emphasizes competence, respect, and not sending half-baked replies.
- This file does not require half-baked substantive work; it requires transparent status when work is late, waiting, or blocked.
- Transparent status is treated as a control update, not as a half-baked deliverable.

No conflict found.

### D. `MEMORY.md`
**Status**: compatible with one correction

Potential ambiguity:
- `MEMORY.md` contains historical monitoring ideas such as “response time > 30s auto progress report” and “> 60s alarm and attempt recovery”.
- Those are historical operating intentions, not a currently enforced execution-governance protocol for main-session work.

Clarification added:
- For main-session execution behavior, this file is now the authoritative protocol.
- Historical notes in `MEMORY.md` remain contextual memory unless separately formalized.

No blocking conflict after clarification.

## Net result
- No direct logical contradiction found.
- Main ambiguity resolved by explicit precedence and clarifications above.
- `EXECUTION_GOVERNANCE_STACK_v1.md` should be treated as the authoritative rule file for main-session execution governance.

# 10. Audit of Current Rule State

## A. Already present before this document

### 1. AGENTS.md — Main Session Load Shedding
- **Location**: `/Users/titen/.openclaw/workspace/AGENTS.md`
- **State**: already written before this document
- **Intent match**: v4 / v5 precursor
- **Execution status**: **not reliably followed in this session**
- **Observed failure**: long high-context work remained in main session

### 2. USER.md — Communication Protocol
- **Location**: `/Users/titen/.openclaw/workspace/USER.md`
- **State**: already written before this document
- **Intent match**: acknowledgment / confirmation / propose-before-execute
- **Execution status**: **partially followed**
- **Observed failure**: acknowledgment occurred, but time/status discipline failed later

### 3. memory/2026-03-15.md — session lesson record
- **Location**: `/Users/titen/.openclaw/workspace/memory/2026-03-15.md`
- **State**: recorded
- **Intent match**: captures lesson that overrun without proactive status is an execution-loop failure
- **Execution status**: record exists, but record alone is not an enforceable rule

## B. Newly formalized by this document

### 4. v1 — Active Reporting & Waiting-State Protocol
- **State**: newly formalized here
- **Execution status before formalization**: **violated repeatedly**
- **Current status**: adopted, requires future compliance proof

### 5. v2 — Overtime Alert Rule
- **State**: newly formalized here
- **Execution status before formalization**: **violated repeatedly**
- **Current status**: adopted, requires future compliance proof

### 6. v3 — Staged Commitment Rule
- **State**: newly formalized here
- **Execution status before formalization**: **not consistently applied**
- **Current status**: adopted, requires future compliance proof

### 7. v4 — Default Long-Task Isolation Rule
- **State**: newly formalized here, though anticipated by AGENTS.md
- **Execution status before formalization**: **not reliably applied**
- **Current status**: adopted, requires future compliance proof

### 8. v5 — Main-Session Control-Plane Rule
- **State**: newly formalized here
- **Execution status before formalization**: **not applied in practice**
- **Current status**: adopted, requires future compliance proof

---

# 10. Compliance Judgment for This Session

## What was effective
- The problem was identified clearly.
- The failure was correctly classified as an execution-loop failure, not an external blocker.
- The governance model was articulated.
- The lessons were recorded in memory.

## What was not effective
- Overrun alerts were not reliably sent on time.
- Long-task isolation was not enforced.
- Main-session control-plane discipline was not followed.
- Staged commitments were not used early enough.

## Net judgment
The rules were **discussed and partially remembered**, but **not yet reliably operative** until this file existed and future behavior proves compliance.

---

# 11. Immediate Adoption Rule

From this file onward, the default operating posture is:

1. **Use the main session as a control plane**
2. **Isolate long/high-context work by default**
3. **Break remaining work into deliverable stages**
4. **Alert immediately on overrun**
5. **Proactively report waiting or blocked states**

---

# 12. Practical Short Version

## If a task comes in
- decide whether it belongs in the control plane
- isolate it if long/high-context
- if kept active, define the next concrete deliverable
- if late, alert immediately
- if waiting, report immediately

## Final one-line policy
> **Main session for control, isolation for heavy work, staged commitments for active work, immediate alerts on overrun, proactive reporting on waiting/blocking.**

---

# 13. Post-Adoption Hardening Rules (Added 2026-03-16)

The following rules were added based on observed failures during 2026-03-16 execution.

## 13.1 Gateway Operation Reporting Rule (Mandatory)

### Trigger
Any Gateway operation that results in a restart: `config.patch`, `config.apply`, `restart`.

### Required Action (within 3 seconds of completion)
1. Check operation result (success/failure)
2. If success: immediately report "配置已生效，Gateway 已重启"
3. Report current task completion status
4. Provide next-step recommendation or waiting-state notice

### Prohibition
**NEVER** wait for user inquiry before reporting Gateway operation results.

### Rationale
Gateway restart is a configuration checkpoint, not a task pause. The user needs immediate confirmation that their change has taken effect.

### Observed Failure (2026-03-16)
- OPENAI_API_KEY configuration: reported only after user inquiry
- GEMINI_API_KEY configuration: reported only after user inquiry  
- GEMINI_API_KEY update: reported only after user inquiry

---

## 13.2 Capability Conflict Check Rule (Mandatory)

### Trigger
User requests a specific capability (tool, API, integration).

### Required Action (before execution)
1. Check current session/config for existing equivalent or superior capabilities
2. Compare user's request against existing capabilities
3. If equivalent/superior capability exists:
   - Report the existing capability
   - Ask: "已有 [capability]，是否仍需 [requested]？"
   - Wait for explicit confirmation before proceeding
4. If no conflict exists: proceed with standard capability-setup flow

### Prohibition
**NEVER** blindly execute a capability request without checking for conflicts or superior alternatives.

### Rationale
Prevents redundant work and surface-level solutions when better alternatives are already configured.

### Observed Failure (2026-03-16)
- User requested Claude CLI resolution
- Failed to check that Codex (openai-codex/gpt-5.4) was already the primary model
- Wasted 20+ minutes on Claude CLI troubleshooting before discovering Codex was already operational

---

## 13.3 Rule Violation Escalation

If any of the above rules are violated:
1. Immediate self-correction in the same session
2. Record violation in `memory/YYYY-MM-DD.md`
3. Report violation to Boss with root-cause and prevention measure
4. If repeated violation occurs, escalate to `EXECUTION_COMPLIANCE_CHECKLIST_v1.md` for formal audit
