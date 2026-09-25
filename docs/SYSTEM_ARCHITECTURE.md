# Aanda — System Architecture & Technical Specifications

**Version:** 2.0  
**Stack:** Flutter (Dart 3.9+) · BLoC · GoRouter · Supabase (PostgreSQL 15+) · Deno TypeScript Edge Functions  
**Architecture Pattern:** Clean Architecture + Feature-First Modularization  
**Last Updated:** September 2026

---

## 1. High-Level Architecture

```
┌───────────────────────────────────────────────────────────────────────────┐
│                    Flutter Client (Android / Web)                         │
│                                                                           │
│   ┌────────────────────────────────────────────────────────────────────┐  │
│   │                         Presentation Layer                         │  │
│   │  Screens · Custom Sheets · Design Tokens · BLoC (State Management) │  │
│   └──────────────────────────────────┬─────────────────────────────────┘  │
│                                      │ calls                              │
│   ┌──────────────────────────────────▼─────────────────────────────────┐  │
│   │                            Domain Layer                            │  │
│   │            Entities · Use Cases · Repository Contracts             │  │
│   └──────────────────────────────────▲─────────────────────────────────┘  │
│                                      │ implements                         │
│   ┌──────────────────────────────────┴─────────────────────────────────┐  │
│   │                            Data Layer                              │  │
│   │       Models · Data Sources · Supabase Client REST & Realtime      │  │
│   └──────────────────────────────────┬─────────────────────────────────┘  │
└──────────────────────────────────────┼────────────────────────────────────┘
                                       │ HTTPS / WSS
                                       ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                          Supabase Backend                                 │
│                                                                           │
│   ┌──────────────────────────┐    ┌───────────────────────────────────┐   │
│   │      Supabase Auth       │    │        Deno Edge Functions        │   │
│   │    (JWT / Session)       │    │  • compute-settlement             │   │
│   └─────────────┬────────────┘    │  • close-cycle                    │   │
│                 │                 │  • dashboard                      │   │
│                 │                 │  • costs                          │   │
│                 ▼                 │  • delete-account                 │   │
│   ┌──────────────────────────┐    └─────────────────┬─────────────────┘   │
│   │     Storage Buckets      │                      │                     │
│   │   avatars, category-icons│                      │                     │
│   └─────────────┬────────────┘                      │                     │
│                 ▼                                   ▼                     │
│   ┌───────────────────────────────────────────────────────────────────┐   │
│   │                     PostgreSQL Database (RLS)                     │   │
│   │   profiles · expense_accounts · expense_account_members · costs   │   │
│   │   meal_logs · billing_cycles · settlements · deposits · notes     │   │
│   └───────────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Directory Structure & Monorepo Setup

```
project_aanda/
├── docs/                                  ← Canonical System Documentation
│   ├── BUSINESS_REQUIREMENTS.md           ← Complete BRD & Product Model
│   ├── DATABASE_SCHEMA.md                 ← Tables, RLS, Indices, Functions
│   ├── IMPLEMENTATION_PLAN.md             ← Milestones & Feature Status
│   └── SYSTEM_ARCHITECTURE.md             ← Technical Specifications
├── aanda/                                 ← Flutter Application (Git Subrepo)
│   ├── lib/
│   │   ├── main.dart                      ← Supabase init & DI bootstrap
│   │   ├── di/                            ← Dependency injection container
│   │   └── src/
│   │       ├── app/                       ← App Shell, Router, Theme tokens
│   │       │   ├── routing/               ← GoRouter configuration & guards
│   │       │   └── view/                  ← AppShellScaffold (Navigation)
│   │       ├── core/                      ← Shared infrastructure
│   │       │   ├── async_handlers/        ← AsyncRequest, RepoResponse
│   │       │   ├── shared/widget/         ← AppCard, AmountText, PageHeaders
│   │       │   └── theme/                 ← Color tokens, AppTextStyles
│   │       └── features/                  ← Modular feature packages
│   │           ├── auth/                  ← Authentication & Welcome
│   │           ├── cost/                  ← Cost creation journey, presets
│   │           ├── dashboard/             ← Summary cards, activity feeds
│   │           ├── house/                 ← Account switcher, join/create
│   │           ├── meal/                  ← Daily & member meal views
│   │           ├── profile/               ← Demographics & avatar management
│   │           └── settlement/            ← 4-phase settlement stepper & deposits
│   └── pubspec.yaml
└── db/                                    ← Supabase Backend (Git Subrepo)
    ├── supabase/
    │   ├── config.toml                    ← Supabase CLI config
    │   ├── full_schema.sql                ← Consolidated full database schema
    │   ├── seed.sql                       ← Local dev seed data
    │   ├── migrations/                    ← 26 SQL migration files
    │   └── functions/                     ← Deno TypeScript edge functions
    │       ├── _shared/                   ← CORS & response utilities
    │       ├── compute-settlement/        ← Settlement calculation engine
    │       ├── close-cycle/               ← Cycle closure & carry forwards
    │       ├── costs/                     ← Expense query & mutate API
    │       ├── dashboard/                 ← Unified summary & activity feed
    │       └── delete-account/            ← Clean user account deletion
    └── README.md
