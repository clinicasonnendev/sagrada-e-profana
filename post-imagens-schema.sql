-- =====================================================================
-- Imagens inseridas no corpo dos posts (galeria do editor) — Sagrada e Profana
-- Rode este script no SQL Editor do MESMO projeto Supabase do schema.sql
-- principal (https://txpkvmxrgfywbmekdkhh.supabase.co).
-- =====================================================================

-- 1) Bucket de storage público para as imagens usadas dentro dos textos
insert into storage.buckets (id, name, public)
values ('post-imagens', 'post-imagens', true)
on conflict (id) do nothing;

create policy "Leitura pública de imagens de post (storage)"
on storage.objects for select
using (bucket_id = 'post-imagens');

create policy "Upload de imagens de post (storage, protótipo sem auth)"
on storage.objects for insert
with check (bucket_id = 'post-imagens');

create policy "Exclusão de imagens de post (storage, protótipo sem auth)"
on storage.objects for delete
using (bucket_id = 'post-imagens');

-- 2) Tabela que registra as imagens já enviadas, para a galeria do editor
create table if not exists post_imagens (
  id bigint generated always as identity primary key,
  image_url text not null,
  path text not null,          -- caminho no bucket, usado para excluir do storage
  created_at timestamptz not null default now()
);

alter table post_imagens enable row level security;

create policy "Leitura pública de post_imagens"
on post_imagens for select
using (true);

create policy "Escrita pública de post_imagens (protótipo sem auth)"
on post_imagens for all
using (true)
with check (true);
