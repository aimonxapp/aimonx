// scripts/schermate.mjs — rifà le immagini dell'app che la landing mostra, a
// partire dalle sorgenti di Pier. Giro W14.
//
// ⛔ PERCHÉ UNO SCRIPT E NON OTTO FILE RIMPICCIOLITI A MANO: stessa ragione di
// scripts/immagine-condivisione.mjs. Un file ridotto a mano non dice più da
// quale sorgente viene, a che misura, con quale qualità — e il giorno che Pier
// rifà una schermata nessuno sa come rifarne la copia per il sito.
//
// ⛔⛔ LE SORGENTI SONO OTTO E SOLO OTTO, nominate qui sotto una per una: sette
// schermate dell'app e la prima (e unica) pagina del PDF di prova. ⛔ Lo script
// NON prende «quel che trova nella cartella»: nella cartella di Pier ci sono
// decine di altre schermate, e nel repo — che è PUBBLICO — entrano solo queste
// (giro W14 §2①). Chi ne vuole una in più la aggiunge alla lista, e si vede.
// ⛔ La cartella si passa come argomento e NON si scrive qui: è un percorso del
// disco di Pier (WD17).
//
// ⚠️ COSA FA ALLE IMMAGINI, e cosa no:
//   · le RIMPICCIOLISCE a tre larghezze e le salva in WebP — nient'altro;
//   · ⛔ non le ritaglia, non le ritocca, non ci scrive sopra, non le incornicia:
//     la cornice in pagina è CSS (`assets/css/b.scss`), il file è la schermata;
//   · ⛔ la pagina del PDF resta INTERA: le foto delle armi lì dentro sono
//     miniature prese da Pixabay (Pier, 09/10/2026) e miniature restano — non
//     si ritagliano e non si ingrandiscono.
//
// ⚠️ LE TRE LARGHEZZE NON SONO A GUSTO. Le schermate sono 1290×2796, cioè un
// iPhone da 430×932 punti a 3×: 430, 645 e 860 sono ×1, ×1,5 e ×2 di quella
// misura, e dividono i pixel SENZA resto — l'altezza esce intera, e i tre file
// hanno esattamente lo stesso rapporto. In pagina una schermata è larga da 150
// a 260 px: 430 basta a uno schermo normale, 645 a un Retina, 860 a un
// telefono a 3×. Sceglie il browser, con `srcset`.
//
// ⚠️ IL WEBP LO SCRIVE IL BROWSER DI PLAYWRIGHT, e non uno strumento nuovo:
// sul Mac non c'è `cwebp`, `sips` il WebP lo legge e non lo scrive, e
// installare un programma per otto immagini sarebbe uno strumento in più da
// misurare (`WD36`). Il browser c'è già. ⚠️ Conseguenza da sapere: un altro
// Chromium può produrre byte diversi per la stessa immagine — il file si rifà
// uguale A VEDERSI, non per forza uguale al byte.
// La pagina del PDF la disegna `pdftoppm` (poppler), che sul Mac c'è già.
//
// Uso:  node scripts/schermate.mjs "<cartella delle sorgenti>"
// Esce: assets/img/screenshots/<nome>-<larghezza>.webp

