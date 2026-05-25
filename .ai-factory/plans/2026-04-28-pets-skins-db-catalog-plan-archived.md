# Plan: приведение петов и скинов к нормальной DB-модели

## Context

- Mode: `fast`
- Workspace: `C:\Users\Indigo\Desktop\diaverse`
- Affected repo: `diaverseapi`
- Current branch in `diaverseapi`: `fix/pets-skins`
- Source audit: `C:\Users\Indigo\Downloads\diaverse-pet-audit`
- Explicit out of scope for this plan: `diaweb` shop UI, mobile app UI, visual fixes in магазине.
- Goal: исправить именно базу данных и backend-правила каталога так, чтобы петы и скины имели один понятный источник истины.

## Implementation Status

- [x] Canonical manifest created: `diaverseapi/docs/pets-skins-canonical-manifest.md`
- [x] Catalog model documentation created: `diaverseapi/docs/pets-skins-catalog.md`
- [x] Preflight SQL created: `diaverseapi/docs/sql/pets_skins_preflight.sql`
- [x] Postcheck SQL created: `diaverseapi/docs/sql/pets_skins_postcheck.sql`
- [x] Backend catalog predicates added: `diaverseapi/app/characters/catalog_rules.py`
- [x] DB migration added: `diaverseapi/migrations/versions/20260428_pets_skins_catalog_cleanup.py`
- [x] Backend catalog/grant guardrails added in `diaverseapi`
- [x] Regression tests added and targeted tests passed locally
- [x] AI memory updated in `.ai-factory/RESEARCH.md`
- [ ] Server preflight SQL must be run before production migration
- [ ] Production/staging migration must be applied by server operator
- [ ] Server postcheck SQL must be run after migration
- [ ] Shop/UI cleanup remains a separate later plan

## Hard Scope Boundary

This plan is DB/catalog-first.

Allowed now:

- inspect DB audit files
- create canonical manifest
- create preflight/postcheck SQL
- create Alembic data migration
- add backend catalog/fulfillment guardrails that protect DB semantics
- update documentation and AI memory docs

Not allowed in this plan:

- change `diaweb`
- redesign or fix shop UI cards
- change mobile app UI
- manually replace visual assets, except reporting missing/broken DB asset references
- silently delete production rows

Shop tables may be used for diagnosis only. Any actual shop display cleanup must be a later separate plan.

## Canonical Rules

These rules are the intended source of truth:

```text
characters.subkind = default
  => base pet

characters.subkind != default
  => legacy/event character variant, not a base pet

pet_skin_defs.is_default = true
  => default age/evolution visual for a base pet, not an item skin

pet_skin_defs.is_default = false
  => real item/equippable pet skin

pet_skin_defs.character_id
  => should point to a base pet: characters.subkind = default
```

## Current Evidence

Source files already inspected:

- `diaverseapi/app/characters/models.py`
  - `Character` table stores pet-like rows.
  - `Character.subkind` is enum `default`, `halloween`, `special`, `christmas`, `asia`, `hippie`, `symbiote`.
  - `UserCharacter.character_id` references `characters.uuid`.
- `diaverseapi/app/pet_skins/models.py`
  - `PetSkinDef.character_id` references `characters.uuid`.
  - Comments already describe `is_default=True` as bundled age visual and `is_default=False` as item skin.
  - `UserSkinItem.skin_def_id` references `pet_skin_defs.uuid`.
- `diaverseapi/app/cabinet/item_catalog/providers.py`
  - `load_character_entries` currently exposes all characters as grantable/rewardable and sellable if `cost > 0`.
  - `load_pet_skin_entries` already makes only `is_default=false` skins grantable/sellable/rewardable.
- `diaverseapi/app/cabinet/shop/seed_data.py`
  - `build_character_seed_specs` currently seeds every positive-cost character as a pet.
  - `build_pet_skin_seed_specs` correctly filters `not skin.is_default`.
- `diaverseapi/app/cabinet/fulfillment/handlers.py`
  - `grant_character_handler` grants any character ref.
  - `grant_pet_skin_handler` delegates to pet skin grant.
- `diaverseapi/app/characters/grants.py`
  - `grant_user_character` currently validates existence only, not `subkind=default`.
- `diaverseapi/app/pet_skins/grants.py`
  - `grant_user_skin_item` already rejects default visuals by filtering `PetSkinDef.is_default == False`.
- `diaverseapi/app/exchange/external/item_service.py`
  - Exchange code already has the correct idea: non-default subkinds are skin variants and should not duplicate into character catalog.

