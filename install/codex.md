# Codex users

Bela's delivery path is Claude Code with Claude in Chrome. The same AGENTS.md and skill files also serve Codex. Claude's settings and hooks do not enforce Codex permissions, and Claude in Chrome is not assumed to be a Codex browser connector.

From Git Bash on Windows or Terminal on Mac, open this folder and start a new session with:

```sh
bash scripts/start-codex.sh
```

This applies startup updates and creates local hard links before Codex reads skills. If linking fails, the launcher stops. Use a local folder outside OneDrive and network drives on a hard-link-capable volume; do not proceed with missing skills. Claude Code itself can continue without these aliases. To resume, use `bash scripts/start-codex.sh resume`; this only checks for updates and prepares links before launching the resumed session. Never apply a startup reset during a resumed job. During a long Codex session, run `bash scripts/update.sh daily` at most once a day. Claude's automatic hooks do not run in Codex.

An IT helper can connect the Nurture server using:

```sh
codex mcp add nurture --url https://app.nurtureoutreach.com/mcp --bearer-token-env-var NURTURE_API_KEY
```

This stores the variable name, not its value. The launcher reads the value from the `.env` that `bash scripts/save-key.sh` writes, unless it is already set. This command's options were checked against the locally installed Codex CLI help; client behaviour on Windows remains unverified. Keep approval prompts enabled. AGENTS.md requires confirmation of every change, saved-record read-back and plain reporting in Codex too. Reads need no recording; failed or partial writes need a task comment. Do not assume Claude's server ask rule or shell deny rules apply to Codex.

Use Codex's skills picker or ask for the named job. Confirm discovery of the local skill files before using them. If a browser fallback is needed, hand the job to Claude Code with Claude in Chrome in Bela's signed-in session, or have Bela do it himself. Do not claim a missing connector can automate the browser.

[Official Codex skills documentation](https://developers.openai.com/codex/skills/) is the client reference. It could not be fetched under this task's no-network rule; local file visibility is tested separately from client discovery.
