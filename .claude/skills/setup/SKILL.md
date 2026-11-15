---
name: setup
description: Check setup, doctor and live coverage for every Nurture command.
---
# /setup

Read AGENTS.md first. Use live discovery, guides/browser.md and guides/recording.md throughout.

Run `bash scripts/doctor.sh`. It uses tools/list only, never a write probe. Show the installed Claude Code version. The prompt hook needs Claude Code 2.1.295 or later for fail-closed hook errors, verified in local documentation and the 2.1.296 bundle; see guides/hook-contract.md. Verify the actual prompt block, project skills, server ask rules and Claude in Chrome on Bela's machine before saying setup is ready.

Inspect the live tool list and each relevant description/schema. Discover a non-secret workspace/person identity read when present; otherwise have Bela verify his workspace and himself in Chrome through get_tutorial. Never infer identity or effective permissions from discovery. Do not probe writes to test access.

For every companion command, report one of: available (state verified tool or browser route and any untested write), not allowed for this key (an actual refusal), not in Nurture yet so browser fallback (the capability is absent), offline, unknown. A listed tool with untested access is unknown. For missing or refused capabilities, separately check and report Chrome readiness. A command with mixed coverage must show its gaps. Enumerate the skill directories for the command roster; it is a job roster, not a Nurture tool inventory.

Check that Bela's own Chrome is connected, the page registry is reachable, skills appear, Nurture calls prompt, and personal folders are ignored. If he has no key, explain the MCP notice and use the browser if page discovery is reachable; otherwise hand over navigation to him. Only Bela enters secrets outside chat with control paused.

Confirmation: checks are reads and need no tracking task or recording. Explain check failures plainly. Ask before a repair; verify and say its saved result. Record only failed or partial writes under guides/recording.md. Do not change settings or install software. Read install/troubleshooting.md for next steps.

Reads need no tracking task or recording. Read back every write and say its result plainly; record only failed or partial writes as task comments under guides/recording.md.
