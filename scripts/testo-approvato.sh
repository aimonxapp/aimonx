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
#   · `.meta.title` e `.meta.description` della landing, assemblati da CC con
#     parole della bozza (dichiarato in `_data/landing.yml`);
#   · `.data_pubblicazione` di Privacy e Terms, che sostituisce il segnaposto
#     «[date of publication]» della bozza — ⛔ l'unica differenza ammessa dal
#     testo approvato (giro W9 §1);
#   · nel SERVITO, il «·» fra i tre link del piede, che è un segno e non una
#     parola (`_includes/piede.html`). ⚠️ Sta comunque nella bozza della
#     landing, quindi non ha bisogno di essere perdonato: lo trova da sé.
#
# ⚠️ IL PIEDE È LO STESSO SU TUTTE E QUATTRO LE PAGINE, e il suo testo è
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
if [ -z "$PIER_DIR" ] || [ ! -d "$CONTENUTI" ]; then
  echo "  ⛔ NON MISURABILE: le bozze approvate non sono leggibili da questo Mac."
  echo "     ⛔ Il percorso non si stampa (WD17): lo definisce scripts/percorsi-locali.sh."
  exit 0
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
"$RUBY" -ryaml - "$MODO" "$CONTENUTI" "$REPO" "$COSTRUITO" <<'PROGRAMMA'
modo, contenuti, repo, costruito = ARGV

# Le quattro pagine del sito: nome, file di dati, bozza, e dove esce nel
# sito costruito. ⛔ Una lista sola per tutte e due le misure: se qui manca
# una pagina, manca in entrambe, e non in una sola di nascosto.
PAGINE = [
  { nome: "landing", dati: "_data/landing.yml", bozza: "landing/landing-en-bozza.md",
    uscita: "index.html" },
  { nome: "privacy", dati: "_data/privacy.yml", bozza: "privacy-policy/privacy-policy-en-bozza.md",
    uscita: "privacy-policy/index.html" },
  { nome: "support", dati: "_data/support.yml", bozza: "support/support-en-bozza.md",
    uscita: "support/index.html" },
  { nome: "terms",   dati: "_data/terms.yml",   bozza: "terms/terms-en-bozza.md",
    uscita: "terms/index.html" },
]

# Le eccezioni dichiarate, per pagina e per percorso dentro il file di dati.
TITOLO_PIER = "titolo di scheda proposto da CC e APPROVATO da Pier il 22/09/2026"
DICHIARATE = {
  "landing" => {
    ".meta.title"       => "assemblato da CC con parole della bozza",
    ".meta.description" => "assemblato da CC con parole della bozza",
  },
  "privacy" => { ".meta.title" => TITOLO_PIER,
                 ".data_pubblicazione" => "sostituisce «[date of publication]» della bozza" },
  "support" => { ".meta.title" => TITOLO_PIER },
  "terms"   => { ".meta.title" => TITOLO_PIER,
                 ".data_pubblicazione" => "sostituisce «[date of publication]» della bozza" },
}

# I titoli di sezione: nella bozza della landing sono etichette in maiuscolo.
TITOLI = [".what.title", ".privacy.title", ".security.title", ".piani.title"]

# ⛔ STRUTTURA, NON PAROLE. `tipo: h2` dice al layout COME impaginare un
# blocco: non compare in pagina e non ha nessun motivo di stare in una bozza.
# ⚠️ Questa lista e volutamente CORTA e fatta di nomi di chiave, non di valori:
# perdonare un valore («h2 va bene») vorrebbe dire perdonarlo ovunque, anche
# dentro una frase. Cosi invece si perdona una casella precisa.
STRUTTURA = ["tipo"]

# La bozza è markdown. Si toglie quel che per regola NON va in pagina: le note
# fra quadre in corsivo (sono per Cowork) e i marcatori di grassetto e corsivo,
# che sono formattazione e non parole. ⭐ Dal giro W9 si scioglie anche il link
# markdown [etichetta](indirizzo): in pagina si legge solo l etichetta, e
# l indirizzo sta in _data/collegamenti.yml.
def piano(percorso)
  t = File.read(percorso, encoding: "UTF-8")
  t = t.gsub(/\*\[[^\]]*\]\*/m, "")
  t = t.gsub(/\[([^\]]+)\]\(\S+\)/) { $1 }
  t = t.gsub("**", "").gsub("*", "")
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
  p[:testo_bozza] = piano(File.join(contenuti, p[:bozza]))
