# Mode d'emploi — Nabu UI Builder

Ce guide explique comment utiliser l'application pour créer des interfaces mobiles.

## 1. Écran d'accueil

- Tu vois la liste des projets.
- Bouton `Nouveau projet` : crée un projet.
- Sur chaque carte projet (`...`) :
- `Renommer`
- `Dupliquer`
- `Supprimer`

## 2. Ouvrir un projet

- Appuie sur une carte projet pour ouvrir l'éditeur.

## 3. Éditeur (vue principale)

L'éditeur est composé de :

- `Tabs d'écrans` (Home, Screen 2, etc.)
- `Aperçu mobile` (preview)
- `Panneau Calques`
- `Panneau Propriétés`

## 4. Gestion des écrans

Dans la barre des écrans :

- Chaque tab affiche le **nombre de composants** entre parenthèses : `Home (3)`.
- `+` : ajouter un écran
- Bouton `...` (actions écran) :
- dupliquer écran
- renommer écran
- déplacer écran à gauche/droite
- supprimer écran

## 5. Ajouter des composants

- Bouton `Ajouter composant`
- **Barre de recherche** en haut de la feuille : filtre les composants en temps réel par nom.
- **36 composants** disponibles :
  - Basiques : Text, Button, Card, Image, TextField, AppBar, Icon, Divider, Avatar, Chip
  - Formulaires : Switch, Checkbox, Slider, Radio Group, Dropdown, Date Picker
  - Navigation : Bottom Nav, Tab Bar, Nav Drawer, FAB, Icon Button
  - Affichage : Badge, Container, Banner, Stat Card, Progress Bar, Circular Progress, List Tile, Search Bar, Rating Stars, Carousel, Stepper, Bottom Sheet
  - Nouveaux : **Segmented Button**, **Expansion Tile**, **Alert Dialog**, **Snackbar**, **Data Table**, **Skeleton**
  - **Annotation** : post-it de design (non exporté en code Flutter)
- Dans cette feuille, tu retrouves aussi `Mes templates` (templates persos).

## 6. Sélection, multi-sélection, calques

- Tap sur un composant : sélection simple
- Appui long (mode drag OFF) : ajouter/retirer de la sélection multiple
- Panneau `Calques` :
- voit l'ordre des composants
- recherche par texte/type
- filtres rapides (visibles, verrouillés, sélection)
- sélection rapide
- bouton oeil : afficher/masquer
- bouton cadenas : verrouiller/déverrouiller

## 7. Verrouillage (Lock)

Un composant verrouillé :

- ne peut pas être déplacé
- ne peut pas être modifié par les actions de masse
- ne peut pas être supprimé par erreur

Tu peux verrouiller :

- depuis `Propriétés > Verrouillé`
- depuis `Calques` (icône cadenas)
- depuis le menu `Plus d’actions` (verrouiller/déverrouiller sélection)

## 8. Panneau Propriétés

Après sélection d'un composant, tu peux modifier :

- texte / sous-texte
- couleurs (color picker)
- background + gradient
- typo (taille, poids, espacement)
- layout (largeur, hauteur, padding, marge, alignement, ligne, **décalage X/Y**)
- effets (bordure, opacité, rotation, scale, ombre)
- actions (navigation vers un autre écran)
- image locale (galerie)
- **Copier le style** (icône pinceau vide) : copie toutes les propriétés visuelles du composant sélectionné.
- **Coller le style** (icône pinceau plein) : applique le style copié à la sélection courante.

Si aucun composant n'est sélectionné :

- le panneau affiche les paramètres de l'écran (ex: background écran)

## 9. Preview : réduit / normal / agrandir

Tu as un contrôle `Taille preview` :

- `Réduit`
- `Normal`
- `Agrandir`

Sur petit écran, ce contrôle passe automatiquement en menu déroulant pour éviter les débordements.

**Zoom pinch** : activable depuis `Plus d'actions > Zoom pinch preview`. Une fois activé, tu peux pincer l'aperçu pour zoomer/dézoomer (0.4× à 3×).

## 10. Mode drag et grille

Dans `Plus d’actions` :

