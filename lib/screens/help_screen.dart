import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mode d’emploi'),
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
      '1. Crée un projet depuis l’accueil.',
      '2. Ouvre le projet puis ajoute des composants.',
      '3. Sélectionne un composant et modifie ses propriétés.',
      '4. Active Mode drag pour glisser-déposer.',
      '5. Active Mode grille + snap pour caler les éléments.',
      '6. Utilise Calques (recherche + filtres) pour retrouver vite un élément.',
      '7. Groupe des éléments, copie/colle ta sélection.',
      '8. Imbrique des composants avec parent/enfant.',
      '9. Enregistre ta sélection en template perso.',
      '10. Règle les contraintes responsive (visibilité, largeur, alignement).',
      '11. Exporte JSON/ZIP et partage par e-mail si besoin.',
      '12. Génére aussi le bundle Flutter Pro structuré.',
      '13. Ouvre la timeline pour revenir à un état précédent, même après redémarrage.',
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
            'Tu as les tabs d’écrans, la preview, le panneau Calques et Propriétés.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Écrans',
          child: Text(
            'Tu peux ajouter, dupliquer, renommer, déplacer gauche/droite et supprimer.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Composants',
          child: Text(
            'Ajoute des composants UI puis modifie texte, taille, couleurs, effets, actions.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Groupe Et Clipboard',
          child: Text(
            'Tu peux grouper/dégrouper des composants, sélectionner un groupe complet, copier une sélection puis la coller sur l’écran.',
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
          title: 'Autosave Et Timeline',
          child: Text(
            'L’application sauvegarde automatiquement les modifications. Tu peux forcer une sauvegarde avec le bouton Sauver et restaurer un point précédent avec l’icône timeline. L’historique est conservé au redémarrage.',
          ),
        ),
        SizedBox(height: 12),
        _InfoCard(
          title: 'Export',
          child: Text(
            'Depuis le menu actions: export/import JSON, export ZIP V2/Pro, export par mail V2/Pro et génération de code Flutter.',
          ),
        ),
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
