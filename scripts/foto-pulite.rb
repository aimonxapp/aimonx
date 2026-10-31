# scripts/foto-pulite.rb — NESSUNA POSIZIONE DENTRO LE IMMAGINI DEL REPO. Giro W31.
#
# ⛔ Il repo è PUBBLICO e il MUST di Pier vale anche dentro i file: gli originali
# delle foto hanno la posizione di scatto. Questa misura guarda i byte dei file
# TRACCIATI, non si fida di come sono stati fatti.
#   · WebP: i contenitori `EXIF` e `XMP ` sono vietati;
#   · PNG: nel blocco `eXIf` è vietato il puntatore GPS;
#   · JPEG, HEIC, TIFF: non devono esserci proprio — il sito non ne usa, e sono
#     i formati in cui la posizione arriva dalla macchina fotografica.
# ⚠️ Nessuna libreria: i due formati si leggono a mano, sono blocchi con nome e
# lunghezza. ⛔ Un file che non si legge si conta come guasto, non come pulito.
#
# Uso:  ruby scripts/foto-pulite.rb <file>…   → stampa immagini_guardate= e immagini_con_metadati=
guasti = []
guardate = 0

ARGV.each do |f|
  guardate += 1
  b = File.binread(f)
  case File.extname(f).downcase
  when ".webp"
    unless b[0, 4] == "RIFF" && b[8, 4] == "WEBP"
      guasti << "#{f}: non si legge come WebP"
      next
    end
    i = 12
    while i + 8 <= b.size
      nome = b[i, 4]
      n = b[i + 4, 4].unpack1("V")
      guasti << "#{f}: contiene il blocco #{nome.strip}" if ["EXIF", "XMP "].include?(nome)
      i += 8 + n + (n % 2)
    end
  when ".png"
    unless b[0, 8] == "\x89PNG\r\n\x1a\n".b
      guasti << "#{f}: non si legge come PNG"
      next
    end
    i = 8
    while i + 8 <= b.size
      n = b[i, 4].unpack1("N")
      nome = b[i + 4, 4]
      # ⚠️ Le icone hanno un `eXIf` di poche righe (colore e dimensioni), da quando
      # sono entrate: nessuna posizione, e il divieto è la POSIZIONE, cioè il
      # puntatore GPS (etichetta 0x8825) nel primo elenco del blocco.
      if nome == "eXIf"
        e = b[i + 8, n]
        fmt = e[0, 2] == "II" ? "v" : "n"
        lung = fmt == "v" ? "V" : "N"
        p = e[4, 4].unpack1(lung)
        conta = e[p, 2].unpack1(fmt)
        etichette = (0...conta).map { |k| e[p + 2 + k * 12, 2].unpack1(fmt) }
        guasti << "#{f}: il blocco eXIf porta la posizione" if etichette.include?(0x8825)
      end
      i += 12 + n
    end
  when ".svg"
    next
  else
    guasti << "#{f}: formato che può portare la posizione"
  end
end

guasti.each { |g| warn "  ⛔ #{g}" }
puts "immagini_guardate=#{guardate}"
puts "immagini_con_metadati=#{guasti.size}"
