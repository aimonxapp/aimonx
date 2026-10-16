#!/bin/bash
#
# La fotografia dell'ambiente da cui dipende l'APP — WD36, giro W20.
# Uso:  scripts/ambiente.sh > prima.txt
#       … si installa lo strumento nuovo per il sito …
#       scripts/ambiente.sh > dopo.txt && diff prima.txt dopo.txt
#
# ⛔⛔ Sito e app non si mischiano (Pier, 15/10/2026). Questa misura esiste per
# provarlo invece di ricordarlo: ogni strumento nuovo per il sito passa di qui,
# prima e dopo, e si tiene solo se il «dopo» è uguale al «prima» per tutto ciò
# che non è suo (la regola sta in CLAUDE.md, fra gli strumenti).
#
# ⛔ LA MISURA NON CAMBIA NIENTE DI CIÒ CHE MISURA, e lo prova da sé: l'ultima
# sezione cerca ogni file scritto, nei posti misurati, MENTRE la misura girava.
# Per questo:
#   · le formule installate si leggono dal Cellar, sul disco, non da `brew list`;
#   · ⛔ niente `brew outdated`, e non per prudenza: MISURATO nel giro W20, la
#     prima esecuzione ha scaricato nella cache di Homebrew l'indice di questo
#     macOS (5 file in ~/Library/Caches/Homebrew/api/internal), e
#     HOMEBREW_NO_AUTO_UPDATE non l'ha impedito, perché quell'indice mancava.
#     Le formule obsolete dipendono dall'indice, non dalla macchina: chi le
#     vuole lancia `brew outdated` da sé, sapendo che può scrivere;
#   · Python con -I -B: niente moduli dalla cartella corrente, niente .pyc;
#   · npm e i plugin si leggono dai loro package.json, non lanciando npm;
#   · git con --no-optional-locks: `git status` altrimenti riscrive l'indice;
#   · l'account attivo di gh si legge da hosts.yml: nessuna chiamata di rete;
#   · ⛔ niente `git push --dry-run` sul repo dell'app (lo faceva il giro W2):
#     parla col remote, che dal 12/10/2026 sta fuori da GitHub. Qui si confrontano solo
#     i riferimenti già sul disco.
#
# ⚠️ Due esecuzioni di seguito devono dare due fotografie IDENTICHE: è la prova
# che il «prima» è fermo. ⛔ Per questo nell'output non c'è un orario, né una
# data di modifica, né un file che cambia da solo.
# ⚠️ Non è tracciato niente di personale: i percorsi si scrivono con «~», e
# i valori di `git config --global` escono come impronta, non per esteso.
#
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR=""
# shellcheck source=/dev/null
[ -r "$REPO/scripts/percorsi-locali.sh" ] && . "$REPO/scripts/percorsi-locali.sh"
export LC_ALL=C HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 \
       HOMEBREW_NO_ENV_HINTS=1 GH_NO_UPDATE_NOTIFIER=1

SEGNO="$(mktemp -d)/segno"
: >"$SEGNO"
trap 'rm -rf "$(dirname "$SEGNO")"' EXIT

corto() { sed "s|$HOME|~|g"; }
sezione() { printf '\n== %s\n' "$1"; }
# versione ETICHETTA COMANDO… → la prima riga, o «assente» se il comando manca
versione() {
  local et="$1"; shift
  if command -v "$1" >/dev/null 2>&1 || [ -x "$1" ]; then
    printf '%s: %s\n' "$et" "$("$@" 2>&1 | head -n 1)"
  else
    printf '%s: assente\n' "$et"
  fi
}
impronta() { shasum -a 256 | cut -c1-16; }

BREW=/opt/homebrew
sezione "macOS e Xcode"
echo "macOS: $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
XC="$(xcode-select -p 2>/dev/null)"
echo "xcode-select: ${XC:-assente}" | corto
[ -n "$XC" ] && echo "Xcode: $(plutil -extract CFBundleShortVersionString raw "$XC/../Info.plist" 2>/dev/null || echo '?')"

