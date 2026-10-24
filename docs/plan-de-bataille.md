# Plan de bataille : amener l'écosystème Pijul au niveau de GitHub

**Objectif :** non pas cloner GitHub, mais rendre Pijul **adoptable par une équipe de production** avec le même niveau d'outillage que l'écosystème Git/GitHub (hébergement, review, CI, agents, gouvernance, migration).

**Positionnement :** Pijul ne gagne pas en copiant GitHub feature-par-feature. Il gagne en étant le seul VCS dont le modèle (patchs commutables, conflits premier-class, historique immuable) résout nativement le nouveau goulot : les workflows d'agents IA en parallèle (cf. AI-Native SDLC Playbook, Anthropic, 2026).

Ce document est la référence stratégique du chantier ; les items opérationnels vivent dans [`backlog.md`](backlog.md), l'historique des décisions dans [`journal-evolutions.md`](journal-evolutions.md).

## État des lieux (octobre 2026)

| Domaine | Git/GitHub | Pijul |
|---|---|---|
| VCS cœur | Mature, ubiquitous | ~1.0 beta, fuzzer récent, bugs `unrecord` corrigés, perfs à polir |
| Hébergement | GitHub/GitLab/Forgejo, écosystème massif | **Nest** (AGPL, PostgreSQL, NLnet/NGI Zero), avec discussions et jobs |
| Review | PRs, code review outillé | Discussions au niveau change, pas d'équivalent PR complet |
| CI | GitHub Actions, standard de facto | CI-ROADMAP en cours sur Nest, embryonnaire |
| Interop | Standard | Import Git existant (rejeu d'historique), pas de pont bidirectionnel |
| Agents IA | Support natif de tous les outils | **[MCP-Pijul](https://github.com/Martin-PB/MCP-Pijul) créé dans ce chantier** |
| Communauté | Millions de dévs | Petit noyau, forum Discourse actif, package Cloudron |

## Phase 0 — Fondations : crédibilité technique (0–6 mois)

**Principe : personne ne migre vers un VCS qui peut corrompre un dépôt.**

1. Sortir de la beta : verrouiller le format de dépôt, checksums systématiques, fuzzer en CI permanent.
2. Benchmarks publics et reproductibles vs Git (monorepo, fusions N branches, partial clones) — publier aussi les défaites.
3. Corpus de merges réels Git où le 3-way merge se trompe, rejoués sous Pijul : l'argument massue, chiffré.
4. Performance « pas gênant » sur des dépôts de 100k fichiers.
5. Packaging trivial (Homebrew/apt/dnf/MSI).

**Critère de sortie :** un dépôt privé de 5 développeurs tourne 6 mois en Pijul sans incident ni envie de revenir.

**Acteur principal :** upstream Pijul. Notre chantier suit, documente, benchmark et fournit des retours d'usage.

## Phase 1 — L'interopérabilité Git : la rampe d'accès (6–18 mois)

**Principe : nul ne migre par grand saut.**

1. `pijul git sync` bidirectionnel de qualité production.
2. Miroir transparent : un projet hébergé en Pijul consommé par le monde Git sans friction.
3. Protocole documenté (smart HTTP) pour les outilleurs.
4. Stratégie de sortie de secours documentée (revenir à Git sans perte).

**Critère de sortie :** une équipe adopte Pijul pour un nouveau projet tout en gardant reviewers, CI et clients sur Git.

**Acteur principal : ce chantier — [passerelle-Git-Pijul](https://github.com/Martin-PB/passerelle-Git-Pijul)**, qui en est la démonstration : la fusion-as-a-service de PRs Git en conflit. Propriété d'acceptation n°1 : `export(import(x)) == x`.

## Phase 2 — Nest : le GitHub de Pijul (12–30 mois)

**Principe : cloner le parcours GitHub, amplifier le différentiateur patch.**

1. Review au niveau patch (l'anti-PR) — incopiable par GitHub sans réécrire Git.
2. Fusion sans douleur en un clic : la démo « merge de deux agents en parallèle sans rebase » comme première page du produit.
3. CI type Actions avec cache par patch commuté (avantage structurel sur GitHub).
4. Ops de production : multi-tenant, backup, SSO, private repos, HA.
5. Fédération / self-hosting de première classe (l'anti-lock-in), assistant d'import GitHub.

**Critère de sortie :** le parcours « repo → push → PR équivalente → CI verte → review → merge » ne demande aucun manuel.

**Acteur principal :** upstream Nest. Le chantier fournit specs et retours ; la passerelle et le MCP consommeront l'API Nest (item backlog `nest_list_changes` etc.).

## Phase 3 — Le pari des agents IA (12–36 mois, en parallèle)

**Principe : le workflow agentic est le seul moment où le modèle Git montre publiquement ses limites et où les équipes réévaluent leurs fondations.**

1. Guide « Pijul for agentic SDLC » : les artefacts du playbook (intent.md → spec.md → plan.md → diff) mappés sur des patchs ; historique immuable = piste d'audit réelle.
2. Adaptateurs agents : **MCP server (fait)**, wrapper compatible muscle-memory Git.
3. Benchmark public : N agents en parallèle — Git (fusions manuelles, rebases, échecs) vs Pijul (fusions automatiques, conflits comme états).
4. CI « conflit-first » : un conflit versionné ne bloque pas le pipeline.
5. Early adopters : équipes agent-native, monorepos, release branches multiples.

**Critère de sortie :** au moins une équipe de production référence « nous utilisons Pijul parce que nos agents se marchent dessus ».

**Acteur principal : ce chantier — [MCP-Pijul](https://github.com/Martin-PB/MCP-Pijul)** (12 outils, roadmap : merge_preview, Nest, read-only, tests, crates.io).

## Phase 4 — Communauté, gouvernance et financement (continu)

1. Bus factor : 3–5 contributeurs cœur financés (NLnet etc.) sur des modules nommés.
2. Roadmap publique du projet upstream.
3. Nourrir la pyramide : tutoriels, « learn Pijul in 15 minutes », docs de migration par profil.
4. Présence conférences (FOSDEM), showcases de pilotes.
5. Modèle économique : Nest OSS gratuit + hébergement payant + support entreprise.
6. Fédérer plutôt qu'assiéger : un plugin Pijul pour Forgejo toucherait des millions d'utilisateurs plus vite qu'un Nest seul.

**Acteur principal :** upstream + communauté. Ce chantier documente, contribue, et pilote.

## Les 5 paris stratégiques

1. **La crédibilité avant les features.** Un VCS qui a eu des crashs passés doit prouver la robustesse d'abord.
2. **Le pont Git est non négociable.** Sans bidirectionnalité de qualité, Pijul reste un ghetto.
3. **Ne pas cloner GitHub : amplifier les patchs.** Review par patch et fusion commutative sont incopiables.
4. **Les agents IA sont la vague à surfer.** Les merge queues intelligentes (Graphite & co) sont déjà une émulation de patchs — le dire, et montrer la version native.
5. **Fédérer plutôt qu'assiéger.** Attaquer via Forgejo et l'interop bat la conquête frontale.

## Risques majeurs et parades

| Risque | Parade |
|---|---|
| Perf insuffisante sur monorepos | Phase 0 benchmarkée ; partial clones comme argument massue |
| Bus factor du mainteneur principal | Financement de contributeurs cœur (Phase 4) |
| GitHub « absorbe » les features clés (mergequeue, stacking) | Le stacking est déjà une émulation de patchs — documenter la version native |
| Indifférence des éditeurs/agents | MCP server (fait) + wrapper Git-compatible : adoption sans attendre les éditeurs |
| Espace mental « pas un autre VCS » | Positionner uniquement sur la douleur merge/rebase/audit, jamais « plus propre que Git » |
