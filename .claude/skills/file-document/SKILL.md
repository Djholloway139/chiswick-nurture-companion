---
name: file-document
description: Upload a safe document to Nurture and choose its live type, subject, date, governance area and topic tags with confirmation.
---
## Task
File a safe document correctly, using live choices and preserving human attestations.

## Method
For every step use the named tool if listed and permitted, otherwise its Chrome path. On refusal explain it, offer that Chrome path and wait for yes. A failed step stops and follows `guides/recording.md`. Confirm every write, including its note, before acting.

1. Identify the local file and the task it supports. The person confirms it contains no identifiable clinical data before Claude reads or uploads it. Do not assume a filename proves safety. Read `guides/filing.md` and retrieve live choices with `list_document_types` and `get_governance_vocabulary` if listed. Today use Chrome `/documents`, **Upload document**, **Group**, **Document type**, and `/settings`, **Document types**; close unsaved lookup dialogs. Read governance choices from a supported file's **Edit classification**, **Governance area**, **Topics**. Ask when two choices fit.
2. Show the proposed file, type, description, subject, document date, area, topics and associated task. If `upload_document` is listed, inspect its schema and use it only with a safe local-file transfer capability. Never put file bytes or a key in a prompt, tool argument, script or chat. This kit has no direct upload script today. If the listed tool does not offer a usable safe transfer, explain that limit, offer Chrome and wait for yes. In Chrome `/documents`, **Upload document**, **Choose a file**: use Claude in Chrome's file-upload capability to supply the confirmed safe local file. Choose **Group** and **Document type**, enter **Description**, then **Upload document** after confirmation. Only if Chrome file upload is unavailable, explain that limit and offer the native file picker; use desktop control only after the person names that picker and confirms the fallback, or ask them to choose the file themselves. Stop on an upload error. On a duplicate prompt, ask whether to keep both or replace; never choose replacement automatically.
3. Verify the new document appears and keep its ID. Use `update_document_metadata` if listed and its schema covers the required fields. Otherwise open `/documents/<id>`, **Edit details**, set **Group**, **Type**, **The day this is about** when offered, **Description**, and **About (team member)**, then **Save details**. Confirm before editing because other surfaces may autosave. If a required date or subject field is unavailable for this file, stop and name the missing field. Do not invent or silently omit it.
4. For area and topics, use `update_document_metadata` only if it separates classification from human attestations. Otherwise return to `/documents`, find the file, select **Edit classification**, choose **Governance area** and **Topics**, then **Save classification** only if that save makes no attestation. Never tick the clinical-data checking box or submit its declaration. If the save carries a checking declaration, leave it for the person. If this document family has no **Edit classification**, stop this step and report that the current app cannot file its area/topics here. Do not change its type to force the control to appear.
5. Reopen the file and verify all requested fields that actually saved, its processing state and any missing classification. If indexing is still pending, say “uploaded, indexing pending”. If it failed, report the failure and stop. Upload alone never proves a file is indexed or approved.
6. Record each upload and metadata save, and every failure, with `comment_on_task`, or the associated task's **Notes**, **Add a note**, **Add note**, following `guides/recording.md`. A task link uses `attach_document_to_task` only for an ordinary task and after confirmation; in Chrome open that task's **Documents**, **Link from library**, enter **Search the Document Library** and verify the matching file. Confirm before clicking its row, which immediately attaches it. Record that write too. For an audit's named requirement use `complete-audit` instead.

## Requirements
Safe file, agreed tracking task and live filing choices. Claude in Chrome's file upload is the browser upload path today. Native file-picker control is a fallback only when Chrome file upload is unavailable and the person confirms it. Never use native control for browser operation or visible clinical records. A missing classification control or a save requiring attestation is a handoff, not permission to work around it.

## Reference files
`CLAUDE.md`; `guides/filing.md`; `guides/recording.md`; `.claude/skills/complete-audit/SKILL.md`.

## Result
Give the Library link, actual saved metadata, processing status and verified task notes. Name fields still blocked or awaiting a human declaration.

## Tools and integrations
Nurture MCP when listed: `list_document_types`, `get_governance_vocabulary`, `upload_document`, `update_document_metadata`, `attach_document_to_task`, `comment_on_task`. Chrome: `https://app.nurtureoutreach.com/documents`, `/documents/<id>`, `/settings`, `/tasks`.
