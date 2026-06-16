# Diaverse Club Runbook

## Ownership

- `diaverseapi/app/club` owns club state: programs, memberships, payment contracts, manual access, Telegram events, outbox commands, pairs, step snapshots, leaderboards, and alerts.
- `aibot/app/clubbot` owns the thin Telegram adapter runtime source code. It is deployed as `copywriting-clubbot` on a foreign bot server, not on the backend server. It must not import or own club DB models directly and must talk to `diaverseapi` through signed internal HTTP only.
- `club10000-bot/` owns the standalone Club10000 bot source code, its restored bot-local PostgreSQL snapshot, Prodamus callback handling, funnels, reminders, referrals, and bot reports. It must not connect directly to the Diaverse database; it mirrors payment state into `diaverseapi` through signed internal HTTP events.
- `diaweb/frontend/modules/club` owns the staff surface at `/staff/club`, including alerts. Do not manage club alerts from the generic staff logging UI.
- `aibot` owns club copywriting, AI leaderboard image generation/publishing, and foreign-server Telegram runtime hosting. It does not own club membership or leaderboard truth.

## Environment

`diaverseapi`:

```env
CLUB_ACTIVE_PROGRAM_CODE=main
CLUBBOT_INTERNAL_SECRET=
CLUBBOT_SIGNATURE_TOLERANCE_SECONDS=300
CLUB_TG_OUTBOX_BATCH_SIZE=50
CLUB_TG_OUTBOX_MAX_ATTEMPTS=5
CLUB_TG_OUTBOX_RETRY_BASE_SECONDS=30
CLUB_TG_OUTBOX_STALE_LEASE_SECONDS=300
CLUB_SILENCE_THRESHOLD_DAYS=2
CLUB_SILENCE_SCAN_BATCH_SIZE=500
CLUB_LIFECYCLE_REVIEW_ONLY_ENABLED=true
CLUB_UNKNOWN_JOIN_POLICY=pending_verification
CLUB_ROSTER_UNKNOWN_POLICY=pending_verification
CLUB_EXPIRY_SCAN_DRY_RUN=true
CLUB_EXPIRY_AUTO_REMOVE_ENABLED=false
CLUB_PAYMENT_GRACE_DAYS=3
CLUB_NON_PAID_PAYMENT_EVENT_POLICY=ledger_only
CLUB_CANCELLED_ACCESS_POLICY=period_end
CLUB_REFUND_ACCESS_POLICY=review_only
CLUB_AIBOT_BASE_URL=
CLUB_AIBOT_SIGNING_SECRET=
CLUB_AIBOT_TIMEOUT_SECONDS=10
CLUB_AIBOT_LEADERBOARD_IMAGE_PATH=/internal/club/leaderboards/image
CLUB_AIBOT_LEADERBOARD_PUBLISH_PATH=/internal/club/leaderboards/publish
CLUB_AIBOT_PAIRING_ROLLOVER_PUBLISH_PATH=/internal/club/leaderboards/pairing-rollovers/publish
CLUB_AIBOT_LEADERBOARD_STATUS_PATH=/internal/club/leaderboards/assets/{asset_id}
CLUB_AIBOT_LEADERBOARD_PREFLIGHT_PATH=/internal/club/leaderboards/preflight
```

`copywriting-clubbot` runtime, deployed from `aibot` code on a foreign bot server:

```env
COPYWRITING_RUNTIME_ROLE=copywriting-clubbot
COPYWRITING_RUNTIME_HEARTBEAT_FILE=/tmp/copywriting-clubbot-heartbeat.json
COPYWRITING_RUNTIME_HEARTBEAT_STALE_SECONDS=180
CLUBBOT_TOKEN=
CLUBBOT_BACKEND_BASE_URL=https://api.example.com/v1
CLUBBOT_BACKEND_SECRET=
CLUBBOT_CHAT_ID=-100...
CLUBBOT_ALLOWED_UPDATES=chat_join_request,chat_member,message,my_chat_member
CLUBBOT_OUTBOX_WORKER_ID=clubbot-1
```

`aibot`:

```env
CLUBBOT_TOKEN=
CLUBBOT_BACKEND_BASE_URL=https://api.example.com/v1
CLUBBOT_BACKEND_SECRET=
CLUBBOT_CHAT_ID=-100...
CLUBBOT_ALLOWED_UPDATES=chat_join_request,chat_member,message,my_chat_member
CLUBBOT_OUTBOX_WORKER_ID=clubbot-1
CLUB_AIBOT_SIGNING_SECRET=
CLUB_AIBOT_SIGNATURE_MAX_SKEW_SECONDS=300
COPYWRITING_USERBOT_PUBLISH_QUEUE=userbot-publish
COPYWRITING_USERBOT_REQUIRE_PREMIUM=true
COPYWRITING_USERBOT_SESSION_DIR=/var/lib/copywriting/userbot
CLUB_ROSTER_SYNC_ENABLED=false
CLUB_ROSTER_CHAT_ID=-100...
CLUB_ROSTER_SYNC_INTERVAL_SECONDS=21600
CLUB_ROSTER_BATCH_SIZE=500
CLUB_ROSTER_BACKEND_BASE_URL=https://api.example.com/v1
CLUB_ROSTER_BACKEND_SECRET=
CLUB_ROSTER_INCLUDE_BOTS=false
CLUB_ROSTER_INCLUDE_DELETED=false
TELEGRAM_API_ID=
TELEGRAM_API_HASH=
TELEGRAM_PHONE=
TELEGRAM_BOT_TOKEN_CLUB= # optional Bot API fallback only
OPENAI_IMAGE_MODEL=gpt-image-2
COPYWRITING_GENERATED_IMAGES_DIR=/var/lib/copywriting/generated_images
```

