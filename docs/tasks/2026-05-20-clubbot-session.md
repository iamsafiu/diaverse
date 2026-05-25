# Clubbot Session Notes - 2026-05-20

This note records the club-related decisions and operations completed during the
2026-05-20 session. It is intentionally separate from the main
[`../club.md`](../club.md) runbook, which remains the long-lived operational
source of truth.

## Scope

The session covered four related areas:

- standalone Club10000 bot and Prodamus payment callbacks;
- Diaverse club ownership model and payment bridge;
- `copywriting-clubbot` and `copywriting-userbot` deployment on the foreign bot
  server;
- moving the active Telegram club chat to `-1003818826378` without topic/thread
  routing.

Secrets, bot tokens, API hashes, and signing keys are not stored in this file.

## Naming And Ownership

To avoid confusing two different Telegram runtimes, the standalone legacy bot is
named `club10000-bot`.

Current naming:

| Name | Runtime/repo | Responsibility |
| --- | --- | --- |
| `club10000-bot` | standalone Club10000 bot | Prodamus callbacks, old club bot flows, reminders, reports, bot-local DB |
| `copywriting-clubbot` | `aibot/app/clubbot` | Telegram Bot API adapter for Diaverse club events and outbox commands |
| `copywriting-userbot` | `aibot/app/userbot` | Telegram user account runtime: source sync, club roster sync, userbot publishing |
| `diaverseapi/app/club` | backend | source of truth for club memberships, access, payments, Telegram events, outbox |
| `diaweb/frontend/modules/club` | frontend | staff club admin UI |

Important constraint: `club10000-bot` must not connect directly to the Diaverse
database. Diaverse club state is owned by `diaverseapi`.

## Server Topology

Foreign bot server:

```text
72.56.108.222
```

Relevant paths and services:

```text
/srv/aibot
  copywriting-api
  copywriting-worker
  copywriting-clubbot
  copywriting-userbot
  copywriting-postgres

/srv/club10000-bot
  club10000_bot
  club10000_postgres
```

The standalone Club10000 compose project was renamed to `club10000`, with
containers `club10000_bot` and `club10000_postgres`. Its old Docker volumes were
kept intentionally for data preservation.

Dev Diaverse API server:

```text
5.42.116.157
```

Relevant service:

```text
diaverse-postgresql-1
```

The active dev backend URL used by club bot integrations is:

```text
https://api.dev.diaverse.app/v1
```

## Payment Integration Decision

The selected short-term integration pattern is a signed internal event bridge:

```text
Prodamus -> club10000-bot -> signed internal payment event -> diaverseapi
```

Rationale:

- Prodamus callback handling stays close to the bot that already understands
  Prodamus and Club10000-specific flows.
- `diaverseapi` remains the only owner of club payment/access truth.
- There is no direct database access from bot to Diaverse.
- There are not two subscription owners.

Prodamus callback URL for the standalone bot on the `iamgradov.ru` server:

```text
https://iamgradov.ru/payments/prodamus/callback
```

The standalone bot may keep its own PostgreSQL database for legacy bot
operations, reports, reminders, and Prodamus bookkeeping. Diaverse-visible
access should still be mirrored through signed internal API events.

## Chat Migration Completed

Target Telegram chat:

```text
-1003818826378
```

Topic/thread routing is intentionally disabled. Messages should go to the
general chat/topic.

### aibot Environment

Updated on:

```text
72.56.108.222:/srv/aibot/.env.production
```

Backup created:

```text
.env.production.bak.20260520145758
```

Active values after the change:

```env
CLUBBOT_CHAT_ID=-1003818826378
CLUB_ROSTER_CHAT_ID=-1003818826378
CLUBBOT_WELCOME_MESSAGE_THREAD_ID=
CLUBBOT_REPORTS_MESSAGE_THREAD_ID=
CLUBBOT_LEADERBOARD_MESSAGE_THREAD_ID=
```

Both `copywriting-clubbot` and `copywriting-userbot` read this env file.

### aibot Publish Target

Updated in `copywriting-postgres`:

