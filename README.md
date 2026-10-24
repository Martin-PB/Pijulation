# Pijulation

**Pilotage de la bataille écosystème Pijul** — ce dépôt est le poste de commandement de l'effort pour amener l'écosystème Pijul au niveau de celui de Git/GitHub. Il porte le plan de bataille, le backlog vivant, le journal des évolutions et la gouvernance commune aux dépôts du chantier.

> Pourquoi Pijul : c'est un VCS dont le modèle (patchs commutables, conflits premier-class, historique immuable) résout structurellement le nouveau goulot des workflows d'agents IA en parallèle — le rebase Git casse l'audit, la commutation ne réécrit jamais rien.

## Cartographie du chantier

| Dépôt | Rôle | Phase du plan |
|---|---|---|
| **Pijulation** (ce dépôt) | Pilotage : plan, backlog, journal, gouvernance | Transverse |
| [MCP-Pijul](https://github.com/Martin-PB/MCP-Pijul) | Serveur MCP exposant Pijul aux agents (12 outils, CLI comme contrat) | Phase 3 — le pari agents IA |
| [passerelle-Git-Pijul](https://github.com/Martin-PB/passerelle-Git-Pijul) | Passerelle bidirectionnelle : fusion-as-a-service de PRs Git en conflit, résolues en Pijul (auto ou opérateur), réexportées en Git | Phase 1 — le pont, cheval de Troie |

Les deux dépôts se composent sans couplage : la passerelle expose des conflits et reçoit des changes de résolution — l'opérateur, seul ou assisté par un LLM via le MCP, est strictement la même opération pour elle.

## Documentation

- [`docs/plan-de-bataille.md`](docs/plan-de-bataille.md) — le plan complet : 5 phases, paris stratégiques, risques et parades.
- [`docs/backlog.md`](docs/backlog.md) — le backlog vivant (acteurs, priorités, dépendances, statuts).
- [`docs/journal-evolutions.md`](docs/journal-evolutions.md) — le journal des évolutions, une entrée par sujet, identifiants `P.xx`.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — gouvernance opposable : PR, relecture humaine, travail parallèle, réservation atomique des identifiants.

## Gouvernance (résumé)

Reprise de [nixos-secops-admin-agent](https://github.com/Martin-PB/nixos-secops-admin-agent) :

1. **Rien n'entre dans `main` sans PR relue par un humain.** Jamais de push direct.
2. **L'agent propose, l'humain décide.** Trailers `Agent: <nom>` + `Relu-par-humain: <auteur de la PR>` sur tout commit généré.
3. **Une PR = un sujet, pas un commit.** Un échec CI se corrige dans la même branche/PR.
4. **Le corps de PR porte l'intention ET la réalisation** (sections imposées, voir le gabarit).
5. **Réservation atomique des identifiants `P.xx`** par branche `reservations/P.<n>` (verrou de ref Git).
6. **Le backlog est vivant** : toute PR qui traite/débloque/annule un item met à jour sa ligne dans le même commit.

## Licence

MIT — voir [LICENSE](LICENSE).
