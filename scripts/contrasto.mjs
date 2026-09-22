// scripts/contrasto.mjs — il contrasto del testo, MISURATO. Giro W4.
//
// ⛔ NON SI GUARDA A OCCHIO, e non si legge da una lista di coppie scritta a
// mano: una lista diverge dal CSS il giorno dopo. Qui la pagina si apre in un
// browser vero, si percorre ogni nodo di testo che si vede, e per ciascuno si
// prende il colore CALCOLATO e lo sfondo che ha DAVVERO sotto — risalendo gli
// antenati finché non se ne trova uno non trasparente, che è quello che il
// browser dipinge sotto quel testo.
//
// La soglia è WCAG 2.1 AA (obiettivo di `conformita-sito.md`):
//   · 4.5:1 per il testo normale;
//   · 3:1 per il testo GRANDE — da 24 px, o da 18.66 px se in grassetto.
// ⚠️ Il grassetto conta: la stessa dimensione passa o non passa a seconda del
// peso, e una soglia unica direbbe il falso in tutte e due le direzioni.
//
// ⛔ COSA NON MISURA, e va detto invece di lasciarlo credere: il contrasto dei
// componenti non testuali (WCAG 1.4.11) — filetti, bordi, il punto del mirino.
// E non dice se la pagina è COMPRENSIBILE: nessuno script lo dice.
//
// Uso: node scripts/contrasto.mjs <url> [altra-url …]

import { homedir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const playwrightPath = process.env.AIMONX_PLAYWRIGHT
  || join(homedir(), '.aimonx-web-tools', 'node_modules', 'playwright', 'index.js');
const pw = await import(pathToFileURL(playwrightPath).href);
const chromium = pw.chromium ?? pw.default?.chromium;

const urls = process.argv.slice(2);
if (urls.length === 0) { console.error('uso: node scripts/contrasto.mjs <url> …'); process.exit(2); }

// La misura gira DENTRO la pagina: solo lì si conoscono i colori calcolati.
const dentro = () => {
  const rgb = (s) => {
    const m = s.match(/[\d.]+/g);
    if (!m) return null;
    const a = m.length > 3 ? parseFloat(m[3]) : 1;
    return { r: +m[0], g: +m[1], b: +m[2], a };
  };
  const lum = ({ r, g, b }) => {
    const c = [r, g, b].map((v) => {
      const x = v / 255;
      return x <= 0.03928 ? x / 12.92 : Math.pow((x + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
  };
  // ⚠️ Un testo semitrasparente si fonde col suo fondo: senza questo, un
  // colore con alpha risulterebbe più contrastato di come si vede.
  const fondi = (sopra, sotto) => ({
    r: sopra.r * sopra.a + sotto.r * (1 - sopra.a),
    g: sopra.g * sopra.a + sotto.g * (1 - sopra.a),
    b: sopra.b * sopra.a + sotto.b * (1 - sopra.a),
    a: 1,
  });
  const rapporto = (x, y) => {
    const [a, b] = [lum(x), lum(y)].sort((p, q) => q - p);
    return (a + 0.05) / (b + 0.05);
  };
  // Lo sfondo VERO: si risale finché non si trova un colore coprente.
  const sfondo = (el) => {
    let n = el, acc = null;
    while (n) {
      const c = rgb(getComputedStyle(n).backgroundColor);
      if (c && c.a > 0) acc = acc ? fondi(acc, c) : c;
      if (acc && acc.a >= 0.999) return acc;
      n = n.parentElement;
    }
    return acc && acc.a >= 0.999 ? acc : { r: 255, g: 255, b: 255, a: 1 };
  };

  const out = [];
  const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  const visti = new Set();
  for (let n = w.nextNode(); n; n = w.nextNode()) {
    const t = n.textContent.trim();
    if (!t) continue;
    const el = n.parentElement;
    if (!el || visti.has(el)) continue;
    visti.add(el);
    const st = getComputedStyle(el);
    if (st.visibility === 'hidden' || st.display === 'none' || +st.opacity === 0) continue;
    const box = el.getBoundingClientRect();
    if (box.width === 0 || box.height === 0) continue;

    const px = parseFloat(st.fontSize);
    const peso = parseInt(st.fontWeight, 10) || 400;
    const grande = px >= 24 || (px >= 18.66 && peso >= 700);
    const bg = sfondo(el);
    const fgGrezzo = rgb(st.color) || { r: 0, g: 0, b: 0, a: 1 };
    const fg = fgGrezzo.a < 1 ? fondi(fgGrezzo, bg) : fgGrezzo;
    const r = rapporto(fg, bg);
    out.push({
      testo: t.slice(0, 44), tag: el.tagName.toLowerCase(), classe: el.className || '',
      px: Math.round(px * 10) / 10, peso, grande,
      colore: st.color, sfondo: `rgb(${Math.round(bg.r)}, ${Math.round(bg.g)}, ${Math.round(bg.b)})`,
      rapporto: Math.round(r * 100) / 100, soglia: grande ? 3 : 4.5,
    });
  }
  return out;
};

const browser = await chromium.launch();
let bocciatiTotali = 0;

for (const url of urls) {
  // ⚠️ Due formati, perché le dimensioni del testo cambiano con la larghezza
  // (clamp) — e con loro la soglia: 23 px non è testo grande, 24 sì.
  for (const f of [{ n: 'telefono', w: 390, h: 844 }, { n: 'computer', w: 1440, h: 900 }]) {
    const ctx = await browser.newContext({ viewport: { width: f.w, height: f.h } });
    const page = await ctx.newPage();
    await page.goto(url, { waitUntil: 'networkidle' });
    const righe = await page.evaluate(dentro);
    const bocciati = righe.filter((x) => x.rapporto < x.soglia);
    bocciatiTotali += bocciati.length;
    const min = righe.reduce((a, x) => Math.min(a, x.rapporto), Infinity);
    console.log(`\n=== ${url} · ${f.n} (${f.w}×${f.h}) ===`);
    console.log(`  ${righe.length} blocchi di testo · sotto la soglia AA: ${bocciati.length} · rapporto più basso: ${min.toFixed(2)}:1`);
    for (const x of bocciati)
      console.log(`  ⛔ ${x.rapporto}:1 (serve ${x.soglia}) ${x.tag}.${x.classe} ${x.px}px/${x.peso} ${x.colore} su ${x.sfondo} — «${x.testo}»`);
    // Le tre righe più vicine alla soglia: servono a vedere quanto si è al limite.
    const stretti = [...righe].sort((a, b) => (a.rapporto - a.soglia) - (b.rapporto - b.soglia)).slice(0, 3);
    for (const x of stretti)
      console.log(`  · ${x.rapporto}:1 (soglia ${x.soglia}) ${x.tag}.${x.classe} ${x.px}px/${x.peso} — «${x.testo}»`);
    await ctx.close();
  }
}
await browser.close();
console.log(`\n→ totale sotto la soglia AA su tutte le pagine e i formati: ${bocciatiTotali}`);
