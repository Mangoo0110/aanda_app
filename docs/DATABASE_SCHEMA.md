# Aanda — Database Architecture & Schema Specification

**Platform:** Supabase / PostgreSQL 15+  
**Repository:** [aanda_app_supabase](https://github.com/Mangoo0110/aanda_app_supabase.git)  
**Schema Path:** `supabase/migrations/`

---

## 1. Overview & Entity Relationship Model

Aanda uses a relational PostgreSQL database with Row Level Security (RLS) enforcing multi-tenant isolation per house and per user.

```
[auth.users] (Supabase Auth)
     │ 1:1
     ▼
 [profiles] ─────────────┐
     │ 1:N               │ 1:N
     ▼                   ▼
 [house_members] ───► [houses]
     │                   │
     │ 1:N               │ 1:N
     ├───────────────────┼────────────────────────┐
     ▼                   ▼                        ▼
 [meal_logs]     [billing_cycles]         [cost_categories]
                         │                        │
                         │ 1:N                    │ 1:N
                         ▼                        ▼
                   [settlements]              [cost_presets]
                         │                        │
                         │ 1:N                    │ 1:N
                         ▼                        ▼
             [carry_forward_balances]         [costs]
```

---

## 2. PostgreSQL Extensions

- `pgcrypto`: cryptographic functions and UUID generation.
- `uuid-ossp`: UUID v4 generation for primary keys (`uuid_generate_v4()`).

---

## 3. Custom Domain Enums

| Type | Allowed Values | Usage |
|---|---|---|
| `house_role` | `admin`, `member` | Role within a shared house |
| `cost_scope` | `personal`, `shared` | Whether expense is private or shared |
| `cost_type` | `fixed`, `variable` | Rent/Internet vs Groceries/One-offs |
| `billing_status` | `active`, `calculating`, `closed` | Lifecycle of a billing cycle |
| `settlement_decision` | `pending`, `carry_forward`, `settled` | Action taken at cycle closure |

---

## 4. Tables Specification

### 4.1 `profiles`
Extends `auth.users`. Automatically populated via trigger `on_auth_user_created`.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, References `auth.users(id)` ON DELETE CASCADE | User ID |
| `username` | `text` | UNIQUE, NOT NULL | Unique display handle |
| `full_name` | `text` | Nullable | Full real name |
| `avatar_url` | `text` | Nullable | Avatar image storage path |
| `created_at` | `timestamptz` | DEFAULT `now()` | Registration timestamp |
| `updated_at` | `timestamptz` | DEFAULT `now()` | Profile last updated |

### 4.2 `houses`
Represents shared living units (mess, flat, shared apartment).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `uuid_generate_v4()` | House ID |
| `name` | `text` | NOT NULL | Flat/House name |
| `currency` | `text` | NOT NULL DEFAULT `BDT` | ISO currency code (BDT, INR, USD, etc.) |
| `cycle_type` | `text` | NOT NULL DEFAULT `monthly` | `monthly`, `weekly`, or `dynamic` |
| `invite_code` | `text` | UNIQUE, NOT NULL | 8-character uppercase code |
| `created_by` | `uuid` | References `profiles(id)` | House founder |
| `created_at` | `timestamptz` | DEFAULT `now()` | Creation timestamp |

### 4.3 `house_members`
Junction table linking profiles to houses.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `uuid_generate_v4()` | Membership ID |
| `house_id` | `uuid` | References `houses(id)` ON DELETE CASCADE | House reference |
| `user_id` | `uuid` | References `profiles(id)` ON DELETE CASCADE | User reference |
| `role` | `house_role` | NOT NULL DEFAULT `member` | `admin` or `member` |
| `joined_at` | `timestamptz` | DEFAULT `now()` | Join timestamp |
| `is_active` | `boolean` | NOT NULL DEFAULT `true` | Soft-deactivation flag |

*Unique constraint:* `(house_id, user_id)`

### 4.4 `billing_cycles`
Tracks accounting cycles. Cycles can have custom meal weights.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `uuid_generate_v4()` | Cycle ID |
| `house_id` | `uuid` | References `houses(id)` ON DELETE CASCADE | House reference |
| `name` | `text` | NOT NULL | Display name (e.g. "September 2026") |
| `start_date` | `date` | NOT NULL | Cycle start date |
| `end_date` | `date` | NOT NULL | Cycle end date |
| `status` | `billing_status` | DEFAULT `active` | `active`, `calculating`, `closed` |
| `breakfast_weight` | `numeric(4,2)` | NOT NULL DEFAULT 1.0 | Weight multiplier for breakfast |
| `lunch_weight` | `numeric(4,2)` | NOT NULL DEFAULT 1.0 | Weight multiplier for lunch |
| `dinner_weight` | `numeric(4,2)` | NOT NULL DEFAULT 1.0 | Weight multiplier for dinner |
| `created_at` | `timestamptz` | DEFAULT `now()` | Creation timestamp |
| `closed_at` | `timestamptz` | Nullable | Closure timestamp |

### 4.5 `cost_categories`
Custom categories defined per house.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `uuid_generate_v4()` | Category ID |
| `house_id` | `uuid` | References `houses(id)` ON DELETE CASCADE | House reference |
| `name` | `text` | NOT NULL | Category name (Groceries, Rent, Wifi) |
| `icon` | `text` | NOT NULL DEFAULT `category` | Icon identifier for UI |
| `is_food` | `boolean` | NOT NULL DEFAULT `false` | True if included in meal rate pool |
| `default_type` | `cost_type` | NOT NULL DEFAULT `variable` | Default cost type suggestion |
| `split_ratios` | `jsonb` | Nullable | Optional custom split ratios per user |
| `created_at` | `timestamptz` | DEFAULT `now()` | Timestamp |

### 4.6 `cost_presets`
Quick-fill templates for frequent expenses.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `uuid_generate_v4()` | Preset ID |
| `house_id` | `uuid` | References `houses(id)` ON DELETE CASCADE | House reference |
| `category_id` | `uuid` | References `cost_categories(id)` ON DELETE CASCADE | Category reference |
| `name` | `text` | NOT NULL | Preset title (e.g. "Monthly Wifi") |
| `default_amount` | `numeric(12,2)` | Nullable | Suggested default amount |
| `cost_type` | `cost_type` | NOT NULL DEFAULT `fixed` | Fixed vs variable |
| `created_at` | `timestamptz` | DEFAULT `now()` | Timestamp |

### 4.7 `costs`
Ledger of all money spent.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `uuid_generate_v4()` | Entry ID |
| `house_id` | `uuid` | Nullable, References `houses(id)` ON DELETE CASCADE | Nullable if personal scope |
| `cycle_id` | `uuid` | Nullable, References `billing_cycles(id)` | Linked billing cycle |
| `category_id` | `uuid` | Nullable, References `cost_categories(id)` | Category |
| `paid_by` | `uuid` | NOT NULL References `profiles(id)` | Who paid |
| `amount` | `numeric(12,2)` | NOT NULL CHECK (`amount > 0`) | Amount spent |
| `cost_scope` | `cost_scope` | NOT NULL DEFAULT `shared` | `personal` or `shared` |
| `cost_type` | `cost_type` | NOT NULL DEFAULT `variable` | `fixed` or `variable` |
| `purchase_date` | `date` | NOT NULL DEFAULT `CURRENT_DATE` | Date spent |
| `note` | `text` | Nullable | Notes/memo |
| `created_at` | `timestamptz` | DEFAULT `now()` | Creation timestamp |

### 4.8 `meal_logs`
Daily meal tracking entries. Allows double / fractional meal counts (0.25, 0.5, 1, 1.5, 2, etc.).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `uuid_generate_v4()` | Entry ID |
| `house_id` | `uuid` | References `houses(id)` ON DELETE CASCADE | House |
| `cycle_id` | `uuid` | References `billing_cycles(id)` ON DELETE CASCADE | Cycle |
| `user_id` | `uuid` | References `profiles(id)` ON DELETE CASCADE | Member |
| `date` | `date` | NOT NULL | Meal date |
| `breakfast` | `numeric(4,2)` | NOT NULL DEFAULT 0.0 CHECK (`>= 0`) | Breakfast count |
| `lunch` | `numeric(4,2)` | NOT NULL DEFAULT 0.0 CHECK (`>= 0`) | Lunch count |
| `dinner` | `numeric(4,2)` | NOT NULL DEFAULT 0.0 CHECK (`>= 0`) | Dinner count |
| `logged_by` | `uuid` | References `profiles(id)` | User who recorded entry |
| `created_at` | `timestamptz` | DEFAULT `now()` | Creation timestamp |

*Unique constraint:* `(house_id, cycle_id, user_id, date)`

### 4.9 `settlements`
Snapshot of computed month-end numbers.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `uuid_generate_v4()` | Settlement ID |
| `cycle_id` | `uuid` | UNIQUE References `billing_cycles(id)` ON DELETE CASCADE | Cycle |
| `house_id` | `uuid` | References `houses(id)` ON DELETE CASCADE | House |
| `total_food_cost` | `numeric(12,2)` | NOT NULL DEFAULT 0 | Sum of shared food expenses |
| `total_fixed_cost` | `numeric(12,2)` | NOT NULL DEFAULT 0 | Sum of shared fixed expenses |
| `total_other_cost` | `numeric(12,2)` | NOT NULL DEFAULT 0 | Sum of shared other variable |
| `total_meal_count` | `numeric(8,2)` | NOT NULL DEFAULT 0 | Sum of all weighted meals |
| `meal_rate` | `numeric(10,4)` | NOT NULL DEFAULT 0 | `total_food_cost / total_meal_count` |
| `member_summaries` | `jsonb` | NOT NULL DEFAULT `[]` | Array of per-member calculations |
| `computed_at` | `timestamptz` | DEFAULT `now()` | Computation timestamp |
| `computed_by` | `uuid` | References `profiles(id)` | Admin who ran settlement |

### 4.10 `carry_forward_balances`
Rollover balances applied from a closed cycle to the next active cycle.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `uuid_generate_v4()` | Record ID |
| `house_id` | `uuid` | References `houses(id)` ON DELETE CASCADE | House |
| `from_cycle_id` | `uuid` | References `billing_cycles(id)` | Closed cycle source |
| `to_cycle_id` | `uuid` | Nullable References `billing_cycles(id)` | Destination cycle |
| `user_id` | `uuid` | References `profiles(id)` | Member |
| `amount` | `numeric(12,2)` | NOT NULL | Positive = owes; Negative = owed |
| `status` | `settlement_decision` | DEFAULT `pending` | `pending`, `carry_forward`, `settled` |
| `created_at` | `timestamptz` | DEFAULT `now()` | Creation timestamp |

### 4.11 `house_notes`
Shared announcement board.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `uuid_generate_v4()` | Note ID |
| `house_id` | `uuid` | References `houses(id)` ON DELETE CASCADE | House |
| `author_id` | `uuid` | References `profiles(id)` | Poster |
| `title` | `text` | NOT NULL | Note title |
| `content` | `text` | NOT NULL | Note body |
| `is_pinned` | `boolean` | DEFAULT `false` | Pinned priority |
| `created_at` | `timestamptz` | DEFAULT `now()` | Creation timestamp |

---

## 5. Row-Level Security (RLS) Policies

Every table has RLS enabled with granular access rules:
- **Helper Functions:**
  - `public.is_house_member(p_house_id)`: returns true if `auth.uid()` has active membership in `p_house_id`.
  - `public.is_house_admin(p_house_id)`: returns true if `auth.uid()` is active admin in `p_house_id`.
- **Costs:**
  - Users can read all shared costs in their houses, plus their own personal costs.
  - Members can insert costs where `paid_by = auth.uid()`.
  - House Admins can insert costs on behalf of any member.
- **Meal Logs:**
  - Any member can view all meal logs in their house.
  - Members can insert/update their own meal logs.
  - House Admins can update/correct any member meal log.

---

## 6. Edge Functions

### `compute-settlement`
- Endpoint: `/functions/v1/compute-settlement`
- Method: `POST`
- Body: `{ "cycle_id": "uuid" }`
- Calculates food totals, fixed totals, weighted meal count, meal rate, member food charges, fixed splits, net balances, and upserts the `settlements` record.

### `close-cycle`
- Endpoint: `/functions/v1/close-cycle`
- Method: `POST`
- Body: `{ "cycle_id": "uuid", "carry_forward_decisions": [{ "user_id": "uuid", "decision": "carry_forward" | "settled" }] }`
- Records carry forward balances, locks the billing cycle as `closed`.
