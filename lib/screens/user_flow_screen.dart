import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project_model.dart';
import '../models/screen_model.dart';
import '../providers/project_provider.dart';

class UserFlowScreen extends StatelessWidget {
  const UserFlowScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.activeProject;

    if (project == null || project.id != projectId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('User Flow · ${project.name}')),
      body: project.screens.isEmpty
          ? const Center(child: Text('Aucun écran dans ce projet.'))
          : _UserFlowCanvas(project: project),
    );
  }
}

class _UserFlowCanvas extends StatelessWidget {
  const _UserFlowCanvas({required this.project});

  final ProjectModel project;

  static const double _cardW = 180;
  static const double _cardH = 110;
  static const double _hGap = 70;

  @override
  Widget build(BuildContext context) {
    final links = <(String, String)>[];
    for (final screen in project.screens) {
      for (final comp in screen.components) {
        final actionType = (comp.properties['actionType'] as String?) ?? 'none';
        final target = (comp.properties['targetScreenId'] as String?) ?? '';
        if (actionType == 'navigate' && target.isNotEmpty) {
          if (project.screens.any((s) => s.id == target)) {
            links.add((screen.id, target));
          }
        }
      }
    }

    final n = project.screens.length;
    final totalW = n * _cardW + (n - 1) * _hGap + 80;
    final totalH = _cardH + 120.0;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(60),
      minScale: 0.3,
      maxScale: 2.5,
      child: SizedBox(
        width: totalW,
        height: totalH,
        child: Stack(
          children: [
            // Arrows painted below
            Positioned.fill(
              child: CustomPaint(
                painter: _ArrowPainter(
                  screens: project.screens,
                  links: links,
                  cardW: _cardW,
                  cardH: _cardH,
                  hGap: _hGap,
                  arrowColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            // Cards
            for (var i = 0; i < project.screens.length; i++)
              Positioned(
                left: 40 + i * (_cardW + _hGap),
                top: 20,
                child: _ScreenCard(
                  screen: project.screens[i],
                  cardW: _cardW,
                  cardH: _cardH,
                  hasIncoming: links.any((l) => l.$2 == project.screens[i].id),
                  hasOutgoing: links.any((l) => l.$1 == project.screens[i].id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScreenCard extends StatelessWidget {
  const _ScreenCard({
    required this.screen,
    required this.cardW,
    required this.cardH,
    required this.hasIncoming,
    required this.hasOutgoing,
  });

  final ScreenModel screen;
  final double cardW;
  final double cardH;
  final bool hasIncoming;
  final bool hasOutgoing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: cardW,
      height: cardH,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_android_rounded, color: cs.primary, size: 26),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              screen.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${screen.components.length} composant(s)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasIncoming) _Badge(label: 'entrée', color: Colors.green),
              if (hasIncoming && hasOutgoing) const SizedBox(width: 4),
              if (hasOutgoing) _Badge(label: 'sortie', color: Colors.orange),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({
    required this.screens,
    required this.links,
    required this.cardW,
    required this.cardH,
    required this.hGap,
    required this.arrowColor,
  });

  final List<ScreenModel> screens;
  final List<(String, String)> links;
  final double cardW;
  final double cardH;
  final double hGap;
  final Color arrowColor;

  Offset _cardCenter(int i) =>
      Offset(40 + i * (cardW + hGap) + cardW / 2, 20 + cardH / 2);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = arrowColor.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = arrowColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final indexById = {for (var i = 0; i < screens.length; i++) screens[i].id: i};

    for (final link in links) {
      final si = indexById[link.$1];
      final di = indexById[link.$2];
      if (si == null || di == null || si == di) continue;

      final src = _cardCenter(si).translate(0, -cardH / 2);
      final dst = _cardCenter(di).translate(0, -cardH / 2);
      final mid = Offset((src.dx + dst.dx) / 2, src.dy - 36);

      final path = Path()
        ..moveTo(src.dx, src.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, dst.dx, dst.dy);
      canvas.drawPath(path, paint);

      // Arrowhead at dst
      final angle = math.atan2(dst.dy - mid.dy, dst.dx - mid.dx);
      final tip = dst;
      final arrowPath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          tip.dx - 10 * math.cos(angle - 0.35),
          tip.dy - 10 * math.sin(angle - 0.35),
        )
        ..lineTo(
          tip.dx - 10 * math.cos(angle + 0.35),
          tip.dy - 10 * math.sin(angle + 0.35),
        )
        ..close();
      canvas.drawPath(arrowPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) =>
      old.links != links || old.screens != screens;
}
