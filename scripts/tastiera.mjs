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
//     voci entrano nel giro del Tab solo da aperte;
//  ④ dal giro W24, con `assets/js/menu.js`: Esc chiude la tendina e il
//     pannello e il fuoco TORNA sul loro pulsante; un clic fuori chiude la
//     tendina. ⛔ E tutto si rifà CON JAVASCRIPT SPENTO: lì Esc e il clic fuori
//     non ci sono (atteso, si stampa), ma aprire, chiudere e il Tab devono
//     restare intatti — se no lo script è diventato una stampella.
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
  testo: (document.activeElement.innerText || document.activeElement.getAttribute('aria-label') || document.activeElement.querySelector('img')?.alt || '').trim().split('\n')[0].slice(0, 34),
  dove: document.activeElement.getAttribute('href') || '',
  corrente: document.activeElement.getAttribute('aria-current') || '',
  contorno: getComputedStyle(document.activeElement, ':focus-visible').outlineStyle,
  visibile: document.activeElement.getBoundingClientRect().width > 0,
};

const browser = await chromium.launch();
let guasti = 0;

for (const url of urls) {
  console.log(`\n=== ${url} ===`);
  for (const script of [true, false])
  for (const [nomeBase, larghezza] of [['telefono', 390], ['computer', 1280]]) {
    const nome = script ? nomeBase : `${nomeBase} SENZA JS`;
    const ctx = await browser.newContext({ viewport: { width: larghezza, height: 900 }, javaScriptEnabled: script });
    const page = await ctx.newPage();
    await page.goto(url, { waitUntil: 'networkidle' });

    // ③ Il pulsante c è solo sul telefono: sopra i 760px il CSS lo toglie.
    const pulsante = await page.evaluate(() => {
      const s = document.querySelector('.barra .apri > summary');
      return s && s.getBoundingClientRect().width > 0 ? s.innerText.trim() : null;
    });

    // ⛔ LA MISURA CHE CONTA DI PIÙ, e si fa PRIMA di aprire: con il menu
    // chiuso, le voci non devono essere raggiungibili col Tab. ⚠️ Un link
    // invisibile ma tabbabile fa sparire il fuoco in un punto che non si vede,
    // ed è peggio di non avere il link.
    // ⛔ FINO AL GIRO W24 QUI SI CERCAVA `.barra .voci a`, e dal W10 la classe
    // è `voci-barra`: il selettore non trovava niente e la misura contava 0
    // QUALUNQUE COSA SUCCEDESSE. Un controllo che non può fallire non è un
    // controllo. ⭐ Ora si contano le voci della barra (telefono, menu chiuso) e
    // quelle della tendina «Features» (computer, tendina chiusa) — e il conto
    // si stampa accanto a quante voci ci sono, così uno 0 su 0 si vede.
    const chiuse = await page.evaluate((telefono) => {
      const sel = telefono ? '.barra .voci-barra a' : '.barra .sotto a';
      const tutte = [...document.querySelectorAll(sel)];
      return { tutte: tutte.length, visibili: tutte.filter((a) => a.offsetParent !== null).length };
    }, Boolean(pulsante));
    const cosa = pulsante ? 'menu CHIUSO, voci della barra' : 'tendina CHIUSA, voci della tendina';
    console.log(`  --- ${nome}: ${cosa} raggiungibili col Tab: ${chiuse.visibili} su ${chiuse.tutte}` +
                (chiuse.visibili === 0 && chiuse.tutte > 0 ? '  ✅' : '  ⛔ dovrebbero essere 0 su più di 0'));
    if (chiuse.visibili !== 0 || chiuse.tutte === 0) guasti++;
    // ⭐ Giro W29: la tendina delle LINGUE, in alto a destra, a ogni larghezza —
    // chiusa, le sue voci non si raggiungono col Tab. Stessa misura, stesso conto.
    const lingueChiuse = await page.evaluate(() => {
      const tutte = [...document.querySelectorAll('.lingue .lingue-voci a')];
      return { tutte: tutte.length, visibili: tutte.filter((a) => a.offsetParent !== null).length };
    });
    console.log(`  --- ${nome}: tendina delle lingue CHIUSA, voci raggiungibili col Tab: ${lingueChiuse.visibili} su ${lingueChiuse.tutte}` +
                (lingueChiuse.visibili === 0 && lingueChiuse.tutte > 0 ? '  ✅' : '  ⛔ dovrebbero essere 0 su più di 0'));
    if (lingueChiuse.visibili !== 0 || lingueChiuse.tutte === 0) guasti++;

    const giro = [];
    await page.evaluate(() => document.body.focus());
    for (let i = 0; i < 22; i++) {
      await page.keyboard.press('Tab');
      const a = await page.evaluate(attivo);
      if (!a || a.tag === 'body') break;
      giro.push(a);
      // Arrivati sul pulsante «Menu», lo si apre con Invio e si prosegue:
      // è esattamente quello che farebbe chi non ha il mouse.
      // ⭐ Dal giro W24 i pulsanti sono due — «Menu» e la tendina «Features»:
      // si apre quello su cui si è.
      if (a.tag === 'summary') {
        await page.keyboard.press('Enter');
        const aperto = await page.evaluate(() => document.activeElement.parentElement.open);
        giro.push({ tag: '⏎', testo: aperto ? `«${a.testo}» si è APERTO` : `⛔ «${a.testo}» NON si è aperto`, dove: '', corrente: '', contorno: 'solid', visibile: true });
        if (!aperto) guasti++;
      }
    }

    console.log(`  --- ${nome} (${larghezza}px) · pulsante «Menu» visibile: ${pulsante ?? 'no'}`);
    // Il giro intero si stampa una volta sola, con lo script: senza, si
    // stampano solo i guasti — le righe sarebbero le stesse.
    giro.forEach((a, i) => {
      const segni = [a.dove && `→ ${a.dove}`, a.corrente && `(${a.corrente})`].filter(Boolean).join(' ');
      const cieco = a.contorno === 'none' ? '  ⛔ SENZA CONTORNO DI FUOCO' : '';
      const invisibile = !a.visibile ? '  ⛔ RAGGIUNGIBILE MA INVISIBILE' : '';
      if (cieco || invisibile) guasti++;
      if (script || cieco || invisibile) console.log(`   ${String(i + 1).padStart(2)}. <${a.tag}> ${a.testo} ${segni}${cieco}${invisibile}`);
    });

    // Il pulsante aperto si richiude da sé, col suo Invio.
    // ⭐ Giro W24: e si RICHIUDE da tastiera — fuoco sul pulsante, Invio.
    // ⭐ Giro W29: anche la tendina delle lingue (`.lingue`). ⚠️ Si chiude
    // sempre il pulsante che SI VEDE: senza script, sul telefono, la tendina
    // delle lingue può restare aperta SOTTO il pannello «Menu» (che nasconde il
    // resto della pagina), e si raggiunge solo dopo aver chiuso il pannello.
    const visibileAperto = () => [...document.querySelectorAll(':is(.barra, .lingue) details[open] > summary')]
      .find((s) => s.getBoundingClientRect().width > 0 && getComputedStyle(s).visibility !== 'hidden');
    let richiusi = 0;
    for (let k = 0; k < 4; k++) {
      const c = await page.evaluate(`(() => { const s = (${visibileAperto.toString()})(); if (!s) return false; s.focus(); return true; })()`);
      if (!c) break;
      await page.keyboard.press('Enter');
      richiusi++;
    }
    const ancoraAperti = await page.evaluate(() => document.querySelectorAll(':is(.barra, .lingue) details[open]').length);
    console.log(`   Invio sul pulsante aperto → ${ancoraAperti === 0 ? `richiuso (${richiusi})  ✅` : `⛔ ancora aperti: ${ancoraAperti}`}`);
    if (ancoraAperti !== 0) guasti++;

    // ④ Esc, su ogni pulsante che si vede: si apre con Invio, poi Esc.
    const pulsanti = await page.evaluate(() =>
      [...document.querySelectorAll(':is(.barra, .lingue) details > summary')].filter((s) => s.getClientRects().length).map((s) => s.parentElement.className));
    for (const classe of pulsanti) {
      await page.focus(`:is(.barra, .lingue) details.${classe} > summary`);
      await page.keyboard.press('Enter');
      // Un Tab DENTRO, sulla prima voce: Esc si preme da lì, ed è da lì che il
      // fuoco deve tornare al pulsante.
      await page.keyboard.press('Tab');
      const dentro = await page.evaluate(() => document.activeElement.closest('.voci-barra, .sotto, .lingue-voci') ? document.activeElement.innerText.trim() : null);
      await page.keyboard.press('Escape');
      const dopo = await page.evaluate((c) => {
        const d = document.querySelector(`:is(.barra, .lingue) details.${c}`);
        return { aperto: d.open, fuoco: document.activeElement === d.querySelector('summary') };
      }, classe);
      if (!script) {
        console.log(`   Esc sul pulsante «${classe}» → ${dopo.aperto ? 'resta aperto (atteso: senza script Esc non c è)' : 'richiuso'}`);
        await page.evaluate((c) => { document.querySelector(`:is(.barra, .lingue) details.${c}`).open = false; }, classe);
        continue;
      }
      const bene = !dopo.aperto && dopo.fuoco && dentro !== null;
      console.log(`   Esc da «${dentro ?? '⛔ fuori dal menu'}», dentro «${classe}» → ${dopo.aperto ? '⛔ resta aperto' : 'richiuso'}, fuoco ${dopo.fuoco ? 'sul suo pulsante' : '⛔ PERSO'}${bene ? '  ✅' : ''}`);
      if (!bene) guasti++;
    }

    // ④ Il clic fuori, sulla tendina del computer: aperta, poi un clic in
    // mezzo alla pagina, lontano dalla barra.
    // ⚠️ Si parte da chiusa: se Esc ha appena fallito, la tendina è ancora
    // aperta, Invio la CHIUDEREBBE e il clic fuori passerebbe senza merito —
    // successo davvero, alla prima controprova di questa misura.
    if (!pulsante) {
      await page.evaluate(() => { document.querySelector('.barra details.tendina').open = false; });
      await page.focus('.barra details.tendina > summary');
      await page.keyboard.press('Enter');
      if (!await page.evaluate(() => document.querySelector('.barra details.tendina').open)) { console.log('   ⛔ la tendina non si è aperta'); guasti++; }
      await page.mouse.click(larghezza / 2, 600);
      const aperta = await page.evaluate(() => document.querySelector('.barra details.tendina').open);
      if (script) {
        console.log(`   clic fuori dalla tendina aperta → ${aperta ? '⛔ resta aperta' : 'richiusa  ✅'}`);
        if (aperta) guasti++;
      } else {
        console.log(`   clic fuori dalla tendina aperta → ${aperta ? 'resta aperta (atteso: senza script)' : 'richiusa'}`);
      }
    }
    // ⭐ Giro W29: il clic fuori anche sulla tendina delle lingue, a ogni larghezza.
    await page.evaluate(() => { document.querySelector('.lingue details.tendina-lingue').open = false; });
    await page.focus('.lingue details.tendina-lingue > summary');
    await page.keyboard.press('Enter');
    if (!await page.evaluate(() => document.querySelector('.lingue details.tendina-lingue').open)) { console.log('   ⛔ la tendina delle lingue non si è aperta'); guasti++; }
    // ⚠️ Nel margine laterale, dove non c'è niente: in mezzo, al telefono, il
    // clic cadeva su un link e cambiava pagina (misurato su `/features/`).
    await page.mouse.click(4, 600);
    const lingueAperta = await page.evaluate(() => document.querySelector('.lingue details.tendina-lingue').open);
    if (script) {
      console.log(`   clic fuori dalla tendina delle lingue → ${lingueAperta ? '⛔ resta aperta' : 'richiusa  ✅'}`);
      if (lingueAperta) guasti++;
    } else {
      console.log(`   clic fuori dalla tendina delle lingue → ${lingueAperta ? 'resta aperta (atteso: senza script)' : 'richiusa'}`);
    }
    await ctx.close();
  }
}

await browser.close();
console.log(`\n→ guasti di tastiera trovati: ${guasti}`);