sezione "Homebrew"
versione "brew" "$BREW/bin/brew" --version
echo "formule installate: $(find "$BREW/Cellar" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
echo "cask installati: $(find "$BREW/Caskroom" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
echo "formula versione — tutte, dal Cellar:"
find "$BREW/Cellar" -mindepth 2 -maxdepth 2 -type d | sed "s|$BREW/Cellar/||; s|/| |" | sort | sed 's/^/  /'

sezione "Le dipendenze condivise con l'app"
versione "openssl@3" "$BREW/opt/openssl@3/bin/openssl" version
versione "python@3.11" "$BREW/opt/python@3.11/bin/python3.11" --version
versione "python@3.12" "$BREW/opt/python@3.12/bin/python3.12" --version
echo "python3 nel PATH: $(command -v python3 || echo assente)" | corto
versione "python3" python3 --version
# ⚠️ I pacchetti aggiunti a mano, non le versioni: l'app non ne chiede nessuno
# (il solo `openpyxl` lo prende in un venv usa-e-getta, carica-traduzioni.py).
for PY in "$BREW/opt/python@3.11/bin/python3.11" "$BREW/opt/python@3.12/bin/python3.12"; do
  SP=$("$PY" -I -B -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])' 2>/dev/null)
  echo "  $(basename "$PY") site-packages: $(ls "$SP" 2>/dev/null | sed -n 's/-[^-]*\.dist-info$//p' | sort | tr '\n' ' ')"
done
echo "~/Library/Python (pacchetti --user): $(ls ~/Library/Python 2>/dev/null | tr '\n' ' ')"
versione "node" node --version
NPMPKG="$(dirname "$(command -v node 2>/dev/null || echo /x)")/../lib/node_modules/npm/package.json"
echo "npm: $(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$NPMPKG" 2>/dev/null | head -n 1)"
echo "pacchetti npm globali: $(ls "$(dirname "$NPMPKG")/.." 2>/dev/null | tr '\n' ' ')"

sezione "Ruby — quello di sistema resta davanti"
echo "which ruby: $(command -v ruby || echo assente)" | corto
versione "/usr/bin/ruby" /usr/bin/ruby --version
case ":$PATH:" in *rbenv*) echo "rbenv nel PATH: SÌ" ;; *) echo "rbenv nel PATH: no" ;; esac
RC=$(grep -l rbenv ~/.zshrc ~/.zprofile ~/.zshenv ~/.bash_profile ~/.bashrc ~/.profile 2>/dev/null | corto | tr '\n' ' ')
echo "file della shell che nominano rbenv: ${RC:-nessuno}"

sezione "gh e git"
versione "gh" gh --version
echo "account in hosts.yml: $(sed -n 's/^        \([A-Za-z0-9_-]*\):.*/\1/p' ~/.config/gh/hosts.yml 2>/dev/null | sort | tr '\n' ' ')"
echo "account ATTIVO: $(sed -n 's/^    user: *//p' ~/.config/gh/hosts.yml 2>/dev/null)"
echo "git config --global — chiavi: $(git config --global --list --name-only 2>/dev/null | sort | tr '\n' ' ')"
echo "git config --global — impronta dei valori: $(git config --global --list 2>/dev/null | impronta)"
echo "credential helper del repo sito (locale): $(git -C "$REPO" config --local --get-regexp '^credential\.' 2>/dev/null | wc -l | tr -d ' ') riga/e"

sezione "Il repo dell'app — letto, mai scritto"
if [ -n "$APP_DIR" ] && [ -d "$APP_DIR/.git" ]; then
  G() { git -C "$APP_DIR" --no-optional-locks "$@"; }
  echo "ramo: $(G rev-parse --abbrev-ref HEAD) @ $(G rev-parse --short HEAD)"
  echo "file modificati o nuovi: $(G status --porcelain | wc -l | tr -d ' ') · stash: $(G stash list | wc -l | tr -d ' ')"
  echo "remote: $(G remote | tr '\n' ' ')"
  echo "rami locali, e dove stanno rispetto al loro remote (riferimenti sul disco):"
  G for-each-ref --format='  %(refname:short) %(objectname:short) %(upstream:short) %(upstream:track)' refs/heads
  echo "plugin abilitati nel repo dell'app: $(sed -n '/enabledPlugins/,/}/p' "$APP_DIR/.claude/settings.json" 2>/dev/null | grep -c '@')"
