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
require "json"

radice = ARGV[0]
pagine = Dir.glob(File.join(radice, "**", "*.html")).sort
$link_rotti = []
$ancore_rotte = []
$seo = []
$ancore_per_pagina = {}
$jsonld = 0
$da_controllare = []
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

  # ⭐ Gli `id` di questa pagina: servono a dire se un link con il `#` cade
  # davvero da qualche parte. ⛔ Un `#sezione` che non esiste non è un errore
  # per il browser — porta in cima alla pagina e basta — quindi è il tipo di
  # rottura che nessuno segnala mai.
  $ancore_per_pagina["/" + nome.sub(%r{index\.html\z}, "")] =
    nudo.scan(/\bid="([^"]+)"/).flatten.to_set

  # --- ⓪ i dati strutturati e l immagine di condivisione (giro W10) ---------
  blocchi = nudo.scan(/<script[^>]*application\/ld\+json[^>]*>(.*?)<\/script>/mi).flatten
  if blocchi.empty?
    $seo << "#{nome}: nessun blocco di dati strutturati"
  else
    blocchi.each do |b|
      begin
        d = JSON.parse(b)
        $jsonld += 1
        $seo << "#{nome}: dati strutturati senza @context schema.org" unless d["@context"].to_s.include?("schema.org")
      rescue JSON::ParserError => e
        $seo << "#{nome}: dati strutturati che non si leggono — #{e.message[0, 70]}"
      end
    end
  end
  og = nudo[/<meta property="og:image" content="([^"]+)"/, 1]
  if og.nil?
    $seo << "#{nome}: nessuna og:image"
  elsif !og.end_with?("condivisione-1200x630.png")
    $seo << "#{nome}: og:image non e l immagine di condivisione -> #{og}"
  end
  %w[og:image:width og:image:height].each do |k|
    $seo << "#{nome}: manca #{k}" unless nudo.include?(%(property="#{k}"))
  end
  unless nudo.include?('name="twitter:card" content="summary_large_image"')
    $seo << "#{nome}: twitter:card non e summary_large_image, con un og:image 1200x630"
  end

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
    meta, frammento = dove.split("#", 2)
    meta = "/" if meta.to_s.empty?
    candidati = [File.join(radice, meta), File.join(radice, meta, "index.html")]
    if candidati.any? { |c| File.file?(c) }
      # ⭐ E se porta a un `#`, il `#` deve esistere NELLA PAGINA DI ARRIVO.
      $da_controllare << [nome, dove, meta, frammento] if frammento && !frammento.empty?
    else
      $link_rotti << "#{nome} -> #{dove}"
    end
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

# --- le ancore, adesso che si conoscono gli id di tutte le pagine ----------
$da_controllare.each do |chi, dove, meta, frammento|
  ids = $ancore_per_pagina[meta]
  if ids.nil?
    $ancore_rotte << "#{chi} -> #{dove} (la pagina di arrivo non si e letta)"
  elsif !ids.include?(frammento)
    $ancore_rotte << "#{chi} -> #{dove} (in quella pagina non c e nessun id \"#{frammento}\")"
  end
end

# --- ② la mappa del sito e robots.txt (giro W10) --------------------------
# ⛔ La mappa si controlla contro LE PAGINE COSTRUITE, nei due versi: ogni
# indirizzo della mappa deve esistere, e ogni pagina deve stare nella mappa.
# ⚠️ Un solo verso non basterebbe: una mappa vuota passerebbe il primo.
mappa = File.join(radice, "sitemap.xml")
indirizzi = []
if !File.file?(mappa)
  $seo << "sitemap.xml non c e"
else
  testo = File.read(mappa, encoding: "UTF-8")
  indirizzi = testo.scan(/<loc>\s*([^<\s]+)\s*<\/loc>/).flatten
  $seo << "sitemap.xml e vuota" if indirizzi.empty?
  indirizzi.each do |u|
    $seo << "sitemap: indirizzo non https -> #{u}" unless u.start_with?("https://")
    percorso = u.sub(%r{\Ahttps?://[^/]+}, "")
    c = [File.join(radice, percorso), File.join(radice, percorso, "index.html")]
    $seo << "sitemap: indirizzo che non esiste nella build -> #{u}" unless c.any? { |x| File.file?(x) }
  end
  pagine.each do |f|
    via = "/" + f.sub(radice.chomp("/") + "/", "").sub(%r{index\.html\z}, "")
    $seo << "sitemap: pagina costruita che NON sta nella mappa -> #{via}" unless indirizzi.any? { |u| u.end_with?(via) }
  end
end

robots = File.join(radice, "robots.txt")
if !File.file?(robots)
  $seo << "robots.txt non c e"
else
  r = File.read(robots, encoding: "UTF-8")
  $seo << "robots.txt non dice User-agent: *" unless r =~ /^User-agent:\s*\*/i
  $seo << "robots.txt non dice Allow: /"      unless r =~ /^Allow:\s*\/\s*$/i
  # ⛔ Decisione di Pier: si permette tutto a tutti, crawler delle AI compresi.
  # Un `Disallow` qui dentro sarebbe una porta chiusa che nessuno ha deciso.
  r.scan(/^Disallow:\s*(\S*)/i) { |(v)| $seo << "robots.txt VIETA qualcosa -> Disallow: #{v}" }
  $seo << "robots.txt non indica la mappa" unless r =~ /^Sitemap:\s*https:\/\//i
end

# --- ③ l immagine di condivisione ------------------------------------------
img = File.join(radice, "assets/img/condivisione-1200x630.png")
if !File.file?(img)
  $seo << "l immagine di condivisione non c e nella build"
else
  testa = File.binread(img, 24)
  if testa[0, 8] != [137, 80, 78, 71, 13, 10, 26, 10].pack("C*")
    $seo << "l immagine di condivisione non e un PNG"
  else
    l, a = testa[16, 8].unpack("N2")
    $seo << "l immagine di condivisione e #{l}x#{a}, non 1200x630" unless l == 1200 && a == 630
  end
end

puts "pagine_costruite=#{pagine.size}"
puts "link_rotti=#{$link_rotti.size}"
puts "titoli_fuori_ordine=#{$titoli_fuori.size}"
puts "indirizzi_o_telefoni=#{$sospetti.size}"
puts "ancore_rotte=#{$ancore_rotte.size}"
puts "sitemap_indirizzi=#{indirizzi.size}"
puts "seo_guasti=#{$seo.size}"
puts "link_verso_fuori=#{$verso_fuori.size}"
puts "blocchi_jsonld=#{$jsonld}"
($link_rotti + $ancore_rotte + $titoli_fuori + $sospetti + $seo).each { |r| puts "  ⛔ #{r}" }
$verso_fuori.sort.each { |u| puts "  · #{u}" }
