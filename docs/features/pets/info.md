# Pets Info

Окей, возвращаю нормально и с картинками-схемами. Ничего пока не чиним, просто строим карту, чтобы дальше не резать вслепую.

1. Общая Картина
   В идеальном мире должно быть так:

Базовый пет
живет в characters
subkind = default

Скин пета
живет в pet_skin_defs
is_default = false
character_id -> базовый пет из characters

Дефолтная возрастная картинка пета
тоже живет в pet_skin_defs
is_default = true
character_id -> базовый пет из characters
Но в текущей БД исторически получилось вот так:

characters
├─ настоящие базовые петы
├─ некоторые скины/вариации, ошибочно заведенные как Character
└─ некоторые сущности, которые по списку должны быть базовыми петами,
но заведены как special/halloween/etc

pet_skin_defs
├─ дефолтные age/evolution картинки
└─ настоящие предметные скины
То есть главная путаница: characters сейчас не чистая таблица базовых петов. Там лежит смесь.

2. Схема Таблиц

characters
+----------------+----------------------------------+
| uuid | id пета/персонажа |
| title | название |
| kind | семейство: fox, bear, panda... |
| rarity | rare / epic / legendary |
| subkind | default / special / halloween... |
| cost | цена |
| icon | иконка |
| image | картинка |
+----------------+----------------------------------+
Правило, которое должно быть главным:

characters.subkind = default
значит: базовый пет

characters.subkind != default
значит: вариация/ивентовый вариант/старый скин, НЕ базовый пет
Пример:

Кибер Хамелеон
characters.kind = chameleon
characters.subkind = default
=> базовый пет

Бумелеон
characters.kind = chameleon
characters.subkind = halloween
=> не базовый пет, а вариация/скин 3. pet_skin_defs

pet_skin_defs
+----------------+------------------------------------------+
| uuid | id конкретной skin-записи |
| character_id | ссылка на characters.uuid |
| title | название скина/возрастной картинки |
| image | полноценная картинка |
| icon | иконка |
| icon_2x/3x | иконки большего размера |
| rarity | редкость скина |
| is_default | ключевой флаг |
| min_level | уровень, с которого доступен дефолт |
| max_level | уровень, до которого доступен дефолт |
| sort_order | порядок/возраст |
+----------------+------------------------------------------+
И вот тут важнейшая развилка:

pet_skin_defs.is_default = true
Это не магазинный скин. Это дефолтная возрастная картинка базового пета.

Например:

Кибер Лиса 1
Кибер Лиса 2
Кибер Лиса 3
Кибер Лиса 4
Это не разные товары. Это как выглядит базовая Лиса на разных стадиях/уровнях.

pet_skin_defs.is_default = false
Это уже настоящий предметный скин. Его можно купить/выдать, и он попадает пользователю как UserSkinItem.

Например:

Рыжая Лиса 1
Рыжая Лиса 2
Рыжая Лиса 3
Рыжая Лиса 4
Это skin-def записи для скина “Рыжая Лиса”.

4. Как Связаны Базовый Пет И Скин

characters
┌──────────────────────────────┐
│ Кибер Лиса │
│ uuid = A │
│ kind = fox │
│ subkind = default │
└──────────────┬───────────────┘
│
│ character_id = A
▼
pet_skin_defs
┌──────────────────────────────┐
│ Кибер Лиса 1 │
│ is_default = true │
└──────────────────────────────┘
┌──────────────────────────────┐
│ Кибер Лиса 2 │
│ is_default = true │
└──────────────────────────────┘
┌──────────────────────────────┐
│ Рыжая Лиса 1 │
│ is_default = false │
└──────────────────────────────┘
┌──────────────────────────────┐
│ Лиса-пловчиха 1 │
│ is_default = false │
└──────────────────────────────┘
Вот это правильная модель.

5. Как Работает Магазин

Магазин не ходит напрямую “просто по всем петам”. Он читает cab_shop_items.

