# Nurture companion for Bela

This kit helps you work with your Nurture tasks, documents, reports and audits. You confirm each change. Accepting a review and closing an audit stay with you.

Start with [Windows installation](install/windows.md) or [Mac installation](install/mac.md). The [install sentence](install/INSTALL-SENTENCE.txt) asks Claude to download the kit safely. Use your own Claude account and your own signed-in Chrome. Never put a key in chat.

Once the folder is open, say **set me up** or use `/setup`.

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

The kit discovers what Nurture offers each time. If a capability is missing or refused, Claude explains and uses your Chrome access after your confirmation. If Chrome or page discovery is unavailable, it asks you to open the page yourself. Some work depends on what your dashboard actually offers.

Use safe counts and summaries you prepare outside clinical systems. Never give Claude identifiable clinical data. Keep safe personal notes in `my-notes/` and requested downloads in `downloads/`. These folders are excluded from updates and Git; they are not encrypted.

Updates apply only when a new session starts. On resume or a daily check you may see **update ready, restart to apply**. Finish the current job and restart. Offline keeps the installed version. Read [update details](guides/maintenance.md).

If a check fails, follow [troubleshooting](install/troubleshooting.md). For Codex, use the separate [Codex setup](install/codex.md); the browser route described here is Claude in Chrome.

Maintainers can run `sh tests/run.sh` and `sh tests/upload.sh`. Both run offline with synthetic responses and fake transports, without Git writes.
