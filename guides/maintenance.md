# Maintenance and verification

VERSION is the installed release. CHANGELOG.md explains releases in plain English. Before Dan publishes, bump the version and add a section at the start of the changelog.

The updater accepts startup, resume, daily and check modes. Only startup can reset tracked files. Resume, clear/compact hooks and the daily prompt hook only fetch and announce an update. The last attempted check and pending notice are written atomically inside .git/. Offline keeps the current version. Startup and resume try again even if the daily check already ran. Fetch has a bounded wait and cannot request credentials. Every updater unsets the Nurture key before doing work.

Startup verifies the expected origin and main branch, rejects releases tracking personal folders or generated skill aliases, then resets tracked kit files. It never cleans untracked files. Safe notes in my-notes/ and downloads/ remain. After applying it prints the old/new versions and changelog sections newer than the old version, then requires a fresh Claude session so loaded instructions match. Startup records pending, ready, failed or restart inside .git/companion-startup/, keyed by the hook session ID or a per-start fallback. Ready is written atomically only after required startup steps finish. UserPromptSubmit runs the fail-closed guard before the daily fetch. A missing state, interrupted startup or restart-required release blocks the prompt through exit 2 and stderr. The prompt hook uses documented onFailure: block so a missing script or timeout also blocks. Codex linking is optional for Claude startup. A commit without a version bump is a release error for Dan to fix.

Before Bela installs, Dan must verify GitHub branch protection and two-factor sign-in for the publishing owner, as required by the approved plan. These settings were not checked offline. Releases are trusted code; this updater does not verify signatures. Do not claim deployment or client verification from local tests.

Skills are tracked only in .claude/skills/. scripts/sync-skills.sh creates ordinary hard-linked SKILL.md aliases under ignored .agents/skills/. Both names refer to the same file on one volume. It verifies identity with Bash's -ef check and fails if linking became copying. It refreshes links at startup after Git replaces source files, and removes retired aliases. There are no Git symlinks and no second file content to maintain. Claude Code reads .claude/skills directly. Link failure warns once per session and does not block Claude Code. The Codex launcher stops if links cannot be created; network drives and filesystems without hard links remain unsupported for Codex sharing.

Sources for this approach:
- Local macOS `man ln`, read during this work, confirms hard links are ordinary directory entries for the same file and cannot span filesystems. The tests verify that identity and refresh after source replacement.
- [Claude project skills and slash commands](https://code.claude.com/docs/en/skills), reviewed in the local source snapshot at ../r2-work/sources/skills.md.
- [Codex project skills](https://developers.openai.com/codex/skills/), reference URL supplied; live client discovery remains unverified offline.
- [GNU ln: hard links refer to the same file](https://www.gnu.org/software/coreutils/manual/html_node/ln-invocation.html).
- [Microsoft hard links and junctions](https://learn.microsoft.com/en-us/windows/win32/fileio/hard-links-and-junctions), the NTFS file-link mechanism, reference URL supplied offline.
- [Claude MCP server permission rules](https://code.claude.com/docs/en/permissions#tool-specific-permission-rules), local snapshot permissions.md documents the server-wide rule.
- [Claude hooks](https://code.claude.com/docs/en/hooks), local snapshot hooks.md documents startup/resume, prompt hooks and Git Bash.

The copied byte upload adapter and receipt parser have been removed. The upload entry point now fails closed without opening a file or contacting Nurture. Local-file uploads use the confirmed Chrome workflow until authoritative published request and receipt schemas can drive a transport. The source inspection for this round found neither contract in the published schema index; see guides/hook-contract.md for the local evidence.

The shell doctor retrieves tools/list without a permission probe. It reports per-command transport state. /setup then matches capabilities by live description/schema, distinguishes absent capabilities from unverified access, checks browser readiness and verifies non-secret workspace/person identity. Until Nurture supplies effective access and identity metadata, some statuses remain unknown. Never classify a listed write as verified usable by executing it as a test.

Run sh tests/run.sh and sh tests/upload.sh before publication. CI is manual and uses fake transports on Windows and Mac. The offline suites do not write Git, access the network, inspect credentials or prove real browser actions. A drift scan rejects copied product rules; its mutation tests prove the targeted forbidden categories are detected. It is a guardrail, not proof against every possible paraphrase.