`CLUB_AIBOT_SIGNING_SECRET` must be the same in `diaverseapi` and `aibot`. `CLUBBOT_BACKEND_SECRET` must match `diaverseapi` `CLUBBOT_INTERNAL_SECRET`. Telegram bot tokens stay in `aibot` foreign-server env, never in the database and never in backend-server env.

`club10000-bot` Club10000 runtime:

```env
BOT_TOKEN=
WEBHOOK_DOMAIN=iamgradov.ru
WEBHOOK_PATH=/webhook/bot
USE_POLLING=false
PRODAMUS_SHOP_URL=https://fitnesspass.payform.ru
PRODAMUS_SECRET=
PRODAMUS_CLUB10000_SUBSCRIPTION_ID=
PRODAMUS_CLUB10000_REFERRAL_SUBSCRIPTION_ID=
CADDY_NETWORK=iamgradov-site_default
DIAVERSE_API_BASE_URL=
DIAVERSE_CLUB10000_SECRET=
CLUB_INVITE_LINK=
DIAVERSE_OUTBOX_ENABLED=true
DIAVERSE_OUTBOX_POLL_SECONDS=15
DIAVERSE_OUTBOX_BATCH_SIZE=20
DIAVERSE_OUTBOX_MAX_ATTEMPTS=8
DIAVERSE_OUTBOX_INITIAL_BACKOFF_SECONDS=60
DIAVERSE_OUTBOX_MAX_BACKOFF_SECONDS=3600
CLUB_LOCAL_RECOVERY_FALLBACK_ENABLED=true
```

The Club10000 `BOT_TOKEN` must be distinct from the existing `copywriting-clubbot`
token unless the old runtime is fully stopped. Verify bot identity with `getMe`
or redacted token hashes before starting the container.

## Staff Setup

1. In `/staff/club/settings`, create/bootstrap the active program if it does not exist.
2. Configure Telegram chat id, topic/thread ids, invite TTL, join cutoff, fallback admin membership, pair notice templates, leaderboard image settings, and `aibot_target_profile`.
3. Run settings validation. The validation must show Telegram chat configuration and aibot service auth as configured before production use.
4. Grant staff permissions through RBAC: `club:view`, `club:edit`, `club.alerts:update`, and `club.settings:manage`.

## Paid Activation And Onboarding

The primary Club10000 activation path starts before the user enters the private
group:

1. `club10000-bot` receives a successful Prodamus payment and queues the signed
   Diaverse payment bridge event.
2. `diaverseapi` records the payment state, creates or resolves the club
   membership, mints a one-use onboarding activation token, and returns
   `activation_url`, `activation_token_id`, and `activation_expires_at` in the
   bridge response.
3. `club10000-bot` sends the paid user a private Telegram message with two
   buttons: activate the club cabinet and enter the private group. The bot stores
   delivery metadata on the outbox payload so retries do not send duplicate
   activation messages.
4. The user opens `/club?activation=...`, authorizes by Telegram or email, and
   the first authenticated user who claims a valid unused link becomes the linked
   club user for that membership.
5. Completing onboarding is the activation signal for the cabinet experience.
   Reopening an already claimed link is idempotent only for the same Diaverse
   user; another authenticated user receives a controlled conflict/error state.

Staff can create an invitation for non-payment access in `/staff/club` with the
`Создать приглашение` button. It creates an `invitation` membership/manual access
record and shows a copyable onboarding activation link. No recipient form is
required in this MVP.

Default group welcome messages no longer create activation links. A legacy custom
`telegram_welcome_message_template` that explicitly contains `{activation_url}`
still gets a member-specific activation URL for backward compatibility, but this
must not be the normal paid onboarding path.

If a user cannot access onboarding, check:

- `club10000-bot` outbox delivery metadata: whether the Diaverse bridge response
  had an activation token id and whether the private Telegram message was sent.
- `diaverseapi` activation token row by token id, not by raw token value: status,
  expiry, membership id, and claimed user id.
- The browser redirect path: unauthenticated `/club?activation=...` requests
  must redirect to `/login?redirect=/club?...` and preserve the query until the
  claim call completes.
- Whether `CABINET_PUBLIC_BASE_URL`, `DIAVERSE_API_BASE_URL`,
  `DIAVERSE_CLUB10000_SECRET`, `DIAVERSE_OUTBOX_ENABLED`, and `CLUB_INVITE_LINK`
  are configured in the relevant runtime.
- Logs must never include the raw activation token, full activation URL, signed
  headers, bot tokens, or private invite links.

## Buddy Pairing

`diaverseapi` owns buddy pairing state in `club_buddy_groups` and
`club_buddy_members`. The fallback admin is not a virtual label: staff must
select a real active club membership in `/staff/club/settings`. That member
keeps normal step accounting and can appear in at most one active buddy group.