```text
copywriting_publish_targets.name = 'Club leaderboard'
copywriting_publish_targets.id = 56064463-018e-487f-826a-a42ba58dd41f
```

Current target state:

```text
target_type     = telegram
destination_ref = -1003818826378
status          = active
is_enabled      = true
```

Current `config_json`:

```json
{
  "club_profile": "club",
  "caption_limit": 1024,
  "publish_transport": "userbot"
}
```

Removed from `config_json`:

```text
message_thread_id
topic_root_message_id
reply_to_message_id
```

This matters because userbot publishing does not use `CLUBBOT_CHAT_ID`; it reads
the destination chat from the publish target row.

### Dev diaverseapi Club Program

Updated on `5.42.116.157` in `diaverse_dev`:

```text
club_programs.code = 'main'
telegram_chat_id   = -1003818826378
```

Cleared from `metadata_json`:

```text
telegram_leaderboard_thread_id
telegram_welcome_thread_id
telegram_report_thread_id
```

This is required because `diaverseapi` rejects Telegram events and roster
snapshots when the event chat does not match `club_programs.telegram_chat_id`.

### Restarted Services

On `72.56.108.222`:

```bash
cd /srv/aibot
docker compose -f docker-compose.prod.yml up -d --no-deps copywriting-clubbot copywriting-userbot
```

Both containers became healthy after restart.

## Verification

`copywriting-clubbot` runtime env after restart:

```text
CLUBBOT_CHAT_ID=-1003818826378
CLUBBOT_BACKEND_BASE_URL=https://api.dev.diaverse.app/v1
CLUBBOT_WELCOME_MESSAGE_THREAD_ID=
CLUBBOT_REPORTS_MESSAGE_THREAD_ID=
CLUBBOT_LEADERBOARD_MESSAGE_THREAD_ID=
```

`copywriting-clubbot` Telegram preflight confirmed:

```text
bot_username=superclub_bot
chat_id=-1003818826378
chat_type=supergroup
is_forum=true
admin_status=administrator
can_approve_join=true
can_remove=true
thread_ids={'welcome': None, 'reports': None, 'leaderboard': None}
```

`copywriting-userbot` runtime env after restart:

```text
CLUB_ROSTER_SYNC_ENABLED=true
CLUB_ROSTER_CHAT_ID=-1003818826378
CLUBBOT_CHAT_ID=-1003818826378
CLUB_ROSTER_BACKEND_BASE_URL=https://api.dev.diaverse.app/v1
COPYWRITING_USERBOT_PUBLISH_QUEUE=userbot-publish
```

`copywriting-userbot` roster sync confirmed access to the new chat:

```text
title=Клуб: 10.000 [ЧАТ]
telegram_member_count=32
participant_count=31
status=complete
error_code=None
backend_status=completed
created=20
updated=11
linked=16
unlinked=12
suspected_missing=1
```

The roster snapshot was accepted by `api.dev.diaverse.app`.

## Not Run

No live leaderboard publish test was triggered during this session. The publish
target is configured for the new chat, but no test message/image was sent.

## Operational Follow-Ups

Before production use, verify:

- `superclub_bot` remains admin in `-1003818826378`;
- the userbot account remains a member of the same chat;
- the staff club settings page shows `telegram_chat_id=-1003818826378`;
- settings validation passes in `/staff/club/settings`;
- a live leaderboard publish is tested when it is acceptable to send a message
  into the chat.

If the production Diaverse API uses a separate database from dev, repeat the
`club_programs` chat id update there as a separate production operation.

## Rollback Notes

To roll back the chat migration:

1. Restore `/srv/aibot/.env.production` from
   `.env.production.bak.20260520145758`, or set `CLUBBOT_CHAT_ID` and
   `CLUB_ROSTER_CHAT_ID` to the previous chat.
2. Restore the `Club leaderboard` publish target `destination_ref` and any topic
   fields that should be active.
3. Restore `club_programs.telegram_chat_id` and metadata in the backend
   database.
4. Restart `copywriting-clubbot` and `copywriting-userbot`.

Do not roll back only one of these places: bot events, roster sync, leaderboard
publishing, and backend validation each read their chat id from different
configuration surfaces.