- `Mode drag` :
- ON : glisser-déposer activé
- OFF : scroll plus fluide + appui long pour multi-sélection

- `Mode grille + snap` :
- affiche la grille
- en drag, les composants se calent sur la grille (snap)

## 11. Autosave intelligent et timeline

- L’app sauvegarde automatiquement après tes modifications (autosave).
- Une ligne d’état indique :
- sauvegarde en cours
- modifications non sauvegardées
- heure de dernière sauvegarde
- bouton `Sauver` : force une sauvegarde immédiate.
- icône `Timeline` (en haut) :
- affiche l’historique visuel des changements
- permet de restaurer un état précédent en un tap

## 12. Actions de masse (menu Plus d’actions)

Sur la sélection courante :

- dupliquer
- copier sélection / coller
- enregistrer en template
- grouper sélection / dégrouper sélection
- sélectionner le groupe
- imbriquer sous sélection (parent/enfant)
- sortir du parent
- premier plan / arrière-plan
- mettre sur même ligne / auto-ligne
- aligner gauche / centre / droite
- supprimer sélection
- verrouiller / déverrouiller sélection

## 13. Arbre imbriqué (parent/enfant)

- Le composant sélectionné peut devenir parent d’autres éléments.
- Parents recommandés : `Container`, `Card`, `Banner`.
- Workflow :
- sélectionne le parent puis au moins un autre composant
- `Plus d’actions > Imbriquer sous sélection`
- pour revenir à plat : `Plus d’actions > Sortir du parent`

Dans le panneau `Calques`, l’arborescence est affichée avec indentation.

## 14. Contraintes responsive

Dans `Propriétés > Responsive` :

- `Visibilité` : tous écrans / mobile seulement / large écran seulement
- `Largeur responsive` : fixe ou remplir disponible
- `Alignement responsive` : hériter / gauche / centre / droite

## 15. Import / Export / Génération Flutter

Dans `Plus d’actions` :

- `Exporter JSON` : copie le projet en JSON
- `Exporter JSON par mail` : génère un fichier JSON puis ouvre le partage Android (Gmail/mail)
- `Importer JSON` : colle un JSON de projet
- `Exporter JSON fichier` : sauvegarde un fichier `.json` local
- `Importer JSON fichier` : charge un `.json` local
- `Générer code Flutter` : génère du code Flutter (copiable)
- `Générer Flutter V2` : bundle multi-fichiers (main + screens)
- `Générer Flutter Pro` : bundle structuré (`app/`, `router/`, `theme/`, `screens/`)
- `Exporter Flutter V2 (.zip)` : crée un zip prêt à récupérer
- `Exporter par mail` : crée le zip Flutter et ouvre le partage Android (Gmail/mail)
- `Exporter Flutter Pro (.zip)` : crée un zip Flutter Pro
- `Exporter Flutter Pro par mail` : envoie le zip Pro via partage Android

## 16. Raccourcis clavier (physique)

Sur tablette ou avec clavier physique connecté :

| Raccourci | Action |
|-----------|--------|
| `Suppr` | Supprimer la sélection |
| `Ctrl + Z` | Annuler (undo) |
| `Ctrl + Y` | Rétablir (redo) |
| `Ctrl + D` | Dupliquer la sélection |
| `Ctrl + G` | Grouper la sélection |
| `Ctrl + C` | Copier la sélection |
| `Ctrl + V` | Coller |

## 17. Aperçu plein écran (Full Preview)

- Bouton `Plein écran` (ou menu) : ouvre une vue de navigation indépendante de l'éditeur.
- Navigation dans l'aperçu : les boutons avec `Action au tap > Naviguer vers` fonctionnent réellement.
- **Bouton retour** : revient à l'écran précédent dans l'historique de navigation.
- **Sélecteur d'écran** (icône calques en haut à droite) : sauter directement à n'importe quel écran.
- **Zoom** : activer/désactiver le pinch-zoom depuis l'icône en haut à droite.

## 18. User Flow (carte des navigations)

Dans `Plus d'actions > User Flow` :