Automatic pairing rules:

1. When a newly active member enters the Telegram group, the existing welcome
   notice is queued first.
2. The backend assigns the member to a buddy group and queues a pair notice to
   the Telegram group.
3. If no regular participant is waiting, the new member is paired with the
   configured fallback admin as a real `ClubBuddyMember(role=fallback)`.
4. If another regular participant joins while that fallback pair is active, the
   fallback pair is closed, the previous regular member is paired with the new
   regular member, and the fallback admin becomes unpaired.
5. If the fallback admin is missing, inactive, or already busy in another pair,
   the regular member remains in a real waiting `solo_buffer`; no virtual admin
   row is created.

Operational invariant:

- `club_buddy_members` has a partial unique index
  `ux_club_bm_active_member` on active `membership_id` rows. This prevents any
  participant, including the fallback admin, from appearing in multiple active
  buddy groups.

15-day pairing rollover:

- The scheduler still publishes the deployment-compatible
  `club_monthly_pairing_rollover` channel, but it now ticks daily at
  `10 0 * * *`.
- The service decides whether work is due by checking
  `last_successful_rollover_date + pairing_rollover_interval_days <= today`.
  The default interval is 15 calendar days.
- The first 15-day cycle is anchored from the latest successful legacy monthly
  state: prefer `program.metadata_json.last_monthly_pairing_at`, otherwise use
  the first day of `last_monthly_pairing_month`.
- Do not use a day-of-month cron such as `*/15`: it resets on month boundaries
  and produces short gaps such as day 31 to day 1.
- When due, all active buddy groups are closed, active regular members are
  shuffled, and new pairs are created.
- The fallback admin is excluded from the regular shuffle and is used only when
  an odd regular member remains.
- The new primary idempotency metadata is stored under
  `last_pairing_rollover_period_key`, `last_pairing_rollover_at`,
  `last_pairing_rollover_anchor_date`, and `last_pairing_rollover_payload`.
- After the rollover transaction commits, `diaverseapi` sends a signed request
  to `aibot` to generate and publish one Telegram post with image and caption.
  No `message_thread_id` is sent, so the post lands in the general/common group
  destination.
- If the initial signed `aibot` request fails synchronously, backend queues a
  plain-text fallback notice with the same pair list, also without a topic id.
- Pairing rollover images use `pairing_rollover_image_prompt_template` and
  reuse `leaderboard_image_reference_paths`.
- Pairing rollover pair lines prefer Telegram usernames formatted as
  `@username`; members without a Telegram username fall back to the existing
  display-name rules.

Settings templates:

- `telegram_welcome_message_template` supports `{club_title}`, `{name}`,
  `{username}`, `{first_name}`, `{last_name}`, and legacy `{activation_url}`.
  Default welcome messages do not create activation links; custom templates that
  explicitly contain `{activation_url}` keep backward-compatible member-specific
  activation URLs and must not be used for shared pair notices.
- `telegram_pair_assigned_message_template` supports
  `{club_title}`, `{member_name}`, `{partner_name}`, `{pair_names}`,
  `{group_code}`, and `{is_fallback}`.
- `telegram_pairing_rollover_message_template` supports `{club_title}`,
  `{period_key}`, `{period_start}`, `{period_end}`, `{pairs_list}`,
  `{pairs_count}`, `{generated_at}`, and legacy `{month}`.
- `telegram_monthly_pairs_message_template` remains readable as a fallback for
  older settings.
- `pairing_rollover_image_prompt_template` supports `{club_title}`,
  `{period_key}`, `{period_start}`, `{period_end}`, `{pairs_list}`,
  `{pairs_count}`, and `{generated_at}`.

Logs to inspect:

- `diaverseapi`: `[club.pairing] fallback pair created`, `fallback pair
  replaced`, `rollover due calculated`, `periodic rollover skipped`,
  `rollover complete`, and `pairing rollover image publish accepted`.
- `diaverseapi` outbox: `reason=telegram_pair_assigned` and
  `reason=pairing_rollover_fallback`.
- `aibot`: `copywriting.api.club_assets.leaderboard_image.requested`,
  `copywriting.use_case.club_leaderboard_image.generate.start`, and
  `copywriting.use_case.club_leaderboard_image.userbot_publish_queued` or
  `.published`.
- `copywriting-clubbot`: `send_message` ACK/NACK for pair notices and fallback
  text commands.

## Lifecycle Policy

`diaverseapi` is the only source of truth for final club access. The bot records
payments and Telegram facts, but the backend resolves whether a member is paid,
manual, gifted, migrated, test-only, expired, or still under review.

Default rollout is intentionally non-destructive:

