# Aanda — Business Requirements Document (BRD)

**Version:** 2.0 — September 2026  
**Platform:** Android · Web (Responsive)  
**Stack:** Flutter · BLoC · Supabase (PostgreSQL + Deno Edge Functions)  
**Last Updated:** September 2026

---

## 1. Product Vision

**Aanda** is an all-in-one shared-living financial ledger and personal expense manager tailored for flat/mess culture. It eliminates the manual friction and social awkwardness of communal living finances:
- Real-time tracking of who paid what and when
- Meal count tracking per member (breakfast, lunch, dinner) to fairly compute food costs
- Splitting fixed living expenses (rent, utility bills, internet) equally or via custom split ratios
- Flexible, date-range based automatic settlement calculations with advance deposit deductions and carry-forward balances
- Dedicated **Personal Expense Ledger** for each user to track private spending completely isolated from shared house ledgers

---

## 2. Users & Identity

### Authentication & Profiles
- **Authentication:** Supabase Auth with email and password.
- **Auto-Provisioning:** Upon email confirmation, a database trigger automatically generates:
  1. A public `profiles` record (username, full name, avatar).
  2. A default **Personal Expense Account** with the user as admin.
- **Demographics:** Optional user demographics including country, gender, and age range for profile completion.
- **Avatars:** Profile avatar upload backed by Supabase Storage (`avatars` bucket).

### Multi-Account Context & Account Switcher
Users can seamlessly switch context between:
1. **Personal Account:** Private ledger entries, isolated from any roommates.
2. **One or More Shared Houses:** Flats, mess homes, or project sprint accounts.
- Switching is done via a bottom-sheet account switcher showing account avatars and roles.

---

## 3. Expense Accounts (Houses)

### Creation & Membership
- Any authenticated user can create an expense account (house).
- Properties: Name, Currency (default `BDT`), Recurrence model (`monthly`, `weekly`, `dynamic`), House Avatar, 8-character uppercase Invite Code.
- Creator is automatically assigned the `admin` role.

### Roles & Permissions
| Role | Capabilities |
|---|---|
| **Admin (Manager)** | Full management: invite codes, category setup, custom split ratios, settlements, deposits recording, member administration. |
| **Member** | Add cost entries, record own meals, view settlement reports, view deposit history and house ledger. |

### Joining an Account
- **Invite Code:** Admin shares the 8-character unique code; new members enter it to join instantly.
- **Direct Search / Invite:** Admin can add members by username/email.

---

## 4. Cost Logging & Presets

### Entry Flexibility (Floating Costs)
- Expenses are **free-floating** — members do not need to open a cycle or wait for admin approval to log costs as they occur.
- Every cost record specifies:
  - `amount`: Monetary value.
  - `cost_scope`: `personal` (private) or `shared` (split with house members).
  - `cost_type`: `fixed` (rent, Wi-Fi) or `variable` (groceries, snacks, supplies).
  - `category_id`: Classified under a specific category.
  - `paid_by`: Who paid (defaults to current user; admin can log on behalf of any member).
  - `purchase_date`: Actual date the purchase occurred.
  - `note`: Optional description or receipt details.

### Category Presets
Standard variable presets pre-seeded for every house:
1. **Food & Dining** (`is_food: true`, pools into meal rate)
2. **Groceries & Bazar** (`is_food: true`, pools into meal rate)
3. **Snacks & Tea** (`is_food: false`, variable, split equally)
4. **Household Supplies** (`is_food: false`, variable, split equally)
5. **Transport & Travel** (`is_food: false`, variable, split equally)

---

## 5. Meal Tracking

### Logging Mechanics
- Each member has breakfast, lunch, and dinner entries per day.
- Unit increments allow fractional meals (e.g. `0.5`, `1.0`, `1.5`, `2.0`).
- Meal weights (e.g. Breakfast = 1.0, Lunch = 1.0, Dinner = 1.0) can be configured to weight hearty meals differently if required.

### Dual-View Interface
1. **Daily View:** A full matrix/table for the active day displaying all house members with quick stepper buttons for rapid breakfast/lunch/dinner increments.
2. **Member View:** Deep-dive into a single member's meal history over the calendar month.

---

## 6. Dynamic Settlements & Deposits

### Flexible Date-Range Settlements
Settlements are decoupled from calendar months. A house manager can generate a settlement for any selected period (e.g. bi-weekly, sprint, or full month).

### 4-Phase Settlement Stepper
1. **Phase 1 (Date Range):** Select `from_date` and `to_date`.
2. **Phase 2 (Cost Selection):** Filter and select unsettled shared costs to be included in this specific settlement run.
3. **Phase 3 (Summary & Breakdown):** The system calculates:
   - Shared food pool $\div$ total weighted meals $\rightarrow$ **Meal Rate**
   - Individual member meal charges
   - Individual member shares of fixed and non-food variable costs
   - Net balance: $(\text{Paid} + \text{Advance Deposits}) - (\text{Total Owed} - \text{Carry In})$
4. **Phase 4 (Resolutions & Finalisation):** Admin decides per member whether residual balance is cleared (`settle`), rolled forward (`carry_forward`), or adjusted.
   - Status updates: `draft` $\rightarrow$ `published` $\rightarrow$ `finalised`.
   - Included costs are permanently tagged with `settlement_id`.

### Deposits Ledger
Handles non-expense capital transfers:
- **Advance:** Upfront cash given to the manager before shopping (deducted from member dues during settlement).
- **Settlement Due:** Payment made by a member to clear negative settlement balance.
- **Cost Payment:** Direct reimbursement between members.
