-- 花间美甲预约系统：Supabase PostgreSQL 初始结构
create extension if not exists pgcrypto;
create table if not exists public.artists (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  bio text not null default '',
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  duration_minutes integer not null check (duration_minutes > 0),
  price_cents integer not null check (price_cents >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null check (char_length(customer_name) between 1 and 80),
  phone text not null check (char_length(phone) between 6 and 32),
  note text not null default '',
  service_id uuid references public.services(id) on delete set null,
  artist_id uuid references public.artists(id) on delete set null,
  service_name text not null,
  artist_name text not null,
  appointment_date date not null,
  appointment_time time not null,
  duration_minutes integer not null check (duration_minutes > 0),
  price_cents integer not null check (price_cents >= 0),
  status text not null default 'pending' check (status in ('pending','confirmed','completed','cancelled')),
  created_at timestamptz not null default now()
);
create index if not exists bookings_date_time_idx on public.bookings(appointment_date, appointment_time);
create index if not exists bookings_status_idx on public.bookings(status);

-- Public visitors may request a booking. Reads and status changes require a staff session.
alter table public.bookings enable row level security;
alter table public.services enable row level security;
alter table public.artists enable row level security;
create policy "Anyone can request a booking" on public.bookings for insert to anon, authenticated with check (status = 'pending');
create policy "Anyone can view active services" on public.services for select to anon, authenticated using (active = true);
create policy "Anyone can view active artists" on public.artists for select to anon, authenticated using (active = true);
-- For launch: create staff users in Supabase Auth and add a restrictive staff-only policy, or use an Edge Function.
-- Never expose the Supabase service_role key in the browser.
insert into public.services(name,description,duration_minutes,price_cents) values
('纯色凝胶','温柔显白 · 含基础护理',60,16800),('法式美甲','经典优雅 · 含基础护理',90,23800),('手绘设计','原创定制 · 复杂款式请备注',120,32800),('手部护理','去角质 · 手膜 · 指缘护理',45,12800)
on conflict do nothing;
insert into public.artists(name,bio) values ('小满','主理人 · 擅长法式与手绘'),('知夏','资深美甲师 · 温柔细节控') on conflict do nothing;