| Situation | Default backend decision | Staff action |
| --- | --- | --- |
| Paid, not in chat | Keep paid membership as pending join. | Send invite or approve join request. |
| Paid, in chat | Keep access until `access_expires_at`. | Monitor payment period and presence. |
| Paid, no game UUID | Access is valid by Telegram/payment identity. | Link game UUID later when the user enters the game. |
| Telegram join through an explicit invite link | Grant `invitation` access after the member is confirmed in the club chat; welcome and buddy-pair notices are queued through the backend outbox. | Monitor invite-link hygiene; remove or manually exclude users when access was granted incorrectly. |
| Unknown Telegram join | Create review record, do not grant paid access silently. | Classify as paid/manual/gift/migration/test or remove. |
| Roster-only existing member | Treat as review or migration candidate. | Reconcile against old Club10000 payments and current group roster. |
| Manual/gift/migration/test | Require explicit source and reason; no-expiry must be deliberate. | Maintain `access_expires_at` as the staff-facing access date when applicable. |
| Expired but still in chat | Surface as removal candidate first. | Remove only after review/dry-run flags are disabled and Telegram ACK succeeds. |
| Removed for non-payment | Mark `ban_reason=nonpayment`, `auto_unban_on_payment=true`, and remove through Telegram outbox. | Late payment may restore access automatically through Diaverse recovery commands. |
| Manually excluded for violation | Mark `ban_reason=manual_exclusion`, `auto_unban_on_payment=false`, and ban through Telegram outbox. | Late payment is recorded but does not restore access; staff must explicitly restore or re-ban. |
| Manually excluded but back in chat | Keep status blocked and surface `manual_exclusion_in_chat`. | Staff chooses "Разблокировать и вернуть" or "Исключить за нарушение". |
| Failed/cancelled/refunded payment | Record event ledger-only unless policy explicitly confirms mutation. | Decide cancellation/refund semantics before enabling destructive effects. |

Lifecycle flags:

- `CLUB_LIFECYCLE_REVIEW_ONLY_ENABLED=true` keeps ambiguous and destructive flows in review mode.
- `CLUB_UNKNOWN_JOIN_POLICY=pending_verification` prevents unknown joins from becoming active access.
- `CLUB_ROSTER_UNKNOWN_POLICY=pending_verification` keeps imported roster members reviewable until staff classifies them.
- `CLUB_EXPIRY_SCAN_DRY_RUN=true` allows expiry scans to report candidates without queueing removals.
- `CLUB_EXPIRY_AUTO_REMOVE_ENABLED=false` prevents Telegram removal commands from being queued automatically.
- `CLUB_PAYMENT_GRACE_DAYS=3` is the backend grace window for confirmed payment-failure policy.
- `CLUB_NON_PAID_PAYMENT_EVENT_POLICY=ledger_only` keeps non-paid payment events from mutating access by default.
- `CLUB_CANCELLED_ACCESS_POLICY=period_end` preserves access through the paid period for cancellation events.
- `CLUB_REFUND_ACCESS_POLICY=review_only` keeps refunds staff-reviewed until business rules are confirmed.

## Ban And Return Policy

Staff UI intentionally has one destructive member action: `Исключить за нарушение`.
It means a real Telegram ban/removal, not just ending the paid period. The action
sets `status=removed`, `ban_reason=manual_exclusion`, and
`auto_unban_on_payment=false`. A later Prodamus payment from this user is stored
on the payment contract and shown for review as `paid_but_manually_blocked`, but
Diaverse must not queue an automatic unban.

Non-payment removal is a different state. Expiry enforcement marks the member
with `ban_reason=nonpayment` and `auto_unban_on_payment=true` before queueing a
Telegram ban. If Prodamus later sends `initial_paid` or `renewal_paid`,
`diaverseapi` clears the ban policy, moves the member to `paid_pending_join` or
`active` depending on current Telegram presence, queues `unban_chat_member`, and
queues a one-use invite link. `copywriting-clubbot` executes those outbox
commands and ACKs them back; membership should not be treated as in-chat until a
Telegram join/presence fact confirms it.

Manual Telegram actions outside Diaverse are treated as facts, not entitlement
decisions. If a manually excluded user is unbanned directly in Telegram and
joins again, the Telegram event sets presence to `in_chat` but keeps access
blocked and surfaces `manual_exclusion_in_chat` / `removed_in_chat` in
reconciliation. Staff then either restores the member explicitly or clicks
`Исключить за нарушение` again to re-ban and preserve the manual exclusion
policy.

Payment-after-ban decision table:

| Existing policy | New payment event | Backend result | Telegram action |
| --- | --- | --- | --- |
| `ban_reason=nonpayment`, `auto_unban_on_payment=true` | `initial_paid` or `renewal_paid` | Clear ban policy, restore to `paid_pending_join` or `active`, update paid period. | Queue `unban_chat_member` and one-use invite link. |
| `ban_reason=manual_exclusion`, `auto_unban_on_payment=false` | `initial_paid` or `renewal_paid` | Keep `status=removed`, record renewed event with `paid_but_manually_blocked`. | No automatic unban; staff review only. |
| `status=removed` with no `ban_reason` | Any payment or Telegram presence contradiction | Surface `removed_reason_unknown` for staff review. | Do not auto-restore until policy is corrected. |

Operational logs to inspect:

- `diaverseapi` club logs: `payment recovered nonpayment ban`, `payment received for manual exclusion`, `membership restore queued recovery`, `manually excluded member rejoined chat`.
- `copywriting-clubbot` logs: outbox `command_id`, `command_type`, Telegram ACK/NACK, and worker id for `unban_chat_member` / `create_invite_link`.
- `club10000-bot` logs: queued normalized Prodamus event with Telegram user id, bot user id, provider ids, and delivery retry/dead-letter status.

