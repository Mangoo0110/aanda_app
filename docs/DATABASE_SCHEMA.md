# Aanda — Database Schema Specification

> **Version**: 2.1 (Migration 027)  
> **Backend**: Supabase (PostgreSQL 15+)  
> **Status**: Development / Pre-release

---

## 1. Entity-Relationship Overview

```
 [profiles] ──────────────────────────┐
     │ 1:N                            │ 1:N
     ▼                                ▼
 [expense_account_members] ───► [expense_accounts] (Houses / Personal)
     │                                │
     │ 1:N                            │ 1:N
     ├────────────────────────────────┼──────────────────────────────┐
     ▼                                ▼                              ▼
 [meal_logs]                  [settlements]                  [cost_categories]
                                      │                              │
                                      │ 1:N                          │ 1:N
                                      ├──────────────┐               ▼
                                      ▼              ▼            [costs]
                                  [deposits]      [costs]
                                  (advance /      (free-floating /
                                  settlement_due) cycle-linked)

 [category_emojis] (Global Preset Catalog with 15 standard presets)
```

---

## 2. PostgreSQL Extensions

- `pgcrypto`: Cryptographic hashing and UUID generation.
- `uuid-ossp`: UUID v4 generation for primary keys (`uuid_generate_v4()`).

---

## 3. Custom Domain Enums & Types

| Type | Allowed Values | Usage |
|---|---|---|
| `member_role` | `admin`, `member` | Role within a shared expense account |
| `cost_scope` | `personal`, `shared` | Scope of the cost entry |
| `cost_type` | `fixed`, `variable` | Cost classification (e.g. rent vs groceries) |
| `cycle_type` | `weekly`, `monthly`, `dynamic` | Billing cycle recurrence style |
| `cycle_status` | `open`, `closed` | Status of sprint / billing cycle |
| `account_type` | `personal`, `shared` | Account classification |
| `deposit_type` | `advance`, `settlement_due`, `adjustment` | Classification of payments and deposits |

---

## 4. Tables Specification

### 4.1 `profiles`
Extends `auth.users`. Automatically populated via trigger `handle_new_user` on auth signup / confirmation.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, References `auth.users(id)` ON DELETE CASCADE | User ID |
| `username` | `text` | UNIQUE, NOT NULL | Unique display handle |
| `full_name` | `text` | Nullable | Full name |
| `avatar_url` | `text` | Nullable | Storage URL in `avatars` bucket |
| `country` | `text` | Nullable | User country |
| `gender` | `text` | Nullable | User gender |
| `age_range` | `text` | Nullable | Age demographic bracket |
| `is_onboarded` | `boolean` | NOT NULL DEFAULT `false` | Onboarding completion flag |
| `created_at` | `timestamptz` | DEFAULT `now()` | Registration timestamp |
| `updated_at` | `timestamptz` | DEFAULT `now()` | Profile last updated |

---

### 4.2 `expense_accounts` (formerly `houses`)
Represents shared living units (mess, flat, shared apartment) as well as personal ledger accounts.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `gen_random_uuid()` | Account ID |
| `name` | `text` | NOT NULL | Account or house display name |
| `currency` | `text` | NOT NULL DEFAULT `'BDT'` | ISO currency code (BDT, INR, USD, etc.) |
| `cycle_type` | `cycle_type` | NOT NULL DEFAULT `'monthly'` | Recurrence model |
| `account_type` | `account_type` | NOT NULL DEFAULT `'shared'` | `'personal'` or `'shared'` |
| `invite_code` | `text` | UNIQUE, NOT NULL | 8-character uppercase invite code |
| `created_by` | `uuid` | References `profiles(id)` | Account creator |
| `avatar_url` | `text` | Nullable | Storage URL in `avatars` bucket for house logo |
| `created_at` | `timestamptz` | DEFAULT `now()` | Creation timestamp |
| `updated_at` | `timestamptz` | DEFAULT `now()` | Last updated timestamp |

---

### 4.3 `expense_account_members` (formerly `house_members`)
Junction table linking profiles to expense accounts.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `gen_random_uuid()` | Membership ID |
| `expense_account_id` | `uuid` | References `expense_accounts(id)` ON DELETE CASCADE | Account reference |
| `user_id` | `uuid` | References `profiles(id)` ON DELETE CASCADE | User reference |
| `role` | `member_role` | NOT NULL DEFAULT `'member'` | `'admin'` or `'member'` |
| `joined_at` | `timestamptz` | DEFAULT `now()` | Join timestamp |

*Unique constraint:* `(expense_account_id, user_id)`

---

