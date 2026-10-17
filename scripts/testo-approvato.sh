#!/bin/bash
#
# Il testo del sito è ancora quello che Pier ha approvato?
#
# ⛔ COSA QUESTO CONTROLLO NON FA, e va detto prima: non dice se una frase è
# chiara, se il tono è sportivo invece che militare, se una promessa è vera.
# Quella resta «l'unica zona senza controprova meccanica» (CLAUDE.md, «Chi
# decide cosa»), e resta di Cowork e di Pier.
#
# ⭐ COSA FA, e dal giro W9 sono DUE MISURE DIVERSE, non una fatta due volte:
#
#   ① IL SORGENTE — ogni stringa dei file di testo (`_data/landing.yml`,
#      `privacy.yml`, `support.yml`, `terms.yml`) deve stare ALLA LETTERA nella
#      sua bozza approvata, fuori dal repo. Se una non c'è, qualcuno ha
#      riscritto un testo dell'utente dentro il repo, e ⛔ quello è un lavoro di
#      Cowork, non di Claude Code.
#
#   ② IL SERVITO — ogni parola che esce nel sito COSTRUITO deve venire da una
#      bozza. ⛔ NON È LO STESSO CONTROLLO: la misura ① guarda i file di dati, e
#      un layout può scrivere di suo una frase che in nessun file di dati
#      compare. Il giro W9 chiede «ogni stringa SERVITA», e questa è quella.
#      ⭐ DAL GIRO W10 ENTRA ANCHE NEI DATI STRUTTURATI (JSON-LD). ⛔ Era il
#      buco rimasto: il testo servito si legge fra un tag e l altro, e il
#      JSON-LD sta DENTRO un `<script>`, che questa misura buttava via insieme
#      agli script veri. Cioè l unico posto del sito dove si poteva scrivere
#      una frase nuova senza che nessuno se ne accorgesse era proprio quello
#      che i motori di ricerca leggono per primo.
#      ⚠️ Serve un sito costruito: si chiama `--servito <cartella>`, e senza
#      quella cartella la misura non c'è — ⭐ terzo esito, non soglia più larga.
#
# ⚠️ FUNZIONA NEI DUE VERSI, ed è il motivo per cui vale la pena: scatta anche
# quando è la BOZZA a cambiare. Allora non c'è nessun errore da riparare —
# c'è una consegna nuova di Cowork da portare nei file di dati.
# ⭐ È SUCCESSO NEL GIRO W6, esattamente così: la bozza ha cambiato «No servers
# of ours» in «No AIMONX servers» in due frasi, questo controllo ha protestato
# all'apertura del giro, e la cura è stata portare la bozza nuova nel repo.
#
# ⛔ LE ECCEZIONI SONO TRE, TUTTE DICHIARATE E TUTTE STAMPATE a ogni run. Una
# eccezione che non si vede è il buco da cui rientra il testo riscritto.
#   · ⭐ DAL GIRO W27 NON PIÙ i `.meta.title` di Privacy, Support e Terms:
#     stanno nella bozza dei titoli (`titoli/titoli-en-bozza.md`).
#     ⭐ DAL GIRO W12 NON CI SONO PIÙ `.meta.title` e `.meta.description`
#     DELLA LANDING: stanno alla lettera nella bozza, e un'eccezione che non
#     serve è un controllo spento per niente (`WD38`);
#   · `.data_pubblicazione` di Privacy e Terms, che sostituisce il segnaposto
#     «[date of publication]» della bozza — ⛔ l'unica differenza ammessa dal
#     testo approvato (giro W9 §1);
#   · nel SERVITO, il «·» fra i tre link del piede, che è un segno e non una
#     parola (`_includes/piede.html`). ⚠️ Sta comunque nella bozza della
#     landing, quindi non ha bisogno di essere perdonato: lo trova da sé.
#
# ⚠️ IL PIEDE È LO STESSO SU TUTTE LE PAGINE, e il suo testo è
# approvato nella bozza della LANDING. Quindi nel controllo ② ogni pagina è
# confrontata con la propria bozza PIÙ quella della landing. Non è una maglia
# larga: è dove Cowork ha scritto quelle parole.
#
# Uso:  scripts/testo-approvato.sh                  → misura ①
#       scripts/testo-approvato.sh --servito DIR    → misura ②
#       usate tutte e due da scripts/controprova.sh
set -u
REPO="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$REPO" || exit 1

MODO="sorgente"
COSTRUITO=""
if [ "${1:-}" = "--servito" ]; then
  MODO="servito"
  COSTRUITO="${2:-}"
fi

PIER_DIR=""
# shellcheck source=/dev/null
[ -r "$REPO/scripts/percorsi-locali.sh" ] && . "$REPO/scripts/percorsi-locali.sh"
CONTENUTI="$PIER_DIR/8- AIMONX web/2- Contenuti"
RUBY="$HOME/.rbenv/versions/3.3.4/bin/ruby"

