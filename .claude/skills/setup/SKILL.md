---
name: setup
description: Check setup, doctor and live coverage for every Nurture command.
---
# /setup

Read AGENTS.md first. Use live discovery, guides/browser.md and guides/recording.md throughout.

Run `bash scripts/doctor.sh`. It uses tools/list only, never a write probe. Show the installed Claude Code version. The prompt hook needs Claude Code 2.1.295 or later for fail-closed hook errors, verified in local documentation and the 2.1.296 bundle; see guides/hook-contract.md. Verify the actual prompt block, project skills and server ask rules on Bela's machine before saying setup is ready.

Inspect the live tool list and each relevant description/schema. Discover a non-secret workspace/person identity read when present; otherwise have Bela verify his workspace and himself in Chrome through get_tutorial. Never infer identity or effective permissions from discovery. Do not probe writes to test access.

For every companion command, report one of: available (state verified tool or browser route and any untested write), not allowed for this key (an actual refusal), not in Nurture yet so browser fallback (the capability is absent), offline, unknown. A listed tool with untested access is unknown. For missing or refused capabilities, separately check and report Chrome readiness. A command with mixed coverage must show its gaps. Enumerate the skill directories for the command roster; it is a job roster, not a Nurture tool inventory.

Claude in Chrome is not part of set-up. Report it as ready, or as not set up yet and needed only for browser fallback. When a job first needs it, walk him through guides/browser.md set-up. Check the page registry is reachable, skills appear, Nurture calls prompt, and personal folders are ignored. If the doctor reports the key missing, say: "A small box will pop up. Paste your Nurture key into it and click Save. I can't see what you type." Then run `bash scripts/save-key.sh`. On SAVED, tell him to start a new session in this folder with **+ New** and say **set me up** again, because the Nurture connection reads the key when a session starts. If he has no key, tell him to ask Dan.

Confirmation: checks are reads and need no tracking task or recording. Explain check failures plainly. Ask before a repair; verify and say its saved result. Record only failed or partial writes under guides/recording.md. Do not change settings or install software. Read install/troubleshooting.md for next steps.

Reads need no tracking task or recording. Read back every write and say its result plainly; record only failed or partial writes as task comments under guides/recording.md.
