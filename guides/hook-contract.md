# Locally verified hook contract

No network was used for this round. The hook fields and output behaviour were checked in the local official documentation snapshot at ../r2-work/sources/hooks.md and the installed Claude Code bundle at /Users/dh/.local/share/claude/versions/2.1.296.

The snapshot documents common session_id input at line 752, command onFailure at line 456, UserPromptSubmit exit-code blocking at lines 1013-1036, and UserPromptSubmit stdin at lines 1528-1545. SessionStart cannot block. UserPromptSubmit exit 2 blocks the prompt and displays stderr. onFailure: block also blocks when a synchronous command cannot start, crashes or times out. The snapshot states that field requires Claude Code 2.1.295 or later.

The local bundle confirms:
- the common hook input schema includes session_id as a string;
- the command-hook schema includes type, command, shell, timeout and onFailure;
- the onFailure enum is continue or block and its description includes prompt blocking;
- the UserPromptSubmit handler has a blocking-message path.

These are the only hook contract features used. No unsupported decision field was added. The committed prompt hook runs the guard and daily check in one command so the check cannot run before readiness passes. Do not split them into independent hooks.

State is atomic and stored under .git/companion-startup/, keyed by a validated session ID. When no ID is supplied, a per-start slot is overwritten before work begins. Pending or absent state blocks after a timeout. Only startup mode writes last-startup.state. A new conversation ID on resume, clear or compact may initialise from a ready latest startup, then run the fetch-only resume check. Any other latest outcome creates a failed state for the new ID; a restart outcome retains the restart message. Existing failed, pending or restart states remain blocked. Restart Claude Code after an applied update; clearing the conversation alone cannot clear that requirement. Codex aliases are optional for Claude; the Codex launcher enforces its own link requirement.

The contract and shell behaviour are checked locally. Actual enforcement in Bela's desktop app remains unverified. Upgrade an older client before using the kit, and verify the block on Bela's machine.

References: [Claude hooks](https://code.claude.com/docs/en/hooks) and [Claude settings](https://code.claude.com/docs/en/settings-reference). These URLs were not fetched during this round.

Upload contract check, 15 November 2026: in the parent nurture-system source, apps/web/src/app/api/v1/docs/schemas/route.ts:37-47 serves only the generated SCHEMA_FILES entries. apps/web/src/lib/developer-docs/manifest.ts:241-297 declares that publication list, and generated.ts:51 starts its generated output. Neither publishes the Library upload byte request nor its successful queued receipt. The document row schema and the unrelated attachment input are not substitutes for those missing contracts. Live deployment was not checked. The byte helper remains disabled; no request or receipt fields are maintained in this kit.