cab_shop_items
+---------------+----------------+----------------------+
| section | source_type | source_ref |
+---------------+----------------+----------------------+
| pets | character | characters.uuid |
| pet_skins | pet_skin | pet_skin_defs.uuid |
+---------------+----------------+----------------------+
Если товар такой:

section = pets
source_type = character
source_ref = uuid из characters
то покупка создает:

user_characters
То есть пользователь получает нового пета.

Если товар такой:

section = pet_skins
source_type = pet_skin
source_ref = uuid из pet_skin_defs
то покупка создает:

user_skin_items
То есть пользователь получает скин-предмет.

6. Где Сломалось

Сломалось вот здесь:

shop seed берет characters
WHERE cost > 0
А должен брать:

characters
WHERE cost > 0
AND subkind = default
Сейчас он не проверяет subkind. Поэтому если в characters лежит:

Бумелеон
subkind = halloween
cost = 100
магазин думает:

О, Character с ценой. Значит это пет.
И кладет его в:

cab_shop_items.section = pets
Хотя по смыслу это скин.

7. Почему Показывается Иконка Вместо Скина

Для pets backend строит карточку из Character:

pets -> Character -> source.icon
Для pet_skins backend строит карточку из PetSkinDef:

pet_skins -> PetSkinDef -> source.image
Поэтому если скин ошибочно попал в pets, магазин показывает его как Character и часто берет icon.svg, старую иконку или неправильный fallback.

Пример:

Dracuhog
лежит в characters
subkind = halloween
icon = icon.svg

shop видит его как pets/character
=> показывает icon.svg
А правильный вариант должен быть:

Ёж-Вампир 1..6
лежит в pet_skin_defs
is_default = false
character_id -> Кибер Ёж

shop должен видеть его как pet_skins/pet_skin
=> показывает нормальный image 8. Почему Некоторые Есть Дважды

Например Бумелеон:

characters
Бумелеон
kind = chameleon
subkind = halloween
cost = 100
и одновременно:

pet_skin_defs
Бумелеон 1
Бумелеон 2
Бумелеон 3
Бумелеон 4
Бумелеон 5
is_default = false
character_id -> Кибер Хамелеон
Правильная товарная сущность тут — pet_skin_defs.
characters.Бумелеон либо старый легаси-вариант, либо должен быть выведен из магазина/каталога.

9. Три Типа Ошибок В БД

Тип A: скин лежит в characters и попадает в pets
Примеры:

Boomeleon
Dracuhog
Swimming Fox
Cryptowolf
Gingerbread Raccoon
Athletic Trot
Burning Squirrel
Правильное действие потом: убрать их из pets, использовать pet_skin_defs.is_default=false.

Тип B: скин помечен как базовый пет
Примеры:

Red Panda
Winner Kangaroo
Они сейчас:

characters.subkind = default
но по утвержденному списку это скины. При этом skin defs для них уже есть. Значит их надо будет аккуратно выводить из роли базовых петов.

Тип C: базовый пет заведен как special, а default-базы нет
Примеры из аудита:

Capybara
Hippo
Badger
Cyber Dragon
Cyber Crocodile
Elephant
Jetboa / Тушканчик
Rhinocesor / Носорог
Тут наоборот: если по утвержденному списку это базовые петы, их надо не переносить в скины, а сделать нормальными subkind=default базовыми петами.

10. Короткая Формула

characters.subkind = default
= базовый пет

characters.subkind != default
= НЕ должен продаваться как пет

pet_skin_defs.is_default = true
= дефолтная возрастная картинка, НЕ товар

pet_skin_defs.is_default = false
= настоящий скин-товар

cab_shop_items.section = pets
= должен ссылаться только на characters.subkind=default

cab_shop_items.section = pet_skins
= должен ссылаться только на pet_skin_defs.is_default=false
И главный корень хаоса:

старые/ивентовые character-вариации имеют cost > 0 +
shop seed берет всех characters с cost > 0
=
скины попадают в магазин как петы
