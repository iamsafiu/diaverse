# Research

Updated: 2026-06-26 21:53
Status: active

## Active Summary (input for /aif-plan)
<!-- aif:active-summary:start -->
Topic: Telegram Codex ops-agent interaction modes
Goal: Let the Telegram ops bot work both as a normal conversational bot and as an operational case runner without starting the heaviest Codex flow for every casual message.
Constraints:
  - Explore mode allows persisting research only in `.ai-factory/RESEARCH.md`; `.ai-factory/PLAN.md` should be updated later through `$aif-plan` or `$aif-improve`
  - The bot should remain simple enough for MVP: Telegram control plane, Codex as worker brain, no custom rich Codex client at first
  - Casual chat must not accidentally execute repair actions or use production write capabilities
  - Case mode may use playbooks, similar case memory, read-only DB diagnostics, Codex investigation, and registered/generated actions according to risk policy
Decisions:
  - Support two modes:
    - Chat mode: free-form conversation, lightweight Codex/LLM call or resumed chat thread, no repair execution.
    - Case mode: create/resume ops case, load playbook, inspect similar cases, run read-only diagnostics, invoke Codex investigation, then preview/execute actions by risk policy.
  - Free-form Telegram messages should be classified by intent:
    - casual/general question -> Chat mode
    - incident/support request -> ask to create an ops case or auto-create when confidence is high
    - explicit command -> route directly
  - Required Telegram commands:
    - `/chat <text>` for lightweight conversation
    - `/ops <text>` for case creation
    - `/case <id>` for case resume
    - `/status` for active cases
    - `/close` for closing the active case
    - `/mode chat|ops` for default behavior in the current Telegram thread
  - Persist thread mapping by `telegram_chat_id`, optional `telegram_thread_id`, `telegram_user_id`, `active_codex_thread_id`, and optional `active_case_id`.
  - Use `codex exec resume <thread_id>` for follow-up messages when possible instead of starting a new Codex thread every time.
  - For the first implementation, prefer `codex exec --json` as the worker interface. Hooks/notify are outbound alerts only; MCP is optional tooling inside Codex; app-server/SDK can come later if richer thread control is needed.
Open questions:
  - Whether Chat mode should use Codex only, or a cheaper direct LLM path for simple non-code conversation.
  - Whether incident intent should auto-create cases or always ask confirmation for the first MVP.
  - How long to keep a chat thread active before expiring the `active_codex_thread_id`.
Success signals:
  - The operator can casually talk to the bot without creating cases or touching repair actions.
  - A clear ops request creates or resumes a case and runs the heavier playbook/diagnostic/Codex flow.
  - Follow-up messages continue the right Codex thread or case instead of losing context.
  - Tests cover intent classification, mode switching, thread persistence, and separation between Chat mode and action execution.
Next step: Update `.ai-factory/PLAN.md` through `$aif-plan` or `$aif-improve` to include Telegram interaction modes in the architecture decisions, Task 10 runtime deliverables, Task 13 lifecycle, verification plan, and definition of done.
<!-- aif:active-summary:end -->

## Sessions
<!-- aif:sessions:start -->
### 2026-06-26 21:53 - Telegram bot chat and case modes
What changed:
  Captured the decision that the Telegram ops bot should support both normal conversation and explicit operational case workflows.

Key notes:
  - Chat mode handles ordinary messages and questions without repair/action execution.
  - Case mode creates or resumes ops cases, loads playbooks, checks similar cases, runs read-only diagnostics, and invokes Codex investigation.
  - Free-form messages should be intent-classified before choosing mode.
  - Required commands should include `/chat`, `/ops`, `/case`, `/status`, `/close`, and `/mode chat|ops`.
  - Persist thread mapping by Telegram chat/thread/user and Codex thread/case ids.
  - Prefer `codex exec --json` and `codex exec resume` for MVP worker control.
  - Use hooks/notify only for outbound alerts, MCP only as optional Codex tooling, and app-server/SDK later for richer thread control if needed.