end
BOZZA_LANDING = PAGINE.first[:testo_bozza]

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
      next if STRUTTURA.include?(via.split(".").last)
      if eccezioni.key?(via)
        dich += 1
        puts "     ⚠️ #{p[:nome]}#{via}: «#{t}» — #{eccezioni[via]}"
        next
      end
      if p[:testo_bozza].include?(t)
        ok += 1
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
    [
      ["carte",    (t["what"]["items"] || []).size, (a["what"] || []).size],
      ["punti",    (eroe["punti"] || []).size,      (a["hero_punti"] || []).size],
      ["garanzie", (eroe["garanzie"] || []).size,   (a["hero_garanzie"] || []).size],
    ].each do |nome, n_testo, n_asp|
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
    percorso = File.join(costruito, p[:uscita])
    unless File.readable?(percorso)
      puts "  #{p[:nome]}: ⛔ NON MISURABILE — la pagina non e nel sito costruito"
      next
    end
    html = File.read(percorso, encoding: "UTF-8")
    html = html.gsub(/<!--.*?-->/m, " ")
    html = html.gsub(/<(script|style)\b.*?<\/\1>/mi, " ")
    pezzi = html.split(/<[^>]*>/).map { |x| x.gsub(/[[:space:]]+/, " ").strip }
    pezzi.reject!(&:empty?)
    # I due caratteri rimessi come li ha scritti Cowork: in pagina sono
    # entita HTML (vedi _includes/frase.html), nella bozza sono se stessi.
    pezzi.map! { |x| x.gsub("&amp;", "&").gsub("&lt;", "<").gsub("&#39;", "'").gsub("&quot;", "\"") }

    consentito = p[:testo_bozza] + "\n" + BOZZA_LANDING
    # ⛔ LE ECCEZIONI SONO LE STESSE DELLE DUE MISURE, e si leggono dallo stesso
    # posto: quel che la ① dichiara, la ② lo riconosce. ⚠️ Se fossero due liste
    # diverse, un giorno una direbbe una cosa e l altra un altra, e non se ne
    # accorgerebbe nessuno — il `<title>` di queste pagine passa per tutte e
    # due, perché in pagina è anche un pezzo di testo.
    date = []
    perdonati = {}
    dati = File.join(repo, p[:dati])
    if File.readable?(dati)
      d = YAML.load_file(dati)
      date << d["data_pubblicazione"] if d["data_pubblicazione"]
      (DICHIARATE[p[:nome]] || {}).each do |via, motivo|
        valore = via.split(".").reject(&:empty?).inject(d) { |n, k| n.is_a?(Hash) ? n[k] : nil }
        perdonati[valore] = motivo if valore.is_a?(String)
      end
    end

    ok = 0; brevi = 0; dich = 0; estranei = []
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
      elsif perdonati.key?(x)
        dich += 1
        puts "     ⚠️ #{p[:nome]}: «#{x}» — #{perdonati[x]}"
      elsif trovata && (senza_data.empty? || consentito.include?(senza_data))
        dich += 1
        puts "     ⚠️ #{p[:nome]}: «#{x}» — la data di pubblicazione e dichiarata (giro W9 §1); il resto sta nella bozza"
      else
        estranei << x
      end
    end
    fuori += estranei.size
    puts "  #{p[:nome]}: #{ok} pezzi di testo servito trovati nella bozza, #{brevi} segni brevi, #{dich} dichiarati, #{estranei.size} estranei"
    estranei.each { |x| puts "     ⛔ #{p[:nome]}: SERVITO ma NON approvato -> «#{x[0, 120]}»" }
  end
end

puts "  fuori_bozza=#{fuori}"
exit(fuori.zero? ? 0 : 1)
PROGRAMMA
