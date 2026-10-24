## Intention
<ce qui doit être fait et pourquoi — 5 lignes maximum, en langage humain ; entrée ou décision du journal (P.xx) touchée, le cas échéant>

## Réalisation
<ce qui a été fait — 3 lignes maximum>

## Périmètre
<chemin exact de chaque fichier modifié, un par ligne. C'est le contrat de coordination
du travail parallèle : un périmètre qui recoupe celui d'une PR ouverte doit être résolu
avant l'ouverture. Si docs/journal-evolutions.md est touché : déclarer chaque identifiant
créé ou modifié (ex. P.5), avec la branche de réservation reservations/P.<n> posée au
préalable (verrou de ref Git, voir CONTRIBUTING.md). Si docs/backlog.md est touché :
citer les items concernés (ex. backlog 2.3).>

## Ce que l'agent a fait / ce que l'humain a changé
- Agent : <parties générées, et comment elles ont été vérifiées — ou « pas d'IA utilisée »>
- Humain : <modifications, rejets, arbitrages faits après génération>

## Vérifications de l'agent (résultats consignés, pas des cases cochées à vide)
- [ ] Cohérence avec le plan de bataille et le journal : identifiants P.xx concernés cités, passages en cause rappelés — ou « sans objet » motivé
- [ ] Backlog vivant : toute ligne traitée/débloquée/annulée par cette PR est mise à jour dans le même commit (statut, PR, sha, date)
- [ ] Statuts honnêtes : « spécifié, jamais exécuté » préservé ; passage à « exécuté » accompagné des journaux ou références
- [ ] Aucun secret dans le diff (passe de lecture, en plus des contrôles automatiques)
- [ ] Branche rebasée sur `main` à jour ; périmètre sans recouplement avec une PR ouverte ; réservation P.xx posée si le journal est touché

## Vérifications humaines (ce que l'agent ne peut pas faire à sa place)
- [ ] L'auteur a relu le diff en entier avant d'ouvrir la PR — il en engage sa responsabilité (trailer `Relu-par-humain`)
- [ ] L'intention et les arbitrages ont été validés par un humain ; la décision de fusion revient au relecteur humain
