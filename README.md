# Nurture companion for Bela

This kit helps Bela work with his Nurture tasks, documents, reports and audits through Claude Code. He confirms each change. Accepting a review and closing an audit stay with him.

## How Bela installs it

Open a new session in Claude Code, paste this and send it:

> Install https://github.com/Djholloway139/chiswick-nurture-companion

## Install steps (for Claude)

Bela is not technical. Explain each step in one plain sentence, do everything a computer can do, and only stop when he has to click something. Never ask for his key in chat, never read or print it, and never handle passwords or clinical data. If a step fails, say plainly what failed and what to send Dan; do not work around it.

1. **Git.** Run `git --version`. If Git is missing, tell him how to install it (Windows: [Git for Windows](https://git-scm.com/download/win), keeping Git Bash; Mac: run `xcode-select --install` and click Install in the box that appears), then wait.
2. **Folder.** Use `~/Nurture/chiswick-nurture-companion` on Mac and `%USERPROFILE%\Nurture\chiswick-nurture-companion` on Windows. If that is inside OneDrive (the `OneDrive`, `OneDriveConsumer` or `OneDriveCommercial` folders) or on a network drive, use `C:\Nurture\chiswick-nurture-companion` instead. If the folder already exists, do not replace or delete it: stop and tell him to send Dan the full path.
3. **Download.** Create the `Nurture` folder if needed, then run `git clone https://github.com/Djholloway139/chiswick-nurture-companion.git chiswick-nurture-companion` inside it. Change nothing anywhere else.
4. **Key.** Run `bash scripts/save-key.sh` from the downloaded folder. Tell him first: "A small box will pop up. Paste your Nurture key into it and click Save. I can't see what you type." It prints only `SAVED` or `NOT SAVED` with a reason. If he doesn't have his key yet, tell him to ask Dan for it; set-up will offer the box again later.
5. **Hand over.** If you have a tool that starts a new Claude Code session in another folder, start one in the companion folder with the message **set me up**, and tell Bela to open it, click **Trust** if asked, and pin it. Otherwise give him these steps with the folder's full path filled in:
   1. Click **+ New** in the left sidebar (Ctrl+N on Windows, Cmd+N on Mac).
   2. Under the message box, click the folder control and choose the companion folder (full path).
   3. If Claude asks whether to trust the folder, click **Trust**.
   4. Type **set me up** and send it.
   5. Pin the session: hover over it in the left sidebar, open its menu and choose **Pin**. Use that pinned session whenever you work in Nurture.

Nothing else is needed at install time. Claude in Chrome is only needed when a job falls back to the browser; the companion walks Bela through it then.

## Commands

| Command | Your job |
| --- | --- |
| /setup | Check connection, identity and what works |
| /my-tasks | Due and overdue work; read, edit, comment, complete ordinary tasks |
| /create-task | Create, assign or reassign |
| /split-task | Create replacement tasks, then cancel the original with links |
| /review-meeting-tasks | Approve, edit then approve, or reject meeting proposals |
| /calendar | Task deadlines and audit dates |
| /run-report | Completed, overdue, team figures and weekly summary |
| /find-document | Search, read and download originals |
| /file-document | Upload, type, metadata and replacement |
| /rollback-document | Restore a replaced document through Chrome when offered |
| /complete-audit | Read the pack, prepare answers, attach evidence, return a stage or defer with a reason |
| /evidence-pack | Prepare and download governance or appraisal evidence |
| /nurture-help | What can I do? |

The kit discovers what Nurture offers each time. If a capability is missing or refused, Claude explains and uses Bela's Chrome after he confirms. Use safe counts and summaries prepared outside clinical systems; never give Claude identifiable clinical data. Safe personal notes go in `my-notes/` and requested downloads in `downloads/`. These folders and the key file `.env` are excluded from Git and updates; they are not encrypted.

Updates apply when a new session starts. If you see **update ready, restart to apply**, finish the current job and start a new session. See [update details](guides/maintenance.md) and [troubleshooting](install/troubleshooting.md). Codex users follow [Codex setup](install/codex.md).

Maintainers can run `sh tests/run.sh` and `sh tests/upload.sh`. Both run offline with synthetic responses and fake transports, without Git writes.
