// assets/js/menu.js — Esc e il clic fuori, per il menu in alto. Giro W24.
//
// ⭐ Deciso da Pier il 16/10/2026: Esc chiude la tendina «Features» del
// computer e il pannello del telefono, e riporta il fuoco sul pulsante che li
// aveva aperti; un clic fuori dalla tendina la chiude.
// ⛔ SOLO QUESTO. Aprire e chiudere col pulsante lo fa già il browser, perché
// sono `<details>` (la nota in `_includes/barra.html`): senza questo file il
// menu funziona uguale, e si perdono solo Esc e il clic fuori.
// ⛔ Nessuna libreria, nessuna richiesta, nessuna parola: spec-sito.md §6.
(function () {
  'use strict';
  var barra = document.querySelector('.barra');
  if (!barra) return;

  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape') return;
    var aperti = barra.querySelectorAll('details[open]');
    var torna = null;
    for (var i = 0; i < aperti.length; i++) {
      aperti[i].open = false;
      var s = aperti[i].querySelector('summary');
      // Il fuoco torna sul pulsante che si vede: sul telefono la tendina c'è
      // ma è nascosta, e il pulsante giusto è «Menu».
      if (s && s.getClientRects().length) torna = s;
    }
    if (torna) torna.focus();
  });

  document.addEventListener('click', function (e) {
    var t = barra.querySelector('details.tendina[open]');
    // `.con-tendina` tiene il pulsante e le sue voci: un clic lì non è «fuori».
    if (t && !t.parentNode.contains(e.target)) t.open = false;
  });
})();