`club10000-bot` may keep its local unban/invite path only as a temporary
compatibility fallback. When `CLUB_LOCAL_RECOVERY_FALLBACK_ENABLED=false`,
Diaverse outbox recovery is authoritative and the bot should only queue the
payment event.

## Existing Member Reconciliation

Reconciliation is a dry-run process until staff explicitly classifies members
and rollout flags are changed. It compares three signals that are already
mirrored into Diaverse state:

- Diaverse `ClubMembership` rows and computed access state.
- Telegram roster/presence facts from `copywriting-clubbot` and roster scans.
- Restored Club10000 active subscriptions imported through signed payment
  events from `club10000-bot`, not through direct database writes.

Run the old Club10000 bootstrap report on the foreign bot server first. This
does not mutate Diaverse unless `--enqueue` is added:

```bash
cd /srv/club10000-bot
docker compose -f docker-compose.production.yml exec bot \
  python scripts/sync_diaverse_payments.py \
    --output-json /tmp/club10000-bootstrap-dry-run.json
```

The JSON contains stable identifiers for each planned imported subscription:
Club10000 subscription id, bot user id, Telegram user id, provider order id,
provider subscription/invoice ids, period end, and bootstrap metadata.

After the production API endpoint exists and bootstrap events have been
delivered into Diaverse, run the Diaverse reconciliation report from the
backend server:

```bash
cd /srv/diaverseapi
python -m app.commands.club_reconcile_existing_members \
  --output-json /tmp/club-reconciliation.json \
  --output-csv /tmp/club-reconciliation.csv
```

For focused review:

```bash
python -m app.commands.club_reconcile_existing_members \
  --segment in_chat_unclassified \
  --output-json /tmp/club-in-chat-unclassified.json
```

The report is read-only. It returns segment counters, operational buckets,
identity conflicts, payment/provider identifiers, roster sync ids, Telegram ids,
game user ids, and the current staff-facing `access_expires_at` value.

Operational buckets:

| Bucket | Meaning | Staff action |
| --- | --- | --- |
| `paid_active` | Payment contract exists and membership is active. | Leave active; link game UUID if missing. |
| `paid_pending_join` | Paid user has not joined or presence is unknown. | Send invite or approve join request. |
| `in_chat_without_payment_or_exception` | Telegram member is in chat with no payment/exception. | Classify as migration/gift/manual/test or remove after review. |
| `manual_or_exception` | Manual, gift, migration, or test access. | Confirm reason and expiry policy. |
| `expired_in_chat` | Access is expired but Telegram presence is still in chat. | Review first; removal remains outbox/ACK based. |
| `removed_in_chat` | Excluded member is currently in Telegram chat. | Restore explicitly or re-run manual exclusion. |
| `paid_but_manually_blocked` | User paid after a manual exclusion. | Review policy; do not auto-unban. |
| `recoverable_nonpayment_removed` | User was removed for non-payment and is eligible for paid recovery. | Confirm payment/recovery outbox state if automatic return did not complete. |
| `suspected_left` | Roster scan or Telegram event suggests the member left. | Confirm presence before changing access. |
| `active_no_game_account` | Club access exists without linked game UUID. | Keep access; link when the user enters the game. |
| `identity_conflict` | Duplicate Telegram or game identity signals. | Resolve manually; never auto-merge. |

Migration decision table:

| Current facts | Target state | Action |
| --- | --- | --- |
| Paid in Club10000, not in chat | `paid_pending_join` | Import payment event, send invite. |
| Paid in Club10000, in chat | `active` | Import payment event and keep access until period end. |
| Paid, no game UUID | `active_no_game_account` | Keep membership; auto-link later by Telegram identity. |
| In chat, no payment | `pending_verification` or explicit exception | Classify as migration/gift/manual/test with reason, or remove after review. |
| Manual/VIP/test | `manual`, `gift`, `migration`, or `test` | Set reason and optional `access_expires_at`; no-expiry must be deliberate. |
| Expired but in chat | `expired_in_chat` | Keep review-only until staff approves removal. |
| Removed for non-payment, later paid | `paid_pending_join` or `active` | Diaverse queues unban and a one-use invite after payment event processing. |
| Manually excluded, later paid | `paid_but_manually_blocked` | Keep blocked; staff must restore explicitly. |
| Manually excluded, later joins after external Telegram unban | `manual_exclusion_in_chat` | Restore explicitly or re-ban through Diaverse. |
| Suspected left | `suspected_left` | Do not remove based on one failed/partial scan. |

Preflight before enabling live propagation:

- `POST https://api.diaverse.app/v1/internal/club/payment-events` must exist and
  return an auth/validation response, not `404`.
- `DIAVERSE_OUTBOX_ENABLED=false` stays in `club10000-bot` until that endpoint is
  deployed and smoke-tested.
- `CLUB_LIFECYCLE_REVIEW_ONLY_ENABLED=true`,
  `CLUB_EXPIRY_SCAN_DRY_RUN=true`, and
  `CLUB_EXPIRY_AUTO_REMOVE_ENABLED=false` stay enabled through the first
  reconciliation pass.
- Run targeted GBrain sync after changing this runbook or related club code.

