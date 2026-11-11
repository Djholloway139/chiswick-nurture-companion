---
name: my-tasks
description: Find my open, due and overdue tasks, open one, create, assign, edit, comment or mark ordinary work done in Nurture.
---
## Task
Help the signed-in person with their own work. Put overdue work first, including assigned project and audit stages. Do not claim a bounded list is complete.

## Method
For every step, use the named MCP tool if listed and permitted. If absent, use the named Chrome path. If a call is refused, explain what Nurture refused in plain English, offer that step's Chrome path, and wait for yes. A failed step stops and follows `guides/recording.md`. Confirm each write and its result note before acting.

1. Establish whose work this is. There is currently no permitted identity tool returning the person's user ID. `get_content_context` returns workspace context, not a user ID, and is outside this kit's permissions. Never infer identity from a name, admin key, task owner or UUID found in a file. Use Chrome at `/tasks`, clear unrelated filters, and select **My tasks**. This page resolves the signed-in user itself. If a future permitted identity source explicitly verifies the signed-in person's user ID, use it. Do not ask for a key or inspect browser tokens to find identity.
2. With a verified user ID, call `list_tasks` with `status: "open"`, `assignee: "user:<verified-uuid>"`, `include: "stages"`, `limit: 50`. Never use its default any-assignee list for “mine”. If 50 rows return, say “This list may be incomplete because the tool stops at 50” and continue in Chrome `/tasks`, **My tasks**. In Chrome, **Overdue** shows overdue work, then switch it off to include all open work; **Due today** narrows today's work. Inspect all displayed results and any page navigation or limit notice. Include matching stages inside their projects. If the screen itself limits results, say so rather than claim completeness.
3. Sort overdue first, then due soon, using the workspace date and timezone. A date-only deadline becomes overdue after that day ends in that timezone. Chrome shows the due facts; do not guess a timezone. Open a task with `get_task` and its ID, or click its title on `/tasks`. The tool maps a stage ID to its parent and shows only the last 20 notes and document names. Open the stage in Chrome to inspect its exact state, instructions and full notes.
4. To edit ordinary work, read the current task, show the proposed fields, confirm, then use `update_task` with only those fields. Use `title`, `description`, `priority`, `due`, `labels` or `assignee` according to the live schema. In Chrome click the task's title to edit it; use **Description**, **Due date**, **Assignee** or **Priority**. These fields can save when focus leaves them, so confirm before typing or picking an option. Use **Save** for Description or **Save & Close**. Verify the changed values before recording them.
5. To assign, use `update_task` only when the target user ID has been verified by a permitted directory source. Do not guess an ID from a name. Otherwise open the task in Chrome, select **Assignee**, find the intended person in its picker, confirm the match and select them. Record the assignment.
6. To add a comment, use `comment_on_task` with task ID and the approved body. In Chrome select **Notes**, enter **Add a note**, then **Add note**. Use a `Claude Code:` prefix for your own result notes. Never use **Instruct the agent** as a comment substitute.
7. To finish an ordinary task, confirm its work is complete, then use `update_task` with `status: "done"`. In Chrome open the task and select **Complete Task**, reviewing its completion dialog before the final confirmed click. If completion would execute attached actions, pause and explain those actions first. If it is an audit, review, closure or attestation task, use `complete-audit` and hand control to the person. Never use status changes to bypass those decisions.
8. To create, agree **Title**, **Description**, **Priority**, a due day or exact time and timezone, and any intended assignee. Call `create_task` with the live schema; it requires `title` and `due`. Creation does not assign someone, so a separately confirmed `update_task` may be needed. In Chrome select **New task**, fill **Title**, **Description**, **Assignee**, **Priority** and **Due date**, then **Create task**. Verify the new task and record both writes on it. Never retry after an ambiguous result until checking for a duplicate.

## Requirements
Signed-in Nurture workspace and either permitted MCP tools or Claude in Chrome. Use desktop control only if the person names a native app needed for an accompanying file operation. Never use desktop control for the browser or while clinical records are visible. Follow `CLAUDE.md` and `guides/recording.md` throughout.

## Reference files
`CLAUDE.md`; `guides/recording.md`; `.claude/skills/complete-audit/SKILL.md`.

## Result
Show overdue, due and upcoming work with task links, named gaps and list limits. State each confirmed change and whether its result note was verified.

## Tools and integrations
Nurture MCP: `list_tasks`, `get_task`, `create_task`, `update_task`, `comment_on_task`. Chrome: `https://app.nurtureoutreach.com/tasks`.
