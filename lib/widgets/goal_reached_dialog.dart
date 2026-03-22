// lib/widgets/goal_reached_dialog.dart
//
// Diálogo comemorativo ao atingir 100% da meta (roadmap v1.1).

import 'package:flutter/material.dart';

abstract final class _GoalDialogColors {
  static const background = Color(0xFF0A0A0A);
  static const accent = Color(0xFF448AFF);
  static const textMuted = Color(0xFF888888);
}

/// Conteúdo do [Dialog] de meta atingida — use com [showDialog] onde precisar
/// (ex.: tela de contribuição com feedback háptico antes de abrir).
class GoalReachedDialog extends StatelessWidget {
  const GoalReachedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _GoalDialogColors.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _GoalDialogColors.accent.withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _GoalDialogColors.accent.withValues(alpha: 0.12),
              blurRadius: 32,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TrophyAnimated(),
              const SizedBox(height: 20),
              Text(
                '🎯 Meta atingida!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _GoalDialogColors.accent.withValues(alpha: 0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Parabéns!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você cumpriu sua meta de economia neste mês. Continue assim!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _GoalDialogColors.textMuted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _GoalDialogColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Atalho com [showDialog] para outros fluxos (ex.: simulação no extrato).
Future<void> showGoalReachedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) => const GoalReachedDialog(),
  );
}

/// Troféu com leve balanço e pulso de escala.
class _TrophyAnimated extends StatefulWidget {
  const _TrophyAnimated();

  @override
  State<_TrophyAnimated> createState() => _TrophyAnimatedState();
}

class _TrophyAnimatedState extends State<_TrophyAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    final rotation = Tween<double>(begin: -0.08, end: 0.08).animate(curved);
    final scale = Tween<double>(begin: 0.94, end: 1.06).animate(curved);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: rotation.value,
          child: Transform.scale(
            scale: scale.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _GoalDialogColors.accent.withValues(alpha: 0.12),
          border: Border.all(
            color: _GoalDialogColors.accent.withValues(alpha: 0.35),
          ),
        ),
        child: const Icon(
          Icons.emoji_events_rounded,
          size: 48,
          color: _GoalDialogColors.accent,
        ),
      ),
    );
  }
}
