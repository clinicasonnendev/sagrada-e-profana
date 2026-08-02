# Sagrado e Profano

**Blog da Nona.**

> Vivemos em uma sociedade que ensina o que pensar antes mesmo de nos ensinar a pensar. Algumas ideias são tratadas como sagradas. Outras, como perigosas. Mas quase ninguém se pergunta quem decidiu essa divisão.

Sagrado e Profano é um blog pessoal que explora os territórios onde espiritualidade, filosofia, sexualidade, consciência, desejo e existência deixam de ser assuntos proibidos para se tornarem perguntas legítimas. Sem compromisso com dogmas, ideologias ou certezas confortáveis — apenas com o exercício de investigar aquilo que muitos preferem evitar.

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

Cada post pertence a um livro, tem status de `rascunho` ou `publicado`, e carrega metadados de SEO (`meta_titulo`, `meta_desc`, `slug`, `keyword`) além de tags temáticas.

## Estrutura do repositório

```
.
├── index.html               # página principal do site (renomeado de sagrada-e-profana.html
│                             #   para que o GitHub Pages sirva a homepage corretamente)
├── 404.html                 # página de erro
├── schema.sql                # schema Postgres/Supabase (livros, posts, comentários)
├── simbolos-schema.sql       # schema do bucket + tabela de símbolos decorativos
└── README.md
```

## Decoração de fundo ("flash decor")

O site espalha pequenos glifos decorativos (tingidos de roxo, ou dourado nas seções com `data-decor-accent`) atrás do conteúdo, adaptado do mesmo efeito usado no site Caos Astral. As imagens vêm da tabela `simbolos` no Supabase e são gerenciadas por **Nona, direto no painel** (aba "Símbolos"): upload de PNG/SVG, listagem e exclusão. Sem símbolos cadastrados, o efeito simplesmente não aparece — nada quebra.

Para habilitar, rode `simbolos-schema.sql` no SQL Editor do Supabase (cria o bucket `simbolos` e a tabela).

## Stack

- **Frontend:** HTML estático, publicado via GitHub Pages
- **Backend/dados:** [Supabase](https://supabase.com) (Postgres) — três tabelas:
  - `livros` — os seis livros do cânone (número, nome, epígrafe, se está selado)
  - `posts` — os textos, vinculados a um livro, com status, tags e SEO
  - `comentarios` — comentários dos leitores, com moderação (`pendente` / `aprovado`)

### Rodando o schema

No painel do Supabase: **SQL Editor → New query**, cole o conteúdo de `schema.sql` e rode. Isso cria as tabelas, habilita Row Level Security e popula os dados de exemplo (os seis livros e alguns posts/comentários seed).

## ⚠️ Aviso de segurança

O schema atual usa a **chave pública (publishable key)** direto no navegador, sem autenticação, e as políticas de RLS liberam **leitura e escrita públicas** em todas as tabelas — suficiente para prototipar, mas **não é seguro para produção**. Antes de divulgar o site publicamente:

- [ ] Adicionar Supabase Auth
- [ ] Restringir `INSERT`/`UPDATE`/`DELETE` de `livros` e `posts` apenas à Nona autenticada
- [ ] Manter a política de escrita pública apenas em `comentarios` (com moderação antes da publicação)

## Licença

_Não definida._
