# Aanda — System Architecture & Technical Specifications

**Version:** 1.0  
**Stack:** Flutter (Dart 3.9+) · BLoC · GoRouter · Supabase (PostgreSQL 15+) · Deno Edge Functions  
**Architecture Pattern:** Clean Architecture + Feature-First Modularization

---

## 1. High-Level Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                    Flutter Client (Android)                   │
│                                                               │
│   ┌────────────────────────────────────────────────────────┐  │
│   │                   Presentation Layer                   │  │
│   │     Screens · Widgets · BLoC (State Management)       │  │
│   └──────────────────────────┬─────────────────────────────┘  │
│                              │ calls                          │
│   ┌──────────────────────────▼─────────────────────────────┐  │
│   │                      Domain Layer                      │  │
│   │        Entities · Use Cases · Repository Contracts      │  │
│   └──────────────────────────▲─────────────────────────────┘  │
│                              │ implements                     │
│   ┌──────────────────────────┴─────────────────────────────┐  │
│   │                      Data Layer                        │  │
│   │    Models · Data Sources · Supabase Client & Realtime  │  │
│   └──────────────────────────┬─────────────────────────────┘  │
└──────────────────────────────┼────────────────────────────────┘
                               │ HTTPS / WSS
                               ▼
┌───────────────────────────────────────────────────────────────┐
│                       Supabase Backend                        │
│                                                               │
│   ┌─────────────────────┐       ┌─────────────────────────┐   │
│   │    Supabase Auth    │       │     Edge Functions      │   │
│   │   (JWT / Session)   │       │  compute-settlement     │   │
│   └──────────┬──────────┘       │  close-cycle            │   │
│              │                  └────────────┬────────────┘   │
│              ▼                               ▼                │
│   ┌───────────────────────────────────────────────────────┐   │
│   │               PostgreSQL Database (RLS)               │   │
│   │     profiles · houses · house_members · costs         │   │
│   │     meal_logs · billing_cycles · settlements          │   │
│   └───────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────┘
```

---

## 2. Directory Structure & Monorepo Setup

```
project_aanda/
├── docs/                               ← System Documentation
│   ├── BUSINESS_REQUIREMENTS.md       ← Full BRD
│   ├── DATABASE_SCHEMA.md             ← Tables, RLS, Edge Functions
│   ├── IMPLEMENTATION_PLAN.md         ← Roadmap & Architecture
│   └── SYSTEM_ARCHITECTURE.md         ← Technical Design & Patterns
├── aanda/                              ← Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart                  ← Entry point & Supabase init
│   │   └── src/
│   │       ├── app/                   ← App Shell, Router, Theme
│   │       ├── core/                  ← Infrastructure, Handlers, Theme
│   │       │   ├── async_handlers/    ← AsyncRequest, RepoResponse
│   │       │   ├── config/            ← SupabaseConfig
│   │       │   ├── theme/             ← Color tokens, AppTheme
│   │       │   └── usecases/          ← BaseUsecase
│   │       └── features/              ← Feature modules
│   │           ├── auth/              ← Authentication & Profile
│   │           ├── house/             ← House creation, join, admin
│   │           ├── cycle/             ← Billing cycles & weights
│   │           ├── costs/             ← Shared & personal ledger
│   │           ├── meals/             ← Daily meal tracking (table)
│   │           └── settlement/        ← Monthly settlement reports
│   └── pubspec.yaml
└── db/                                 ← Supabase Backend Project
    ├── supabase/
    │   ├── config.toml                ← Supabase CLI config
    │   ├── seed.sql                   ← Development seed data
    │   ├── migrations/                ← 14 SQL migration scripts
    │   └── functions/                 ← Deno TypeScript edge functions
    │       ├── _shared/               ← CORS and response helpers
    │       ├── compute-settlement/    ← Settlement calculation logic
    │       └── close-cycle/           ← Finalize and rollover balance
    └── README.md
```

---

## 3. Core Principles & Coding Standards

### 3.1 Clean Architecture Rules
1. **Domain layer has zero external framework dependencies.** It contains pure Dart entities, use cases, and repository interfaces.
2. **Data layer depends on Domain.** Implements domain repository interfaces, handles JSON serialization (freezed / json_serializable), and communicates with Supabase.
3. **Presentation layer depends on Domain.** BLoCs invoke use cases and emit immutable UI states. UI widgets listen to BLoC states and dispatch events.
4. **No raw exceptions crossing boundaries.** All async repository calls return `AsyncRequest<T>` (`Future<RepoResponse<T>>`), wrapping success (`SuccessRepoCall<T>`) or failure (`FailedRepoCall<T>`).

### 3.2 State Management (flutter_bloc 9.x)
- Every feature has a dedicated BLoC or Cubit.
- BLoCs use event-driven reactive updates with `on<Event>` handlers.
- UI uses `BlocBuilder`, `BlocConsumer`, or `context.read<Bloc>()` for predictable rendering.

### 3.3 Routing (go_router 17.x)
- Centralized `AppRouter` with route redirection based on `AuthStatus`.
- Unauthenticated users are redirected to `/auth/login`.
- Authenticated users land on `/dashboard` or house setup if no house membership exists.

---

## 4. Business Calculation Engine

### 4.1 Meal Rate Formula
$$\text{Total Weighted Meals} = \sum (\text{breakfast} \times w_b + \text{lunch} \times w_l + \text{dinner} \times w_d)$$

$$\text{Meal Rate} = \frac{\text{Total Shared Food Costs}}{\text{Total Weighted Meals}}$$

$$\text{Member Food Cost} = \text{Member Weighted Meals} \times \text{Meal Rate}$$

### 4.2 Fixed Cost Split
$$\text{Member Fixed Share} = \frac{\text{Total Shared Fixed Costs}}{\text{Active Member Count}}$$
*(Unless overridden by custom category split ratios)*

### 4.3 Other Variable Split
$$\text{Member Other Variable Share} = \frac{\text{Total Shared Non-Food Variable Costs}}{\text{Active Member Count}}$$

### 4.4 Member Net Balance
$$\text{Total Member Due} = \text{Food Cost} + \text{Fixed Share} + \text{Other Variable Share}$$

$$\text{Net Balance} = \text{Total Member Due} - \text{Total Paid by Member for Shared Expenses}$$

- If **Net Balance > 0**: Member owes money to the house pool.
- If **Net Balance < 0**: Member is owed a refund from the house pool.
- With Carry-Forward:
  $$\text{Final Balance} = \text{Net Balance} + \text{Previous Cycle Carry-Forward}$$
