# scripts/modifica/server.rb — IL SITO IN LOCALE, con la modalità modifica. Giro W37.
#
# Lo accende `scripts/modifica/accendi.sh` (l'icona sulla Scrivania di Pier);
# a mano:  bundle exec ruby scripts/modifica/server.rb [porta]
#
# Cosa fa, in quattro pezzi:
#   ① costruisce il sito COME PAGES (`jekyll build --watch --safe`,
#     `JEKYLL_ENV=production`) in una cartella temporanea, e lo ricostruisce
#     da sé a ogni file salvato — di testo o di stile;
#   ② dopo ogni build rifà la build sonda (`sonda.rb`), che dice da quale file
#     viene ogni pezzo di pagina;
#   ③ serve il sito su http://127.0.0.1:<porta>/ — ⛔ SOLO su questo Mac: ascolta
#     su 127.0.0.1, non su una rete — e aggiunge a ogni pagina, SOLO QUI, lo
#     script dell'editore (`editore.js`). ⛔ Il sito costruito non lo contiene:
#     l'aggiunta avviene mentre la pagina viene servita;
#   ④ riceve le modifiche di Pier e le scrive nei file di `_data/` (`testi.rb`).
#
# ⛔ NON TOCCA GIT: scrive i file e basta. Il ramo lo apre `accendi.sh`, e il
# commit lo fa CC quando Pier dice «ho finito».
# ⛔ NON VA MAI ONLINE: sta sotto `scripts/`, che `_config.yml` esclude.
# ⭐ Niente gem nuove: WEBrick, Jekyll e Nokogiri sono già nel Gemfile.lock.
require "webrick"
require "json"
require "tmpdir"
require "fileutils"
require "open3"
require_relative "testi"

PORTA = (ARGV[0] || ENV["MODIFICA_PORTA"] || 4100).to_i
QUI = __dir__
RADICE = Testi::RADICE
# Una cartella per porta: due attrezzi accesi insieme non si pestano i piedi.
LAVORO = File.join(Dir.tmpdir, "aimonx-modifica-#{PORTA}")
SITO = File.join(LAVORO, "sito")
SONDA = File.join(LAVORO, "sonda")
FileUtils.mkdir_p(LAVORO)

$stato = { versione: 0, costruisce: true, errore: nil }
$sonda = nil
$versione_sonda = -1
$serratura = Mutex.new
$scrittura = Mutex.new

def ramo
  out, st = Open3.capture2("git", "-C", RADICE, "rev-parse", "--abbrev-ref", "HEAD")
  st.success? ? out.strip : "?"
end

def rifai_sonda
  nuova = "#{SONDA}-#{Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)}"
  out, st = Open3.capture2e({ "JEKYLL_ENV" => "production" }, "ruby", File.join(QUI, "sonda.rb"), nuova, chdir: RADICE)
  unless st.success?
    warn out
    return nil
  end
  vecchia = Dir["#{SONDA}-*"] - [nuova]
  s = Testi::Sonda.new(nuova)
  diverse = s.verifica(SITO)
  $stdout.puts "  ⚠️  sonda: #{diverse.size} pagine diverse dal sito vero, non si modificano da qui" if diverse.any?
  FileUtils.rm_rf(vecchia)
  s
end

# ① il sito, ricostruito a ogni salvataggio
# ⛔ Jekyll gira come processo a parte: quando questo si spegne, si spegne anche lui.
_in, $uscita_jekyll, $jekyll = Open3.popen2e({ "JEKYLL_ENV" => "production" },
                                             "jekyll", "build", "--watch", "--safe", "-d", SITO, chdir: RADICE)
at_exit do
  Process.kill("TERM", $jekyll.pid)
rescue StandardError
  nil
end
Thread.new do
  begin
    out = $uscita_jekyll
    errore = []
    out.each_line do |riga|
      $stdout.print "  [jekyll] #{riga}" if riga =~ /error|warn|done/i
      if riga =~ /Regenerating|Generating\.\.\./
        $stato[:costruisce] = true
        errore = []
      elsif riga =~ /error/i
        errore << riga.strip
      elsif riga =~ /done in/
        # Il sito è pronto: la pagina può ricaricarsi SUBITO. La sonda viene
        # dopo, e serve solo a chi sta modificando (che la aspetta).
        v = $serratura.synchronize do
          $stato[:errore] = errore.empty? ? nil : errore.join("\n")
          $stato[:costruisce] = false
          $stato[:versione] += 1
        end
        s = rifai_sonda
        $serratura.synchronize { $sonda = s if s; $versione_sonda = v if s }
      end
    end
  end
  $stato[:errore] = "La costruzione del sito si è fermata: chiudi la finestra e riaccendi."
end

server = WEBrick::HTTPServer.new(
  BindAddress: "127.0.0.1", Port: PORTA,
  Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN), AccessLog: []
)

ORIGINI = ["http://127.0.0.1:#{PORTA}", "http://localhost:#{PORTA}"].freeze

# ⛔ Solo dalle pagine di questo server: un'altra pagina aperta nel browser non
# può scrivere nei file. L'intestazione `X-Modifica` obbliga il browser a
# chiedere il permesso prima di una richiesta da un altro sito, e qui il
# permesso non c'è; l'Host controllato tiene fuori i nomi che puntano a 127.0.0.1.
def ammessa?(req)
  ORIGINI.any? { |o| o.end_with?(req.host.to_s + ":#{PORTA}") } &&
    req["X-Modifica"] == "1" && (req["Origin"].nil? || ORIGINI.include?(req["Origin"]))
end