Links (paths):
  - `.ai-factory/PLAN.md`
  - `aibot/app/ops_agent/handlers.py`
  - `aibot/app/ops_agent/orchestrator.py`
  - `aibot/app/ops_agent/codex_runner.py`

### 2026-06-23 07:33 - Factory map/layout convention
What changed:
  Captured the product convention that all factory levels must use the same playable map and the same workshop layout/hotspot geometry.

Key notes:
  - Current source verification found shared hotspot geometry in `diaweb/frontend/modules/factory/assetManifest.ts`, so workshop positions were not removed.
  - Initial source verification found that level 2 and level 3 did not resolve to the exact same playable background/aspect ratio.
  - Follow-up implementation aligned level visual keys and level 3 preview to the shared playable map asset/geometry.

Links (paths):
  - `diaweb/frontend/modules/factory/assetManifest.ts`
  - `diaweb/frontend/modules/factory/components/FactoryScene.tsx`
  - `diaweb/frontend/__tests__/modules/factory/FactoryScene.test.tsx`

### 2026-06-04 11:55 - April and May Advent revenue strategy
What changed:
  Captured a read-only production analysis of the April and May Advent calendars, including configuration, revenue, payment methods, currency behavior, paid-day funnel performance, and a recommended monetization strategy toward 2000 USDT calendar revenue.

Methodology:
  - Used local project context and source code to verify Advent models, finance reporting, and payment fact logic.
  - Queried production PostgreSQL through existing server access with read-only SQL.
  - Counted only successful paid Advent unlocks within the 2026 calendar windows.
  - Treated USD and USDT source prices as base real-money revenue; RUB is provider collection currency for Pay1Time/Prodamus after FX.
  - Excluded raw user identifiers, guest session identifiers, IPs, tokens, checkout URLs, provider payloads, and other sensitive values.
  - Noted but excluded old 2024 Zion success rows attached to the April calendar from 2026 window analysis.

Calendar configuration:
  - April calendar: `aprelskiy_kalendar`, title `Апрельский календарь`, 15 days, 2026-04-15 through 2026-04-30, 6 paid days and 9 free days, full paid path 19 USD.
  - April paid days: day 3 = 1 USD `Галаклей`; day 5 = 2 USD `Необычная шкатулка`; day 8 = 4 USD `Редкая шкатулка`; day 11 = 3 USD `ДНК капсулы`; day 13 = 5 USD `Кирпичи`; day 15 = 4 USD `Легендарная шкатулка`.
  - May calendar: `mayskiy_kalendar`, title `Майский календарь`, 31 days, 2026-05-01 through 2026-06-05, active and published as of 2026-06-04, 8 paid days and 23 free days, full paid path 29 USD.
  - May paid days: day 5 = 2 USD `Необычная шкатулка`; day 9 = 3 USD `Редкая шкатулка`; day 12 = 2 USD `Эпическая шкатулка`; day 15 = 4 USD `Эпическая шкатулка`; day 18 = 5 USD `Шестеренки`; day 23 = 3 USD `Кирпичи`; day 26 = 4 USD `ДНК капсулы`; day 30 = 6 USD `Эвоген эпический`.

Revenue summary:
  - April full window: 555 starters, 24 completed, 4.3% completion, average reached day 6.35, 64 unique payers, 233 paid payments, 653 USDT revenue, 2.80 USDT average payment, 10.20 USDT ARPPU.
  - May month only, 2026-05-01 through 2026-05-31: 759 starters, 35 completed, 4.6% completion, average reached day 12.71, 73 unique payers, 385 paid payments, 1285 USDT revenue, 3.34 USDT average payment, 17.60 USDT ARPPU.
  - May line-to-date, 2026-05-01 through 2026-06-04: 773 starters, 35 completed, 4.5% completion, average reached day 12.62, 74 unique payers, 404 paid payments, 1344 USDT revenue, 3.33 USDT average payment, 18.16 USDT ARPPU.
  - To reach 2000 USDT from the May line-to-date baseline, the gap is about 656 USDT. At 74 payers, required ARPPU is about 27.03 USDT.