else
  echo "⛔ NON MISURABILE: manca scripts/percorsi-locali.sh, o APP_DIR non è un repo"
fi

sezione "I pezzi del sito — che stiano dove sono stati messi"
echo "~/.rbenv/versions: $(ls ~/.rbenv/versions 2>/dev/null | tr '\n' ' ')"
versione "ruby del sito" ~/.rbenv/versions/3.3.4/bin/ruby --version
echo "rbenv @ $(git -C ~/.rbenv --no-optional-locks rev-parse --short HEAD 2>/dev/null) · ruby-build @ $(git -C ~/.rbenv/plugins/ruby-build --no-optional-locks rev-parse --short HEAD 2>/dev/null)"
echo "~/.aimonx-web-tools: $(ls ~/.aimonx-web-tools/node_modules 2>/dev/null | tr '\n' ' ')· playwright $(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' ~/.aimonx-web-tools/node_modules/playwright/package.json 2>/dev/null | head -n 1)"
echo "browser di Playwright: $(ls ~/Library/Caches/ms-playwright 2>/dev/null | tr '\n' ' ')· $(du -sk ~/Library/Caches/ms-playwright 2>/dev/null | cut -f1) KB"
echo "cache di npx (il server MCP di playwright gira da qui):"
for d in ~/.npm/_npx/*/; do
  [ -f "$d/package.json" ] && echo "  $(basename "$d") $(tr -d '\n ' <"$d/package.json" | sed -n 's/.*"dependencies":{\([^}]*\)}.*/\1/p')"
done
echo "plugin di Claude Code — nome, scope, progetto, versione:"
python3 -I -B - <<'PY' | corto
import json, os
p = os.path.expanduser("~/.claude/plugins/installed_plugins.json")
try:
    d = json.load(open(p))["plugins"]
except Exception as e:
    print("  ⛔ NON MISURABILE:", type(e).__name__); raise SystemExit
for nome in sorted(d):
    for i in d[nome]:
        print("  %s %s %s %s" % (nome, i.get("scope"), i.get("projectPath", "-"), i.get("version")))
PY
echo "plugin abilitati in scope user: $(sed -n '/enabledPlugins/,/}/p' ~/.claude/settings.json 2>/dev/null | grep -o '"[^"]*@[^"]*"' | tr -d '"' | tr '\n' ' ')"
echo "plugin dell'account, sincronizzati: $(cat ~/.claude/plugins/synced/*/manifest.json 2>/dev/null | grep -o '"name": *"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' | sort | tr '\n' ' ')"

sezione "Scritture durante questa misura, nei posti misurati"
# ⛔ Se non è 0, la misura ha cambiato qualcosa (o qualcun altro, nello stesso
# momento, ha lavorato su quel posto): i file sono nominati, e si guarda chi.
# ⚠️ ~/.claude non c'è apposta: Claude Code ci scrive mentre lavora.
SCRITTI=$(find "$BREW" ~/Library/Caches/Homebrew ~/.rbenv ~/.aimonx-web-tools \
  ~/Library/Caches/ms-playwright ~/.npm ~/.config/gh ~/.local/state/gh ~/.gitconfig \
  ${APP_DIR:+"$APP_DIR/.git"} -newer "$SEGNO" 2>/dev/null | corto | sort)
echo "file scritti: $(printf '%s' "$SCRITTI" | grep -c .)"
[ -n "$SCRITTI" ] && printf '%s\n' "$SCRITTI" | sed 's/^/  /'
exit 0
