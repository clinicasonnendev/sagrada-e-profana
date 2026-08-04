# Sagrada e Profana

**Blog & loja da Nona.**

> Vivemos em uma sociedade que ensina o que pensar antes mesmo de nos ensinar a pensar. Algumas ideias são tratadas como sagradas. Outras, como perigosas. Mas quase ninguém se pergunta quem decidiu essa divisão.

Sagrada e Profana é um blog pessoal que explora os territórios onde espiritualidade, filosofia, sexualidade, consciência, desejo e existência deixam de ser assuntos proibidos para se tornarem perguntas legítimas. Sem compromisso com dogmas, ideologias ou certezas confortáveis — apenas com o exercício de investigar aquilo que muitos preferem evitar.

🔗 Site: [clinicasonnendev.github.io/sagrada-e-profana](https://clinicasonnendev.github.io/sagrada-e-profana/)

---

## Sobre a Nona

Autora do blog. Não escreve para agradar — escreve para incomodar. Caminha na fronteira onde sagrado e profano deixam de fazer sentido como categorias separadas, questionando dogmas e desconfiando de certezas prontas. Neste espaço, espiritualidade divide a mesa com psicodélicos, filosofia conversa com erotismo, humor desafia a moral, religião encontra o ceticismo.

## Estrutura editorial

Os textos são organizados em **seis livros**, que espelham (e subvertem) o cânone bíblico:

| # | Livro | Epígrafe |
|---|-------|----------|
| I | Gênesis | *"No princípio era o silêncio, e o silêncio se chamava Nona."* |
| II | Êxodo | *"Toda travessia começa com a coragem de abandonar um deus antigo."* |
| III | Levítico | *"Os ritos do corpo também são orações."* |
| IV | Números | *"Contei os dias perdidos e ainda faltam mais do que os que restam."* |
| V | Deuteronômio | *"A lei que escrevo é só para quem ficar depois de mim."* |
| VI | Apocalipse | *"O véu ainda não se rasgou. Em breve."* — **selado**, ainda não publicado |

Cada post pertence a um livro e a uma categoria opcional, tem status de `rascunho` ou `publicado`, imagem de capa opcional, e carrega metadados de SEO (`meta_titulo`, `meta_desc`, `slug`, `keyword`) além de tags temáticas. **O conteúdo dos posts é totalmente aberto** — sem login nem paywall pra leitura.

## Painel administrativo

Acessível em `/admin` ou pelo botão "Painel de Nona". Único login: **Nona (via `julianamyrian@gmail.com`)**, protegido em duas camadas:

1. Supabase Auth (e-mail + senha).
2. Tabela `admins` — mesmo com login válido, só quem está cadastrado nessa tabela consegue ver o painel. Isso existe porque o mesmo sistema de autenticação já foi usado por um recurso de contas de leitor (removido depois — ver histórico abaixo), e sem essa segunda camada qualquer conta autenticada entraria como se fosse a Nona.

Abas do painel: Visão Geral, Estatísticas, Posts, Novo Post (editor), Livros, Categorias, Mídia, Símbolos, Produtos (loja), Comentários, SEO do Site, Configurações.

## Loja virtual

Vitrine em `/loja`, com abas "Todos / Físicos / Digitais". Vende dois tipos de produto:

- **Físicos** — japamalás, guias impressos, etc. Têm controle opcional de estoque (deixe em branco pra não controlar).
- **Digitais** — textos em PDF. Sem controle de estoque.

Cada produto tem seu próprio **Stripe Payment Link** (criado no Dashboard do Stripe, sem precisar de código), colado no campo "Link de pagamento" ao cadastrar o produto no painel (aba "Produtos"). O botão "Comprar" da loja leva direto pro checkout hospedado do Stripe.

- Produtos físicos: habilite "Collect customer addresses" no Payment Link, pra receber o endereço de entrega.
- Produtos digitais (PDF): use a entrega nativa de "digital product" do Stripe (anexa o arquivo ao próprio Payment Link) — o Stripe libera o download automaticamente após o pagamento, sem precisar de backend nosso.

## Imagens no editor de posts

Duas formas de upload, separadas:

1. **Imagem de capa** — campo logo abaixo do Título. Aparece nas listagens (início, dentro de um livro) e no topo da leitura do post. Uma por post, opcional.
2. **Imagens dentro do texto** — barra acima do campo "Conteúdo": **+ Enviar imagem** (upload novo, insere no cursor) e **Galeria de imagens** (reaproveita uma imagem já enviada antes, em qualquer post).

Ambas usam o mesmo bucket (`post-imagens`).

## Decoração de fundo ("flash decor")

O site espalha pequenos glifos decorativos (tingidos de roxo, ou dourado nas seções com `data-decor-accent`) atrás do conteúdo. As imagens vêm da tabela `simbolos` e são gerenciadas por Nona direto no painel (aba "Símbolos"). Sem símbolos cadastrados, o efeito simplesmente não aparece.

## Estrutura do repositório

```
.
├── index.html                       # site inteiro (SPA: front público + painel administrativo)
├── 404.html                         # redireciona rotas desconhecidas de volta pro index.html
│                                     #   (necessário pro roteamento da SPA funcionar no GitHub Pages)
├── schema.sql                       # schema base: livros, posts, categorias, comentarios
├── simbolos-schema.sql              # bucket + tabela dos símbolos decorativos
├── post-imagens-schema.sql          # bucket + tabela das imagens usadas dentro dos posts
├── posts-imagem-capa-migration.sql  # adiciona a coluna de imagem de capa aos posts
├── produtos-schema.sql              # bucket + tabela dos produtos da loja
├── leitores-schema.sql              # tabela `admins` (proteção do painel — ainda em uso;
│                                     #   a parte de `assinantes` é resíduo de uma feature removida)
├── fix-grants.sql                   # GRANT de leitura/escrita pros papéis anon/authenticated
├── fix-grants-admins.sql            # mesmo GRANT, só que pra tabela `admins` (faltou no anterior)
├── insert-admin.sql                 # cadastra um e-mail existente como admin do painel
└── README.md
```

## Setup do zero (ordem importa)

Se for reconstruir o projeto num Supabase novo, rode os scripts **nessa ordem**, tudo no SQL Editor:

1. `schema.sql`
2. `simbolos-schema.sql`
3. `post-imagens-schema.sql`
4. `posts-imagem-capa-migration.sql`
5. `produtos-schema.sql`
6. `leitores-schema.sql`
7. `fix-grants.sql` **e** `fix-grants-admins.sql` — sem isso, todas as leituras dão `permission denied` mesmo com RLS configurado certo (RLS e GRANT são camadas diferentes; ver aviso abaixo)
8. Crie a conta de admin em **Authentication → Users → Add user** (e-mail + senha)
9. Rode `insert-admin.sql`, trocando o e-mail pelo da conta criada no passo 8

No `index.html`, confira se `SUPABASE_URL` e `SUPABASE_KEY` (perto do topo do `<script>`) batem com o projeto — **use a chave legacy `anon` (formato JWT, começa com `eyJ...`)**, pega em Settings → API Keys → aba "Legacy anon, service_role API keys". O formato novo `sb_publishable_...` deu 401 em todas as chamadas neste projeto.

Se o site for servido numa subpasta do GitHub Pages (`usuario.github.io/repo/`, como este), confira também a constante `BASE_PATH` perto do roteador no `index.html` — precisa bater com o nome do repositório.

## Stack

- **Frontend:** HTML/CSS/JS estático (uma SPA num arquivo só), publicado via GitHub Pages.
- **Backend/dados:** [Supabase](https://supabase.com) (Postgres + Auth + Storage). Tabelas: `livros`, `categorias`, `posts`, `comentarios`, `simbolos`, `post_imagens`, `produtos`, `admins`.
- **Pagamento:** Stripe Payment Links (checkout hospedado, sem backend próprio).

## ⚠️ Avisos de segurança

**Escrita pública nas tabelas.** As políticas de RLS liberam leitura e escrita públicas na maioria das tabelas (`livros`, `posts`, `categorias`, `comentarios`, `simbolos`, `post_imagens`, `produtos`) — suficiente pra prototipar com o painel usando só a chave anônima no navegador, mas **não é seguro pra produção**. Antes de divulgar o site abertamente:
- [ ] Restringir `INSERT`/`UPDATE`/`DELETE` dessas tabelas só à Nona autenticada (a tabela `admins` já existe pra apoiar essa checagem)
- [ ] Manter escrita pública só em `comentarios`, com moderação antes de publicar

**RLS não é suficiente sozinho.** Toda tabela nova precisa de dois passos, não um: a política de RLS (quem pode ver quais linhas) **e** o `GRANT` de base (se o papel pode tocar na tabela). Esquecer o segundo gera erro `42501 permission denied`, mesmo com a política certa.

**Pagamentos.** Como usamos Payment Links do próprio Stripe (checkout hospedado, sem webhook customizado), a confirmação de pagamento é feita inteiramente pelo Stripe — não há o risco de "confirmação só no navegador" que existiria numa integração caseira.

## Licença

_Não definida._
