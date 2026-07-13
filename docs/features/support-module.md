# Support Module

Status: web support tickets with private image attachments across `diaverseapi`,
`diaweb`, and `aibot` compatibility.

## Repositories

- `diaverseapi`: support ticket domain, private attachment storage, migration,
  public/staff/internal APIs.
- `diaweb`: user support page, protected attachment gallery, and staff support
  board.
- `aibot`: hourly support digest inside `copywriting-ops-agent`.

## Behavior

Users and guests create support tickets in diaweb. Text-only creation still uses
the legacy JSON endpoint. Tickets with images use multipart creation with a
`payload` JSON field plus repeated `images` fields. Attachments are accepted only
on the initial ticket; follow-up user messages, staff replies, and manual staff
tickets remain text-only.

Staff manage tickets in `/staff/support` with a ticket board, detail drawer,
staff messages, status changes, protected attachment gallery, and compensation
handoff for authenticated users.

## Image Attachments

| Area | Contract |
| --- | --- |
| Limits | Up to three PNG/JPEG/WebP images, up to 5 MiB each and 15 MiB total |
| Validation | Backend decodes bytes with Pillow, rejects fake/corrupt/animated/oversized/non-raster input, applies EXIF orientation, and re-encodes without source metadata |
| Storage | Private persistent `SUPPORT_ATTACHMENTS_DIR`, outside `/static` and not mounted as public assets |
| Metadata | Ticket details expose only attachment UUID, position, MIME, processed size, dimensions, and creation time |
| Content reads | Owner/guest endpoint and staff endpoint return bytes with authenticated access checks |
| Browser rendering | diaweb fetches protected blobs with credentials, renders revocable object URLs, and bypasses Next image optimization/public caching |

Protected content endpoints:

- owner/guest:
  `/v1/support/tickets/{ticket_id}/attachments/{attachment_id}`
- staff:
  `/v1/admin/support/tickets/{ticket_id}/attachments/{attachment_id}`

Attachment responses use `Content-Disposition: inline`,
`Cache-Control: private, no-store`, and `X-Content-Type-Options: nosniff`.

Ops Agent periodically claims accumulated tickets, posts an intake message to
the configured Telegram support topic, groups similar reports, checks prior
`OpsAgentCase` memory plus backend `in_progress`/`done` ticket history, and
tries safe registered backend repair actions before creating developer work.
It posts a processing summary and separate `@jirabot` task messages for Denis
and Ilgizar when developer work remains.

## Safety Rules

- `done` closes a ticket permanently for user follow-up.
- Guest ownership is derived by the backend, not from browser input.
- Owner/guest denial and missing attachments both return 404.
- Attachment storage keys, SHA-256 values, filenames, protected URLs, blob URLs,
  and image bytes are never exposed through read schemas, docs, logs, or Ops
  payloads.
- Attachment creation is all-or-nothing: DB/storage failures roll back the ticket
  transaction and best-effort delete already-written files.
- `diaweb` support pages and protected blobs stay private/no-store; attachments
  must not be served from `/static`.
- Ops Agent moves claimed `new` tickets to `in_progress`.
- Ops Agent closes tickets to `done` only when the completed run reports
  `auto_repaired` and backend `OPS_AGENT_SUPPORT_AUTO_CLOSE_REPAIRED` is true;
  unresolved, failed, and duplicate-known tickets remain auditable through Ops
  events.
- Ops Agent writes Telegram task requests only; an external tracker bot may
  consume the `@jirabot` messages.
- Ops Agent/aibot payload remains attachment-free; it receives no IDs, URLs,
  filenames, keys, hashes, metadata expansion, or bytes for support images.
- Logs and docs must not include raw complaints, guest tokens, cookies,
  Telegram bot tokens, HMAC secrets, signatures, filenames, storage keys, object
  URLs, private server addresses, or production payloads.

## Deployment And Verification

Deploy order:

1. Deploy `diaverseapi` with the private volume/env configuration and run the
   additive support attachment migration.
2. Verify legacy JSON ticket creation still works.
3. Deploy `diaweb` attachment UI/blob clients.
4. Smoke test guest and authenticated creation with 1-3 valid images, invalid
   limits/formats, owner/staff reads, and a denied cross-owner read.
5. Verify attachment files persist across an API container restart and are not
   available under `/static`.

## Rollback

1. Roll back `diaweb` first so text-only JSON support remains usable.
2. Keep backend read compatibility and private stored files; do not delete
   attachment rows/files during a normal UI rollback.
3. Disable `OPS_AGENT_SUPPORT_DIGEST_ENABLED` only for Ops digest incidents.
4. If needed, hide diaweb staff ticket UI while keeping backend data.
5. Keep support tables unless a controlled data rollback is explicitly approved.