Audit facts:

```text
characters: 84
characters subkind=default: 38
characters subkind!=default: 46
pet_skin_defs: 527
pet_skin_defs is_default=true: 341
pet_skin_defs is_default=false: 186
pet_skin_groups: 115 groups
default visual groups: 77
item skin groups: 38
```

Audit anomaly counts:

```text
46 POSITIVE_COST_NON_DEFAULT_CHARACTER_WILL_SEED_AS_PET
45 SHOP_PET_POINTS_TO_NON_DEFAULT_CHARACTER
10 CHARACTER_VARIANT_WITHOUT_DEFAULT_BASE
7  PET_SKIN_ATTACHED_TO_NON_DEFAULT_CHARACTER
3  DUPLICATE_DEFAULT_CHARACTER_KIND
```

Current item catalog projection also shows 46 non-default characters as grantable/sellable/rewardable characters. This is backend catalog risk, not just shop UI risk.

## Approved Catalog

The user-approved list is the content source of truth.

Rare bases:

- Лис -> Рыжая Лиса, Лиса-пловчиха
- Бык -> Быкозавр
- Тигр -> Тигр из Дерри
- Лев -> Львица
- Тушканчик -> no skins
- Енот -> Пряничный Енот
- Пёс/Собака -> Дискодог
- Белка -> Белка-горелка
- Волк -> Криптоволк
- Заяц -> Шоколадный заяц
- Панда -> Красная панда
- Горилла -> Азартная обезьяна
- Кот -> Кот Спартака
- Хомяк -> Хомяк с Улицы Вязов, Новый Хомяк
- Носорог -> no skins
- Лианчик -> no approved skins
- Сурикат -> no approved skins

Epic bases:

- Медведь -> Белый Медведь, Франкенмииш
- Хамелеон -> Бумелеон
- Капибара -> no skins
- Бегемот -> no skins
- Лемур -> Самка Лемура
- Летучая мышь -> Летучая мышь - Путешественник
- Панголин -> Панголишка, Шейп-Панголин
- Овца -> Кунг-Фу Лама, Моряш
- Крот -> Пасхальный крот
- Олененок -> Золотой Оленёнок
- Гепард -> Гепард-марафонец, Дзен-пантера, Снежный барс, Спортивная Рысь
- Гиена -> no approved skins
- Огонёк -> no approved skins
- Осьминог -> no approved skins

Legendary bases:

- Орел -> Орландец, Хохлатый змеиный орел
- Дракон -> no skins
- Крокодил -> no skins
- Аксолотль -> Самка Аксолотля, Аксолотль ведьма
- Попугай -> Ара Мороженщик, Канарейка Чикс
- Единорог -> no skins
- Ёж -> Ёж-Вампир, Пацанский Ёж
- Кенгуру -> Кенгуру-победитель
- Слон -> no skins
- Барсук -> no skins
- Мистер Пигз/Свинка -> no approved skins
- Бородавочник -> no approved skins
- Кристаллик -> no approved skins
- Бобр -> no approved skins

Known mismatches from the audit:

- Approved base pets currently not clean `subkind=default`: Тушканчик, Носорог, Лианчик, Капибара, Бегемот, Олененок, Дракон, Крокодил, Единорог, Слон, Барсук.
- Approved skins missing as `pet_skin_defs.is_default=false`: Золотой Оленёнок, Гепард-марафонец.
- Approved skins incorrectly duplicated as base pets: Красная панда, Кенгуру-победитель.
- Extra suspicious item skin: Единорог has `pet_skin_defs.is_default=false` rows, but approved list says Единорог has no skins.
- Rarity mismatch: Моряш item skin rows are `rare`, while the approved section/base is epic.
- `kind=mutant` is ambiguous in current DB: Огонёк and Кристаллик are default, Лианчик is special. User decision: these are three different base pets, so the migration must split or otherwise uniquely identify them as separate base identities.

## Approval Gate

Approved by user:

- Красная панда:
  - decision: skin of Панда, not a base pet.
  - DB action: stop treating `characters.Красная панда` as a base pet; keep/ensure item skin defs under base Панда.
- Кенгуру-победитель:
  - decision: skin of Кенгуру, not a base pet.
  - DB action: stop treating `characters.Кенгуру-победитель` as a base pet; keep/ensure item skin defs under base Кенгуру.
- Единорог:
  - decision: base pet without approved skins.
  - DB action: existing `pet_skin_defs.is_default=false` Unicorn rows must become legacy/non-acquirable and must not be issued to new users.
