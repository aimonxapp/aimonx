// scripts/schermate.mjs — rifà le immagini dell'app che la landing mostra, a
// partire dalle sorgenti di Pier. Giro W14.
//
// ⛔ PERCHÉ UNO SCRIPT E NON OTTO FILE RIMPICCIOLITI A MANO: stessa ragione di
// scripts/immagine-condivisione.mjs. Un file ridotto a mano non dice più da
// quale sorgente viene, a che misura, con quale qualità — e il giorno che Pier
// rifà una schermata nessuno sa come rifarne la copia per il sito.
//
// ⛔⛔ LE SORGENTI SONO QUELLE NOMINATE QUI SOTTO, UNA PER UNA, E SOLO QUELLE:
// otto dal giro W14 (sette schermate dell'app e la prima e unica pagina del PDF
// di prova) e tre dal W15, per la pagina «Round count». ⛔ Lo script
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
//   · ⭐ ALLA PAGINA DEL PDF TOGLIE IL BIANCO, e solo quello (Pier,
//     09/10/2026): fra i totali e la riga in fondo c'è un terzo di foglio
//     vuoto, che in pagina era un rettangolo bianco. Lo script cerca la fascia
//     di righe TUTTE BIANCHE più alta e la accorcia; ⛔ tabella, totali e la
//     riga «AIMONX · Generated locally from the data stored on this device»
//     restano, pixel per pixel — quella riga è una prova di privacy.
//     ⚠️ Quindi l'immagine NON è più la pagina com'è uscita dall'app: è la
//     pagina con meno vuoto in mezzo. Niente è spostato di lato, niente è
//     ridisegnato, e la fascia tolta non conteneva un solo pixel scritto;
//   · ⛔ le foto delle armi dentro il PDF sono miniature prese da Pixabay
//     (Pier, 09/10/2026) e miniature restano: non si ritagliano e non si
//     ingrandiscono.
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
  // --- giro W15, la pagina «Round count» ---
  { da: 'sessions_2.png',      a: 'aimonx-firearm-sessions',     larghezze: TELEFONO },
  { da: 'stats_2.png',         a: 'aimonx-rounds-by-firearm',    larghezze: TELEFONO },
  // ⚠️ Questa contiene tre FOTO VERE di un'arma di Pier, in miniatura: uso
  // autorizzato da lui il 09/10/2026, matricola non leggibile. ⛔ Restano
  // miniature dentro la schermata: non si ritagliano e non si ingrandiscono.
  { da: 'firearms_5.png',      a: 'aimonx-firearm-stats',        larghezze: TELEFONO },
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
    const esito = await page.evaluate(async ({ dati, l, q, accorcia }) => {
      const img = new Image();
      img.src = dati;
      await img.decode();
      let fonte = img, larga = img.naturalWidth, alta = img.naturalHeight, tolte = 0;
      if (accorcia) {
        // La fascia bianca più alta: una riga è «bianca» se ogni suo pixel lo
        // è. ⚠️ Se ne lascia un pezzo, alto il 5% del foglio: senza, la riga
        // in fondo finirebbe attaccata ai totali come se ne facesse parte.
        const intera = new OffscreenCanvas(larga, alta);
        const c = intera.getContext('2d', { willReadFrequently: true });
        c.drawImage(img, 0, 0);
        const px = c.getImageData(0, 0, larga, alta).data;
        const bianca = (y) => { for (let i = y * larga * 4, f = i + larga * 4; i < f; i += 4) if (px[i] < 250 || px[i + 1] < 250 || px[i + 2] < 250) return false; return true; };
        let meglio = [0, 0], da = -1;
        for (let y = 0; y <= alta; y++) {
          const b = y < alta && bianca(y);
          if (b && da < 0) da = y;
          if (!b && da >= 0) { if (da > 0 && y < alta && y - da > meglio[1] - meglio[0]) meglio = [da, y]; da = -1; }
        }
        const resta = Math.round(alta * 0.05);
        tolte = Math.max(0, meglio[1] - meglio[0] - resta);
        if (tolte > 0) {
          const corta = new OffscreenCanvas(larga, alta - tolte);
          const k = corta.getContext('2d');
          const taglio = meglio[0] + Math.round(resta / 2);
          k.drawImage(intera, 0, 0, larga, taglio, 0, 0, larga, taglio);
          k.drawImage(intera, 0, taglio + tolte, larga, alta - taglio - tolte, 0, taglio, larga, alta - taglio - tolte);
          fonte = corta; alta -= tolte;
        }
      }
      const a = Math.round(alta * l / larga);
      const piccola = await createImageBitmap(fonte, { resizeWidth: l, resizeHeight: a, resizeQuality: 'high' });
      const tela = new OffscreenCanvas(l, a);
      tela.getContext('2d').drawImage(piccola, 0, 0);
      const blob = await tela.convertToBlob({ type: 'image/webp', quality: q });
      const byte = new Uint8Array(await blob.arrayBuffer());
      let s = '';
      for (let i = 0; i < byte.length; i += 0x8000) s += String.fromCharCode(...byte.subarray(i, i + 0x8000));
      return { base64: btoa(s), l, a, da: [img.naturalWidth, img.naturalHeight], tolte };
    }, { dati, l, q: QUALITA, accorcia: voce.da.endsWith('.pdf') });
    const file = join(USCITA, `${voce.a}-${l}.webp`);
    const corpo = Buffer.from(esito.base64, 'base64');
    await writeFile(file, corpo);
    totale += corpo.length;
    console.log(`${voce.da} (${esito.da[0]}×${esito.da[1]}) → ${voce.a}-${l}.webp  ${esito.l}×${esito.a}  ${(corpo.length / 1024).toFixed(1)} KB${esito.tolte ? ` · tolte ${esito.tolte} righe bianche` : ''}`);
  }
}

await browser.close();
await rm(tmp, { recursive: true, force: true });
console.log(`\n${LISTA.length} sorgenti · ${LISTA.reduce((s, v) => s + v.larghezze.length, 0)} file · ${(totale / 1024).toFixed(1)} KB in tutto → ${USCITA}`);