Payment methods and currency:
  - April Pay1Time/SBP: 219 paid payments, 57 paid actors, 614 USDT revenue, about 48757.80 RUB provider total.
  - April Prodamus: 6 paid payments, 4 paid actors, 21 USDT revenue, about 1574.51 RUB provider total.
  - April Zion crypto: 8 paid payments, 6 paid actors, 18 USDT revenue.
  - May through 2026-06-04 Pay1Time/SBP: 373 paid payments, 67 paid actors, 1253 USDT revenue, about 95705.99 RUB provider total.
  - May through 2026-06-04 Prodamus: 24 paid payments, 10 paid actors, 73 USDT revenue, about 5248.30 RUB provider total.
  - May through 2026-06-04 Zion crypto: 7 paid payments, 3 paid actors, 18 USDT revenue.
  - May checkout behavior shows crypto as high-friction: 178 crypto attempt actors produced only 3 paid actors by 2026-06-04, while Pay1Time carried more than 90% of revenue.

Actual reward source of truth:
  - The effective reward list comes from `cab_advent_item_rewards` when rows exist for a cell.
  - If `cab_advent_item_rewards` exists, `CabAdventService._resolve_rewards_for_item` grants that list instead of the primary `cab_advent_items.reward_*` fields.
  - There are no run override rows for the April or May calendars, so the reward lists below are the effective run-1 rewards.
  - April has 33 `cab_advent_item_rewards` rows; May has 49 `cab_advent_item_rewards` rows.
  - Some configured cell titles do not match the effective reward bundle. This matters because players buy perceived value, not hidden DB value.

April reward map:
  - Day 1 free, title `Кирпичи`: Кирпичи x50.
  - Day 2 free, title `Шестеренки`: Шестеренки x50.
  - Day 3 paid 1 USD, title `Галаклей`: Базовая шкатулка x5; Галаклей x300; Обычный мутаген x10; Ядерные желуди x300.
  - Day 4 free, title `ДНК капсулы`: ДНК капсулы x50.
  - Day 5 paid 2 USD, title `Необычная шкатулка`: Кирпичи x2000; Глаз оракула редкий x5; Необычная шкатулка x10; Обычный мутаген x20.
  - Day 6 free, title `Галаклей`: Галаклей x500.
  - Day 7 free, title `Серебряный ваучер в Пустоши`: фактически Галаклей x700.
  - Day 8 paid 4 USD, title `Редкая шкатулка`: Эвоген редкий x1; Редкий мутаген x20; Ядерные желуди x500; Редкая шкатулка x10; Шестеренки x300.
  - Day 9 free, title `Кирпичи`: Кирпичи x1000.
  - Day 10 free, title `Серебряный ваучер в Оазис`: фактически ДНК капсулы x100.
  - Day 11 paid 3 USD, title `ДНК капсулы`: Редкий мутаген x20; XP капсулы x200; ДНК капсулы x500; Глаз оракула эпический x5.
  - Day 12 free, title `Эвоген редкий`: Эвоген редкий x1.
  - Day 13 paid 5 USD, title `Кирпичи`: Кирпичи x10000; Обычный мутаген x50; Эпическая шкатулка x10.
  - Day 14 free, title `Мифическая шкатулка`: фактически Эвоген легендарный x1.
  - Day 15 paid 4 USD, title `Легендарная шкатулка`: Редкий мутаген x20; Легендарная шкатулка x10; Страховка мутации x5; XP капсулы x300.