- Missing approved skins:
  - Золотой Оленёнок
  - Гепард-марафонец
  - decision: do not create placeholders; wait for user-provided assets/data.
- Existing user-owned accidental character skins:
  - decision: do not delete user-owned `UserCharacter` rows.
  - DB action: migrate/add equivalent `UserSkinItem` where a matching item skin exists; otherwise keep the old `UserCharacter` as legacy.

Final approved decision:

- `kind=mutant`:
  - decision: Огонёк, Кристаллик, Лианчик are three different base pets.
  - DB action: migration must split or otherwise uniquely identify them as separate base identities; do not keep them as ambiguous variants of one shared base pet.

Approval gate is closed. Data-changing migration may be planned from these decisions, but still requires the normal preflight and staging checks before execution.

## Implementation Tasks

### 1. Create canonical manifest as the source of truth

Create a durable manifest, not just prose documentation.

Recommended artifact:

- `diaverseapi/docs/pets-skins-canonical-manifest.md`

Optional generated companion:

- `diaverseapi/docs/pets-skins-canonical-manifest.csv`

For every approved base pet, include:

- approved Russian name
- approved English/current title if known
- approved rarity
- target `kind`
- target `subkind`
- current `characters.uuid`
- current `characters.title.ru/en`
- current `characters.kind`
- current `characters.subkind`
- current `characters.rarity`
- current default visual group count
- current item skin group count
- target action: keep, reclassify-to-base, split-kind, needs-decision, missing-data

For every approved skin, include:

- approved skin name
- target base pet
- current `pet_skin_defs` group UUIDs/count
- current accidental `characters` duplicate UUID, if present
- target action: keep-item-skin, reattach, mark-missing, mark-legacy-character, needs-decision

This manifest must be reviewed before writing the migration.

### 2. Add preflight audit SQL

Create a repeatable read-only SQL file:

- `diaverseapi/docs/sql/pets_skins_preflight.sql`

It should export or report:

- all `characters` with `subkind`, `kind`, rarity, cost, icon, image
- all grouped `pet_skin_defs` by normalized skin group title
- non-default characters with `cost > 0`
- duplicate default characters by `kind`
- item skins attached to non-default characters
- default visuals attached to non-default characters
- active/sellable catalog rows that point to suspicious characters
- advent/support/fulfillment references for character and pet skin rewards
- static asset reference summary for `characters.icon/image` and `pet_skin_defs.icon/image`

The script must be safe to run on production because it is read-only.

### 3. Export ownership and fulfillment risk

Create or run read-only ownership export before touching data.

Required coverage:

- `user_characters` referencing suspicious or non-default characters
- `user_skin_items` referencing suspicious item skins
- `user_character_skins`
- `cab_fulfillment_lines` for `character` and `pet_skin`
- shop/support/advent references pointing to suspicious entities
- active user characters for rows that may be reclassified

Data-changing migration must not delete any row with ownership or fulfillment references.

Known existing risk from audit:

- recent shop/support/advent fulfillment already contains `character` and `pet_skin` grants.
- at least one support grant exists for a character-style item.

### 4. Decide legacy ownership strategy

Document the exact policy before migration:

- If an approved skin was granted as `UserCharacter`, do not delete it.
- If an equivalent `pet_skin_defs.is_default=false` exists, prefer creating `UserSkinItem` for the user and preserving historical `UserCharacter` as legacy/inactive only if needed.
- If no equivalent item skin exists, keep the legacy `UserCharacter` and block new acquisition paths.
- Never silently convert an active user pet into a skin without reviewing active/rent/evolution/state fields.

This task must produce a decision table for every impacted `characters.uuid`.

### 5. Create data migration plan and dry-run SQL

Prepare one Alembic migration or a controlled SQL migration pair:

- upgrade: data changes
- downgrade or manual rollback notes: exact reverse strategy where safe

Migration should:

- preserve UUIDs whenever existing references depend on them
- reclassify approved base pets to clean `subkind=default` where approved
- reclassify approved skin duplicates away from `subkind=default`
- reattach `pet_skin_defs.character_id` only to approved base pets
- keep missing skins missing and documented, not fabricated
- keep legacy rows if referenced

