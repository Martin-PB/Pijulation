#!/usr/bin/env bash
# Run TLC against the provenance model and its three intentional fault injections.
# Safe to run from any directory inside a checkout. Does not modify model sources.
set -uo pipefail

SCRIPT_NAME="validate-provenance-tla"
MODEL_DIR="formal/provenance"
LOG_DIR="${TLA_LOG_DIR:-$HOME/pijulation-tla-logs/$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$LOG_DIR" || { echo "ERREUR: impossible de créer $LOG_DIR"; exit 2; }

finish() {
  local rc=$?
  echo
  echo "===== FIN DE VALIDATION : code $rc ====="
  echo "Journaux : $LOG_DIR"
  if [[ -t 0 ]]; then
    read -r -p "Appuie sur Entrée pour fermer ce rapport..." _ || true
  fi
  exit "$rc"
}
trap finish EXIT

say() { printf '\n===== %s =====\n' "$*"; }

# Find the checkout from the current directory or this script's own location.
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
elif [[ -d "$(dirname "$0")/../../.git" ]]; then
  REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
else
  echo "ERREUR: lance ce script depuis un clone Git de Pijulation."
  echo "Exemple: cd ~/Pijulation && bash formal/provenance/run-tlc.sh"
  exit 2
fi
cd "$REPO_ROOT" || exit 2

say "Dépôt et état Git"
printf 'Dépôt : %s\n' "$REPO_ROOT"
git status --short --branch 2>&1 | tee "$LOG_DIR/git-status.log"
printf 'Branche : '; git branch --show-current 2>/dev/null || true

say "Vérification des fichiers du modèle"
required=(
  "$MODEL_DIR/Provenance.tla" "$MODEL_DIR/Provenance.cfg"
  "$MODEL_DIR/ProvenanceBypass.tla" "$MODEL_DIR/ProvenanceBypass.cfg"
  "$MODEL_DIR/ProvenancePayloadTamper.tla" "$MODEL_DIR/ProvenancePayloadTamper.cfg"
  "$MODEL_DIR/ProvenancePayloadOverwrite.tla" "$MODEL_DIR/ProvenancePayloadOverwrite.cfg"
)
missing=0
for f in "${required[@]}"; do
  if [[ -s "$f" ]]; then printf 'OK      %s\n' "$f"; else printf 'MANQUANT %s\n' "$f"; missing=1; fi
done
if (( missing )); then echo "FAIL: des fichiers requis sont absents."; exit 2; fi

say "Java et TLC"
if ! command -v java >/dev/null 2>&1; then
  echo "NON EXÉCUTÉ: Java n'est pas installé. Installe un JDK/JRE puis relance."
  exit 2
fi
java -version 2>&1 | tee "$LOG_DIR/java-version.log"

TLC_JAR="${TLA2TOOLS_JAR:-}"
if [[ -z "$TLC_JAR" ]]; then
  for candidate in \
    "$REPO_ROOT/tla2tools.jar" \
    "$REPO_ROOT/.tools/tla2tools.jar" \
    "$HOME/.local/share/tlaplus/tla2tools.jar" \
    "$HOME/tla2tools.jar" \
    "/usr/share/java/tla2tools.jar"; do
    if [[ -s "$candidate" ]]; then TLC_JAR="$candidate"; break; fi
  done
fi

if [[ -z "$TLC_JAR" || ! -s "$TLC_JAR" ]]; then
  if command -v curl >/dev/null 2>&1; then
    say "TLC absent : tentative de téléchargement officiel"
    mkdir -p "$HOME/.local/share/tlaplus" || exit 2
    tmp="$HOME/.local/share/tlaplus/tla2tools.jar.tmp"
    if curl --fail --location --connect-timeout 10 --max-time 120 \
      https://github.com/tlaplus/tlaplus/releases/latest/download/tla2tools.jar \
      --output "$tmp" 2>&1 | tee "$LOG_DIR/tlc-download.log"; then
      if [[ -s "$tmp" ]] && java -cp "$tmp" tlc2.TLC -help >/dev/null 2>&1; then
        mv "$tmp" "$HOME/.local/share/tlaplus/tla2tools.jar"
        TLC_JAR="$HOME/.local/share/tlaplus/tla2tools.jar"
      else
        rm -f "$tmp"
      fi
    fi
  fi
