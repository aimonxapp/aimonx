// scripts/badge.mjs — il badge dell'App Store sta dentro le regole di Apple?
// Giro W12.
//
// ⛔ NON È UN TEST CHE PASSA O FALLISCE: è una MISURA, come sbordi.mjs e
// tastiera.mjs. Stampa i numeri e lascia il giudizio a chi legge.
//
// ⭐ PERCHÉ ESISTE: le regole di Apple sul badge (App Store Marketing
// Guidelines) sono numeri — altezza minima 40 px, spazio libero intorno pari
// ad almeno un quarto dell'altezza — e un numero scritto in un commento del
// CSS resta vero finché nessuno tocca la riga accanto. ⛔ Lo spazio libero in
// particolare NON lo decide il badge: lo decide chi gli sta vicino, cioè
// regole scritte per altri elementi, che cambiano a ogni larghezza.
//
// COSA MISURA, sulla pagina che ha il badge, a otto larghezze:
//   ① quanti badge ci sono (Apple: uno per pagina);
//   ② altezza e larghezza a schermo, e se le proporzioni sono quelle del file;
//   ③ lo SPAZIO LIBERO: la distanza dal badge al testo o alla grafica più
//      vicini, sopra, sotto, a sinistra e a destra, contro il quarto d'altezza;
//   ④ che il CSS non lo modifichi: filtro, opacità, rotazione, ombra, bordo,
//      angoli, transizione — a riposo e col mouse sopra.
// ⚠️ ③ guarda l'INCHIOSTRO, non le scatole: di un paragrafo conta dove
// arrivano le lettere, non il suo margine — è quello che l'occhio vede vicino
// al badge. Il bordo della finestra non è grafica e si stampa a parte.
// ⚠️ Il contorno del fuoco da tastiera NON entra in ③: c'è solo mentre il
// badge ha il fuoco. È dichiarato in `assets/css/b.scss` come scelta al limite.
//
// Uso:  node scripts/badge.mjs <url> [url...]