May reward map:
  - Day 1 free, title `Патроны`: Патроны x50.
  - Day 2 free, title `Кирпичи`: Кирпичи x50.
  - Day 3 free, title `Базовая шкатулка`: ДНК капсулы x20; Базовая шкатулка x5.
  - Day 4 free, title `Галаклей`: Галаклей x50.
  - Day 5 paid 2 USD, title `Необычная шкатулка`: фактически Мифическая шкатулка x5; XP капсулы x1500.
  - Day 6 free, title `Шестеренки`: Шестеренки x100.
  - Day 7 free, title `ДНК капсулы`: ДНК капсулы x100.
  - Day 8 free, title `Ядерные желуди`: Ядерные желуди x150.
  - Day 9 paid 3 USD, title `Редкая шкатулка`: фактически XP капсулы x1500; Легендарная шкатулка x10.
  - Day 10 free, title `Кирпичи`: Кирпичи x500.
  - Day 11 free, title `Ядерные желуди`: Ядерные желуди x400.
  - Day 12 paid 2 USD, title `Эпическая шкатулка`: Обычный мутаген x50; Эпическая шкатулка x5; Кирпичи x10000.
  - Day 13 free, title `Патроны`: Патроны x500.
  - Day 14 free, title `XP капсулы`: XP капсулы x100.
  - Day 15 paid 4 USD, title `Эпическая шкатулка`: Обычный мутаген x50; Кирпичи x20000; Патроны x5000; Эпическая шкатулка x5.
  - Day 16 free, title `ДНК капсулы`: ДНК капсулы x150.
  - Day 17 free, title `Галаклей`: Галаклей x750.
  - Day 18 paid 5 USD, title `Шестеренки`: Шестеренки x4000; Эпическая шкатулка x10; Кирпичи x15000; XP капсулы x300; Редкий мутаген x30.
  - Day 19 free, title `Ядерные желуди`: Ядерные желуди x500.
  - Day 20 free, title `Глаз оракула эпический`: Глаз оракула эпический x5.
  - Day 21 free, title `Эвоген редкий`: Эвоген редкий x1.
  - Day 22 free, title `Патроны`: Патроны x1500.
  - Day 23 paid 3 USD, title `Кирпичи`: ДНК капсулы x500; Редкий мутаген x30; Кирпичи x10000.
  - Day 24 free, title `Мифическая шкатулка`: Мифическая шкатулка x5.
  - Day 25 free, title `Обычный мутаген`: Обычный мутаген x30.
  - Day 26 paid 4 USD, title `ДНК капсулы`: ДНК капсулы x500; XP капсулы x200; Шестеренки x2000; Ядерные желуди x5000.
  - Day 27 free, title `Кирпичи`: Кирпичи x10000.
  - Day 28 free, title `Легендарная шкатулка`: Легендарная шкатулка x5.
  - Day 29 free, title `Редкий мутаген`: Редкий мутаген x20.
  - Day 30 paid 6 USD, title `Эвоген эпический`: Эвоген эпический x2.
  - Day 31 free, title `Эвоген эпический`: Легендарный мутаген x10; Эвоген эпический x1.