Must run SQL compilation check before applying:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
```

### 6. Resolve approved base pet classification

Bring these approved bases to a clean base state after approval:

- Тушканчик/Jetboa
- Носорог/Rhinoceros
- Лианчик/Lianchik
- Капибара/Capybara
- Бегемот/Hippo
- Олененок/Cyber Fawn or approved naming decision
- Дракон/Cyber Dragon
- Крокодил/Cyber Crocodile
- Единорог/Unicorn
- Слон/Elephant
- Барсук/Badger

Each row needs:

- current UUID preserved or explicit replacement/repoint decision
- target `subkind=default`
- correct rarity
- default visual coverage checked
- item skin attachments checked

### 7. Resolve duplicate base identities

`kind=panda`:

- keep Кибер Панда as base pet if that matches approved base Панда.
- reclassify Красная панда as skin-only/legacy character.
- preserve item skin defs Красная панда 1..N under base Панда.

`kind=kangaroo`:

- keep Кенгуру as base pet.
- reclassify Кенгуру-победитель as skin-only/legacy character.
- preserve item skin defs Кенгуру-победитель 1..N under base Кенгуру.

`kind=mutant`:

- user decision: Огонёк, Кристаллик, Лианчик are three different base pets.
- migration should split them into distinct base identities, preferably distinct `kind` values, unless a better explicit identity field is introduced.
- do not keep them as ambiguous variants of one shared `kind`.

### 8. Resolve approved item skins

Ensure every approved skin that exists is represented as grouped `pet_skin_defs.is_default=false`.

Confirm or fix attachment to correct base:

- Бумелеон -> Хамелеон
- Ёж-Вампир -> Ёж
- Пацанский Ёж -> Ёж
- Пряничный Енот -> Енот
- Пасхальный крот -> Крот
- Кенгуру-победитель -> Кенгуру
- Красная панда -> Панда
- all other approved skins from the manifest

Flag missing as content blockers:

- Золотой Оленёнок
- Гепард-марафонец

Resolve extra Unicorn item skin group:

- approved list says no Unicorn skins
- either mark those item skins legacy/non-acquirable or get product approval to keep them

### 9. Add backend catalog predicates

Centralize rules in code instead of repeating ad-hoc filters.

Recommended module:

- `diaverseapi/app/characters/catalog_rules.py`

Predicates:

```python
is_base_pet(character) -> bool
is_legacy_character_variant(character) -> bool
is_item_pet_skin(skin_def) -> bool
is_default_pet_visual(skin_def) -> bool
```

Keep these rules aligned with the documentation.

### 10. Add backend catalog and grant guardrails

No `diaweb` changes here. These backend changes prevent DB/catalog drift.

Update:

- `diaverseapi/app/cabinet/item_catalog/providers.py`
  - character entries should be grantable/sellable/rewardable only for base pets.
  - non-default characters should not appear as normal character catalog items for new acquisition.
- `diaverseapi/app/cabinet/shop/seed_data.py`
  - character shop seeds should include only base pets.
  - keep pet skins sourced only from `pet_skin_defs.is_default=false`.
- `diaverseapi/app/characters/grants.py`
  - normal character grants should reject non-default characters unless an explicit legacy/admin path is passed.
- `diaverseapi/app/pet_skins/grants.py`
  - keep the existing `is_default=false` validation.
  - add/adjust logging if needed for rejected default visuals.
- `diaverseapi/app/exchange/external/item_service.py`
  - replace local duplicated skin-variant logic with shared predicates if practical.

Use explicit logging for blocked legacy/non-default grants.

### 11. Audit all remaining grant paths

Search and review every path that can grant or expose characters/skins:

- cabinet fulfillment
- cabinet admin/support reward hydration
- advent rewards
- shop bootstrap/sync
- item catalog
- exchange item service
- containers/loot boxes
- onboarding rewards
- events/reward processors
- payment rewards

For this plan, only change paths that can newly grant or sell wrong pet/skin entities. Record anything broader as follow-up.

### 12. Add DB guardrails after data cleanup

Add only after manifest decisions are approved.

Candidates:

- partial unique index for one default character per `kind`:

```sql
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS uq_characters_default_kind
ON characters (kind)
WHERE subkind = 'default';
```

Do not add this blindly until Огонёк, Кристаллик, and Лианчик have been split or otherwise made compatible with the approved "three different base pets" decision.

Other possible checks:

- postcheck query that fails if `pet_skin_defs.is_default=false` points to non-default character
- postcheck query that fails if default visuals point to non-default character

Prefer postcheck scripts first; add DB constraints only when they match real approved data.

### 13. Add asset-reference audit

This is DB-only asset validation, not UI work.

Use audit file:

- `08_all_db_asset_refs.csv`

Add a repeatable check that reports:

- DB asset refs with no matching static file
- empty `characters.icon/image`
- empty `pet_skin_defs.icon/image`
- item skins whose `image` is missing while icon exists
- base pets whose carousel icon path is wrong or missing

Do not replace assets in this plan. Report missing files for the user to provide.

### 14. Add regression tests

Required tests:

- catalog predicate tests
- item catalog provider tests:
  - non-default characters are not grantable/sellable/rewardable as normal pets
  - default pet visuals are not item skins
  - item pet skins are grantable/sellable/rewardable
- shop seed tests:
  - positive-cost non-default character does not seed as pet
  - positive-cost default character does seed as pet
  - only `is_default=false` pet skins seed as pet skins
- grant tests:
  - normal character grant rejects non-default character
  - normal pet skin grant rejects default visual
- SQL postcheck tests or fixtures where feasible

Existing relevant test files:

- `diaverseapi/tests/test_cabinet_item_catalog.py`
- `diaverseapi/tests/test_cabinet_shop_service.py`
- add new focused tests if needed.

### 15. Add postcheck SQL

Create a repeatable post-migration SQL file:

- `diaverseapi/docs/sql/pets_skins_postcheck.sql`

Must include:

```sql
-- duplicate default pet kinds
SELECT kind, COUNT(*) AS default_count, string_agg(title->>'ru', ', ' ORDER BY title->>'ru')
FROM characters
WHERE subkind::text = 'default'
GROUP BY kind
HAVING COUNT(*) > 1;

