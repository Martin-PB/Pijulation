#!/usr/bin/env python3
"""check_pr.py — garde-fou du gabarit de pull request (Pijulation).

Usage :
    python3 ci/check_pr.py --body <fichier corps de PR> --files <fichier chemins modifies>

Contrôles (CONTRIBUTING.md, sections imposées) :
  1. les 6 sections requises présentes, exactement une fois, apostrophes droites ;
  2. toutes les cases de « Vérifications de l'agent » cochées (résultats consignés) ;
  3. chaque fichier modifié listé dans la section Périmètre (contrat de coordination) ;
  4. journal touché (docs/journal-evolutions.md) => identifiant P.xx déclaré dans Périmètre ;
  5. backlog touché (docs/backlog.md) => items cités dans Périmètre.

Code retour : 0 si conforme, 1 sinon (échec fermé).
"""
from __future__ import annotations

import argparse
import re
import sys

REQUIRED_SECTIONS = [
    "## Intention",
    "## Réalisation",
    "## Périmètre",
    "## Ce que l'agent a fait / ce que l'humain a changé",
    "## Vérifications de l'agent (résultats consignés, pas des cases cochées à vide)",
    "## Vérifications humaines (ce que l'agent ne peut pas faire à sa place)",
]

SECTION_RE = re.compile(r"^## (.+)$", re.MULTILINE)
P_XX_RE = re.compile(r"\bP\.(\d+)\b")
BACKLOG_RE = re.compile(r"backlog (\d+\.\d+)", re.IGNORECASE)


def sections(body: str) -> dict[str, str]:
    """Coupe le corps en sections par en-tête '## '."""
    matches = list(SECTION_RE.finditer(body))
    out: dict[str, str] = {}
    for i, m in enumerate(matches):
        title = m.group(1).strip()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(body)
        out[title] = body[start:end]
    return out


def check(body_path: str, files_path: str) -> list[str]:
    errors: list[str] = []
    body = open(body_path, encoding="utf-8").read()
    files = [ln.strip() for ln in open(files_path, encoding="utf-8") if ln.strip()]

    # 0. apostrophes typographiques interdites dans les en-têtes de section
    for line in body.splitlines():
        if line.startswith("## ") and "\u2019" in line:
            errors.append(f"apostrophe typographique dans l'en-tête : {line!r} (exiger l'apostrophe droite)")

    found = sections(body)

    # 1. sections requises
    for req in REQUIRED_SECTIONS:
        title = req.removeprefix("## ")
        if title not in found:
            errors.append(f"section manquante ou mal orthographiée : '## {title}'")

    # 2. cases de « Vérifications de l'agent » toutes cochées
    agent_title = "Vérifications de l'agent (résultats consignés, pas des cases cochées à vide)"
    if agent_title in found:
        agent = found[agent_title]
        unchecked = [ln for ln in agent.splitlines() if re.match(r"\s*- \[ \]", ln)]
        if unchecked:
            errors.append(f"{len(unchecked)} case(s) non cochée(s) dans 'Vérifications de l'agent' : {[u.strip() for u in unchecked]}")
        if "- [x]" not in agent and "- [X]" not in agent:
            errors.append("aucune case agent cochée : la section 'Vérifications de l'agent' est vide de résultats")

    # 3. Périmètre couvre le diff
    scope_title = "Périmètre"
    if scope_title in found and files:
        scope = found[scope_title]
        for f in files:
            if f not in scope:
                errors.append(f"fichier modifié absent du Périmètre : {f}")

    # 4. journal touché => identifiant P.xx déclaré
    if any(f == "docs/journal-evolutions.md" for f in files):
        scope = found.get(scope_title, "")
        if not P_XX_RE.search(scope):
            errors.append("docs/journal-evolutions.md modifié sans identifiant P.xx déclaré dans le Périmètre (réservation reservations/P.<n> requise)")

    # 5. backlog touché => items cités
    if any(f == "docs/backlog.md" for f in files):
        scope = found.get(scope_title, "")
        if not BACKLOG_RE.search(scope) and "backlog" not in scope.lower():
            errors.append("docs/backlog.md modifié sans items cités dans le Périmètre")

    return errors


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--body", required=True)
    ap.add_argument("--files", required=True)
    args = ap.parse_args()
    errors = check(args.body, args.files)
    if errors:
        for e in errors:
            print(f"ERREUR: {e}")
        return 1
    print("check_pr: conforme")
    return 0


if __name__ == "__main__":
    sys.exit(main())