- Affiche une carte de tous les écrans et leurs liens de navigation.
- Les flèches représentent les composants avec une action `Naviguer vers`.
- Badges `entrée` / `sortie` indiquent le sens des navigations pour chaque écran.
- L'affichage est zoomable (pinch ou molette) de 0.3× à 2.5×.

## 19. Presets de thème

Dans `Plus d'actions > Appliquer un preset thème` :

Applique instantanément un jeu de couleurs cohérent à tous les composants non verrouillés.

| Preset | Style |
|--------|-------|
| Material Teal | Vert sarcelle Material Design |
| Bleu Océan | Bleu profond |
| Violet Pro | Violet moderne |
| Corail Warm | Tons chauds corail |
| Dark Mode | Sombre avec accents gris/bleu |
| Minimaliste | Blanc/gris épuré |

## 20. Export aperçu PNG

Dans `Plus d'actions > Exporter aperçu PNG` :

- Capture l'aperçu mobile en image PNG.
- Ouvre le menu de partage Android (enregistrer, envoyer par mail, etc.).

## 21. Auto-layout (Container)

Dans `Propriétés > Auto-layout` (visible uniquement sur un composant **Container**) :

- `Aucun` : comportement par défaut (enfants en liste verticale indentée)
- `Rangée (horizontal)` : enfants côte à côte avec espacement configurable
- `Colonne (vertical)` : enfants empilés verticalement avec espacement configurable
- `Espacement enfants` : slider de 0 à 40 px entre les éléments

## 22. Annotations (post-its)

Le composant **Annotation** (icône post-it dans Ajouter composant) permet d'ajouter des notes de design directement sur l'écran :

- Rendu en fond jaune avec icône épingle
- Modifiable comme tout composant (texte, taille, position)
- **Non exporté** dans le code Flutter généré

## 23. Preview sombre

Dans `Plus d'actions > Preview sombre` :

- Bascule l'aperçu en dark mode sans modifier le projet.
- Coché = preview sombre activée, décoché = preview normale.

## 24. Guides manuels

Dans `Plus d'actions` :

- `Ajouter guide horizontal` : ajoute une ligne rouge horizontale au centre de la preview.
- `Ajouter guide vertical` : ajoute une ligne rouge verticale au centre de la preview.
- `Effacer les guides` : supprime tous les guides affichés.

Les guides sont superposés à la preview (non exportés, non visibles dans le plein écran).

## 25. Design tokens (couleur globale)

Dans `Plus d'actions > Design tokens (couleur globale)` :

- Choisis une **couleur accent** parmi 6 teintes prédéfinies.
- Choisis une **couleur de fond** parmi 6 options.
- Applique les deux couleurs à **tous les composants non verrouillés** de l'écran actif en un clic.

## 26. Multi-écrans côte à côte

Dans `Plus d'actions > Multi-ecrans cote a cote` :

- Affiche tous les écrans du projet en vue horizontale scrollable.
- Chaque écran est affiché dans son device frame avec son nom.
- Utile pour comparer les écrans et vérifier la cohérence visuelle.

## 27. Mode présentation (slideshow)

Dans `Plus d'actions > Mode presentation` :

- Lance un slideshow de tous les écrans du projet.
- **Lecture auto** : icône play en haut à droite pour avancer automatiquement.
- **Intervalle** : menu déroulant 2s / 3s / 5s / 10s.
- **Navigation manuelle** : flèches gauche/droite ou tap sur les points de navigation.
- Navigation interactive : les boutons avec `Action au tap > Naviguer vers` fonctionnent.

## 28. Conseils pratiques

- Pour éditer vite : utilise le panneau calques + multi-sélection + recherche.
- Pour éviter les erreurs : verrouille les éléments finalisés.
- Pour réorganiser proprement : active `Mode drag`, puis `Mode grille + snap`.
- Pour présenter : utilise `Plein écran`.

## 29. Dépannage rapide

- Si le scroll est difficile : désactive `Mode drag`.
- Si un composant ne bouge pas : vérifie qu'il n'est pas verrouillé.
- Si un bouton n'agit pas : vérifie `Action au tap` + `Écran cible`.
- Si le téléphone n'est pas détecté : reconnecte USB + `flutter devices`.