Reward-to-funnel interpretation:
  - April day 3 and May day 5 were generous first paid bundles, but both performed poorly. April day 3 gave four reward types for 1 USD and converted only 12.7% of reached users. May day 5 gave Mythical box x5 plus XP x1500 for 2 USD and converted only 10.8% of reached users. This points to first-payment psychology and checkout friction, not insufficient reward value.
  - Later paid days convert well because the audience is already qualified. April day 13 converted 93.1% of reached users at 5 USD with Epic box x10 plus Brick x10000 plus Common mutagen x50. May day 30 converted 89.2% of reached users at 6 USD with Epic EvoGen x2.
  - Strong late free rewards such as May day 24 Mythical box x5, day 28 Legendary box x5, and day 31 Epic EvoGen plus Legendary mutagen are good for satisfaction, but they do not solve acquisition into the paying path because only about 4.5% of starters complete the calendar.
  - May has better perceived jackpot design than April: Legendary box x10 at day 9, repeated Epic boxes, large resource bundles, and Epic EvoGen x2 at day 30. This likely helped ARPPU rise from 10.20 to 18.16 USDT.
  - Several title/reward mismatches probably reduce conversion: May day 5 is titled `Необычная шкатулка` but grants `Мифическая шкатулка x5`; May day 9 is titled `Редкая шкатулка` but grants `Легендарная шкатулка x10`; April day 14 is titled `Мифическая шкатулка` but grants `Эвоген легендарный x1`; April day 7 and day 10 are titled as vouchers but grant resources. The player-facing cell should advertise the best actual reward.
  - Reward bundles should be named as bundles when there are multiple rewards. For example, `Мифический набор: шкатулки + XP`, `Легендарный набор`, `Эвоген-пак`, `Мутационный набор`. A single title hides value when a paid cell grants 3-5 items.

Reward-driven strategy update:
  - Keep the first paid gate at day 5 or later, but make it an explicitly named bundle. Example: `Мифический стартовый набор` with Mythical box x5 plus XP/resource bonus.
  - Do not underprice or hide late high-value cells. Day 30-style EvoGen rewards can anchor the pass price: the pass is not buying small cells, it is buying guaranteed access to the EvoGen/jackpot track.
  - Put the highest-perceived reward classes on paid milestones: Legendary/Mythical boxes, EvoGen vouchers, rare/legendary mutagens, and utility boosts. Use plain resources as secondary fillers, not as the headline paid reward.
  - Use free days immediately before paid gates to build desire for the next paid cell: tease the category, then pay off with a bundle. Example: free day 8 gives nuclear acorns, paid day 9 gives `Легендарный набор`.
  - Avoid naming paid cells by a low-prestige component when the actual bundle contains a higher-prestige item. The visible name should always be the strongest item.

April paid-day funnel:
  - Day 3, 1 USD: 441 reached from previous day, 142 attempted, 56 paid, 62 payments, 62 USDT revenue. Reached-to-paid was 12.7%; attempt-to-paid was 39.4%.
  - Day 5, 2 USD: 80 reached, 47 attempted, 34 paid, 40 payments, 80 USDT revenue. Reached-to-paid was 42.5%; attempt-to-paid was 72.3%.
  - Day 8, 4 USD: 55 reached, 33 attempted, 29 paid, 34 payments, 136 USDT revenue. Reached-to-paid was 52.7%; attempt-to-paid was 87.9%.
  - Day 11, 3 USD: 38 reached, 36 attempted, 29 paid, 34 payments, 102 USDT revenue. Reached-to-paid was 76.3%; attempt-to-paid was 80.6%.
  - Day 13, 5 USD: 29 reached, 28 attempted, 27 paid, 31 payments, 155 USDT revenue. Reached-to-paid was 93.1%; attempt-to-paid was 96.4%.
  - Day 15, 4 USD: 27 reached, 24 attempted, 24 paid, 28 payments, 112 USDT revenue. Reached-to-paid was 88.9%; attempt-to-paid was 100.0%.

