# Backlog vivant du chantier Pijulation

> **Document de pilotage vivant**, hors journal (`P.xx`). Convention de maintenance : toute PR qui traite, débloque ou annule un item **met à jour sa ligne dans le même commit** (statut, n° PR, sha, date). Un résultat n'est PASS que réellement exécuté et réussi : distinguer **PASS** / **FAIL** / **NOT RUN**. Les dépôts d'implémentation (MCP-Pijul, passerelle-Git-Pijul) ont leurs propres issues ; ce backlog est la vue consolidée et les arbitrages.
>
> Légende acteurs : 🧑 opérateur humain · 🤖 agent · ⚙️ upstream Pijul (hors de notre contrôle direct). Priorités P0 (bloquant) → P3 (plus tard). Statuts : À faire / En cours / En attente d'arbitrage / Bloqué (condition) / Sur demande / Fait (réf.).

## 1. Dépôt MCP-Pijul — Phase 3 du plan

| Item | Acteur | Prio | Dépend de | Statut |
|---|---|---|---|---|
| 1.1 Intégration continue : GitHub Actions + pijul dans le runner | 🤖 | P1 | rien | Fait (intégré sur main MCP-Pijul le 24/10/2026 ; exécution CI NOT RUN — crédits GitHub Actions épuisés, à relancer) |
| 1.2 Tests d'intégration sur dépôts générés (hermétiques, pas de réseau) | 🤖 | P1 | 1.1 | Fait (intégré sur main MCP-Pijul le 24/10/2026 ; exécution NOT RUN — crédits Actions) |
| 1.3 `pijul_merge_preview` : preview de commutation et conflits restants SANS toucher au working copy | 🤖 | P1 | 1.2 (harnas) | En cours (branche `mp-merge-preview`, [PR #8](https://github.com/Martin-PB/MCP-Pijul/pull/8) ouverte le 24/10/2026) — **l'outil killer** |
| 1.4 Mode read-only + annotations `readOnlyHint`/`destructiveHint` | 🤖 | P2 | rien | Fait (garde `PIJUL_MCP_READONLY` intégrée sur main MCP-Pijul le 24/10/2026 ; exécution NOT RUN — crédits Actions ; annotations hints non couvertes, à suivre) |
| 1.5 Intégration Nest : API du Nest à investiguer, puis `nest_list_changes` etc. | 🤖 | P2 | dispo API Nest (⚙️) | Bloqué (API Nest non documentée publiquement) |
| 1.6 Publication crates.io + registre MCP officiel | 🧑+🤖 | P2 | 1.2 vert, tag v0.1.0 | À faire |

## 2. Dépôt passerelle-Git-Pijul — Phase 1 du plan

| Item | Acteur | Prio | Dépend de | Statut |
|---|---|---|---|---|
| 2.1 Harnas P0 : round-trip `export(import(x)) == x` sur corpus synthétique de dépôts tests (3 branches en conflit) | 🤖 | P0 | rien | À faire — corpus synthétique uniquement (arbitrage 5.1 tranché) ; **critère de survie du projet** |
| 2.2 Traduction aller réelle : `pijul git` par ref, channel `pr-<n>`, base = branche cible | 🤖 | P0 | 2.1 | En cours — première tranche d'ingest (miroir bare, refs épinglées, contrôle du SHA attendu) dans [passerelle PR #4](https://github.com/Martin-PB/passerelle-Git-Pijul/pull/4), head `14b4e3a5ee9a2738a6fef24fb645f23841084d2b` ; tests écrits mais NOT RUN ; traduction Pijul et channels nommés encore à faire |
| 2.3 Export réel : mode `linear` (commit par change, ordre des dépendances, auteurs préservés) | 🤖 | P0 | 2.1 | À faire |
| 2.4 Export mode `merge-topology` (un merge commit par PR) | 🤖 | P1 | 2.3 | À faire |
| 2.5 Règles d'auto-résolution (SameContent, CanonicalFormatting, sémantique union/ours) | 🤖 | P1 | 2.2 | À faire |
| 2.6 File opérateur persistante + CLI interactif (`operator queue`/`submit`) | 🤖 | P2 | 2.5 | À faire |
| 2.7 Gestion force-push : invalidation du channel `pr-<n>` sur événement `synchronize` | 🤖 | P2 | 2.6 | À faire |
| 2.8 Benchmark public : N PRs en conflit, merge queue Git vs passerelle (fusions manuelles vs auto) | 🧑+🤖 | P2 | 2.1–2.5 | À faire — **la démo de référence** |

## 3. Pijulation (ce dépôt) — transverse

| Item | Acteur | Prio | Dépend de | Statut |
|---|---|---|---|---|
| 3.1 Garde-fous automatiques : contrôle du gabarit de PR (check_pr.py) + workflow static-checks | 🤖 | P2 | rien | Fait (fusionné le 24/10/2026, PR #1 ; exécution du workflow NOT RUN — crédits Actions) |
| 3.2 Contrôle anti-collision `P.xx` (doublons/trous du journal) en CI | 🤖 | P2 | 3.1 | Fait (fusionné le 24/10/2026 avec la PR #1 ; exécution NOT RUN — crédits Actions) |
| 3.3 Protection de branche `main` : PR obligatoire, 1 approbation, pas de force-push | 🧑 | P0 | rien | À faire (réglage GitHub, geste opérateur) |
| 3.4 Guide « Pijul for agentic SDLC » : mapping intent.md→spec.md→plan.md→diff sur patchs | 🤖 | P3 | 1.3 | À faire |
| 3.5 Veille upstream : releases Pijul/Nest, roadmap publique, Forgejo (fédération Phase 4) | 🤖 | P3 | rien | Continu |

## 4. Upstream (⚙️) — suivi, hors de notre contrôle

| Item | Acteur | Prio | Statut |
|---|---|---|---|
| 4.1 Sortie de beta + format de dépôt verrouillé (Phase 0) | ⚙️ | — | À suivre ; nous fournissons retours d'usage + bugs via forum/Discourse |
| 4.2 CI du Nest (CI-ROADMAP) + API publique | ⚙️ | — | Bloque 1.5 ; à investiguer en premier pour débloquer |
| 4.3 Bus factor / financement contributeurs cœur (Phase 4) | ⚙️🧑 | — | À suivre |

## 5. Arbitrages en attente (opérateur)

- 5.1 Portée du corpus de tests round-trip : **tranché le 24/10/2026 — A, dépôts synthétiques uniquement pour P0**. Les dépôts réels éventuels relèveront d'une extension ultérieure, hors du critère initial d'acceptation.
- 5.2 Benchmark 2.8 : public dès les premiers chiffres, ou après stabilisation ? (risque de sur-promesse vs visibilité du chantier).
- 5.3 Contribution des deux dépôts à l'upstream (mention, fork communautaire, organisation dédiée) : sur demande explicite uniquement, comme la règle fork→orga du modèle d'origine.

## 6. Ménage / hygiène

- Branches `reservations/P.<n>` : à supprimer après fusion (geste 🧑, le connecteur agent ne sait pas supprimer une branche).
- À chaque fusion : vérifier qu'aucune PR ouverte ne devient obsolète (dépendances 1.x/2.x ci-dessus).
