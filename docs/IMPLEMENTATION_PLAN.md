# Aanda — Shared Cost & Meal Tracker: Implementation Plan

## Overview

**Aanda** is a shared-living management app for roommates. It lets members of a household:
- Track personal and shared costs (fixed & variable, preset-based)
- Log daily meal counts (breakfast / lunch / dinner) per person
- Get automatic monthly settlement calculations (meal rate, per-person cost, rent split, etc.)

**Tech Stack:** Flutter · Bloc (DI + state) · Supabase (PostgreSQL) · freezed/json_serializable · go_router

---

## Open Questions / Design Decisions

> [!IMPORTANT]
> Please review and answer these before we start coding.

1. **Authentication model** — The current codebase uses a PIN-based **local** auth (secure storage). For a shared multi-user app backed by Supabase, we need real cloud auth (Supabase Auth — email/password or magic link). Should we:
   - **A) Replace** local auth entirely with Supabase Auth (recommended for a multi-user app)?
   - **B) Keep** local PIN as a secondary screen-lock after Supabase sign-in?

2. **House / Household model** — A "house" is the shared unit. Should one user be able to belong to **multiple** houses (e.g., different months), or just one active house at a time?

3. **Invite / Join flow** — How do members join a house? Options:
   - **A) Invite code** (6-char code) — member enters it to join
   - **B) Admin manually adds members** by email/username
   - **C) Both**

4. **Monthly settlement** — At month end, should the app:
   - Auto-calculate and show a "monthly report" screen?
   - Allow marking a settlement as "paid/closed"?
   - Send push notifications for settlement?

5. **Cost preset library** — Are presets shared house-wide (e.g., "Electricity", "Internet") or personal (e.g., "Gym membership")?

6. **Offline support** — Supabase supports real-time reads and writes via its Dart client; offline write is **not** natively supported (writes fail without network). Should we:
   - Accept online-only (simplest, recommended for v1)?
   - Add local SQLite as an offline write queue for later?

> [!NOTE]
> The plan below assumes: **A) Supabase Auth replaces local PIN auth**, one active house, invite-code join, auto monthly report, presets are house-wide, and **online-only for v1**.

---

## Business Logic

### Core Entities

| Entity | Description |
|---|---|
| `User` | Supabase Auth user; has profile (name, avatar URL) |
| `House` | Shared living unit; has a name, invite code, admin |
| `HouseMember` | Junction: User ↔ House, with role (admin/member), joined_at |
| `CostCategory` | Named category (e.g., "Groceries", "Electricity") |
| `CostPreset` | Reusable cost template (name, amount, type fixed/variable, category) |
| `Cost` | An actual cost entry: amount, type, scope (personal/shared), date, paid_by |
| `MealLog` | Per-user per-day: breakfast + lunch + dinner counts (double) |
| `MonthlySettlement` | Computed summary per billing month: meal rate, per-person cost, etc. |

### Cost Rules
- A cost can be **personal** (only visible/counted to the payer) or **shared** (split among all house members)
- Cost type: **fixed** (same every month, e.g., rent) or **variable** (one-off, e.g., groceries)
- Costs can be created from a **preset** or from scratch
- Shared costs are split equally among active members (or weighted by meal count for meal-related costs)

### Meal Rules
- Each member logs their own meals for each day
- Meal count is a `double` — values like `0.5`, `1.0`, `1.5`, `2.0`, `3.0` are valid
- **Meal Rate** = Total shared variable food cost / Total meal counts across all members for that month
- Each member's meal charge = their meal count × meal rate

### Monthly Settlement Calculation
```
Total Fixed Shared Cost  = sum of all shared fixed costs for the month
Total Variable Food Cost = sum of all shared variable costs tagged as food
Total Other Variable     = sum of other shared variable costs
Meal Rate                = Total Variable Food Cost / Total Meal Count (all members)
Member Meal Charge       = member_total_meals × meal_rate
Member Share of Fixed    = Total Fixed Shared Cost / number_of_members
Member Total Owed        = Member Meal Charge + Member Share of Fixed + Member Share of Other Variable
Net Settlement           = Member Total Owed − Member Personal Costs Already Paid
```

---

## Database Schema (PostgreSQL / Supabase)

### Tables

#### `profiles`
Extension of Supabase `auth.users`.
```sql
create table profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  username    text unique not null,
  full_name   text,
  avatar_url  text,
  created_at  timestamptz default now()
);
```

#### `houses`
```sql
create table houses (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  invite_code  text unique not null default substr(md5(random()::text), 1, 8),
  created_by   uuid not null references profiles(id),
  created_at   timestamptz default now()
);
```

