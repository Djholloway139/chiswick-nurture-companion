# Windows: start here

1. Before set-up, ask Dan how to get your own Nurture key. Create it yourself with Claude's control paused, then enter it in the next step. Never send the key to Dan or paste it into chat.
2. In Windows, search for **Edit environment variables for your account**. Create a user variable named `NURTURE_API_KEY` and enter the value yourself. Save, fully quit Claude Code if it is open, and reopen it after installation. If your app offers environment settings for Code, use those instead of a second copy. Claude must never view or screenshot the value.
3. Install [Git for Windows](https://git-scm.com/download/win). Keep Git Bash and the standard command line tools enabled. Use Windows directly; this guide does not use WSL.
4. Install [Claude Code](https://code.claude.com/docs/en/desktop-quickstart) and sign in to your own Claude account. Your organisation must allow Claude Code and its browser integration.
5. Install [Chrome](https://www.google.com/chrome/) if needed. In your own Chrome profile, install the [Claude in Chrome extension](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn). Sign in to the extension with your own Claude account. Open https://app.nurtureoutreach.com and sign in yourself. Keep password entry and clinical records off Claude's screen.
6. Use a local folder outside OneDrive and network drives. If your Documents folder is synced to OneDrive, ask Dan which folder to use before downloading. Paste [the install sentence](INSTALL-SENTENCE.txt) into Claude Code. Stop if the destination exists. Codex sharing additionally needs a local NTFS volume that supports hard links.
7. Open the companion folder as the project in Claude Code. Trust it only if you recognise Dan's repository. Allow the supplied startup hook. It checks updates; Codex link failure only warns and does not stop Claude Code. A startup failure or applied update blocks prompts until you start a new session.
8. In Claude Desktop, open Settings, then Customize, then Connectors. Find Claude in Chrome, choose Configure and turn it on. Then ask Claude to check it can see a safe Nurture page in your signed-in Chrome.
9. If that connection fails, ask IT to start the Claude Code CLI in Git Bash from this folder with `claude --chrome`; `/chrome` checks its connection. Sign in interactively to your Claude account. A Nurture key is separate from Claude sign-in.
10. Approve this project's Nurture MCP server and say **set me up** or use `/setup`. Check the workspace and person are yours, Chrome is connected and the commands appear. Each Nurture call should ask you. Do not approve an option that skips future approvals.

If you cannot obtain your own key, tell Dan. Do not enter a placeholder or borrow one. Use Chrome where page discovery is reachable, or open the requested page yourself.

The desktop walkthrough and live connection remain unverified on your machine. See [troubleshooting](troubleshooting.md) if any check is missing or unknown.
