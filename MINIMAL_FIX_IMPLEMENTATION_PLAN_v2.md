# MINIMAL_FIX_IMPLEMENTATION_PLAN_v2

> 目的：把 `MINIMAL_FIX_IMPLEMENTATION_DRAFT_v2.md` 从“方向草案”进一步压成可编码、可验证、可回滚的最小实施计划。

---

# 0. Plan Goal

This plan is for a **narrow cron-only repair**.
It is not a broad rewrite of announce/completion plumbing.

The concrete goal is:

> For eligible business cron jobs, bypass main-session completion relay and use direct external delivery when the result is already a finalized plain-text deliverable.

---

# 1. Implementation Entry

## Primary entry point
Implement at the **cron-specific announce routing decision**.

## Principle
Change the earliest cron-only routing branch that decides whether completed cron output should:
- re-enter main assistant session via completion relay
or
- go directly to the external target

## Why here
- cron-only scope
- full job/delivery context already available
- minimal blast radius
- avoids touching shared non-cron completion behavior

---

# 2. First-Patch Scope Rule

## Eligible branch condition (v1)
The first patch should only bypass relay when **all** of the following are true:

1. the source is a cron job
2. the job is one of the targeted business-report style jobs, or otherwise clearly marked equivalent
3. `delivery.channel` is explicitly present
4. `delivery.to` is explicitly present
5. the produced output is already finalized plain text
6. there is no required structured payload / thread-binding / assistant-mediated rewrite dependency

## First-patch scope recommendation
Prefer the narrowest initial scope:
- `daily-comprehensive-briefing`
- `end-of-day`
- `weekly-review`

Only expand after observation confirms safety.

---

# 3. Routing Decision Logic

## Current undesired path
cron completed output
→ announce/completion relay
→ main assistant injected completion event
→ assistant rewrite
→ user-visible delivery

## Desired path for eligible jobs
cron completed output
→ direct external delivery
→ observation/logging

## Required behavior for non-eligible jobs
Keep existing behavior unchanged.

---

# 4. Direct Delivery Reuse Strategy

## Rule
Do not invent a new send path if an existing direct-delivery branch/helper already exists in the cron/gateway delivery stack.

## Implementation preference
Reuse an existing direct-delivery helper/path that already supports:
- target channel
- target recipient
- existing provider/account routing
- normal delivery logging/status

## Avoid
- hand-built ad hoc message send
- new parallel delivery plumbing
- changes that bypass normal delivery accounting

---

# 5. Exact Patch Tasks

## Task 1 — Add narrow branch condition
Add a cron-only branch that checks whether a completed cron output matches the eligible direct-delivery conditions.

### Output of Task 1
A boolean routing decision such as:
- eligible for direct delivery bypass
- not eligible, continue existing announce path

---

## Task 2 — Route eligible cron output to existing direct delivery path
If eligible:
- do not route through main-session completion relay
- send directly to configured external destination
- retain normal success/failure recording

### Output of Task 2
Eligible business cron jobs deliver externally without main-session rewrite mediation.

---

## Task 3 — Preserve existing behavior for all non-eligible cases
If not eligible:
- preserve prior announce/completion behavior exactly

### Output of Task 3
Blast radius stays narrow and non-target workflows remain stable.

---

## Task 4 — Add safe observability markers
Ensure logs or delivery status make it possible to distinguish:
- direct cron delivery bypass path used
- legacy announce/completion path used

### Output of Task 4
Observation after patch can verify whether targeted jobs still re-enter main session.

---

# 6. Acceptance Test Plan

## Test A — Targeted business cron jobs
For each targeted job:
- confirm delivery still reaches the correct destination
- confirm visible message no longer depends on main-session rewrite path
- confirm normal delivered status is preserved

## Test B — Non-target cron behavior
Use at least one non-eligible announce-style job/path if available:
- confirm prior behavior remains unchanged

## Test C — Main-session contamination check
After targeted jobs run:
- confirm they no longer create the same main-session completion rewrite pattern
- confirm main-session load from these jobs is reduced

## Test D — Failure-path safety
If direct delivery fails:
- confirm failure is recorded normally
- confirm the patch does not create duplicate user-visible sends
- confirm fallback behavior does not silently bypass observability

---

# 7. Rollback Plan

## Trigger rollback if
- targeted jobs stop delivering reliably
- direct-send branch loses necessary destination semantics
- duplicate-send behavior increases
- unexpected non-target regressions appear

## Rollback scope
Rollback only the cron-specific bypass branch.
Do not combine rollback with shared completion-layer modifications.

## Rollback outcome
Targeted jobs return to prior announce/completion-relay behavior while preserving broader system stability.

---

# 8. Observation Window

## Window
- **72 hours** after patch

## Watch for
- whether targeted jobs still re-enter main session
- whether delivery remains correct and timely
- whether duplicate/old-content symptom frequency declines
- whether automatic-report contribution to main-session pressure declines

---

# 9. Explicit Non-Goals

Do not do these in the first patch:
- do not modify generic subagent completion machinery
- do not modify generic internal task-completion event formatting
- do not broadly redesign announce semantics for all producers
- do not switch Assistant bot identity/routing in the same change
- do not couple this patch with wider runtime cleanup work

---

# 10. Pre-Coding Checklist

Before coding, confirm:
- exact targeted branch location is identified in current runtime file
- an existing safe direct-delivery helper/path is available for reuse
- targeted jobs are enumerated clearly
- acceptance-test sequence is ready
- rollback edit scope is isolated

If any of these are unclear, do one last narrow code-read pass before editing.

---

# 11. Recommended Execution Order

1. locate exact branch condition site
2. verify reusable direct-delivery path/helper
3. patch narrow eligible cron bypass
4. test targeted jobs / delivery semantics
5. test non-target unchanged behavior
6. observe for 72 hours

---

# 12. One-Line Summary

> Implement a **cron-only direct-delivery bypass** for a narrow set of finalized business-report jobs, while leaving shared completion machinery untouched and validating behavior through targeted delivery tests plus a 72-hour observation window.