# ⛔ Terzo esito, non una soglia più larga: se manca un pezzo lo si dice.
if [ ! -x "$RUBY" ]; then
  echo "  ⛔ NON MISURABILE: la toolchain Ruby locale manca (CLAUDE.md, «Comandi»)."; exit 0
fi
# ⛔ SI PROVA A LEGGERE DAVVERO, non a chiedere se la cartella esiste (giro
# W12). ⚠️ Nel W11 il terminale non aveva il permesso di macOS sulla cartella
# Documenti: una cartella così può ancora «esistere» per `-d` e non lasciarsi
# leggere, e la misura finiva senza un numero — che chi legge in fretta prende
# per uno zero. ⭐ Qui si apre ogni bozza, un byte, e se una sola non si apre
# l'esito è il terzo. ⛔ Esce con 4, non con 0: «non ho potuto guardare» non è
# «ho guardato e va bene», e `scripts/controprova.sh` lo conta a parte.
ILLEGGIBILI=0
if [ -z "$PIER_DIR" ]; then
  ILLEGGIBILI=1
else
  for BOZZA in landing/landing-en-bozza.md privacy-policy/privacy-policy-en-bozza.md \
               support/support-en-bozza.md terms/terms-en-bozza.md \
               round-count/round-count-en-bozza.md your-data/your-data-en-bozza.md \
               navigazione/navigazione-en-bozza.md; do
    head -c 1 "$CONTENUTI/$BOZZA" >/dev/null 2>&1 || ILLEGGIBILI=$((ILLEGGIBILI + 1))
  done
fi
if [ "$ILLEGGIBILI" != 0 ]; then
  echo "  ⛔ NON MISURABILE: le bozze approvate non sono leggibili da questo Mac."
  echo "     ⛔ Il percorso non si stampa (WD17): lo definisce scripts/percorsi-locali.sh."
  echo "     ⚠️ Se il file c'è, è il permesso di macOS sulla cartella Documenti per"
  echo "        questo terminale (Impostazioni › Privacy e sicurezza › File e cartelle)."
  exit 4
fi
if [ "$MODO" = "servito" ] && { [ -z "$COSTRUITO" ] || [ ! -d "$COSTRUITO" ]; }; then
  echo "  ⛔ NON MISURABILE: nessun sito costruito da guardare."
  echo "     Il controllo del testo SERVITO ha bisogno di una build (WD25)."
  exit 0
fi

# ⛔ IL PROGRAMMA ARRIVA DA UN HEREDOC CITATO, non da una stringa fra apici.
# ⚠️ Fino al giro W8 stava fra apici singoli, e portava un avvertimento: «qui
# dentro NON si usano apostrofi, uno chiuderebbe la stringa a metà». Un
# programma che ha una trappola da ricordarsi è un programma che un giorno
# qualcuno fa saltare. Con <<'PROGRAMMA' nessun carattere è speciale.
"$RUBY" -ryaml -rjson - "$MODO" "$CONTENUTI" "$REPO" "$COSTRUITO" <<'PROGRAMMA'
modo, contenuti, repo, costruito = ARGV

# Le sezioni della bozza della navigazione che vanno in pagina (giro W24).
SEZIONI_NAVIGAZIONE = ["Menu in alto", "Briciole di pane (pagine di sezione)",
  "Etichette per i lettori di schermo (invisibili a schermo)",
  "Colonna laterale (computer) / in fondo (telefono)", "La pagina indice `/features/`",
  "Piede, i titoli delle colonne"]

