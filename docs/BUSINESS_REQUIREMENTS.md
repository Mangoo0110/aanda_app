# Aanda — Business Requirements Document (BRD)
**Version:** 0.1 — September 2026  
**Platform:** Android  
**Stack:** Flutter · BLoC · Supabase (PostgreSQL)

---

## 1. Product Vision

**Aanda** is a shared-living management app designed for South Asian mess/flat culture. It solves the monthly headache of:
- Tracking who bought what and how much
- Counting meals per person to fairly calculate food costs
- Splitting fixed costs (rent, bills) among members with optional custom ratios
- Doing the end-of-month settlement math automatically

A user can also track **personal expenses** that have nothing to do with the house — making Aanda a complete personal + shared ledger.

---

## 2. Users & Identity

### Authentication
- **Sign-up / Login:** Supabase Auth with **email + password**
- A user has a **profile**: username (unique), full name, avatar (future)
- App name: **Aanda**

### User Context
A user can:
1. Be a member of **one or more houses** (e.g., two flats, or past + present)
2. Track **personal expenses** — when adding any cost, the user chooses the **scope**: either `personal` or one of their shared houses. Personal costs are tied to the user profile and are never split with anyone.

---

## 3. House (Shared Living Unit)

### Creation
- Any authenticated user can create a house
- House has: **name**, **currency** (chosen at creation), **billing cycle type** (weekly / monthly / dynamic), **invite code**
- Creator automatically becomes the **admin**

### Membership
| Role | Capabilities |
|------|-------------|
| **Admin** | Full access: manage members, categories, presets, settings, close cycles, override meal logs |
| **Member** | Add own cost entries, log own meals, view house data |

### Joining a House
Two methods (both supported):
1. **Invite code** — Admin shares an 8-character code; member enters it to request join
2. **Admin adds by username/email** — Admin searches and directly adds a member

### House Settings (Admin-only)
- Change billing cycle type
- Set house currency
- Manage cost categories (labels)
- Manage split ratios per category
- Regenerate invite code
- Post/manage notes/announcements

---

## 4. Billing Cycle

### Cycle Types
| Type | Behavior |
|------|----------|
| **Monthly** | Default. Runs from a configurable start date (e.g., 1st of month) to end date (last day) |
| **Weekly** | 7-day cycles |
| **Dynamic** | Admin defines custom start and end date for each cycle |

### Cycle Mechanics
- Each cycle has a **start date**, **end date**, and **status**: `open` or `closed`
- All cost entries reference a cycle (via foreign key)
- When a new cycle starts, the previous one is still accessible as history
- Admin can change the cycle type for the **current or future** cycle from settings

---

## 5. Cost Entries

### Who Can Add
- Any member can add a cost entry for themselves (as payer)
- Admin can add a cost entry and **specify any member as the payer**

### Cost Entry Fields
| Field | Details |
|-------|---------|
| `amount` | Actual money spent (numeric) |
| `label / category` | Required — e.g., "Grocery", "Rent", "Electricity" |
| `cost_type` | `fixed` or `variable` |
| `cost_scope` | `personal` or `shared` |
| `paid_by` | Who paid — defaults to current user; admin can override |
| `purchase_date` | When the money was spent (user sets this) |
| `cycle_id` | Foreign key to the current running cycle |
| `created_at` | Auto-generated timestamp |
| `note` | Optional free-text description |

### Cost Types
| Type | Meaning | Examples |
|------|---------|---------|
| `fixed` | Same amount every cycle | Rent, Internet |
| `variable` | One-off, varies | Groceries, medicine |

### Cost Scope
| Scope | Meaning |
|-------|---------|
| `shared` | Split among house members per the category's split rule |
| `personal` | Only counted against the individual who paid — does NOT affect others |

### Labels / Categories
- House-wide, managed by admin
- Each category has: name, icon, `is_food` flag (used in meal rate calculation), cost_type hint
- A label is **required** when adding a cost entry
- If a label doesn't exist yet, the user is prompted to create one after saving the entry (or via the 3-dot menu on a cost tile)

### Presets
- A preset saves a common cost template: label + cost_type + optional fixed amount
- After adding a cost, if that combination (label + cost_type + optional amount) is not already a preset, the app offers to save it as one
- Can also be created/managed via the 3-dot menu on any cost tile
- Presets are house-wide

### No Planned/Pending State
- Costs are entered as **actual spent money** — no draft/pending state

### No Recurring Auto-Add
- Admin manually enters fixed costs (like rent) each cycle by hand
- Presets make this fast (one-tap fill from preset)

---

## 6. Cost Splitting Rules

### Fixed Shared Costs (e.g., Rent, Internet)
- **Default:** Split equally among all active members of the cycle
- **Override:** Admin can set a **split ratio per category** (e.g., Rent → 40% A, 30% B, 30% C)
- Split ratio is set at the **category level** and applies to all costs in that category

### Variable Food/Grocery Costs (`is_food = true`)
- Pooled together → calculate **Meal Rate**
- Each member's food charge = their total meal count × meal rate

### Variable Non-Food Shared Costs
- Split equally among members (same as fixed, unless category has a custom ratio)

### Personal Costs
- Not split — only counted against the payer
- Excluded from settlement calculations for other members

