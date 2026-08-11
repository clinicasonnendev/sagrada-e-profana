-- ============================================================
-- flash-decor kit — setup.sql (portável, rode em qualquer projeto Supabase)
--
-- Cria:
--   1. public.profiles          (se ainda não existir) + coluna is_admin
--      + trigger que cria a linha automaticamente no primeiro login
--   2. public.flash_decor_images (a pool de imagens do efeito)
--   3. políticas de RLS: leitura pública, escrita só pra admin
--   4. grants de baixo nível (sem isso a RLS nem chega a ser avaliada)
--
-- Depois de rodar isto, falta só (fora do SQL, feito pelo painel):
--   a) Storage → New bucket → nome "flash-decor" → marcar Public
--   b) Logar uma vez em admin-flash-decor.html com sua conta Google
--      (isso cria sua linha em profiles via trigger)
--   c) Rodar o UPDATE lá no fim deste arquivo com o SEU uuid, pra
--      virar admin (pegue o uuid em Authentication → Users)
--
-- Idempotente — seguro rodar mais de uma vez.
-- ============================================================

-- 1) profiles ---------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists is_admin boolean not null default false;

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id);

-- trigger: cria a linha em profiles automaticamente no primeiro login
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2) flash_decor_images -----------------------------------------
create table if not exists public.flash_decor_images (
  id uuid primary key default gen_random_uuid(),
  titulo text,
  image_url text not null,
  tags text[] not null default '{}',
  decor boolean not null default true,
  created_at timestamptz not null default now()
);

comment on table public.flash_decor_images is
  'Pool de imagens do efeito flash-decor.js + admin-flash-decor.html.';

alter table public.flash_decor_images enable row level security;

drop policy if exists "flash_decor_images_select_public" on public.flash_decor_images;
create policy "flash_decor_images_select_public"
  on public.flash_decor_images for select
  using (true);

drop policy if exists "flash_decor_images_write_admin" on public.flash_decor_images;
create policy "flash_decor_images_write_admin"
  on public.flash_decor_images for all
  using (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true))
  with check (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- 3) Storage — bucket "flash-decor" (criar manualmente no painel primeiro,
--    Storage → New bucket → nome exato "flash-decor" → Public). As
--    policies abaixo só funcionam depois do bucket já existir.
drop policy if exists "flash_decor_bucket_select_public" on storage.objects;
create policy "flash_decor_bucket_select_public"
  on storage.objects for select
  using (bucket_id = 'flash-decor');

drop policy if exists "flash_decor_bucket_write_admin" on storage.objects;
create policy "flash_decor_bucket_write_admin"
  on storage.objects for all
  using (
    bucket_id = 'flash-decor'
    and exists (select 1 from public.profiles where id = auth.uid() and is_admin = true)
  )
  with check (
    bucket_id = 'flash-decor'
    and exists (select 1 from public.profiles where id = auth.uid() and is_admin = true)
  );

-- 4) Grants de baixo nível (sem isso, RLS nunca chega a ser avaliada
--    em projetos onde o grant automático de fábrica não veio configurado)
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on all tables in schema public to anon;
alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public grant select on tables to anon;

-- ============================================================
-- ÚLTIMO PASSO — depois de logar uma vez em admin-flash-decor.html,
-- pegue seu uuid em Authentication → Users e rode isto:
--
-- update public.profiles set is_admin = true where id = 'SEU-UUID-AQUI'::uuid;
-- ============================================================
