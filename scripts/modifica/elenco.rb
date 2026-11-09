# scripts/modifica/elenco.rb — COSA HA CAMBIATO PIER, quando dice «ho finito». Giro W37.
# Uso:  bundle exec ruby scripts/modifica/elenco.rb [base] [fino]
#       base = da dove si confronta; senza, `git merge-base HEAD main`.
#       fino = fin dove: un commit; senza, i file come sono adesso sul disco.
# ⭐ Giro W38: due elenchi diversi quando il lavoro di un giro sta sotto le
# modifiche di Pier — `elenco.rb main <commit del giro>` dice cosa ha portato il
# giro; `elenco.rb <commit del giro>` dice cosa ha cambiato Pier sopra.
#
# ⭐ Per ogni testo cambiato: lingua, file, chiave, DOVE SI VEDE (le pagine che
# lo mostrano, prese dalla build sonda) e prima → dopo. È l'elenco che va a
# Cowork per la rilettura da madrelingua (L6) e per aggiornare le bozze.
# ⚠️ Confronta anche ciò che non è ancora in un commit: l'attrezzo scrive i
# file senza salvarli in git.
# ⭐ Per gli stili e ogni altro file elenca solo QUALI file sono cambiati: cosa è
# cambiato a vedersi lo racconta CC a parole.
require "open3"
require "psych"
require "json"
require "tmpdir"
require_relative "testi"

R = Testi::RADICE
def git(*a)
  out, st = Open3.capture2("git", "-C", R, *a)
  abort "git #{a.join(' ')} è fallito" unless st.success?
  out
end

base = ARGV[0] || git("merge-base", "HEAD", "main").strip
fino = ARGV[1]
cambiati = git("diff", "--name-only", base, *[fino].compact, "--").lines.map(&:strip)
cambiati |= git("ls-files", "--others", "--exclude-standard").lines.map(&:strip) unless fino
dati = cambiati.select { |f| f.start_with?("_data/") && f.end_with?(".yml") }
altri = cambiati - dati - cambiati.select { |f| f.match?(%r{\A(scripts/|docs/|\.claude/|CLAUDE\.md|README\.md)}) }

def foglie(x, p = [], out = {})
  case x
  when Hash then x.each { |k, v| foglie(v, p + [k], out) }
  when Array then x.each_with_index { |v, i| foglie(v, p + [i], out) }
  else out[p] = x
  end
  out
end

# Dove si vede un valore: le pagine della sonda che portano il suo segno.
sonda = File.join(Dir.tmpdir, "aimonx-elenco-sonda")
_, st = Open3.capture2e({ "JEKYLL_ENV" => "production" }, "ruby", File.join(__dir__, "sonda.rb"), sonda, chdir: R)
mappa = st.success? ? JSON.parse(File.read(File.join(sonda, "mappa.json"))) : []
pagine = Dir[File.join(sonda, "sito", "**", "*.html")].to_h { |f| [f, File.read(f, encoding: "UTF-8")] }
dove = lambda do |file, percorso|
  id = mappa.index({ "file" => file, "percorso" => percorso })
  return "?" unless id
  segno = Testi::APRI + id.to_s(4).each_char.map { |c| Testi::CIFRE[c.to_i] }.join + Testi::NUMERO
  qui = pagine.select { |_, t| t.include?(segno) }.keys.map { |f| f.sub(File.join(sonda, "sito"), "").sub(/index\.html\z/, "") }
  qui.size > 4 ? "#{qui.size} pagine (#{qui.first(3).join(', ')}…)" : qui.join(", ")
end

lingue = Testi.lingue
n = 0
puts "Cosa è cambiato da #{base} a #{fino || "i file sul disco"} (ramo #{git('rev-parse', '--abbrev-ref', 'HEAD').strip})"
dati.each do |f|
  prima_txt, = Open3.capture2("git", "-C", R, "show", "#{base}:#{f}")
  prima = foglie(Psych.safe_load(prima_txt.to_s) || {})
  dopo_txt = if fino
               Open3.capture2("git", "-C", R, "show", "#{fino}:#{f}").first
             elsif File.file?(File.join(R, f))
               File.read(File.join(R, f), encoding: "UTF-8")
             end
  dopo = foglie(Psych.safe_load(dopo_txt.to_s) || {})
  (prima.keys | dopo.keys).each do |k|
    next if prima[k] == dopo[k]
    n += 1
    lin = lingue.find { |l| l["codice"] == Testi.lingua_del_file(f) }&.[]("nome")
    puts
    puts "#{n}. #{lin} · #{f} · #{k.join('.')}"
    puts "   si vede in: #{dove.call(f, k)}"
    puts "   prima: #{prima[k].inspect}"
    puts "   dopo:  #{dopo[k].inspect}"
  end
end
puts "\nNessun testo cambiato." if n.zero?
unless altri.empty?
  puts "\nAltri file cambiati (la grafica, da raccontare a parole):"
  altri.each { |f| puts "   · #{f}" }
end
