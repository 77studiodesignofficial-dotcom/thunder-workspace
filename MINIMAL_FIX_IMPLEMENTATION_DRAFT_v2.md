# MINIMAL_FIX_IMPLEMENTATION_DRAFT_v2

> 目的：基于最新 implementation-level preflight 结论，把本次最小修复从“泛方向”收敛到一个明确、低 blast radius、可回滚的实现草案。

---

# 0. Draft Status

## Current draft judgment
This draft is now based on a stronger implementation-level conclusion:

> The narrowest practical control point is the **cron-side announce dispatch entry**, not the generic subagent completion machinery and not the main-session post-processing layer.

This draft is intended to support a minimal change, not a broad behavior redesign.

---

# 1. Problem Statement

Current business cron jobs produce completed output, but instead of always delivering directly to the external target, they can enter a completion-relay path that feeds the result back into the main assistant conversation.

That creates the following risk chain:
- cron output is completed
- output re-enters main assistant session
- main session rewrites/sends the visible user message
- automatic reports become entangled with main-session context load
- timeout / snapshot fallback / retry conditions can amplify the failure mode

The minimal-fix goal is therefore:

> **For eligible business cron jobs, stop routing completed plain-text output back into the main assistant session when direct delivery is already possible.**

---

# 2. Confirmed Control Point

## Recommended implementation entry
The recommended entry point is:

> **cron runtime announce dispatch layer**

Current conclusion:
- the relay path is chosen at the cron-side announce dispatch stage
- that stage has enough context to decide whether main-session relay is necessary
- changing this stage scopes the fix to cron jobs instead of all subagent/task-completion flows

---

# 3. Intended Minimal Change Shape

## Core change
For a narrow eligible subset of cron jobs:
- if the job already has an explicit external destination
- and the final output is already complete plain text
- and there is no dependency on assistant-side rewriting semantics

then:

> **bypass the main-session completion relay path and use direct external delivery instead**

Instead of:
- cron result → completion relay → main assistant → visible message

Use:
- cron result → direct delivery to external target

---

# 4. Scope Conditions

The first implementation should be intentionally narrow.

## In-scope candidates
Business cron jobs like:
- `daily-comprehensive-briefing`
- `end-of-day`
- `weekly-review`

when all of the following are true:
- explicit `channel` is present
- explicit `to` target is present
- output is already a finalized plain-text deliverable
- no thread-binding or structured-response dependency requires assistant-session mediation

## Out-of-scope for first patch
Do not include yet:
- ambiguous routing cases
- jobs that depend on assistant-style conversational rewriting
- jobs whose output is not already finalized for direct send
- general subagent completion announcements unrelated to cron

---

# 5. Layer Explicitly Not To Modify First

Do **not** first modify:
- generic subagent completion flow
- generic task-completion internal event formatting
- generic announcement plumbing shared by non-cron flows
- main-session injected completion handling as the primary fix point

## Reason
Those layers are shared and higher blast radius.
They likely support valid non-cron completion behavior that should not be risked during a minimal repair.

The principle is:

> fix the earliest cron-specific routing decision, not the broad shared completion ecosystem.

---

# 6. Behavioral Policy of the Fix

## Desired behavior after patch
For eligible business cron jobs:
- completion should no longer re-enter the main assistant conversation by default
- the final plain-text output should be delivered directly to the external destination
- the main session should not be used as a rewriting bridge for these jobs

## Desired behavior retained
For non-eligible or ambiguous cases:
- existing announce/completion semantics remain unchanged

---

# 7. Acceptance Criteria

The patch should only be considered successful if all of the following hold.

## 7.1 Delivery behavior
- eligible business cron jobs no longer produce a main-session completion rewrite step before user-visible delivery
- the visible delivery reaches the correct external target directly

## 7.2 Main-session isolation impact
- automatic business-report output no longer increases main-session conversation load through injected completion handling
- main-session pollution from these jobs drops materially

## 7.3 Safety / compatibility
- non-cron subagent completion behavior remains unchanged
- ambiguous or out-of-scope cron announce cases still use prior behavior
- no duplicate send regression is introduced

## 7.4 Symptom reduction
During observation, the following should decline:
- cron-result entanglement with main-session flow
- repeated or fallback-driven outward正文 after main-session overload
- automatic-report contribution to main-session context pressure

---

# 8. Rollback Conditions

Rollback should be triggered if any of the following appear:
- business cron jobs stop reaching the user reliably
- direct delivery bypass skips required formatting or destination semantics
- valid non-target cron announce behavior regresses
- delivery duplication or silent-drop behavior increases

## Rollback method
Rollback should restore the prior cron announce routing for the narrowed branch only.
Do not mix rollback with broader runtime behavior changes.

---

# 9. Observation Window After Change

Recommended observation window:
- **72 hours**

## Observe for
- whether eligible cron jobs still re-enter main session
- whether user-visible delivery remains correct
- whether duplicate or fallback-linked outward messages decline
- whether main-session load symptoms reduce during automatic-report windows

---

# 10. Remaining Pre-Implementation Decisions

The implementation is now narrow enough, but a few decisions still need explicit confirmation before coding.

## 10.1 Exact scope condition
Choose the safest first condition set, likely based on:
- cron-job path
- explicit external `channel` + `to`
- finalized plain-text output
- no structured/thread-bound dependency

## 10.2 Reuse of existing direct-send path
Implementation should prefer reusing an existing direct-delivery helper/path rather than inventing a new send path.

## 10.3 Product-semantics guardrail
Confirm whether any intended product behavior explicitly depends on these cron jobs being rewritten by the main assistant before delivery.
If no such dependency exists, the bypass is safer.

---

# 11. Implementation Recommendation

## Recommended next step
Proceed to a small scoped implementation plan that says:
1. exact branch condition
2. exact cron-only bypass path
3. exact rollback hook
4. exact acceptance-test sequence

This should be the next document or coding step — not another broad investigation pass.

---

# 12. One-Line Summary

> The minimal fix should be implemented at the **cron-specific announce routing decision**, where eligible business cron jobs can be sent directly to the user instead of being relayed back into the main assistant session.
