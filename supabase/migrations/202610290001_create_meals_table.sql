-- Royal Hires: Meals table
-- Review before running in the LIVE Supabase project.
-- This creates the table with RLS enabled and deliberately adds NO public/anon policies.
-- Meal API access will remain blocked until Supabase Auth and least-privilege policies are implemented.

create table if not exists public.meals (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.employees(id) on delete cascade,
  meal_date date not null,
  breakfast integer not null default 0 check (breakfast in (0, 1)),
  lunch integer not null default 0 check (lunch in (0, 1)),
  dinner integer not null default 0 check (dinner in (0, 1)),
  created_at timestamptz not null default now(),
  constraint meals_employee_date_unique unique (employee_id, meal_date)
);

alter table public.meals enable row level security;

comment on table public.meals is
  'Royal Hires daily meal tracking. RLS enabled; add least-privilege policies only after app authentication is configured.';
