// assets/js/calcolatori.js — I DUE CALCOLATORI DEL SITO. Giro W38.
//
// ⭐ IL PRIMO JAVASCRIPT VERO DEL SITO (`spec-sito.md` §6: JS minimo). Lo
// caricano solo le due pagine che hanno un calcolatore (`script_pagina`).
// ⛔ NON SALVA NIENTE E NON MANDA NIENTE: nessuna memoria del browser, nessun
// cookie, nessuna richiesta. La pagina lo dice, quindi deve essere vero — e lo
// misura il browser vero.
// ⛔ NESSUNA PAROLA QUI: etichette ed esiti stanno nella pagina (i file di
// `_data/`, di Cowork). Lo script scrive solo numeri, unità e «—», il segno
// vuoto dell'app.
//
// ⛔ I CONTI SONO QUELLI DELL'APP, letti nel suo codice in sola lettura
// (`AIMONX/Balistica.swift`, `AIMONX/CalcoloLotti.swift`, `AIMONX/Valuta.swift`)
// e nelle sue regole (`prodotto.md` §17.11, §17.12, §17.13):
//   · la velocità in fps si porta in m/s (× 0,3048) e di lì si ricalcola, come
//     fa l'app, che la tiene in m/s;
//   · Power Factor = grani × fps / 1000, intero coi decimali SCARTATI, dopo
//     averlo arrotondato a sei decimali (l'app fa così per assorbire il viaggio
//     fps → m/s → fps: 124 gr a 1.050 fps non deve uscire 129);
//   · energia = ½ m v², in J coi m/s e in ft·lb coi fps, senza decimali,
//     arrotondata come l'app (al pari più vicino);
//   · bossolo, innesco, palla = prezzo ÷ quantità; polvere = prezzo ÷ grani
//     della confezione × dose; 1 lb = 7000 gr, 1 gr = 64,79891 mg;
//   · i componenti fino a tre decimali, e così il costo per colpo totale
//     ($0.246); per 50, 100 e 1.000 a due. ⚠️ Nell'app il totale è a due: è
//     una scelta del sito (Pier, 09/11/2026, W39 — $0.25 accanto a $12.30 stonava).
(() => {
  "use strict";

  const M_PER_PIEDE = 0.3048;
  const KG_PER_GRANO = 0.00006479891;
  const J_PER_PIEDE_LIBBRA = 1.3558179483314004;
  const GRANI = [7000, 0.001 / KG_PER_GRANO, 1 / KG_PER_GRANO]; // lb, g, kg
  const lingua = document.documentElement.lang || "en-US";
  const VUOTO = "—";

  // ---- i conti dell'app -----------------------------------------------------
  const utile = (v) => (Number.isFinite(v) && v > 0 ? v : null);
  const inMs = (v, unita) => (unita === "fps" ? v * M_PER_PIEDE : v);
  function powerFactor(grani, ms) {
    const g = utile(grani), v = utile(ms);
    if (g === null || v === null) return null;
    const pf = g * (v / M_PER_PIEDE) / 1000;
    return Math.trunc(Math.round(pf * 1e6) / 1e6);
  }
  function energiaJoule(grani, ms) {
    const g = utile(grani), v = utile(ms);
    if (g === null || v === null) return null;
    return 0.5 * (g * KG_PER_GRANO) * v * v;
  }

  // ---- i numeri a schermo ---------------------------------------------------
  const numero = (cifre) => new Intl.NumberFormat(lingua, { maximumFractionDigits: cifre, roundingMode: "halfEven" });
  const intero = numero(0);
  const valuta = (codice, min, max) => new Intl.NumberFormat(lingua, {
    style: "currency", currency: codice, minimumFractionDigits: min, maximumFractionDigits: max, roundingMode: "halfEven",
  });

  // Un campo: vuoto (null), oppure un numero (NaN se scritto male).
  function leggi(input) {
    if (!input) return null;
    if (input.validity && input.validity.badInput) return NaN;
    if (input.value.trim() === "") return null;
    return Number(input.value);
  }
  const scelta = (form, nome) => (form.querySelector(`input[name="${nome}"]:checked`) || {}).value;

  // ---- il Power Factor ------------------------------------------------------
  function calcolatorePF(form) {
    const peso = form.querySelector("#pf-peso");
    const vel = form.querySelector("#pf-velocita");
    const outPF = form.querySelector("[data-pf]");
    const outE = form.querySelector("[data-energia]");
    const manca = form.querySelector("[data-manca]");
    const blocco = form.querySelector("[data-divisione]");
    const select = form.querySelector("#pf-divisione");
    const esito = form.querySelector("[data-esito]");
    const soloMinor = form.querySelector("[data-solo-minor]");
    const tabelle = [...document.querySelectorAll("table.soglie")];

    function riempiDivisioni() {
      const gara = scelta(form, "gara");
      const t = tabelle.find((x) => x.dataset.gara === gara);
      const prima = select.value;
      select.replaceChildren(...(t ? [...t.querySelectorAll("tbody tr")] : []).map((r) => {
        const o = document.createElement("option");
        o.value = o.textContent = r.dataset.divisione;
        return o;
      }));
      if ([...select.options].some((o) => o.value === prima)) select.value = prima;
    }

    function aggiorna() {
      const unita = scelta(form, "unita_velocita");
      const g = leggi(peso), v = leggi(vel);
      const ms = v === null ? null : inMs(v, unita);
      const pf = powerFactor(g, ms);
      const e = energiaJoule(g, ms);
      outPF.textContent = pf === null ? VUOTO : intero.format(pf);
      outE.textContent = e === null ? VUOTO
        : unita === "fps" ? `${intero.format(e / J_PER_PIEDE_LIBBRA)} ${form.dataset.ftlb}`
          : `${intero.format(e)} ${form.dataset.joule}`;
      manca.hidden = pf !== null;
      blocco.hidden = pf === null;

      // Le soglie superate si accendono in tutte e due le tabelle; la riga
      // della divisione scelta si segna.
      const gara = scelta(form, "gara");
      tabelle.forEach((t) => {
        t.querySelectorAll("td[data-soglia]").forEach((td) => {
          td.classList.toggle("superata", pf !== null && pf >= Number(td.dataset.soglia));
        });
        t.querySelectorAll("tbody tr").forEach((r) => {
          r.classList.toggle("scelta", pf !== null && t.dataset.gara === gara && r.dataset.divisione === select.value);
        });
      });
      if (pf === null) { esito.textContent = ""; soloMinor.hidden = true; return; }
      const t = tabelle.find((x) => x.dataset.gara === gara);
      const riga = t && [...t.querySelectorAll("tbody tr")].find((r) => r.dataset.divisione === select.value);
      if (!riga) return;
      const [cMajor, cMinor] = riga.querySelectorAll("td");
      const major = cMajor && cMajor.dataset.soglia ? Number(cMajor.dataset.soglia) : null;
      const minor = Number(cMinor.dataset.soglia);
      esito.textContent = major !== null && pf >= major ? form.dataset.major
        : pf >= minor ? form.dataset.minor : form.dataset.sotto;
      esito.dataset.livello = major !== null && pf >= major ? "major" : pf >= minor ? "minor" : "sotto";
      soloMinor.hidden = major !== null;
    }

    form.addEventListener("input", aggiorna);
    form.addEventListener("change", (ev) => { if (ev.target.name === "gara") riempiDivisioni(); aggiorna(); });
    form.addEventListener("submit", (ev) => ev.preventDefault());
    riempiDivisioni();
    aggiorna();
  }

  // ---- il costo della ricarica ---------------------------------------------
  function calcolatoreRicarica(form) {
    const codice = form.dataset.valuta;
    const comp = valuta(codice, 2, 3);
    const tot = valuta(codice, 2, 2);
    const simbolo = (comp.formatToParts(0).find((p) => p.type === "currency") || {}).value || "";
    form.querySelectorAll(".valuta").forEach((s) => { s.textContent = simbolo; });
    const toccati = new Set();
    let mostraTutto = false;

    const campo = (nome) => form.elements[nome];
    function errore(input, testo) {
      const p = input.closest(".campo").querySelector(".errore");
      const mostra = testo && (mostraTutto || toccati.has(input.name));
      p.hidden = !mostra;
      p.textContent = mostra ? testo : "";
      input.toggleAttribute("aria-invalid", Boolean(mostra));
      if (!("base" in input.dataset)) input.dataset.base = input.getAttribute("aria-describedby") || "";
      const legami = [input.dataset.base, mostra ? p.id : ""].filter(Boolean).join(" ");
      if (legami) input.setAttribute("aria-describedby", legami); else input.removeAttribute("aria-describedby");
      return Boolean(testo);
    }
    form.querySelectorAll(".errore").forEach((p, i) => { p.id = `r-errore-${i}`; });

    // Un componente si calcola se ne è scritto almeno un campo, e allora servono
    // tutti e due: il prezzo può essere 0, quantità e peso no (§17.12).
    function prezzoQuanti(pre) {
      const ip = campo(`${pre}_prezzo`), iq = campo(`${pre}_quanti`);
      const p = leggi(ip), q = leggi(iq);
      const scritto = p !== null || q !== null;
      const eP = scritto && !(Number.isFinite(p) && p >= 0) ? form.dataset.obbligatorio : "";
      const eQ = scritto && !(Number.isFinite(q) && q > 0) ? form.dataset.maggiore : "";
      const male = errore(ip, eP) | errore(iq, eQ);
      return { scritto, valore: scritto && !male ? p / q : null, male: Boolean(male) };
    }
    function polvere() {
      const ip = campo("w_prezzo"), ic = campo("w_confezione"), id = campo("w_dose");
      const p = leggi(ip), c = leggi(ic), d = leggi(id);
      const scritto = p !== null || c !== null;
      const eP = scritto && !(Number.isFinite(p) && p >= 0) ? form.dataset.obbligatorio : "";
      const eC = scritto && !(Number.isFinite(c) && c > 0) ? form.dataset.maggiore : "";
      // La polvere senza dose non si calcola, e non è un errore; una dose scritta male sì.
      const eD = d !== null && !(Number.isFinite(d) && d > 0) ? form.dataset.maggiore : "";
      const male = errore(ip, eP) | errore(ic, eC) | errore(id, eD);
      const grani = Number.isFinite(c) ? c * GRANI[Number(scelta(form, "w_unita"))] : null;
      const valore = scritto && !male && d !== null ? p / grani * d : null;
      return { scritto, valore, male: Boolean(male) };
    }

    let ultimo = null;
    function aggiorna() {
      const b = prezzoQuanti("b");
      const volte = leggi(campo("b_volte"));
      const eV = volte !== null && !(Number.isFinite(volte) && volte > 0) ? form.dataset.maggiore : "";
      const maleV = errore(campo("b_volte"), eV);
      if (b.valore !== null) b.valore = maleV ? null : b.valore / (volte === null ? 1 : volte);
      b.male = b.male || maleV;
      const r = { bossoli: b, inneschi: prezzoQuanti("i"), palle: prezzoQuanti("p"), polvere: polvere() };
      Object.entries(r).forEach(([k, x]) => {
        form.querySelector(`[data-componente="${k}"] [data-costo]`).textContent = x.valore === null ? VUOTO : comp.format(x.valore);
      });
      const calcolati = Object.values(r).filter((x) => x.valore !== null);
      const somma = calcolati.reduce((s, x) => s + x.valore, 0);
      form.querySelectorAll("[data-totale]").forEach((o) => {
        const n = Number(o.dataset.totale);
        o.textContent = calcolati.length ? (n === 1 ? comp : tot).format(somma * n) : VUOTO;
      });
      const ms = (() => { const v = leggi(campo("velocita")); return v === null ? null : inMs(v, scelta(form, "unita_velocita")); })();
      const pf = powerFactor(leggi(campo("p_peso")), ms);
      form.querySelector("[data-pf]").textContent = pf === null ? VUOTO : intero.format(pf);
      ultimo = { r, somma, calcolati: calcolati.length, pf };
      return Object.values(r).some((x) => x.male);
    }

    // ---- la scheda da stampare ----
    const scheda = document.querySelector(".scheda-carico");
    // Fuori dal foglio, figlia diretta della pagina: in stampa esce solo lei.
    document.body.append(scheda);
    document.body.classList.add("ha-scheda");
    const testo = (n) => (campo(n) ? campo(n).value.trim() : "");
    const conUnita = (n, u) => (testo(n) ? `${numero(6).format(Number(testo(n)))} ${u}` : "");
    const etichettaScelta = (n) => {
      const i = form.querySelector(`input[name="${n}"]:checked`);
      return i ? i.nextElementSibling.textContent : "";
    };
    function riempiScheda() {
      aggiorna();
      const { r, somma, calcolati, pf } = ultimo;
      const val = {
        nome: testo("nome"), calibro: testo("calibro"),
        data: new Intl.DateTimeFormat(lingua, { dateStyle: "long" }).format(new Date()),
        p_nome: testo("p_nome"), w_nome: testo("w_nome"),
        w_dose: testo("w_dose") ? numero(6).format(Number(testo("w_dose"))) : "",
        p_peso: testo("p_peso") ? numero(6).format(Number(testo("p_peso"))) : "",
        col: conUnita("col", etichettaScelta("col_unita")),
        velocita: conUnita("velocita", etichettaScelta("unita_velocita")),
        pf: pf === null ? "" : intero.format(pf),
        note: testo("note"),
        b_volte: testo("b_volte") ? numero(6).format(Number(testo("b_volte"))) : "",
        w_confezione: conUnita("w_confezione", etichettaScelta("w_unita")),
      };
      ["b", "i", "p", "w"].forEach((k) => {
        val[`${k}_prezzo`] = testo(`${k}_prezzo`) ? comp.format(Number(testo(`${k}_prezzo`))) : "";
        if (k !== "w") val[`${k}_quanti`] = testo(`${k}_quanti`) ? numero(6).format(Number(testo(`${k}_quanti`))) : "";
      });
      Object.entries(r).forEach(([k, x]) => { val[`c_${k}`] = x.valore === null ? "" : comp.format(x.valore); });
      [1, 50, 100, 1000].forEach((n) => { val[`t${n}`] = calcolati ? (n === 1 ? comp : tot).format(somma * n) : ""; });
      scheda.querySelectorAll("[data-campo]").forEach((e) => { e.textContent = val[e.dataset.campo] || ""; });
      // Solo i campi scritti: una riga senza niente non esce.
      const righe = {
        bossoli: r.bossoli.scritto, bossoli_volte: Boolean(val.b_volte), inneschi: r.inneschi.scritto,
        palle: r.palle.scritto || Boolean(val.p_nome), polvere: r.polvere.scritto || Boolean(val.w_nome),
      };
      scheda.querySelectorAll("[data-riga]").forEach((e) => {
        const k = e.dataset.riga;
        e.hidden = k in righe ? !righe[k] : !val[k];
      });
      scheda.querySelector(".scheda-componenti").hidden = !Object.values(righe).some(Boolean);
      scheda.querySelector(".scheda-totali").hidden = !calcolati;
      scheda.querySelector("[data-campo='nome']").hidden = !val.nome;
      scheda.querySelector("[data-campo='calibro']").hidden = !val.calibro;
    }
    window.addEventListener("beforeprint", riempiScheda);

    form.addEventListener("input", aggiorna);
    form.addEventListener("change", aggiorna);
    form.addEventListener("focusout", (ev) => { if (ev.target.name) { toccati.add(ev.target.name); aggiorna(); } });
    form.addEventListener("submit", (ev) => ev.preventDefault());
    form.querySelector("[data-stampa]").addEventListener("click", () => {
      mostraTutto = true;
      if (aggiorna()) {
        const primo = form.querySelector("[aria-invalid]");
        if (primo) primo.focus();
        return;
      }
      riempiScheda();
      window.print();
    });
    aggiorna();
  }

  document.querySelectorAll("form[data-calcolatore='pf']").forEach(calcolatorePF);
  document.querySelectorAll("form[data-calcolatore='ricarica']").forEach(calcolatoreRicarica);
})();
