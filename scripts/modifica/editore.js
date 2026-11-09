// scripts/modifica/editore.js — LA MODALITÀ MODIFICA, nel browser di Pier. Giro W37.
//
// ⛔ NON È UNO SCRIPT DEL SITO e non va mai online: lo aggiunge a ogni pagina
// `server.rb` MENTRE la serve sul Mac di Pier. Il sito costruito non lo nomina,
// e la controprova lo misura (`attrezzo_nel_sito`).
// ⭐ Le scritte qui dentro sono per Pier, in italiano, e non sono testo pubblico.
//
// Cosa fa:
//   · tiene la pagina aggiornata da sola: quando il sito è stato ricostruito
//     (un testo o uno stile salvato), la ricarica, e torna dov'era;
//   · col pulsante «Modifica» segna i testi che si possono cambiare: un clic,
//     si scrive, Invio salva — nel file della lingua della pagina;
//   · ⭐ Option+Invio (Pier, 09/11/2026) va A CAPO: nel file diventa `<br>`, e
//     il server lo rifiuta dove un `<br>` non si leggerebbe (`testi.rb`);
//   · «Testi nascosti» apre il titolo e la descrizione per Google e i testi
//     alternativi delle immagini.
(() => {
  "use strict";
  const MIO = "data-modifica";
  const ESCLUSI = new Set(["SCRIPT", "STYLE", "NOSCRIPT", "TEMPLATE"]);
  const url = location.pathname;
  let versione = null;
  let lingua = "";
  let attiva = false;
  let segnati = [];

  const memo = {
    get(k) { try { return sessionStorage.getItem(k); } catch { return null; } },
    set(k, v) { try { sessionStorage.setItem(k, v); } catch { /* niente */ } },
    del(k) { try { sessionStorage.removeItem(k); } catch { /* niente */ } },
  };

  // ---- l'interfaccia -------------------------------------------------------
  const el = (tag, attr = {}, ...figli) => {
    const e = document.createElement(tag);
    for (const [k, v] of Object.entries(attr)) {
      if (k === "testo") e.textContent = v; else e.setAttribute(k, v);
    }
    e.setAttribute(MIO, "");
    figli.forEach((f) => e.append(f));
    return e;
  };
  const barra = el("div", { class: "mod-barra" });
  const bottone = el("button", { type: "button", class: "mod-bottone", testo: "✏️ Modifica" });
  const nascosti = el("button", { type: "button", class: "mod-bottone mod-secondario", testo: "Testi nascosti" });
  const scritta = el("span", { class: "mod-scritta" });
  barra.append(bottone, nascosti, scritta);
  const avviso = el("div", { class: "mod-avviso", role: "status" });
  const fascia = el("div", { class: "mod-fascia" });
  const pannello = el("div", { class: "mod-pannello", hidden: "" });
  document.body.append(fascia, barra, avviso, pannello);
  nascosti.hidden = true;
  bottone.disabled = true; // finché non si sa a che versione del sito è la pagina

  let timerAvviso;
  function avvisa(testo, tipo = "info", durata = 6000) {
    avviso.textContent = testo;
    avviso.className = "mod-avviso mod-" + tipo + " mod-visibile";
    clearTimeout(timerAvviso);
    if (durata) timerAvviso = setTimeout(() => avviso.classList.remove("mod-visibile"), durata);
  }

  // ---- il testo della pagina, contato come lo conta il server -------------
  function nodiDiTesto() {
    const out = [];
    let pos = 0;
    const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
      acceptNode(n) {
        for (let a = n.parentNode; a && a !== document.body; a = a.parentNode) {
          if (a.nodeType === 1 && (ESCLUSI.has(a.tagName) || a.hasAttribute(MIO))) return NodeFilter.FILTER_REJECT;
        }
        return NodeFilter.FILTER_ACCEPT;
      },
    });
    for (let n = w.nextNode(); n; n = w.nextNode()) {
      const t = n.data;
      const inizio = t.length - t.trimStart().length;
      const pezzo = t.trim();
      if (pezzo && /\p{L}/u.test(pezzo)) out.push({ nodo: n, testo: pezzo, posizione: pos + inizio });
      pos += t.length;
    }
    return out;
  }

  function attributiDellaPagina() {
    const out = [];
    const t = document.querySelector("head title");
    if (t) out.push({ tipo: "title", indice: 0, nome: "Titolo per Google (la scheda del browser)", valore: t.textContent });
    const d = document.querySelector('head meta[name="description"]');
    if (d) out.push({ tipo: "description", indice: 0, nome: "Descrizione per Google", valore: d.content });
    // Lo stesso elenco del server: ogni immagine con il suo testo alternativo, in ordine.
    const imgs = [...document.body.querySelectorAll("img[alt]")].filter((i) => !i.closest(`[${MIO}]`));
    imgs.forEach((img, i) => {
      if (img.alt.trim()) out.push({ tipo: "alt", indice: i, nome: "Testo alternativo di un'immagine", valore: img.alt, img });
    });
    return out;
  }

  async function chiedi(nome, dati) {
    const r = await fetch("/__modifica/" + nome, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Modifica": "1" },
      body: JSON.stringify({ url, versione, ...dati }),
    });
    const j = await r.json().catch(() => ({ errore: "Risposta illeggibile dall'attrezzo." }));
    if (!r.ok) throw new Error(j.errore || "Errore " + r.status);
    return j;
  }

  // ---- la modalità modifica ------------------------------------------------
  async function accendi() {
    attiva = true;
    memo.set("mod-attiva", "1");
    document.documentElement.classList.add("mod-in-modifica");
    bottone.textContent = "✓ Esci dalla modifica";
    nascosti.hidden = false;
    fascia.textContent = `MODALITÀ MODIFICA · stai scrivendo in ${lingua.toUpperCase()} — cambia solo questa lingua`;
    fascia.classList.add("mod-visibile");
    const nodi = nodiDiTesto();
    let r;
    try {
      r = await chiedi("controlla", { testi: nodi.map(({ testo, posizione }) => ({ testo, posizione })), attributi: [] });
    } catch (e) {
      avvisa(e.message, "errore");
      if (/ricarica/.test(e.message)) location.reload();
      return;
    }
    let si = 0;
    nodi.forEach((n, i) => {
      const st = r.testi[i];
      const t = n.nodo.data;
      const a = t.length - t.trimStart().length;
      const span = document.createElement("span");
      span.className = st.esito === "ok" ? "mod-si" : "mod-no";
      if (st.esito === "ok") { si += 1; span.title = `${st.file} · ${st.chiave}`; } else span.title = st.perche;
      span.dataset.modPosizione = n.posizione;
      span.dataset.modPerche = st.perche || "";
      const r2 = document.createRange();
      r2.setStart(n.nodo, a);
      r2.setEnd(n.nodo, a + n.testo.length);
      r2.surroundContents(span);
      segnati.push(span);
    });
    avvisa(`Si possono cambiare ${si} testi su ${nodi.length}. Clicca un testo sottolineato in verde.`, "info", 5000);
  }

  function spegni() {
    attiva = false;
    memo.del("mod-attiva");
    location.reload();
  }

  bottone.addEventListener("click", () => (attiva ? spegni() : accendi()));
  nascosti.addEventListener("click", apriNascosti);

  // In modifica i link non portano via e i menu non si aprono: un clic è una scelta di testo.
  document.addEventListener("click", (ev) => {
    if (!attiva || ev.target.closest(`[${MIO}]`)) return;
    const s = ev.target.closest(".mod-si, .mod-no");
    ev.preventDefault();
    ev.stopPropagation();
    if (!s) return;
    if (s.classList.contains("mod-no")) { avvisa(s.dataset.modPerche, "attenzione", 9000); return; }
    if (s.isContentEditable) return;
    modifica(s);
  }, true);

  function modifica(span) {
    const vecchio = span.textContent;
    span.contentEditable = "plaintext-only";
    if (span.contentEditable !== "plaintext-only") span.contentEditable = "true";
    span.classList.add("mod-sto-scrivendo");
    span.focus();
    const sel = getSelection();
    sel.selectAllChildren(span);
    avvisa("Scrivi. Invio = salva · Option+Invio = a capo · Esc = annulla.", "info", 0);
    const fine = () => {
      span.removeEventListener("keydown", tasti);
      span.removeEventListener("blur", via);
      span.contentEditable = "false";
      span.classList.remove("mod-sto-scrivendo");
    };
    const annulla = () => { fine(); span.textContent = vecchio; avvisa("Annullato: niente è cambiato.", "info", 3000); };
    const salva = async () => {
      // Ogni riga ripulita dagli spazi doppi; fra una riga e l'altra resta l'a capo (`\n`).
      const nuovo = span.textContent.split("\n").map((r) => r.replace(/\s+/g, " ").trim()).filter(Boolean).join("\n");
      fine();
      if (nuovo === vecchio.trim()) { span.textContent = vecchio; avvisa("Niente da salvare.", "info", 2500); return; }
      avvisa("Salvo…", "info", 0);
      try {
        const r = await chiedi("salva", { tipo: "testo", vecchio, nuovo, posizione: Number(span.dataset.modPosizione) });
        avvisa(`Salvato in ${r.file}. La pagina si aggiorna da sola…`, "ok", 0);
        memo.set("mod-dopo", "1");
      } catch (e) {
        span.textContent = vecchio;
        avvisa(e.message, "errore", 10000);
      }
    };
    function tasti(ev) {
      if (ev.key === "Enter" && ev.altKey) { ev.preventDefault(); document.execCommand("insertText", false, "\n"); return; }
      if (ev.key === "Enter") { ev.preventDefault(); salva(); }
      if (ev.key === "Escape") { ev.preventDefault(); annulla(); }
    }
    function via() { if (span.textContent !== vecchio) salva(); else fine(); }
    span.addEventListener("keydown", tasti);
    span.addEventListener("blur", via);
  }

  // ---- i testi nascosti ----------------------------------------------------
  async function apriNascosti() {
    pannello.replaceChildren();
    pannello.hidden = false;
    const chiudi = el("button", { type: "button", class: "mod-bottone mod-secondario", testo: "Chiudi" });
    chiudi.addEventListener("click", () => { pannello.hidden = true; });
    pannello.append(el("h2", { testo: `Testi nascosti · ${lingua}` }),
      el("p", { testo: "Non si vedono sulla pagina, ma li leggono Google e chi usa un lettore di schermo." }));
    const attr = attributiDellaPagina();
    let r;
    try {
      r = await chiedi("controlla", { testi: [], attributi: attr.map(({ tipo, indice }) => ({ tipo, indice })) });
    } catch (e) { avvisa(e.message, "errore"); return; }
    attr.forEach((a, i) => {
      const st = r.attributi[i];
      const riga = el("div", { class: "mod-riga" });
      const etichetta = el("label", { testo: a.nome });
      if (a.img) {
        const mini = el("img", { src: a.img.currentSrc || a.img.src, alt: "", class: "mod-mini" });
        riga.append(mini);
      }
      riga.append(etichetta);
      if (st.esito !== "ok") {
        riga.append(el("p", { class: "mod-fisso", testo: a.valore }), el("p", { class: "mod-perche", testo: st.perche }));
      } else {
        const campo = el("textarea", { rows: "2" });
        campo.value = st.parte;
        const salva = el("button", { type: "button", class: "mod-bottone", testo: "Salva" });
        salva.addEventListener("click", async () => {
          const nuovo = campo.value.replace(/\s+/g, " ").trim();
          try {
            const x = await chiedi("salva", { tipo: a.tipo, indice: a.indice, vecchio: st.parte, nuovo });
            avvisa(`Salvato in ${x.file}. La pagina si aggiorna da sola…`, "ok", 0);
            memo.set("mod-nascosti", "1");
          } catch (e) { avvisa(e.message, "errore", 10000); }
        });
        riga.append(campo, el("p", { class: "mod-dove", testo: `${st.file} · ${st.chiave}` }), salva);
      }
      pannello.append(riga);
    });
    pannello.append(chiudi);
  }

  // ---- la pagina si aggiorna da sola ---------------------------------------
  async function guarda() {
    try {
      const r = await fetch("/__modifica/stato?url=" + encodeURIComponent(url), { cache: "no-store" });
      const s = await r.json();
      lingua = s.lingua;
      if (versione === null) { versione = s.versione; bottone.disabled = false; }
      if (s.versione !== versione && !s.costruisce) {
        memo.set("mod-scorri", String(scrollY));
        location.reload();
        return;
      }
      scritta.textContent = s.costruisce ? "⏳ sto ricostruendo il sito…" : `${lingua} · ramo ${s.ramo}`;
      if (s.errore) avvisa("⚠️ Il sito non si è costruito: " + s.errore, "errore", 0);
    } catch {
      scritta.textContent = "⚠️ l'attrezzo è spento: riaccendilo dall'icona";
    }
    setTimeout(guarda, 800);
  }

  (async () => {
    const y = memo.get("mod-scorri");
    if (y !== null) { memo.del("mod-scorri"); requestAnimationFrame(() => scrollTo(0, Number(y))); }
    await guarda();
    if (memo.get("mod-dopo")) {
      memo.del("mod-dopo");
      // ⚠️ Un a capo che la pagina scrive come segni («<br>») invece di andare a capo.
      if (/<br\s*\/?>/i.test(document.body.textContent)) avvisa("⚠️ Su questa pagina l'a capo si vede come «<br>»: chiedi a CC.", "errore", 0);
      else avvisa("Fatto: la pagina mostra il testo nuovo.", "ok", 4000);
    }
    if (memo.get("mod-attiva")) await accendi();
    if (memo.get("mod-nascosti")) { memo.del("mod-nascosti"); apriNascosti(); }
  })();
})();
