# If something fails

Tell Claude exactly which check failed, without including passwords, keys or clinical data.

- **Git missing:** install Git for Windows with Git Bash, or on Mac run `xcode-select --install`. Restart Claude Code.
- **Key missing or refused:** say **set me up**; Claude opens a private box to paste your own key. Then start a new session. Ask Dan about key access or permissions. Never paste a key into chat.
- **NOT SAVED: the key box failed:** send Dan that whole status line. It contains the first line of the box failure, without the key. `NOT SAVED: cancelled` means the box was cancelled. If no box appeared on an older release, send Dan the installed version and say that the box never opened.
- **JSON Parse error ... Unrecognized token:** send Dan the error line, the installed version and the doctor's `header helper` status lines. Release 1.1.1 uses Git's bundled shell so Windows can find Bash. Start a new companion session after the release is installed. Never run the header helper yourself or send its output, because it contains the key.
- **Wrong workspace or person:** stop before any change and sign in to your own workspace. Discovery alone cannot verify identity.
- **Chrome missing:** install the official extension in your own Chrome and sign in. In Claude Desktop, open Settings, then Customize, then Connectors. Find Claude in Chrome, choose Configure and turn it on. Then ask Claude to check it can see a safe Nurture page in your signed-in Chrome. If it still fails, tell Dan. Your subscription or organisation may restrict it.
- **Page discovery unavailable:** open the requested page yourself. Claude must not invent the route.
- **Codex skills unavailable in this folder:** Claude Code can continue because it reads .claude/skills directly. Codex users must stop and follow install/codex.md. Use a local folder outside OneDrive and network drives, as the README install steps pick. Do not enable Administrator mode or accept duplicate copies as a fix.
- **Update skipped:** continue with the current version after Claude explains the warning. Check again on a new session. A daily check records its last attempt, so it does not repeatedly fetch while offline. Repeated lock or origin warnings need Dan. Never remove a populated lock yourself.
- **Startup blocked or update applied:** restart Claude Code with a new session. The prompt guard blocks missing, interrupted or failed startup and updates that need a restart. A resumed old session cannot clear that state. Repeated failure needs Dan.
- **Unknown write outcome:** inspect the saved record before retrying. A lost reply can follow a successful change.
- **Failure comment failed:** Claude must say the failure could not be recorded. Add the proposed safe comment yourself or agree a pending personal note. Successful reads and writes need no extra result comment.

If `/help` shows Claude help, use `/nurture-help` for this kit. Use `/setup` for this kit's doctor; Claude also has its own built-in doctor.

Windows, live MCP permissions and Chrome installation must be checked on Bela's actual machine. Offline tests cannot prove those work.