```

---

## 3. Core Principles & Coding Standards

### 3.1 Clean Architecture Rules
1. **Domain layer has zero external framework dependencies.** It contains pure Dart entities, use cases, and repository interfaces.
2. **Data layer depends on Domain.** Implements domain repository interfaces, handles JSON serialization, and communicates with Supabase (via PostgREST or Edge Functions).
3. **Presentation layer depends on Domain.** BLoCs invoke use cases and emit immutable UI states. UI widgets listen to BLoC states and dispatch events.
4. **No raw exceptions crossing boundaries.** All async repository calls return `AsyncRequest<T>` (`Future<RepoResponse<T>>`), wrapping success (`SuccessRepoCall<T>`) or failure (`FailedRepoCall<T>`).

### 3.2 State Management (flutter_bloc 9.x)
- Every feature has dedicated BLoCs (e.g. `DashboardBloc`, `HouseMealsBloc`, `SettlementBloc`, `CostCategoryFormBloc`).
- Event-driven reactive updates with `on<Event>` handlers.
- UI utilizes `BlocBuilder`, `BlocConsumer`, or `context.read<Bloc>()` for declarative rendering.

### 3.3 Routing (go_router 17.x)
- Centralized `AppRouter` with route redirection based on `AuthStatus` and active account state.
- Unauthenticated users land on `/auth/welcome` or `/auth/login`.
- Authenticated users navigate between the persistent `AppShellScaffold` tabs (`/dashboard`, `/costs`, `/meals`, `/settlement`, `/account`).

---

## 4. Business Calculation Engine

### 4.1 Meal Rate Formula
Aanda distinguishes between food-pool expenses and non-food expenses:

$$\text{Total Weighted Meals} = \sum_{m \in \text{members}} \sum_{d \in \text{dates}} (\text{breakfast}_{m,d} \times w_b + \text{lunch}_{m,d} \times w_l + \text{dinner}_{m,d} \times w_d)$$

$$\text{Meal Rate} = \frac{\text{Total Shared Food Costs}}{\text{Total Weighted Meals}}$$

$$\text{Member Food Cost}_m = \text{Member Weighted Meals}_m \times \text{Meal Rate}$$

### 4.2 Dynamic Settlement Computation Engine (`compute-settlement`)
Settlements in Aanda are decoupled from strict calendar limits and are run for arbitrary date windows $[T_{\text{from}}, T_{\text{to}}]$ across an explicit list of included costs:

1. **Cost Partitioning:**
   - **Shared Food Costs ($C_{\text{food}}$):** Costs where `cost_scope = 'shared'` and `category.is_food = true`.
   - **Shared Fixed Costs ($C_{\text{fixed}}$):** Costs where `cost_scope = 'shared'` and `cost_type = 'fixed'`.
   - **Shared Other Variable Costs ($C_{\text{other}}$):** Costs where `cost_scope = 'shared'`, `cost_type = 'variable'`, and `category.is_food = false`.

2. **Per-Member Allocation:**
   - **Fixed Cost Share:** $\frac{C_{\text{fixed}}}{N_{\text{members}}}$
   - **Other Variable Share:** $\frac{C_{\text{other}}}{N_{\text{members}}}$
   - **Total Member Owed:**
     $$\text{Total Owed}_m = \text{Member Food Cost}_m + \text{Fixed Cost Share}_m + \text{Other Variable Share}_m$$

3. **Credits & Prior Liabilities:**
   - **Total Paid ($P_m$):** Sum of costs within the settlement paid by member $m$.
   - **Advance Deposits ($A_m$):** Sum of advance deposits recorded in `deposits` table for member $m$ in this period.
   - **Carry-Forward In ($CF_m$):** Balance brought forward from previous settlement ($+CF$ = credit, $-CF$ = debt).

4. **Net Settlement Balance:**
   $$\text{Net Balance}_m = (P_m + A_m) - (\text{Total Owed}_m - CF_m)$$
   - Positive $\rightarrow$ House owes the member a reimbursement.
   - Negative $\rightarrow$ Member owes the house money.

---

## 5. Settlement Frontend Lifecycle (4-Phase Wizard)

The Flutter settlement UI guides the house manager through 4 discrete phases:

```
[Phase 1: Date Range] ──► [Phase 2: Cost Selection] ──► [Phase 3: Summary] ──► [Phase 4: Resolutions & Finalisation]
   Pick From & To            Check/Uncheck Costs          Review Meal Rate,       Set Carry-Forward vs Settle,
       Dates                   Included in Settle          Breakdowns & Dues      Save Draft or Publish/Finalise
```

1. **Phase 1: Date Range Picker** — Filter unsettled shared costs and meal logs between custom dates.
2. **Phase 2: Cost Selection** — Interactive multi-select list of candidate costs with totals summary.
3. **Phase 3: Summary Phase** — Full transparent breakdown displaying meal rate, individual food/fixed/variable contributions, advance credits, and net balances.
4. **Phase 4: Resolution & Finalise** — Manager chooses per member whether residual balance will be settled immediately (`settle`) or carried forward into the next period (`carry_forward`).
