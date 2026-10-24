# Pijul for agentic SDLC — un workflow de développement piloté par agents

> Backlog 3.4. Ce guide mappe le cycle intention → spécification → plan →
> implémentation → relecture sur les primitives Pijul, et documente comment
> brancher un agent (via [mcp-server-pijul](https://github.com/Martin-PB/MCP-Pijul))
> sur un dépôt sans lui donner les moyens de détruire quoi que ce soit.
> Dépendance satisfaite : `pijul_merge_preview` (backlog 1.3) y est l'outil
> pivot.

## 1. Le modèle mental : l'intention voyage en patchs

Le cycle de travail d'un agent (humain ou LLM) se décompose naturellement :

| Étape | Artefact | Primitive Pijul | Outil MCP |
|---|---|---|---|
| Intention | `intent.md` (le pourquoi) | — (pas de VCS) | — |
| Spécification | `spec.md` (le quoi, critères) | change P.1 (doc) | `pijul_record` |
| Plan | `plan.md` (l'ordonnancement) | change P.2 (doc) | `pijul_record` |
| Implémentation | code | changes empilés | `pijul_record`, `pijul_diff` |
| Revue de fusion | aperçu sans mutation | commutation de patchs | `pijul_merge_preview` |

Deux propriétés de Pijul changent la donne par rapport à un workflow Git :

1. **La commutation** : les changes indépendants s'appliquent dans n'importe
   quel ordre. Un agent n'a pas besoin de « rebase » : les étapes du plan qui
   ne se touchent pas commutent, et le tri des conflits ne se joue qu'entre
   changes qui touchent vraiment les mêmes lignes.
2. **Le conflit est un état** : un conflit n'échoue pas la fusion ; il vit
   dans l'état du graphe et se résout en enregistrant un nouveau change. Un
   agent peut donc *montrer* un conflit (`pijul_conflict_show`) et proposer
   sa résolution (`pijul_record`) comme n'importe quelle contribution —
   jamais comme une opération hors-processus qui casse l'historique.

## 2. Le workflow, étape par étape

### 2.1 Intention — `intent.md`

Aucune machine là-dedans : l'humain écrit le pourquoi en langage libre.
Convention : le fichier vit dans un canal dédié pour ne pas polluer le canal
de production.

### 2.2 Spécification — `spec.md`

L'agent (ou l'humain) traduit l'intention en critères vérifiables. Le
fichier est enregistré comme change Pijul :

```
pijul record --message "spec: critères d'acceptation de <intention>"
```

L'intérêt : la spec est un **patch**. Elle peut être commentée, amendée,
dépliée dans un canal de revue — et surtout, elle fait partie des
dépendances du code qui l'implémente si les deux changes se suivent dans le
canal de travail.

### 2.3 Plan — `plan.md`

L'ordonnancement (quelles étapes, dans quel canal, dans quel ordre). Même
traitement : un change de documentation. Les étapes qui commutent (fichiers
disjoints) n'exigent aucun ordre — c'est le détecteur gratuit de
« plan sur-ingénierié » : si tout doit être séquentiel, c'est que tout se
touche.

### 2.4 Implémentation — empiler des changes

Par canal de travail (`pr-<n>`), l'agent enregistre un change par étape du
plan. Règles pour un agent LLM :

- **un change = un sujet** (le miroir exact de notre règle de gouvernance
  « une PR = un sujet ») ;
- les outils destructifs sont annoncés : le serveur MCP expose
  `destructiveHint` (`pijul_unrecord`) — un agent prudent les évite sauf
  instruction explicite ;
- en inspection (revue, veille), l'agent tourne sous
  `PIJUL_MCP_READONLY=1` : les 7 outils mutants sont refusés **avant tout
  spawn pijul**, donc même une hallucination d'agent ne mute rien.

### 2.5 Revue de fusion — l'outil pivot : `pijul_merge_preview`

Le moment dangereux d'un workflow agent est la fusion : c'est là qu'un
agent pressé écrase le travail d'un autre. Le protocole :

1. **Aperçu sans mutation** : `pijul_merge_preview {source, target}` liste
   les changes à fusionner, ordre d'application compris, sans toucher au
   dépôt.
2. **Décision humaine** : l'aperçu est lisible par un humain (comptes par
   catégorie, hashes oldest-first) ; la fusion n'est jamais exécutée par
   l'agent tant que l'humain n'a pas dit go (ou que l'arbitrage a été
   délégué explicitement).
3. **Fusion contrôlée** : `apply=true` effectue la fusion via
   `pijul apply --channel` — les dépendances suivent, les conflits deviennent
   un état visible par `pijul_conflict_show`.
4. **Résolution comme contribution** : la résolution d'un conflit est un
   change ordinaire, relisible, révocable par unrecord si nécessaire (et
   signalé destructif).

## 3. Frontières de confiance (lecture pour les opérateurs)

- **Mode read-only** : inspection sans risque, y compris pour des agents
  tierces (`PIJUL_MCP_READONLY`).
- **Hints d'annotations** : le client agent lit `readOnlyHint` /
  `destructiveHint` / `openWorldHint` pour auto-modérer ses appels —
  `pijul_push`/`pijul_pull` annoncent `openWorldHint` (remotes).
- **Un change = un sujet** : la relecture humaine reste atomique ; un
  correctif suit le même change/la même PR, jamais un « -v2 » parallèle.
- **Trailers d'agent** : tout change généré par un agent porte ses trailers
  (`Agent:`, `Relu-par-humain:`) dans le message — auditable dans
  `pijul log`.

## 4. Anti-patterns (ce que ce workflow interdit)

- **Rebase comme outil de rangement** : inutile et toxique — les changes
  commutent ; ranger l'historique détruit l'auditabilité des revues déjà
  faites.
- **Conflits résolus « à l'aveugle »** : une résolution non relue est un
  change non relu ; le conflit est visible précisément pour exiger une
  relecture.
- **Agent avec droits d'écriture sur le canal de production** : les agents
  travaillent dans des canaux dédiés ; la fusion vers le canal cible passe
  par l'aperçu (2.5).
- **Historique réécrit pour « faire propre »** : la propreté vient du
  découpage (un change = un sujet), jamais de la réécriture.
