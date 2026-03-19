# MINIMAL_FIX_DECISION_BOARD_v1

> 目的：把当前 cron / Assistant bot / delivery path / timeout / retry / sender authority 相关的最小修复准备工作，压成一份可执行、可决策、可验证的决策板。

---

# 0. Current Phase

## Current judgment
The project is currently **not** in a pure preflight-only state, and also **not** in a fully cleared implementation state.

The most accurate phase label is:

> **First-batch conservative containment is partially in effect + 72H observation is ongoing + second-batch identity/routing correction is still blocked on preflight completion.**

This matters because the next decision is **not** “whether to begin any repair at all”.
The real decision is:
- whether observation is stable enough
- whether second-batch identity/routing work is ready
- whether deeper runtime interception is required

---

# 1. Decision Board Structure

This board classifies the situation into four states:

1. **Confirmed**
2. **To Validate**
3. **To Decide**
4. **Do Not Execute Yet**

---

# 2. Confirmed

## 2.1 Root-cause ordering
Current working order remains:
1. **H1** — main-session overload / timeout / snapshot fallback
2. **H3** — queue / lane / retry / fallback closure problems as amplifiers
3. **H4** — sender-identity / sending-subject misalignment still needs more confirmation
4. **H2** — dual sending authority / timezone / idempotency as background structural weakness, not the leading direct cause

## 2.2 Phase truth
The work has already moved beyond discussion-only mode.
At least part of the first conservative containment batch has already been applied.

## 2.3 Observation state
A **72-hour observation window** is already the active operating mode.
The current best action is not broad expansion, but verifying whether the first-batch containment materially reduces symptoms.

## 2.4 Governance state
Main-session load-shedding / control-plane governance has already been formalized and linked into the workspace rule chain.

---

# 3. To Validate

These items are still not sufficiently closed and must remain explicit open checks.

## 3.1 Delivery path
Still verify the actual delivery path for:
- `daily-comprehensive-briefing`
- `weekly-review`
- `end-of-day`

Need final answer to:
> Are these truly independently delivered, or do they still route back into the main assistant reply chain?

## 3.2 Assistant bot identity mapping
Still verify:
- which live provider/account identity corresponds to the intended Assistant bot
- whether that identity is distinct from the current main assistant sending identity
- how routing is currently split or merged

## 3.3 Runtime control point for timeout / snapshot fallback
Still verify:
> At what real runtime layer should automatic outward正文 be stopped after `embedded run timeout`, `using current snapshot`, or summarization failure?

## 3.4 Runtime control point for retry duplication
Still verify:
> At what real runtime layer should retry stop producing repeated outward正文 after repeated delivery/error conditions?

## 3.5 Main-session contamination path
Still verify whether automatic results enter the main session primarily through:
- announce
- delivery configuration
- runtime completion relay
- main-session post-processing / reply behavior

---

# 4. To Decide

These are the next real decision gates.

## 4.1 Whether second-batch sender correction can begin
This refers to restoring daily/weekly delivery to the correct Assistant bot sender identity.

This should only proceed when identity mapping and routing are sufficiently clear.

## 4.2 Whether deeper runtime interception is needed
If 72H observation does **not** show symptom reduction, then the next decision is whether to move below policy/payload containment and into deeper runtime interception.

## 4.3 Whether current minimum-fix gate is satisfied
Need a clear call on whether the system is ready to move from:
- conservative containment + observation
into:
- second-batch sender/routing correction

---

# 5. Do Not Execute Yet

The following actions should remain explicitly out of scope for now.

## 5.1 Do not directly switch daily/weekly sending identity yet
Reason:
- Assistant bot mapping is not yet fully closed
- routing relation is not yet fully closed

## 5.2 Do not broadly modify OpenClaw core/runtime
Reason:
- the current direction is still minimal repair, not architecture rewrite

## 5.3 Do not expand fix scope without object-level evidence
Reason:
- avoid turning likely hypotheses into broad unjustified changes

## 5.4 Do not treat first-batch partial landing as final resolution
Reason:
- the current state is still observation-dependent

---

# 6. What Has Already Landed

Based on the current remediation index and execution plan chain, the following are already materially true:

## 6.1 First-batch conservative containment has partially landed
Including:
- tighter output boundary for relevant cron jobs
- reduced expansion of automatic result handling
- governance rule to reduce main-session overload
- safe-fail / idempotency-oriented output discipline

## 6.2 But runtime hard interception is not fully closed
Especially for:
- timeout / snapshot fallback → outward正文 blocking
- retry threshold → repeated outward正文 blocking

So the current state is:
> **partially landed containment, not fully hardened runtime enforcement**

---

# 7. Minimum Gate for Entering Second-Batch Work

The next phase should be defined as:

## Phase: Second-batch identity/routing correction

Suggested minimum gate:
- 72H observation does not show first-batch failure severe enough to force immediate redesign
- actual daily/weekly delivery path is clearly identified
- Assistant bot identity mapping is clearly identified
- routing relationship between main assistant and Assistant bot is clearly identified

If these are not met, remain in:
> observation + preflight closure

---

# 8. Decision Options for Boss

After reading this board, the practical choices are:

## Option A — Continue observation
Use when:
- first-batch containment appears to be helping
- key identity/path checks are still open

## Option B — Finish remaining preflight checks
Use when:
- observation is ongoing
- but the remaining unknowns are now the main blocker

## Option C — Prepare second-batch sender/routing correction
Use when:
- identity/path questions are sufficiently closed
- first-batch behavior is stable enough

## Option D — Escalate to deeper interception
Use when:
- observation shows repeated symptom recurrence despite first-batch containment

---

# 9. Recommended Current Position

## Recommendation
The recommended current position is:

> **Stay in observation + finish remaining preflight closure for identity/path/runtime control points.**

Reason:
- first-batch containment is already partially active
- second-batch sender correction is not yet safely unlocked
- the biggest remaining decision blockers are now specific and knowable, not broad and vague

---

# 10. Consistency With Existing Documents

This board is intended to stay aligned with:
- `/Users/titen/.openclaw/workspace/MINIMAL_FIX_PREFLIGHT_CHECKLIST_v1.md`
- `/Users/titen/.openclaw/workspace/MINIMAL_FIX_EXECUTION_PLAN_v1.md`
- `/Users/titen/.openclaw/workspace/IMPLEMENTATION_ACTION_QUEUE_v1.md`
- `/Users/titen/.openclaw/workspace/CRON_INCIDENT_REMEDIATION_INDEX_v1.md`
- `/Users/titen/.openclaw/workspace/ROOT_CAUSE_VALIDATION_CHECKLIST_v1.md`

Interpretation alignment:
- preflight file = what still needs checking
- execution plan = what first-batch containment means
- action queue = how first-batch work was ordered
- remediation index = phase truth and observation truth
- root-cause file = why current prioritization still centers on H1/H3/H4/H2 ordering

---

# 11. One-Line Summary

> The system is currently in **partial first-batch containment + active 72H observation**, while **second-batch Assistant-bot identity/routing correction remains blocked on finishing the remaining preflight checks**.