May paid-day funnel through 2026-06-04:
  - Day 5, 2 USD: 627 reached from previous day, 247 attempted, 68 paid, 78 payments, 156 USDT revenue. Reached-to-paid was 10.8%; attempt-to-paid was 27.5%.
  - Day 9, 3 USD: 73 reached, 63 attempted, 57 paid, 63 payments, 189 USDT revenue. Reached-to-paid was 78.1%; attempt-to-paid was 90.5%.
  - Day 12, 2 USD: 59 reached, 52 attempted, 51 paid, 56 payments, 112 USDT revenue. Reached-to-paid was 86.4%; attempt-to-paid was 98.1%.
  - Day 15, 4 USD: 52 reached, 44 attempted, 42 paid, 47 payments, 188 USDT revenue. Reached-to-paid was 80.8%; attempt-to-paid was 95.5%.
  - Day 18, 5 USD: 44 reached, 39 attempted, 37 paid, 40 payments, 200 USDT revenue. Reached-to-paid was 84.1%; attempt-to-paid was 94.9%.
  - Day 23, 3 USD: 39 reached, 37 attempted, 37 paid, 40 payments, 120 USDT revenue. Reached-to-paid was 94.9%; attempt-to-paid was 100.0%.
  - Day 26, 4 USD: 39 reached, 36 attempted, 36 paid, 39 payments, 156 USDT revenue. Reached-to-paid was 92.3%; attempt-to-paid was 100.0%.
  - Day 30, 6 USD: 37 reached, 33 attempted, 33 paid, 35 payments, 210 USDT revenue. Reached-to-paid was 89.2%; attempt-to-paid was 100.0%.

Key interpretation:
  - The early paid gate is the biggest revenue and retention leak. April day 3 and May day 5 converted only about 11-13% of users who had reached the previous day.
  - Once a user crosses the first paid gate, later paid cells convert very strongly, often 80-95% of reached users.
  - The calendar currently monetizes a small but committed paying segment; the next revenue step should increase first-purchase conversion and ARPPU, not simply add more blockers.
  - May improved ARPPU from 10.20 to 18.16 USDT, but still needs about 27 USDT ARPPU at current payer volume to reach 2000 USDT.
  - Pay1Time/SBP should be the primary payment path; crypto should remain available but not be the main CTA.

Recommended 31-day monetization model:
  - Keep paid days at 8, but make the first four days free to build commitment before the first paywall.
  - Paid day placement: 5, 9, 12, 15, 18, 23, 26, 30.
  - A-la-carte prices: day 5 = 3 USD, day 9 = 4 USD, day 12 = 3 USD, day 15 = 5 USD, day 18 = 6 USD, day 23 = 5 USD, day 26 = 5 USD, day 30 = 9 USD.
  - Full a-la-carte path: 40 USD.
  - Early full pass before day 5: 24.90 USD.
  - Regular full pass after day 5: 29.90 USD.
  - Mini-pass for first three paid days: 8.90-9.90 USD.
  - Psychological framing: sell the pass as a premium route with guaranteed access and visible savings, not as a punishment for free players.

Recommended 15-day monetization model:
  - Use 4 paid days instead of 6 to avoid an overly dense short-calendar paywall.
  - Paid day placement: 5, 8, 11, 15.
  - A-la-carte prices: 3 USD, 4 USD, 5 USD, 8 USD.
  - Full a-la-carte path: 20 USD.
  - Short-calendar pass: 14.90 USD.

Priority actions:
  - Move the first paid gate away from day 3; day 5 is the earliest reasonable first premium day.
  - Add full pass and mini-pass products so ARPPU can rise without relying only on many low-value payments.
  - Make Pay1Time/SBP the dominant visible payment CTA and offer a clear fallback from failed/abandoned crypto attempts.
  - Do not increase paid-day count until first-gate conversion improves.
  - Track next launch with these KPIs: first paid gate reached-to-attempt, reached-to-paid, pass conversion, ARPPU, Pay1Time success rate, crypto fallback recovery, completion rate, and revenue per starter.

Links (paths):
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\offers\advent\models.py`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\offers\advent\payment_facts.py`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\finance\reporting.py`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\analytics\usecases.py`

### 2026-05-25 - Local GBrain workspace knowledge layer
What changed:
  Switched the active workspace knowledge decision to local GBrain sources over root documentation, AI Factory context, and the four child code repositories.

Key notes:
  - GBrain is local CLI-first through `scripts/gbrain.ps1`
  - Project-local state lives under `.tools/gbrain/home`
  - Stable source IDs are `diaverse-docs`, `diaverse-aif`, `diaweb-code`, `diaverseapi-code`, `aibot-code`, and `club10000-bot-code`
  - No public HTTP MCP, ChatGPT connector, tunnel, daemon, or raw conversation auto-capture is enabled by default
  - Source code and canonical docs remain the final authority

