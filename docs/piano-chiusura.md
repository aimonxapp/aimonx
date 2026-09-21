# Piano di chiusura del sito AIMONX

**Costruito su [`docs/aperti.md`](aperti.md). Obiettivo: pubblicare le pagine che sbloccano la submission dell'app** — landing, Privacy Policy, pagina di supporto.

**Una coda sola, una cosa alla volta.** ⛔ **Questo file dice l'ORDINE, non il merito:** cosa sia ciascuna voce sta nel registro, e lì si legge prima di toccarla.

⭐ **Ricalca la Fase E del piano dell'app** (`~/Developer/AIMONX/docs/piano-chiusura.md`): stesso ordine — `RD16` → `RA4` → `RA1 · RA2` → `RA3` → `RA11` — sulle gemelle del sito. ⚠️ **Con due vincoli che nel piano dell'app non ci sono** (W2 e W3 qui sotto), e ⛔ **con una Fase 0 che il piano dell'app non poteva prevedere**, perché nasce da ciò che il giro W0 ha misurato nel repo.

## Fase 0 — prima di ogni altra cosa, e il resto non parte senza

⛔ **Non è un preliminare di comodo: senza questi tre punti il lavoro non esce dal Mac, o esce in un posto sbagliato.** Tutti e tre sono di Pier, e sono decisioni, non lavoro.

| # | Voce | Cosa | Chi | Perché lì |
|---|---|---|---|---|
| W0-a | **WD17** | decidere cosa può stare in un repo **pubblico** — i file di lavoro al push, le pagine al merge | P | ⛔ **Va deciso PRIMA del primo push**, non dopo: un push a un repo pubblico non si annulla leggendo, e chi ha già letto ha letto. Le tre strade coi costi stanno nel verbale del giro W0 |
| W0-b | **WA15** | sbloccare il push verso `aimonxapp/aimonx` — accesso in scrittura a `Pier974`, oppure autenticare `aimonxapp` | P | ⛔ Finché il push non passa, **nessun ramo di lavoro arriva su GitHub e niente si pubblica.** ⚠️ Viene dopo W0-a di proposito: sbloccare il push senza aver deciso cosa ci va sopra è il verso sbagliato |
| W0-c | **WA16** | *Enforce HTTPS* in GitHub → Settings → Pages | P | Una spunta, e ⛔ **la mette Pier**: è un'impostazione di GitHub. Sta qui e non più in basso perché ⚠️ costa un minuto e riguarda **ogni** pagina che verrà pubblicata dopo, `WA1` compresa |

## Fase W — il sito

| # | Voce | Cosa | Chi | Perché lì |
|---|---|---|---|---|
| W1 | **WD16** | igiene del repo: `.gitignore` e licenza | P sceglie la licenza, CC scrive il `.gitignore` | Prima di pubblicarci sopra. ⚠️ **Il repo è pubblico e senza licenza:** per difetto è «tutti i diritti riservati», e va scelto invece che subìto |
| W2 | **—** | ⛔ **Cowork riallinea `spec-sito.md` a `~/Developer/AIMONX/docs/prodotto.md`** | CW | ⭐ **Non è una voce del registro: è un lavoro fuori dal repo che deve accadere prima.** `spec-sito.md` è ferma a luglio e si fonda su `specifiche-aimonx.md`, che nel frattempo è diventata **archivio**; l'autorità viva su cosa fa l'app è `~/Developer/AIMONX/docs/prodotto.md`. ⛔ **Scrivere pagine contro una spec disallineata significa promettere funzioni che non ci sono** — è la trappola del sito |
| W3 | **WD19** | ⛔ **Pier sceglie con cosa si costruisce il sito** — Jekyll, HTML a mano, altro generatore statico | P | ⭐ **Il criterio non è tecnico: è quanto costa a Pier cambiare un testo da solo.** Le tre strade coi costi stanno nel verbale del giro W0. ⛔ Prima di `WA4`, perché le pagine si scrivono **in** qualcosa |
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
| **`WA1` e `WA2` hanno bisogno di un sito che esista** | W4 prima di W5 |

## Cosa questo piano NON copre, e dichiarato

- ⛔ **Le gemelle restano aperte anche nel registro dell'app:** chiudere `WA1` qui non chiude `RA1` là. Il piano dell'app ha la sua Fase E, e i due si tengono al passo via `bacheca.md`.
- ⛔ **I social non sono in questo piano.** Decisione di Pier: il sito viene prima, i social si fanno sull'app finita.
- ⚠️ **`WD18`, `WD20` e `WD21` non hanno un posto in coda**, e non è una dimenticanza: sono debiti di documento che si chiudono quando si tocca il documento, non voci che bloccano qualcos'altro.
