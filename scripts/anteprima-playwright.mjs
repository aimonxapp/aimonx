// scripts/anteprima-playwright.mjs — guarda l'anteprima locale con un browser
// VERO e scrive tre cose che a occhio non si vedono. Giro W2, punto ⑥.
//
// ⛔ NON È UN TEST CHE PASSA O FALLISCE: è una MISURA. Stampa quel che trova e
// lascia il giudizio a chi legge. Un controllo che protesta sempre viene
// disattivato (CLAUDE.md, «Verifica di fine giro»).
//
// Le tre cose che cerca, e perché:
//  ① due screenshot (telefono e computer) — l'unica prova di «com'è venuto»
//     che non sia una descrizione a parole;
//  ② gli errori in console — una pagina rotta può sembrare intera;
//  ③ ⛔ OGNI richiesta verso un dominio diverso da quello locale. Questa è la
//     più importante: il vincolo del sito è «nessuna risorsa da server
//     esterni» (CLAUDE.md, condizioni del SITO FIGO), e un font o uno script
//     caricato da fuori dice a quel server chi visita aimonx.app. ⚠️ Misurato
//     nel giro W2: il tema di default di Pages carica anchor.js da cdnjs —
//     vedi WD26.
//
// Il browser è quello di Playwright, ⭐ separato da Chrome di Pier: scaricato
// in ~/Library/Caches/ms-playwright, non tocca il suo profilo né le sue schede.
//
// Uso:  node scripts/anteprima-playwright.mjs [url] [cartella-uscita]
// Le dipendenze stanno FUORI dal repo (vedi CLAUDE.md, «Comandi»): il repo è
// pubblico e node_modules non ci entra.

import { mkdir } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

// ⛔ Playwright si carica PER PERCORSO, e non con un `import` normale. Motivo
// misurato: le sue dipendenze stanno fuori dal repo (il repo è pubblico, e
// node_modules non ci entra), e un modulo ESM cerca i pacchetti risalendo
// dalla cartella DELLO SCRIPT — non dal cwd, e NODE_PATH per ESM non vale.
// Provato nel giro W2: con NODE_PATH l'avvio muore con ERR_MODULE_NOT_FOUND.
const playwrightPath = process.env.AIMONX_PLAYWRIGHT
  || join(homedir(), '.aimonx-web-tools', 'node_modules', 'playwright', 'index.js');
// ⚠️ Playwright è un modulo CommonJS: caricato così, le sue esportazioni
// arrivano sotto `.default`. Senza questo, `chromium` è `undefined`.
const pw = await import(pathToFileURL(playwrightPath).href);
const chromium = pw.chromium ?? pw.default?.chromium;

const url = process.argv[2] || 'http://127.0.0.1:4000/';
const outDir = process.argv[3] || join(homedir(), 'Desktop', 'aimonx-anteprima');
const host = new URL(url).hostname;

await mkdir(outDir, { recursive: true });

const browser = await chromium.launch();
const errori = [];
const esterne = [];
const tutte = [];

// ⚠️ I due formati non sono decorativi: la pagina si guarda dove la guardano
// le persone. 390×844 è un telefono corrente, 1440×900 un portatile.
const formati = [
  { nome: 'telefono', width: 390, height: 844, deviceScaleFactor: 2 },
  { nome: 'computer', width: 1440, height: 900, deviceScaleFactor: 2 },
];

for (const f of formati) {
  const ctx = await browser.newContext({
    viewport: { width: f.width, height: f.height },
    deviceScaleFactor: f.deviceScaleFactor,
  });
  const page = await ctx.newPage();

  page.on('console', (m) => {
    if (m.type() === 'error' || m.type() === 'warning')
      errori.push(`[${f.nome}] ${m.type()}: ${m.text()}`);
  });
  page.on('pageerror', (e) => errori.push(`[${f.nome}] pageerror: ${e.message}`));
  page.on('request', (r) => {
    const h = new URL(r.url()).hostname;
    tutte.push(`[${f.nome}] ${h}${new URL(r.url()).pathname}`);
    // ⛔ Il confronto è sull'HOST, non sull'inizio dell'indirizzo: un
    // `startsWith(url)` lascerebbe passare un dominio che comincia uguale.
    if (h !== host) esterne.push(`[${f.nome}] ${r.url()}`);
  });

  await page.goto(url, { waitUntil: 'networkidle' });
  const file = join(outDir, `anteprima-${f.nome}.png`);
  await page.screenshot({ path: file, fullPage: true });
  console.log(`① screenshot ${f.nome} (${f.width}×${f.height}) → ${file}`);
  await ctx.close();
}

await browser.close();

console.log(`\n② errori e avvisi in console: ${errori.length}`);
for (const e of errori) console.log(`   ${e}`);

console.log(`\n③ richieste totali: ${tutte.length} · verso un dominio ESTERNO a ${host}: ${esterne.length}`);
for (const e of esterne) console.log(`   ⛔ ${e}`);
if (esterne.length === 0) console.log('   ✅ nessuna: tutto servito dal dominio locale');

console.log('\n--- ogni richiesta, per intero ---');
for (const t of tutte) console.log(`   ${t}`);