#### `house_members`
```sql
create type member_role as enum ('admin', 'member');

create table house_members (
  id         uuid primary key default gen_random_uuid(),
  house_id   uuid not null references houses(id) on delete cascade,
  user_id    uuid not null references profiles(id) on delete cascade,
  role       member_role not null default 'member',
  joined_at  timestamptz default now(),
  unique(house_id, user_id)
);
```

#### `cost_categories`
```sql
create table cost_categories (
  id        uuid primary key default gen_random_uuid(),
  house_id  uuid not null references houses(id) on delete cascade,
  name      text not null,
  icon      text,             -- icon name/code
  is_food   boolean default false,  -- used for meal rate calc
  created_at timestamptz default now()
);
```

#### `cost_presets`
```sql
create type cost_type as enum ('fixed', 'variable');
create type cost_scope as enum ('personal', 'shared');

create table cost_presets (
  id           uuid primary key default gen_random_uuid(),
  house_id     uuid not null references houses(id) on delete cascade,
  name         text not null,
  amount       numeric(12,2) not null default 0,
  cost_type    cost_type not null,
  cost_scope   cost_scope not null,
  category_id  uuid references cost_categories(id) on delete set null,
  created_by   uuid not null references profiles(id),
  created_at   timestamptz default now()
);
```

#### `costs`
```sql
create table costs (
  id           uuid primary key default gen_random_uuid(),
  house_id     uuid not null references houses(id) on delete cascade,
  paid_by      uuid not null references profiles(id),
  preset_id    uuid references cost_presets(id) on delete set null,
  category_id  uuid references cost_categories(id) on delete set null,
  name         text not null,
  amount       numeric(12,2) not null,
  cost_type    cost_type not null,
  cost_scope   cost_scope not null,
  note         text,
  date         date not null default current_date,
  billing_month text not null,  -- format: 'YYYY-MM', for monthly grouping
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);
-- Index for fast monthly queries
create index costs_billing_month_idx on costs(house_id, billing_month);
```

#### `meal_logs`
```sql
create table meal_logs (
  id         uuid primary key default gen_random_uuid(),
  house_id   uuid not null references houses(id) on delete cascade,
  user_id    uuid not null references profiles(id),
  date       date not null,
  breakfast  numeric(4,2) not null default 0,
  lunch      numeric(4,2) not null default 0,
  dinner     numeric(4,2) not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(house_id, user_id, date)   -- one row per person per day
);
create index meal_logs_house_date_idx on meal_logs(house_id, date);
```

#### `monthly_settlements`  _(cached computation)_
```sql
create table monthly_settlements (
  id                 uuid primary key default gen_random_uuid(),
  house_id           uuid not null references houses(id) on delete cascade,
  billing_month      text not null,           -- 'YYYY-MM'
  meal_rate          numeric(12,4),
  total_fixed_cost   numeric(12,2),
  total_food_cost    numeric(12,2),
  total_other_cost   numeric(12,2),
  total_meal_count   numeric(12,2),
  member_summaries   jsonb,                   -- array of per-member breakdown
  is_closed          boolean default false,
  closed_at          timestamptz,
  created_at         timestamptz default now(),
  updated_at         timestamptz default now(),
  unique(house_id, billing_month)
);
```

### Row-Level Security (RLS) Strategy
- All tables are protected by RLS
- A user can only read/write data for houses they are a member of
- Helper function: `is_house_member(house_id uuid)` returns bool
- Admins can additionally manage members, presets, and categories

### Supabase Realtime
Enable realtime on: `costs`, `meal_logs`, `house_members` — for live multi-user sync.

---

## Flutter Architecture

### Folder Structure (Feature-Slice)

```
lib/
  main.dart
  src/
    app/
      bloc/
        auth_guard/          ← existing, adapt for Supabase Auth
        dashboard/           ← existing, adapt
        app_theme_cubit.dart
      routing/               ← existing, add new routes
      view/
    core/
      async_handlers/        ← existing, keep
      constants/             ← existing, keep
      error_handler/         ← existing, keep
      shared/                ← existing, keep
      theme/                 ← existing, keep
      usecases/              ← existing, keep
      utils/                 ← existing, keep
    features/
      auth/                  ← MODIFY: replace local storage with Supabase Auth
      house/                 ← NEW
      costs/                 ← NEW
      meals/                 ← NEW
      settlement/            ← NEW
```

### Feature: `auth` (Modified)

**Changes:**
- Replace `AuthStorage` (secure storage) with `SupabaseAuthDatasource`
- `Account` entity extended to include `id: String` (Supabase UUID), `email`, `fullName`
- Auth now uses `supabase.auth.signUp`, `signInWithPassword`, `signOut`
- `AuthStatus` remains the same sealed class — just the underlying data changes
- Local PIN screen-lock is kept as an optional UX layer (post-auth PIN), not affecting Supabase sessions

