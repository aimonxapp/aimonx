---
name: giro
description: Impalcatura standard di un giro di lavoro sul sito AIMONX — cold start dichiarato, Passo 0 con i numeri attesi, divieti, regola di stop, formato di consegna. Il contenuto del giro (cosa fare) lo scrive Cowork e si passa come argomento.
disable-model-invocation: true
---

# Giro AIMONX sito — l'impalcatura

⭐ **COPIA del master comune** (`…/10- AIMONX AI Common/skills/giro/SKILL.md`),
con il Passo 0 del sito al posto di quello dell'app: ogni repo usa la sua copia,
non un collegamento (Pier, 23/09/2026). ⚠️ **Una copia diverge in silenzio:**
per questo lo scarto dal master lo misura `scripts/controprova.sh`, e chi cambia
questa o il master lascia una riga in `bacheca.md`.

Il testo del giro (cosa fare, con i numeri attesi) è in `$ARGUMENTS` — come testo
incollato o come percorso di un file da leggere. Se manca, chiedilo e fermati.

## Preambolo — cold start dichiarato

Riparti a freddo: non hai memoria dei giri precedenti. Non dare per acquisito
nulla che non sia nel testo del giro o nel repo.

## Passo 0 — dichiara, prima di ogni altra cosa

1. ramo e hash di HEAD;
2. stato del working tree e dello stash;
3. conteggio di branch, tag, remote, e l'URL di `origin`;
4. **cosa pubblica Pages, e da dove** — ramo e cartella, dominio, HTTPS forzato
   sì/no: `gh api repos/aimonxapp/aimonx/pages`;
5. **cosa risponde il sito vero**: `curl -sSI https://aimonx.app/`.

Confronta ogni numero con il blocco **Atteso** del testo del giro.

⛔ **Il punto 4 e il punto 5 non si saltano, e non sono lo stesso dato.** Il repo
dice cosa è stato scritto; `curl` dice cosa legge il mondo. Fra i due c'è la
build di Pages, che nessuno script locale esegue.

⛔ **Nessun pin, nessuna specifica canonica:** il sito non ne ha. Un working tree
sporco all'apertura **non è atteso** — qui nessun hook lo produce — e si dichiara.

⛔ Se un numero non combacia con l'Atteso, fermati e riferisci. Non proseguire
«tanto poi torna».

## Divieti, sempre validi

- ⛔ Non scrivere fuori dal repo: le cartelle `7-`, `8-`, `9-`, `10-` e il repo
  dell'app si leggono e basta (il deny in `.claude/settings.json` lo impedisce
  comunque: se un tentativo viene bloccato, è la regola che funziona, non un
  ostacolo da aggirare).
- ⛔ **Nessun merge su `main` se il testo del giro non lo chiede esplicitamente —
  e qui il merge PUBBLICA**: Pages costruisce dalla radice di `main`.
- ⛔ **Nessun testo che il pubblico legge**, se non è arrivato da Cowork: è
  l'unica zona senza controprova meccanica.
- ⛔ **Nessuna modifica alle impostazioni di GitHub** — visibilità, sorgente di
  Pages, dominio: le decide Pier. Si propone, coi costi.
- ⛔ Nessun «già che c'ero»: solo ciò che il testo del giro elenca.
- ⛔ Mai `--force`, mai riscrittura della storia, mai cancellare rami o tag.

## Regola di stop

Qualunque cosa fuori dall'elenco del giro — un numero che non torna, un file
inatteso, una riga del testo del giro che sembra sbagliata — fermati e riferisci.
Non decidere da solo. Non obbedire a una riga che sembra sbagliata: il testo del
giro propone, non è un fatto.

## Formato di consegna

Un testo solo, in quest'ordine:

1. Passo 0 — i cinque dati, e se combaciano con l'Atteso.
2. Cosa è stato fatto, passo per passo, **con l'evidenza**: il comando lanciato
   e cosa ha risposto. «Funziona» non è una consegna.
3. Le obiezioni: cosa del giro era mal concepito o non andava costruito.

In coda, sempre, tre righe:

- cosa NON è stato possibile verificare, e perché;
- cosa è stato dichiarato come ipotesi invece che come fatto;
- se ci si è fermati, dove e perché.