fi

if [[ -z "$TLC_JAR" || ! -s "$TLC_JAR" ]]; then
  echo "NON EXÉCUTÉ: tla2tools.jar introuvable et téléchargement impossible."
  echo "Si tu as déjà le JAR, relance avec :"
  echo "TLA2TOOLS_JAR=/chemin/vers/tla2tools.jar bash formal/provenance/run-tlc.sh"
  exit 2
fi
printf 'TLC JAR : %s\n' "$TLC_JAR"
if ! java -cp "$TLC_JAR" tlc2.TLC -help >/dev/null 2>&1; then
  echo "FAIL: le fichier TLC n'est pas un JAR valide."
  exit 2
fi

cd "$REPO_ROOT/$MODEL_DIR" || exit 2
overall=0
run_case() {
  local label="$1" module="$2" cfg="$3" expected="$4"
  local log="$LOG_DIR/$label.log"
  local rc=0 result="FAIL"
  say "$label"
  printf 'Commande : java -cp %q tlc2.TLC -cleanup -config %q %q\n' "$TLC_JAR" "$cfg" "$module"
  java -cp "$TLC_JAR" tlc2.TLC -cleanup -config "$cfg" "$module" 2>&1 | tee "$log"
  rc=${PIPESTATUS[0]}

  if [[ "$expected" == "pass" ]]; then
    if (( rc == 0 )) && grep -Eq 'Model checking completed\. No error has been found|No error has been found' "$log"; then
      result="PASS"
    fi
  else
    # A negative test passes only if TLC reports an invariant violation,
    # not merely because the Java process failed to start or parse the module.
    if grep -Eqi 'Invariant .* is violated|Error: The behavior up to this point|invariant .* violated' "$log" &&
       grep -Eqi 'AcceptedContentRetained|NoUnreportedBypass' "$log"; then
      result="PASS — contre-exemple attendu"
    fi
  fi
  printf '%s\t%s\tcode=%s\n' "$label" "$result" "$rc" | tee -a "$LOG_DIR/summary.tsv"
  if [[ "$expected" == "pass" && "$result" != "PASS" ]]; then overall=1; fi
  if [[ "$expected" == "counterexample" && "$result" != "PASS — contre-exemple attendu" ]]; then overall=1; fi
}

printf 'CAS\tRÉSULTAT\tCODE\n' > "$LOG_DIR/summary.tsv"
run_case "01-main-model" "Provenance" "Provenance.cfg" "pass"
run_case "02-bypass-negative" "ProvenanceBypass" "ProvenanceBypass.cfg" "counterexample"
run_case "03-payload-tamper-negative" "ProvenancePayloadTamper" "ProvenancePayloadTamper.cfg" "counterexample"
run_case "04-payload-overwrite-negative" "ProvenancePayloadOverwrite" "ProvenancePayloadOverwrite.cfg" "counterexample"

say "BILAN FINAL"
cat "$LOG_DIR/summary.tsv"
echo
if (( overall == 0 )); then
  echo "RÉSULTAT : PASS — le modèle principal passe et les trois injections produisent les contre-exemples attendus."
  echo "Attention : cela valide uniquement ces modèles finis, pas l'implémentation réelle."
  exit 0
else
  echo "RÉSULTAT : FAIL — au moins un résultat est inattendu ou TLC n'a pas terminé correctement."
  echo "Consulte les journaux ci-dessus et le dossier $LOG_DIR."
  exit 1
fi