Links (paths):
  - `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain.ps1`
  - `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-sync.ps1`
  - `C:\Users\Indigo\Desktop\diaverse\scripts\gbrain-health.ps1`
  - `C:\Users\Indigo\Desktop\diaverse\docs\knowledge-system.md`

### 2026-04-28 - Pets and pet skins source of truth
What changed:
  Captured the backend catalog model for Diaverse pets and pet skins after the production audit showed mixed base pets, legacy character variants, default visuals, and item skins.

Key notes:
  - `characters.subkind = default` is the only normal base-pet shape.
  - `characters.subkind != default` is a legacy/event character variant and must not be sold or granted as a new base pet.
  - `pet_skin_defs.is_default = true` is a bundled default age/evolution visual, not a `UserSkinItem`.
  - `pet_skin_defs.is_default = false AND is_acquirable = true` is a real item/equippable pet skin.
  - `pet_skin_defs.is_default = false AND is_acquirable = false` is a legacy/non-acquirable skin definition.
  - User-approved decisions: Красная панда is a skin of Панда; Кенгуру-победитель is a skin of Кенгуру; Единорог is a base pet without approved item skins; Огонёк, Кристаллик, and Лианчик are three different base pets; missing skins must wait for real assets/data.

Links:
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\docs\pets-skins-catalog.md`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\docs\pets-skins-canonical-manifest.md`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\docs\sql\pets_skins_preflight.sql`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\docs\sql\pets_skins_postcheck.sql`

### 2026-04-21 16:40 - Workspace AI coordination bootstrap
What changed:
  Established the decision to keep a shared workspace root with top-level Graphify and AI Factory context while preserving the three separate repositories.

Key notes:
  - `diaweb` already had the richest AI context and skill pack
  - `aibot` had partial AI Factory state
  - `diaverseapi` had no local AI Factory files
  - Top-level Graphify and MCP are the right place to unify architectural context

Links (paths):
  - `C:\Users\Indigo\Desktop\diaverse\diaweb`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi`
  - `C:\Users\Indigo\Desktop\diaverse\aibot`

### 2026-04-21 16:45 - Shared graph runtime wired and validated
What changed:
  Installed Graphify into `C:\Users\Indigo\Desktop\diaverse\.tools\graphify\.venv`, enabled Codex integration, created a shared Graphify MCP server, and produced the first workspace graph artifacts.

Key notes:
  - `ai-factory init --agents codex --no-skills --mcp filesystem,playwright,postgres,chrome-devtools` was enough to bootstrap top-level AI Factory metadata without moving repo-local contexts
  - `graphify codex install` added always-on Graphify guidance and a Codex pre-tool hook at the workspace root
  - The installed `graphify` CLI exposes `update`, `query`, `path`, `explain`, and `serve`; the slash-command examples in the README map to skill behavior, not a public `graphify .` CLI subcommand
  - The workspace graph is large enough to exceed Graphify's default HTML visualization limit (`MAX_NODES_FOR_VIZ = 5000`), so the workspace scripts now rebuild through a helper that safely raises the cap for this workspace
  - Current shared graph outputs:
    - `C:\Users\Indigo\Desktop\diaverse\graphify-out\GRAPH_REPORT.md`
    - `C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json`
    - `C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.html`

Validation:
  - Rebuild command: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-build.ps1`
  - Refresh command: `powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-update.ps1`
  - Graph query example: `C:\Users\Indigo\Desktop\diaverse\.tools\graphify\.venv\Scripts\python.exe -m graphify query "show the auth flow" --graph C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json`
  - MCP server command: `C:\Users\Indigo\Desktop\diaverse\.tools\graphify\.venv\Scripts\python.exe -m graphify.serve C:\Users\Indigo\Desktop\diaverse\graphify-out\graph.json`