### 4.4 `costs`
Stores all expense entries (personal and shared). Costs can float freely or be linked to a `cycle_id`. When scope is `shared`, `expense_account_id` is required; for `personal` scope, `expense_account_id` is null.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `gen_random_uuid()` | Cost entry ID |
| `expense_account_id` | `uuid` | Nullable, References `expense_accounts(id)` ON DELETE CASCADE | Required if shared, null if personal |
| `cycle_id` | `uuid` | Nullable, References `billing_cycles(id)` ON DELETE SET NULL | Optional cycle reference |
| `paid_by` | `uuid` | NOT NULL References `profiles(id)` | Payer user ID |
| `category_id` | `uuid` | Nullable References `cost_categories(id)` ON DELETE SET NULL | Category classification |
| `name` | `text` | NOT NULL | Description/title |
| `amount` | `numeric(14,2)` | NOT NULL, CHECK `amount > 0` | Cost amount |
| `cost_type` | `cost_type` | NOT NULL | `'fixed'` or `'variable'` |
| `cost_scope` | `cost_scope` | NOT NULL | `'personal'` or `'shared'` |
| `purchase_date`| `date` | NOT NULL DEFAULT `current_date` | Date expense occurred |
| `note` | `text` | Nullable | Optional notes |
| `created_at` | `timestamptz` | DEFAULT `now()` | Created timestamp |
| `updated_at` | `timestamptz` | DEFAULT `now()` | Updated timestamp |

*Key Indexes:*
- `costs_account_idx` ON `costs(expense_account_id)`
- `costs_cycle_idx` ON `costs(cycle_id)`
- `costs_payer_idx` ON `costs(paid_by)`
- `costs_date_idx` ON `costs(purchase_date desc)`

---

### 4.5 `category_emojis` & `cost_categories`

#### `category_emojis` (Global Preset Catalog)
Global standard presets available for selection during cost entry.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `gen_random_uuid()` | Preset ID |
| `name` | `text` | UNIQUE, NOT NULL | Category name |
| `emoji` | `text` | NOT NULL | Display emoji |
| `bg_color` | `text` | NOT NULL DEFAULT `'#3B82F6'` | Hex badge background color |
| `display_order`| `integer`| NOT NULL DEFAULT `0` | Sort order in picker |
| `is_food` | `boolean` | NOT NULL DEFAULT `false` | True if cost pools into meal rate |
| `created_at` | `timestamptz` | DEFAULT `now()` | Timestamp |

#### `cost_categories` (Account-Specific Custom Categories)
Custom categories defined per expense account.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `gen_random_uuid()` | Category ID |
| `expense_account_id` | `uuid` | References `expense_accounts(id)` ON DELETE CASCADE | Account reference |
| `name` | `text` | NOT NULL | Category name |
| `icon` | `text` | Nullable | Icon name or emoji/URL |
| `is_food` | `boolean` | NOT NULL DEFAULT `false` | If true, cost pools into meal rate |
| `created_by` | `uuid` | References `profiles(id)` | Creator |
| `created_at` | `timestamptz` | DEFAULT `now()` | Timestamp |
| `updated_at` | `timestamptz` | DEFAULT `now()` | Timestamp |

*Unique constraint:* `(expense_account_id, name)`  
*(Note: Legacy `cost_presets` table was dropped in Migration 027.)*

---

### 4.6 `billing_cycles`
Billing cycles (sprints) for tracking expenses and meals over discrete timeframes.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `gen_random_uuid()` | Cycle ID |
| `expense_account_id` | `uuid` | References `expense_accounts(id)` ON DELETE CASCADE | Account reference |
| `cycle_type` | `cycle_type` | NOT NULL DEFAULT `'monthly'` | Recurrence model |
| `status` | `cycle_status` | NOT NULL DEFAULT `'open'` | `'open'` or `'closed'` |
| `start_date` | `date` | NOT NULL | Cycle start date |
| `end_date` | `date` | Nullable | Cycle end date |
| `breakfast_weight`| `numeric(4,2)`| NOT NULL DEFAULT `1.0` | Weight for breakfast |
| `lunch_weight` | `numeric(4,2)`| NOT NULL DEFAULT `1.0` | Weight for lunch |
| `dinner_weight`| `numeric(4,2)`| NOT NULL DEFAULT `1.0` | Weight for dinner |
| `label` | `text` | Nullable | Human-readable label (e.g. "September 2026") |
| `created_by` | `uuid` | References `profiles(id)` | Creator |
| `closed_at` | `timestamptz` | Nullable | Closure timestamp |
| `created_at` | `timestamptz` | DEFAULT `now()` | Creation timestamp |
| `updated_at` | `timestamptz` | DEFAULT `now()` | Last updated timestamp |

---

### 4.7 `meal_logs`
Daily meal tallies per user per expense account.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `gen_random_uuid()` | Meal log ID |
| `expense_account_id` | `uuid` | References `expense_accounts(id)` ON DELETE CASCADE | Account reference |
| `cycle_id` | `uuid` | Nullable References `billing_cycles(id)` ON DELETE CASCADE | Optional cycle link |
| `user_id` | `uuid` | References `profiles(id)` | Member ID |
| `log_date` | `date` | NOT NULL | Date logged |
| `breakfast`| `numeric(3,1)` | NOT NULL DEFAULT 0.0, CHECK `>= 0` | Breakfast meal units |
| `lunch` | `numeric(3,1)` | NOT NULL DEFAULT 0.0, CHECK `>= 0` | Lunch meal units |
| `dinner` | `numeric(3,1)` | NOT NULL DEFAULT 0.0, CHECK `>= 0` | Dinner meal units |
| `created_at` | `timestamptz` | DEFAULT `now()` | Timestamp |
| `updated_at` | `timestamptz` | DEFAULT `now()` | Timestamp |

