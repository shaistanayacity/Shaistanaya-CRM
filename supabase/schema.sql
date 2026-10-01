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
  signals       jsonb not null default '[]'::jsonb,  -- temperature checklist ids
  next_at       date,                                   -- follow-up berikutnya
  next_note     text,
  survey_at     timestamptz,                            -- jadwal survey
  ajak_at       timestamptz,                            -- ajakan survey terkirim
  konfirm_at    timestamptz,                            -- konfirmasi survey terkirim
  done_at       timestamptz,                            -- terakhir ditandai selesai di Tugas Hari Ini
  objections    jsonb not null default '[]'::jsonb,     -- alasan keberatan yang dicatat [{r, ts}]
  updated_at    timestamptz not null default now()
);

create index if not exists leads_created_at_idx on public.leads (created_at desc);

-- Normalized phone (0812… / +62 812… / 812… -> 62812…) for duplicate checks.
alter table public.leads add column if not exists telp_norm text generated always as (
  case
    when regexp_replace(telp, '\D', '', 'g') like '0%' then '62' || substr(regexp_replace(telp, '\D', '', 'g'), 2)
    when regexp_replace(telp, '\D', '', 'g') like '8%' then '62' || regexp_replace(telp, '\D', '', 'g')
    else regexp_replace(telp, '\D', '', 'g')
  end
) stored;
create index if not exists leads_telp_norm_idx on public.leads (telp_norm);

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

-- Akses: admin lihat/ubah semua; marketing hanya lead miliknya sendiri
-- (owner_email), tidak bisa hapus lead dan tidak bisa ubah Playbook.
create table if not exists public.team_members (
  email     text primary key check (email = lower(email)),
  nama      text,
  role      text not null default 'marketing' check (role in ('admin', 'marketing')),
  added_at  timestamptz not null default now()
);
alter table public.team_members enable row level security;

alter table public.leads add column if not exists owner_email text;
update public.leads set owner_email = 'shaistanayacity@gmail.com' where owner_email is null;
alter table public.leads alter column owner_email set not null;
alter table public.leads alter column owner_email set default lower(coalesce(auth.jwt() ->> 'email', ''));
create index if not exists leads_owner_idx on public.leads (owner_email);

create schema if not exists private;
grant usage on schema private to authenticated;

create or replace function private.is_team_member()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.team_members where email = lower(coalesce(auth.jwt() ->> 'email', ''))); $$;
create or replace function private.is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.team_members where email = lower(coalesce(auth.jwt() ->> 'email', '')) and role = 'admin'); $$;
revoke execute on function private.is_team_member() from public, anon;
revoke execute on function private.is_admin() from public, anon;
grant execute on function private.is_team_member() to authenticated;
grant execute on function private.is_admin() to authenticated;

alter table public.leads enable row level security;
alter table public.cluster_notes enable row level security;

drop policy if exists "leads select" on public.leads;
drop policy if exists "leads insert" on public.leads;
drop policy if exists "leads update" on public.leads;
drop policy if exists "leads delete admin" on public.leads;
create policy "leads select" on public.leads for select to authenticated
  using ((select private.is_admin()) or (owner_email = lower(coalesce(auth.jwt() ->> 'email', '')) and (select private.is_team_member())));
create policy "leads insert" on public.leads for insert to authenticated
  with check ((select private.is_admin()) or (owner_email = lower(coalesce(auth.jwt() ->> 'email', '')) and (select private.is_team_member())));
create policy "leads update" on public.leads for update to authenticated
  using ((select private.is_admin()) or (owner_email = lower(coalesce(auth.jwt() ->> 'email', '')) and (select private.is_team_member())))
  with check ((select private.is_admin()) or (owner_email = lower(coalesce(auth.jwt() ->> 'email', '')) and (select private.is_team_member())));
create policy "leads delete admin" on public.leads for delete to authenticated
  using ((select private.is_admin()));

drop policy if exists "team can read cluster notes" on public.cluster_notes;
drop policy if exists "admin writes cluster notes" on public.cluster_notes;
create policy "team can read cluster notes" on public.cluster_notes
  for select to authenticated using ((select private.is_team_member()));
create policy "admin writes cluster notes" on public.cluster_notes
  for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

drop policy if exists "team members read" on public.team_members;
create policy "team members read" on public.team_members for select to authenticated
  using ((select private.is_admin()) or email = lower(coalesce(auth.jwt() ->> 'email', '')));

-- Daftar tim (buat user-nya di Authentication → Users, lalu daftarkan di sini):
-- insert into public.team_members(email, nama, role) values
--   ('shaistanayacity@gmail.com', 'Admin', 'admin'),
--   ('tama@shaistanayacity.com', 'Tama', 'marketing'), ('nonik@shaistanayacity.com', 'Nonik', 'marketing'),
--   ('karin@shaistanayacity.com', 'Karin', 'marketing'), ('eki@shaistanayacity.com', 'Eki', 'marketing'),
--   ('putri@shaistanayacity.com', 'Putri', 'marketing'), ('kholid@shaistanayacity.com', 'Kholid', 'marketing')
-- on conflict (email) do nothing;
