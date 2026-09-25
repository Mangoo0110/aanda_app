# Aanda — Shared Cost & Meal Tracker: Implementation Plan

**Version:** 2.0 — September 2026  
**Stack:** Flutter · BLoC · Supabase (PostgreSQL + Deno Edge Functions) · GoRouter  
**Last Updated:** September 2026

---

## 1. Project Progress & Milestone Overview

| Phase | Milestone | Status | Description |
| :--- | :--- | :---: | :--- |
| **Phase 1** | Foundation & Supabase Cloud Auth | ✅ **Completed** | Supabase Auth migration, auto-provisioning triggers, DI bootstrapping, route guards. |
| **Phase 2** | Unified Expense Accounts & Multi-Tenancy | ✅ **Completed** | Personal & shared account unification (`expense_accounts`), account switcher sheet, invite codes. |
| **Phase 3** | Cost Management & Floating Expenses | ✅ **Completed** | Free-floating costs, personal vs shared ledger, standard category presets with storage icons. |
| **Phase 4** | Meal Tracking System | ✅ **Completed** | Dual-view UI (Daily matrix table + Member view), fractional meal steppers, meal weights. |
| **Phase 5** | Dynamic Settlement Engine (Edge Function) | ✅ **Completed** | Decoupled date-range calculations, 4-phase stepper wizard, meal rate math, draft/published/finalised lifecycle. |
| **Phase 6** | Deposits Ledger & Carry-Forward | ✅ **Completed** | `deposits` table for advances & settlement dues, rollover balance resolutions (`carry` vs `settle`). |
| **Phase 7** | Backend Edge Functions & Aggregations | ✅ **Completed** | `compute-settlement`, `close-cycle`, `dashboard`, `costs`, and `delete-account` Deno services. |
| **Phase 8** | Settlement Export & Social Sharing | 🟡 **In Progress** | PDF/CSV generation, copyable breakdown message for WhatsApp/Telegram. |
| **Phase 9** | Notifications & Reminders | ⏳ **Upcoming** | Automated meal logging nudges, settlement published push alerts. |
| **Phase 10** | Offline Caching & Polish | ⏳ **Upcoming** | Local SQLite/Hive caching for read-only offline access, optimistic meal updates. |

---

## 2. Completed Architectural Phases

### Phase 1: Foundation & Supabase Auth
- Replaced local PIN auth with cloud Supabase Auth (email + password).
- `handle_new_user()` trigger auto-creates profile rows and default Personal Expense Accounts.
- Configured centralized GoRouter with `AuthRouteGate` to manage redirect flows.

### Phase 2: Unified Expense Accounts (`expense_accounts`)
- Consolidated individual houses and personal spaces into a single multi-tenant `expense_accounts` table.
- Added fast account switcher bottom-sheet inspired by modern profile pickers.
- Implemented role-based permissions (`admin` vs `member`).

### Phase 3: Cost Management (Floating Expenses)
- Removed strict cycle requirement: expenses can be logged anytime as floating costs.
- Standard presets seeded automatically: Food & Dining, Groceries, Snacks, Household, Transport.
- Categories support `is_food` flag (routes expense into the meal rate pool) and `cost_nature` (`fixed` vs `variable`).

### Phase 4: Meal Tracking Engine
- **Daily View:** Quick-log matrix table showing all members on current date with one-tap steppers.
- **Member View:** Chronological monthly view per member.
- Weighted meal calculations ($w_b, w_l, w_d$) supporting decimal counts (`0.5`, `1.0`, `1.5`, etc.).

### Phase 5 & 6: Settlement Engine & Deposits System
- Migrated settlement logic to Deno Edge Function (`compute-settlement`).
- 4-Phase Frontend Wizard:
  1. **Date Range Phase:** Select arbitrary `from_date` and `to_date`.
  2. **Cost Selection Phase:** Toggle candidate shared costs with live sum totals.
  3. **Summary Phase:** View meal rate, per-member food/fixed/other shares, advances deducted, and net dues.
  4. **Resolution Phase:** Finalise settlement, mark costs with `settlement_id`, and resolve remaining balances (`carry_forward` vs `settle`).
- Implemented `deposits` table for tracking advances, settlement payments, and direct member reimbursements.

---

## 3. Active & Upcoming Implementation Roadmap

### Phase 8: Settlement Export & Social Sharing (Current Priority)
- [ ] Add PDF summary exporter with downloadable receipt for house records.
- [ ] Add "Share Summary" button generating a human-readable WhatsApp/Telegram message:
  ```
  🏡 House Settlement: Sept 1 - Sept 24
  🍲 Meal Rate: ৳85.40/meal
  👤 Member A: Owed ৳2,450 | Advance: ৳1,000 | Net Due: ৳1,450
  👤 Member B: Owed ৳1,800 | Paid: ৳3,000 | Refund: ৳1,200
  ```
- [ ] Add CSV export for members who keep spreadsheets.

### Phase 9: Push Notifications & House Reminders
- [ ] Daily reminder at night to log that day's meals.
- [ ] Real-time alert when a manager publishes a new settlement.
- [ ] Alert when an advance deposit is recorded by an admin.

### Phase 10: Performance, Optimizations & Offline Caching
- [ ] Optimistic updates in BLoC for instant meal stepper feedback.
- [ ] Offline caching of dashboard summary and member lists.
- [ ] Comprehensive integration testing for edge-case calculations (zero meals, all fixed costs, negative net balances).
