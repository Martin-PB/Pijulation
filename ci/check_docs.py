#!/usr/bin/env python3
"""check_docs.py — garde-fous du journal des évolutions (Pijulation).

Usage :
    python3 ci/check_docs.py docs/journal-evolutions.md

Contrôles :
  1. aucun doublon d'identifiant `### P.<n>` ;
  2. aucun trou de numérotation (le prochain identifiant libre = max + 1) ;
  3. toute référence `P.<n>` citée dans le corps a un en-tête cible.

Leçons retenues du modèle d'origine : n'exiger NI l'ordre croissant des
entrées dans le document (insertions historiques légitimes) NI un
démarrage à P.1 — seulement l'unicité et la continuité.

Code retour : 0 si conforme, 1 sinon (échec fermé).
"""
from __future__ import annotations

import argparse
import re
import sys

HEADING_RE = re.compile(r"^### P\.(\d+)\b")
REF_RE = re.compile(r"\bP\.(\d+)\b")


def check(journal_path: str) -> list[str]:
    errors: list[str] = []
    lines = open(journal_path, encoding="utf-8").read().splitlines()
    headings: dict[int, int] = {}  # numéro -> ligne
    seen: set[int] = set()

    for i, line in enumerate(lines, 1):
        m = HEADING_RE.match(line)
        if not m:
            continue
        n = int(m.group(1))
        if n in seen:
            errors.append(f"doublon d'identifiant P.{n} (l.{headings[n]} et l.{i})")
        else:
            seen.add(n)
            headings[n] = i

    if not seen:
        errors.append("aucun identifiant P.<n> trouvé dans le journal")
    else:
        mx, mn = max(seen), min(seen)
        holes = sorted(set(range(mn, mx + 1)) - seen)
        if holes:
            errors.append(f"trous de numérotation : {', '.join(f'P.{h}' for h in holes)}")
        print(f"check_docs: {len(seen)} entrées ({mn}..{mx}), prochain identifiant libre : P.{mx + 1}")

    # toute référence P.<n> citée dans le corps a un en-tête cible
    for i, line in enumerate(lines, 1):
        if HEADING_RE.match(line):
            continue
        for m in REF_RE.finditer(line):
            n = int(m.group(1))
            if n not in seen:
                errors.append(f"l.{i}: référence à P.{n} sans en-tête '### P.{n}' dans le journal")

    return errors


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("journal", nargs="+")
    args = ap.parse_args()
    errors: list[str] = []
    for j in args.journal:
        errors.extend(check(j))
    if errors:
        for e in errors:
            print(f"ERREUR: {e}")
        return 1
    print("check_docs: conforme")
    return 0


if __name__ == "__main__":
    sys.exit(main())
