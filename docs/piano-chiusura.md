# Piano di chiusura del sito AIMONX

**Costruito su [`docs/aperti.md`](aperti.md). Obiettivo: pubblicare le pagine che sbloccano la submission dell'app** — landing, Privacy Policy, pagina di supporto.

**Una coda sola, una cosa alla volta.** ⛔ **Questo file dice l'ORDINE, non il merito:** cosa sia ciascuna voce sta nel registro, e lì si legge prima di toccarla.

⭐ **Ricalca la Fase E del piano dell'app** (`~/Developer/AIMONX/docs/piano-chiusura.md`): stesso ordine — `RD16` → `RA4` → `RA1 · RA2` → `RA3` → `RA11` — sulle gemelle del sito. ⚠️ **Con due vincoli che nel piano dell'app non ci sono** (W2 e W3 qui sotto), e ⛔ **con una Fase 0 che il piano dell'app non poteva prevedere**, perché nasce da ciò che il giro W0 ha misurato nel repo.

## Fase 0 — prima di ogni altra cosa, e il resto non parte senza

⛔ **Non è un preliminare di comodo: senza questi punti il lavoro non esce dal Mac, o esce in un posto sbagliato.** ⭐ **Chiusa tutta nel giro W1**, e resta scritta perché è l'ordine che ha reso possibile il primo push — non perché aspetti ancora qualcosa.

| # | Voce | Cosa | Chi | Perché lì |
|---|---|---|---|---|
| W0-a | **WD17** | ✅ **deciso da Pier il 21/09/2026 e FATTO nel giro W1**: repo pubblico, percorsi del suo disco fuori da tutti i file tracciati, e un controllo in controprova che lo tiene vero | P ha deciso, CC ha eseguito | ⛔ **Va fatto PRIMA del primo push**, non dopo: un push a un repo pubblico non si annulla leggendo, e chi ha già letto ha letto |
| W0-b | **WA15** | ✅ **FATTA nel giro W1**: `gh auth login` di `aimonxapp` (Pier), e un credential helper **locale al repo sito** che prende il token di quell'account senza toccare l'attivo | P + CC | ⛔ Finché il push non passa, **nessun ramo di lavoro arriva su GitHub e niente si pubblica.** ⚠️ Viene dopo W0-a di proposito: sbloccare il push senza aver deciso cosa ci va sopra è il verso sbagliato |
| W0-c | **WA16** | ✅ **FATTA da Pier il 21/09/2026**, e misurata nel giro W1: `https_enforced: true`, `http://` → `301` | P | Una spunta, e ⛔ **la mette Pier**: è un'impostazione di GitHub. Sta qui e non più in basso perché ⚠️ costa un minuto e riguarda **ogni** pagina che verrà pubblicata dopo, `WA1` compresa |
| W0-d | **WD22** | ✅ **FATTA nel giro W1**: Pier ha sbloccato la scrittura su `.claude/`, il recinto è in `.claude/settings.local.json`, e **è stato riprovato dopo lo spostamento** | P ha sbloccato, CC ha eseguito | ⛔ **Era l'ultimo pezzo di W0-a**, e senza non si poteva pushare |

## Fase W — il sito

| # | Voce | Cosa | Chi | Perché lì |
|---|---|---|---|---|
| W1 | **WD16** | ✅ **`.gitignore` scritto nel giro W1** · ⏳ **resta la licenza, e la sceglie Pier** | P sceglie la licenza | Prima di pubblicarci sopra. ⚠️ **Il repo è pubblico e senza licenza:** per difetto è «tutti i diritti riservati», e va scelto invece che subìto |
| W2 | **—** | ⛔ **Cowork riallinea `spec-sito.md` a `~/Developer/AIMONX/docs/prodotto.md`** | CW | ⭐ **Non è una voce del registro: è un lavoro fuori dal repo che deve accadere prima.** `spec-sito.md` è ferma a luglio e si fonda su `specifiche-aimonx.md`, che nel frattempo è diventata **archivio**; l'autorità viva su cosa fa l'app è `~/Developer/AIMONX/docs/prodotto.md`. ⛔ **Scrivere pagine contro una spec disallineata significa promettere funzioni che non ci sono** — è la trappola del sito |
| W3 | **WD19** | ✅ **scelto da Pier il 21/09/2026: Jekyll.** `_config.yml` è sul ramo dal giro W1; ⏳ **resta da provare che l'esclusione tenga** (`WD25`) | P ha scelto, CC costruisce | ⛔ **Il criterio scritto prima qui era sbagliato:** diceva *«quanto costa a Pier cambiare un testo da solo»*, ma **Pier non scrive codice.** ⭐ **I costi si misurano sul lavoro dei giri e sul rischio.** Prima di `WA4`, perché le pagine si scrivono **in** qualcosa |
| W4 | **WA4** | il contenuto del sito — le pagine del set minimo | P + CW scrivono, CC costruisce | ⭐ La catena tecnica è già in piedi: manca il testo, non l'infrastruttura. Dopo W2 e W3, che sono le sue due condizioni |
| W5 | **WA1 · WA2** | Privacy Policy e Support URL online | P + CW | ⛔ Senza queste due la submission dell'app non parte. Hanno bisogno di W4 per avere dove vivere |
| W6 | **WA3** | accertare se i ToS sono obbligatori | CW | Due sezioni della fonte dicono cose diverse e nessuna cita Apple. ⚠️ **È una domanda, non una pagina:** se la risposta è sì, la pagina è un lavoro di W4 |
| W7 | **WA11** | scheda App Store anche in italiano | P + CW | La primaria è inglese USA. ⚠️ **Si compila in App Store Connect, non sul sito:** sta in coda perché condivide i testi con le pagine di W4, e riscriverli due volte sarebbe lavoro doppio |

## I vincoli che fissano l'ordine

| Vincolo | Conseguenza |
|---|---|
| **Un repo pubblico non si «de-pubblica» leggendo** | `WD17` prima del primo push, non dopo |
| **Senza push niente arriva su GitHub** | `WA15` prima di qualunque lavoro che debba uscire dal Mac |
| **Il merge su `main` PUBBLICA** (Pages costruisce dalla radice di `main`) | ogni merge è un'autorizzazione di Pier, e va letto come «metto online», non come «salvo» |
| **Il sito non promette ciò che l'app non fa** | W2 prima di W4, sempre — e la verifica è contro `~/Developer/AIMONX/docs/prodotto.md`, non contro `spec-sito.md` |
| **Le pagine si scrivono in qualcosa** | W3 prima di W4 |
| **Una lista di esclusioni fallisce APERTA** | `WD25` prima del merge: `exclude` nega ciò che nomina, e un file nuovo è pubblicato finché qualcuno non se ne accorge |
| **`WA1` e `WA2` hanno bisogno di un sito che esista** | W4 prima di W5 |

## Cosa questo piano NON copre, e dichiarato

- ⛔ **Le gemelle restano aperte anche nel registro dell'app:** chiudere `WA1` qui non chiude `RA1` là. Il piano dell'app ha la sua Fase E, e i due si tengono al passo via `bacheca.md`.
- ⛔ **I social non sono in questo piano.** Decisione di Pier: il sito viene prima, i social si fanno sull'app finita.
- ⚠️ **`WD18`, `WD20`, `WD21`, `WD23` e `WD24` non hanno un posto in coda**, e non è una dimenticanza: sono debiti di documento che si chiudono quando si tocca il documento, non voci che bloccano qualcos'altro.