# Le pagine del sito: nome, file di dati, bozza, e dove esce nel
# sito costruito. ⛔ Una lista sola per tutte e due le misure: se qui manca
# una pagina, manca in entrambe, e non in una sola di nascosto.
PAGINE = [
  { nome: "landing", dati: "_data/landing.yml", bozza: "landing/landing-en-bozza.md",
    uscita: "index.html" },
  # ⭐ Giro W27: il titolo di scheda di queste tre sta nella bozza dei titoli,
  # tabella «Titoli» (`anche`), e non è più un'eccezione.
  { nome: "privacy", dati: "_data/privacy.yml", bozza: "privacy-policy/privacy-policy-en-bozza.md",
    uscita: "privacy-policy/index.html", anche: [["titoli/titoli-en-bozza.md", ["Titoli"]]] },
  { nome: "support", dati: "_data/support.yml", bozza: "support/support-en-bozza.md",
    uscita: "support/index.html", anche: [["titoli/titoli-en-bozza.md", ["Titoli"]]] },
  { nome: "terms",   dati: "_data/terms.yml",   bozza: "terms/terms-en-bozza.md",
    uscita: "terms/index.html", anche: [["titoli/titoli-en-bozza.md", ["Titoli"]]] },
  # ⭐ Giro W15, la prima pagina-funzione. ⛔ `sezioni`: della sua bozza valgono
  # SOLO «Meta» e «Page». Il resto di quel file — il link per la landing, la
  # tabella «Controllo», le note — non va in pagina, e se il controllo lo
  # accettasse, una riga della tabella copiata nel sito passerebbe per
  # approvata. ⚠️ Le pagine-funzione che verranno si aggiungono qui, uguali.
  { nome: "round-count", dati: "_data/round-count.yml", bozza: "round-count/round-count-en-bozza.md",
    uscita: "features/round-count/index.html", sezioni: ["Meta", "Page"] },
  # ⭐ Giro W16, la seconda: stesse regole. ⚠️ Nella sua bozza i «Punti
  # aperti» e la tabella «Controllo» stanno in sezioni `## ` proprie, e
  # `sezioni` li lascia fuori; la nota «[⏳ da approvare…]» sotto gli alt è
  # una riga fra quadre da sola, e cade come le «[schermata: …]».
  { nome: "your-data", dati: "_data/your-data.yml", bozza: "your-data/your-data-en-bozza.md",
    uscita: "features/privacy-and-security/index.html", sezioni: ["Meta", "Page"] },
  # ⭐ Giro W17: la terza pagina-funzione e la pagina delle novità, con le
  # stesse regole. ⚠️ In «What's new» le righe «Chi la tiene aggiornata» e la
  # tabella «Controllo» stanno in sezioni `## ` proprie, e `sezioni` le lascia
  # fuori come i «Punti aperti».
  { nome: "maintenance", dati: "_data/maintenance.yml", bozza: "maintenance/maintenance-en-bozza.md",
    uscita: "features/maintenance/index.html", sezioni: ["Meta", "Page"] },
  # ⭐ Giro W23: la quarta pagina-funzione, con le stesse regole. ⚠️ Nella
  # bozza ci sono anche la voce per la landing e la sezione per le FAQ, in
  # sezioni `## ` proprie: `sezioni` le lascia fuori, e le loro parole si
  # cercano nelle bozze della landing e delle FAQ, che restano l'originale.
  { nome: "custom-lists", dati: "_data/custom-lists.yml", bozza: "custom-lists/custom-lists-en-bozza.md",
    uscita: "features/custom-lists/index.html", sezioni: ["Meta", "Page"] },
  { nome: "whats-new", dati: "_data/whats-new.yml", bozza: "whats-new/whats-new-en-bozza.md",
    uscita: "updates/index.html", sezioni: ["Meta", "Page"] },
  # ⭐ Giro W18, le FAQ. ⚠️ `alt_da`: la sua schermata è quella di «Your data»,
  # col testo alternativo GIÀ APPROVATO là — nella bozza delle FAQ c'è solo la
  # nota che lo rimanda. ⛔ Il prestito vale SOLO per i testi alternativi, e
  # solo come RIGA INTERA della sezione «Page» di quella bozza: una frase di
  # «Your data» copiata in un paragrafo delle FAQ resta fuori bozza.
  { nome: "faq", dati: "_data/faq.yml", bozza: "faq/faq-en-bozza.md",
    uscita: "faq/index.html", sezioni: ["Meta", "Page"],
    alt_da: "your-data/your-data-en-bozza.md" },
  # ⭐ Giro W25, LA PAGINA «FREE AND PRO» (`/pricing/`), con le regole delle
  # pagine-funzione: della bozza valgono «Meta» e «Page», e il link per la
  # landing, la rilettura e la tabella «Controllo» restano fuori. ⚠️ Le righe
  # della tabella nella bozza sono righe con le sbarre (`| Firearms | 1 active
  # | Unlimited |`): ogni cella si trova lo stesso, alla lettera.
  { nome: "pricing", dati: "_data/pricing.yml", bozza: "pricing/pricing-en-bozza.md",
    uscita: "pricing/index.html", sezioni: ["Meta", "Page"] },
  # ⭐ Giro W24, LA NAVIGAZIONE E L'INDICE `/features/`. ⚠️ Della bozza valgono
  # le sezioni che vanno in pagina — menu, briciole, «More features», l'indice
  # e i titoli del piede — e NON la rilettura da madrelingua né la tabella
  # «Controllo». ⚠️ `anche`: le etichette dei link del piede esistevano già, e
  # stanno nella bozza della landing. ⚠️ `alt_da`: l'indice mostra la prima
  # schermata di «Your data», col testo alternativo approvato là.
  { nome: "navigazione", dati: "_data/navigazione.yml", bozza: "navigazione/navigazione-en-bozza.md",
    uscita: "features/index.html", sezioni: SEZIONI_NAVIGAZIONE,
    anche: [["landing/landing-en-bozza.md", nil]],
    alt_da: "your-data/your-data-en-bozza.md" },
  # ⭐ Giro W27, LA PAGINA 404: il testo è nella bozza dei titoli, nella sua
  # sezione (i sottotitoli «Meta» e «Page» cadono come tutti i `###`); le
  # etichette dei cinque link sono quelle già approvate della navigazione.
  { nome: "404", dati: "_data/non-trovato.yml", bozza: "titoli/titoli-en-bozza.md",
    uscita: "404.html", sezioni: ["La pagina «non trovato» (404)"],
    anche: [["navigazione/navigazione-en-bozza.md", SEZIONI_NAVIGAZIONE]] },
  # ⭐ Giro W24, LA FONTE UNICA DELLE FUNZIONI. Non è una pagina — `uscita` non
  # c'è, e la misura ② la salta: il suo testo esce nella landing e nell'indice,
  # e lì lo guardano le loro voci. ⚠️ Le righe sono quelle delle carte (bozza
  # della landing), il nome breve è della bozza della navigazione, e il testo
  # alternativo di «Your data» della sua bozza.
  { nome: "funzioni", dati: "_data/funzioni.yml", bozza: "landing/landing-en-bozza.md",
    anche: [["navigazione/navigazione-en-bozza.md", SEZIONI_NAVIGAZIONE]],
    alt_da: "your-data/your-data-en-bozza.md" },
]

