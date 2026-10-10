# Football Quiz – fiche App Store (v1.0)

## Nom (30 max)
Football Quiz – Culture Foot

(« Football Quiz » seul était déjà pris. Sous l'icône, l'app reste « Football Quiz ».)

## Sous-titre (30 max)
Clubs, Coupe du monde et CAN

## Texte promotionnel (170 max, modifiable sans nouvelle version)
Plus de 4 000 questions sur le foot, des clubs aux Coupes du monde. Débloque les pays de l'Aventure un par un et grimpe au classement Game Center !

## Mots-clés (100 max, séparés par des virgules, sans espace)
trivia,questions,afrique,ballon,joueurs,sport,jeu,mondial,ligue,europe,défi,histoire,buteur,match

(Les mots du nom et du sous-titre – football, quiz, culture, foot, clubs, coupe du monde, CAN – sont déjà pris en compte par la recherche : inutile de les répéter.)

## Description (4 000 max)
Tu penses tout savoir sur le foot ? Prouve-le !

Football Quiz réunit plus de 4 000 questions sur le football : l'histoire des grands clubs, les Coupes du monde, la Coupe d'Afrique des nations et toute la culture foot, des années 1990 à aujourd'hui.

SPÉCIAL FOOT
100 questions, 3 vies, 5 niveaux de difficulté. Réponds vite pour marquer plus de points.

HARDCORE
Une seule vie, uniquement des questions Expert et Légende, et ça ne s'arrête jamais. Joue sur tout le foot ou choisis un pays : France, Espagne, Royaume-Uni, Allemagne, Italie, Coupe du monde ou CAN. Chaque mode a son propre classement.

AVENTURE
Pars de la France et parcours l'histoire de 18 clubs, de 2024 jusqu'aux années 1990, en 10 étapes chacun. Termine tous les clubs d'un pays pour débloquer le suivant : Espagne, Royaume-Uni, Allemagne, Italie, les Coupes du monde de 1978 à 2022 et les CAN de 2000 à 2025.

BADGES ET CLASSEMENTS
Gagne des badges en jouant, puis compare ton score et tes badges avec les autres joueurs grâce aux classements Game Center.

ET AUSSI
• De nouvelles questions arrivent régulièrement, sans mise à jour de l'app
• Fonctionne hors ligne
• Pas de publicité, pas de compte à créer, aucune donnée collectée

Un bug, une question fausse, une idée ? Écris-nous depuis ton profil, dans l'app.

## Catégories
Principale : Jeux › Quiz
Secondaire : Jeux › Sports

## URLs
Assistance : https://charlit.github.io/sportquiz/
Confidentialité : https://charlit.github.io/sportquiz/confidentialite.html

## Copyright
2026 Charles Jussan

## Confidentialité de l'app (App Store Connect)
Aucune donnée collectée.

## Informations pour la vérification (notes pour Apple)
Football Quiz est un quiz de football. Tout le contenu (plus de 4 000 questions, cartes, badges) est embarqué dans l'app et fonctionne hors ligne. Les classements utilisent Game Center (un classement par mode). L'app télécharge en arrière-plan la dernière liste de questions depuis GitHub (données JSON uniquement, aucun code). Aucun compte n'est nécessaire pour tester : tous les modes sont jouables directement depuis l'accueil.

## Classements Game Center (9)
App Store Connect › l'app › Services › Game Center › Classements › « + » › Classement classique. Pour chacun :
- Format du score : Entier · Type d'envoi : Meilleur score · Ordre : Du plus haut au plus bas
- Plage de scores : 0 → maximum ci-dessous (refuse les scores impossibles)
- Localisation Français : nom ci-dessous, format « Entier », suffixe « points » (singulier « point »)

| Nom de référence | Identifiant | Nom affiché (français) | Score max |
|---|---|---|---|
| Spécial Foot | sportquiz.foot | Spécial Foot | 32500 |
| Hardcore Foot | sportquiz.hardfoot | Hardcore · Tout le foot | 400000 |
| Hardcore France | sportquiz.hardfr | Hardcore · France | 400000 |
| Hardcore Espagne | sportquiz.hardes | Hardcore · Espagne | 400000 |
| Hardcore Royaume-Uni | sportquiz.harduk | Hardcore · Royaume-Uni | 400000 |
| Hardcore Allemagne | sportquiz.hardde | Hardcore · Allemagne | 400000 |
| Hardcore Italie | sportquiz.hardit | Hardcore · Italie | 400000 |
| Hardcore Coupe du monde | sportquiz.hardwc | Hardcore · Coupe du monde | 400000 |
| Hardcore CAN | sportquiz.hardcan | Hardcore · CAN | 400000 |

Les identifiants doivent être exactement ceux-ci : l'app envoie les scores à `sportquiz.<mode>`.
Les 7 autres modes connus de l'app (hard, hardrugby, hardbasket, hardtennis, hardf1, hardvelo, multi) ne sont plus jouables : inutile de les créer.

## Captures d'écran (iPhone 6,9" – 1320 × 2868)
Dans `captures/`, à envoyer dans cet ordre :
1. `1-accueil.png` – les trois modes
2. `2-question.png` – une question en cours de Spécial Foot
3. `3-aventure-carte.png` – la carte des clubs de France
4. `4-aventure-pays.png` – les pays à débloquer
5. `5-classement.png` – le classement Game Center (pseudos fictifs)
6. `6-badges.png` – les badges

Pour les refaire (après un build, pour que `SportQuizApp/Game` soit à jour) :
`mkdir -p /tmp/captures && cp scripts/screenshot-states.json /tmp/captures/states.json && swiftc -O scripts/make-screenshots.swift -o /tmp/shots && /tmp/shots SportQuizApp/Game /tmp/captures`