During live reconciliation, operators should capture these identifiers for each
manual decision or support case:

- Diaverse `membership_id` and, when linked, game `user_id`.
- Telegram `telegram_user_id`, `telegram_username`, and latest roster sync id.
- Prodamus `provider_order_id`, `provider_subscription_id`, and
  `provider_invoice_id`.
- Club10000 `clubbot_subscription_id`, `clubbot_user_id`, and local outbox row
  id when the event came from bootstrap or callback delivery.
- Signed internal request id from Diaverse/club10000-bot logs for failed or retried
  payment-event deliveries.
- Staff classification source, reason, and chosen `access_expires_at`. Treat
  `access_expires_at` as the staff-facing "access until" date.

## Telegram Deployment

The Telegram group contains the club bot account for system actions. It also contains the configured Premium userbot account when leaderboard content must be published with premium emoji.

All Telegram runtimes must run on foreign bot infrastructure. The backend server owns state and signed internal APIs only; it must not run club bot polling/webhook or store the live club bot token for runtime use.

Responsibilities are split:

- `copywriting-clubbot` handles inbound updates, invite links, removals, moderation/system outbox actions, and future payment-grace removal flows.
- `aibot` generates creative assets, enqueues leaderboard publication through the existing `copywriting-userbot` runtime, and runs optional roster scans through the same Premium userbot account.
- Bot API publishing with `TELEGRAM_BOT_TOKEN_CLUB` is an explicit fallback target, not the default leaderboard path.

Only `copywriting-clubbot` consumes club bot updates. `copywriting-api`, `copywriting-worker`, `copywriting-userbot`, and `diaverseapi` must not set a webhook or poll updates for the club bot.

Operational logs must be joinable across services. `copywriting-clubbot` logs should include Telegram `update_id` for inbound updates, outbox `command_id` for claimed commands, `worker_id` for the running outbox worker, and signed HTTP `request_id` when calling `diaverseapi`. Backend club security/event logs should include the same `request_id`, but must not log signatures, tokens, or raw request bodies.

## Club10000 Payment Bridge Server Preflight

Read-only server preflight on 2026-05-20 for `root@72.56.108.222`:

- Hostname: `discontent`.
- `iamgradov.ru` and `www.iamgradov.ru` are served by Caddy from `/srv`.
- Caddy container: `iamgradov-caddy`, image `caddy:2-alpine`, network `iamgradov-site_default`, public ports `80` and `443`.
- Existing Caddyfile has no `/payments/prodamus/callback` route yet.
- Existing `copywriting-clubbot` is a separate container on `copywriting_internal`.
- `club10000-bot` production compose must set `CADDY_NETWORK=iamgradov-site_default` so Caddy can reach `club10000_bot:8080`.

Add the payment route inside the existing `iamgradov.ru, www.iamgradov.ru` site block before `file_server`:

```caddyfile
handle /payments/prodamus/callback {
    reverse_proxy club10000_bot:8080
}
```

If Club10000 runs in Telegram webhook mode, also route the configured webhook path:

```caddyfile
handle /webhook/bot {
    reverse_proxy club10000_bot:8080
}
```

Do not change the static site fallback for other paths. Run Caddy validation
before reload on the server:

```bash
docker exec iamgradov-caddy caddy validate --config /etc/caddy/Caddyfile
docker exec iamgradov-caddy caddy reload --config /etc/caddy/Caddyfile
```

## Club10000 2026-05-20 Server Smoke Check

Deployment target: `root@72.56.108.222`, app directory `/srv/club10000-bot`.

Runtime state after restore:

- `club10000_postgres`: running, healthy, private Docker network only.
- `club10000_bot`: smoke-tested as healthy, then stopped on 2026-05-20 because the same Telegram bot token is still used by the old production server.
- Telegram webhook: `https://iamgradov.ru/webhook/bot` was set during smoke test, then deleted with `drop_pending_updates=false`; current Telegram webhook is empty.
- Payment callback route: `https://iamgradov.ru/payments/prodamus/callback`.
- Diaverse delivery worker: temporarily disabled with `DIAVERSE_OUTBOX_ENABLED=false` until the production API exposes the internal payment endpoint. Local callbacks still write bot-local state and durable outbox rows.
- Caddy route validation: passed; reload completed.
- Static site smoke check: `GET https://iamgradov.ru/` returned `200`.
- Callback route smoke check: empty `POST https://iamgradov.ru/payments/prodamus/callback` returned `400 order_id required` from aiohttp through Caddy, so routing reaches the bot.

Restored DB counts:

```text
users=429
club_subscriptions=18
pay1time_payment_attempts=189
payments=21
diaverse_event_outbox=0
```

`scripts/verify_restore.py` passed on the server. The bootstrap dry-run found
14 active subscriptions to mirror into Diaverse and queued `0` events because it
was intentionally run without `--enqueue`.

Do not run bootstrap with `--enqueue` and do not switch Prodamus production
settings until `https://api.diaverse.app/v1/internal/club/payment-events` exists
in production. On 2026-05-20 that endpoint still returned `404 Not Found`,
which means the production `diaverseapi` code has not received the new payment
bridge deployment yet. Re-enable the delivery worker with
`DIAVERSE_OUTBOX_ENABLED=true` and restart `club10000_bot` only after that API
deployment is verified.

