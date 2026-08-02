-- =====================================================================
-- Símbolos de decoração (efeito "flash-decor") — Sagrada e Profana
-- Rode este script no SQL Editor do MESMO projeto Supabase do schema.sql
-- principal (https://txpkvmxrgfywbmekdkhh.supabase.co).
-- =====================================================================

-- 1) Bucket de storage público para as imagens dos símbolos
insert into storage.buckets (id, name, public)
values ('simbolos', 'simbolos', true)
on conflict (id) do nothing;

-- políticas de acesso ao bucket (protótipo: leitura e escrita públicas,
-- igual ao restante do schema — ver aviso de segurança no README)
create policy "Leitura pública de símbolos (storage)"
on storage.objects for select
using (bucket_id = 'simbolos');

create policy "Upload de símbolos (storage, protótipo sem auth)"
on storage.objects for insert
with check (bucket_id = 'simbolos');

create policy "Exclusão de símbolos (storage, protótipo sem auth)"
on storage.objects for delete
using (bucket_id = 'simbolos');

-- 2) Tabela que registra quais imagens do bucket entram na decoração
create table if not exists simbolos (
  id bigint generated always as identity primary key,
  image_url text not null,
  path text not null,           -- caminho no bucket, usado para excluir do storage
  decor boolean not null default true,
  created_at timestamptz not null default now()
);

alter table simbolos enable row level security;

create policy "Leitura pública de simbolos"
on simbolos for select
using (true);

create policy "Escrita pública de simbolos (protótipo sem auth)"
on simbolos for all
using (true)
with check (true);
