# MINIMAL_FIX_PATCH_CONDITION_ADDENDUM_v1

> 目的：补足 `MINIMAL_FIX_IMPLEMENTATION_PLAN_v2.md` 中对“eligible for direct bypass”条件的收紧定义，避免把 announce 路径中承担的结果收口语义一起误切掉。

---

# 0. Why This Addendum Exists

The latest pre-coding confirmation changed one important assumption:

> The current announce path is not only transport/routing.
> It also appears to bundle some finalization semantics.

That means the first patch cannot safely use a broad rule like:
- all cron announce deliveries should bypass relay

Instead, the patch must use a narrower rule:

> only cron outputs that are already sufficiently final for direct external delivery should bypass the announce/completion-relay path.

---

# 1. Main Risk To Guard Against

If bypass is applied too early or too broadly, direct delivery may send:
- interim text
- not-yet-settled descendant output
- raw synthesized text that was previously rewritten before user delivery
- text that should have been suppressed under `NO_REPLY`-style semantics

So the patch must preserve this principle:

> **Do not bypass announce when announce is still providing necessary result-finalization behavior.**

---

# 2. Narrow Eligibility Rule

A cron result should be considered eligible for direct bypass only when **all** of the following are true.

## 2.1 Source and scope
- the source is a cron job
- the job is in the explicitly targeted first-batch business-report set

## 2.2 Delivery explicitness
- `delivery.channel` is explicitly present
- `delivery.to` is explicitly present
- routing is unambiguous

## 2.3 Output finalization confidence
- the output is already a finalized plain-text user deliverable
- there is no sign that further assistant-session rewrite is expected
- there is no dependency on downstream settle/wait logic for additional child output

## 2.4 Semantics safety
- no structured payload dependency is required
- no thread-binding dependency is required
- no product requirement depends on assistant-mediated voice rewriting for this job
- no `NO_REPLY`-style suppression behavior is needed for the final output state

## 2.5 First-patch practical interpretation
In practice, this means:
- only use bypass for jobs whose final artifact is already intentionally written as the final user-facing message
- do not use bypass for jobs whose result still relies on agent-side completion mediation

---

# 3. First-Batch Allowed Set

The allowed first-batch set should stay extremely narrow.

## Candidate set
- `daily-comprehensive-briefing`
- `end-of-day`
- `weekly-review`

## But even inside this set
Membership in the set is **not sufficient by itself**.
The job must also satisfy the finalization-confidence conditions above.

---

# 4. First-Batch Exclusion Rules

Do **not** use direct bypass yet for any cron output where one or more of the following are true:

- the output may still be interim
- descendant subagent completion/settling may still matter
- final wording is expected to be rewritten by assistant-session handling
- the output shape is not plain text
- target routing is ambiguous
- thread semantics matter
- suppression behavior might change the correct final action

If any of the above are uncertain, default to:

> keep existing announce/completion behavior

---

# 5. Operational Decision Rule

## Safe bias
When certainty is incomplete, bias toward:
- keeping announce behavior
not toward:
- forcing direct bypass

The patch should optimize for **low blast radius**, not maximum bypass coverage.

---

# 6. Patch Branch Guidance

## Recommended branch behavior
The bypass condition should be treated as:
- a narrow allowlist condition
not:
- a broad default with exclusions added later

That means the first patch should read conceptually as:

1. Is this a targeted cron job?
2. Is destination explicit and unambiguous?
3. Is output already final plain text?
4. Is there no announce-specific semantic still needed?
5. If all yes → direct delivery
6. Otherwise → keep existing announce path

---

# 7. Acceptance Criteria Addendum

The patch should now be judged by these additional criteria:

## 7.1 No premature delivery
- direct bypass must not cause interim or not-yet-settled text to be sent

## 7.2 No voice/finalization regression
- targeted jobs must still read like intended final user-facing messages

## 7.3 No suppression regression
- bypass must not cause messages to be sent that previously would correctly have been suppressed

## 7.4 Narrow blast radius preserved
- uncertainty should preserve announce behavior rather than expanding bypass behavior

---

# 8. Coding Readiness Judgment

## Current judgment
After adding this condition layer, the project is **closer to coding-safe**, but not yet “blindly patch now” safe.

## What must be true before coding
Before editing, the coder should be able to answer:
- what exact observable condition implies “output already final”
- what exact local signals imply no announce-side finalization is still needed
- whether the three targeted jobs currently satisfy those signals consistently

If those answers are still only conceptual, do one more narrow source/log confirmation pass before patching.

---

# 9. Recommended Next Step

The next step should be one of the following:

## Option A — final narrow confirmation before coding
Use when:
- exact code signals for “already final” are still not explicit enough

## Option B — coding step with strict narrow allowlist
Use when:
- the implementation can safely hardcode a first-pass allowlist for the 3 known business jobs
- and preserve announce for everything else

The safer default is:
> **narrow allowlist first, then expand only after observation**

---

# 10. One-Line Summary

> The first direct-bypass patch should be an **allowlist-style narrow cron repair** that only bypasses announce when destination is explicit, output is already final, and no announce-side finalization semantics are still needed.
