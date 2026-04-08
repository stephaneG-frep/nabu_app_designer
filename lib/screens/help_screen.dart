import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mode d'emploi"),
          bottom: const TabBar(
            tabs: [
              Tab(text: '2 minutes'),
              Tab(text: 'Complet'),
            ],
          ),
        ),
        body: const TabBarView(children: [_QuickGuideTab(), _FullGuideTab()]),
      ),
    );
  }
}

class _QuickGuideTab extends StatelessWidget {
  const _QuickGuideTab();

  @override
  Widget build(BuildContext context) {
    final steps = <String>[
      "1. Crée un projet depuis l'accueil.",
      '2. Ouvre le projet puis ajoute des composants (recherche par nom dans la feuille).',
      '3. Sélectionne un composant et modifie ses propriétés.',
      '4. Copie/colle le style entre composants (icônes pinceau dans Propriétés).',
      '5. Active Mode drag pour glisser-déposer.',
      '6. Active Mode grille + snap pour caler les éléments.',
      '7. Utilise Calques (recherche + filtres) pour retrouver vite un élément.',
      '8. Groupe des éléments, copie/colle ta sélection.',
      '9. Imbrique des composants avec parent/enfant.',
      '10. Enregistre ta sélection en template perso.',
      '11. Règle les contraintes responsive (visibilité, largeur, alignement).',
      '12. Applique un preset de thème depuis Plus actions pour harmoniser les couleurs.',
      '13. Ouvre User Flow pour visualiser la carte des navigations.',
      '14. Exporte JSON/ZIP et partage par e-mail si besoin.',
      '15. Génère aussi le bundle Flutter Pro structuré.',
      '16. Exporte un aperçu PNG depuis Plus actions.',
      '17. Ouvre la timeline pour revenir à un état précédent, même après redémarrage.',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: 'Prise En Main Rapide',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: steps
                .map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(step),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        const _InfoCard(
          title: 'Raccourcis Clavier',
          child: _KeyboardShortcutsWidget(),
        ),
        const SizedBox(height: 12),
        const _InfoCard(
          title: 'Astuce',
          child: Text(
            'Si le scroll est difficile, coupe le Mode drag. '
            'Rallume-le seulement quand tu veux déplacer des composants.',
          ),
        ),
      ],
    );
  }
}

class _KeyboardShortcutsWidget extends StatelessWidget {
  const _KeyboardShortcutsWidget();

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      ('Suppr', 'Supprimer la sélection'),
      ('Ctrl + Z', 'Annuler'),
      ('Ctrl + Y', 'Rétablir'),
      ('Ctrl + D', 'Dupliquer'),
      ('Ctrl + G', 'Grouper'),
      ('Ctrl + C', 'Copier'),
      ('Ctrl + V', 'Coller'),
    ];
    return Column(
      children: shortcuts
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      s.$1,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(s.$2),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FullGuideTab extends StatelessWidget {
  const _FullGuideTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _InfoCard(
          title: 'Accueil',
          child: Text(
            'Crée, renomme, duplique ou supprime des projets depuis les cartes.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Éditeur',
          child: Text(
            "Tu as les tabs d'écrans (avec le nombre de composants), la preview, le panneau Calques et Propriétés.",
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Écrans',
          child: Text(
            'Tu peux ajouter, dupliquer, renommer, déplacer gauche/droite et supprimer. '
            'Chaque tab affiche le nombre de composants entre parenthèses.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Composants',
          child: Text(
            'Ajoute des composants UI via la barre de recherche intégrée dans la feuille. '
            'Composants disponibles : Text, Button, Card, Image, TextField, AppBar, Switch, Checkbox, '
            'Progress Bar, Badge, Container, Icon Button, FAB, Bottom Nav, Tab Bar, Banner, Stat Card, '
            'Circular Progress, Slider, Radio Group, Dropdown, List Tile, Search Bar, Rating Stars, '
            'Carousel, Date Picker, Nav Drawer, Stepper, Bottom Sheet.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Propriétés Et Style',
          child: Text(
            'Modifie texte, taille, couleurs, effets, actions, décalage X/Y. '
            'Copie le style avec le bouton pinceau vide et colle-le sur une autre sélection avec le pinceau plein.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Groupe Et Clipboard',
          child: Text(
            "Tu peux grouper/dégrouper des composants, sélectionner un groupe complet, copier une sélection puis la coller sur l'écran.",
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Templates Perso',
          child: Text(
            'Sauvegarde une sélection en template puis réutilise-la depuis Ajouter composant. Tu peux aussi supprimer un template depuis cette feuille.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Arbre Imbriqué',
          child: Text(
            'Depuis le menu actions, imbrique des éléments sous un parent (Container/Card/Banner) puis retire-les du parent si besoin.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Responsive',
          child: Text(
            'Dans Propriétés > Responsive, choisis visibilité mobile/desktop, largeur fixe ou remplie, et alignement responsive.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Calques Et Lock',
          child: Text(
            'Le panneau Calques permet sélection rapide, visibilité et verrouillage.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Drag Et Grille',
          child: Text(
            'Mode drag = glisser-déposer. Mode grille + snap = alignement automatique.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Zoom Pinch Preview',
          child: Text(
            "Active Zoom pinch preview depuis Plus actions pour pincer l'aperçu et zoomer/dézoomer (0.4× à 3×).",
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Aperçu Plein Écran',
          child: Text(
            "L'aperçu plein écran est indépendant de l'éditeur : la navigation entre écrans ne modifie pas ton projet. "
            "Utilise le sélecteur d'écrans (icône calques) pour sauter directement à un écran, "
            "et le bouton retour pour reculer dans l'historique.",
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'User Flow',
          child: Text(
            "Depuis Plus actions > User Flow : visualise la carte de tous tes écrans et leurs liens de navigation. "
            "Les flèches indiquent les actions Naviguer vers définies sur tes composants. "
            "L'affichage est zoomable.",
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Presets De Thème',
          child: Text(
            "Depuis Plus actions > Appliquer un preset thème : applique instantanément un jeu de couleurs cohérent "
            "(Material Teal, Bleu Océan, Violet Pro, Corail Warm, Dark Mode, Minimaliste) "
            "à tous les composants non verrouillés.",
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Autosave Et Timeline',
          child: Text(
            "L'application sauvegarde automatiquement les modifications. Tu peux forcer une sauvegarde avec le bouton Sauver et restaurer un point précédent avec l'icône timeline. L'historique est conservé au redémarrage.",
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Export',
          child: Text(
            "Depuis le menu actions : export/import JSON, export ZIP V2/Pro, export par mail V2/Pro, "
            "génération de code Flutter, et export aperçu PNG.",
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Raccourcis Clavier',
          child: Text(
            "Suppr = supprimer · Ctrl+Z/Y = undo/redo · Ctrl+D = dupliquer · "
            "Ctrl+G = grouper · Ctrl+C = copier · Ctrl+V = coller.",
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
