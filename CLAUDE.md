# CLAUDE.md

## Da dove comincio — l'indice

⛔ **Una domanda, un file. Se una cosa sta in due file, uno dei due è sbagliato.**

⚠️ **Il nome di questa cartella non è il nome del repo, e non è un errore.** Il repo su GitHub si chiama **`aimonx`** (`aimonxapp/aimonx`); la cartella locale si chiama `aimonx-web` perché ⛔ **su APFS non distingue maiuscole da minuscole `~/Developer/aimonx` È `~/Developer/AIMONX`**, cioè il repo dell'app. Misurato: `ls -d ~/Developer/aimonx` risponde col percorso di `~/Developer/AIMONX`, cioè apre il repo dell'app. **Il nome vero si legge da `git remote -v`, sempre.**

### I file vivi — si leggono per sapere dov'è il progetto

| Cerchi… | File |
|---|---|
| **il metodo — come si sta in chat con Pier, chi decide cosa, dove sta l'originale del metodo di costruzione** | `…/13 Armi e Tiro/10- AIMONX AI Common/metodo-aimonx.md` — **fuori dal repo**, comune ai due progetti. ⛔ **Non si ricopia qui: si cita** |
| **gli avvisi fra i progetti** — cosa ha cambiato l'altro, cosa aspetta da noi | `…/10- AIMONX AI Common/bacheca.md` — si legge **a ogni sessione** |
| **da dove comincio, cosa non si deroga, gli attrezzi di QUESTO repo** | **questo file** |
| **dove siamo adesso** | `…/13 Armi e Tiro/8- AIMONX web/1- Specifiche/memory.md` — cartella di Pier, **fuori dal repo** |
| **cosa manca e cosa blocca** | `docs/aperti.md` — ID a prefisso `W`; le voci nate dal registro dell'app citano la gemella (`WA1 ↔ RA1`) |
| **come si è chiusa una voce del registro** | ⏳ `docs/aperti-chiusi.md` — nasce alla prima chiusura, non prima; ⛔ non si legge all'avvio |
| **in che ordine, e cosa aspetta cosa** | `docs/piano-chiusura.md` |
| **cosa deve fare il sito — pagine, contenuti, tono** | `…/8- AIMONX web/1- Specifiche/spec-sito.md` — **fuori dal repo, di Cowork**: è testo che il pubblico legge. ⭐ **Sta bene lì, e questo repo non ne tiene copia:** una copia nel repo sarebbe leggibile da chiunque (vedi «Trappole»), e diverge dall'originale il giorno dopo. Se un giro avrà bisogno di un estratto, si cita il `§`, non si ricopia |
| **cosa fa l'app** — l'unica autorità su ciò che il sito può promettere | `~/Developer/AIMONX/docs/prodotto.md` (⛔ **sempre col percorso intero:** scritto nudo si leggerebbe come un file di QUESTO repo, e non c'è) — ⛔ **si legge, non si scrive.** Se non sta lì, sul sito non va |
| **cosa dice l'app, in italiano e nei due inglesi** | `~/Developer/AIMONX/catalogo-testi/catalogo-testi-aimonx.xlsx` — le parole del sito sono quelle dell'app |

### Gli attrezzi

| Cerchi… | Dove |
|---|---|
| **come si conduce un giro** | skill `/giro` → `.claude/skills/giro/SKILL.md` — ⭐ **è una COPIA di quella dell'app, non un collegamento**, perché il master comune ⏳ `…/10- AIMONX AI Common/skills/giro/` **non esiste**: misurato, `find "…/10- AIMONX AI Common"` elenca due file e nessuna cartella `skills`. ⚠️ **Una copia diverge in silenzio:** chi cambia questa skill o quella dell'app lascia una riga in `bacheca.md` |
| **la verifica di fine giro** | `scripts/controprova.sh` · valori attesi in `scripts/attese.txt` |
| **i percorsi di QUESTO Mac** — e perché non stanno in un file tracciato | `scripts/percorsi-locali.sh` e `.claude/settings.local.json`, tenuti fuori da `.gitignore` (WD17). ⚠️ **Non arrivano col clone:** su un Mac nuovo si riscrivono a mano |
| **cosa Pages pubblica e cosa no** | `_config.yml` — ⛔ **`exclude` è una lista di negazioni, e fallisce APERTA:** chi aggiunge un file alla radice lo pubblica. Chi se ne accorge è la controprova (`pagine_dal_merge`), non la memoria |
| **il push** | `scripts/push-remoto.sh`, chiamato dall'hook `Stop` — remote misurato: `https://github.com/aimonxapp/aimonx.git`. ⛔ **Nessun hook di pin:** il sito non ha una specifica canonica congelata. ⛔ **Spinge il SOLO ramo corrente e rifiuta `main`**, perché `main` è il sito pubblicato |

### Materiale di riferimento — nella cartella di Pier, fuori dal repo

| Cerchi… | Dove |
|---|---|
| **i contenuti scritti e approvati** | `…/8- AIMONX web/2- Contenuti/` |
| **le risorse grafiche del sito** | `…/8- AIMONX web/4- risorse/` — ⚠️ **esiste ed è VUOTA**: `spec-sito.md` §1 la dà per la destinazione degli asset, e l'unico materiale grafico del sito sta altrove (`WD21`). I colori e le misure decise per l'app: `…/7- App AIMONX/1- Specifiche/tavolozza-aimonx.md` |
| **il materiale marketing** (di luglio, da verificare contro `prodotto.md`) | `…/7- App AIMONX/1- Specifiche/marketing-aimonx.md` · `marketing-strategia-aimonx-budget-50.md` |
| **la misura dell'infrastruttura** — Pages, dominio, certificato, posta | `…/7- App AIMONX/3- note/_archivio/nota-infrastruttura-sito-mail-10-08.md` |
| **le lezioni dell'app** — si aprono quando si scrive un giro | `…/7- App AIMONX/1- Specifiche/lezioni-aimonx.md` |
| **i social** | `…/9- AIMONX social/` — ⏳ vuota |

### Archivi — si aprono solo per ricostruire come si è arrivati a una decisione

| Cerchi… | Dove |
|---|---|
| **prompt e risposte dei giri chiusi** | `…/8- AIMONX web/3- note/_archivio/` — c'è dal verbale del giro W0 |
| **la bozza di luglio della struttura del sito** (ChatGPT, non autorità) | `…/8- AIMONX web/1- Specifiche/da GPT/` |

⭐ **Prima si sposta, poi si corregge. Mai nello stesso giro.** **Spostare** è meccanico e si dimostra coi numeri. **Correggere** è giudizio, e il giudizio può perdere pezzi. ⛔ **Mescolarli è il modo in cui si perdono i pezzi**, perché un errore di giudizio si nasconde dentro quella che sembrava una copia, **e nessuna controprova lo vede.**

⭐ **La regola dei due file.** Ogni giro finisce con due **tipi** di scrittura:

1. **i file vivi che ha cambiato** — sovrascritti, sempre al presente. ⭐ **Possono essere più d'uno**, se il giro lo richiede e restano coerenti fra loro.
2. **un verbale in archivio** — la cronaca, che lì può crescere quanto vuole.

⛔ **Il verbale non entra mai in un file vivo.**
⛔ **Se un giro non ha cambiato nessun file vivo, non ha cambiato lo stato del progetto:** è solo storia.
⛔ **Un giro che produce solo documenti non ne apre un altro:** i suoi finding vanno in `docs/aperti.md` e **aspettano** — il registro esiste perché un finding possa aspettare. ⚠️ **Il segnale non è la fatica, è il rendimento per giro che crolla**, e i documenti sui documenti hanno profondità infinita.
⚠️ **Il verbale è la consegna di fine giro, e la archivia Cowork** in `…/8- AIMONX web/3- note/_archivio/`. **Nel repo non serve niente**, e a Claude Code la scrittura lì è negata dai permessi — la lettura no: si legge, non si tocca.

⚠️ **`memory.md` sta nella cartella di Pier, dove la scrittura ti è negata dai permessi.** Si legge, non si tocca. **Quando un file vivo di Cowork va aggiornato, il testo arriva come nota in `…/8- AIMONX web/3- note/` e lo integri tu.** ⛔ **Il recinto qui copre quattro cartelle, non una:** `7- App AIMONX`, `8- AIMONX web`, `9- AIMONX social`, `10- AIMONX AI Common`.

## Progetto

AIMONX sito — il sito pubblico `aimonx.app` dell'app iOS AIMONX, diario tecnico per tiratori sportivi. **Sito statico su GitHub Pages**, con dominio collegato e certificato valido.

- **Repo:** `aimonxapp/aimonx` — ⛔ **pubblico**, ramo di default `main`, due commit, un ramo, zero tag, due file (`CNAME`, `README.md`). Remote: `https://github.com/aimonxapp/aimonx.git`. ⭐ **Il proprietario è l'account `aimonxapp`, NON `Pier974`** che possiede il repo dell'app. *(`gh repo view aimonxapp/aimonx`, `gh api repos/aimonxapp/aimonx`.)*
- **Pages pubblica dal ramo `main`, cartella radice `/`**, con **Jekyll** (`"build_type": "legacy"`); dominio `aimonx.app`, certificato approvato. **`https_enforced` è `true`** e `http://aimonx.app` risponde `301` verso HTTPS. ⚠️ **Ma la pagina si dichiara ancora `http://` da sé** nel proprio `canonical`: quello lo scrive Jekyll, non GitHub, e il rimedio (`url:` in `_config.yml`) è sul ramo e non ancora online — WD23. *(`gh api repos/aimonxapp/aimonx/pages`, `curl -sSI http://aimonx.app/`.)*
- **Cosa pubblica oggi:** il README, reso con **Jekyll v3.10.0** — titolo *«aimonx-website»*, corpo *«AIMONX website»*. Nessuna landing, nessuna pagina di contenuto. *(`curl -sS https://aimonx.app/ | grep generator`.)*
- ⛔ **Con cosa si costruirà — Jekyll, HTML puro, altro — è una decisione di Pier:** CC propone con i costi, non decide. Vincoli da `spec-sito.md` §6: statico, JS minimo, nessun database, nessun CMS, nessun tracker.
- ⛔ **`main` è il sito pubblicato, ed è misurato, non più un'ipotesi:** un merge su `main` **è una pubblicazione al mondo**, perché Pages costruisce dalla radice di `main`. La regola di ramo qui pesa il doppio.

## Comandi

⛔ **Nessun comando di build o di anteprima è scritto qui, perché non ne esiste ancora uno:** il repo ha due file e nessuna toolchain. Un comando si scrive quando è stato lanciato. Quelli che oggi ci sono e sono stati lanciati:

```bash
scripts/controprova.sh                    # quadro di fine giro
scripts/controprova.sh --aggiorna-attese  # riscrive i valori attesi misurati ora

gh api repos/aimonxapp/aimonx/pages       # cosa pubblica Pages, e da dove
curl -sSI https://aimonx.app/             # cosa risponde il sito vero
```

## Regole operative

- I commenti nei file di lavoro sono parte del contratto con la specifica: citano il punto e spiegano vincoli non ovvi. Mantenerli aggiornati quando si cambia il comportamento.
- ⛔ **Il `§` indirizza SOLO `spec-sito.md`**, l'unico documento di questo progetto con sezioni numerate. La specifica dell'app si cita **per nome e sezione** (`prodotto.md §27.6`), e un punto di un documento di giro si cita **per nome**: `giro W0 §4`, `WA1`. *(Dall'app, `RD45`: le citazioni nude risolvevano su una sezione che non c'entra, e il guardrail non le vedeva.)*

## Vincoli non negoziabili

Non sono lo stato attuale del codice: sono impegni presi. Non si derogano senza una decisione esplicita di Pier.

- **Local-first.** Nessun server dello sviluppatore, nessun account obbligatorio, nessuna telemetria. I dati restano sul dispositivo dell'utente.
- **Nessuna libreria di terze parti che comunichi in rete.** Prima di aggiungere una dipendenza: fermarsi e chiedere.
- **Tono sportivo e neutro, mai militare o aggressivo.** Vale per i testi dell'app, i commenti, i messaggi di commit e la scheda App Store.

**In più, per il sito:**

- **Il sito non promette niente che non stia in `~/Developer/AIMONX/docs/prodotto.md`.** Una promessa sul sito è pubblica: un'app che vende privacy non può avere un sito che dice il falso.
- **Nessun tracker, nessun analytics, nessun form che raccolga dati** senza una decisione esplicita di Pier, scritta in `spec-sito.md`.
- **Lingua primaria: inglese US scritto nativo.** L'italiano è secondario. Le parole dell'app sono quelle del catalogo testi.

## Trappole — sembrano miglioramenti, sono danni pubblici

- ⛔ **Un merge su `main` pubblica, ed è misurato.** Pages costruisce con Jekyll dalla radice di `main`: al merge **`CLAUDE.md` diventa `aimonx.app/CLAUDE.html` e `docs/aperti.md` diventa `aimonx.app/docs/aperti.html`.** Non è «salvare»: è mettere online. Nessun merge senza l'autorizzazione di Pier — e qui chi sbaglia lo vede il mondo, non un test.
- ⛔ **Il repo è PUBBLICO, e questo vale prima del merge e indipendentemente da lui.** Un `git push` di un ramo qualsiasi rende i file di lavoro leggibili su `github.com/aimonxapp/aimonx` da chiunque, merge o no. ⚠️ **I file vivi citano le cartelle di Pier in forma abbreviata** (`…/8- AIMONX web/…`): il nome della cartella, non il percorso intero. ⛔ **Il percorso intero non entra in nessun file tracciato** (WD17, deciso da Pier il 21/09/2026): sta in `.claude/settings.local.json` e in `scripts/percorsi-locali.sh`, che `.gitignore` tiene fuori — **e la controprova lo controlla a ogni giro.** **Nessun dato personale nei messaggi di commit, nessun file di lavoro di Pier nel repo** (`spec-sito.md` §1).
- ⛔ **Due account sul Mac, e confonderli è il modo di fare un casino con l'app.** Questo repo è di `aimonxapp`, quello dell'app di `Pier974`. ⭐ **L'isolamento è un credential helper LOCALE a questo repo** (`git config --local credential.https://github.com.helper`), che prende il token con `gh auth token --user aimonxapp`. ⛔ **Non si usa `gh auth switch`:** l'account attivo di `gh` è `Pier974` e serve all'app — cambiarlo firmerebbe `aimonxapp` anche i push dell'app. ⚠️ **Misurato:** `gh auth git-credential` serve **solo** l'account attivo e rifiuta se il nome chiesto è un altro.
- ⛔ **Un testo «migliorato» che dice più di quello che l'app fa** è la trappola del sito: la funzione promessa e non presente. Si verifica contro `~/Developer/AIMONX/docs/prodotto.md`, non contro la memoria.

**Se una modifica tocca una di queste quattro zone: fermati e chiedi, anche se la controprova passa.**

## Chi decide cosa — il criterio è cosa ciascuno può vedere

- **Claude Code vede il repo, il codice, git e i numeri.** Decide e scrive **il come**: sintassi, comandi, struttura dei file, misure. ⭐ **Se un giro ti dice come si fa una cosa nel repo e il come è sbagliato, non obbedire: correggi e dillo.**
- **Cowork vede Pier, le decisioni e il mondo fuori dal repo.** Scrive **l'intento** di ogni giro e le condizioni di stop, i vincoli che nel codice non esistono, e il lavoro di pubblicazione (privacy policy, App Store, DSA).
- ⛔ **Cowork non ti dice più come si fa una cosa nel repo:** scrive cosa deve essere vero alla fine e come si prova. **Ogni sua ipotesi su qualcosa che sta nel codice arriva etichettata come ipotesi** — verificala e riferisci, non darla per buona.
- ⛔ **I testi che l'utente legge li scrive Cowork.** Non per gerarchia: **non esiste un test che dica se una frase è chiara, o se il tono è sportivo invece che militare.** È l'unica zona senza controprova meccanica. **Se un giro richiede un testo nuovo per l'utente, fermati e riferisci.** ⚠️ **Qui vale il doppio:** in questo repo *tutto* ciò che si costruisce è testo che l'utente legge.
- ⛔ **Pier non scrive codice, e nessun criterio di scelta può misurarsi su quanto gli costi modificarlo.** ⚠️ **È stato scritto davvero, in `WD19`:** *«quanto costa a Pier cambiare un testo da solo»* — un costo che non è suo, quindi un criterio che non misura niente. ⭐ **I costi si misurano sul lavoro dei giri e sul rischio:** quante sessioni serve, e cosa succede se va storta.
- ⭐ **`CLAUDE.md` e i file del repo sono tuoi, questo blocco compreso.** Cowork consegna il testo, tu lo integri dove ha senso. **Aggiungere un puntatore a un file che hai appena creato è tuo diritto, non un'intrusione.**
- **Cosa è aperto sta in `docs/aperti.md`**, nel repo. ⛔ **Le voci gemelle restano aperte anche nel registro dell'app:** chiuderne una qui non chiude quella là, e il contrario nemmeno. Chi ne chiude una lo dice in `bacheca.md`.

## Regole di ramo

- ⛔ **Non si committa su `main`.** Ogni giro ha il suo ramo.
- ⛔ **Il merge su `main` lo autorizza Pier**, mai il giro che ha scritto il codice. **E qui il merge è una pubblicazione:** vedi «Trappole».
- **Non si cancella nulla:** i rami dei tentativi falliti si taggano e restano.

## Regola delle versioni

Il sito non ha versioni: ha ciò che è online. ⛔ Nessuna numerazione si inventa. ⚠️ `spec-sito.md` §8 prevede una pagina `aggiornamenti/`: quella è una **cronologia leggibile dall'utente**, con le date dei cambiamenti pubblicati, e ⛔ **non è una numerazione del sito.** Se servirà un numero, lo si propone allora.

## Verifica di fine giro

- `scripts/controprova.sh`.
- ⛔ **I numeri attesi non sono scritti qui: li misura lo script.** Un numero copiato a mano invecchia senza dirlo. I valori attesi stanno in `scripts/attese.txt`, e si aggiornano solo con `--aggiorna-attese`. ⭐ **E vale oltre le attese: un numero misurabile oggi non si scrive senza il comando che lo produce; se cambia a ogni commit, si scrive solo il comando.** ⚠️ **Non vale per i numeri al passato dentro un verbale:** quelli sono citazioni, non misure, e si tengono.
- **Il guardrail dei file vivi** è dentro la stessa controprova: tetto di righe per ciascuno, **nessuna data nei titoli `## `**, e ogni percorso citato che risolve. ⛔ **Se scatta il controllo delle date, un verbale è entrato in un file vivo: si guarda cos'è entrato prima di alzare il numero.**
- ⛔ **Un controllo che protesta sempre viene disattivato — è così che muoiono i guardrail.** Quindi si controlla che una misura **porti la sua prova**, non che sia ancora quella di ieri. ⭐ **E quando una misura non si può fare, il terzo esito è «non misurabile», dichiarato — non una soglia più larga.**
- ⛔ **La misura che conta è il sito vero, non il repo.** `curl` su `https://aimonx.app` dice cosa legge il mondo; il repo dice solo cosa è stato scritto. ⚠️ **Fra i due c'è la build di Pages**, che nessuno script locale esegue.
- ⭐ **I tre tetti sono due domande diverse.** `docs/aperti.md` è **append-only** — la regola 2 del registro tiene in tabella anche le voci chiuse, quindi chiudere non libera una riga — e lì lo sfondamento non chiede *«stai ingrassando?»* ma *«cosa è entrato: una regola o un verbale?»*, e dopo aver guardato la risposta giusta è quasi sempre alzarlo. Per `CLAUDE.md` e `docs/piano-chiusura.md` no: **quei due devono restare stabili**, e lì il tetto è un freno.
