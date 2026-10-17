# Prochaine version : textes pour App Store Connect

Prêts à coller (ou à envoyer par l'API) au moment de soumettre la version suivante.
Règle 2.3.1(a) : chaque fonction doit être décrite précisément dans les notes pour le vérificateur.
À relire avant l'envoi : retirer ce qui n'est pas dans le build envoyé, ajouter ce qui a été fait depuis.

## Notes pour le vérificateur (App Review Information › Notes, en anglais, 4 000 caractères max)

```
1. What the app is
Football Quiz is a French-language football trivia game for French-speaking fans of all ages: more than 4,000 multiple-choice questions on club history and football culture, with increasing difficulty, a timer and points. No account, no login, no user-generated content, no in-app purchases, no ads, no data collected.

2. Every feature and how to reach it (all from the home screen, no setup)
- "Spécial Foot": 100 questions, 3 lives, Game Center leaderboard.
- "Hardcore": "Tout le foot" or one country; one wrong answer ends the game; one leaderboard each.
- "Aventure": pick France, then a club on the map; 10 stages per club; finishing every French club unlocks the choice of the next country.
- "Défi de la semaine" (weekly challenge): every Monday, 10 questions about one football personality, the same for everyone, one attempt per week; recurring weekly Game Center leaderboard "Défi de la semaine".
- "Derbies": choose a country (France, Spain, Germany, Italy, United Kingdom), then a derby; 15 questions about the two clubs, replayable, no leaderboard.
- Pre-match quiz ("Avant-match"): a banner appears on the home screen during the 24 hours before a major league or Champions League match between two clubs of the game; it opens a 10-question quiz on both clubs, replayable until kick-off. If no such match is scheduled in the next 24 hours when you test, the banner is simply not shown.
- "Classement": leaderboards per mode; "Ouvrir dans Game Center" opens the native Game Center screen.
- Profile (top-right button): badges, choice of name frame, settings (vibrations, reminders), contact button, privacy policy link, app version.

3. Native iOS features
Game Center leaderboards and 23 achievements (one per badge; the iOS achievement banner appears when a badge is earned); haptic feedback (can be turned off in Profile › Réglages); share sheet for scores; home-screen quick actions (long-press the app icon); App Store rating prompt via SKStoreReviewController; full offline play with bundled content.
- iCloud: progress (badges, Aventure, played challenges, settings) is copied to the player's own iCloud key-value storage so it comes back after a reinstall or on a new iPhone. The developer never receives it.
- Local notifications: after the first finished game the app asks permission through the standard iOS prompt. If accepted, it schedules local reminders on the device only (new weekly challenge on Monday, last-day reminder on Sunday if not played, pre-match quizzes the day before). They can be turned off in Profile › Réglages › Rappels. No server, nothing sent.

4. External services
- Apple Game Center (leaderboards, achievements) and iCloud key-value storage, both handled by Apple.
- GitHub (raw.githubusercontent.com): the app downloads updated JSON data files (questions, clubs, weekly challenges, upcoming matches) from the public repository github.com/charlit/sportquiz. JSON data only, validated by the app, never executable code. Nothing is sent. If the download fails, the bundled data is used. The match list is produced by a scheduled script using football-data.org; the app never contacts football-data.org.
No analytics, advertising, authentication, payment or AI services.

5. Regions
French only, distributed in French-speaking countries; identical everywhere.

6. Third-party material
All questions are original factual trivia written by the developer. Clubs, players and competitions are only mentioned by name as facts; no logos, crests, official photos, videos or branding. Flags are simple drawings. Achievement images use Twemoji artwork (CC-BY 4.0, credited on the support page). Not affiliated with or endorsed by any club, league or federation.
```

## Description App Store (fr-FR, 4 000 caractères max)

```
Tu penses tout savoir sur le foot ? Prouve-le !

Football Quiz réunit plus de 4 000 questions sur le football : l'histoire des grands clubs, les derbies, les légendes et toute la culture foot, des années 1990 à aujourd'hui.

SPÉCIAL FOOT
100 questions, 3 vies, 5 niveaux de difficulté. Réponds vite pour marquer plus de points.

HARDCORE
Une seule vie, uniquement des questions Expert et Légende, et ça ne s'arrête jamais. Joue sur tout le foot ou choisis un pays : France, Espagne, Royaume-Uni, Allemagne ou Italie. Chaque mode a son propre classement.

AVENTURE
Pars de la France et parcours l'histoire de 18 clubs, de 2024 jusqu'aux années 1990, en 10 étapes chacun. Termine tous les clubs d'un pays pour débloquer le suivant : Espagne, Royaume-Uni, Allemagne et Italie.

DÉFI DE LA SEMAINE
Chaque lundi, 10 questions sur une légende du foot : joueurs, entraîneurs, gardiens, arbitres. Un seul essai, les mêmes questions pour tout le monde, et un classement remis à zéro chaque semaine.

DERBIES
Le Classique, El Clásico, la Madonnina, le Merseyside… 30 grandes rivalités en France, Espagne, Allemagne, Italie et Royaume-Uni, 15 questions par derby.

AVANT-MATCH
24 heures avant les grosses affiches, un quiz spécial sur les deux équipes apparaît. Échauffe-toi avant le coup d'envoi !

BADGES, SUCCÈS ET CLASSEMENTS
Gagne des badges en jouant, retrouve-les en succès Game Center, choisis l'encart de ton nom et compare tes scores avec les autres joueurs.

ET AUSSI
• Progression sauvegardée dans iCloud : tu la retrouves sur ton nouvel iPhone
• Rappels pour le défi de la semaine et les avant-matchs (désactivables)
• De nouvelles questions arrivent régulièrement, sans mise à jour de l'app
• Fonctionne hors ligne
• Pas de publicité, pas de compte à créer, aucune donnée collectée

Un bug, une question fausse, une idée ? Écris-nous depuis ton profil, dans l'app.
```

## Nouveautés de cette version (fr-FR, « What's New »)

```
• Défi de la semaine : 10 questions sur une légende du foot, un seul essai, un classement chaque semaine
• Derbies : 30 grandes rivalités dans 5 pays
• Avant-match : un quiz sur les deux équipes 24 h avant les grosses affiches
• Succès Game Center pour tous les badges
• Sauvegarde iCloud de ta progression
• Rappels pour le défi et les avant-matchs
• Choix de l'encart de ton nom, accueil plus compact, corrections diverses
```

## Aussi au moment de l'envoi

- Remplacer les images des succès par les dessins Twemoji : `python3 ~/.appstoreconnect/gc-achievements.py --remplacer-images` (seulement quand aucune soumission en attente ne contient les succès).
- Le mode Supporters n'est accessible par aucun écran : ne pas le mentionner tant qu'il n'est pas affiché à l'accueil.
