#!/bin/bash
#
# Il testo della landing è ancora quello che Pier ha approvato?
#
# ⛔ COSA QUESTO CONTROLLO NON FA, e va detto prima: non dice se una frase è
# chiara, se il tono è sportivo invece che militare, se una promessa è vera.
# Quella resta «l'unica zona senza controprova meccanica» (CLAUDE.md, «Chi
# decide cosa»), e resta di Cowork e di Pier.
#
# ⭐ COSA FA: prende ogni stringa di `_data/landing.yml` — cioè ogni parola che
# il sito mostra — e la cerca ALLA LETTERA nella bozza approvata, che sta
# fuori dal repo, in `…/8- AIMONX web/2- Contenuti/landing/`. Se una non c'è,
# qualcuno ha riscritto un testo dell'utente dentro il repo, e ⛔ quello è un
# lavoro di Cowork, non di Claude Code.
#
# ⚠️ FUNZIONA NEI DUE VERSI, ed è il motivo per cui vale la pena: scatta anche
# quando è la BOZZA a cambiare. Allora non c'è nessun errore da riparare —
# c'è una consegna nuova di Cowork da portare in `_data/landing.yml`.
# ⭐ È SUCCESSO NEL GIRO W6, esattamente così: la bozza ha cambiato «No servers
# of ours» in «No AIMONX server» in due frasi, questo controllo ha protestato
# all'apertura del giro, e la cura è stata portare la bozza nuova nel repo.
#
# ⛔ Le uniche due stringhe che NON stanno nella bozza sono dichiarate nel file
# di dati e ripetute qui: `meta.title` e `meta.description`, assemblati da CC
# con parole della bozza. Se ne compare una terza, il controllo la nomina.
#
# Uso:  scripts/testo-approvato.sh        → stampa il quadro, esce 0/1
#       usato anche da scripts/controprova.sh
set -u
REPO="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$REPO" || exit 1

PIER_DIR=""
# shellcheck source=/dev/null
[ -r "$REPO/scripts/percorsi-locali.sh" ] && . "$REPO/scripts/percorsi-locali.sh"
BOZZA="$PIER_DIR/8- AIMONX web/2- Contenuti/landing/landing-en-bozza.md"
DATI="$REPO/_data/landing.yml"
ASPETTO="$REPO/_data/aspetto.yml"
RUBY="$HOME/.rbenv/versions/3.3.4/bin/ruby"

# ⛔ Terzo esito, non una soglia più larga: se manca un pezzo lo si dice.
if [ ! -x "$RUBY" ]; then
  echo "  ⛔ NON MISURABILE: la toolchain Ruby locale manca (CLAUDE.md, «Comandi»)."; exit 0
fi
if [ ! -r "$DATI" ]; then
  echo "  ⛔ NON MISURABILE: _data/landing.yml non c'è — nessuna landing da controllare."; exit 0
fi
if [ ! -r "$BOZZA" ]; then
  echo "  ⛔ NON MISURABILE: la bozza approvata non è leggibile da questo Mac."
  echo "     ⛔ Il percorso non si stampa (WD17): lo definisce scripts/percorsi-locali.sh."
  exit 0
fi

"$RUBY" -ryaml -e '
  bozza, dati, aspetto = ARGV
  # La bozza è markdown. Si toglie quel che per regola NON va in pagina:
  # le note fra quadre in corsivo (sono per Cowork), e i marcatori di
  # grassetto e corsivo, che sono formattazione e non parole.
  piano = File.read(bozza, encoding: "UTF-8")
  piano = piano.gsub(/\*\[[^\]]*\]\*/m, "").gsub("**", "").gsub("*", "")
  piano = piano.gsub(/[ \t]+/, " ")

  # Le due assemblate, dichiarate in _data/landing.yml.
  ASSEMBLATE = [".meta.title", ".meta.description"]
  # I titoli di sezione: nella bozza sono etichette in maiuscolo.
  TITOLI = [".what.title", ".privacy.title", ".security.title", ".piani.title"]

  def stringhe(n, via = "", &b)
    case n
    when String then b.call(via, n)
    when Hash   then n.each { |k, v| stringhe(v, "#{via}.#{k}", &b) }
    when Array  then n.each_with_index { |v, i| stringhe(v, "#{via}[#{i}]", &b) }
    end
  end

  ok = 0; assemblate = 0; mancanti = []
  stringhe(YAML.load_file(dati)) do |via, s|
    t = s.gsub(/[ \t]+/, " ").strip
    if ASSEMBLATE.include?(via)
      assemblate += 1
      puts "     ⚠️ #{via}: assemblato da CC con parole della bozza (dichiarato in _data/landing.yml)"
      next
    end
    if piano.include?(t)
      ok += 1
    elsif TITOLI.include?(via) && piano.include?(t.upcase)
      ok += 1
      puts "     ⚠️ #{via}: nella bozza è etichetta in maiuscolo («#{t.upcase}»), in pagina è un titolo"
    else
      mancanti << [via, t]
    end
  end

  puts "  stringhe mostrate dal sito e trovate ALLA LETTERA nella bozza: #{ok}"
  puts "  stringhe assemblate da CC, dichiarate: #{assemblate}"
  # ATTENZIONE: qui dentro NON si usano apostrofi. Tutto questo programma sta
  # fra virgolette singole nello shell, e un apostrofo lo chiuderebbe a meta.
  #
  # Il testo e laspetto si accoppiano PER POSIZIONE. Se Cowork aggiunge o
  # toglie una voce e nessuno tocca _data/aspetto.yml, le tinte e i glifi
  # scivolano di una riga, e a occhio non si vede: la pagina resta intera.
  # ⛔ Dal giro W6 le liste accoppiate sono TRE, non una: alle sette carte si
  # sono aggiunte le quattro voci e le tre garanzie della parte alta. Ognuna
  # porta lo stesso rischio, quindi ognuna ha il suo confronto.
  scarto = 0
  if aspetto && File.readable?(aspetto)
    t = YAML.load_file(dati); a = YAML.load_file(aspetto)
    eroe = t["hero"] || {}
    coppie = [
      ["carte",    (t["what"]["items"] || []).size,  (a["what"] || []).size],
      ["punti",    (eroe["punti"] || []).size,       (a["hero_punti"] || []).size],
      ["garanzie", (eroe["garanzie"] || []).size,    (a["hero_garanzie"] || []).size],
    ]
    coppie.each do |nome, n_testo, n_asp|
      d = (n_testo - n_asp).abs
      scarto += d
      puts "  #{nome}: voci di testo #{n_testo} - righe di aspetto #{n_asp}" + (d.zero? ? "" : "  NON COINCIDONO")
    end
  end
  puts "  fuori_bozza=#{mancanti.size + scarto}"
  mancanti.each { |via, t| puts "     ⛔ #{via}: NON sta nella bozza → «#{t[0, 120]}»" }
  exit(mancanti.empty? ? 0 : 1)
' "$BOZZA" "$DATI" "$ASPETTO"
