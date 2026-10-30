-- Royal Hires employee portal foundation
-- Employees must authenticate through Supabase Auth. Never verify PINs in browser code.
-- Run after reviewing the existing schema and setting up employee/admin authentication.

create table if not exists public.employee_portal_accounts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  employee_id uuid not null unique references public.employees(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.employee_portal_accounts enable row level security;

-- A signed-in employee may read only their own account mapping.
drop policy if exists "employee reads own portal mapping"
  on public.employee_portal_accounts;
create policy "employee reads own portal mapping"
  on public.employee_portal_accounts
  for select to authenticated
  using (user_id = (select auth.uid()));

grant select on public.employee_portal_accounts to authenticated;

-- Centrally managed meal rates, instead of browser-localStorage rates.
create table if not exists public.meal_rates (
  id integer generated always as identity primary key,
  breakfast numeric(10,2) not null default 150 check (breakfast >= 0),
  lunch numeric(10,2) not null default 350 check (lunch >= 0),
  dinner numeric(10,2) not null default 320 check (dinner >= 0),
  effective_from date not null default current_date,
  created_at timestamptz not null default now(),
  constraint meal_rates_effective_from_unique unique (effective_from)
);

alter table public.meal_rates enable row level security;

-- Authenticated users may read the published rates. No client-side writes.
drop policy if exists "authenticated users read meal rates"
  on public.meal_rates;
create policy "authenticated users read meal rates"
  on public.meal_rates
  for select to authenticated
  using (true);

grant select on public.meal_rates to authenticated;

-- Only authenticated employees mapped to an employee row can read that employee's meal records.
drop policy if exists "employee reads own meal records"
  on public.meals;
create policy "employee reads own meal records"
  on public.meals
  for select to authenticated
  using (
    exists (
      select 1
      from public.employee_portal_accounts a
      where a.user_id = (select auth.uid())
        and a.employee_id = meals.employee_id
    )
  );

grant select on public.meals to authenticated;

-- Do not add broad anon policies. Admin meal entry needs a separately authenticated admin role
-- or a trusted server-side endpoint before write policies are introduced.
