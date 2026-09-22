// scripts/tastiera.mjs — la pagina si usa senza mouse? Giro W10.
//
// ⛔ NON È UN TEST CHE PASSA O FALLISCE: è una MISURA, come contrasto.mjs e
// sbordi.mjs. Stampa il giro del tasto Tab e lascia il giudizio a chi legge.
//
// ⭐ PERCHÉ ESISTE ADESSO: fino al W9 il sito era fatto di testo e di link, e
// «si usa da tastiera» era quasi una tautologia. La barra del W10 ha un
// PULSANTE che apre e chiude — cioè uno stato — e lì la domanda diventa vera:
// ⛔ chi non usa il mouse deve poterlo aprire, e quando è chiuso le voci NON
// devono restare raggiungibili col Tab. ⚠️ Un link invisibile ma tabbabile è
// peggio di nessun link: il fuoco sparisce in un punto che non si vede.
//
// COSA MISURA, a due larghezze:
//  ① l ordine del Tab, elemento per elemento, con quel che si vede;
//  ② che il fuoco si VEDA: nessun elemento raggiungibile può avere
//     `outline-style: none` senza metterci qualcos altro al posto;
//  ③ sul telefono: il pulsante «Menu» apre con Invio e chiude con Esc, e le
//     voci entrano nel giro del Tab solo da aperte.
//
// Uso:  node scripts/tastiera.mjs <url> [url...]

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
if (urls.length === 0) { console.error('Uso: node scripts/tastiera.mjs <url> [url...]'); process.exit(2); }

const attivo = () => document.activeElement && {
  tag: document.activeElement.tagName.toLowerCase(),
  testo: (document.activeElement.innerText || document.activeElement.getAttribute('aria-label') || '').trim().split('\n')[0].slice(0, 34),
  dove: document.activeElement.getAttribute('href') || '',
  corrente: document.activeElement.getAttribute('aria-current') || '',
  contorno: getComputedStyle(document.activeElement, ':focus-visible').outlineStyle,
  visibile: document.activeElement.getBoundingClientRect().width > 0,
};

const browser = await chromium.launch();
let guasti = 0;

for (const url of urls) {
  console.log(`\n=== ${url} ===`);
  for (const [nome, larghezza] of [['telefono', 390], ['computer', 1280]]) {
    const page = await browser.newPage({ viewport: { width: larghezza, height: 900 } });
    await page.goto(url, { waitUntil: 'networkidle' });

    // ③ Il pulsante c è solo sul telefono: sopra i 760px il CSS lo toglie.
    const pulsante = await page.evaluate(() => {
      const s = document.querySelector('.barra .apri > summary');
      return s && s.getBoundingClientRect().width > 0 ? s.textContent.trim() : null;
    });

    // ⛔ LA MISURA CHE CONTA DI PIÙ, e si fa PRIMA di aprire: con il menu
    // chiuso, le voci non devono essere raggiungibili col Tab. ⚠️ Un link
    // invisibile ma tabbabile fa sparire il fuoco in un punto che non si vede,
    // ed è peggio di non avere il link.
    if (pulsante) {
      const fantasmi = await page.evaluate(() =>
        [...document.querySelectorAll('.barra .voci a')].filter((a) => a.offsetParent !== null).length);
      console.log(`  --- ${nome}: menu CHIUSO, voci raggiungibili col Tab: ${fantasmi}` +
                  (fantasmi === 0 ? '  ✅' : '  ⛔ dovrebbero essere 0'));
      if (fantasmi !== 0) guasti++;
    }

    const giro = [];
    await page.evaluate(() => document.body.focus());
    for (let i = 0; i < 14; i++) {
      await page.keyboard.press('Tab');
      const a = await page.evaluate(attivo);
      if (!a || a.tag === 'body') break;
      giro.push(a);
      // Arrivati sul pulsante «Menu», lo si apre con Invio e si prosegue:
      // è esattamente quello che farebbe chi non ha il mouse.
      if (a.tag === 'summary') {
        await page.keyboard.press('Enter');
        const aperto = await page.evaluate(() => document.querySelector('.barra .apri').open);
        giro.push({ tag: '⏎', testo: aperto ? 'il menu si è APERTO' : '⛔ il menu NON si è aperto', dove: '', corrente: '', contorno: 'solid', visibile: true });
        if (!aperto) guasti++;
      }
    }

    console.log(`  --- ${nome} (${larghezza}px) · pulsante «Menu» visibile: ${pulsante ?? 'no'}`);
    giro.forEach((a, i) => {
      const segni = [a.dove && `→ ${a.dove}`, a.corrente && `(${a.corrente})`].filter(Boolean).join(' ');
      const cieco = a.contorno === 'none' ? '  ⛔ SENZA CONTORNO DI FUOCO' : '';
      const invisibile = !a.visibile ? '  ⛔ RAGGIUNGIBILE MA INVISIBILE' : '';
      if (cieco || invisibile) guasti++;
      console.log(`   ${String(i + 1).padStart(2)}. <${a.tag}> ${a.testo} ${segni}${cieco}${invisibile}`);
    });

    // Esc richiude, che è quel che ci si aspetta da un pannello aperto.
    if (pulsante) {
      await page.keyboard.press('Escape');
      const ancora = await page.evaluate(() => document.querySelector('.barra .apri').open);
      // ⚠️ `<details>` NON si chiude con Esc, e non è un guasto: non è una
      // finestra modale, è un pannello che si apre. Lo si richiude col suo
      // stesso pulsante, che è dove il fuoco è già. ⛔ Farlo chiudere con Esc
      // vorrebbe dire JavaScript, e qui non ce n è. Si MISURA e si dichiara,
      // invece di lasciar credere che faccia una cosa che non fa.
      console.log(`   Esc → il menu è ${ancora ? 'ancora aperto (atteso: <details> non è una modale)' : 'richiuso'}`);
    }
    await page.close();
  }
}

await browser.close();
console.log(`\n→ guasti di tastiera trovati: ${guasti}`);