Recovery steps:
  - If the graph looks stale, rerun `scripts\graphify-update.ps1`
  - If graph files are missing or corrupted, rerun `scripts\graphify-build.ps1`
  - If graph output conflicts with code, trust the code, then refresh the graph

### 2026-04-21 17:10 - Multi-repo AIF full mode decision
What changed:
  Reframed the top-level `diaverse` workspace as the primary operational AIF center, not just a planning brain. The user's preferred workflow is one AIF session from `C:\Users\Indigo\Desktop\diaverse` that may plan, implement, review, verify, and coordinate changes across `diaweb`, `diaverseapi`, and `aibot`.

Key notes:
  - Do not require the user to enter each child repository and run `$aif-implement` separately
  - In the workspace root, `$aif-plan full` means multi-repo full mode over affected child repositories
  - The top-level folder is a coordination git repository only; child repositories stay independent
  - Branches, status checks, staging, and commits remain per child repository
  - The top-level plan remains the single progress source of truth
  - Helper scripts now support status and branch creation/switching across selected child repositories

Links (paths):
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\skill-context\aif-plan\SKILL.md`
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\skill-context\aif-implement\SKILL.md`
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\skill-context\aif-verify\SKILL.md`
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\skill-context\aif-commit\SKILL.md`
  - `C:\Users\Indigo\Desktop\diaverse\scripts\aif-workspace-status.ps1`
  - `C:\Users\Indigo\Desktop\diaverse\scripts\aif-workspace-branch.ps1`

### 2026-04-21 18:01 - Multi-repo AIF housekeeping
What changed:
  Removed stale wording from the active research summary so it consistently treats top-level AIF as the default workspace control plane for planning, implementation, review, verification, and commit coordination.

Key notes:
  - Repo-local AI context remains useful as reference/fallback context
  - Cross-repo progress should stay in the top-level plan under `diaverse\.ai-factory\plans\`
  - `diaverseapi` now has a local `AGENTS.md` map for backend-specific agent guidance

Links (paths):
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\RESEARCH.md`
  - `C:\Users\Indigo\Desktop\diaverse\diaverseapi\AGENTS.md`
  - `C:\Users\Indigo\Desktop\diaverse\.ai-factory\plans\`

### 2026-07-27 00:00 — PvP architecture and implementation boundary
What changed:
  Consolidated the supplied PvP/map specifications, source-code reconnaissance,
  architecture choices, and product decisions into two independently releasable
  implementation plans.

Key notes:
  - Delivery is split into `PvP World & Recon` and `PvP Combat & Consequences`.
  - `diaverseapi/app/pvp` is the server-authoritative bounded context for the
    finite 1000x1000 world, scouting, combat snapshots, attacks, battles,
    settlement, Hospital records, locks, idempotency, and reconciliation.
  - `diaweb/frontend/modules/pvp` owns presentation, polling, confirmations,
    reports, Hospital and repair UX through the same-origin BFF.
  - Public map/profile data is allowlisted; private factory, inventory, pet, and
    Hospital state is exposed only through persisted, granted facts.
  - Combat uses deterministic, versioned rules, immutable evidence, stable
    row-lock ordering, narrow cross-domain gateways, and independently gated
    destructive effects.
  - The final plans and living contracts are preserved under
    `.ai-factory/plans/` and `docs/features/`, with rollout/recovery guidance in
    `docs/runbooks/pvp-combat-consequences.md`.

Links (paths):
  - `.ai-factory/plans/feature-pvp-world-recon.md`
  - `.ai-factory/plans/feature-pvp-combat-consequences.md`
  - `docs/features/pvp-world-recon.md`
  - `docs/features/pvp-combat-consequences.md`
  - `docs/runbooks/pvp-combat-consequences.md`
<!-- aif:sessions:end -->
