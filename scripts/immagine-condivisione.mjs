// scripts/immagine-condivisione.mjs — l'immagine che si vede quando qualcuno
// incolla un indirizzo di aimonx.app in un messaggio. Giro W10.
//
// ⛔ PERCHÉ UNO SCRIPT E NON UN FILE DISEGNATO UNA VOLTA: un PNG nel repo è un
// numero copiato a mano, in forma di pixel. Nessuno sa più con quali colori,
// quale corpo e quale logo è stato fatto, e il giorno che la tavolozza cambia
// nessuno se ne accorge. ⭐ Così invece l'immagine si RIFÀ con un comando, e
// i colori sono gli stessi nomi di `assets/css/comune.scss`.
//
// ⛔ LE PAROLE SONO SOLO QUELLE APPROVATE, e sono la riga del piede della
// bozza della landing spezzata in due: «AIMONX» e «the technical log for
// sport shooters». ⚠️ Spezzare una frase per impaginarla è la regola che Pier
// ha scritto il 22/09/2026, e vale qui come nella pagina.
// ⚠️ MA QUI IL CONTROLLO NON ARRIVA: `scripts/testo-approvato.sh` legge testo,
// non pixel. ⛔ Quindi chi cambia queste due stringhe non ha nessuna rete
// sotto, e deve saperlo — è il motivo per cui stanno in cima, da sole.
//
// ⛔ NIENTE SAGOME, NIENTE ARMI, NIENTE iPHONE, NIENTE SCHERMATE FINTE: giro
// W10 §2④, ed è la stessa linea del W6 sulla parte alta della landing.
//
// Uso:  node scripts/immagine-condivisione.mjs [file-di-uscita]
// Difetto: assets/img/condivisione-1200x630.png

import { writeFile, mkdir } from 'node:fs/promises';
import { homedir, tmpdir } from 'node:os';
import { join, dirname, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

// ⛔ Playwright si carica PER PERCORSO: le sue dipendenze stanno fuori dal repo
// (il repo è pubblico, node_modules non ci entra). Stessa ragione e stesso
// commento di scripts/anteprima-playwright.mjs.
const playwrightPath = process.env.AIMONX_PLAYWRIGHT
  ?? join(homedir(), '.aimonx-web-tools', 'node_modules', 'playwright', 'index.js');
const pw = await import(pathToFileURL(playwrightPath).href);
const chromium = pw.chromium ?? pw.default?.chromium;

const REPO = resolve(dirname(new URL(import.meta.url).pathname), '..');
const uscita = resolve(process.argv[2] ?? join(REPO, 'assets/img/condivisione-1200x630.png'));

// ⚠️ 1200×630 non è una misura a gusto: è quella che Open Graph chiede per la
// scheda grande, ed è il rapporto 1,91:1 che i messaggi ritagliano senza
// tagliare niente.
const L = 1200, A = 630;

// I colori sono quelli di assets/css/comune.scss (tavolozza dell'app §2 e §4b).
const pagina = `<!DOCTYPE html><html><head><meta charset="utf-8"><style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    width: ${L}px; height: ${A}px; overflow: hidden;
    background: #0F3625;
    background-image: linear-gradient(145deg, #1A4A33 0%, #0F3625 62%);
    font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif;
    color: #FDFDFD;
    display: flex; align-items: center; justify-content: center; gap: 78px;
    padding: 0 76px;
  }
  /* Il logo è l'icona dell'app così com'è, con lo stesso raggio d'angolo che
     porta in pagina (22,4%) e la stessa ombra: non è ridisegnata. */
  .logo {
    width: 320px; height: 320px; flex: none;
    border-radius: 22.4%;
    border: 1px solid rgba(140, 204, 166, .22);
    box-shadow: 0 26px 64px rgba(4, 18, 12, .5);
  }
  .nome { font-size: 122px; font-weight: 700; letter-spacing: .095em; line-height: 1; }
  /* Il filetto arancio è l'unico segno che non è una parola: è lo stesso
     accento della pillola della landing, ridotto a una riga. */
  .filetto { width: 132px; height: 8px; border-radius: 4px; background: #EC6F18; margin: 34px 0 30px; }
  .riga { font-size: 44px; font-weight: 600; line-height: 1.22; color: #8CCCA6; max-width: 21ch; }
</style></head><body>
  <img class="logo" src="${pathToFileURL(join(REPO, 'assets/img/aimonx-512.png')).href}">
  <div>
    <p class="nome">AIMONX</p>
    <div class="filetto"></div>
    <!-- ⚠️ «sport&nbsp;shooters» insieme, dal giro W11: con «log» al posto di
         «logbook» la riga andava a capo fra le due parole, e «shooters»
         restava sola sotto. Stesse parole: cambia solo dove si va a capo. -->
    <p class="riga">the technical log for sport&nbsp;shooters</p>
  </div>
</body></html>`;

const tmp = join(tmpdir(), `aimonx-condivisione-${process.pid}.html`);
await writeFile(tmp, pagina, 'utf8');

const browser = await chromium.launch();
// ⚠️ deviceScaleFactor 1: il file deve essere 1200×630 VERI, non 2400×1260.
// Chi consuma un og:image guarda i pixel dichiarati, non il doppio.
const page = await browser.newPage({ viewport: { width: L, height: A }, deviceScaleFactor: 1 });
await page.goto(pathToFileURL(tmp).href, { waitUntil: 'networkidle' });
await mkdir(dirname(uscita), { recursive: true });
await page.screenshot({ path: uscita, type: 'png' });
const misura = await page.evaluate(() => [window.innerWidth, window.innerHeight]);
await browser.close();

console.log(`scritta: ${uscita}`);
console.log(`misura della pagina: ${misura[0]}×${misura[1]}`);
