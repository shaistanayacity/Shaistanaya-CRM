-- Shaistanaya CRM — skema database Supabase.
-- Jalankan sekali di Supabase → SQL Editor.

create table if not exists public.leads (
  id            text primary key,
  created_at    timestamptz not null,
  responded_at  timestamptz,
  source        text not null default '—',
  nama          text not null default '(tanpa nama)',
  telp          text not null,
  domisili      text not null default '—',
  minat         text not null default '—',
  stage         text not null default 'Masuk'
                check (stage in ('Masuk', 'Direspon', 'Follow Up', 'Janjian', 'Deal', 'Lost')),
  loss_rank     smallint,
  notes         jsonb not null default '[]'::jsonb,
  updated_at    timestamptz not null default now()
);

create index if not exists leads_created_at_idx on public.leads (created_at desc);

create table if not exists public.cluster_notes (
  minat       text primary key,
  note        text not null,
  updated_at  timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists leads_touch on public.leads;
create trigger leads_touch before update on public.leads
  for each row execute function public.touch_updated_at();

drop trigger if exists cluster_notes_touch on public.cluster_notes;
create trigger cluster_notes_touch before update on public.cluster_notes
  for each row execute function public.touch_updated_at();

-- Data lead berisi no. telp pelanggan: hanya email yang terdaftar di team_members
-- yang boleh akses, walaupun ada orang lain yang berhasil daftar akun.
create table if not exists public.team_members (
  email     text primary key check (email = lower(email)),
  added_at  timestamptz not null default now()
);
-- Tanpa policy: tabel ini hanya dikelola dari dashboard / SQL Editor.
alter table public.team_members enable row level security;

create schema if not exists private;
grant usage on schema private to authenticated;

create or replace function private.is_team_member()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.team_members
    where email = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke execute on function private.is_team_member() from public, anon;
grant execute on function private.is_team_member() to authenticated;

alter table public.leads enable row level security;
alter table public.cluster_notes enable row level security;

drop policy if exists "team can read leads" on public.leads;
drop policy if exists "team can write leads" on public.leads;
create policy "team can read leads" on public.leads
  for select to authenticated using ((select private.is_team_member()));
create policy "team can write leads" on public.leads
  for all to authenticated using ((select private.is_team_member())) with check ((select private.is_team_member()));

drop policy if exists "team can read cluster notes" on public.cluster_notes;
drop policy if exists "team can write cluster notes" on public.cluster_notes;
create policy "team can read cluster notes" on public.cluster_notes
  for select to authenticated using ((select private.is_team_member()));
create policy "team can write cluster notes" on public.cluster_notes
  for all to authenticated using ((select private.is_team_member())) with check ((select private.is_team_member()));
