# OpenClaw Session Policy

Updated: 2026-03-10

## Goal
Keep the main Boss chat clean, reduce context bloat, and prevent maintenance work from contaminating normal delegation flow.

## Session classes

### 1. Main session
Use for:
- Boss instructions
- decisions
- short planning
- short answers and summaries

Avoid in main session:
- deep maintenance logs
- long-running troubleshooting transcripts
- repeated raw diagnostics
- large implementation traces

### 2. Isolated maintenance execution
Use by default for:
- OpenClaw maintenance
- troubleshooting
- inspection
- repair validation
- system diagnosis

### 3. Task-specific analysis context
Use when work becomes long, technical, or document-heavy.
Examples:
- architecture review
- incident analysis
- large code investigation

## Reset / split triggers
If any of the following happens, split work out of the main session:
- maintenance details start dominating the conversation
- repeated logs / stack traces appear
- the task spans many diagnostic steps
- the user explicitly asks to avoid context pollution
- there are signs of timeout, lock conflict, or context bloat

## Operating rules
- Do not keep raw maintenance detail in the main session unless the Boss asks.
- Summarize findings back into the main session in executive form.
- Prefer concise status reports: state, evidence, action, conclusion.
- When a session becomes noisy, create a clean task boundary rather than continuing to accumulate context.

## Practical policy for Thunder
- Boss chat = executive surface
- maintenance = isolated work surface
- final report = concise executive summary back to Boss
