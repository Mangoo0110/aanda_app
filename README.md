# Aanda (আন্দা) — Shared Living Cost & Meal Management System

**Aanda** is a modern shared-living management platform tailored for flat/mess culture in South Asia. It streamlines daily expense tracking, multi-member meal logging, and end-of-billing-cycle settlement calculations.

---

## 📚 Project Documentation

All system specifications and architectural designs are available under the [`docs/`](docs/) directory:

| Document | Description |
|---|---|
| [**Business Requirements Document (BRD)**](docs/BUSINESS_REQUIREMENTS.md) | Complete business logic, rules, calculation formulas, permissions, and entity definitions. |
| [**System Architecture**](docs/SYSTEM_ARCHITECTURE.md) | High-level system architecture, Clean Architecture standards, BLoC state design, and monorepo structure. |
| [**Database Schema Specification**](docs/DATABASE_SCHEMA.md) | PostgreSQL tables, constraints, custom enums, RLS policies, triggers, and Edge Function contracts. |
| [**Implementation Plan**](docs/IMPLEMENTATION_PLAN.md) | Technical implementation roadmap, module breakdown, and verification steps. |

---

## 🏗️ Repository Structure

```
project_aanda/
├── docs/                        ← Complete system documentation
├── aanda/                       ← Flutter mobile client (Clean Architecture + BLoC)
│   ├── lib/
│   │   ├── main.dart            ← App entry & Supabase initialization
│   │   └── src/
│   │       ├── app/             ← Shell, GoRouter routing, AppBlocs
│   │       ├── core/            ← Result wrappers, theme tokens, widgets
│   │       └── features/        ← Auth, House, Cycle, Costs, Meals, Settlements
│   └── pubspec.yaml
└── db/                          ← Supabase backend (PostgreSQL + Deno)
    ├── supabase/
    │   ├── migrations/          ← 14 SQL migration files (tables, RLS, triggers)
    │   ├── functions/           ← Deno edge functions (compute-settlement, close-cycle)
    │   ├── config.toml          ← Supabase CLI config
    │   └── seed.sql             ← Initial seed data
    └── README.md
```

---

## 🔗 Remote Repositories

- **Mobile Client:** [`git@github.com:Mangoo0110/aanda_app.git`](https://github.com/Mangoo0110/aanda_app)
- **Supabase Backend:** [`git@github.com:Mangoo0110/aanda_app_supabase.git`](https://github.com/Mangoo0110/aanda_app_supabase)
