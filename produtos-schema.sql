-- =====================================================================
-- Loja virtual — produtos físicos (japamalás, guias) e digitais (PDFs)
-- Rode este script no SQL Editor do MESMO projeto Supabase do schema.sql
-- principal (https://txpkvmxrgfywbmekdkhh.supabase.co).
-- =====================================================================

-- 1) Bucket de storage público para as imagens dos produtos
insert into storage.buckets (id, name, public)
values ('produtos', 'produtos', true)
on conflict (id) do nothing;

create policy "Leitura pública de imagens de produto (storage)"
on storage.objects for select
using (bucket_id = 'produtos');

create policy "Upload de imagens de produto (storage, protótipo sem auth)"
on storage.objects for insert
with check (bucket_id = 'produtos');

create policy "Exclusão de imagens de produto (storage, protótipo sem auth)"
on storage.objects for delete
using (bucket_id = 'produtos');

-- 2) Tabela de produtos
create table if not exists produtos (
  id bigint generated always as identity primary key,
  nome text not null,
  tipo text not null check (tipo in ('fisico','digital')),
  preco numeric(10,2) not null default 0,
  descricao text,
  imagem_url text,
  imagem_path text,        -- caminho no bucket, usado para excluir do storage
  link_pagamento text,     -- Stripe Payment Link específico deste produto
  estoque integer,         -- null = não controla estoque (padrão p/ digital)
  ativo boolean not null default true,
  ordem integer not null default 0,
  created_at timestamptz not null default now()
);

alter table produtos enable row level security;

create policy "Leitura pública de produtos"
on produtos for select
using (true);

create policy "Escrita pública de produtos (protótipo sem auth)"
on produtos for all
using (true)
with check (true);

-- =====================================================================
-- SOBRE OS PAGAMENTOS E A ENTREGA
--
-- Cada produto tem seu próprio "link_pagamento": um Stripe Payment Link
-- criado no Dashboard do Stripe (dashboard.stripe.com → Payment Links),
-- sem precisar de nenhum código de servidor. Nona cola esse link no
-- campo "Link de pagamento" ao criar/editar o produto no painel.
--
-- • Produtos FÍSICOS: no Payment Link, habilite "Collect customer
--   addresses" pra receber o endereço de entrega.
-- • Produtos DIGITAIS (PDF): no Payment Link, use a opção nativa do
--   Stripe de anexar um arquivo ao produto ("digital product delivery")
--   — o Stripe libera o download automaticamente após o pagamento,
--   sem precisar de nenhum backend nosso.
--
-- Como cada produto usa o checkout hospedado do próprio Stripe, não há
-- o mesmo risco de "confirmação só no navegador" que existia no
-- protótipo anterior de assinatura — o Stripe cuida de tudo.
-- =====================================================================