# Le eccezioni dichiarate, per pagina e per percorso dentro il file di dati.
# ⭐ Dal giro W27 non c'è più `TITOLO_PIER`: i titoli di Privacy, Support e
# Terms stanno nella bozza dei titoli, e si cercano lì come tutto il resto.
# ⭐ La landing non ne ha più, dal giro W12: il suo titolo di scheda e la sua
# descrizione stanno ALLA LETTERA nella bozza (la riga del piede e il paragrafo
# della parte alta), quindi si cercano come tutto il resto. ⛔ Era `WD38`: da
# eccezioni, una descrizione rimasta vecchia non la guardava nessuno.
DICHIARATE = {
  "landing" => {},
  "privacy" => { ".data_pubblicazione" => "sostituisce «[date of publication]» della bozza" },
  "support" => {},
  "terms"   => { ".data_pubblicazione" => "sostituisce «[date of publication]» della bozza" },
}

# I titoli di sezione: nella bozza della landing sono etichette in maiuscolo.
TITOLI = [".what.title", ".privacy.title", ".security.title", ".piani.title"]

# ⛔ STRUTTURA, NON PAROLE. `tipo: h2` dice al layout COME impaginare un
# blocco: non compare in pagina e non ha nessun motivo di stare in una bozza.
# ⚠️ Questa lista e volutamente CORTA e fatta di nomi di chiave, non di valori:
# perdonare un valore («h2 va bene») vorrebbe dire perdonarlo ovunque, anche
# dentro una frase. Cosi invece si perdona una casella precisa.
# ⭐ Dal giro W24 anche `aspetto`, ed è un SOTTOALBERO intero: nella fonte
# unica delle funzioni (`_data/funzioni.yml`) indirizzo, glifo, tinta e
# schermata stanno sotto quella chiave, che è di CC e non porta parole. ⚠️ Si
# guarda ogni pezzo del percorso, non solo l ultimo, apposta per questo.
STRUTTURA = ["tipo", "aspetto"]

# La bozza è markdown. Si toglie quel che per regola NON va in pagina: le note
# fra quadre in corsivo (sono per Cowork) e i marcatori di grassetto e corsivo,
# che sono formattazione e non parole. ⭐ Dal giro W9 si scioglie anche il link
# markdown [etichetta](indirizzo): in pagina si legge solo l etichetta, e
# l indirizzo sta in _data/collegamenti.yml.
# ⭐ Dal giro W15 `sezioni` restringe la bozza ai soli titoli `## ` nominati, e
# toglie le righe che sono una NOTA FRA QUADRE da sole («[schermata: …]»): sono
# istruzioni per chi costruisce, non testo.
def piano(percorso, sezioni = nil)
  t = File.read(percorso, encoding: "UTF-8")
  if sezioni
    pezzi = t.split(/^## /).drop(1).select { |s| sezioni.include?(s.lines.first.to_s.strip) }
    t = pezzi.map { |s| s.lines.drop(1).reject { |r| r.strip.start_with?("[") && r.strip.end_with?("]") }.join }.join("\n")
    t = t.gsub(/^\#{2,}\s*/, "")
  end
  t = t.gsub(/\*\[[^\]]*\]\*/m, "")
  t = t.gsub(/\[([^\]]+)\]\(\S+\)/) { $1 }
  t = t.gsub("**", "").gsub("*", "")
  # ⭐ Giro W27: dentro una tabella markdown la sbarra si scrive `\|`, e in
  # pagina si legge `|` (i titoli «… | AIMONX» della bozza dei titoli).
  t = t.gsub("\\|", "|")
  t.gsub(/[ \t]+/, " ")
