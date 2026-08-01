-- ============================================================
-- SAGRADA E PROFANA — proteger o painel: só a Nona pode escrever
-- Rode isto no SQL Editor do Supabase DEPOIS de criar o usuário
-- de login da Nona (veja o passo a passo abaixo).
-- ============================================================

-- ---------- 1) Trocar as políticas de escrita pública por "só autenticado" ----------

drop policy if exists "livros: escrita publica" on livros;
create policy "livros: escrita autenticada" on livros
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "posts: escrita publica" on posts;
create policy "posts: escrita autenticada" on posts
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "comentarios: escrita publica" on comentarios;
-- comentários: qualquer leitor pode enviar um comentário (fica pendente),
-- mas só a Nona autenticada pode aprovar/editar/excluir.
create policy "comentarios: qualquer um pode comentar" on comentarios
  for insert with check (true);
create policy "comentarios: só autenticado modera" on comentarios
  for update using (auth.role() = 'authenticated');
create policy "comentarios: só autenticado exclui" on comentarios
  for delete using (auth.role() = 'authenticated');

drop policy if exists "categorias: escrita publica" on categorias;
create policy "categorias: escrita autenticada" on categorias
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- Leitura continua pública em todas as tabelas (o blog precisa ser lido por qualquer visitante).

-- ============================================================
-- 2) Criar a conta de login da Nona (faça isso pela interface, não por SQL):
--
--    Supabase Dashboard → Authentication → Users → "Add user"
--      - Email: o e-mail que a Nona vai usar para logar
--      - Password: uma senha forte
--      - Marque "Auto Confirm User" para não precisar confirmar por e-mail
--
--    Depois disso, esse e-mail e senha são o login em
--    sagrada-e-profana.html → "Painel de Nona".
-- ============================================================
