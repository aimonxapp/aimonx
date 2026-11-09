# scripts/modifica/sonda.rb — LA BUILD SONDA: da quale valore viene ogni pezzo di pagina.
# Giro W37, modalità modifica. Uso (da `server.rb`, con `bundle exec`):
#     ruby scripts/modifica/sonda.rb <cartella-di-uscita>
#
# ⭐ PERCHÉ UNA SECONDA BUILD. Cercare una frase nei file di testo, alla lettera,
# non basta: misurato su tutto il sito il 09/11/2026, più di metà dei pezzi di
# testo brevi («Features», «Home», «FAQ») compaiono in più valori, e indovinare
# vorrebbe dire scrivere nel file sbagliato. Qui il sito si costruisce UNA
# SECONDA VOLTA, in una cartella temporanea, con ogni valore dei file di testo
# preceduto e seguito da un segno invisibile che porta il suo numero: nella
# pagina sonda ogni pezzo dice da dove viene. Esatto, non indovinato.
#
# ⛔ LA SONDA NON TOCCA NULLA DEL SITO VERO: i segni si mettono nei dati GIÀ
# LETTI da Jekyll, in memoria (un aggancio `:post_read` registrato da questo
# script, non un plugin del repo), e la build va in una cartella temporanea.
# Nessun file del repo cambia, e la build di produzione resta quella di sempre.
#
# ⚠️ Si segnano solo i valori che sembrano parole: con uno spazio, un apostrofo
# o una punteggiatura, una maiuscola in testa o una lettera non ASCII, e non un
# indirizzo. ⚠️ Restano fuori le parole sole in minuscolo («none»): hanno la
# stessa forma di un nome di icona, e segnarle tutte rompe la build (provato). I nomi di
# file, di icone, i codici delle lingue servono ai layout per trovare le cose,
# e un segno lì dentro romperebbe la build.
require "jekyll"
require "json"

USCITA = ARGV[0] or abort("uso: sonda.rb <cartella-di-uscita>")
RADICE = File.expand_path("../..", __dir__)
SALTA = %w[aspetto lingue collegamenti impronte].freeze # file che non sono parole

APRI = "⁣"   # INVISIBLE SEPARATOR — apre il segno
NUMERO = "⁤" # INVISIBLE PLUS — chiude il numero
CHIUDI = "⁢" # INVISIBLE TIMES — chiude il valore
CIFRE = ["​", "‌", "‍", "⁠"].freeze

def codifica(n)
  s = n.to_s(4)
  s.each_char.map { |c| CIFRE[c.to_i] }.join
end

def parola?(v)
  v.is_a?(String) && !v.start_with?("/", "http", "mailto:") &&
    (v.match?(/[\s'’,!?;:()]/) || v.match?(/\A\p{Lu}/) || v.match?(/[^\x00-\x7F]/))
end

# ⭐ UN VALORE SEGNATO È UGUALE ALL'ORIGINALE PER OGNI CONFRONTO, e porta il
# segno solo quando viene SCRITTO. Misurato al primo tentativo: con il segno
# dentro il testo vero, la barra spariva, perché i nomi del menu servono anche
# da chiavi per trovare i loro indirizzi. Qui il contenuto della stringa resta
# quello originale (uguaglianze, chiavi, `where`, `contains`), e `to_s` — che è
# ciò che Liquid chiama per scrivere e che i filtri chiamano per lavorare —
# restituisce il testo segnato.
class Segnata < String
  def initialize(originale, segnata)
    super(originale)
    @segnata = segnata
  end

  def to_s = @segnata
  def to_liquid = self
end

def piano(x) = x.is_a?(Segnata) ? String.new(x) : x

# ⚠️ Tre filtri che confrontano o tagliano passando per `to_s`, e quindi
# vedrebbero il segno: `where` di Jekyll (i link dalle frasi di
# `collegamenti.yml`) e `slice` di Liquid (la prima lettera di una frase, per
# decidere lo spazio), e `replace`. Misurati nella prima prova; qui lavorano sul testo vero.
# ⛔ Toccano SOLO la build sonda: questo file non è un plugin del sito.
module SondaFiltri
  def where(input, property, value)
    return super if property.nil? || value.nil? || !input.respond_to?(:select)
    lista = input.is_a?(Hash) ? input.values : input
    lista.select do |o|
      Array(item_property(o, property)).map { |x| piano(x).to_s }.include?(piano(value).to_s)
    end
  end

  # Il testo da cercare si cerca senza segno: la pagina di Range System mette
  # in neretto il codice e in link «MakerWorld» dentro una frase.
  def replace(input, string, replacement = "")
    super(input, piano(string), replacement)
  end

  def slice(input, offset, length = nil)
    super(piano(input), offset, length)
  end

  # ⭐ L'A CAPO (Option+Invio): un valore che passa per uno di questi filtri
  # non diventa HTML, o non resta com'è (un indirizzo, un dato strutturato, una
  # parola in minuscolo), e lì un `<br>` si leggerebbe come segni. Si annota il
  # suo numero, e la modalità modifica non lo fa andare a capo.
  %i[jsonify slugify strip_newlines downcase upcase capitalize escape escape_once xml_escape
     strip_html cgi_escape uri_escape url_encode truncate truncatewords normalize_whitespace].each do |f|
    define_method(f) do |input, *resto|
      input.to_s.scan(/#{APRI}([#{CIFRE.join}]*)#{NUMERO}/o) { |(c)| $senza_a_capo << c.each_char.map { |d| CIFRE.index(d) }.join.to_i(4) }
      super(input, *resto)
    end
  end
end
$senza_a_capo = []
Liquid::Template.register_filter(SondaFiltri)

$mappa = []

def segna(nodo, file, percorso)
  case nodo
  when Hash then nodo.each_key { |k| nodo[k] = segna(nodo[k], file, percorso + [k]) }
  when Array then nodo.each_index { |i| nodo[i] = segna(nodo[i], file, percorso + [i]) }
  when String
    return nodo unless parola?(nodo)
    id = $mappa.size
    $mappa << { "file" => file, "percorso" => percorso }
    return Segnata.new(nodo, "#{APRI}#{codifica(id)}#{NUMERO}#{nodo}#{CHIUDI}")
  end
  nodo
end

Jekyll::Hooks.register :site, :post_read do |site|
  lingue = site.data["lingue"].map { |l| l["codice"] }
  site.data.each_key do |nome|
    next if SALTA.include?(nome)
    if lingue.include?(nome) && site.data[nome].is_a?(Hash)
      site.data[nome].each_key do |n2|
        next if SALTA.include?(n2)
        site.data[nome][n2] = segna(site.data[nome][n2], "_data/#{nome}/#{n2}.yml", [])
      end
    else
      site.data[nome] = segna(site.data[nome], "_data/#{nome}.yml", [])
    end
  end
end

ENV["JEKYLL_ENV"] = "production"
Jekyll::Commands::Build.process(
  "source" => RADICE, "destination" => File.join(USCITA, "sito"),
  "safe" => true, "quiet" => true
)
$senza_a_capo.uniq.each { |id| $mappa[id]["senza_a_capo"] = true if $mappa[id] }
File.write(File.join(USCITA, "mappa.json"), JSON.generate($mappa))
