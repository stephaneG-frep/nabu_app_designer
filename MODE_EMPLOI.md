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

- `+` : ajouter un écran
- Bouton `...` (actions écran) :
- dupliquer écran
- renommer écran
- déplacer écran à gauche/droite
- supprimer écran

## 5. Ajouter des composants

- Bouton `Ajouter composant`
- Tu peux ajouter : Text, Button, Card, Image placeholder, TextField, AppBar, etc.

## 6. Sélection, multi-sélection, calques

- Tap sur un composant : sélection simple
- Appui long (mode drag OFF) : ajouter/retirer de la sélection multiple
- Panneau `Calques` :
- voit l'ordre des composants
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
- layout (largeur, hauteur, padding, marge, alignement, ligne)
- effets (bordure, opacité, rotation, scale, ombre)
- actions (navigation vers un autre écran)
- image locale (galerie)

Si aucun composant n'est sélectionné :

- le panneau affiche les paramètres de l'écran (ex: background écran)

## 9. Preview : réduit / normal / agrandir

Tu as un contrôle `Taille preview` :

- `Réduit`
- `Normal`
- `Agrandir`

Sur petit écran, ce contrôle passe automatiquement en menu déroulant pour éviter les débordements.

## 10. Mode drag et grille

Dans `Plus d’actions` :

- `Mode drag` :
- ON : glisser-déposer activé
- OFF : scroll plus fluide + appui long pour multi-sélection

- `Mode grille + snap` :
- affiche la grille
- en drag, les composants se calent sur la grille (snap)

## 11. Actions de masse (menu Plus d’actions)

Sur la sélection courante :

- dupliquer
- premier plan / arrière-plan
- mettre sur même ligne / auto-ligne
- aligner gauche / centre / droite
- supprimer sélection
- verrouiller / déverrouiller sélection

## 12. Import / Export / Génération Flutter

Dans `Plus d’actions` :

- `Exporter JSON` : copie le projet en JSON
- `Importer JSON` : colle un JSON de projet
- `Générer code Flutter` : génère du code Flutter (copiable)

## 13. Conseils pratiques

- Pour éditer vite : utilise le panneau calques + multi-sélection.
- Pour éviter les erreurs : verrouille les éléments finalisés.
- Pour réorganiser proprement : active `Mode drag`, puis `Mode grille + snap`.
- Pour présenter : utilise `Plein écran`.

## 14. Dépannage rapide

- Si le scroll est difficile : désactive `Mode drag`.
- Si un composant ne bouge pas : vérifie qu'il n'est pas verrouillé.
- Si un bouton n'agit pas : vérifie `Action au tap` + `Écran cible`.
- Si le téléphone n'est pas détecté : reconnecte USB + `flutter devices`.

