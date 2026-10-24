# Journal des évolutions

> Une entrée par sujet, identifiants `P.xx` stables. Toute décision citée dans le corpus est définie ici. Convention de maintenance : la réservation des identifiants est atomique (branche `reservations/P.<n>`, voir `CONTRIBUTING.md`) ; `ci`-garde-fous éventuels viendront en PR dédiée. L'ordre des entrées est chronologique à l'insertion, pas par tri artificiel.

### P.1 — Plan de bataille écosystème Pijul

**Date : 24/10/2026. Statut : spécifié, jamais exécuté (document de pilotage).**

Le plan stratégique 5 phases (fondations, pont Git, Nest, agents IA, communauté) est consigné dans `docs/plan-de-bataille.md`. Positionnement central : Pijul gagne sur le goulot des workflows d'agents en parallèle, pas en clonant GitHub. Le document de référence du workflow agentic est l'AI-Native SDLC Playbook (Anthropic, 2026) : la chaîne d'artefacts versionnés (intent.md → spec.md → plan.md → diff) et l'historique immuable comme piste d'audit.

### P.2 — Création du dépôt MCP-Pijul

**Date : 24/10/2026. Statut : squelette poussé, issues de roadmap ouvertes.**

Dépôt [Martin-PB/MCP-Pijul](https://github.com/Martin-PB/MCP-Pijul) : serveur MCP stdio en Rust (JSON-RPC à la main, deps minimales), 12 outils shells vers le CLI `pijul`, vocabulaire patch-native (changes/channels, conflits comme état). 5 issues de roadmap : `pijul_merge_preview` (l'outil killer), intégration Nest, mode read-only + annotations MCP, tests d'intégration, publication crates.io. Répond à la Phase 3 du plan.

### P.3 — Création du dépôt passerelle-Git-Pijul

**Date : 24/10/2026. Statut : squelette poussé, propriété d'acceptation spécifiée.**

Dépôt [Martin-PB/passerelle-Git-Pijul](https://github.com/Martin-PB/passerelle-Git-Pijul) : passerelle qui traduit des PRs Git en conflit en changes Pijul, y résout les conflits (auto par règles, ou opérateur), et réexporte en Git (`linear` / `merge-topology`). Squelette Rust : ledger SHA↔change-hash (idempotence, détection de force-push), triage à trois issues exactement (Clean / AutoResolved / Operator), frontière opérateur stricte (expose `ConflictReport`, reçoit `ResolutionChange` — le producteur, seul ou assisté par LLM via le MCP, est hors périmètre et indiscernable). Propriété d'acceptation n°1 : `export(import(x)) == x`. Répond à la Phase 1 (pont) comme démonstration de fusion-as-a-service.

### P.4 — Gouvernance adoptée pour le chantier

**Date : 24/10/2026. Statut : actif.**

Reprise du modèle de [nixos-secops-admin-agent](https://github.com/Martin-PB/nixos-secops-admin-agent) : jamais de push direct sur `main`, PR = unité de travail et de mémoire (sections imposées), trailers `Agent` / `Relu-par-humain`, une PR = un sujet (correctifs dans la même branche, jamais de `-v2`), relecture et fusion par l'humain uniquement, travail parallèle par périmètre déclaré, réservation atomique des identifiants `P.xx` par verrou de ref Git, backlog vivant dans `docs/backlog.md` avec convention de maintenance inscrite en en-tête. La frontière opérateur de la passerelle (P.3) est un sous-produit du même principe : la gouvernance ne tague pas les producteurs, elle exige des artefacts vérifiables.
