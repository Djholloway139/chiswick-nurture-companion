# Nurture companion

This folder gives your own Claude Code instructions for working with your Nurture tasks, Library documents, reports and audits. Results and failures are recorded on a Nurture task. You confirm changes before Claude makes them. Review and sign-off decisions stay with you.

You need the Claude Code desktop app, signed in to your own Claude account, and access to your Nurture workspace. On Windows, install Git for Windows, including Git Bash. On Mac, Git must be installed; if the doctor cannot find it, ask your IT contact to install Apple's command line tools. You do not need a GitHub account, Node, Python or a package manager.

Install the Claude in Chrome extension and sign it in to your own account. Chrome integration needs Pro, Max, Team or Enterprise. Desktop control for native apps needs Pro or Max. Your organisation may restrict these features. Without an available tool or Chrome, Claude stops and tells you what is missing. It cannot work in the background when Claude Code is closed.

Paste this one sentence into Claude Code:

> Clone https://github.com/Djholloway139/chiswick-nurture-companion.git into my Documents folder as chiswick-nurture-companion, without replacing anything already there; then tell me how to open that folder in Claude Code and say set me up. Never ask for a key in chat.

If Documents is redirected, for example to a managed drive, Claude should ask you to select your actual Documents folder. It must not replace an existing folder. Open the new `chiswick-nurture-companion` folder in Claude Code, approve trust only if you recognise this repo, and say **set me up**.

An admin gets their own key by opening Nurture at https://app.nurtureoutreach.com, then **Developers**, **API keys**, **Create key**. Use your own name in **Name**. Choose the task and document permissions you need, then **Create key**. Handle the one-time key display yourself with Claude's browser and desktop control paused. Never share an admin key with a team member. Members use Chrome only until Nurture offers personal keys; they then create their own key. Never send a key to Claude in chat.

A member without a key will see a "missing environment variable" notice for the **nurture** server. This is expected until personal keys arrive. Continue with Chrome only; do not enter a placeholder or borrow someone else's key.

On Windows, open Start, type **environment variables**, choose **Edit environment variables for your account**, then **New** under your user variables. Set the name to `NURTURE_API_KEY` and enter the key as its value yourself. Save the dialogs. If your Claude Desktop app offers environment settings for Code, you may enter that same variable there instead. Use one place. Claude must never view or screenshot the value.

On Mac, use the app's environment settings if present. Otherwise, for the standard Mac zsh shell, open your own `~/.zprofile` in a text editor with Claude's control paused. Add the line `export NURTURE_API_KEY='replace-this-yourself'`, replacing only the placeholder with your key yourself. This profile is outside this repo. If you use a different shell or need help opening the profile, ask IT. Never type the key into a chat or a Terminal command, where it could enter command history. A shell profile is not guaranteed to reach an app launched from Finder. After reopening Terminal, launch Claude Code from that environment, or use the app's environment settings. Ask IT if the desktop app still cannot see it. Claude will not write or read your profile.

Fully quit and restart Claude Code after adding the variable. Open this folder again, approve the project MCP server **nurture** when prompted, and say **set me up** again. The doctor checks presence without showing the key. When a key is available, it makes one task read to verify the key and task permission. It never prints the returned task.

When the doctor says **MISSING**, follow the fix on that line and run **set me up** again. **UNKNOWN** means the check could not be confirmed, such as when offline. Do not treat it as success. A refused key must be replaced by its owner in Nurture. A key that works but lacks task permission needs your admin to add list tasks. The doctor reports the Claude Code version as information only; this kit does not claim a known minimum version for the remaining settings. If the app has no readable CLI version, ask IT to check its bundled version.

Try saying “what's on my plate?”, “review my meeting tasks”, “find the document about this”, “file this document”, “how is the team doing this week?” or “help me complete this audit”. Use safe counts and summaries prepared outside the clinical records system. Never give Claude identifiable clinical data.

Each new session checks for updates. It waits at most eight seconds for the fetch. If an update succeeds, tracked local edits are reset. `my-notes/` and `downloads/` are kept. When Claude says **restart Claude Code to apply**, restart before doing work. If an update is skipped, Claude explains why and uses the existing instructions. The updater automatically removes an empty lock older than two minutes. Tell your administrator about repeated failures; do not delete locks yourself.

Do not edit the kit. Keep personal notes in `my-notes/` and requested files in `downloads/`. These folders are excluded from git, which does not encrypt them or protect them from your computer's backups. Store no clinical records here. Local permission rules help reduce mistakes; your own account and Nurture key permissions still govern access.

For maintainers, run `sh tests/run.sh`. The tests need only Git, Bash and standard shell utilities supplied by macOS or Git Bash. They create and remove their own test repositories in the temporary folder. They never call Nurture.