end

def stringhe(n, via = "", &b)
  case n
  when String then b.call(via, n)
  when Hash   then n.each { |k, v| stringhe(v, "#{via}.#{k}", &b) }
  when Array  then n.each_with_index { |v, i| stringhe(v, "#{via}[#{i}]", &b) }
  end
end

PAGINE.each do |p|
  p[:testo_bozza] = piano(File.join(contenuti, p[:bozza]), p[:sezioni])
  # ⭐ Giro W24: le bozze in più da cui una voce prende testo (`anche`).
  (p[:anche] || []).each { |b, s| p[:testo_bozza] += "\n" + piano(File.join(contenuti, b), s) }
  # Le righe intere della bozza da cui una pagina prende in prestito i testi
  # alternativi (giro W18, `alt_da`). Vuoto per tutte le altre.
  p[:alt_prestati] = p[:alt_da] ? piano(File.join(contenuti, p[:alt_da]), ["Page"]).split("\n").map(&:strip) : []
end
BOZZA_LANDING = PAGINE.first[:testo_bozza]
# ⭐ Giro W24: la barra, le briciole e il piede sono su OGNI pagina, e le loro
# parole stanno nella bozza della navigazione — come il piede di prima stava
# in quella della landing. Quindi ogni pagina si confronta anche con lei.
BOZZA_NAVIGAZIONE = piano(File.join(contenuti, "navigazione/navigazione-en-bozza.md"), SEZIONI_NAVIGAZIONE)

fuori = 0

if modo == "sorgente"
  PAGINE.each do |p|
    percorso = File.join(repo, p[:dati])
    unless File.readable?(percorso)
      puts "  #{p[:nome]}: ⛔ NON MISURABILE — #{p[:dati]} non c e"
      next
    end
    ok = 0; dich = 0; mancanti = []
    eccezioni = DICHIARATE[p[:nome]] || {}
    stringhe(YAML.load_file(percorso)) do |via, s|
      t = s.gsub(/[ \t]+/, " ").strip
      next if (via.split(".").map { |x| x.sub(/\[\d+\]\z/, "") } & STRUTTURA).any?
      if eccezioni.key?(via)
        dich += 1
        puts "     ⚠️ #{p[:nome]}#{via}: «#{t}» — #{eccezioni[via]}"
        next
      end
      if p[:testo_bozza].include?(t)
        ok += 1
      # ⚠️ `alt` con o senza indice: nelle pagine è una lista (`alt[0]`), nella
      # fonte unica delle funzioni una riga per voce (`[9].alt`, giro W24).
      elsif via =~ /\.alt(\[\d+\])?\z/ && p[:alt_prestati].include?(t)
        dich += 1
        puts "     ⚠️ #{p[:nome]}#{via}: testo alternativo preso ALLA LETTERA da #{p[:alt_da]}"
      elsif TITOLI.include?(via) && p[:testo_bozza].include?(t.upcase)
        ok += 1
        puts "     ⚠️ #{p[:nome]}#{via}: nella bozza e etichetta in maiuscolo, in pagina e un titolo"
      else
        mancanti << [via, t]
      end
    end
    fuori += mancanti.size
    puts "  #{p[:nome]}: #{ok} stringhe trovate ALLA LETTERA nella bozza, #{dich} dichiarate, #{mancanti.size} fuori"
    mancanti.each { |via, t| puts "     ⛔ #{p[:nome]}#{via}: NON sta nella bozza -> «#{t[0, 120]}»" }
  end

  # Il testo e l aspetto si accoppiano PER POSIZIONE. Se Cowork aggiunge o
  # toglie una voce e nessuno tocca _data/aspetto.yml, le tinte e i glifi
  # scivolano di una riga, e a occhio non si vede: la pagina resta intera.
  # ⛔ Dal giro W6 le liste accoppiate sono TRE, non una: alle sette carte si
  # sono aggiunte le quattro voci e le tre garanzie della parte alta.
  aspetto = File.join(repo, "_data/aspetto.yml")
  if File.readable?(aspetto)
    t = YAML.load_file(File.join(repo, "_data/landing.yml")); a = YAML.load_file(aspetto)
    eroe = t["hero"] || {}
    # ⭐ Giro W15: le schermate delle pagine-funzione si accoppiano ai loro
    # file per ORDINE DI COMPARSA. Per ogni pagina che ne ha, i testi
    # alternativi nel file di Cowork e i nomi in `funzioni` devono essere
    # tanti uguali — se no l ultima schermata non esce, o esce quella sbagliata.
    coppie = []
    (a["funzioni"] || {}).each do |pagina, nomi|
      f = File.join(repo, "_data/#{pagina}.yml")
      n_alt = File.readable?(f) ? (YAML.load_file(f)["blocchi"] || []).sum { |b| b["tipo"] == "schermate" ? (b["alt"] || []).size : 0 } : 0
      coppie << ["schermate di #{pagina}", n_alt, (nomi || []).size]
    end
    # ⭐ Dal giro W24 le CARTE non si accoppiano più: testo e aspetto di ogni
    # funzione stanno nella stessa voce di `_data/funzioni.yml`.
    ([
      ["punti",    (eroe["punti"] || []).size,      (a["hero_punti"] || []).size],
      ["garanzie", (eroe["garanzie"] || []).size,   (a["hero_garanzie"] || []).size],
    ] + coppie).each do |nome, n_testo, n_asp|
      d = (n_testo - n_asp).abs
      fuori += d
      puts "  #{nome}: voci di testo #{n_testo} - righe di aspetto #{n_asp}" + (d.zero? ? "" : "  NON COINCIDONO")
    end
  end