**New use cases:**
- `SignUpWithEmail` — register with email + password + username
- `SignInWithEmail` — login
- `SignOut` — logout
- `GetCurrentSession` — check Supabase session on app start

---

### Feature: `house`

#### Domain
```
house/
  domain/
    entities/
      house.dart              -- id, name, inviteCode, createdBy, createdAt
      house_member.dart       -- id, houseId, userId, role, joinedAt
      member_role.dart        -- enum: admin | member
    repo/
      house_repo.dart         -- interface
    usecases/
      create_house.dart
      join_house.dart         -- by invite code
      get_my_houses.dart
      get_house_members.dart
      leave_house.dart
      remove_member.dart      -- admin only
      regenerate_invite_code.dart
```

#### Data
```
  data/
    models/
      house_model.dart        -- freezed, fromJson/toJson
      house_member_model.dart
    datasources/
      house_remote_datasource.dart    -- Supabase CRUD
    repo/
      house_repo_impl.dart
```

#### Presentation
```
  presentation/
    bloc/
      house_list/            -- lists houses user belongs to
      house_detail/          -- members, invite code, settings
      house_create/          -- create flow
      house_join/            -- join by code
    screens/
      house_list_screen.dart
      house_detail_screen.dart
      house_create_screen.dart
      house_join_screen.dart
    widgets/
      member_tile.dart
      invite_code_card.dart
```

---

### Feature: `costs`

#### Domain
```
costs/
  domain/
    entities/
      cost.dart              -- all cost fields
      cost_category.dart
      cost_preset.dart
      cost_type.dart         -- enum: fixed | variable
      cost_scope.dart        -- enum: personal | shared
    repo/
      cost_repo.dart
    usecases/
      add_cost.dart
      edit_cost.dart
      delete_cost.dart
      get_costs.dart         -- paginated, filterable by month/scope/type
      get_cost_categories.dart
      create_cost_preset.dart
      get_cost_presets.dart
      delete_cost_preset.dart
```

#### Data
```
  data/
    models/
      cost_model.dart
      cost_category_model.dart
      cost_preset_model.dart
    datasources/
      cost_remote_datasource.dart
    repo/
      cost_repo_impl.dart
```

#### Presentation
```
  presentation/
    bloc/
      cost_feed/             -- paginated list, filter by month
      cost_form/             -- create/edit cost, preset picker
      preset_list/           -- manage presets
      category_manage/       -- manage categories
    screens/
      cost_feed_screen.dart
      cost_form_screen.dart
      preset_list_screen.dart
    widgets/
      cost_tile.dart
      cost_filter_bar.dart
      cost_type_badge.dart
      preset_picker_sheet.dart
      scope_selector.dart
```

---

### Feature: `meals`

#### Domain
```
meals/
  domain/
    entities/
      meal_log.dart         -- houseId, userId, date, breakfast, lunch, dinner
    repo/
      meal_repo.dart
    usecases/
      log_meal.dart         -- upsert for user+date
      get_meal_logs.dart    -- for a house, optional date range
      get_my_meal_logs.dart -- current user
      get_monthly_meal_totals.dart  -- aggregated
```

#### Data
```
  data/
    models/
      meal_log_model.dart
    datasources/
      meal_remote_datasource.dart
    repo/
      meal_repo_impl.dart
```

#### Presentation
```
  presentation/
    bloc/
      meal_calendar/        -- monthly view, tap day to log
      meal_log_form/        -- log/edit breakfast+lunch+dinner for a day
      meal_summary/         -- per-member monthly meal totals
    screens/
      meal_calendar_screen.dart
      meal_log_form_screen.dart
      meal_summary_screen.dart
    widgets/
      meal_day_card.dart
      meal_counter_input.dart  -- stepper: 0, 0.5, 1, 1.5, 2, 2.5, 3
      meal_member_row.dart
```

---

### Feature: `settlement`

#### Domain
```
settlement/
  domain/
    entities/
      monthly_settlement.dart
      member_summary.dart    -- userId, mealCount, mealCharge, fixedShare, otherShare, totalOwed
    repo/
      settlement_repo.dart
    usecases/
      compute_monthly_settlement.dart   -- reads costs + meals, computes, saves
      get_monthly_settlement.dart
      close_settlement.dart
      get_settlement_history.dart
```

#### Data
```
  data/
    models/
      monthly_settlement_model.dart
      member_summary_model.dart
    datasources/
      settlement_remote_datasource.dart
    repo/
      settlement_repo_impl.dart
```

