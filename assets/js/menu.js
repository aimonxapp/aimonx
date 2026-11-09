// assets/js/menu.js — il passaggio del mouse, Esc e il clic fuori, per il menu
// in alto. Giro W24, ⭐ giro W39 (Pier, 09/11/2026: «passandoci sopra si aprono
// bene le sottovoci», come su apple.com).
//
// ⛔ SOLO QUESTO. Aprire e chiudere col clic, col tocco, con Invio e con lo
// spazio lo fa già il browser, perché le sezioni sono `<details>` (la nota in
// `_includes/barra.html`): senza questo file il menu funziona uguale, e si
// perdono solo il passaggio del mouse, Esc e il clic fuori.
//   · PASSAGGIO DEL MOUSE: solo col mouse vero (`pointerType`), solo quando le
//     sezioni sono in riga (sul computer), e con un attimo di ritardo, in
//     entrata e in uscita, perché un mouse che attraversa la barra non apra e
//     chiuda tutto. Si apre una sezione alla volta.
//     ⚠️ Un clic su una sezione appena aperta dal mouse la lascia aperta: se
//     no il gesto di chi passa e poi clicca la chiuderebbe sotto la sua mano.
//   · Esc chiude ciò che è aperto e riporta il fuoco sul pulsante che si vede.
//   · Un clic fuori dalla sezione (anche sulla pagina sfocata dietro) la chiude.
// ⛔ Nessuna libreria, nessuna richiesta, nessuna parola: spec-sito.md §6.
(function () {
  'use strict';
  var barra = document.querySelector('.barra');
  if (!barra) return;

  var sezioni = barra.querySelectorAll('.sezione');
  var inRiga = window.matchMedia('(min-width: 1060px)');
  var timer = null;
  var dalMouse = null;

  function chiudiTutte(tranne) {
    for (var i = 0; i < sezioni.length; i++) {
      var d = sezioni[i].querySelector('details.tendina');
      if (d !== tranne) d.open = false;
    }
  }

  for (var i = 0; i < sezioni.length; i++) {
    (function (li) {
      var d = li.querySelector('details.tendina');
      li.addEventListener('pointerenter', function (e) {
        if (e.pointerType !== 'mouse' || !inRiga.matches) return;
        clearTimeout(timer);
        // Se un'altra sezione è già aperta si passa subito; se no, un attimo.
        var giaAperta = barra.querySelector('.sezione details.tendina[open]');
        timer = setTimeout(function () {
          chiudiTutte(d);
          if (!d.open) { d.open = true; dalMouse = d; }
        }, giaAperta ? 60 : 160);
      });
      li.addEventListener('pointerleave', function (e) {
        if (e.pointerType !== 'mouse' || !inRiga.matches) return;
        clearTimeout(timer);
        timer = setTimeout(function () {
          if (d.open && dalMouse === d) { d.open = false; dalMouse = null; }
        }, 260);
      });
      d.querySelector('summary').addEventListener('click', function (e) {
        if (dalMouse === d && d.open) { e.preventDefault(); dalMouse = null; return; }
        dalMouse = null;
        // Col clic, una sezione alla volta come col mouse.
        if (!d.open) chiudiTutte(d);
      });
    })(sezioni[i]);
  }

  // Aperto o chiuso «Menu», le sezioni dentro ripartono chiuse: se no una
  // resterebbe aperta di nascosto, e al primo Esc si chiuderebbe lei invece di
  // «Menu». ⚠️ Sul CLIC del pulsante (Invio e spazio passano di lì), che è
  // sincrono: l'evento `toggle` arriva dopo, e fra i due chi usa la tastiera
  // può già aver aperto una sezione — misurato da `scripts/tastiera.mjs`, due
  // volte (prima 12 pagine su 75, poi 10).
  var apri = barra.querySelector('details.apri');
  if (apri) apri.querySelector('summary').addEventListener('click', function () {
    var dentro = barra.querySelectorAll('.voci-barra details[open]');
    for (var i = 0; i < dentro.length; i++) dentro[i].open = false;
  });

  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape') return;
    // Si chiude il più interno FRA QUELLI CHE SI VEDONO, e il fuoco torna sul
    // suo pulsante: sul telefono il primo Esc chiude la sezione aperta, il
    // secondo «Menu».
    var aperti = [].filter.call(barra.querySelectorAll('details[open]'), function (d) {
      return d.querySelector('summary').getClientRects().length;
    });
    if (!aperti.length) return;
    var ultimo = aperti[aperti.length - 1];
    ultimo.open = false;
    dalMouse = null;
    var s = ultimo.querySelector('summary');
    if (s && s.getClientRects().length) s.focus();
  });

  document.addEventListener('click', function (e) {
    // `.sezione` (e `.lingue`) tiene il pulsante e il suo pannello: un clic lì
    // non è «fuori». ⚠️ Solo sul computer: sul telefono le sezioni stanno nel
    // pannello del «Menu», e chiuderle a un tocco altrove sarebbe un dispetto.
    var t = document.querySelectorAll('.barra .sezione details.tendina[open], .barra .lingue details.tendina-lingue[open]');
    for (var i = 0; i < t.length; i++) {
      if (!inRiga.matches && t[i].classList.contains('tendina')) continue;
      if (!t[i].parentNode.contains(e.target)) { t[i].open = false; if (dalMouse === t[i]) dalMouse = null; }
    }
  });
})();
