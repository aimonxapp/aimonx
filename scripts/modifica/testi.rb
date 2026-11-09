# scripts/modifica/testi.rb — DA DOVE VIENE UN PEZZO DI PAGINA, e come lo si
# cambia senza toccare altro. Giro W37: il cuore della modalità modifica.
#
# ⛔ QUESTO FILE NON VA MAI ONLINE: sta sotto `scripts/`, che `_config.yml`
# esclude, e la controprova conta che nessun file del sito costruito nomini
# l'attrezzo (`attrezzo_nel_sito`).
#
# ⭐ DA DOVE VIENE: lo dice la build sonda (`sonda.rb`), dove ogni valore dei
# file di testo porta un segno invisibile col suo numero. Il pezzo cliccato si
# ritrova nella pagina sonda alla stessa posizione, e il segno che lo racchiude
# dice file e chiave. ⛔ Niente si indovina: se il pezzo non sta dentro UN
# valore, non si cambia da qui, e si dice perché.
#
# ⛔ LA SCRITTURA TOCCA SOLO I CARATTERI DI QUEL PEZZO: il file non si riscrive
# da YAML (si perderebbero commenti e ordine), si sostituisce il pezzo nel testo
# del file. E poi SI RILEGGE TUTTO: il file nuovo deve dare gli stessi dati del
# vecchio salvo quell'unico valore — se no non si scrive.
#
# ⭐ Niente gem nuove: Psych e Nokogiri sono già nella toolchain del sito.
require "psych"
require "json"
require "nokogiri"