else
  # ② IL SERVITO. Si prende il testo che esce dai tag e si cerca nella bozza.
  # ⛔ Niente parser HTML: nessuna libreria esterna entra in questo repo. Si
  # tolgono i commenti, gli script e gli stili, poi si guarda quel che resta
  # fra un tag e l altro. ⚠️ Gli ATTRIBUTI non si guardano qui: la description
  # e i meta di condivisione vengono dai file di dati, che la misura ① ha gia
  # confrontato con la bozza.
  # ⚠️ I frammenti brevissimi (punteggiatura rimasta sola quando una frase e
  # spezzata da un link) si trovano da se in qualunque bozza: non provano
  # niente, ma non mentono neanche, e contarli separati e piu onesto che
  # buttarli via in silenzio.
  PAGINE.each do |p|
    next unless p[:uscita]
    percorso = File.join(costruito, p[:uscita])
    unless File.readable?(percorso)
      puts "  #{p[:nome]}: ⛔ NON MISURABILE — la pagina non e nel sito costruito"
      next
    end
    html = File.read(percorso, encoding: "UTF-8")
    html = html.gsub(/<!--.*?-->/m, " ")

    # ⛔ IL JSON-LD SI RACCOGLIE PRIMA CHE GLI SCRIPT VENGANO BUTTATI VIA.
    # ⚠️ Non tutte le chiavi portano parole: `@type`, `@id`, `url`, `image`,
    # `@context` e `inLanguage` sono indirizzi e nomi tecnici, non testo che
    # qualcuno legge. ⛔ La lista è CORTA e fatta di NOMI DI CHIAVE apposta:
    # perdonare un VALORE («AIMONX va bene ovunque») lo perdonerebbe anche in
    # mezzo a una frase inventata.
    # ⭐ Dal giro W13 anche `installUrl` (un indirizzo, come `url`) e
    # `applicationCategory` (una parola della lista di Google, non una frase).
    # ⛔ Che quelle due caselle contengano DAVVERO un indirizzo nudo e una
    # categoria, e non una frase infilata lì, lo misura `misure-pagine.rb`.
    # ⭐ Dal giro W14 anche `screenshot`: sono gli indirizzi delle schermate,
    # come `image`. ⛔ Che siano DAVVERO indirizzi di file nostri, e non una
    # frase infilata lì, lo misura `misure-pagine.rb` (`immagini_guasti`).
    # ⭐ Dal giro W17 anche `priceCurrency`: un codice di tre lettere («USD»),
    # non una frase. ⛔ Che l offerta sia UNA, a zero, con quel codice e
    # nient altro, lo misura `misure-pagine.rb` (`offerte_a_zero`).
    # ⭐ Dal giro W24 anche `item`: nel `BreadcrumbList` è l indirizzo di ogni
    # briciola, come `url`. I NOMI delle briciole restano controllati.
    tecniche = ["@context", "@type", "@id", "url", "image", "inLanguage", "installUrl", "applicationCategory", "screenshot", "priceCurrency", "item"]
    parole_jsonld = []
    html.scan(/<script[^>]*type=["\x27]application\/ld\+json["\x27][^>]*>(.*?)<\/script>/mi) do |(blocco)|
      begin
        dato = JSON.parse(blocco)
      rescue JSON::ParserError => e
        parole_jsonld << [:rotto, e.message[0, 90]]
        next
      end
      raccogli = lambda do |n, chiave|
        case n
        when String then parole_jsonld << [:parola, n] unless tecniche.include?(chiave)
        when Hash   then n.each { |k, v| raccogli.call(v, k) }
        when Array  then n.each { |v| raccogli.call(v, chiave) }
        end
      end
      raccogli.call(dato, nil)
    end

    html = html.gsub(/<(script|style)\b.*?<\/\1>/mi, " ")
    # ⛔ I TESTI ALTERNATIVI SI RACCOLGONO PRIMA CHE I TAG VENGANO BUTTATI VIA
    # (giro W14). ⚠️ Fino al W13 questa misura non guardava nessun attributo, e
    # la nota in testa al blocco lo dichiarava: bastava, perché l unico `alt`
    # con parole era quello del badge e veniva dai file di dati. ⭐ Ora le
    # immagini con un testo alternativo sono nove, e un `alt` è una frase che
    # qualcuno SENTE: scritta a mano in un layout non starebbe in nessun file
    # di dati, e la misura ① non la vedrebbe — la stessa ragione per cui
    # esiste questa. ⚠️ `alt=""` non si conta: dichiara un immagine decorativa
    # e non porta parole.
    alt_serviti = html.scan(/<img\b[^>]*?\balt="([^"]*)"/mi).flatten.map { |x| x.gsub(/[[:space:]]+/, " ").strip }.reject(&:empty?)
    alt_serviti.map! { |x| x.gsub("&amp;", "&").gsub("&lt;", "<").gsub("&#39;", "'").gsub("&quot;", "\"") }
    # ⭐ Giro W24: anche le ETICHETTE `aria-label`, per la stessa ragione degli
    # `alt` — non si vedono, ma qualcuno le SENTE, e scritte a mano in un
    # layout sfuggirebbero alla misura ①. Si giudicano come loro: riga intera.
    etichette_servite = html.scan(/\baria-label="([^"]*)"/mi).flatten.map { |x| x.gsub(/[[:space:]]+/, " ").strip }.reject(&:empty?)
    # ⭐ Giro W26: `abbr` sulle testate della tabella di «Free and Pro» è il
    # nome breve che chi ascolta sente a ogni cella. Non è una riga a sé della
    # bozza — è una parola della riga — e si giudica come il testo in pagina.
    abbr_serviti = html.scan(/<th\b[^>]*?\babbr="([^"]*)"/mi).flatten.map { |x| x.gsub(/[[:space:]]+/, " ").strip }.reject(&:empty?)
    # ⛔ IL <title> SI STACCA PRIMA, e si giudica da solo (giro W12, `WD38`).
    # ⚠️ Fino al W11 un'eccezione dichiarata si perdonava per VALORE: qualunque
    # pezzo di pagina uguale al titolo di scheda passava, ovunque fosse. Ora
    # il titolo di scheda è perdonato in UN posto solo — il <title> — e lo
    # stesso testo scritto in un paragrafo deve stare nella bozza come gli altri.
    titolo_scheda = nil
    html = html.sub(/<title\b[^>]*>(.*?)<\/title>/mi) { titolo_scheda = $1.gsub(/[[:space:]]+/, " ").strip; " " }
    pezzi = html.split(/<[^>]*>/).map { |x| x.gsub(/[[:space:]]+/, " ").strip }
    pezzi.reject!(&:empty?)
    pezzi.concat(abbr_serviti)
    # I due caratteri rimessi come li ha scritti Cowork: in pagina sono
    # entita HTML (vedi _includes/frase.html), nella bozza sono se stessi.
    # ⭐ Dal giro W13 anche `&nbsp;`: è uno SPAZIO, che l impaginazione mette
    # davanti a una lineetta perché non apra una riga. Non è una parola, e
    # nella bozza al suo posto c è uno spazio normale.
    pezzi.map! { |x| x.gsub("&nbsp;", " ").gsub("&amp;", "&").gsub("&lt;", "<").gsub("&#39;", "'").gsub("&quot;", "\"") }

    consentito = p[:testo_bozza] + "\n" + BOZZA_LANDING + "\n" + BOZZA_NAVIGAZIONE
    # ⚠️ IL JSON-LD HA UN CONSENTITO PIÙ LARGO, ed è dichiarato invece che
    # nascosto: TUTTE E QUATTRO le bozze. ⛔ Non è una maglia larga per comodo:
    # quel blocco non descrive UNA pagina, descrive il sito e l app — e «iOS»,
    # per esempio, Pier lo ha approvato nella bozza di Support, non in quella
    # della landing. ⭐ Quel che il controllo deve impedire resta impedito: una
    # frase INVENTATA non sta in nessuna delle quattro.
    consentito_jsonld = PAGINE.map { |q| q[:testo_bozza] }.join("\n")
    # ⛔ LE ECCEZIONI SONO LE STESSE DELLE DUE MISURE, e si leggono dallo stesso
    # posto: quel che la ① dichiara, la ② lo riconosce. ⚠️ Se fossero due liste
    # diverse, un giorno una direbbe una cosa e l altra un altra, e non se ne
    # accorgerebbe nessuno. ⛔ Ma si riconoscono PER POSTO, non per valore: il
    # titolo di scheda nel <title>, la data dentro il suo pezzo (`WD38`).
    date = []
    titolo_dichiarato = nil
    dati = File.join(repo, p[:dati])
    if File.readable?(dati)
      d = YAML.load_file(dati)
      date << d["data_pubblicazione"] if d["data_pubblicazione"]
      if (DICHIARATE[p[:nome]] || {}).key?(".meta.title")
        titolo_dichiarato = d.dig("meta", "title")
      end
    end

    ok = 0; brevi = 0; dich = 0; estranei = []
    if titolo_scheda
      titolo_scheda = titolo_scheda.gsub("&amp;", "&").gsub("&lt;", "<").gsub("&#39;", "'").gsub("&quot;", "\"")
      if consentito.include?(titolo_scheda)
        ok += 1
      elsif titolo_dichiarato && titolo_scheda == titolo_dichiarato
        dich += 1
        puts "     ⚠️ #{p[:nome]}: <title> «#{titolo_scheda}» — #{DICHIARATE[p[:nome]][".meta.title"]}"
      else
        estranei << "<title> #{titolo_scheda}"
      end
    end
    pezzi.each do |x|
      # ⚠️ LA DATA SI TOGLIE DAL PEZZO, non si confronta col pezzo intero: in
      # pagina «Last updated:» e la data stanno nello stesso pezzo di testo, e
      # separarli con un tag apposta vorrebbe dire cambiare la pagina per
      # far contento il controllo. ⛔ Quel che resta DOPO averla tolta deve
      # stare nella bozza lo stesso — cosi la data e perdonata, il resto no.
      senza_data = x
      trovata = nil
      date.each do |g|
        if senza_data.include?(g)
          trovata = g
          senza_data = senza_data.sub(g, "").gsub(/[[:space:]]+/, " ").strip
        end
      end
      if x.length < 3
        brevi += 1
      elsif consentito.include?(x)
        ok += 1
      elsif trovata && (senza_data.empty? || consentito.include?(senza_data))
        dich += 1
        puts "     ⚠️ #{p[:nome]}: «#{x}» — la data di pubblicazione e dichiarata (giro W9 §1); il resto sta nella bozza"
      else
        estranei << x
      end
    end
    # ⛔ Un testo alternativo deve stare nella bozza INTERO, come riga a sé:
    # non basta che le sue parole compaiano da qualche parte.
    alt_ok = 0
    alt_serviti.each do |x|
      if consentito.split("\n").map(&:strip).include?(x)
        alt_ok += 1
      elsif p[:alt_prestati].include?(x)
        alt_ok += 1
        puts "     ⚠️ #{p[:nome]}: testo alternativo preso ALLA LETTERA da #{p[:alt_da]}"
      else
        estranei << "testo alternativo di un immagine: #{x}"
      end
    end
    righe_consentite = consentito.split("\n").map(&:strip)
    eti_ok = 0
    etichette_servite.each do |x|
      if righe_consentite.include?(x) then eti_ok += 1
      else estranei << "etichetta per i lettori di schermo: #{x}"
      end
    end
    jl_ok = 0; jl_fuori = []
    parole_jsonld.each do |tipo, x|
      if tipo == :rotto
        jl_fuori << "JSON-LD NON SI LEGGE: #{x}"
      # ⛔ Nessun perdono qui dentro, dal giro W12: ogni parola dei dati
      # strutturati sta in una bozza, e nessuna ha bisogno di un'eccezione.
      elsif consentito_jsonld.include?(x)
        jl_ok += 1
      else
        jl_fuori << "nei dati strutturati, NON approvato -> «#{x[0, 120]}»"
      end
    end

    fuori += estranei.size + jl_fuori.size
    puts "  #{p[:nome]}: #{ok} pezzi di testo servito trovati nella bozza, #{brevi} segni brevi, #{dich} dichiarati, #{estranei.size} estranei · testi alternativi: #{alt_ok} su #{alt_serviti.size} alla lettera · etichette: #{eti_ok} su #{etichette_servite.size} · JSON-LD: #{jl_ok} parole approvate, #{jl_fuori.size} fuori"
    estranei.each { |x| puts "     ⛔ #{p[:nome]}: SERVITO ma NON approvato -> «#{x[0, 120]}»" }
    jl_fuori.each { |x| puts "     ⛔ #{p[:nome]}: #{x}" }
  end
end

puts "  fuori_bozza=#{fuori}"
exit(fuori.zero? ? 0 : 1)
PROGRAMMA
