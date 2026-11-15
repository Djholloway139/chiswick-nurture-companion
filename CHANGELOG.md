# Changes

## 1.1.0

- Install is now one message: paste the repo link and say install. The README holds the steps for Claude.
- Bela pastes his key into a private pop-up box; it is stored in the ignored .env in the companion folder. No shell profile or environment variables.
- The Nurture connection reads the key through a headers helper, so a new session connects without restarting the app.
- Claude in Chrome set-up moved out of install; the companion walks Bela through it the first time a job needs the browser.
- Removed the separate Mac and Windows guides and the install sentence.

## 1.0.0

- Added commands for every agreed job, with a browser fallback for missing capabilities.
- Put Nurture calls on ask while server safeguards are being completed.
- Kept review acceptance and audit closure with Bela.
- Removed copied product instructions, limits and error matches.
- Added safe startup updates, daily checks and shared skills for Claude Code and Codex.
- Blocked prompts after incomplete startup or an update that needs a new session.
- Made Codex link failure a warning for Claude Code and a stop for Codex.
- Clarified desktop browser setup, personal key preparation and local installation folders.
- Removed the copied byte upload adapter pending published request and receipt schemas; local uploads use Chrome.
- Removed result comments for successful reads and writes; failed or partial writes still get task comments.