import { homedir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

// ⛔ Playwright si carica PER PERCORSO: le sue dipendenze stanno fuori dal
// repo. Stessa ragione e stesso commento di scripts/anteprima-playwright.mjs.
const playwrightPath = process.env.AIMONX_PLAYWRIGHT
  ?? join(homedir(), '.aimonx-web-tools', 'node_modules', 'playwright', 'index.js');
const pw = await import(pathToFileURL(playwrightPath).href);
const chromium = pw.chromium ?? pw.default?.chromium;

const urls = process.argv.slice(2);
if (urls.length === 0) { console.error('Uso: node scripts/badge.mjs <url> [url...]'); process.exit(2); }

// Le stesse otto di scripts/sbordi.mjs, per la stessa ragione.
const LARGHEZZE = [360, 390, 768, 879, 880, 1024, 1440, 1920];
// ⛔ Il badge si riconosce dal NOME DEL FILE di Apple, non da una classe
// nostra: una classe la può portare qualunque cosa, il file no.
const SELETTORE = 'img[src*="download-on-the-app-store"]';

const misura = (selettore) => {
  const badge = [...document.querySelectorAll(selettore)];
  if (badge.length === 0) return { quanti: 0 };
  const img = badge[0];
  const link = img.closest('a');
  const b = img.getBoundingClientRect();
  const quarto = b.height / 4;

  // L'inchiostro degli altri: le righe di testo e le immagini, non le scatole.
  const inchiostro = [];
  const cammina = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  for (let n = cammina.nextNode(); n; n = cammina.nextNode()) {
    if (!n.textContent.trim() || (link ?? img).contains(n)) continue;
    const s = getComputedStyle(n.parentElement);
    if (s.visibility === 'hidden' || s.display === 'none') continue;
    const r = document.createRange(); r.selectNodeContents(n);
    for (const q of r.getClientRects()) if (q.width > 0 && q.height > 0)
      inchiostro.push({ q, chi: n.parentElement.tagName.toLowerCase() + '«' + n.textContent.trim().slice(0, 24) + '»' });
  }
  for (const el of document.querySelectorAll('img, svg')) {
    if (el === img) continue;
    const q = el.getBoundingClientRect();
    if (q.width > 0 && q.height > 0) inchiostro.push({ q, chi: el.tagName.toLowerCase() + '.' + (el.getAttribute('class') ?? '') });
  }

  // La distanza più corta in ciascun verso, fra chi sta nella stessa fascia
  // del badge ALLARGATA del quarto: è lì dentro che niente deve entrare.
  const vicino = { sopra: null, sotto: null, sinistra: null, destra: null };
  const prova = (verso, d, chi) => { if (d >= -0.5 && (vicino[verso] === null || d < vicino[verso].d)) vicino[verso] = { d: Math.round(d * 10) / 10, chi }; };
  let dentro = 0;
  for (const { q, chi } of inchiostro) {
    const inColonna = q.right > b.left - quarto && q.left < b.right + quarto;
    const inRiga = q.bottom > b.top - quarto && q.top < b.bottom + quarto;
    if (inColonna && q.bottom <= b.top + 0.5) prova('sopra', b.top - q.bottom, chi);
    if (inColonna && q.top >= b.bottom - 0.5) prova('sotto', q.top - b.bottom, chi);
    if (inRiga && q.right <= b.left + 0.5) prova('sinistra', b.left - q.right, chi);
    if (inRiga && q.left >= b.right - 0.5) prova('destra', q.left - b.right, chi);
    if (inColonna && inRiga) dentro++;
  }

  const stile = (el) => {
    const s = getComputedStyle(el);
    const fuori = [];
    if (s.filter !== 'none') fuori.push(`filter ${s.filter}`);
    if (s.opacity !== '1') fuori.push(`opacity ${s.opacity}`);
    if (s.transform !== 'none') fuori.push(`transform ${s.transform}`);
    if (s.boxShadow !== 'none') fuori.push(`box-shadow ${s.boxShadow}`);
    if (s.borderTopWidth !== '0px' || s.borderLeftWidth !== '0px') fuori.push('border');
    if (s.borderTopLeftRadius !== '0px') fuori.push(`border-radius ${s.borderTopLeftRadius}`);
    if (s.mixBlendMode !== 'normal') fuori.push(`mix-blend-mode ${s.mixBlendMode}`);
    if (!['none', 'running', 'paused', ''].includes(s.animationName) ) fuori.push(`animation ${s.animationName}`);
    if (parseFloat(s.transitionDuration) > 0) fuori.push(`transition ${s.transitionDuration}`);
    return fuori;
  };

  return {
    quanti: badge.length,
    alt: Math.round(b.height * 100) / 100, larg: Math.round(b.width * 100) / 100,
    proporzione: b.width / b.height, naturale: img.naturalWidth / img.naturalHeight,
    quarto: Math.round(quarto * 10) / 10, vicino, dentro,
    bordoFinestra: Math.round(b.left * 10) / 10,
    ritocchi: [...stile(img), ...(link ? stile(link) : [])],
    href: link?.getAttribute('href') ?? null, testoAlt: img.alt, sorgente: img.currentSrc,
  };
};

const browser = await chromium.launch();
let guasti = 0;

for (const url of urls) {
  console.log(`\n=== ${url} ===`);
  const page = await browser.newPage();
  await page.goto(url, { waitUntil: 'networkidle' });
  for (const width of LARGHEZZE) {
    await page.setViewportSize({ width, height: 900 });
    await page.waitForTimeout(120);
    const m = await page.evaluate(misura, SELETTORE);
    if (m.quanti === 0) { console.log(`  ${width}px · nessun badge in questa pagina`); continue; }

    // ④ col mouse sopra: stessi stili di prima, o è un effetto.
    await page.hover(SELETTORE);
    await page.waitForTimeout(60);
    const sopra = await page.evaluate(misura, SELETTORE);
    await page.mouse.move(0, 0);

    const note = [];
    if (m.quanti !== 1) note.push(`⛔ ${m.quanti} badge (Apple: uno per pagina)`);
    if (m.alt < 40) note.push('⛔ sotto i 40 px');
    if (Math.abs(m.proporzione - m.naturale) > 0.01) note.push(`⛔ proporzioni ${m.proporzione.toFixed(3)} invece di ${m.naturale.toFixed(3)}`);
    for (const v of ['sopra', 'sotto', 'sinistra', 'destra'])
      if (m.vicino[v] && m.vicino[v].d < m.quarto) note.push(`⛔ ${v}: ${m.vicino[v].chi} a ${m.vicino[v].d} px`);
    if (m.ritocchi.length) note.push(`⛔ ritocchi: ${m.ritocchi.join(', ')}`);
    if (sopra.ritocchi.length || sopra.alt !== m.alt) note.push('⛔ cambia col mouse sopra');
    guasti += note.length;

    const d = (v) => (m.vicino[v] ? `${m.vicino[v].d}` : 'niente');
    console.log(`  ${String(width).padStart(4)}px · badge ${m.alt}×${m.larg} px · quarto ${m.quarto} px · ` +
                `libero: sopra ${d('sopra')} · sotto ${d('sotto')} · sinistra ${d('sinistra')} · destra ${d('destra')} ` +
                `(bordo finestra a ${m.bordoFinestra} px)  ${note.length ? note.join(' · ') : '✅'}`);
    if (width === LARGHEZZE[0]) {
      console.log(`         sopra c'è ${m.vicino.sopra?.chi ?? '—'} · sotto c'è ${m.vicino.sotto?.chi ?? '—'}`);
      console.log(`         link → ${m.href} · alt «${m.testoAlt}» · file ${new URL(m.sorgente).host}${new URL(m.sorgente).pathname}`);
    }
  }
  await page.close();
}

await browser.close();
console.log(`\n→ scostamenti dalle regole di Apple trovati: ${guasti}`);