Before starting `club10000_bot`, confirm:

- `BOT_TOKEN` is the expected `@club10000_bot` token.
- The token is not reused by `copywriting-clubbot`.
- Runtime mode is explicit: webhook through `iamgradov.ru/webhook/bot` or polling, not both.
- `copywriting-clubbot` remains running for Diaverse club operations.
- `club10000_postgres` is not exposed publicly.

Roster sync operational logs to grep:

- `copywriting.userbot.club_roster.*`
- `copywriting.userbot.club_roster.preflight.*`
- `[club] roster snapshot`
- `[club] roster sync run`
- `[club.steps] daily snapshot complete`

Set the webhook to the external `copywriting-clubbot` endpoint and include allowed updates:

```text
chat_join_request
chat_member
message
my_chat_member
```

Preflight before launch:

- Bot identity is the expected club bot.
- Bot is inside the target supergroup.
- Bot is admin where needed.
- Bot can see join requests/member updates.
- Bot can approve join requests.
- Bot can create invite links.
- Bot can send messages/photos to configured topics if a Bot API fallback target is used.
- Premium userbot account is inside the target supergroup, can send messages/photos to the configured leaderboard topic, and can enumerate members for roster sync.
- Future removal flow requires ban/unban permissions.

## Club10000 Payment Bridge Rollback

Rollback is deliberately split by owner so the bot can be stopped without
touching the Diaverse database.

1. In Prodamus, switch the callback URL back to the previous production
   endpoint. Record the exact old and new callback URLs.
2. On `72.56.108.222`, inspect the latest local outbox state before stopping:

```bash
cd /srv/club10000-bot
docker compose -f docker-compose.production.yml exec postgres sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT id, status, event_kind, provider_order_id, created_at, delivered_at FROM diaverse_event_outbox ORDER BY id DESC LIMIT 20;"'
```

3. Stop only the Club10000 bot runtime if callbacks or Telegram webhook traffic
   must be paused:

```bash
cd /srv/club10000-bot
docker compose -f docker-compose.production.yml stop bot
```

4. Revert only the Caddy `handle /payments/prodamus/callback` and
   `handle /webhook/bot` blocks if route rollback is required. Keep the static
   site fallback unchanged.
5. Validate and reload Caddy:

```bash
docker exec iamgradov-caddy caddy validate --config /etc/caddy/Caddyfile
docker exec iamgradov-caddy caddy reload --config /etc/caddy/Caddyfile
```

6. Leave `club10000_postgres` data intact unless an explicit data rollback is
   requested. Duplicate payment events are idempotent in `club10000-bot` and in
   `diaverseapi`, so retrying after rollback should not create duplicate
   memberships or contracts.

## Roster Model

Telegram Bot API is not used as a full group member directory. The roster is built from:

- Prodamus initial paid callbacks.
- Manual staff additions.
- Bulk imports for migration/VIP/test cases.
- Telegram join/chat-member events.
- Periodic `copywriting-userbot` MTProto roster scans.
- Staff-assisted verification events.
- Known-user checks such as `getChatMember` when a numeric Telegram user id is already known.

Username-only imports stay `pending_verification` and are excluded from leaderboards until a numeric Telegram user id is verified or staff applies an explicit override reason.

Users do not need to confirm themselves with `/start` in v1. Bot DM/start confirmation remains a future enhancement.

Roster sync flow:

1. `copywriting-userbot` scans the club supergroup with Pyrogram/MTProto.
2. It sends signed batches to `POST /v1/internal/club/telegram/roster-snapshot`.
3. `diaverseapi` creates or updates `ClubMembership` rows with source `telegram_roster_scan`.
4. Real-time no-link joins from `copywriting-clubbot` create review rows with source `telegram_join`; joins that carry Telegram `invite_link` metadata create or update `source=invitation` and activate after in-chat presence is confirmed.
5. Neither path creates a game `User`. `ClubMembership.user_id` is linked only when an existing user can be matched by Telegram identity.
6. Linked members read steps from `user_activities`; unlinked members remain visible in `/staff/club/members` and do not break leaderboard snapshots.
7. A completed full scan may mark missing members as `suspected_left`. Partial or failed scans must not mark members missing.

Roster status is visible in `/staff/club/settings`. Member filters in `/staff/club/members` include linked/unlinked, Telegram presence, and source. Staff may retry linking by Telegram id or link to an explicit game user UUID.

Roster sync is disabled by default. Enable it only after the userbot account resolves the club chat and can read participants. If the userbot cannot read members, keep `CLUB_ROSTER_SYNC_ENABLED=false` and use `copywriting-clubbot` real-time events plus staff overrides until permissions are fixed.

## Onboarding Flow

Manual/staff path:

1. Staff creates a manual member or bulk import row in `/staff/club/members`.
2. If only username/display name is known, membership remains `pending_verification`.
3. Staff generates a verification code.
4. The member sends `/verify_club <manual_access_id> <code>` in the Telegram group, or staff verifies the numeric Telegram id in the panel.
5. `copywriting-clubbot` sends a signed `staff_verification` event to `diaverseapi`.
6. `diaverseapi` records the Telegram event, verifies the code, activates membership, records a membership event, and assigns a buddy pair.