*Unique constraint:* `(expense_account_id, user_id, log_date)`

---

### 4.8 `settlements`
Calculated settlement records across billing cycles or dynamic date ranges.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `gen_random_uuid()` | Settlement ID |
| `expense_account_id` | `uuid` | References `expense_accounts(id)` ON DELETE CASCADE | Account reference |
| `cycle_id` | `uuid` | Nullable References `billing_cycles(id)` | Linked cycle |
| `from_date` | `date` | NOT NULL | Start date of settlement period |
| `to_date` | `date` | NOT NULL | End date of settlement period |
| `status` | `text` | NOT NULL DEFAULT `'finalised'` | `'draft'`, `'published'`, or `'finalised'` |
| `total_food_cost` | `numeric(14,2)` | NOT NULL DEFAULT 0 | Total food expenses |
| `total_fixed_cost`| `numeric(14,2)` | NOT NULL DEFAULT 0 | Total fixed expenses |
| `total_other_cost`| `numeric(14,2)` | NOT NULL DEFAULT 0 | Total non-food variable expenses |
| `total_meal_count`| `numeric(8,2)` | NOT NULL DEFAULT 0 | Sum of weighted meals for all members |
| `meal_rate` | `numeric(10,4)` | NOT NULL DEFAULT 0 | `total_food_cost / total_meal_count` |
| `member_summaries`| `jsonb` | NOT NULL DEFAULT `'[]'` | Detailed per-member JSON breakdown |
| `computed_at` | `timestamptz` | DEFAULT `now()` | Calculation timestamp |
| `created_at` | `timestamptz` | DEFAULT `now()` | Timestamp |

---

### 4.9 `deposits` (Migration 026)
Tracks capital movements outside direct cost reimbursements (advances, settlement collections, adjustments).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `gen_random_uuid()` | Deposit ID |
| `expense_account_id` | `uuid` | References `expense_accounts(id)` ON DELETE CASCADE | Account reference |
| `user_id` | `uuid` | References `profiles(id)` ON DELETE CASCADE | Member making deposit/payment |
| `settlement_id` | `uuid` | Nullable References `settlements(id)` ON DELETE CASCADE | Linked settlement (if due payment) |
| `cost_id` | `uuid` | Nullable References `costs(id)` ON DELETE SET NULL | Linked cost |
| `deposit_type` | `deposit_type` | NOT NULL DEFAULT `'advance'` | `'advance'`, `'settlement_due'`, `'adjustment'` |
| `amount` | `numeric(14,2)` | NOT NULL CHECK (`amount > 0`) | Transaction amount |
| `note` | `text` | Nullable | Reference / note |
| `deposit_date` | `date` | NOT NULL DEFAULT `current_date` | Date paid |
| `recorded_by` | `uuid` | References `profiles(id)` | User who recorded entry |
| `created_at` | `timestamptz` | DEFAULT `now()` | Timestamp |
| `updated_at` | `timestamptz` | DEFAULT `now()` | Timestamp |

---

### 4.10 `carry_forward_balances`
Tracks balances rolled forward between cycles.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `gen_random_uuid()` | Entry ID |
| `expense_account_id` | `uuid` | References `expense_accounts(id)` ON DELETE CASCADE | Account reference |
| `cycle_id` | `uuid` | References `billing_cycles(id)` ON DELETE CASCADE | Cycle reference |
| `user_id` | `uuid` | References `profiles(id)` | Member reference |
| `net_balance` | `numeric(14,2)` | NOT NULL DEFAULT `0` | Net balance carried |
| `created_at` | `timestamptz` | DEFAULT `now()` | Creation timestamp |

*Unique constraint:* `(expense_account_id, cycle_id, user_id)`

---

### 4.11 `house_notes`
Expense account bulletin board for announcements and notes.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | Primary Key, DEFAULT `gen_random_uuid()` | Note ID |
| `expense_account_id` | `uuid` | References `expense_accounts(id)` ON DELETE CASCADE | Account reference |
| `title` | `text` | NOT NULL | Note title |
| `body` | `text` | NOT NULL | Content |
| `created_by` | `uuid` | References `profiles(id)` | Author |
| `created_at` | `timestamptz` | DEFAULT `now()` | Timestamp |
| `updated_at` | `timestamptz` | DEFAULT `now()` | Timestamp |

---

## 5. PostgreSQL Security & Helper Functions

- `is_expense_account_member(p_account_id uuid)`: Returns boolean indicating if caller is an active member or creator of personal account.
- `is_expense_account_admin(p_account_id uuid)`: Returns boolean indicating if caller is an admin of the expense account.
- `is_house_member(p_house_id uuid)`: Backward-compatibility alias calling `is_expense_account_member`.
- `is_house_admin(p_house_id uuid)`: Backward-compatibility alias calling `is_expense_account_admin`.
- `handle_new_user()`: Trigger on `auth.users` insert. Automatically populates `public.profiles`.