---

## 7. Meal Management

### Logging
- Each member logs their own meals **per day**, **per meal type**
- **Admin can override/correct** any member's meal entry
- 3 meal types per day: **Breakfast**, **Lunch**, **Dinner**
- Each value is a **free numeric input** (e.g., 0, 0.5, 1, 1.5, 2, 3) — not constrained to a fixed set

### Meal Weights
- **Default:** Breakfast = 1, Lunch = 1, Dinner = 1 (all equal)
- Admin can configure **custom meal weights per billing cycle** (not a fixed house setting — can change each cycle)
- Stored as part of the cycle record: `breakfast_weight`, `lunch_weight`, `dinner_weight`
- Changes to weights apply to the cycle they are set in; past cycles retain their own weights

### Meal Rate Calculation
```
Total Food Cost    = sum of all shared variable costs where category.is_food = true, in the cycle
Total Meal Count   = sum of (breakfast × weight + lunch × weight + dinner × weight) for ALL members in cycle
Meal Rate          = Total Food Cost / Total Meal Count
Member Food Charge = member's total weighted meal count × Meal Rate
```

### Meal View
- **Spreadsheet / Table view:** Members as rows, dates as columns
- Shows breakfast / lunch / dinner per cell
- Tap a cell to log/edit that day's meals for yourself (admin can tap any member's cell)

---

## 8. Settlement

### Trigger
- Admin manually triggers **"Compute Settlement"** when ready to close a cycle
- Any member can **preview** the settlement at any time without closing

### Settlement Report — What It Shows
| Section | Details |
|---------|---------|
| **Meal Summary** | Total meals per member (breakfast + lunch + dinner) |
| **Meal Rate** | Food cost ÷ total meal count |
| **Food Charge per Member** | meals × meal rate |
| **Fixed Cost per Member** | Each member's share of fixed shared costs |
| **Other Variable per Member** | Each member's share of non-food variable shared costs |
| **Total Owed per Member** | Sum of all charges |
| **Payer Ledger** | Who paid which cost, and total each person contributed |
| **Net Balance per Member** | Total owed − total paid = net amount they owe (positive) or are owed back (negative) |
| **Carry-Forward Balance** | Balance from previous cycle, if any |
| **Final Balance** | Net balance + carry-forward |
| **History** | All past closed cycles accessible |

### Carry-Forward
- When closing a cycle, admin sees each member's net balance
- Per member, admin chooses:
  - **Carry forward** — balance transfers to next cycle's opening balance
  - **Write off / Settled** — balance cleared (member paid in cash / resolved offline)
- This is a per-member decision at close time, not automatic

### Settlement Closure
- Once admin closes a cycle: it's locked (read-only)
- A new open cycle begins with the carry-forward balances applied

---

## 9. House Ledger (Cost Entries Feed)

This is the main tab for cost tracking — renamed from "Buy List" for clarity.

- Lists all cost entries for the **current open cycle**
- Filterable by: scope (personal / shared), type (fixed / variable), category, member
- Each tile shows: amount, label, payer, date, type badge
- **3-dot menu** per tile: Edit, Delete, Save as Preset (if not already one)
- Members see all shared costs + their own personal costs
- Members **cannot** see other members' personal costs
- Admin sees everything

---

## 10. Notes / Announcements

- Simple pinned text notes on the house dashboard
- Admin posts and manages notes
- Members can read
- Not a chat — just a notice board
- **Future scope:** real-time chat, image uploads

---

## 11. Dashboard (Home Screen)

Quick summary for the current cycle:
- My net balance (what I owe or am owed)
- Total shared costs this cycle
- My total meal count this cycle
- Recent cost entries
- Quick-add button for cost entry and meal log

---

## 12. Personal Expense Tracking

- When adding a cost entry, the user always **chooses the scope first**:
  - **Personal** — linked only to their profile, no house
  - **A specific house** — enters into that house's shared ledger
- Personal costs appear in the user's own "My Expenses" view
- Not part of any house settlement — purely for the user's own records
- A user with no house membership can still use the app purely as a personal expense tracker

---

## 13. Data Visibility Rules

| Data | Who Can See |
|------|------------|
| Shared costs | All house members |
| Personal costs | Only the owner (and admin within the house context) |
| Other members' personal costs | Admin only |
| Meal logs | All members (it's a collective table) |
| Settlement report | All members (preview); finalized by admin |
| House settings | Admin only |
| Invite code | Admin only |

---

## 14. Future Scope (Not v1)

- Real-time chat per house
- Receipt image upload (attached to cost entry)
- Push notifications (new cost added, settlement ready)
- PDF/Share settlement report
- Personal budgeting features
- iOS support
- Monetization (freemium model TBD)

---

## 15. Technical Decisions

| Decision | Choice |
|----------|--------|
| Auth | Supabase Auth — email + password |
| Database | PostgreSQL via Supabase |
| Offline support | Online-only for v1 (Supabase does not buffer writes offline natively) |
| Realtime sync | Supabase Realtime on cost entries and meal logs |
| Platform | Android only (v1) |
| Theme | Light + Dark (follows system) |
| Currency | Chosen per house at creation; all costs in house currency |
| Monetization | Free (v1) |
