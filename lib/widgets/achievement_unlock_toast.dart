// lib/widgets/achievement_unlock_toast.dart
//
// Toast animado ao desbloquear conquista (roadmap v1.1). Usa Overlay na raiz
// para continuar visível após pop de rota (ex.: voltar da contribuição).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/achievement_model.dart';

/// Exibe toasts em sequência para cada conquista recém-desbloqueada.
abstract final class AchievementUnlockToast {
  AchievementUnlockToast._();

  /// Enfileira um toast por item; ids desconhecidos são ignorados.
  /// Usa [rootOverlay] para o banner sobreviver a `Navigator.pop` imediato.
  static void showSequence(BuildContext context, List<String> unlockedIds) {
    final items = <AchievementModel>[];
    for (final id in unlockedIds) {
      final def = _definitionFor(id);
      if (def != null) items.add(def);
    }
    if (items.isEmpty) return;
    _showAtIndex(context, items, 0);
  }

  static AchievementModel? _definitionFor(String id) {
    for (final a in AchievementModel.all) {
      if (a.id == id) return a;
    }
    return null;
  }

  static void _showAtIndex(
    BuildContext context,
    List<AchievementModel> list,
    int index,
  ) {
    if (!context.mounted || index >= list.length) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    final navigatorContext = context;
    entry = OverlayEntry(
      builder: (ctx) => _UnlockToastOverlay(
        achievement: list[index],
        onDismissed: () {
          entry.remove();
          Future<void>.delayed(const Duration(milliseconds: 300), () {
            if (!navigatorContext.mounted) return;
            _showAtIndex(navigatorContext, list, index + 1);
          });
        },
      ),
    );
    overlay.insert(entry);
    HapticFeedback.mediumImpact();
  }
}

class _UnlockToastOverlay extends StatefulWidget {
  const _UnlockToastOverlay({
    required this.achievement,
    required this.onDismissed,
  });

  final AchievementModel achievement;
  final VoidCallback onDismissed;

  @override
  State<_UnlockToastOverlay> createState() => _UnlockToastOverlayState();
}

class _UnlockToastOverlayState extends State<_UnlockToastOverlay>
    with SingleTickerProviderStateMixin {
  static const _hold = Duration(milliseconds: 2400);
  static const _inOut = Duration(milliseconds: 420);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _inOut);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.15),
      end: Offset.zero,
    ).animate(_fade);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(_fade);

    _controller.forward();
    Future<void>.delayed(_hold, () {
      if (!mounted) return;
      _controller.reverse().whenComplete(() {
        if (mounted) widget.onDismissed();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 12;

    return Positioned(
      left: 16,
      right: 16,
      top: top,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Semantics(
              liveRegion: true,
              label:
                  'Conquista desbloqueada: ${widget.achievement.title}',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: _scale,
                      child: Text(
                        widget.achievement.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Conquista desbloqueada!',
                            style: TextStyle(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.95),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.achievement.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.achievement.description,
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
