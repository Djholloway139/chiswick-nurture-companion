# Record the result

Use this procedure after every write and every failure in every skill. Before a job, identify its existing task with the person. For a document, use its linked task. If there is none, ask to create an ordinary tracking task with an agreed title and due date through `create_task`, or `/tasks`, **New task**, **Title**, **Due date**, **Create task**. Do not invent a date or create a task without consent. Keep the returned task ID. Include the proposed result comment when asking to confirm the job.

Use `comment_on_task` when listed and permitted, with that ID and `body` starting **Claude Code:**. State the action, document or requirement reference, result, and reason for a failure in plain English. Exclude secrets and identifiable clinical data. A comment can record its own posting; do not create an endless series of comments about comments. A creation comment on the new task records the task's creation as well.

Read the result back with `get_task`, or reopen the task in Chrome and check the note. Do not retry a write with an unknown outcome until you have checked whether it landed. Record partial success explicitly, for example “Claude Code: The file was uploaded. Linking it to the selected requirement failed because access was refused. The requirement remains incomplete.”

If the comment tool is absent, go to https://app.nurtureoutreach.com/tasks, open the agreed task, select **Notes**, type into **Add a note**, then click **Add note**. Confirm the note appears. If the tool is refused, first explain the refusal, offer these Chrome steps and wait for yes. A refusal does not authorise a different account, key or workspace.

If recording also fails, say “I could not record this result in Nurture” and give the safe reason. Stop. Offer the exact text for the person to add themselves, or, with consent, save it in `my-notes/` as pending. Do not say the job is fully recorded. Setup without an accessible task, an offline failure, or a safety stop can leave recording blocked. Name that limitation and do not keep retrying. Never inspect an unsafe page to reach its note composer.
