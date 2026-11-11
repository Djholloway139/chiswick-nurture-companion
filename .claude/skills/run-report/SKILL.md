---
name: run-report
description: Read team progress, completed and overdue work and a weekly summary in Nurture with clear date ranges and limits.
---
## Task
Explain the team's work for the period the person requests, with supporting task links and clear limits.

## Method
For each step use the named tool if listed and permitted, otherwise the Chrome path. On refusal say what was refused, offer Chrome and wait for yes. A failed step stops and follows `guides/recording.md`. Do not infer that a failed report contains zero work.

1. Agree the date range, workspace timezone and team or person. Use `get_workspace_report` if listed, with the current schema and explicit period. Check its scope and completeness before reporting. There is no working MCP workspace report today. Do not substitute sales metrics or guess a tool named after a screen.
2. In Chrome open `/reports`, **Overview**. Select **This week** for the current week, or another displayed period matching the request. Read **Tasks overdue** and its displayed task counts. These are workspace metrics, not necessarily filtered to one teammate or the report period; read their displayed definition and do not imply otherwise. Open `/tasks` for supporting work: clear unrelated filters, use **Overdue**, and read task assignees. Never use **My tasks** to describe the entire team.
3. To review completed work, use `/tasks`, **Show completed**, set **Completed from** and **Completed to** to the agreed calendar bounds, and use the **Assignee** filter for a named person if requested. Open relevant task titles to inspect actual completion. State any cap or missing row warning; `list_tasks` is capped at 50 and has no cursor, so it cannot establish a full historical total. Do not add different stage and parent counts together as separate projects.
4. In `/reports`, select **Agent Team**, read **Weekly summary** and the available agent report cards. These describe agent reports; label them separately from human task progress. If no weekly summary exists, say it is unavailable and summarise the verified task data for the agreed week. Do not enable reports, apply proposals, change schedules or email a report as part of reading it.
5. Explain progress, completed work, overdue items and the next work needing attention, with links and the period used. Keep human task counts separate from agent metrics and distinguish current overdue state from completions in the selected week. If data is bounded or absent, identify that precisely.
6. If saving the summary was requested, show its proposed `Claude Code:` task note and ask for confirmation. Use `comment_on_task`, or `/tasks`, open the agreed reporting task, **Notes**, **Add a note**, **Add note**. Record every report failure there too following `guides/recording.md`. Do not create a new reporting task without agreeing its title and due date.

## Requirements
Permission to read the requested team data, an agreed period and a task for any saved result or failure. Desktop control is only for a native app the person names for a requested export, never for browser navigation or while clinical records are visible.

## Reference files
`CLAUDE.md`; `guides/recording.md`; `.claude/skills/my-tasks/SKILL.md`.

## Result
A dated, attributed summary with task links, source scope, limits and recorded notes when saved or failed.

## Tools and integrations
Nurture MCP: future `get_workspace_report`; `list_tasks`, `get_task`, `comment_on_task`. Chrome: `https://app.nurtureoutreach.com/reports` and `/tasks`.