def json(res, dati, codice = 200)
  res.status = codice
  res["Content-Type"] = "application/json; charset=utf-8"
  res["Cache-Control"] = "no-store"
  res.body = JSON.generate(dati)
end

def aspetta_sonda
  100.times do
    s = $serratura.synchronize { $stato[:costruisce] || $versione_sonda != $stato[:versione] ? nil : $sonda }
    return s if s
    sleep 0.2
  end
  raise Testi::Rifiuto, "Il sito si sta ancora ricostruendo: riprova fra qualche secondo."
end

server.mount_proc "/__modifica/" do |req, res|
  nome = req.path.sub("/__modifica/", "")
  case nome
  when "editore.js", "editore.css"
    res["Content-Type"] = nome.end_with?("js") ? "text/javascript; charset=utf-8" : "text/css; charset=utf-8"
    res["Cache-Control"] = "no-store"
    res.body = File.read(File.join(QUI, nome))
  when "stato"
    url = req.query["url"].to_s
    lin = Testi.lingua_di(url)
    json(res, $stato.merge(lingua: lin["nome"], codice: lin["codice"], ramo: ramo))
  when "controlla", "salva"
    unless req.request_method == "POST" && ammessa?(req)
      next json(res, { errore: "Richiesta non ammessa." }, 403)
    end
    begin
      d = JSON.parse(req.body)
      url = d["url"].to_s
      raise Testi::Rifiuto, "La pagina è cambiata: si ricarica." if d["versione"].to_i != $stato[:versione]
      sonda = aspetta_sonda
      if nome == "controlla"
        testi = d["testi"].map do |t|
          st = Testi.giudica(url, sonda.trova_testo(url, t["testo"], t["posizione"]), sonda)
          st.slice(:esito, :file, :chiave).merge(perche: st[:esito] == "ok" ? nil : Testi.spiega(st))
        end
        attributi = d["attributi"].map do |t|
          st = Testi.giudica(url, sonda.trova_attributo(url, t["tipo"], t["indice"]), sonda)
          st.slice(:esito, :file, :chiave, :parte).merge(perche: st[:esito] == "ok" ? nil : Testi.spiega(st))
        end
        json(res, { testi: testi, attributi: attributi })
      else
        trovato = if d["tipo"] == "testo"
                    sonda.trova_testo(url, d["vecchio"], d["posizione"])
                  else
                    sonda.trova_attributo(url, d["tipo"], d["indice"])
                  end
        st = Testi.giudica(url, trovato, sonda)
        raise Testi::Rifiuto, Testi.spiega(st) unless st[:esito] == "ok"
        vecchio = d["vecchio"]
        if d["tipo"] != "testo"
          # Per un attributo si cambia la parte che viene dal file: il resto
          # (per esempio « | AIMONX» in coda a un titolo) lo mette lo stampo.
          parte = trovato[:parte]
          raise Testi::Rifiuto, "Il testo è cambiato: ricarica la pagina." unless Testi.norm(parte) == Testi.norm(vecchio)
        end
        esito = $scrittura.synchronize { Testi.scrivi(st[:file], st[:percorso], st[:scarto], vecchio, d["nuovo"]) }
        $stdout.puts "  ✏️  #{esito[:file]} · #{esito[:chiave]}\n      prima: #{esito[:prima]}\n      dopo:  #{esito[:dopo]}"
        json(res, esito)
      end
    rescue Testi::Rifiuto => e
      json(res, { errore: e.message }, 409)
    rescue StandardError => e
      warn e.full_message
      json(res, { errore: "Errore dell'attrezzo (#{e.class}): chiedi a CC." }, 500)
    end
  else
    res.status = 404
  end
end

INIEZIONE = %(<link rel="stylesheet" href="/__modifica/editore.css"><script src="/__modifica/editore.js" defer></script>)

# ③ il sito, con l'editore aggiunto mentre lo si serve
server.mount_proc "/" do |req, res|
  percorso = File.expand_path(File.join(SITO, req.path))
  percorso = SITO if percorso == SITO
  unless percorso == SITO || percorso.start_with?(SITO + "/")
    res.status = 403
    next
  end
  file = [percorso, File.join(percorso, "index.html"), "#{percorso}.html"].find { |f| File.file?(f) }
  if file.nil? && File.directory?(percorso) && !req.path.end_with?("/")
    res.set_redirect(WEBrick::HTTPStatus::MovedPermanently, req.path + "/")
  end
  if file.nil?
    res.status = 404
    file = File.join(SITO, "404.html")
    next unless File.file?(file)
  end
  # ⭐ Sempre la versione di adesso: niente cache, così un foglio di stile
  # cambiato si vede anche se il suo `?v=` (l'impronta del W26) è rimasto quello.
  res["Cache-Control"] = "no-store"
  tipo = WEBrick::HTTPUtils.mime_type(file, WEBrick::HTTPUtils::DefaultMimeTypes.merge("webp" => "image/webp", "svg" => "image/svg+xml", "woff2" => "font/woff2"))
  res["Content-Type"] = tipo
  corpo = File.binread(file)
  if file.end_with?(".html")
    corpo = corpo.force_encoding("UTF-8").sub(%r{</body>}i) { INIEZIONE + "</body>" }
    res["Content-Type"] = "text/html; charset=utf-8"
  end
  res.body = corpo
end

trap("INT") { server.shutdown }
trap("TERM") { server.shutdown }
trap("HUP") { server.shutdown }
$stdout.puts "  Il sito è su http://127.0.0.1:#{PORTA}/ (ramo: #{ramo})"
server.start