#### Presentation
```
  presentation/
    bloc/
      settlement_overview/     -- current month live summary
      settlement_history/      -- list of past months
      settlement_detail/       -- per-month detail with member breakdown
    screens/
      settlement_overview_screen.dart
      settlement_history_screen.dart
      settlement_detail_screen.dart
    widgets/
      member_cost_card.dart
      settlement_summary_bar.dart
      close_settlement_button.dart
```

---

## App Navigation (go_router)

```
/auth                    → Welcome / Sign In / Sign Up
/auth/login
/auth/register

/home                    → House picker (if multiple houses) OR redirect to /house/:id

/house/:id               → House Dashboard Shell
  /house/:id/costs       → Cost Feed (this month)
  /house/:id/costs/add   → Add Cost Form
  /house/:id/costs/:cid  → Cost Detail / Edit
  /house/:id/meals       → Meal Calendar
  /house/:id/meals/log   → Log Meal for Day
  /house/:id/settlement  → Settlement Overview
  /house/:id/members     → House Members
  /house/:id/settings    → House Settings (invite code, presets, categories)

/profile                 → My Profile & Settings
```

---

## Dependency Injection (BlocProvider tree)

```
MultiRepositoryProvider (app-level, via main.dart)
  ├── SupabaseClient (from supabase_flutter)
  ├── AuthRepo
  ├── HouseRepo
  ├── CostRepo
  ├── MealRepo
  └── SettlementRepo
    ↓ injected into use cases
    ↓ use cases injected into Blocs via BlocProvider in router
```

---

## New Dependencies to Add

| Package | Purpose |
|---|---|
| `supabase_flutter` | ✅ Already present |
| `flutter_bloc` | ✅ Already present |
| `freezed_annotation` + `freezed` | ✅ Already present |
| `go_router` | ✅ Already present |
| `flutter_secure_storage` | ✅ Already present (for local PIN layer) |
| `table_calendar` | Meal calendar UI |
| `intl` | Date/number formatting |
| `fl_chart` | Settlement charts (optional) |
| `cached_network_image` | Avatar images (future) |
| `image_picker` | Image uploads (future scope) |

---

## Phased Execution Plan

### Phase 1 — Foundation & Auth Migration
1. Update `pubspec.yaml` with new dependencies
2. Create Supabase project, run schema migrations, enable RLS and realtime
3. Adapt `auth` feature:
   - New `SupabaseAuthDatasource` replacing `AuthStorage`
   - Extend `Account` entity with Supabase fields
   - New sign-up/sign-in screens (email + password)
   - Update `AuthRepo` interface and `AuthRepoImpl`
   - Update `main.dart` to initialize Supabase

### Phase 2 — House Feature
4. Build `house` feature (domain → data → presentation)
5. Add house routes to `app_router.dart`
6. House dashboard shell with bottom nav

### Phase 3 — Costs Feature
7. Build `costs` feature (domain → data → presentation)
8. Cost feed + form screens with preset picker
9. Category + preset management screen

### Phase 4 — Meals Feature
10. Build `meals` feature
11. Calendar screen + meal log form
12. Meal summary per member

### Phase 5 — Settlement Feature
13. Build `settlement` feature
14. Settlement overview, history, detail
15. Monthly computation logic (pure Dart, triggered on demand)

### Phase 6 — Polish
16. Realtime subscriptions (costs + meals live sync)
17. Theme + dark mode
18. Error states, empty states, loading skeletons
19. Monthly report PDF/share (stretch goal)

---

## Verification Plan

### Automated
- Unit tests for settlement computation logic (pure Dart, no Flutter deps)
- Widget tests for meal counter input component
- Run `dart analyze` and `flutter test` after each phase

### Manual
- Create two accounts, join the same house via invite code
- Add shared and personal costs from both accounts
- Log meals for multiple days
- Trigger settlement compute and verify math manually
- Test realtime: cost added on device A appears instantly on device B

---

## Notes on Existing Codebase

| Area | Decision |
|---|---|
| `core/async_handlers/` (AsyncRequest, RepoResponse) | ✅ Keep as-is — clean pattern, reuse everywhere |
| `core/usecases/base_usecase.dart` | ✅ Keep — all new use cases extend these interfaces |
| `core/error_handler/` | ✅ Keep — reuse `asyncTryCatch` in all new repos |
| `app/bloc/auth_guard/` | **Modify** — adapt to watch Supabase auth stream |
| `app/bloc/dashboard/` | **Modify** — scope to a house context |
| `app/routing/app_router.dart` | **Extend** — add new routes |
| `features/auth/data/datasources/auth_storage.dart` | **Replace** with `SupabaseAuthDatasource` |
| Local PIN auth (auth_manager, secure_storage) | **Keep** as optional screen-lock UX layer |
