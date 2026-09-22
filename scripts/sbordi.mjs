// scripts/sbordi.mjs — la pagina sborda dallo schermo? Giro W9.
//
// ⛔ NON È UN TEST CHE PASSA O FALLISCE: è una MISURA, come contrasto.mjs e
// anteprima-playwright.mjs. Stampa cosa sborda e di quanto, e il giudizio è di
// chi legge (CLAUDE.md, «Verifica di fine giro»).
//
// ⭐ PERCHÉ ESISTE: fino al giro W8 gli sbordi si guardavano negli screenshot,
// cioè a occhio, a due larghezze. ⚠️ Uno sbordo non si vede sempre: il browser
// aggiunge una barra di scorrimento orizzontale e la pagina resta leggibile —
// finché non la si apre su un telefono, dove quella barra non c'è e il testo
// esce dal bordo. E soprattutto non si vede alle larghezze che nessuno prova.
// ⛔ Con quattro pagine, guardare a occhio otto screenshot per ogni ritocco non
// è più un metodo: è una cosa che prima o poi si salta.
//
// COSA MISURA, per ogni pagina e per ogni larghezza:
//   ① se il documento è più largo della finestra (lo sbordo vero e proprio);
//   ② QUALE elemento sporge, e di quanto — perché «sborda» senza il colpevole
//      è una segnalazione che costa mezz'ora a ogni giro.
// ⚠️ Gli elementi dichiarati `aria-hidden` o nascosti NON sono esentati: se si
// vedono e sporgono, sporgono.
//
// Uso:  node scripts/sbordi.mjs <url> [url...]
// Le dipendenze stanno FUORI dal repo (CLAUDE.md, «Comandi»): il repo è
// pubblico e node_modules non ci entra.

import { homedir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

// ⛔ Playwright si carica PER PERCORSO, non con un `import` normale: le sue
// dipendenze stanno fuori dal repo, e un modulo ESM cerca i pacchetti
// risalendo dalla cartella DELLO SCRIPT. Stessa ragione, stesso rimedio e
// stesso commento di scripts/anteprima-playwright.mjs.
const playwrightPath = process.env.AIMONX_PLAYWRIGHT
  ?? join(homedir(), '.aimonx-web-tools', 'node_modules', 'playwright', 'index.js');
const pw = await import(pathToFileURL(playwrightPath).href);
const chromium = pw.chromium ?? pw.default?.chromium;

const urls = process.argv.slice(2);
if (urls.length === 0) {
  console.error('Uso: node scripts/sbordi.mjs <url> [url...]');
  process.exit(2);
}

// ⚠️ Le larghezze non sono a caso: 360 è il telefono piccolo che si trova
// ancora in giro, 390 l'iPhone di oggi, 768 il tablet in verticale, 880 il
// punto in cui i fogli di stile cambiano impaginazione (le `@media` di
// b.scss e testo.scss), 1440 il portatile, 1920 lo schermo grande.
// ⛔ 880 c'è perché è la soglia: un guaio di impaginazione si nasconde
// esattamente lì, un pixel prima o un pixel dopo il cambio.
const LARGHEZZE = [360, 390, 768, 879, 880, 1024, 1440, 1920];

const browser = await chromium.launch();
let totale = 0;

for (const url of urls) {
  const page = await browser.newPage();
  await page.goto(url, { waitUntil: 'networkidle' });
  const righe = [];
  for (const width of LARGHEZZE) {
    await page.setViewportSize({ width, height: 900 });
    // ⚠️ Un momento di respiro: le misure in `clamp()` si ricalcolano al
    // ridimensionamento, e leggerle troppo presto darebbe i numeri di prima.
    await page.waitForTimeout(120);
    const esito = await page.evaluate(() => {
      const w = document.documentElement.clientWidth;
      const colpevoli = [];
      for (const el of document.querySelectorAll('body *')) {
        const r = el.getBoundingClientRect();
        if (r.width === 0 && r.height === 0) continue;
        const oltre = Math.round(r.right - w);
        // ⚠️ 1 px di tolleranza: gli arrotondamenti del browser sui bordi e
        // sulle ombre valgono meno di un pixel, e segnalarli sarebbe il
        // rumore che fa smettere di leggere un controllo.
        if (oltre > 1) {
          colpevoli.push({
            chi: el.tagName.toLowerCase() + (el.className && typeof el.className === 'string'
              ? '.' + el.className.trim().split(/\s+/).join('.') : ''),
            oltre,
          });
        }
      }
      return { doc: document.documentElement.scrollWidth, finestra: w, colpevoli };
    });
    const sborda = esito.doc > esito.finestra + 1;
    const n = esito.colpevoli.length;
    totale += n + (sborda ? 1 : 0);
    if (sborda || n > 0) {
      righe.push(`  ⛔ ${width}px · documento ${esito.doc}px su finestra ${esito.finestra}px`);
      // Solo i cinque peggiori: un elemento che sporge se ne porta dietro i figli.
      esito.colpevoli.sort((a, b) => b.oltre - a.oltre).slice(0, 5)
        .forEach((c) => righe.push(`       ${c.chi} — ${c.oltre}px oltre il bordo`));
    } else {
      righe.push(`  ✅ ${width}px · documento ${esito.doc}px, niente oltre il bordo`);
    }
  }
  console.log(`\n=== ${url} ===`);
  righe.forEach((r) => console.log(r));
  await page.close();
}

await browser.close();
console.log(`\n→ sbordi trovati in totale: ${totale}`);
