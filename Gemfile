# Gemfile — la toolchain Jekyll LOCALE del sito. WD25, strada A scelta da Pier
# il 21/09/2026: costruire sul Mac con le stesse versioni di GitHub Pages, e
# GUARDARE il risultato prima di qualunque merge.
#
# ⛔ QUESTE GEM NON SONO UNA SCELTA NOSTRA. La gem `github-pages` è il pacchetto
# che GitHub stessa dichiara in https://pages.github.com/versions.json: fissa
# Jekyll, i plugin e le loro versioni in un blocco solo. Un numero diverso qui
# significherebbe costruire una cosa e pubblicarne un'altra — cioè una prova che
# non prova niente.
#
# ⚠️ IL NUMERO 232 NON SI AGGIORNA A MANO, e non si mette `~>`: lo decide
# GitHub, e si rilegge alla fonte. Il comando che dice quale sia:
#   curl -sS https://pages.github.com/versions.json
# Se quel `github-pages` non è più 232, la toolchain locale è disallineata dal
# sito vero, e il Gemfile.lock va rifatto — non il contrario.
source "https://rubygems.org"

gem "github-pages", "232", group: :jekyll_plugins

# ⚠️ nokogiri NON è fissata da `github-pages` 232 — la dichiara `>= 1.16.2, < 2.0`,
# e bundler prende quindi l'ultima. Misurato: senza questa riga arrivava 1.19.4,
# mentre Pages costruisce con 1.16.7. Qui si fissa al numero di Pages, per la
# stessa ragione di sopra: costruire con le gem del sito vero, non con altre.
gem "nokogiri", "1.16.7"