-- item skins attached to non-default characters
SELECT ps.uuid, ps.title->>'ru' AS skin_ru, c.title->>'ru' AS attached_to, c.kind, c.subkind::text
FROM pet_skin_defs ps
JOIN characters c ON c.uuid = ps.character_id
WHERE ps.is_default = false
  AND c.subkind::text <> 'default';

-- default visuals attached to non-default characters
SELECT ps.uuid, ps.title->>'ru' AS visual_ru, c.title->>'ru' AS attached_to, c.kind, c.subkind::text
FROM pet_skin_defs ps
JOIN characters c ON c.uuid = ps.character_id
WHERE ps.is_default = true
  AND c.subkind::text <> 'default';

-- non-default characters still exposed as sellable/grantable catalog entries
-- implementation depends on final catalog query or materialized export
```

Postcheck should also assert manifest-specific expectations:

- all approved base pets exist as base rows
- all approved skins exist except documented missing blockers
- no approved skin is a default base pet
- no unexpected item skin remains attached to a non-default character

### 16. Add documentation and AI memory

Create/update:

- `diaverseapi/docs/pets-skins-catalog.md`
- `diaverseapi/docs/pets-skins-canonical-manifest.md`
- top-level `.ai-factory/RESEARCH.md` with a short "Pets and Skins Source of Truth" summary

Documentation must include:

- table meanings
- correct DB rules
- valid examples
- invalid legacy examples
- approved catalog snapshot
- known unresolved blockers
- exact statement that shop/UI cleanup is separate from DB cleanup

After the model is accepted, add stable project rules via `/aif-rules`:

- never treat `characters.subkind != default` as a base pet
- never sell/grant `pet_skin_defs.is_default=true` as a skin item
- keep approved catalog manifest in sync with data migrations

## Verification Commands

From `C:\Users\Indigo\Desktop\diaverse\diaverseapi`:

```powershell
.\.venv\Scripts\python.exe -m alembic heads
.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
.\.venv\Scripts\python.exe -m pytest tests\test_cabinet_item_catalog.py
.\.venv\Scripts\python.exe -m pytest tests\test_cabinet_shop_service.py
.\.venv\Scripts\python.exe -m pytest
```

Run preflight/postcheck SQL against a staging copy before production.

From workspace root after code/docs changes:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Indigo\Desktop\diaverse\scripts\graphify-update.ps1
```

## Rollout Plan

1. Create canonical manifest.
2. Run preflight SQL on production copy.
3. Export ownership/fulfillment risk.
4. Review approval-gate decisions with user.
5. Write migration only after decisions are approved.
6. Apply migration to staging.
7. Run postcheck SQL.
8. Run backend tests.
9. Add backend guardrails.
10. Run postcheck again.
11. Update docs and AI memory.
12. Only after DB/backend catalog is stable, start separate plan for shop display and mobile impact.

## Commit Plan

1. `docs: document pets and skins catalog source of truth`
2. `test: cover pet and skin catalog classification`
3. `fix: guard pet catalog against legacy character variants`
4. `fix: migrate pets and skins catalog data`
5. `docs: record pets and skins rules for agents`
