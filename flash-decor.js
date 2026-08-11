/**
 * flash-decor.js — efeito de decoração fractal com imagens (portável)
 * ---------------------------------------------------------------
 * Espalha uma pool de imagens (vindas do Supabase) em várias "passagens"
 * decrescentes de tamanho por trás do conteúdo de cada seção da página,
 * tipo um fractal de flash de tatuagem: cada passagem preenche os buracos
 * deixados pela anterior, sem sobrepor nada e sem cobrir texto/botões/forms.
 *
 * Zero dependências além do supabase-js (só pra fazer um fetch REST simples
 * — na verdade nem precisa do SDK, é fetch puro, ver getPool() abaixo).
 * Se a tabela estiver vazia ou não existir ainda, não faz nada, sem quebrar
 * o resto da página.
 *
 * ============================== USO ==============================
 * 1. Suba assets/flash-decor.js no seu projeto.
 * 2. Rode o setup.sql (neste kit) no SQL Editor do seu Supabase.
 * 3. Antes de carregar este script, defina a config:
 *
 *   <script>
 *     window.FLASH_DECOR_CONFIG = {
 *       supabaseUrl: 'https://SEU-PROJETO.supabase.co',
 *       supabaseKey: 'sb_publishable_....',   // chave publicável (anon)
 *     };
 *   </script>
 *   <script src="assets/flash-decor.js" defer></script>
 *
 * 4. Use admin-flash-decor.html (neste kit) pra fazer upload das imagens.
 * 5. Pronto — toda tag <section> da página ganha o efeito automaticamente.
 *    Pra excluir uma seção específica, adicione o atributo data-no-decor.
 *    Pra usar a paleta de "destaque" numa seção (tingimento diferente,
 *    se configurado), adicione data-decor-accent nela ou num pai dela.
 *
 * ============================ CONFIG ================================
 * Todas as chaves de window.FLASH_DECOR_CONFIG são opcionais, exceto
 * supabaseUrl/supabaseKey. Defaults abaixo:
 *
 *   table          : 'flash_decor_images'   nome da tabela no Supabase
 *   imageColumn    : 'image_url'            coluna com a URL pública da imagem
 *   decorColumn    : 'decor'                coluna boolean, filtra o que entra na pool
 *   targetSelector : 'section'              quais elementos ganham o efeito
 *   excludeAttr    : 'data-no-decor'         atributo que exclui um elemento
 *   accentAttr     : 'data-decor-accent'    atributo que ativa o tingimento de destaque
 *   filterNormal   : null                    CSS filter (string) aplicado nas imagens normais
 *   filterAccent   : null                    CSS filter (string) nas imagens em seção de destaque
 *   cacheKey       : 'flash_decor_pool_v1'   chave usada no sessionStorage
 *   passes         : ver PASSES_DEFAULT abaixo — 5 passagens fractais
 *
 * Exemplo de tingimento (pra imitar o efeito "tom osso / tom vermelho" do
 * Caos Astral original, artes de linha escuras sobre fundo claro/transparente):
 *   filterNormal: 'invert(94%) sepia(6%) saturate(280%) hue-rotate(345deg) brightness(0.92) contrast(0.9)',
 *   filterAccent: 'invert(14%) sepia(64%) saturate(2800%) hue-rotate(347deg) brightness(85%) contrast(92%)',
 * ====================================================================
 */
