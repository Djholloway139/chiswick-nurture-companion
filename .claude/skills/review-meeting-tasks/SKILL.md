---
name: review-meeting-tasks
description: Review tasks proposed from a meeting, with a separate chat confirmation before confirming, editing and approving, or rejecting each item.
---
## Task
Help a person decide on meeting proposals. Never make the decision for them or approve a batch.

## Method
For each step use its listed, permitted tool first, otherwise its Chrome path. On refusal explain the reason, offer Chrome and wait for yes. A failed step stops and follows `guides/recording.md`. Do not use another account or status write to bypass review.

1. `list_tasks` with `status: "any"`, `include: "stages,review"`, `limit: 50` can suggest candidate proposals. It cannot return a complete meeting-only queue. Open Chrome `/tasks`, select **Task Review**, and inspect each proposal's source, meeting context, proposed owner, due date and actions. A list of 50 is potentially incomplete; say so and use the queue. Do not call a task meeting-derived unless its displayed source supports that.
2. Use `get_task` for details if helpful, but inspect the proposal card in **Task Review** for its review controls and source. Present one item with its effects. Ask the person to choose confirm, edit and approve, or reject for that named item in chat. No tool currently performs proposal review. Never use `update_task` to change a pending proposal's status. No bulk **Approve all** or **Reject all**.
3. After the person confirms that specific item, click its **Confirm** in Chrome. If a **Link to audit cycle** prompt appears, explain the proposed link and ask which cycle the person intends before proceeding. Do not create or guess a cycle. If it exposes reviewer, deferral, attestation or closure authority, hand control back.
4. For changes, open that proposal's **Edit**. Show and confirm the intended **Title**, **Priority**, **Due**, **Assignee** and **Description**, or **Event summary** when shown. Review any proposed actions as part of confirmation. Fill only approved changes, then **Save and approve** after the person confirms this particular edited item in chat. Stop on an unfamiliar category or unavailable required value.
5. To reject, obtain that item's chat confirmation and optional reason, click **Reject**, enter **Reason (optional)** in **Decline this proposed task?**, then **Decline task**. Record the result using its task ID even when it disappears from the queue. If the rejected task cannot be opened to comment, explain that recording is blocked and offer the safe note text for the person.
6. Verify the actual result in the queue and task. Use `comment_on_task`, or the task's **Notes**, **Add a note**, **Add note**, following `guides/recording.md`. Say what the person decided and what Claude clicked. Ask about the next item separately.

## Requirements
Claude in Chrome and access to the person's meeting proposals. Browser review is the working path today. Desktop control is only for a native app the person names, never for browser review or visible clinical records.

## Reference files
`CLAUDE.md`; `guides/recording.md`; `.claude/skills/my-tasks/SKILL.md`.

## Result
List each proposal's confirmed decision, verified state and result note. Name anything still awaiting the person's decision or blocked.

## Tools and integrations
Nurture MCP: `list_tasks`, `get_task`, `comment_on_task`. Chrome: `https://app.nurtureoutreach.com/tasks`, **Task Review**. Review transitions use Chrome only.
