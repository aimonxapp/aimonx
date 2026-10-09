// scripts/peso.mjs — quanto pesa una pagina e quante richieste fa, col browser
// VERO. Giro W14, quando sulla landing sono entrate le schermate dell'app.
//
// ⛔ NON È UN TEST CHE PASSA O FALLISCE: è una MISURA, come le altre col
// browser. Stampa i numeri e lascia il giudizio a chi legge.
//
// ⭐ PERCHÉ DUE MOMENTI E NON UN TOTALE SOLO. Le immagini sotto la parte alta
// sono `loading="lazy"`: il browser le chiede quando ci si avvicina, non
// all'apertura. Un totale unico direbbe «la pagina pesa X» e nasconderebbe la
// sola cosa che conta per chi apre il sito — quanto arriva PRIMA di poter
// leggere. Quindi:
//   ① ALL'APERTURA — pagina caricata, senza toccare niente;
//   ② DOPO AVER SCORSO FINO IN FONDO — tutto quel che la pagina può chiedere.
//
// ⭐ E LO SPOSTAMENTO: «nessuno spostamento della pagina mentre le immagini
// arrivano» si misura, non si guarda. Il browser tiene il conto da sé
// (`layout-shift`, quello di Core Web Vitals): la somma deve restare 0.
// ⚠️ Per vederlo davvero le immagini sono RALLENTATE apposta di 400 ms: in
// locale arrivano in un millisecondo, e una pagina che salta non farebbe in
// tempo a saltare.
//
// ⚠️ I BYTE SONO QUELLI DEL CORPO DELLA RISPOSTA, così come il server li
// manda. `jekyll serve` NON comprime, GitHub Pages sì (HTML, CSS, SVG): sul
// sito vero testo e fogli pesano meno di quel che si legge in locale. Le
// immagini no — WebP e PNG sono già compressi, e sono loro la voce che cambia.
//
// Uso:  node scripts/peso.mjs [url ...]      (difetto: http://127.0.0.1:4000/)

import { homedir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

// ⛔ Playwright si carica PER PERCORSO: stessa ragione e stesso commento di
// scripts/anteprima-playwright.mjs.
const playwrightPath = process.env.AIMONX_PLAYWRIGHT
  || join(homedir(), '.aimonx-web-tools', 'node_modules', 'playwright', 'index.js');
const pw = await import(pathToFileURL(playwrightPath).href);
const chromium = pw.chromium ?? pw.default?.chromium;

const indirizzi = process.argv.slice(2);
if (indirizzi.length === 0) indirizzi.push('http://127.0.0.1:4000/');

// ⚠️ Il telefono è a 3×, non a 2×: è la densità degli iPhone correnti, ed è
// quella che fa scegliere al browser il file più grande di ogni `srcset`.
const formati = [
  { nome: 'telefono', width: 390, height: 844, deviceScaleFactor: 3 },
  { nome: 'computer', width: 1440, height: 900, deviceScaleFactor: 2 },
];

const kb = (n) => `${(n / 1024).toFixed(1)} KB`;
const browser = await chromium.launch();

for (const url of indirizzi) {
  console.log(`\n=== ${url} ===`);
  for (const f of formati) {
    const ctx = await browser.newContext({
      viewport: { width: f.width, height: f.height },
      deviceScaleFactor: f.deviceScaleFactor,
    });
    const page = await ctx.newPage();

    const risposte = [];
    page.on('response', async (r) => {
      let peso = 0;
      try { peso = (await r.body()).length; } catch { /* risposta senza corpo */ }
      risposte.push({ url: r.url(), tipo: r.request().resourceType(), stato: r.status(), peso });
    });
    await page.route('**/*.{webp,png,jpg,jpeg,svg}', async (rotta) => {
      await new Promise((ok) => setTimeout(ok, 400));
      await rotta.continue();
    });
    await page.addInitScript(() => {
      window.__spostamento = 0;
      new PerformanceObserver((lista) => {
        for (const v of lista.getEntries()) if (!v.hadRecentInput) window.__spostamento += v.value;
      }).observe({ type: 'layout-shift', buffered: true });
    });

    await page.goto(url, { waitUntil: 'networkidle' });
    const apertura = risposte.length;
    const pesoApertura = risposte.reduce((s, r) => s + r.peso, 0);
    const immApertura = risposte.filter((r) => r.tipo === 'image');

    // Si scorre a passi di mezzo schermo: un salto solo in fondo lascerebbe
    // le immagini di mezzo mai «vicine», e quindi mai chieste.
    const alta = await page.evaluate(() => document.documentElement.scrollHeight);
    for (let y = 0; y <= alta; y += Math.round(f.height / 2)) {
      await page.evaluate((v) => window.scrollTo(0, v), y);
      await page.waitForTimeout(120);
    }
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(600);

    // ⚠️ I conti si FERMANO QUI: la misura delle immagini sgranate, più sotto,
    // riapre ogni file, e quelle richieste sono sue e non della pagina.
    const tutte = risposte.length;
    const pesoTutto = risposte.reduce((s, r) => s + r.peso, 0);
    const imm = risposte.filter((r) => r.tipo === 'image');
    const spostamento = await page.evaluate(() => window.__spostamento);
    const nonArrivate = risposte.filter((r) => r.stato >= 400);
    // ⚠️ Un'immagine che il browser deve INGRANDIRE è sfocata: si confronta la
    // larghezza vera del FILE scelto con i pixel fisici che deve riempire.
    // ⛔ Il file si riapre e si misura, e non si chiede a `naturalWidth`: con
    // `srcset` quel numero è già diviso per la densità, cioè dice quanto
    // l'immagine è larga in pagina e non quanti pixel ha. Provato: la prima
    // versione di questa misura segnalava sgranate TUTTE le schermate.
    const sgranate = await page.evaluate(async (dsf) => {
      const esito = [];
      for (const i of document.images) {
        if (!i.currentSrc || i.currentSrc.endsWith('.svg')) continue;
        const pixel = await createImageBitmap(await (await fetch(i.currentSrc)).blob());
        const serve = Math.round(i.getBoundingClientRect().width * dsf);
        if (pixel.width < serve * 0.75) esito.push({ file: i.currentSrc.split('/').pop(), ha: pixel.width, serve });
      }
      return esito;
    }, f.deviceScaleFactor);

    console.log(`[${f.nome} ${f.width}×${f.height} @${f.deviceScaleFactor}×]`);
    console.log(`  ① all'apertura:        ${apertura} richieste · ${kb(pesoApertura)} · di cui immagini ${immApertura.length} (${kb(immApertura.reduce((s, r) => s + r.peso, 0))})`);
    console.log(`  ② scorsa fino in fondo: ${tutte} richieste · ${kb(pesoTutto)} · di cui immagini ${imm.length} (${kb(imm.reduce((s, r) => s + r.peso, 0))})`);
    console.log(`  spostamento della pagina (layout-shift, somma): ${spostamento.toFixed(4)}`);
    console.log(`  risposte con errore: ${nonArrivate.length} · immagini che il browser deve ingrandire oltre un terzo: ${sgranate.length}`);
    for (const r of nonArrivate) console.log(`     ⛔ ${r.stato} ${r.url}`);
    for (const s of sgranate) console.log(`     ⚠️ ${s.file}: il file è largo ${s.ha} px, ne servono ${s.serve}`);
    for (const r of imm) console.log(`     · ${kb(r.peso).padStart(9)}  ${new URL(r.url).pathname}`);
    await ctx.close();
  }
}

await browser.close();