(function () {
  'use strict';

  const CFG = Object.assign({
    supabaseUrl: null,
    supabaseKey: null,
    table: 'flash_decor_images',
    imageColumn: 'image_url',
    decorColumn: 'decor',
    targetSelector: 'section',
    excludeAttr: 'data-no-decor',
    accentAttr: 'data-decor-accent',
    filterNormal: null,
    filterAccent: null,
    cacheKey: 'flash_decor_pool_v1',
  }, window.FLASH_DECOR_CONFIG || {});

  if (!CFG.supabaseUrl || !CFG.supabaseKey) {
    console.warn('[flash-decor] window.FLASH_DECOR_CONFIG.supabaseUrl / supabaseKey não configurados — efeito desligado.');
    return;
  }

  // ── Pool ────────────────────────────────────────────────────
  async function getPool() {
    // Só usa cache de sessão se ele tiver pelo menos 1 imagem. Um pool
    // vazio (tabela ainda sem dado, ou erro numa visita anterior) NUNCA
    // é cacheado como resultado válido — evita ficar "travado" sem
    // decoração depois que as imagens forem cadastradas.
    const cached = sessionStorage.getItem(CFG.cacheKey);
    if (cached) {
      try {
        const parsed = JSON.parse(cached);
        if (Array.isArray(parsed) && parsed.length > 0) return parsed;
      } catch {}
    }
    try {
      const url = `${CFG.supabaseUrl}/rest/v1/${CFG.table}?select=${CFG.imageColumn}&${CFG.decorColumn}=eq.true`;
      const r = await fetch(url, {
        headers: { apikey: CFG.supabaseKey, Authorization: `Bearer ${CFG.supabaseKey}` },
        cache: 'no-store'
      });
      if (!r.ok) throw new Error('tabela ainda não existe, sem acesso, ou vazia');
      const rows = await r.json();
      const pool = (Array.isArray(rows) ? rows : [])
        .map(row => row[CFG.imageColumn])
        .filter(Boolean);
      if (pool.length > 0) sessionStorage.setItem(CFG.cacheKey, JSON.stringify(pool));
      return pool;
    } catch (e) {
      return []; // sem tabela/dado ainda, decoração fica desligada, sem quebrar nada.
    }
  }

  // ── Utilitários ─────────────────────────────────────────────
  function shuffle(arr) {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }
  function rnd(a, b) { return a + Math.random() * (b - a); }

  // ── Passagens fractais ───────────────────────────────────────
  // Cada passagem: [raio de colisão px, largura CSS, faixa de opacidade, quantidade base]
  const OVERLAP = 1.4;
  const PASSES_DEFAULT = [
    [140, 'clamp(150px,20vw,280px)', [0.05, 0.08], 3],
    [85, 'clamp(90px,12vw,165px)', [0.05, 0.07], 5],
    [50, 'clamp(50px,7vw,95px)', [0.04, 0.06], 9],
    [27, 'clamp(26px,4vw,54px)', [0.04, 0.06], 14],
    [14, 'clamp(13px,2vw,26px)', [0.03, 0.05], 20],
  ];
  const PASSES = CFG.passes || PASSES_DEFAULT;

  function overlaps(placed, cx, cy, r) {
    for (const p of placed) {
      const dx = cx - p.cx, dy = cy - p.cy;
      if (Math.sqrt(dx * dx + dy * dy) < (r + p.r) * OVERLAP) return true;
    }
    return false;
  }

  function inGuard(cx, cy, r, guardRects, elLeft, elTop) {
    for (const g of guardRects) {
      if ((elLeft + cx) > g.left - r && (elLeft + cx) < g.right + r &&
          (elTop + cy) > g.top - r && (elTop + cy) < g.bottom + r) return true;
    }
    return false;
  }

  function runPass(el, pool, placed, passR, passCss, opRange, nBase, guardRects) {
    const rect = el.getBoundingClientRect();
    const W = rect.width || el.offsetWidth || window.innerWidth;
    const H = rect.height || el.offsetHeight || 400;
    if (W < 10 || H < 10) return;

    const elLeft = rect.left + window.scrollX;
    const elTop = rect.top + window.scrollY;

    const area = W * H;
    const refArea = 960 * 500;
    const n = Math.round(nBase * Math.min(2.2, Math.max(0.4, area / refArea)));
    const imgs = shuffle(pool).slice(0, Math.min(n * 3, pool.length));
    let placedCount = 0;

    const accent = el.closest(`[${CFG.accentAttr}]`) !== null;
    const tintCss = accent
      ? (CFG.filterAccent ? `filter:${CFG.filterAccent};` : '')
      : (CFG.filterNormal ? `filter:${CFG.filterNormal};` : '');

    for (const src of imgs) {
      if (placedCount >= n) break;
      const MAX = 200;
      for (let t = 0; t < MAX; t++) {
        const cx = rnd(passR, W - passR);
        const cy = rnd(passR, H - passR);
        if (overlaps(placed, cx, cy, passR)) continue;
        if (guardRects.length && inGuard(cx, cy, passR, guardRects, elLeft, elTop)) continue;

        placed.push({ cx, cy, r: passR });
        placedCount++;

        const img = document.createElement('img');
        img.src = src;
        img.alt = '';
        img.loading = 'lazy';
        img.decoding = 'async';

        const rot = rnd(-35, 35).toFixed(1);
        const op = (opRange[0] + Math.random() * (opRange[1] - opRange[0])).toFixed(3);

        img.style.cssText = [
          'position:absolute',
          'pointer-events:none',
          'user-select:none',
          tintCss,
          'height:auto',
          'z-index:0',
          `width:${passCss}`,
          `opacity:${op}`,
          `left:${((cx / W) * 100).toFixed(2)}%`,
          `top:${((cy / H) * 100).toFixed(2)}%`,
          `transform:translate(-50%,-50%) rotate(${rot}deg)`,
        ].join(';');

        el.appendChild(img);
        break;
      }
    }
  }

  // ── Guard rects, evita cobrir imagem real, formulário ou botão ──
  function getGuardRects() {
    const guards = [];
    document.querySelectorAll(
      'img:not([data-decor]), svg, form, input, textarea, select, button, a, .btn, .card'
    ).forEach(el => {
      const r = el.getBoundingClientRect();
      if (r.width > 40 && r.height > 20) {
        guards.push({
          top: r.top + window.scrollY - 14,
          left: r.left + window.scrollX - 14,
          bottom: r.bottom + window.scrollY + 14,
          right: r.right + window.scrollX + 14,
        });
      }
    });
    return guards;
  }

  // ── Init ────────────────────────────────────────────────────
  async function init() {
    const pool = await getPool();
    if (!pool.length) return; // sem imagem cadastrada ainda, não faz nada

    await new Promise(r => setTimeout(r, 400));
    const guards = getGuardRects();

    requestAnimationFrame(() => {
      document.querySelectorAll(CFG.targetSelector).forEach(el => {
        if (el.hasAttribute(CFG.excludeAttr)) return;
        const pos = getComputedStyle(el).position;
        if (pos === 'static') el.style.position = 'relative';
        if (getComputedStyle(el).overflow === 'visible') el.style.overflow = 'hidden';

        const placed = [];
        PASSES.forEach(([r, css, opRange, nBase]) => {
          runPass(el, pool, placed, r, css, opRange, nBase, guards);
        });
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