Paid path:

1. Prodamus initial paid callback finalizes a `club` payment session.
2. `diaverseapi` creates or reuses a `paid_pending_join` membership and payment contract.
3. Staff or future product flow generates an invite/join path.
4. `copywriting-clubbot` sends join/member events to `diaverseapi`.
5. Once numeric Telegram identity is known, membership activates and buddy pairing runs.

Invitation path:

1. A user enters or requests to enter the closed Telegram group through a Telegram invite link.
2. `copywriting-clubbot` forwards the join request or chat-member update with `invite_link` metadata.
3. `diaverseapi` records the membership as `source=invitation`; no-link joins stay review-only.
4. When the member is confirmed in chat, backend activation runs, the member enters normal leaderboards and buddy pairing, and existing outbox commands queue the welcome and pair notices.

The public checkout/join UX is intentionally deferred until product details are confirmed.

Cabinet member activation:

1. `diaverseapi` generates a member-specific opaque activation URL for the
   Telegram welcome message. Raw activation tokens are never stored; only token
   hashes are persisted.
2. The URL opens `diaweb` at `/{locale}/club?activation=<token>`. The cabinet
   auth redirect must preserve the full query string so Telegram login returns
   to the same activation URL.
3. The web BFF proxies onboarding calls through `/api/cabinet/club/*` to
   `/v1/cabinet/club/*` with cabinet cookies and `x-platform: cabinet`.
4. The `/club` cabinet route is auth-only and renders in fullscreen mode without
   the standard cabinet topbar, footer, or bottom nav while onboarding is active.
5. Onboarding progress is stored on `ClubMembership.metadata_json["onboarding"]`
   for this MVP. The route can claim activation, fetch state, save progress, and
   complete into a simple club hub.
6. `referral_enabled=false` is intentional for this launch. The UI may show a
   deferred cashback/referral placeholder, but it must not generate a personal
   referral link, cashback balance, Decardium reward, or referral bot flow.

## Outbox Contract

`diaverseapi` persists desired Telegram actions in `club_tg_outbox`. `copywriting-clubbot` claims and executes them.

Claim:

```http
POST /v1/internal/club/outbox/claim
```

Ack:

```http
POST /v1/internal/club/outbox/{command_id}/ack
```

Nack:

```http
POST /v1/internal/club/outbox/{command_id}/nack
```

Every command has an idempotency key, attempt count, lease, retry metadata, and dead-letter state. Telegram failures must remain visible in `/staff/club/alerts`.

## Leaderboards And AI Images

The ranking source of truth is:

```text
active/manual active/payment grace club memberships
+ user_activities step rows
-> ClubDailyStepSnapshot
-> ClubLeaderboardSnapshot.snapshot_json
```

Screenshots and Telegram reports are evidence only. They do not replace DB step aggregation.

Image/publish flow:

1. Staff or scheduled job builds leaderboard snapshots.
2. `diaverseapi` sends a signed HMAC request to `aibot` with the exact `snapshot_json`, target profile, and optional leaderboard topic/thread id.
3. `aibot` creates/reuses an idempotent image asset and worker job.
4. Worker generates an image. If the target uses `publish_transport=userbot`, `aibot` enqueues a `copywriting-userbot` publish job for the existing Premium userbot session.
5. The userbot runtime posts the image/caption into the configured Telegram topic. For current Pyrogram support, topic routing is passed as `reply_to_message_id` / topic root message id.
6. Bot API targets with `publish_transport=bot` remain an explicit fallback and use env-backed bot tokens only.
7. `diaverseapi` stores aibot asset/publish ids and separate publish status fields in `ClubLeaderboardSnapshot.metadata_json`.
8. `/staff/club/leaderboards` shows the exact payload table, preview image, asset status, publish status, transport, topic strategy, publish job id, message ids, idempotency key, and retry/publish actions.

AI image text is presentational. `ClubLeaderboardSnapshot.snapshot_json` remains authoritative.

## Prodamus Recurring Guardrails

Recurring automation is not fully implemented in this slice. The schema and state machine are prepared for it.

For the Club10000 migration path, Prodamus callbacks should first reach the standalone `club10000-bot` service. `club10000-bot` keeps its local operational state and sends a normalized signed payment event to `diaverseapi`, where `club_payment_contracts` and `club_memberships` are updated for staff visibility.

Rules for the future implementation:

- No reminders before renewal. Do not send "3 days left" pre-renewal pushes.
- React only after an actual failed renewal event from Prodamus.
- Day 0 failed renewal moves the member to payment grace/paused and queues a DM.
- Days 1 and 2 may queue soft DMs.
- During grace, keep the current pair but do not assign the member into new pairs.
- If renewal succeeds during grace, return to active.
- At the deadline, expire for nonpayment, queue final DM, queue Telegram removal through outbox, and reform the affected pair.
- Confirm exact Prodamus recurring callback payloads before coding the jobs.

## Alerts

Club alerts are persisted through the existing cabinet logging/alert pipeline with module `club`, but all staff workflows for club alerts live in `/staff/club`.

Initial alert sources:

- Silent member detection.
- Telegram delivery failures.
- Onboarding/verification failures.
- Future payment grace and removal failures.

Do not add a separate club alert workflow under `/staff/logging`.