module Testi
  RADICE = File.expand_path("../..", __dir__)

  APRI = "⁣"
  NUMERO = "⁤"
  CHIUDI = "⁢"
  CIFRE = ["​", "‌", "‍", "⁠"].freeze
  ESCLUSI = %w[script style noscript template].freeze

  class Rifiuto < StandardError; end

  # Il carattere che i layout mettono al posto di uno spazio (`&nbsp;`): per il
  # confronto vale come uno spazio. È uno a uno, quindi le posizioni tengono.
  def self.norm(s) = s.to_s.tr(" ", " ")

  def self.lingue
    Psych.safe_load(File.read(File.join(RADICE, "_data/lingue.yml"), encoding: "UTF-8"))
  end

  # La lingua di un indirizzo, dal prefisso (`/it/…`); senza prefisso, la prima.
  def self.lingua_di(url)
    l = lingue
    l.find { |x| x["prefisso"].to_s != "" && (url == x["prefisso"] || url.start_with?(x["prefisso"] + "/")) } || l.first
  end

  # La lingua di un file di testo: la cartella, o la prima se sta alla radice.
  def self.lingua_del_file(file)
    m = file.match(%r{\A_data/([a-z]{2})/})
    m ? m[1] : lingue.first["codice"]
  end

  # ---- la pagina sonda --------------------------------------------------------

  # Testo di una stringa sonda: [testo senza segni, per ogni carattere l'id del
  # valore che lo racchiude (o nil), e dove comincia ogni valore].
  def self.svolgi(s, ids = [], pila = [], testo = +"", inizi = {})
    i = 0
    while i < s.length
      c = s[i]
      if c == APRI
        j = s.index(NUMERO, i)
        n = s[(i + 1)...j].each_char.map { |d| CIFRE.index(d) }.join.to_i(4)
        pila.push(n)
        inizi[n] ||= testo.length
        i = j + 1
      elsif c == CHIUDI
        pila.pop
        i += 1
      else
        testo << c
        ids << pila.last
        i += 1
      end
    end
    [testo, ids, pila, inizi]
  end

  # Il segno che apre un valore, col suo numero (lo stesso di `sonda.rb`).
  def self.segno(id)
    APRI + id.to_s(4).each_char.map { |c| CIFRE[c.to_i] }.join + NUMERO
  end

  # ⭐ L'A CAPO (Option+Invio, Pier 09/11/2026): nel file è `<br>`, e nella
  # pagina non è testo. Da un punto del testo VISIBILE di un valore al punto
  # del valore vero, saltando i `<br>` (un pezzo cliccato non comincia mai con uno).
  BR = "<br>"
  def self.visibile(s) = s.gsub(BR, "")

  def self.a_grezzo(valore, k)
    raw = 0
    vis = 0
    while vis < k && raw < valore.length
      if valore[raw, BR.length] == BR then raw += BR.length
      else
        raw += 1
        vis += 1
      end
    end
    raw += BR.length while valore[raw, BR.length] == BR
    raw
  end

  def self.togli_segni(s) = s.gsub(/#{APRI}[#{CIFRE.join}]*#{NUMERO}|#{CHIUDI}/o, "")

  class Sonda
    def initialize(cartella)
      @cartella = cartella
      @mappa = JSON.parse(File.read(File.join(cartella, "mappa.json")))
      @pagine = {}
    end

    def voce(id) = @mappa[id]

    # ⭐ Un valore va a capo SOLO se in ogni pagina sta nel testo del corpo: nel
    # titolo, nella descrizione per Google, in un testo alternativo o nei dati
    # strutturati un `<br>` si leggerebbe come segni.
    def solo_nel_corpo?(id)
      return false if voce(id)["senza_a_capo"]
      segno = Testi.segno(id)
      Dir[File.join(@cartella, "sito", "**", "*.html")].all? do |f|
        grezzo = File.read(f, encoding: "UTF-8")
        tutte = grezzo.scan(segno).size
        next true if tutte.zero?
        corpo = 0
        Nokogiri::HTML5(grezzo).at("body")&.traverse do |n|
          next unless n.text? && n.ancestors.none? { |a| ESCLUSI.include?(a.name) }
          corpo += n.content.scan(segno).size
        end
        corpo == tutte
      end
    end

    # ⛔ LA SONDA SI CONTROLLA DA SÉ, a ogni build: tolti i segni, ogni sua
    # pagina deve essere IDENTICA al byte a quella del sito vero. Una pagina
    # che non lo è (un filtro che il segno ha confuso) non si modifica da qui,
    # invece di rischiare di scrivere nel posto sbagliato. Misurato il 09/11/2026:
    # 73 pagine su 73 identiche.
    def verifica(sito)
      @inaffidabili = Dir[File.join(@cartella, "sito", "**", "*.html")].reject do |f|
        vero = f.sub(File.join(@cartella, "sito"), sito)
        File.file?(vero) && Testi.togli_segni(File.read(f, encoding: "UTF-8")) == File.read(vero, encoding: "UTF-8")
      end
    end

    def controlla_pagina(url)
      return unless @inaffidabili&.include?(file_pagina(url))
      raise Rifiuto, "Su questa pagina l'attrezzo non sa dire con certezza da dove viene ogni testo: chiedi a CC."
    end

    def file_pagina(url)
      base = File.join(@cartella, "sito", url)
      [File.join(base, "index.html"), base].find { |f| File.file?(f) } or
        raise Rifiuto, "Non trovo questa pagina nella sonda (#{url})."
    end

    def pagina(url)
      @pagine[url] ||= begin
        doc = Nokogiri::HTML5(File.read(file_pagina(url), encoding: "UTF-8"))
        testo = +""
        ids = []
        pila = []
        inizi = {}
        doc.at("body").traverse do |n|
          next unless n.text?
          next if n.ancestors.any? { |a| ESCLUSI.include?(a.name) }
          Testi.svolgi(n.content, ids, pila, testo, inizi)
        end
        { doc: doc, testo: testo, ids: ids, inizi: inizi }
      end
    end

    # Il valore da cui viene un pezzo di testo che sulla pagina vera comincia a
    # `posizione` (contata come fa l'editore nel browser).
    def trova_testo(url, pezzo, posizione)
      controlla_pagina(url)
      p = pagina(url)
      t = Testi.norm(p[:testo])
      pz = Testi.norm(pezzo)
      dove = []
      i = t.index(pz)
      while i
        dove << i
        i = t.index(pz, i + 1)
      end
      raise Rifiuto, "Non ritrovo questo testo nella pagina: ricaricala e riprova." if dove.empty?
      inizio = dove.min_by { |x| (x - posizione.to_i).abs }
      tratto = p[:ids][inizio, pz.length]
      return { esito: "stampo" } if tratto.all?(&:nil?)
      return { esito: "misto" } unless tratto.uniq.size == 1
      id = tratto.first
      { esito: "ok", id: id, scarto: inizio - p[:inizi][id] }
    end

    # Il valore di un attributo (testo alternativo) o di un testo della testa.
    def trova_attributo(url, tipo, indice)
      controlla_pagina(url)
      doc = pagina(url)[:doc]
      grezzo =
        case tipo
        when "title" then doc.at("head title")&.content
        when "description" then doc.at('head meta[name="description"]')&.[]("content")
        when "alt" then doc.css("body img[alt]")[indice.to_i]&.[]("alt")
        end
      raise Rifiuto, "Non ritrovo questo testo nella pagina: ricaricala e riprova." if grezzo.nil?
      testo, ids, _, inizi = Testi.svolgi(grezzo)
      tratto = ids.compact.uniq
      return { esito: "stampo" } if tratto.empty?
      return { esito: "misto" } if tratto.size > 1
      id = tratto.first
      # Si cambia il valore intero: la parte dell'attributo che viene dal file.
      parte = testo.each_char.select.with_index { |_, k| ids[k] == id }.join
      { esito: "ok", id: id, scarto: 0, parte: parte }
    end
  end

  # ---- lo stato di un pezzo: si può cambiare da qui? ---------------------------

  def self.giudica(url, trovato, sonda)
    return trovato unless trovato[:esito] == "ok"
    v = sonda.voce(trovato[:id])
    lin_pagina = lingua_di(url)["codice"]
    lin_file = lingua_del_file(v["file"])
    if lin_file != lin_pagina
      nome = lingue.find { |l| l["codice"] == lin_file }&.[]("nome")
      return { esito: "altra_lingua", file: v["file"], lingua: nome }
    end
    trovato.merge(file: v["file"], chiave: v["percorso"].join("."), percorso: v["percorso"])
  end

  def self.spiega(st)
    case st[:esito]
    when "stampo"
      "Questo testo non sta in un file di testo: è scritto nello stampo della pagina. Chiedilo a CC."
    when "misto"
      "Questo pezzo unisce testi che vengono da posti diversi: cambiane una parte alla volta, o chiedilo a CC."
    when "altra_lingua"
      "Questo testo viene dal file #{st[:lingua] ? "in #{st[:lingua]}" : ''} (#{st[:file]}): da questa pagina non si cambia, perché cambierebbe un'altra lingua. Chiedilo a CC."
    else
      "Non si può cambiare da qui."
    end
  end

  # ---- la scrittura -------------------------------------------------------------

  Valore = Struct.new(:percorso, :valore, :stile, :riga, :col, :riga_fine, :col_fine)

  # I valori di un file YAML con la loro posizione nel testo del file.
  class Raccolta < Psych::Handler
    attr_reader :valori

    def initialize
      @valori = []
      @pila = [] # [:map, aspetta_chiave, chiave] o [:seq, indice]
    end

    def event_location(sl, sc, el, ec) = (@pos = [sl, sc, el, ec])
    def start_mapping(*) = entra([:map, true, nil])
    def start_sequence(*) = entra([:seq, 0])
    def end_mapping = esci
    def end_sequence = esci

    def scalar(valore, _anc, _tag, _plain, _quoted, stile)
      cima = @pila.last
      if cima && cima[0] == :map && cima[1]
        cima[1] = false
        cima[2] = valore
        return
      end
      @valori << Valore.new(@pila.map { |p| p[0] == :map ? p[2] : p[1] }, valore, stile, *@pos)
      avanza
    end

    private

    def entra(cosa) = @pila << cosa

    def esci
      @pila.pop
      avanza
    end

    def avanza
      cima = @pila.last
      return unless cima
      cima[0] == :map ? cima[1] = true : cima[1] += 1
    end
  end

  def self.escapa(s, stile)
    case stile
    when Psych::Nodes::Scalar::DOUBLE_QUOTED then s.gsub("\\") { "\\\\" }.gsub('"') { '\\"' }
    when Psych::Nodes::Scalar::SINGLE_QUOTED then s.gsub("'", "''")
    else s
    end
  end

  def self.virgolette(stile)
    { Psych::Nodes::Scalar::DOUBLE_QUOTED => '"', Psych::Nodes::Scalar::SINGLE_QUOTED => "'" }[stile] || ""
  end

  def self.offset(righe, riga, col) = righe[0...riga].sum(&:length) + col

  def self.metti(dati, percorso, valore)
    *su, ultimo = percorso
    su.reduce(dati) { |d, k| d[k] }[ultimo] = valore
  end

  # Cambia `vecchio` → `nuovo` nel valore `percorso` del file, a partire dal
  # carattere `scarto` del valore. Restituisce prima e dopo del valore intero.
  def self.scrivi(file_rel, percorso, scarto, vecchio, nuovo, a_capo: false)
    vecchio = norm(vecchio)
    nuovo = norm(nuovo).strip.empty? ? "" : norm(nuovo)
    raise Rifiuto, "Il testo nuovo è vuoto: per togliere una frase intera chiedi a CC." if nuovo.empty?
    raise Rifiuto, "Non è cambiato niente." if nuovo == vecchio
    if nuovo.include?("\n")
      raise Rifiuto, "Qui non si va a capo: questo testo serve anche altrove (il titolo per Google, una descrizione, un testo alternativo o l'ancora di una domanda). Chiedilo a CC." unless a_capo
      nuovo = nuovo.split("\n").map(&:strip).reject(&:empty?).join(BR)
    end

    file = File.join(RADICE, file_rel)
    testo = File.read(file, encoding: "UTF-8")
    v = Raccolta.new.tap { |r| Psych::Parser.new(r).parse(testo) }.valori.find { |x| x.percorso == percorso }
    raise Rifiuto, "Non ritrovo il testo nel file #{file_rel}: forse è cambiato. Ricarica la pagina." unless v

    # Il pezzo si cerca nel testo VISIBILE (senza i `<br>`), poi si riporta al valore vero.
    vis = visibile(norm(v.valore))
    k = vis[scarto, vecchio.length] == vecchio ? scarto : nil
    if k.nil?
      tutte = vis.scan(vecchio).size
      raise Rifiuto, "Il testo nel file #{file_rel} non è più quello della pagina: ricaricala e riprova." unless tutte == 1
      k = vis.index(vecchio)
    end
    i = a_grezzo(v.valore, k)
    raise Rifiuto, "Il testo nel file #{file_rel} non è più quello della pagina: ricaricala e riprova." unless norm(v.valore)[i, vecchio.length] == vecchio
    # Si cambia il valore VERO: gli eventuali spazi fissi fuori dal pezzo restano dov'erano.
    valore_nuovo = v.valore[0...i] + nuovo + v.valore[(i + vecchio.length)..]

    righe = testo.lines
    da = offset(righe, v.riga, v.col)
    a = offset(righe, v.riga_fine, v.col_fine)
    sorgente = testo[da...a]
    q = virgolette(v.stile)

    candidati = []
    # ① Il caso normale: il valore è scritto com'è, fra le sue virgolette. Si
    #    sostituiscono solo i caratteri del pezzo, nella sua posizione.
    if sorgente == q + escapa(v.valore, v.stile) + q
      p0 = q.length + escapa(v.valore[0...i], v.stile).length
      p1 = p0 + escapa(v.valore[i, vecchio.length], v.stile).length
      candidati << sorgente[0...p0] + escapa(nuovo, v.stile) + sorgente[p1..]
    end
    # ② Se no (un escape, un valore senza virgolette che con il testo nuovo non
    #    reggerebbe più), il valore intero fra virgolette doppie, sulla sua riga.
    candidati << "\"#{escapa(valore_nuovo, Psych::Nodes::Scalar::DOUBLE_QUOTED)}\""

    prima = Psych.safe_load(testo)
    atteso = Marshal.load(Marshal.dump(prima))
    metti(atteso, percorso, valore_nuovo)
    candidati.each do |s|
      testo_nuovo = testo[0...da] + s + testo[a..]
      dopo = begin
        Psych.safe_load(testo_nuovo)
      rescue Psych::Exception
        next
      end
      next unless dopo == atteso

      File.write(file + ".modifica", testo_nuovo)
      File.rename(file + ".modifica", file)
      return { file: file_rel, chiave: percorso.join("."), prima: v.valore, dopo: valore_nuovo }
    end
    raise Rifiuto, "Non riesco a scriverlo senza toccare altro nel file #{file_rel}: chiedilo a CC."
  end
end
