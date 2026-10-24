# AGENTS.md

Instructions pour les agents de codage travaillant sur ce dépôt. La gouvernance
détaillée est dans `CONTRIBUTING.md` — ce fichier ne la duplique pas : il donne
à l'agent ce qu'il doit savoir AVANT son premier commit. L'opérateur relit et
fusionne toujours ; l'agent ne fusionne jamais ses propres PR.

## Ce qu'est ce dépôt

Le poste de commandement du chantier « écosystème Pijul » : plan de bataille
(`docs/plan-de-bataille.md`), backlog vivant (`docs/backlog.md`), journal des
évolutions (`docs/journal-evolutions.md`, identifiants `P.xx`), gouvernance
commune. Les dépôts d'implémentation sont [MCP-Pijul](https://github.com/Martin-PB/MCP-Pijul)
(Phase 3 — agents IA) et [passerelle-Git-Pijul](https://github.com/Martin-PB/passerelle-Git-Pijul)
(Phase 1 — pont Git). Les contributions à l'upstream Pijul (pijul/pijul, pijul/nest)
se préparent ici (spec, benchmark, retour d'usage) et se proposent là-bas
selon leurs règles propres (le Nest peut refuser les patchs générés par LLM —
toujours le signaler à l'opérateur avant d'en proposer un).

## Commandes de vérification (avant toute PR)

- Dépôt documentaire : relecture humaine + vérification des liens internes ;
  les garde-fous automatiques (lint markdown, contrôle du gabarit de PR)
  arriveront en PR dédiée — ne pas cocher un contrôle non exécuté.
- Pour les dépôts d'implémentation : voir leur CONTRIBUTING à eux (tests
  `cargo test`, round-trip pour la passerelle).

## Workflow de pull request

- Jamais de push direct sur `main`. Branche : `mp-<slug>`. Une PR porte UN
  sujet (pas un commit) : un échec ou une correction se pousse dans la MÊME
  branche/PR, jamais de branche `-v2` ni de PR de remplacement.
- Corps de PR : sections EXACTES du gabarit (apostrophes droites). Toutes les
  cases de « Vérifications de l'agent » cochées avec résultats consignés.
- Entrée du journal (`P.xx`) : réservation atomique AVANT rédaction (branche
  `reservations/P.<n>` sur `main` — la création de ref est le verrou ; si elle
  échoue, l'identifiant est pris). La branche de réservation ne reçoit jamais
  de commit.
- Backlog : toute PR qui traite/débloque/annule un item met à jour sa ligne
  dans `docs/backlog.md` dans le même commit.
- Trailers de commit : `Agent: <nom>` + `Relu-par-humain: Martin Pruvost-Beaurain`.
- L'agent ne fusionne jamais ; l'opérateur relit, valide localement si
  pertinent, et fusionne.

## Pièges éprouvés (transmis depuis nixos-secops-admin-agent)

- L'API de contenu GitHub ne pose pas le bit exécutable (mode 100644) : les
  scripts s'invoquent via `bash <script>`.
- Le connecteur GitHub ne sait pas supprimer une branche : le ménage des
  branches `reservations/*` et des branches fusionnées est un geste
  opérateur, à rappeler dans « Vérifications humaines ».
- Après chaque push, relire le fichier depuis la branche (protocole
  anti-mojibake) : accents intacts, aucun U+FFFD, aucun CR parasite.
- Les apostrophes des en-têtes de section de PR sont DROITES (') — une
  apostrophe typographique (’) casse les garde-fous futurs.
- Toute PR fermée sans fusion : lire son commentaire de fermeture avant de
  conclure quoi que ce soit sur son contenu.
