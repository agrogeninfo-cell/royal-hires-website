-- Pay Royal payroll and factory billing module
-- Applied to Supabase project jwghmsflabvzzhucuwsn on 2026-10-30.
-- Safe to re-run: tables/columns/indexes are guarded; policies are recreated.

create table if not exists public.factory_rate_cards (
  id uuid primary key default gen_random_uuid(),
  factory_name text not null unique,
  male_wage numeric(12,2),
  female_wage numeric(12,2),
  male_bill_rate numeric(12,2),
  female_bill_rate numeric(12,2),
  ot_wage_rate numeric(12,2),
  ot_bill_rate numeric(12,2),
  late_deduction_per_hour numeric(12,2) not null default 150,
  attendance_bonus numeric(12,2) not null default 5500,
  attendance_bonus_days numeric(6,2) not null default 21,
  breakfast_rate numeric(12,2) not null default 130,
  lunch_rate numeric(12,2) not null default 250,
  dinner_rate numeric(12,2) not null default 250,
  weekday_wage numeric(12,2),
  saturday_wage numeric(12,2),
  sunday_poya_wage numeric(12,2),
  updated_at timestamptz not null default now(),
  constraint factory_rate_cards_nonnegative check (
    coalesce(male_wage,0)>=0 and coalesce(female_wage,0)>=0 and
    coalesce(male_bill_rate,0)>=0 and coalesce(female_bill_rate,0)>=0 and
    coalesce(ot_wage_rate,0)>=0 and coalesce(ot_bill_rate,0)>=0 and
    late_deduction_per_hour>=0 and attendance_bonus>=0 and attendance_bonus_days>0 and
    breakfast_rate>=0 and lunch_rate>=0 and dinner_rate>=0
  )
);

alter table public.factory_rate_cards
  add column if not exists weekday_wage numeric(12,2),
  add column if not exists saturday_wage numeric(12,2),
  add column if not exists sunday_poya_wage numeric(12,2);

insert into public.factory_rate_cards
(factory_name,male_wage,female_wage,male_bill_rate,female_bill_rate,ot_wage_rate,ot_bill_rate,
 late_deduction_per_hour,attendance_bonus,attendance_bonus_days,breakfast_rate,lunch_rate,dinner_rate,
 weekday_wage,saturday_wage,sunday_poya_wage)
values
('Millennium Estate',2500,2100,3000,2500,180,225,150,5500,21,130,250,250,null,null,null),
('Empire Tea Factory',null,null,null,null,null,null,150,5500,21,130,250,250,2000,2000,2300)
on conflict(factory_name) do nothing;

alter table public.attendance add column if not exists shift_type text not null default 'weekday';
alter table public.attendance drop constraint if exists attendance_shift_type_check;
alter table public.attendance add constraint attendance_shift_type_check check (shift_type in ('weekday','saturday','sunday_poya'));
update public.factory_rate_cards set weekday_wage=2000,saturday_wage=2000,sunday_poya_wage=2300,updated_at=now() where factory_name='Empire Tea Factory' and weekday_wage is null and saturday_wage is null and sunday_poya_wage is null;

alter table public.attendance
  add column if not exists shift_type text not null default 'weekday';
alter table public.attendance drop constraint if exists attendance_shift_type_check;
alter table public.attendance add constraint attendance_shift_type_check
  check (shift_type in ('weekday','saturday','sunday_poya'));

alter table public.settlements
  alter column days type numeric(8,2) using days::numeric;
alter table public.settlements
  add column if not exists gross_pay numeric(12,2),
  add column if not exists ot_pay numeric(12,2),
  add column if not exists bonus numeric(12,2) not null default 0,
  add column if not exists meal_deduction numeric(12,2) not null default 0,
  add column if not exists late_deduction numeric(12,2) not null default 0,
  add column if not exists advance_deduction numeric(12,2) not null default 0,
  add column if not exists net_pay numeric(12,2),
  add column if not exists factory_name text,
  add column if not exists period_start date,
  add column if not exists period_end date,
  add column if not exists calculated_at timestamptz,
  add column if not exists calculation_details jsonb not null default '{}'::jsonb;

create unique index if not exists settlements_employee_period_unique
  on public.settlements(employee_id,period)
  where employee_id is not null and period is not null;

create table if not exists public.factory_invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_number text not null unique,
  factory_name text not null,
  period text not null,
  period_start date not null,
  period_end date not null,
  attendance_total numeric(12,2) not null default 0,
  ot_hours numeric(12,2) not null default 0,
  labour_amount numeric(12,2) not null default 0,
  ot_amount numeric(12,2) not null default 0,
  other_amount numeric(12,2) not null default 0,
  total_amount numeric(12,2) not null default 0,
  status text not null default 'draft' check(status in ('draft','issued','paid','void')),
  line_items jsonb not null default '[]'::jsonb,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique(factory_name,period)
);

alter table public.factory_rate_cards enable row level security;
alter table public.factory_invoices enable row level security;
revoke all on public.factory_rate_cards,public.factory_invoices from anon,authenticated;
grant select,insert,update,delete on public.factory_rate_cards,public.factory_invoices to authenticated;

drop policy if exists "admin office manage factory rates" on public.factory_rate_cards;
create policy "admin office manage factory rates" on public.factory_rate_cards
for all to authenticated
using (exists(select 1 from public.user_profiles p where p.user_id=(select auth.uid()) and p.is_active and p.role in ('admin','office_staff')))
with check (exists(select 1 from public.user_profiles p where p.user_id=(select auth.uid()) and p.is_active and p.role in ('admin','office_staff')));

drop policy if exists "admin office manage invoices" on public.factory_invoices;
create policy "admin office manage invoices" on public.factory_invoices
for all to authenticated
using (exists(select 1 from public.user_profiles p where p.user_id=(select auth.uid()) and p.is_active and p.role in ('admin','office_staff')))
with check (exists(select 1 from public.user_profiles p where p.user_id=(select auth.uid()) and p.is_active and p.role in ('admin','office_staff')));

revoke all on public.user_profiles,public.employees,public.attendance,public.meals,public.settlements from anon;
grant select on public.user_profiles to authenticated;
grant select,insert,update,delete on public.employees,public.attendance,public.meals,public.settlements to authenticated;

create index if not exists attendance_employee_id_idx on public.attendance(employee_id);
create index if not exists attendance_date_employee_idx on public.attendance(date,employee_id);
create index if not exists meals_date_employee_idx on public.meals(meal_date,employee_id);
create index if not exists factory_invoices_created_by_idx on public.factory_invoices(created_by);
create index if not exists user_profiles_employee_id_idx on public.user_profiles(employee_id);
create index if not exists employees_factory_idx on public.employees(factory);
create index if not exists settlements_period_factory_idx on public.settlements(period,factory_name);
