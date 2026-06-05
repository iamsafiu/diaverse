# Factory Craft Logs

{
    "schema_version": "factory.v1",
    "server_time": "2026-06-02T12:23:51.275909Z",
    "catalog_version": "factory_catalog.v1",
    "status": "blocked",
    "idempotency_key": "factory-cf2b94be-6a8f-4c32-a46e-df3293bd1ac7",
    "state": {
        "schema_version": "factory.v1",
        "server_time": "2026-06-02T12:23:51.275909Z",
        "catalog_version": "factory_catalog.v1",
        "rollout_enabled": true,
        "next_refresh_at": null,
        "profile": {
            "profile_id": "2a003ba8-09c5-421a-9763-0f9ad4ec49e2",
            "level": 1,
            "status": "active",
            "onboarding_completed": true,
            "visual": {
                "visual_key": "factory.map.level_1",
                "state": "active",
                "effect_key": null,
                "metadata": {}
            },
            "available_actions": [
                {
                    "code": "claim_impulses",
                    "enabled": true,
                    "idempotency_required": true,
                    "payment_options": [],
                    "missing_requirements": [],
                    "lock_reasons": [],
                    "metadata": {}
                },
                {
                    "code": "upgrade_level",
                    "enabled": true,
                    "idempotency_required": true,
                    "payment_options": [
                        {
                            "option_key": "level_2_real_money",
                            "method": "real_money",
                            "prices": [
                                {
                                    "kind": "real_money",
                                    "amount": "15",
                                    "currency": "USD",
                                    "resource_key": null,
                                    "label": null,
                                    "title": null,
                                    "icon": null,
                                    "visual_key": null,
                                    "metadata": {}
                                }
                            ],
                            "enabled": true,
                            "lock_reasons": []
                        },
                        {
                            "option_key": "level_2_game_dollar",
                            "method": "game_dollar",
                            "prices": [
                                {
                                    "kind": "game_dollar",
                                    "amount": "375",
                                    "currency": "USD",
                                    "resource_key": null,
                                    "label": null,
                                    "title": "Game dollars",
                                    "icon": "dollar.webp",
                                    "visual_key": "factory.icon.game_dollar",
                                    "metadata": {}
                                }
                            ],
                            "enabled": true,
                            "lock_reasons": []
                        },
                        {
                            "option_key": "level_2_brick",
                            "method": "brick",
                            "prices": [
                                {
                                    "kind": "brick",
                                    "amount": "15000",
                                    "currency": null,
                                    "resource_key": "brick",
                                    "label": null,
                                    "title": "brick",
                                    "icon": "brick.webp",
                                    "visual_key": "factory.icon.brick",
                                    "metadata": {}
                                }
                            ],
                            "enabled": true,
                            "lock_reasons": []
                        }
                    ],
                    "missing_requirements": [],
                    "lock_reasons": [],
                    "metadata": {
                        "target_level": 2
                    }
                }
            ]
        },
        "subscription": {
            "active_tier": "none",
            "features": [],
            "expires_at": null,
            "next_settlement_at": null
        },
        "impulse_claim": {
            "daily_cap": 30000,
            "claimed_today": 0,
            "available_to_claim": 0,
            "next_reset_at": "2026-06-02T19:00:00Z"
        },
        "balances": [
            {
                "key": "game_dollar",
                "quantity": "95.00",
                "kind": "game_dollar",
                "visual_key": "factory.icon.game_dollar",
                "title": "Game dollars",
                "icon": "dollar.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "xdv",
                "quantity": "82322.830",
                "kind": "xdv",
                "visual_key": "factory.icon.xdv",
                "title": "XDV",
                "icon": null,
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "impulse",
                "quantity": "80000",
                "kind": "impulse",
                "visual_key": "factory.icon.impulse",
                "title": "impulse",
                "icon": "impulse.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "brick",
                "quantity": "78006",
                "kind": "brick",
                "visual_key": "factory.icon.brick",
                "title": "brick",
                "icon": "brick.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "slot_token",
                "quantity": "98",
                "kind": "slot_token",
                "visual_key": "factory.icon.slot_token",
                "title": "slot_token",
                "icon": "slot-token.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "token_details",
                "quantity": "0",
                "kind": "token_details",
                "visual_key": "factory.icon.token_details",
                "title": "token_details",
                "icon": "token-details.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "shard_rare",
                "quantity": "1",
                "kind": "resource",
                "visual_key": "factory.icon.shard_rare",
                "title": "Rare pet fragments",
                "icon": null,
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "shard",
                    "entity_key": "shard_rare",
                    "rarity": "rare",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [
                        "rare_pet_fragment",
                        "rare_pet_fragments"
                    ]
                }
            },
            {
                "key": "shard_epic",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.shard_epic",
                "title": "Epic pet fragments",
                "icon": null,
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "shard",
                    "entity_key": "shard_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [
                        "epic_pet_fragment",
                        "epic_pet_fragments"
                    ]
                }
            },
            {
                "key": "shard_legendary",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.shard_legendary",
                "title": "Legendary pet fragments",
                "icon": null,
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "shard",
                    "entity_key": "shard_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [
                        "legendary_pet_fragment",
                        "legendary_pet_fragments"
                    ]
                }
            },
            {
                "key": "user_character_rare",
                "quantity": "2",
                "kind": "resource",
                "visual_key": "factory.icon.user_character_rare",
                "title": "Rare pet",
                "icon": null,
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_rare",
                    "rarity": "rare",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": []
                }
            },
            {
                "key": "user_character_epic",
                "quantity": "9",
                "kind": "resource",
                "visual_key": "factory.icon.user_character_epic",
                "title": "Epic pet",
                "icon": null,
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": []
                }
            },
            {
                "key": "user_character_legendary",
                "quantity": "12",
                "kind": "resource",
                "visual_key": "factory.icon.user_character_legendary",
                "title": "Legendary pet",
                "icon": null,
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": []
                }
            },
            {
                "key": "evogen_rare",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.evogen_rare",
                "title": "Rare EvoGen",
                "icon": "rare_pet_4_evolution.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "evogen",
                    "entity_key": "evogen_rare",
                    "rarity": "rare",
                    "resource_type": null,
                    "voucher_type": "rare_pet_4_evolution",
                    "requires_selection": false,
                    "legacy_keys": []
                }
            },
            {
                "key": "evogen_epic",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.evogen_epic",
                "title": "Epic EvoGen",
                "icon": "epic_pet_4_evolution.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "evogen",
                    "entity_key": "evogen_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": "epic_pet_4_evolution",
                    "requires_selection": false,
                    "legacy_keys": []
                }
            },
            {
                "key": "evogen_legendary",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.evogen_legendary",
                "title": "Legendary EvoGen",
                "icon": "legendary_pet_4_evolution.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "evogen",
                    "entity_key": "evogen_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": "legendary_pet_4_evolution",
                    "requires_selection": false,
                    "legacy_keys": []
                }
            },
            {
                "key": "mutagen_common",
                "quantity": "391",
                "kind": "resource",
                "visual_key": "factory.icon.mutagen_common",
                "title": "Common mutagen",
                "icon": "common_mutagen.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "mutagen",
                    "entity_key": "mutagen_common",
                    "rarity": "common",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": false,
                    "legacy_keys": []
                }
            },
            {
                "key": "mutagen_rare",
                "quantity": "10",
                "kind": "resource",
                "visual_key": "factory.icon.mutagen_rare",
                "title": "Rare mutagen",
                "icon": "rare_mutagen.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "mutagen",
                    "entity_key": "mutagen_rare",
                    "rarity": "rare",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": false,
                    "legacy_keys": []
                }
            },
            {
                "key": "mutagen_epic",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.mutagen_epic",
                "title": "Epic mutagen",
                "icon": "epic_mutagen.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "mutagen",
                    "entity_key": "mutagen_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": false,
                    "legacy_keys": []
                }
            },
            {
                "key": "mutagen_legendary",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.mutagen_legendary",
                "title": "Legendary mutagen",
                "icon": "legendary_mutagen.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "mutagen",
                    "entity_key": "mutagen_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": false,
                    "legacy_keys": []
                }
            },
            {
                "key": "synthesis_core",
                "quantity": "15",
                "kind": "resource",
                "visual_key": "factory.icon.synthesis_core",
                "title": "synthesis_core",
                "icon": "Core.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "bullet",
                "quantity": "3285",
                "kind": "resource",
                "visual_key": "factory.icon.bullet",
                "title": "bullet",
                "icon": "bullet.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "galaglue",
                "quantity": "4225",
                "kind": "resource",
                "visual_key": "factory.icon.galaglue",
                "title": "galaglue",
                "icon": "galaglue.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "nuclear_acorn",
                "quantity": "2229",
                "kind": "resource",
                "visual_key": "factory.icon.nuclear_acorn",
                "title": "nuclear_acorn",
                "icon": "nuclear_acorn.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "gear",
                "quantity": "964",
                "kind": "resource",
                "visual_key": "factory.icon.gear",
                "title": "gear",
                "icon": "gear.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "dna_capsule",
                "quantity": "343",
                "kind": "resource",
                "visual_key": "factory.icon.dna_capsule",
                "title": "dna_capsule",
                "icon": "dna_capsule.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "brick",
                "quantity": "78006",
                "kind": "resource",
                "visual_key": "factory.icon.brick",
                "title": "brick",
                "icon": "brick.webp",
                "metadata": {
                    "source": "user_inventory"
                }
            },
            {
                "key": "shard:1133ae32-4d62-448c-9154-444f9cd3cb1d",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.shard.rare",
                "title": "Кибер Белка",
                "icon": "squirrel-shard.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "shard",
                    "entity_key": "shard_rare",
                    "rarity": "rare",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [
                        "rare_pet_fragment",
                        "rare_pet_fragments"
                    ],
                    "aggregate_key": "shard_rare",
                    "selectable": true,
                    "selection_field": "shard_id",
                    "shard_id": "1133ae32-4d62-448c-9154-444f9cd3cb1d",
                    "character_id": "b6e0fa3d-551e-420c-abc3-a675704a323e",
                    "character_kind": "squirrel",
                    "title": "Кибер Белка",
                    "icon": "squirrel-shard.webp",
                    "visual_key": "factory.entity.shard.rare"
                }
            },
            {
                "key": "user_character:8e8e13e0-ee9c-412d-b0eb-76251cd7b94c",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.rare",
                "title": "Кибер Собака",
                "icon": "dog.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_rare",
                    "rarity": "rare",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_rare",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "8e8e13e0-ee9c-412d-b0eb-76251cd7b94c",
                    "character_id": "6e0c1157-bd16-4155-afc8-a4db7c2aa011",
                    "character_kind": "dog",
                    "evolution": 1,
                    "title": "Кибер Собака",
                    "icon": "dog.webp",
                    "visual_key": "factory.entity.user_character.rare"
                }
            },
            {
                "key": "user_character:50337b9a-d91e-4812-9277-384843f98be2",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.rare",
                "title": "Кибер Ходок",
                "icon": "icon.svg",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_rare",
                    "rarity": "rare",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_rare",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "50337b9a-d91e-4812-9277-384843f98be2",
                    "character_id": "9a343d26-5875-4626-b99c-230769ca591c",
                    "character_kind": "walker",
                    "evolution": 1,
                    "title": "Кибер Ходок",
                    "icon": "icon.svg",
                    "visual_key": "factory.entity.user_character.rare"
                }
            },
            {
                "key": "user_character:88076ae4-1425-4814-8cec-54133af86f8a",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.epic",
                "title": "Капибара",
                "icon": "characters/capybara.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_epic",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "88076ae4-1425-4814-8cec-54133af86f8a",
                    "character_id": "9243d444-c182-48b6-8c7f-9d0178b9391b",
                    "character_kind": "capybara",
                    "evolution": 1,
                    "title": "Капибара",
                    "icon": "characters/capybara.webp",
                    "visual_key": "factory.entity.user_character.epic"
                }
            },
            {
                "key": "user_character:db7620c0-1f4a-445e-ba23-1353dbb67bc3",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.epic",
                "title": "Капибара",
                "icon": "characters/capybara.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_epic",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "db7620c0-1f4a-445e-ba23-1353dbb67bc3",
                    "character_id": "9243d444-c182-48b6-8c7f-9d0178b9391b",
                    "character_kind": "capybara",
                    "evolution": 1,
                    "title": "Капибара",
                    "icon": "characters/capybara.webp",
                    "visual_key": "factory.entity.user_character.epic"
                }
            },
            {
                "key": "user_character:258c2b15-ea49-4fae-9bcd-5d144b9adaba",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.epic",
                "title": "Капибара",
                "icon": "characters/capybara.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_epic",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "258c2b15-ea49-4fae-9bcd-5d144b9adaba",
                    "character_id": "9243d444-c182-48b6-8c7f-9d0178b9391b",
                    "character_kind": "capybara",
                    "evolution": 1,
                    "title": "Капибара",
                    "icon": "characters/capybara.webp",
                    "visual_key": "factory.entity.user_character.epic"
                }
            },
            {
                "key": "user_character:e174c2fb-da55-4e64-8667-3d527c989e01",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.epic",
                "title": "Капибара",
                "icon": "characters/capybara.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_epic",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "e174c2fb-da55-4e64-8667-3d527c989e01",
                    "character_id": "9243d444-c182-48b6-8c7f-9d0178b9391b",
                    "character_kind": "capybara",
                    "evolution": 1,
                    "title": "Капибара",
                    "icon": "characters/capybara.webp",
                    "visual_key": "factory.entity.user_character.epic"
                }
            },
            {
                "key": "user_character:9210668c-8555-4842-aa2d-0ab426a781a9",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.epic",
                "title": "Капибара",
                "icon": "characters/capybara.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_epic",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "9210668c-8555-4842-aa2d-0ab426a781a9",
                    "character_id": "9243d444-c182-48b6-8c7f-9d0178b9391b",
                    "character_kind": "capybara",
                    "evolution": 1,
                    "title": "Капибара",
                    "icon": "characters/capybara.webp",
                    "visual_key": "factory.entity.user_character.epic"
                }
            },
            {
                "key": "user_character:ba03b9cb-da63-4d87-a7c4-eaab9bc24d30",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.epic",
                "title": "Кибер Олененок",
                "icon": "icon.svg",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_epic",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "ba03b9cb-da63-4d87-a7c4-eaab9bc24d30",
                    "character_id": "2693dbb5-7df8-4531-b50e-ad067f462ead",
                    "character_kind": "fawn",
                    "evolution": 1,
                    "title": "Кибер Олененок",
                    "icon": "icon.svg",
                    "visual_key": "factory.entity.user_character.epic"
                }
            },
            {
                "key": "user_character:19acf981-1258-4261-854a-cb1dc9fc1ad8",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.epic",
                "title": "Кибер Олененок",
                "icon": "icon.svg",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_epic",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "19acf981-1258-4261-854a-cb1dc9fc1ad8",
                    "character_id": "2693dbb5-7df8-4531-b50e-ad067f462ead",
                    "character_kind": "fawn",
                    "evolution": 1,
                    "title": "Кибер Олененок",
                    "icon": "icon.svg",
                    "visual_key": "factory.entity.user_character.epic"
                }
            },
            {
                "key": "user_character:e33e3643-afff-4175-95e4-81db0dbe231f",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.epic",
                "title": "Спортивная Рысь",
                "icon": "characters/trot.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_epic",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "e33e3643-afff-4175-95e4-81db0dbe231f",
                    "character_id": "61b94a0b-a766-4d4c-88a3-9946d581f7b7",
                    "character_kind": "gepard",
                    "evolution": 1,
                    "title": "Спортивная Рысь",
                    "icon": "characters/trot.webp",
                    "visual_key": "factory.entity.user_character.epic"
                }
            },
            {
                "key": "user_character:ac36f993-2318-4736-93eb-a6ce5b4b8d16",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.epic",
                "title": "Гиена",
                "icon": "hyena_1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_epic",
                    "rarity": "epic",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_epic",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "ac36f993-2318-4736-93eb-a6ce5b4b8d16",
                    "character_id": "558faa4d-d4cf-4e95-816c-4770825e0447",
                    "character_kind": "hyena",
                    "evolution": 1,
                    "title": "Гиена",
                    "icon": "hyena_1.webp",
                    "visual_key": "factory.entity.user_character.epic"
                }
            },
            {
                "key": "user_character:d84a59be-34c9-4c94-8474-8094f493abab",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Барсук",
                "icon": "characters/badger.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "d84a59be-34c9-4c94-8474-8094f493abab",
                    "character_id": "a3c4fe00-b891-4fe7-a350-4fd8f0dbd9a7",
                    "character_kind": "badger",
                    "evolution": 1,
                    "title": "Барсук",
                    "icon": "characters/badger.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "user_character:412f4602-a375-41cd-8561-a6deff95d31c",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Бобр",
                "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "412f4602-a375-41cd-8561-a6deff95d31c",
                    "character_id": "2e322c68-f946-4aea-937c-e3bbcf58eabd",
                    "character_kind": "bobr",
                    "evolution": 1,
                    "title": "Бобр",
                    "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "user_character:cf9486c8-8bd6-477f-8cd6-92dc966ee4b2",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Бобр",
                "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "cf9486c8-8bd6-477f-8cd6-92dc966ee4b2",
                    "character_id": "2e322c68-f946-4aea-937c-e3bbcf58eabd",
                    "character_kind": "bobr",
                    "evolution": 1,
                    "title": "Бобр",
                    "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "user_character:ca50db4c-1dc3-4f08-952e-09be7cfb202e",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Бобр",
                "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "ca50db4c-1dc3-4f08-952e-09be7cfb202e",
                    "character_id": "2e322c68-f946-4aea-937c-e3bbcf58eabd",
                    "character_kind": "bobr",
                    "evolution": 1,
                    "title": "Бобр",
                    "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "user_character:9a33aea7-7f55-4d84-9034-fe9b59a27700",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Бобр",
                "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "9a33aea7-7f55-4d84-9034-fe9b59a27700",
                    "character_id": "2e322c68-f946-4aea-937c-e3bbcf58eabd",
                    "character_kind": "bobr",
                    "evolution": 1,
                    "title": "Бобр",
                    "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "user_character:b35b15e9-5a64-4256-8900-a525ef521773",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Бобр",
                "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "b35b15e9-5a64-4256-8900-a525ef521773",
                    "character_id": "2e322c68-f946-4aea-937c-e3bbcf58eabd",
                    "character_kind": "bobr",
                    "evolution": 1,
                    "title": "Бобр",
                    "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "user_character:b72e27d5-014f-4609-b6e3-8bcb3366aeb4",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Бобр",
                "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "b72e27d5-014f-4609-b6e3-8bcb3366aeb4",
                    "character_id": "2e322c68-f946-4aea-937c-e3bbcf58eabd",
                    "character_kind": "bobr",
                    "evolution": 1,
                    "title": "Бобр",
                    "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "user_character:af0e11d6-4ea2-442a-9d05-c03055f8a523",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Бобр",
                "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "af0e11d6-4ea2-442a-9d05-c03055f8a523",
                    "character_id": "2e322c68-f946-4aea-937c-e3bbcf58eabd",
                    "character_kind": "bobr",
                    "evolution": 1,
                    "title": "Бобр",
                    "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "user_character:c4242cac-2a96-4513-81ce-d9b9b39061a3",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Бобр",
                "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "c4242cac-2a96-4513-81ce-d9b9b39061a3",
                    "character_id": "2e322c68-f946-4aea-937c-e3bbcf58eabd",
                    "character_kind": "bobr",
                    "evolution": 1,
                    "title": "Бобр",
                    "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "user_character:92bc2011-d90b-4ad9-8f73-fbb5d7a0d8b6",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Бобр",
                "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "92bc2011-d90b-4ad9-8f73-fbb5d7a0d8b6",
                    "character_id": "2e322c68-f946-4aea-937c-e3bbcf58eabd",
                    "character_kind": "bobr",
                    "evolution": 1,
                    "title": "Бобр",
                    "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "user_character:9800f514-581f-4b57-9031-ba87a6b1076e",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Бобр",
                "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "9800f514-581f-4b57-9031-ba87a6b1076e",
                    "character_id": "2e322c68-f946-4aea-937c-e3bbcf58eabd",
                    "character_kind": "bobr",
                    "evolution": 1,
                    "title": "Бобр",
                    "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "user_character:71ea76fe-19ed-4dbb-bd3e-ac328330ab04",
                "quantity": "1",
                "kind": "entity",
                "visual_key": "factory.entity.user_character.legendary",
                "title": "Бобр",
                "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                "metadata": {
                    "source": "user_inventory",
                    "entity_kind": "user_character",
                    "entity_key": "user_character_legendary",
                    "rarity": "legendary",
                    "resource_type": null,
                    "voucher_type": null,
                    "requires_selection": true,
                    "legacy_keys": [],
                    "aggregate_key": "user_character_legendary",
                    "selectable": true,
                    "selection_field": "user_character_id",
                    "user_character_id": "71ea76fe-19ed-4dbb-bd3e-ac328330ab04",
                    "character_id": "2e322c68-f946-4aea-937c-e3bbcf58eabd",
                    "character_kind": "bobr",
                    "evolution": 1,
                    "title": "Бобр",
                    "icon": "pets/bobr/pet_bobr_default_icon_age1_84_v1.webp",
                    "visual_key": "factory.entity.user_character.legendary"
                }
            },
            {
                "key": "warehouse:brick",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.brick",
                "title": "brick",
                "icon": "brick.webp",
                "metadata": {
                    "source": "factory_warehouse",
                    "balance_key": "brick",
                    "stored_quantity": "13.5885",
                    "stopped": false,
                    "cap_hours": "10",
                    "cap_seconds": 60,
                    "resource_rate_multiplier": "1440",
                    "last_accrual_at": "2026-06-02T06:07:01.289086+00:00",
                    "stop_at": "2026-06-02T06:08:01.289086+00:00",
                    "remaining_stop_seconds": 0
                }
            },
            {
                "key": "warehouse:bullet",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.bullet",
                "title": "bullet",
                "icon": "bullet.webp",
                "metadata": {
                    "source": "factory_warehouse",
                    "balance_key": "bullet",
                    "stored_quantity": "25.0894",
                    "stopped": false,
                    "cap_hours": "10",
                    "cap_seconds": 60,
                    "resource_rate_multiplier": "1440",
                    "last_accrual_at": "2026-06-02T06:07:01.289086+00:00",
                    "stop_at": "2026-06-02T06:08:01.289086+00:00",
                    "remaining_stop_seconds": 0
                }
            },
            {
                "key": "warehouse:dna_capsule",
                "quantity": "0.3502",
                "kind": "resource",
                "visual_key": "factory.icon.dna_capsule",
                "title": "dna_capsule",
                "icon": "dna_capsule.webp",
                "metadata": {
                    "source": "factory_warehouse",
                    "balance_key": "dna_capsule",
                    "stored_quantity": "0.9068",
                    "stopped": false,
                    "cap_hours": "10",
                    "cap_seconds": 60,
                    "resource_rate_multiplier": "1440",
                    "last_accrual_at": "2026-06-02T11:54:48.213044+00:00",
                    "stop_at": "2026-06-02T11:55:48.213044+00:00",
                    "remaining_stop_seconds": 0
                }
            },
            {
                "key": "warehouse:galaglue",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.galaglue",
                "title": "galaglue",
                "icon": "galaglue.webp",
                "metadata": {
                    "source": "factory_warehouse",
                    "balance_key": "galaglue",
                    "stored_quantity": "19.6962",
                    "stopped": false,
                    "cap_hours": "10",
                    "cap_seconds": 60,
                    "resource_rate_multiplier": "1440",
                    "last_accrual_at": "2026-06-02T06:06:57.443175+00:00",
                    "stop_at": "2026-06-02T06:07:57.443175+00:00",
                    "remaining_stop_seconds": 0
                }
            },
            {
                "key": "warehouse:game_dollar",
                "quantity": "0",
                "kind": "game_dollar",
                "visual_key": "factory.icon.game_dollar",
                "title": "Game dollars",
                "icon": "dollar.webp",
                "metadata": {
                    "source": "factory_warehouse",
                    "balance_key": "game_dollar",
                    "stored_quantity": "0",
                    "stopped": false,
                    "cap_hours": "10",
                    "cap_seconds": 60,
                    "resource_rate_multiplier": "1440",
                    "last_accrual_at": "2026-05-26T09:43:18.918386+00:00",
                    "stop_at": "2026-05-26T09:44:18.918386+00:00",
                    "remaining_stop_seconds": 0
                }
            },
            {
                "key": "warehouse:gear",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.gear",
                "title": "gear",
                "icon": "gear.webp",
                "metadata": {
                    "source": "factory_warehouse",
                    "balance_key": "gear",
                    "stored_quantity": "7.5878",
                    "stopped": false,
                    "cap_hours": "10",
                    "cap_seconds": 60,
                    "resource_rate_multiplier": "1440",
                    "last_accrual_at": "2026-06-02T06:07:01.289086+00:00",
                    "stop_at": "2026-06-02T06:08:01.289086+00:00",
                    "remaining_stop_seconds": 0
                }
            },
            {
                "key": "warehouse:nuclear_acorn",
                "quantity": "0",
                "kind": "resource",
                "visual_key": "factory.icon.nuclear_acorn",
                "title": "nuclear_acorn",
                "icon": "nuclear_acorn.webp",
                "metadata": {
                    "source": "factory_warehouse",
                    "balance_key": "nuclear_acorn",
                    "stored_quantity": "15.7676",
                    "stopped": false,
                    "cap_hours": "10",
                    "cap_seconds": 60,
                    "resource_rate_multiplier": "1440",
                    "last_accrual_at": "2026-06-02T06:07:01.289086+00:00",
                    "stop_at": "2026-06-02T06:08:01.289086+00:00",
                    "remaining_stop_seconds": 0
                }
            }
        ],
        "resource_assets": {
            "xdv": {
                "key": "xdv",
                "title": "XDV",
                "icon": null,
                "visual_key": "factory.icon.xdv"
            },
            "game_dollar": {
                "key": "game_dollar",
                "title": "Game dollars",
                "icon": "dollar.webp",
                "visual_key": "factory.icon.game_dollar"
            },
            "shard_rare": {
                "key": "shard_rare",
                "title": "Rare pet fragments",
                "icon": null,
                "visual_key": "factory.icon.shard_rare"
            },
            "shard_epic": {
                "key": "shard_epic",
                "title": "Epic pet fragments",
                "icon": null,
                "visual_key": "factory.icon.shard_epic"
            },
            "shard_legendary": {
                "key": "shard_legendary",
                "title": "Legendary pet fragments",
                "icon": null,
                "visual_key": "factory.icon.shard_legendary"
            },
            "user_character_rare": {
                "key": "user_character_rare",
                "title": "Rare pet",
                "icon": null,
                "visual_key": "factory.icon.user_character_rare"
            },
            "user_character_epic": {
                "key": "user_character_epic",
                "title": "Epic pet",
                "icon": null,
                "visual_key": "factory.icon.user_character_epic"
            },
            "user_character_legendary": {
                "key": "user_character_legendary",
                "title": "Legendary pet",
                "icon": null,
                "visual_key": "factory.icon.user_character_legendary"
            },
            "character_rare": {
                "key": "character_rare",
                "title": "Rare pet",
                "icon": null,
                "visual_key": "factory.icon.character_rare"
            },
            "character_epic": {
                "key": "character_epic",
                "title": "Epic pet",
                "icon": null,
                "visual_key": "factory.icon.character_epic"
            },
            "character_legendary": {
                "key": "character_legendary",
                "title": "Legendary pet",
                "icon": null,
                "visual_key": "factory.icon.character_legendary"
            },
            "evogen_rare": {
                "key": "evogen_rare",
                "title": "Rare EvoGen",
                "icon": "rare_pet_4_evolution.webp",
                "visual_key": "factory.icon.evogen_rare"
            },
            "evogen_epic": {
                "key": "evogen_epic",
                "title": "Epic EvoGen",
                "icon": "epic_pet_4_evolution.webp",
                "visual_key": "factory.icon.evogen_epic"
            },
            "evogen_legendary": {
                "key": "evogen_legendary",
                "title": "Legendary EvoGen",
                "icon": "legendary_pet_4_evolution.webp",
                "visual_key": "factory.icon.evogen_legendary"
            },
            "mutagen_common": {
                "key": "mutagen_common",
                "title": "Common mutagen",
                "icon": "common_mutagen.webp",
                "visual_key": "factory.icon.mutagen_common"
            },
            "mutagen_rare": {
                "key": "mutagen_rare",
                "title": "Rare mutagen",
                "icon": "rare_mutagen.webp",
                "visual_key": "factory.icon.mutagen_rare"
            },
            "mutagen_epic": {
                "key": "mutagen_epic",
                "title": "Epic mutagen",
                "icon": "epic_mutagen.webp",
                "visual_key": "factory.icon.mutagen_epic"
            },
            "mutagen_legendary": {
                "key": "mutagen_legendary",
                "title": "Legendary mutagen",
                "icon": "legendary_mutagen.webp",
                "visual_key": "factory.icon.mutagen_legendary"
            },
            "base_nullifier": {
                "key": "base_nullifier",
                "title": "base_nullifier",
                "icon": "",
                "visual_key": "factory.icon.base_nullifier"
            },
            "max_nullifier": {
                "key": "max_nullifier",
                "title": "max_nullifier",
                "icon": "",
                "visual_key": "factory.icon.max_nullifier"
            },
            "rare_biomass": {
                "key": "rare_biomass",
                "title": "rare_biomass",
                "icon": "",
                "visual_key": "factory.icon.rare_biomass"
            },
            "epic_biomass": {
                "key": "epic_biomass",
                "title": "epic_biomass",
                "icon": "",
                "visual_key": "factory.icon.epic_biomass"
            },
            "legendary_biomass": {
                "key": "legendary_biomass",
                "title": "legendary_biomass",
                "icon": "",
                "visual_key": "factory.icon.legendary_biomass"
            },
            "bullet": {
                "key": "bullet",
                "title": "bullet",
                "icon": "bullet.webp",
                "visual_key": "factory.icon.bullet"
            },
            "galaglue": {
                "key": "galaglue",
                "title": "galaglue",
                "icon": "galaglue.webp",
                "visual_key": "factory.icon.galaglue"
            },
            "nuclear_acorn": {
                "key": "nuclear_acorn",
                "title": "nuclear_acorn",
                "icon": "nuclear_acorn.webp",
                "visual_key": "factory.icon.nuclear_acorn"
            },
            "gear": {
                "key": "gear",
                "title": "gear",
                "icon": "gear.webp",
                "visual_key": "factory.icon.gear"
            },
            "brick": {
                "key": "brick",
                "title": "brick",
                "icon": "brick.webp",
                "visual_key": "factory.icon.brick"
            },
            "dna_capsule": {
                "key": "dna_capsule",
                "title": "dna_capsule",
                "icon": "dna_capsule.webp",
                "visual_key": "factory.icon.dna_capsule"
            },
            "xp_capsule": {
                "key": "xp_capsule",
                "title": "xp_capsule",
                "icon": "xp_capsula.webp",
                "visual_key": "factory.icon.xp_capsule"
            },
            "boost_quantum_miner": {
                "key": "boost_quantum_miner",
                "title": "boost_quantum_miner",
                "icon": "boost_quantum_miner.webp",
                "visual_key": "factory.icon.boost_quantum_miner"
            },
            "boost_neuro_accelerator": {
                "key": "boost_neuro_accelerator",
                "title": "boost_neuro_accelerator",
                "icon": "boost_neuro_accelerator_7d.webp",
                "visual_key": "factory.icon.boost_neuro_accelerator"
            },
            "boost_hacker_key": {
                "key": "boost_hacker_key",
                "title": "boost_hacker_key",
                "icon": "Хакерский ключ (2).webp",
                "visual_key": "factory.icon.boost_hacker_key"
            },
            "boost_chest_cracker": {
                "key": "boost_chest_cracker",
                "title": "boost_chest_cracker",
                "icon": "boost_chest_cracker.webp",
                "visual_key": "factory.icon.boost_chest_cracker"
            },
            "boost_chest_magnet": {
                "key": "boost_chest_magnet",
                "title": "boost_chest_magnet",
                "icon": "boost_chest_magnet.webp",
                "visual_key": "factory.icon.boost_chest_magnet"
            },
            "boost_chest_speed": {
                "key": "boost_chest_speed",
                "title": "boost_chest_speed",
                "icon": "Хроноперескок (2).webp",
                "visual_key": "factory.icon.boost_chest_speed"
            },
            "boost_oracle_eye_rare": {
                "key": "boost_oracle_eye_rare",
                "title": "boost_oracle_eye_rare",
                "icon": "Редкий глаз оракула (2).webp",
                "visual_key": "factory.icon.boost_oracle_eye_rare"
            },
            "boost_oracle_eye_epic": {
                "key": "boost_oracle_eye_epic",
                "title": "boost_oracle_eye_epic",
                "icon": "Эпический глаз оракула (2).webp",
                "visual_key": "factory.icon.boost_oracle_eye_epic"
            },
            "experience_converter": {
                "key": "experience_converter",
                "title": "experience_converter",
                "icon": "/icons/experience_converter_basic.png",
                "visual_key": "factory.icon.experience_converter"
            },
            "boost_pet_xp": {
                "key": "boost_pet_xp",
                "title": "boost_pet_xp",
                "icon": "food_xp_boost.webp",
                "visual_key": "factory.icon.boost_pet_xp"
            },
            "enriched_synthesis_core": {
                "key": "enriched_synthesis_core",
                "title": "enriched_synthesis_core",
                "icon": "photo_5447184190207103438_y.webp",
                "visual_key": "factory.icon.enriched_synthesis_core"
            },
            "synthesis_core": {
                "key": "synthesis_core",
                "title": "synthesis_core",
                "icon": "Core.webp",
                "visual_key": "factory.icon.synthesis_core"
            },
            "boost_mutation_shield": {
                "key": "boost_mutation_shield",
                "title": "boost_mutation_shield",
                "icon": "medical_insurance_boost.webp",
                "visual_key": "factory.icon.boost_mutation_shield"
            },
            "impulse": {
                "key": "impulse",
                "title": "impulse",
                "icon": "impulse.webp",
                "visual_key": "factory.icon.impulse"
            },
            "token_details": {
                "key": "token_details",
                "title": "token_details",
                "icon": "token-details.webp",
                "visual_key": "factory.icon.token_details"
            },
            "slot_token": {
                "key": "slot_token",
                "title": "slot_token",
                "icon": "slot-token.webp",
                "visual_key": "factory.icon.slot_token"
            },
            "rare_pet_fragment": {
                "key": "rare_pet_fragment",
                "title": "rare_pet_fragment",
                "icon": "rare_pet_fragment.webp",
                "visual_key": "factory.icon.rare_pet_fragment"
            },
            "epic_pet_fragment": {
                "key": "epic_pet_fragment",
                "title": "epic_pet_fragment",
                "icon": "epic_pet_fragment.webp",
                "visual_key": "factory.icon.epic_pet_fragment"
            },
            "legendary_pet_fragment": {
                "key": "legendary_pet_fragment",
                "title": "legendary_pet_fragment",
                "icon": "legendary_pet_fragment.webp",
                "visual_key": "factory.icon.legendary_pet_fragment"
            },
            "rare_evogen": {
                "key": "rare_evogen",
                "title": "rare_evogen",
                "icon": "rare_evogen.webp",
                "visual_key": "factory.icon.rare_evogen"
            }
        },
        "buildings": [
            {
                "building_key": "bullet_workshop",
                "title": "Ballistic conveyor",
                "building_type": "resource",
                "required_level": 1,
                "early_access_level": null,
                "early_access": false,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.bullet_workshop",
                    "state": "active"
                },
                "resource_part": {
                    "status": "active",
                    "level": 1,
                    "resource_key": "bullet",
                    "in_development": false
                },
                "production_part": {
                    "status": "disabled",
                    "in_development": true,
                    "purpose": null,
                    "compartments": []
                },
                "available_actions": [
                    "upgrade_resource_part"
                ],
                "lock_reasons": [],
                "metadata": {
                    "resource_spend_snapshots": [
                        {
                            "prices": [
                                {
                                    "kind": "impulse",
                                    "amount": "10000",
                                    "currency": null,
                                    "resource_key": null
                                },
                                {
                                    "kind": "xdv",
                                    "amount": "10000.000",
                                    "currency": "XDV",
                                    "resource_key": null
                                }
                            ],
                            "reason": "build",
                            "metadata": {
                                "ready_at": "2026-05-27T19:44:26.214127+00:00"
                            },
                            "recorded_at": "2026-05-27T18:44:26.214127+00:00"
                        }
                    ],
                    "last_resource_construction": {
                        "kind": "build",
                        "completed_at": "2026-05-27T19:44:26.214127+00:00",
                        "target_level": 1
                    }
                }
            },
            {
                "building_key": "galaglue_workshop",
                "title": "Chemical laboratory",
                "building_type": "resource",
                "required_level": 1,
                "early_access_level": null,
                "early_access": false,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.galaglue_workshop",
                    "state": "active"
                },
                "resource_part": {
                    "status": "active",
                    "level": 1,
                    "resource_key": "galaglue",
                    "in_development": false
                },
                "production_part": {
                    "status": "disabled",
                    "in_development": true,
                    "purpose": null,
                    "compartments": []
                },
                "available_actions": [
                    "upgrade_resource_part"
                ],
                "lock_reasons": [],
                "metadata": {
                    "resource_spend_snapshots": [
                        {
                            "prices": [
                                {
                                    "kind": "impulse",
                                    "amount": "10000",
                                    "currency": null,
                                    "resource_key": null
                                },
                                {
                                    "kind": "xdv",
                                    "amount": "10000.000",
                                    "currency": "XDV",
                                    "resource_key": null
                                }
                            ],
                            "reason": "build",
                            "metadata": {
                                "ready_at": "2026-05-27T19:44:21.342808+00:00"
                            },
                            "recorded_at": "2026-05-27T18:44:21.342808+00:00"
                        }
                    ],
                    "last_resource_construction": {
                        "kind": "build",
                        "completed_at": "2026-05-27T19:44:21.342808+00:00",
                        "target_level": 1
                    }
                }
            },
            {
                "building_key": "nuclear_acorn_workshop",
                "title": "Atomic converter",
                "building_type": "resource",
                "required_level": 1,
                "early_access_level": null,
                "early_access": false,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.nuclear_acorn_workshop",
                    "state": "active"
                },
                "resource_part": {
                    "status": "active",
                    "level": 1,
                    "resource_key": "nuclear_acorn",
                    "in_development": false
                },
                "production_part": {
                    "status": "disabled",
                    "in_development": true,
                    "purpose": null,
                    "compartments": []
                },
                "available_actions": [
                    "upgrade_resource_part"
                ],
                "lock_reasons": [],
                "metadata": {
                    "resource_spend_snapshots": [
                        {
                            "prices": [
                                {
                                    "kind": "impulse",
                                    "amount": "10000",
                                    "currency": null,
                                    "resource_key": null
                                },
                                {
                                    "kind": "xdv",
                                    "amount": "10000.000",
                                    "currency": "XDV",
                                    "resource_key": null
                                }
                            ],
                            "reason": "build",
                            "metadata": {
                                "ready_at": "2026-05-27T19:44:34.244348+00:00"
                            },
                            "recorded_at": "2026-05-27T18:44:34.244348+00:00"
                        }
                    ],
                    "last_resource_construction": {
                        "kind": "build",
                        "completed_at": "2026-05-27T19:44:34.244348+00:00",
                        "target_level": 1
                    }
                }
            },
            {
                "building_key": "gear_workshop",
                "title": "Mechanical molding node",
                "building_type": "resource",
                "required_level": 1,
                "early_access_level": null,
                "early_access": false,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.gear_workshop",
                    "state": "active"
                },
                "resource_part": {
                    "status": "active",
                    "level": 1,
                    "resource_key": "gear",
                    "in_development": false
                },
                "production_part": {
                    "status": "disabled",
                    "in_development": true,
                    "purpose": null,
                    "compartments": []
                },
                "available_actions": [
                    "upgrade_resource_part"
                ],
                "lock_reasons": [],
                "metadata": {
                    "last_demolition": {
                        "part": "all",
                        "refunds": [
                            {
                                "kind": "impulse",
                                "amount": "5000",
                                "currency": null,
                                "resource_key": null
                            },
                            {
                                "kind": "xdv",
                                "amount": "5000.000",
                                "currency": "XDV",
                                "resource_key": null
                            }
                        ],
                        "demolished_at": "2026-05-30T08:03:59.843357+00:00"
                    },
                    "resource_spend_snapshots": [
                        {
                            "prices": [
                                {
                                    "kind": "impulse",
                                    "amount": "10000",
                                    "currency": null,
                                    "resource_key": null
                                },
                                {
                                    "kind": "xdv",
                                    "amount": "10000.000",
                                    "currency": "XDV",
                                    "resource_key": null
                                }
                            ],
                            "reason": "build",
                            "metadata": {
                                "ready_at": "2026-05-30T08:05:27.733257+00:00"
                            },
                            "recorded_at": "2026-05-30T08:04:27.733257+00:00"
                        }
                    ],
                    "last_resource_construction": {
                        "kind": "build",
                        "completed_at": "2026-05-30T08:05:27.733257+00:00",
                        "target_level": 1
                    }
                }
            },
            {
                "building_key": "dna_capsule_workshop",
                "title": "DNA synthesizer",
                "building_type": "resource",
                "required_level": 1,
                "early_access_level": null,
                "early_access": false,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.dna_capsule_workshop",
                    "state": "active"
                },
                "resource_part": {
                    "status": "active",
                    "level": 1,
                    "resource_key": "dna_capsule",
                    "in_development": false
                },
                "production_part": {
                    "status": "locked",
                    "in_development": false,
                    "purpose": "Biomass cultivation",
                    "compartments": [
                        {
                            "compartment_key": "rare_biomass",
                            "title": "Rare biomass cultivation",
                            "output_key": "rare_biomass",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 4,
                            "early_access_level": 3,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        },
                        {
                            "compartment_key": "epic_biomass",
                            "title": "Epic biomass cultivation",
                            "output_key": "epic_biomass",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 5,
                            "early_access_level": 4,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        },
                        {
                            "compartment_key": "legendary_biomass",
                            "title": "Legendary biomass cultivation",
                            "output_key": "legendary_biomass",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 6,
                            "early_access_level": 5,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        }
                    ]
                },
                "available_actions": [
                    "upgrade_resource_part"
                ],
                "lock_reasons": [],
                "metadata": {
                    "resource_spend_snapshots": [
                        {
                            "prices": [
                                {
                                    "kind": "impulse",
                                    "amount": "10000",
                                    "currency": null,
                                    "resource_key": null
                                },
                                {
                                    "kind": "xdv",
                                    "amount": "10000.000",
                                    "currency": "XDV",
                                    "resource_key": null
                                }
                            ],
                            "reason": "build",
                            "metadata": {
                                "ready_at": "2026-05-27T19:44:37.384091+00:00"
                            },
                            "recorded_at": "2026-05-27T18:44:37.384091+00:00"
                        }
                    ],
                    "last_resource_construction": {
                        "kind": "build",
                        "completed_at": "2026-05-27T19:44:37.384091+00:00",
                        "target_level": 1
                    }
                }
            },
            {
                "building_key": "brick_workshop",
                "title": "Composite casting",
                "building_type": "resource",
                "required_level": 1,
                "early_access_level": null,
                "early_access": false,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.brick_workshop",
                    "state": "active"
                },
                "resource_part": {
                    "status": "active",
                    "level": 1,
                    "resource_key": "brick",
                    "in_development": false
                },
                "production_part": {
                    "status": "active",
                    "in_development": false,
                    "purpose": "Brick production from pet fragments",
                    "compartments": [
                        {
                            "compartment_key": "brick_production",
                            "title": "Brick production compartment",
                            "output_key": "brick",
                            "status": "active",
                            "level": 2,
                            "lines_unlocked": 1,
                            "required_level": 1,
                            "early_access_level": null,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [
                                "upgrade_compartment"
                            ],
                            "metadata": {
                                "early_access": false,
                                "last_upgrade": {
                                    "paid": false,
                                    "applied_at": "2026-06-02T12:02:28.840355+00:00",
                                    "target_level": 2,
                                    "purchase_mode": "single_level"
                                },
                                "spend_snapshots": [
                                    {
                                        "prices": [
                                            {
                                                "kind": "brick",
                                                "amount": "3300",
                                                "currency": null,
                                                "resource_key": "brick"
                                            },
                                            {
                                                "kind": "slot_token",
                                                "amount": "1",
                                                "currency": null,
                                                "resource_key": "slot_token"
                                            }
                                        ],
                                        "reason": "upgrade",
                                        "metadata": {
                                            "paid": false,
                                            "target_level": 1,
                                            "purchase_mode": "single_level",
                                            "payment_session_id": null
                                        },
                                        "recorded_at": "2026-06-02T11:58:42.768465+00:00"
                                    },
                                    {
                                        "prices": [
                                            {
                                                "kind": "brick",
                                                "amount": "3300",
                                                "currency": null,
                                                "resource_key": "brick"
                                            }
                                        ],
                                        "reason": "upgrade",
                                        "metadata": {
                                            "paid": false,
                                            "target_level": 2,
                                            "purchase_mode": "single_level",
                                            "payment_session_id": null
                                        },
                                        "recorded_at": "2026-06-02T12:02:28.840355+00:00"
                                    }
                                ],
                                "early_access_penalty": {
                                    "cost_multiplier": "1",
                                    "duration_multiplier": "1"
                                }
                            }
                        }
                    ]
                },
                "available_actions": [
                    "upgrade_resource_part"
                ],
                "lock_reasons": [],
                "metadata": {
                    "last_demolition": {
                        "part": "all",
                        "refunds": [
                            {
                                "kind": "impulse",
                                "amount": "5000",
                                "currency": null,
                                "resource_key": null
                            },
                            {
                                "kind": "xdv",
                                "amount": "5000.000",
                                "currency": "XDV",
                                "resource_key": null
                            }
                        ],
                        "demolished_at": "2026-06-02T11:56:49.607425+00:00"
                    },
                    "production_early_access": false,
                    "resource_spend_snapshots": [
                        {
                            "prices": [
                                {
                                    "kind": "impulse",
                                    "amount": "10000",
                                    "currency": null,
                                    "resource_key": null
                                },
                                {
                                    "kind": "xdv",
                                    "amount": "10000.000",
                                    "currency": "XDV",
                                    "resource_key": null
                                }
                            ],
                            "reason": "build",
                            "metadata": {
                                "ready_at": "2026-06-02T11:57:58.669022+00:00"
                            },
                            "recorded_at": "2026-06-02T11:56:58.669022+00:00"
                        }
                    ],
                    "last_resource_construction": {
                        "kind": "build",
                        "completed_at": "2026-06-02T11:57:58.669022+00:00",
                        "target_level": 1
                    },
                    "production_spend_snapshots": [
                        {
                            "prices": [],
                            "reason": "build",
                            "metadata": {
                                "cost_source": "embedded_resource_building_production"
                            },
                            "recorded_at": "2026-06-02T11:58:28.208361+00:00"
                        }
                    ]
                }
            },
            {
                "building_key": "life_force_workshop",
                "title": "Life force workshop",
                "building_type": "production",
                "required_level": 2,
                "early_access_level": 1,
                "early_access": true,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.life_force_workshop",
                    "state": "active"
                },
                "resource_part": {
                    "status": "disabled",
                    "level": null,
                    "resource_key": null,
                    "in_development": true
                },
                "production_part": {
                    "status": "active",
                    "in_development": false,
                    "purpose": "Extract life force from pets into fragments and resources",
                    "compartments": [
                        {
                            "compartment_key": "rare_pet_life_force",
                            "title": "Rare pet life force",
                            "output_key": "rare_pet_fragments",
                            "status": "active",
                            "level": 1,
                            "lines_unlocked": 1,
                            "required_level": 2,
                            "early_access_level": 1,
                            "early_access": true,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [
                                "upgrade_compartment"
                            ],
                            "metadata": {
                                "early_access": true,
                                "last_upgrade": {
                                    "paid": false,
                                    "applied_at": "2026-05-30T08:13:33.475202+00:00",
                                    "target_level": 1,
                                    "purchase_mode": "single_level"
                                },
                                "spend_snapshots": [
                                    {
                                        "prices": [
                                            {
                                                "kind": "brick",
                                                "amount": "3300",
                                                "currency": null,
                                                "resource_key": "brick"
                                            },
                                            {
                                                "kind": "slot_token",
                                                "amount": "1",
                                                "currency": null,
                                                "resource_key": "slot_token"
                                            }
                                        ],
                                        "reason": "upgrade",
                                        "metadata": {
                                            "paid": false,
                                            "target_level": 1,
                                            "purchase_mode": "single_level",
                                            "payment_session_id": null
                                        },
                                        "recorded_at": "2026-05-30T08:13:33.475202+00:00"
                                    }
                                ],
                                "early_access_penalty": {
                                    "cost_multiplier": "2",
                                    "duration_multiplier": "2"
                                }
                            }
                        },
                        {
                            "compartment_key": "epic_pet_life_force",
                            "title": "Epic pet life force",
                            "output_key": "epic_pet_fragments",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 3,
                            "early_access_level": 2,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        }
                    ]
                },
                "available_actions": [],
                "lock_reasons": [],
                "metadata": {
                    "production_early_access": true,
                    "production_spend_snapshots": [
                        {
                            "prices": [
                                {
                                    "kind": "impulse",
                                    "amount": "40000",
                                    "currency": null,
                                    "resource_key": null
                                },
                                {
                                    "kind": "xdv",
                                    "amount": "40000.000",
                                    "currency": "XDV",
                                    "resource_key": null
                                },
                                {
                                    "kind": "slot_token",
                                    "amount": "3",
                                    "currency": null,
                                    "resource_key": "slot_token"
                                }
                            ],
                            "reason": "build",
                            "metadata": {
                                "cost_source": "production_building_construction_costs"
                            },
                            "recorded_at": "2026-05-30T08:13:21.224791+00:00"
                        }
                    ]
                }
            },
            {
                "building_key": "pet_craft_workshop",
                "title": "Pet craft workshop",
                "building_type": "production",
                "required_level": 4,
                "early_access_level": 3,
                "early_access": false,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.pet_craft_workshop",
                    "state": "locked"
                },
                "resource_part": {
                    "status": "disabled",
                    "level": null,
                    "resource_key": null,
                    "in_development": true
                },
                "production_part": {
                    "status": "locked",
                    "in_development": false,
                    "purpose": "Craft pilot companion pets",
                    "compartments": [
                        {
                            "compartment_key": "rare_pet_craft",
                            "title": "Rare pet craft",
                            "output_key": "rare_pet",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 4,
                            "early_access_level": 3,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        },
                        {
                            "compartment_key": "epic_pet_craft",
                            "title": "Epic pet craft",
                            "output_key": "epic_pet",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 5,
                            "early_access_level": 4,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        }
                    ]
                },
                "available_actions": [],
                "lock_reasons": [
                    {
                        "code": "available_from_factory_level",
                        "detail": "Factory level is too low for this building.",
                        "required_level": 4,
                        "factory_level": 1
                    }
                ],
                "metadata": {}
            },
            {
                "building_key": "pet_incubator_workshop",
                "title": "Pet incubator",
                "building_type": "production",
                "required_level": 6,
                "early_access_level": 5,
                "early_access": false,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.pet_incubator_workshop",
                    "state": "locked"
                },
                "resource_part": {
                    "status": "disabled",
                    "level": null,
                    "resource_key": null,
                    "in_development": true
                },
                "production_part": {
                    "status": "locked",
                    "in_development": false,
                    "purpose": "Grow pets from fragments",
                    "compartments": [
                        {
                            "compartment_key": "rare_pet_incubation",
                            "title": "Rare pet incubation",
                            "output_key": "rare_pet",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 6,
                            "early_access_level": 5,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        },
                        {
                            "compartment_key": "epic_pet_incubation",
                            "title": "Epic pet incubation",
                            "output_key": "epic_pet",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 7,
                            "early_access_level": 6,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        }
                    ]
                },
                "available_actions": [],
                "lock_reasons": [
                    {
                        "code": "available_from_factory_level",
                        "detail": "Factory level is too low for this building.",
                        "required_level": 6,
                        "factory_level": 1
                    }
                ],
                "metadata": {}
            },
            {
                "building_key": "evogen_workshop",
                "title": "EvoGen workshop",
                "building_type": "production",
                "required_level": 6,
                "early_access_level": 5,
                "early_access": false,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.evogen_workshop",
                    "state": "locked"
                },
                "resource_part": {
                    "status": "disabled",
                    "level": null,
                    "resource_key": null,
                    "in_development": true
                },
                "production_part": {
                    "status": "locked",
                    "in_development": false,
                    "purpose": "Produce EvoGens",
                    "compartments": [
                        {
                            "compartment_key": "rare_evogen",
                            "title": "Rare EvoGen",
                            "output_key": "rare_evogen",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 6,
                            "early_access_level": 5,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        },
                        {
                            "compartment_key": "epic_evogen",
                            "title": "Epic EvoGen",
                            "output_key": "epic_evogen",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 7,
                            "early_access_level": 6,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        },
                        {
                            "compartment_key": "legendary_evogen",
                            "title": "Legendary EvoGen",
                            "output_key": "legendary_evogen",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 8,
                            "early_access_level": 7,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        }
                    ]
                },
                "available_actions": [],
                "lock_reasons": [
                    {
                        "code": "available_from_factory_level",
                        "detail": "Factory level is too low for this building.",
                        "required_level": 6,
                        "factory_level": 1
                    }
                ],
                "metadata": {}
            },
            {
                "building_key": "mutagen_workshop",
                "title": "Mutagen workshop",
                "building_type": "production",
                "required_level": 5,
                "early_access_level": 4,
                "early_access": false,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.mutagen_workshop",
                    "state": "locked"
                },
                "resource_part": {
                    "status": "disabled",
                    "level": null,
                    "resource_key": null,
                    "in_development": true
                },
                "production_part": {
                    "status": "locked",
                    "in_development": false,
                    "purpose": "Produce mutagens",
                    "compartments": [
                        {
                            "compartment_key": "common_mutagen",
                            "title": "Common mutagens",
                            "output_key": "common_mutagen",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 5,
                            "early_access_level": 4,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        },
                        {
                            "compartment_key": "rare_mutagen",
                            "title": "Rare mutagens",
                            "output_key": "rare_mutagen",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 6,
                            "early_access_level": 5,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        },
                        {
                            "compartment_key": "epic_mutagen",
                            "title": "Epic mutagens",
                            "output_key": "epic_mutagen",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 7,
                            "early_access_level": 6,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        },
                        {
                            "compartment_key": "legendary_mutagen",
                            "title": "Legendary mutagens",
                            "output_key": "legendary_mutagen",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 8,
                            "early_access_level": 7,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        }
                    ]
                },
                "available_actions": [],
                "lock_reasons": [
                    {
                        "code": "available_from_factory_level",
                        "detail": "Factory level is too low for this building.",
                        "required_level": 5,
                        "factory_level": 1
                    }
                ],
                "metadata": {}
            },
            {
                "building_key": "cyber_memory_workshop",
                "title": "Cyber memory workshop",
                "building_type": "production",
                "required_level": 7,
                "early_access_level": 6,
                "early_access": false,
                "mandatory": true,
                "visual": {
                    "visual_key": "factory.building.cyber_memory_workshop",
                    "state": "locked"
                },
                "resource_part": {
                    "status": "disabled",
                    "level": null,
                    "resource_key": null,
                    "in_development": true
                },
                "production_part": {
                    "status": "locked",
                    "in_development": false,
                    "purpose": "Produce nullifiers and XP capsules",
                    "compartments": [
                        {
                            "compartment_key": "base_nullifier",
                            "title": "Base nullifier",
                            "output_key": "base_nullifier",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 7,
                            "early_access_level": 6,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        },
                        {
                            "compartment_key": "max_nullifier",
                            "title": "Max nullifier",
                            "output_key": "max_nullifier",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 8,
                            "early_access_level": 7,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        },
                        {
                            "compartment_key": "xp_capsules",
                            "title": "XP capsules",
                            "output_key": "xp_capsule",
                            "status": "locked",
                            "level": 0,
                            "lines_unlocked": 0,
                            "required_level": 8,
                            "early_access_level": 7,
                            "early_access": false,
                            "in_development": false,
                            "cooldown_until": null,
                            "repair_until": null,
                            "available_actions": [],
                            "metadata": {}
                        }
                    ]
                },
                "available_actions": [],
                "lock_reasons": [
                    {
                        "code": "available_from_factory_level",
                        "detail": "Factory level is too low for this building.",
                        "required_level": 7,
                        "factory_level": 1
                    }
                ],
                "metadata": {}
            }
        ],
        "jobs": [
            {
                "job_id": "e1c617c7-f85d-41e8-a957-fd0cb2a2fe21",
                "status": "collected",
                "building_key": "brick_workshop",
                "compartment_key": "brick_production",
                "recipe_key": "brick_workshop.brick_production.level_1",
                "line_index": 1,
                "queue_position": null,
                "level_snapshot": 1,
                "catalog_version": "factory_catalog.v1",
                "started_at": "2026-05-28T09:15:26.043721Z",
                "ready_at": "2026-05-28T09:16:26.043721Z",
                "collected_at": "2026-05-28T09:16:33.422205Z",
                "cancelled_at": null,
                "cooldown_until": null,
                "subscription_required": false,
                "available_actions": [],
                "input_snapshot": {
                    "prices": [
                        {
                            "kind": "resource",
                            "amount": "1",
                            "currency": null,
                            "metadata": {
                                "rarity": "rare",
                                "entity_key": "shard_rare",
                                "recipe_key": null,
                                "entity_kind": "shard",
                                "legacy_keys": [
                                    "rare_pet_fragment",
                                    "rare_pet_fragments"
                                ],
                                "voucher_type": null,
                                "resource_type": null,
                                "source_column": "selected_pet_fragment",
                                "input_overrides": {
                                    "shard_id": "6b6e7012-9784-44ac-a3f0-26220bfb3726",
                                    "fragment_key": "shard_rare",
                                    "selected_shard_id": "6b6e7012-9784-44ac-a3f0-26220bfb3726"
                                },
                                "requires_selection": true
                            },
                            "resource_key": "shard_rare"
                        }
                    ],
                    "input_overrides": {
                        "shard_id": "6b6e7012-9784-44ac-a3f0-26220bfb3726",
                        "fragment_key": "shard_rare",
                        "selected_shard_id": "6b6e7012-9784-44ac-a3f0-26220bfb3726"
                    }
                },
                "output_snapshot": {
                    "outputs": [
                        {
                            "kind": "brick",
                            "amount": "13",
                            "currency": null,
                            "resource_key": "brick"
                        }
                    ],
                    "brick_special": {
                        "type": "brick_craft",
                        "lucky": false,
                        "explosive": false,
                        "luck_roll": "0.965918",
                        "base_output": "13",
                        "final_output": "13",
                        "fragment_key": "shard_rare",
                        "repair_hours": "0",
                        "explosion_roll": "0.343847",
                        "luck_multiplier": "3",
                        "luck_probability": "0.25",
                        "explosion_probability": "0.05"
                    }
                },
                "modifier_snapshot": {
                    "boosters": {
                        "active_boosters": [],
                        "cost_multiplier": "1",
                        "output_multiplier": "1",
                        "duration_multiplier": "1"
                    },
                    "features": [],
                    "expires_at": null,
                    "active_tier": "none",
                    "queue_limit": 0,
                    "early_access": false,
                    "queue_enabled": false,
                    "cooldown_hours": "0",
                    "duration_hours": "8",
                    "autocraft_collect": false,
                    "next_settlement_at": null,
                    "cooldown_multiplier": "1",
                    "extra_lines_enabled": false,
                    "resource_multiplier": "1",
                    "autocollect_resources": false,
                    "craft_cost_multiplier": "1",
                    "craft_duration_multiplier": "1",
                    "slot_token_drop_multiplier": "1",
                    "construction_speed_multiplier": "1",
                    "construction_duration_multiplier": "1"
                }
            },
            {
                "job_id": "eb987586-d06f-415e-973e-a169b6681bfd",
                "status": "collected",
                "building_key": "brick_workshop",
                "compartment_key": "brick_production",
                "recipe_key": "brick_workshop.brick_production.level_1",
                "line_index": 1,
                "queue_position": null,
                "level_snapshot": 1,
                "catalog_version": "factory_catalog.v1",
                "started_at": "2026-05-28T09:38:15.206418Z",
                "ready_at": "2026-05-28T09:39:15.206418Z",
                "collected_at": "2026-05-28T09:40:02.740220Z",
                "cancelled_at": null,
                "cooldown_until": null,
                "subscription_required": false,
                "available_actions": [],
                "input_snapshot": {
                    "prices": [
                        {
                            "kind": "resource",
                            "amount": "1",
                            "currency": null,
                            "metadata": {
                                "rarity": "rare",
                                "entity_key": "shard_rare",
                                "recipe_key": null,
                                "entity_kind": "shard",
                                "legacy_keys": [
                                    "rare_pet_fragment",
                                    "rare_pet_fragments"
                                ],
                                "voucher_type": null,
                                "resource_type": null,
                                "source_column": "selected_pet_fragment",
                                "input_overrides": {
                                    "shard_id": "82d97bf1-872f-4d76-88e4-da587d6eb515",
                                    "fragment_key": "shard_rare",
                                    "selected_shard_id": "82d97bf1-872f-4d76-88e4-da587d6eb515"
                                },
                                "requires_selection": true
                            },
                            "resource_key": "shard_rare"
                        }
                    ],
                    "input_overrides": {
                        "shard_id": "82d97bf1-872f-4d76-88e4-da587d6eb515",
                        "fragment_key": "shard_rare",
                        "selected_shard_id": "82d97bf1-872f-4d76-88e4-da587d6eb515"
                    }
                },
                "output_snapshot": {
                    "outputs": [
                        {
                            "kind": "brick",
                            "amount": "13",
                            "currency": null,
                            "resource_key": "brick"
                        }
                    ],
                    "brick_special": {
                        "type": "brick_craft",
                        "lucky": false,
                        "explosive": false,
                        "luck_roll": "0.77377",
                        "base_output": "13",
                        "final_output": "13",
                        "fragment_key": "shard_rare",
                        "repair_hours": "0",
                        "explosion_roll": "0.982372",
                        "luck_multiplier": "3",
                        "luck_probability": "0.25",
                        "explosion_probability": "0.05"
                    }
                },
                "modifier_snapshot": {
                    "boosters": {
                        "active_boosters": [],
                        "cost_multiplier": "1",
                        "output_multiplier": "1",
                        "duration_multiplier": "1"
                    },
                    "features": [],
                    "expires_at": null,
                    "active_tier": "none",
                    "queue_limit": 0,
                    "early_access": false,
                    "queue_enabled": false,
                    "cooldown_hours": "0",
                    "duration_hours": "8",
                    "autocraft_collect": false,
                    "next_settlement_at": null,
                    "cooldown_multiplier": "1",
                    "extra_lines_enabled": false,
                    "resource_multiplier": "1",
                    "autocollect_resources": false,
                    "craft_cost_multiplier": "1",
                    "craft_duration_multiplier": "1",
                    "slot_token_drop_multiplier": "1",
                    "construction_speed_multiplier": "1",
                    "construction_duration_multiplier": "1"
                }
            },
            {
                "job_id": "9f6a2b92-dff8-4026-9767-de12b27367d4",
                "status": "collected",
                "building_key": "brick_workshop",
                "compartment_key": "brick_production",
                "recipe_key": "brick_workshop.brick_production.level_1",
                "line_index": 1,
                "queue_position": null,
                "level_snapshot": 1,
                "catalog_version": "factory_catalog.v1",
                "started_at": "2026-05-28T09:40:29.319861Z",
                "ready_at": "2026-05-28T09:41:29.319861Z",
                "collected_at": "2026-05-28T09:48:30.009774Z",
                "cancelled_at": null,
                "cooldown_until": null,
                "subscription_required": false,
                "available_actions": [],
                "input_snapshot": {
                    "prices": [
                        {
                            "kind": "resource",
                            "amount": "1",
                            "currency": null,
                            "metadata": {
                                "rarity": "rare",
                                "entity_key": "shard_rare",
                                "recipe_key": null,
                                "entity_kind": "shard",
                                "legacy_keys": [
                                    "rare_pet_fragment",
                                    "rare_pet_fragments"
                                ],
                                "voucher_type": null,
                                "resource_type": null,
                                "source_column": "selected_pet_fragment",
                                "input_overrides": {
                                    "shard_id": "1133ae32-4d62-448c-9154-444f9cd3cb1d",
                                    "fragment_key": "shard_rare",
                                    "selected_shard_id": "1133ae32-4d62-448c-9154-444f9cd3cb1d"
                                },
                                "requires_selection": true
                            },
                            "resource_key": "shard_rare"
                        }
                    ],
                    "input_overrides": {
                        "shard_id": "1133ae32-4d62-448c-9154-444f9cd3cb1d",
                        "fragment_key": "shard_rare",
                        "selected_shard_id": "1133ae32-4d62-448c-9154-444f9cd3cb1d"
                    }
                },
                "output_snapshot": {
                    "outputs": [
                        {
                            "kind": "brick",
                            "amount": "16",
                            "currency": null,
                            "resource_key": "brick"
                        }
                    ],
                    "brick_special": {
                        "type": "brick_craft",
                        "lucky": false,
                        "explosive": false,
                        "luck_roll": "0.443757",
                        "base_output": "15.60000000",
                        "final_output": "15.60000000",
                        "fragment_key": "shard_rare",
                        "repair_hours": "0",
                        "explosion_roll": "0.098913",
                        "luck_multiplier": "3",
                        "luck_probability": "0.25",
                        "explosion_probability": "0.05"
                    }
                },
                "modifier_snapshot": {
                    "boosters": {
                        "active_boosters": [
                            {
                                "scope_key": "brick_workshop.brick_production",
                                "expires_at": "2026-05-29T09:38:44.871534+00:00",
                                "scope_type": "compartment",
                                "booster_key": "factory_employee_speed",
                                "effect_type": "speed"
                            },
                            {
                                "scope_key": "brick_workshop.brick_production",
                                "expires_at": "2026-06-04T09:38:57.572377+00:00",
                                "scope_type": "compartment",
                                "booster_key": "factory_employee_output",
                                "effect_type": "output"
                            }
                        ],
                        "cost_multiplier": "1.00000000",
                        "output_multiplier": "1.20000000",
                        "duration_multiplier": "0.80000000"
                    },
                    "features": [],
                    "expires_at": null,
                    "active_tier": "none",
                    "queue_limit": 0,
                    "early_access": false,
                    "queue_enabled": false,
                    "cooldown_hours": "0",
                    "duration_hours": "6.40000000",
                    "autocraft_collect": false,
                    "next_settlement_at": null,
                    "cooldown_multiplier": "1",
                    "extra_lines_enabled": false,
                    "resource_multiplier": "1",
                    "autocollect_resources": false,
                    "craft_cost_multiplier": "1",
                    "craft_duration_multiplier": "1",
                    "slot_token_drop_multiplier": "1",
                    "construction_speed_multiplier": "1",
                    "construction_duration_multiplier": "1"
                }
            },
            {
                "job_id": "3a08a524-1101-4d5c-8e9b-2cbc0e0720c2",
                "status": "collected",
                "building_key": "brick_workshop",
                "compartment_key": "brick_production",
                "recipe_key": "brick_workshop.brick_production.level_1",
                "line_index": 1,
                "queue_position": null,
                "level_snapshot": 1,
                "catalog_version": "factory_catalog.v1",
                "started_at": "2026-05-28T10:39:02.359748Z",
                "ready_at": "2026-05-28T10:40:02.359748Z",
                "collected_at": "2026-05-28T10:40:05.282960Z",
                "cancelled_at": null,
                "cooldown_until": null,
                "subscription_required": false,
                "available_actions": [],
                "input_snapshot": {
                    "prices": [
                        {
                            "kind": "resource",
                            "amount": "1",
                            "currency": null,
                            "metadata": {
                                "rarity": "rare",
                                "entity_key": "shard_rare",
                                "recipe_key": null,
                                "entity_kind": "shard",
                                "legacy_keys": [
                                    "rare_pet_fragment",
                                    "rare_pet_fragments"
                                ],
                                "voucher_type": null,
                                "resource_type": null,
                                "source_column": "selected_pet_fragment",
                                "input_overrides": {
                                    "shard_id": "1133ae32-4d62-448c-9154-444f9cd3cb1d",
                                    "fragment_key": "shard_rare",
                                    "selected_shard_id": "1133ae32-4d62-448c-9154-444f9cd3cb1d"
                                },
                                "requires_selection": true
                            },
                            "resource_key": "shard_rare"
                        }
                    ],
                    "input_overrides": {
                        "shard_id": "1133ae32-4d62-448c-9154-444f9cd3cb1d",
                        "fragment_key": "shard_rare",
                        "selected_shard_id": "1133ae32-4d62-448c-9154-444f9cd3cb1d"
                    }
                },
                "output_snapshot": {
                    "outputs": [
                        {
                            "kind": "brick",
                            "amount": "16",
                            "currency": null,
                            "resource_key": "brick"
                        }
                    ],
                    "brick_special": {
                        "type": "brick_craft",
                        "lucky": false,
                        "explosive": false,
                        "luck_roll": "0.299616",
                        "base_output": "15.60000000",
                        "final_output": "15.60000000",
                        "fragment_key": "shard_rare",
                        "repair_hours": "0",
                        "explosion_roll": "0.983066",
                        "luck_multiplier": "3",
                        "luck_probability": "0.25",
                        "explosion_probability": "0.05"
                    }
                },
                "modifier_snapshot": {
                    "boosters": {
                        "active_boosters": [
                            {
                                "scope_key": "brick_workshop.brick_production",
                                "expires_at": "2026-05-29T09:38:44.871534+00:00",
                                "scope_type": "compartment",
                                "booster_key": "factory_employee_speed",
                                "effect_type": "speed"
                            },
                            {
                                "scope_key": "brick_workshop.brick_production",
                                "expires_at": "2026-06-04T09:38:57.572377+00:00",
                                "scope_type": "compartment",
                                "booster_key": "factory_employee_output",
                                "effect_type": "output"
                            }
                        ],
                        "cost_multiplier": "1.00000000",
                        "output_multiplier": "1.20000000",
                        "duration_multiplier": "0.80000000"
                    },
                    "features": [],
                    "expires_at": null,
                    "active_tier": "none",
                    "queue_limit": 0,
                    "early_access": false,
                    "queue_enabled": false,
                    "cooldown_hours": "0",
                    "duration_hours": "6.40000000",
                    "autocraft_collect": false,
                    "next_settlement_at": null,
                    "cooldown_multiplier": "1",
                    "extra_lines_enabled": false,
                    "resource_multiplier": "1",
                    "autocollect_resources": false,
                    "craft_cost_multiplier": "1",
                    "craft_duration_multiplier": "1",
                    "slot_token_drop_multiplier": "1",
                    "construction_speed_multiplier": "1",
                    "construction_duration_multiplier": "1"
                }
            }
        ],
        "boosters": [
            {
                "booster_id": "0bf81da8-75fa-417c-8797-8414f407a43d",
                "booster_key": "factory_employee_output",
                "scope_type": "compartment",
                "scope_key": "brick_workshop.brick_production",
                "status": "active",
                "output_multiplier": "1.2",
                "duration_multiplier": "1",
                "cost_multiplier": "1",
                "price_amount": "2",
                "price_kind": "game_dollar",
                "hired_at": "2026-05-28T09:38:57.572377Z",
                "starts_at": "2026-05-28T09:38:57.572377Z",
                "expires_at": "2026-06-04T09:38:57.572377Z",
                "metadata": {
                    "price": {
                        "kind": "game_dollar",
                        "amount": "2.00",
                        "currency": "USD",
                        "resource_key": null
                    },
                    "title": "Biotechnician Lyra",
                    "effect_type": "output",
                    "duration_days": 7
                }
            }
        ],
        "notifications": [],
        "available_actions": [
            {
                "code": "claim_impulses",
                "enabled": true,
                "idempotency_required": true,
                "payment_options": [],
                "missing_requirements": [],
                "lock_reasons": [],
                "metadata": {}
            },
            {
                "code": "upgrade_level",
                "enabled": true,
                "idempotency_required": true,
                "payment_options": [
                    {
                        "option_key": "level_2_real_money",
                        "method": "real_money",
                        "prices": [
                            {
                                "kind": "real_money",
                                "amount": "15",
                                "currency": "USD",
                                "resource_key": null,
                                "label": null,
                                "title": null,
                                "icon": null,
                                "visual_key": null,
                                "metadata": {}
                            }
                        ],
                        "enabled": true,
                        "lock_reasons": []
                    },
                    {
                        "option_key": "level_2_game_dollar",
                        "method": "game_dollar",
                        "prices": [
                            {
                                "kind": "game_dollar",
                                "amount": "375",
                                "currency": "USD",
                                "resource_key": null,
                                "label": null,
                                "title": "Game dollars",
                                "icon": "dollar.webp",
                                "visual_key": "factory.icon.game_dollar",
                                "metadata": {}
                            }
                        ],
                        "enabled": true,
                        "lock_reasons": []
                    },
                    {
                        "option_key": "level_2_brick",
                        "method": "brick",
                        "prices": [
                            {
                                "kind": "brick",
                                "amount": "15000",
                                "currency": null,
                                "resource_key": "brick",
                                "label": null,
                                "title": "brick",
                                "icon": "brick.webp",
                                "visual_key": "factory.icon.brick",
                                "metadata": {}
                            }
                        ],
                        "enabled": true,
                        "lock_reasons": []
                    }
                ],
                "missing_requirements": [],
                "lock_reasons": [],
                "metadata": {
                    "target_level": 2
                }
            }
        ]
    },
    "notifications": [],
    "errors": [
        {
            "code": "insufficient_balance",
            "detail": "Insufficient balance for factory craft.",
            "context": {
                "balance_key": "user_character_rare",
                "required": "2.0000",
                "available": "1",
                "building_key": "life_force_workshop",
                "compartment_key": "rare_pet_life_force",
                "line_index": 1,
                "recipe_key": "life_force_workshop.rare_pet_life_force.level_1",
                "input_overrides": {
                    "user_character_id": "8e8e13e0-ee9c-412d-b0eb-76251cd7b94c",
                    "selected_user_character_id": "8e8e13e0-ee9c-412d-b0eb-76251cd7b94c"
                }
            }
        }
    ],
    "metadata": {}
}
