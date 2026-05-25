---
name: daily-work
description: Manage the Diaverse local Daily Work log and Confluence publishing workflow. Use when the user says "$daily-work add", "$daily-work status", "$daily-work publish", asks to append today's completed work to docs/daily, checks daily publish readiness, or wants to publish the safe public digest to Confluence.
---

# Daily Work

Use this skill from `C:\Users\Indigo\Desktop\diaverse`. It is script-driven: run the workspace scripts instead of rewriting Confluence REST logic.

## Model

- Local files are per author: `docs/daily/YYYY-MM-DD-<author>.md`.
- The author comes from `DAILY_WORK_AUTHOR`; if it is missing, the default is `safiu`.
- Confluence pages are shared per day: `Daily Work - YYYY-MM-DD`.
- Publishing updates only the current author's section on the shared Confluence page and preserves other author sections.
- Only `Public digest` is published. `Internal log` stays local.

## Commands

### `$daily-work add`

Append or normalize today's local daily file:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-add.ps1 -Public "<безопасная публичная заметка>" -Internal "<локальная техническая заметка>"
```

If the user gives no text, synthesize a concise note from the just-completed task. Daily document entries must be written in Russian unless the user explicitly asks for another language. Keep `Public digest` user-safe and put implementation details in `Internal log`.

For another author explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-add.ps1 -Author "<author-slug>" -Public "<безопасная публичная заметка>"
```

### `$daily-work status`

Show today's file path, author, target Confluence title, section counts, unsafe public markers, and Confluence config presence without printing secret values:

```powershell
python scripts\daily_work_publish.py status
```

Use this as a preflight before publishing or when the user asks whether the daily doc is ready.

### `$daily-work publish`

Publish only `Public digest` to the current author's section on the shared Confluence page:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-publish.ps1
```

For validation without network writes:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\daily-work-publish.ps1 -DryRun
```

Run `status` first when the user has not already checked readiness. If publish succeeds, include the Confluence page URL in the final answer.

## Safety Rules

- Never publish or prompt-generate from `Internal log`.
- Write daily document content in Russian by default. Keep the technical section names `Public digest` and `Internal log` unchanged because the publisher parses them.
- Never echo Confluence tokens, raw env values, auth headers, private SSH commands, SSH key paths, internal IPs, private infrastructure details, or sensitive stack traces.
- If `Public digest` contains unsafe markers, stop and tell the user what marker classes were detected. Do not include the sensitive text.
- If config is missing, report only missing env key names.
- Keep final answers concise and mention whether the daily file was updated or published.

## Script Logging

Expect script-level `INFO`, `WARN`, and `ERROR` logs. They should include paths, dates, counts, author, page ids, titles, and safe reason codes only. They must not include generated post bodies, Confluence document bodies, tokens, JWTs, or raw environment values.
