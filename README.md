# thunder-workspace

Operational workspace for Thunder / OpenClaw.

## What this repo contains
- governance and execution documents
- runbooks and incident notes
- automation scripts and cron-related helpers
- operational tooling for the local OpenClaw setup

## What is intentionally kept out of Git
This repository does **not** track local runtime state or sensitive/local-only artifacts, including:
- `memory/`
- `.openclaw/`
- runtime logs
- temporary backups
- local state files

## Notes
This repo is meant to keep the durable, shareable parts of the workspace under version control while leaving machine-local runtime data on the host.
