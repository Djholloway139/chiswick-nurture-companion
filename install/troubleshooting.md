# If something fails

Tell Claude exactly which check failed, without including passwords, keys or clinical data.

- **Git missing:** install Git for Windows with Git Bash, or ask IT for Mac command line tools. Restart Claude Code.
- **Key missing or refused:** enter your own key outside chat with control paused. Restart the app. Ask your administrator about personal key access or permissions. Never let Claude inspect the variable or a profile.
- **Wrong workspace or person:** stop before any change and sign in to your own workspace. Discovery alone cannot verify identity.
- **Chrome missing:** install the official extension in your own Chrome and sign in. In Claude Desktop, open Settings, then Customize, then Connectors. Find Claude in Chrome, choose Configure and turn it on. Then ask Claude to check it can see a safe Nurture page in your signed-in Chrome. If it fails, ask IT to start the CLI from this folder with `claude --chrome` and check `/chrome`. Your subscription or organisation may restrict it.
- **Page discovery unavailable:** open the requested page yourself. Claude must not invent the route.
- **Codex skills unavailable in this folder:** Claude Code can continue because it reads .claude/skills directly. Codex users must stop and follow install/codex.md. Use a local folder outside OneDrive and network drives, as the install sentence picks. Do not enable Administrator mode or accept duplicate copies as a fix.
- **Update skipped:** continue with the current version after Claude explains the warning. Check again on a new session. A daily check records its last attempt, so it does not repeatedly fetch while offline. Repeated lock or origin warnings need Dan. Never remove a populated lock yourself.
- **Startup blocked or update applied:** restart Claude Code with a new session. The prompt guard blocks missing, interrupted or failed startup and updates that need a restart. A resumed old session cannot clear that state. Repeated failure needs Dan.
- **Unknown write outcome:** inspect the saved record before retrying. A lost reply can follow a successful change.
- **Failure comment failed:** Claude must say the failure could not be recorded. Add the proposed safe comment yourself or agree a pending personal note. Successful reads and writes need no extra result comment.

If `/help` shows Claude help, use `/nurture-help` for this kit. Use `/setup` for this kit's doctor; Claude also has its own built-in doctor.

Windows, live MCP permissions and Chrome installation must be checked on Bela's actual machine. Offline tests cannot prove those work.
