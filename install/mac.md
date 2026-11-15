# Mac: start here

1. Before set-up, ask Dan how to get your own Nurture key. Create it yourself with Claude's control paused, then enter it in the next step. Never send the key to Dan or paste it into chat.
2. Use the app's environment settings for Code if offered, with the variable name `NURTURE_API_KEY`. Otherwise ask IT to help you open your own shell profile in a text editor. For the standard zsh shell, you personally add an export of that variable in `~/.zprofile`. Enter the value yourself, never in a Terminal command or chat. Claude must never open your profile. An app opened from Finder may not inherit it; launch the CLI from a fresh Terminal or ask IT about the app's environment.
3. Install [Claude Code](https://code.claude.com/docs/en/desktop-quickstart) and sign in to your own Claude account. If Git is missing, ask IT to install Apple's command line tools. Fully quit and restart the app after setting your variable.
4. Install [Chrome](https://www.google.com/chrome/) and the [Claude in Chrome extension](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn) in your own profile. Sign in to the extension with your own Claude account, then sign in to https://app.nurtureoutreach.com yourself. Pause Claude for passwords and clinical records.
5. Paste [the install sentence](INSTALL-SENTENCE.txt) into Claude Code. Claude picks the folder itself: `~/Nurture/chiswick-nurture-companion`. Never replace an existing folder. Codex sharing needs a hard-link-capable volume, such as local APFS.
6. Click **+ New** in the left sidebar (Cmd+N), choose the companion folder in the project folder control under the message box, and pin that session (hover over it, open its menu, choose **Pin**). Trust Dan's project only if you recognise it and allow the startup hook. Codex link failure only warns and does not stop Claude Code. A startup failure or applied update blocks prompts until you start a new session.
7. In Claude Desktop, open Settings, then Customize, then Connectors. Find Claude in Chrome, choose Configure and turn it on. Then ask Claude to check it can see a safe Nurture page in your signed-in Chrome.
8. If that connection fails, ask IT to start the Claude Code CLI in Terminal from this folder with `claude --chrome`; use `/chrome` to check its connection. Browser integration requires an eligible direct Claude subscription and your organisation's approval.
9. Approve this project's Nurture MCP server and say **set me up** or use `/setup`. Confirm your workspace, person, browser connection and that Nurture calls ask you.

Without your own key, ask Dan; do not borrow one or enter a placeholder. Use Chrome where page discovery works, or open the requested page yourself. An unknown check remains unknown until verified.

The desktop walkthrough and live connection remain unverified on your machine. See [troubleshooting](troubleshooting.md) if setup fails.
