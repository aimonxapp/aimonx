# scripts/misure-pagine.rb — LE MISURE CHE SI FANNO SULLE PAGINE COSTRUITE.
# Nato nel giro W9, quando il sito è passato da una pagina a quattro.
#
# ⛔ SI GUARDA IL SITO COSTRUITO, NON IL REPO. Fra i sorgenti e le pagine c'è
# Jekyll: un link scritto `/terms/` nei dati può uscire diverso, un titolo può
# arrivare da un layout che nessuno ha riletto. Quel che conta è quel che esce.
#
# ⛔ NIENTE PARSER HTML, e non è pigrizia: nessuna libreria di terze parti entra
# in questo repo (CLAUDE.md, «Vincoli non negoziabili»). Le pagine qui dentro
# le scriviamo noi, sono quattro, e le espressioni qui sotto le leggono per
# quello che sono — non per quello che HTML permetterebbe in generale.
#
# Stampa righe `chiave=numero`, che scripts/controprova.sh confronta con
# scripts/attese.txt. ⛔ Non decide niente: misura e basta.
require "set"

radice = ARGV[0]
pagine = Dir.glob(File.join(radice, "**", "*.html")).sort
$link_rotti = []
$titoli_fuori = []
$sospetti = []
$verso_fuori = Set.new

# ---------------------------------------------------------------------------
# ⛔⛔ IL MUST DI PIER, MISURATO: il suo indirizzo e il suo telefono non vanno
# MAI online. ⚠️ Questo controllo NON sa quali siano — e non deve saperlo: un
# controllo che contenesse l'indirizzo di Pier lo pubblicherebbe lui stesso,
# esattamente come per i percorsi del disco in scripts/controprova.sh.
# ⭐ Quindi cerca la FORMA, non il valore: qualcosa che SOMIGLI a un recapito
# postale o a un numero di telefono, di chiunque sia.
# ⚠️ Un controllo di forma può protestare a vuoto (un falso allarme), e va
# bene: un falso allarme si guarda in trenta secondi, il MUST no.
RECAPITI = [
  [/\b(?:tel|sms|callto|fax):/i,                      "un link che chiama o manda un SMS"],
  [/\+\d{1,3}[ .\-]?\d[\d .\-]{6,}/,                  "un numero con il prefisso internazionale"],
  [/\(?\b\d{3}\)?[ .\-]\d{3}[ .\-]\d{4}\b/,           "un numero nella forma americana"],
  [/\b\d{2,4}[ .\-]\d{6,8}\b/,                        "un numero nella forma italiana"],
  [/\b(?:Via|Viale|Vicolo|Corso|Piazza|Strada|Largo)\s+[A-Z]/, "una via o una piazza"],
  [/\b(?:P\.?\s?O\.?\s?Box|Casella\s+Postale)\b/i,    "una casella postale"],
  [/\b\d+[A-Za-z]?\s+[A-Z][a-zA-Z]+\s+(?:Street|St\.|Road|Rd\.|Avenue|Ave\.|Drive|Dr\.|Lane|Ln\.|Boulevard|Blvd\.|Parkway|Pkwy\.|Way|Court|Ct\.|Place|Pl\.|Terrace|Circle)\b/, "un indirizzo all americana"],
  [/\b\d{5}\s+[A-Z][a-z]{2,}\b/,                      "un CAP seguito da una citta"],
]

pagine.each do |percorso|
  nome = percorso.sub(radice.chomp("/") + "/", "")
  html = File.read(percorso, encoding: "UTF-8")
  nudo = html.gsub(/<!--.*?-->/m, " ")

  # --- ① i link -------------------------------------------------------------
  # ⚠️ SOLO i link veri, cioè gli `<a href>`: un `<link rel=stylesheet>` o un
  # `<img src>` non è un link, è una risorsa, e la conta un altro controllo.
  nudo.scan(/<a\b[^>]*\bhref="([^"]*)"/i) do |(dove)|
    next if dove.start_with?("#")
    if dove =~ %r{\A[a-z][a-z0-9+.\-]*:}i
      # ⛔ Un indirizzo verso fuori NON è una risorsa esterna: la pagina non
      # scarica niente da quel dominio, ci manda il lettore solo se clicca
      # (giro W9 §1). Si contano per poterli guardare, non per protestare.
      $verso_fuori << dove unless dove.start_with?("mailto:")
      next
    end
    # Un indirizzo di questo sito deve risolvere in una pagina costruita.
    meta = dove.split("#").first.to_s
    meta = "/" if meta.empty?
    candidati = [File.join(radice, meta), File.join(radice, meta, "index.html")]
    $link_rotti << "#{nome} -> #{dove}" unless candidati.any? { |c| File.file?(c) }
  end

  # --- ② l'ordine dei titoli ------------------------------------------------
  # ⛔ Un lettore di schermo naviga per titoli: saltare da h1 a h3 gli toglie un
  # piano dell'indice, e due h1 gli dicono che la pagina è due pagine.
  livelli = nudo.scan(/<h([1-6])\b/i).flatten.map(&:to_i)
  uno = livelli.count(1)
  $titoli_fuori << "#{nome}: #{uno} titoli h1 (ne serve 1)" if uno != 1
  livelli.each_cons(2) do |a, b|
    $titoli_fuori << "#{nome}: da h#{a} a h#{b}, un piano saltato" if b > a + 1
  end

  # --- ③ il MUST -----------------------------------------------------------
  RECAPITI.each do |motivo, cosa|
    nudo.scan(motivo) { |_| $sospetti << "#{nome}: #{cosa} -> «#{$~[0].strip[0, 60]}»" }
  end
end

puts "pagine_costruite=#{pagine.size}"
puts "link_rotti=#{$link_rotti.size}"
puts "titoli_fuori_ordine=#{$titoli_fuori.size}"
puts "indirizzi_o_telefoni=#{$sospetti.size}"
puts "link_verso_fuori=#{$verso_fuori.size}"
($link_rotti + $titoli_fuori + $sospetti).each { |r| puts "  ⛔ #{r}" }
$verso_fuori.sort.each { |u| puts "  · #{u}" }