import { readFile, writeFile, mkdir, mkdtemp, rm } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { homedir, tmpdir } from 'node:os';
import { join, dirname, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const playwrightPath = process.env.AIMONX_PLAYWRIGHT
  ?? join(homedir(), '.aimonx-web-tools', 'node_modules', 'playwright', 'index.js');
const pw = await import(pathToFileURL(playwrightPath).href);
const chromium = pw.chromium ?? pw.default?.chromium;

const REPO = resolve(dirname(new URL(import.meta.url).pathname), '..');
const USCITA = join(REPO, 'assets/img/screenshots');
const sorgenti = process.argv[2];
if (!sorgenti) {
  console.error('⛔ manca la cartella delle sorgenti: node scripts/schermate.mjs "<cartella>"');
  process.exit(2);
}

// ⛔ I NOMI DI USCITA SONO IN INGLESE E DICONO COSA SI VEDE: li legge anche
// Google (giro W14 §2①). ⚠️ Gli stessi nomi stanno in `_data/aspetto.yml`,
// che li accoppia alle voci della landing.
const TELEFONO = [430, 645, 860];
const FOGLIO = [600, 900, 1200];
const LISTA = [
  { da: 'home_1.png',          a: 'aimonx-home-screen',          larghezze: TELEFONO },
  { da: 'firearms_1.png',      a: 'aimonx-firearms-round-count', larghezze: TELEFONO },
  { da: 'sessions_1.png',      a: 'aimonx-range-sessions',       larghezze: TELEFONO },
  { da: 'ammo_1.png',          a: 'aimonx-ammo-inventory',       larghezze: TELEFONO },
  { da: 'firearms_2.png',      a: 'aimonx-maintenance-rules',    larghezze: TELEFONO },
  { da: 'renewals_1.png',      a: 'aimonx-renewals',             larghezze: TELEFONO },
  { da: 'stats_4.png',         a: 'aimonx-shooting-costs',       larghezze: TELEFONO },
  { da: 'inventario-demo.pdf', a: 'aimonx-firearm-inventory-pdf', larghezze: FOGLIO },
];
// ⚠️ 0,82: sotto, il testo piccolo delle schermate comincia a sporcarsi
// intorno alle lettere; sopra, il peso sale e a occhio non cambia niente.
const QUALITA = 0.82;

const tmp = await mkdtemp(join(tmpdir(), 'aimonx-schermate-'));
await mkdir(USCITA, { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage();

let totale = 0;
for (const voce of LISTA) {
  let png = join(sorgenti, voce.da);
  if (voce.da.endsWith('.pdf')) {
    // ⛔ `-f 1 -l 1`: la prima pagina e basta, anche se un giorno il PDF di
    // prova ne avesse due. 300 punti per pollice: più del doppio di quel che
    // serve alla larghezza massima, così si rimpicciolisce e non si ingrandisce.
    execFileSync('pdftoppm', ['-f', '1', '-l', '1', '-singlefile', '-r', '300', '-png', png, join(tmp, 'foglio')]);
    png = join(tmp, 'foglio.png');
  }
  const dati = `data:image/png;base64,${(await readFile(png)).toString('base64')}`;
  for (const l of voce.larghezze) {
    const esito = await page.evaluate(async ({ dati, l, q }) => {
      const img = new Image();
      img.src = dati;
      await img.decode();
      const a = Math.round(img.naturalHeight * l / img.naturalWidth);
      const piccola = await createImageBitmap(img, { resizeWidth: l, resizeHeight: a, resizeQuality: 'high' });
      const tela = new OffscreenCanvas(l, a);
      tela.getContext('2d').drawImage(piccola, 0, 0);
      const blob = await tela.convertToBlob({ type: 'image/webp', quality: q });
      const byte = new Uint8Array(await blob.arrayBuffer());
      let s = '';
      for (let i = 0; i < byte.length; i += 0x8000) s += String.fromCharCode(...byte.subarray(i, i + 0x8000));
      return { base64: btoa(s), l, a, da: [img.naturalWidth, img.naturalHeight] };
    }, { dati, l, q: QUALITA });
    const file = join(USCITA, `${voce.a}-${l}.webp`);
    const corpo = Buffer.from(esito.base64, 'base64');
    await writeFile(file, corpo);
    totale += corpo.length;
    console.log(`${voce.da} (${esito.da[0]}×${esito.da[1]}) → ${voce.a}-${l}.webp  ${esito.l}×${esito.a}  ${(corpo.length / 1024).toFixed(1)} KB`);
  }
}

await browser.close();
await rm(tmp, { recursive: true, force: true });
console.log(`\n${LISTA.length} sorgenti · ${LISTA.reduce((s, v) => s + v.larghezze.length, 0)} file · ${(totale / 1024).toFixed(1)} KB in tutto → ${USCITA}`);
