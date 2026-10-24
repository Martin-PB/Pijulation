#!/usr/bin/env python3
"""selftest.py — autotests des contrôleurs de Pijulation.

Exécute check_pr et check_docs sur des corpus de test (fixtures in-line) et
vérifie qu'ils échouent sur les non-conformités et passent sur les corpus
conformes. Un contrôleur qui ne peut pas être testé n'est pas un garde-fou.

Code retour : 0 si tous les cas passent, 1 sinon.
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

CONFORME_PR = """## Intention
Ajouter le garde-fou X parce que Y.

## Réalisation
check_pr.py + workflow.

## Périmètre
ci/check_pr.py
.github/workflows/static-checks.yml
docs/backlog.md
backlog 3.1 (ligne mise à jour : En cours)

## Ce que l'agent a fait / ce que l'humain a changé
- Agent : contrôleur écrit, cas de test passés.
- Humain : à valider.

## Vérifications de l'agent (résultats consignés, pas des cases cochées à vide)
- [x] selftest exécuté : PASS
- [x] aucun secret dans le diff

## Vérifications humaines (ce que l'agent ne peut pas faire à sa place)
- [ ] relecture du diff par l'auteur
"""

NON_CONFORME_PR = """## Intention
Texte.

## Réalisation
Texte.

## Périmètre
rien de listé

## Ce que l'agent a fait / ce que l'humain a changé
- Agent : tout.
- Humain : rien.

## Vérifications de l'agent (résultats consignés, pas des cases cochées à vide)
- [ ] une case non cochée

## Vérifications humaines (ce que l'agent ne peut pas faire à sa place)
- [ ] relecture
"""

JOURNAL_CONFORME = """# Journal des évolutions

### P.1 — Premier
Corps citant P.1 lui-même.

### P.2 — Deuxième
Suit P.1.
"""

JOURNAL_NON_CONFORME = """# Journal

### P.1 — Premier
### P.1 — Doublon
Référence à P.3 sans cible.
"""


def run(script: str, *args: str) -> int:
    return subprocess.run(
        [sys.executable, script, *args], capture_output=True, text=True
    ).returncode


def main() -> int:
    tmp = Path(tempfile.mkdtemp())
    ok = True

    body_c = tmp / "body_ok.md"
    body_n = tmp / "body_nok.md"
    files = tmp / "files.txt"
    body_c.write_text(CONFORME_PR, encoding="utf-8")
    body_n.write_text(NON_CONFORME_PR, encoding="utf-8")
    files.write_text(
        "ci/check_pr.py\n.github/workflows/static-checks.yml\ndocs/backlog.md\n",
        encoding="utf-8",
    )

    # check_pr : conforme
    if run("ci/check_pr.py", "--body", str(body_c), "--files", str(files)) != 0:
        print("FAIL: check_pr doit passer sur le corpus conforme")
        ok = False
    # check_pr : non-conformités détectées (case non cochée + fichiers hors Périmètre)
    if run("ci/check_pr.py", "--body", str(body_n), "--files", str(files)) == 0:
        print("FAIL: check_pr doit échouer sur le corpus non conforme")
        ok = False

    jc = tmp / "journal_ok.md"
    jn = tmp / "journal_nok.md"
    jc.write_text(JOURNAL_CONFORME, encoding="utf-8")
    jn.write_text(JOURNAL_NON_CONFORME, encoding="utf-8")

    if run("ci/check_docs.py", str(jc)) != 0:
        print("FAIL: check_docs doit passer sur le journal conforme")
        ok = False
    if run("ci/check_docs.py", str(jn)) == 0:
        print("FAIL: check_docs doit échouer sur le journal non conforme")
        ok = False

    print("selftest: PASS" if ok else "selftest: FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
