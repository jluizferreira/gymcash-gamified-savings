// lib/screens/profile_screen.dart
//
// Resumo do usuário: acumulado, streak, patente e conquistas (roadmap v1.1).

import 'package:flutter/material.dart';

import '../models/achievement_model.dart';
import '../models/rank_model.dart';
import '../models/user_model.dart';
import '../services/achievement_service.dart';
import '../services/local_storage_service.dart';
import '../services/streak_service.dart';
import '../widgets/achievement_unlock_toast.dart';
import 'achievements_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LocalStorageService _storage = LocalStorageService();

  bool _loading = true;
  String? _errorMessage;

  double _totalAccumulated = 0;
  int _streak = 0;
  int _unlockedCount = 0;
  RankModel? _rank;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Agrega dados do gateway e serviços; falhas viram mensagem em português.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final total = await _storage.getTotalAccumulated(widget.user.id);
      final streak =
          await StreakService(_storage).calculateStreak(widget.user.id);
      final newlyUnlocked =
          await AchievementService(_storage).checkAndUnlock(widget.user.id);
      final unlocked =
          await AchievementService(_storage).unlockedCount(widget.user.id);
      final rank = RankModel.fromTotal(total);

      if (!mounted) return;
      setState(() {
        _totalAccumulated = total;
        _streak = streak;
        _unlockedCount = unlocked;
        _rank = rank;
        _loading = false;
      });

      if (newlyUnlocked.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          AchievementUnlockToast.showSequence(context, newlyUnlocked);
        });
      }
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage =
            'Não foi possível carregar seu perfil. Verifique o armazenamento e tente novamente.';
      });
    }
  }

  Future<void> _openAchievements() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AchievementsScreen(userId: widget.user.id),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00E676),
                  strokeWidth: 2,
                ),
              )
            : _errorMessage != null
                ? _ProfileErrorState(
                    message: _errorMessage!,
                    onRetry: _load,
                  )
                : RefreshIndicator(
                    color: const Color(0xFF00E676),
                    backgroundColor: const Color(0xFF161616),
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      children: [
                        _ProfileHeader(user: widget.user),
                        const SizedBox(height: 24),
                        _ProfileAccumulatedCard(total: _totalAccumulated),
                        const SizedBox(height: 12),
                        _ProfileStreakCard(streak: _streak),
                        const SizedBox(height: 12),
                        if (_rank != null)
                          _ProfileRankCard(
                            rank: _rank!,
                            total: _totalAccumulated,
                          ),
                        const SizedBox(height: 12),
                        _ProfileAchievementsCard(
                          unlocked: _unlockedCount,
                          total: AchievementModel.all.length,
                          onOpen: _openAchievements,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

// ── Erro + retry ─────────────────────────────────────────────────────────────
class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Icon(
          Icons.cloud_off_rounded,
          size: 56,
          color: Colors.redAccent.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 20),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => onRetry(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00E676),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Cabeçalho ────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00E676).withValues(alpha: 0.35),
            ),
          ),
          child: Center(
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Resumo da sua jornada',
                style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Acumulado ───────────────────────────────────────────────────────────────
class _ProfileAccumulatedCard extends StatelessWidget {
  const _ProfileAccumulatedCard({required this.total});

  final double total;

  static String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final dec = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return 'R\$ ${buffer.toString()},$dec';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00E676).withValues(alpha: 0.12),
            const Color(0xFF00E676).withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: Color(0xFF00E676),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total acumulado (maratona)',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streak ───────────────────────────────────────────────────────────────────
class _ProfileStreakCard extends StatelessWidget {
  const _ProfileStreakCard({required this.streak});

  final int streak;

  String get _label {
    if (streak == 0) return 'Comece a contribuir este mês!';
    if (streak == 1) return '1 mês consecutivo';
    return '$streak meses consecutivos';
  }

  String get _emoji {
    if (streak == 0) return '💤';
    if (streak < 3) return '🔥';
    if (streak < 6) return '🔥🔥';
    return '🔥🔥🔥';
  }

  Color get _color {
    if (streak == 0) return const Color(0xFF444444);
    if (streak < 3) return const Color(0xFFFF6B35);
    if (streak < 6) return const Color(0xFFFF4500);
    return const Color(0xFFFF2200);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: streak > 0
            ? _color.withValues(alpha: 0.07)
            : const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: streak > 0
              ? _color.withValues(alpha: 0.3)
              : const Color(0xFF1E1E1E),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sequência (streak)',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _label,
                  style: TextStyle(
                    color: streak > 0 ? Colors.white : const Color(0xFF555555),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$streak',
                style: TextStyle(
                  color: _color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Patente + barra ──────────────────────────────────────────────────────────
class _ProfileRankCard extends StatelessWidget {
  const _ProfileRankCard({
    required this.rank,
    required this.total,
  });

  final RankModel rank;
  final double total;

  String _fmtInt(double v) {
    final s = v.toStringAsFixed(0);
    final parts = s.split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write('.');
      buf.write(parts[i]);
    }
    return 'R\$ ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(rank.colorValue);
    final next = RankModel.nextRank(rank);
    final progress = RankModel.progressToNext(total);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(rank.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patente atual',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      rank.title,
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Próxima: ${next.emoji} ${next.title}',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _fmtInt(next.minAmount),
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFF222222),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Você alcançou a patente máxima.',
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Conquistas (atalho) ─────────────────────────────────────────────────────
class _ProfileAchievementsCard extends StatelessWidget {
  const _ProfileAchievementsCard({
    required this.unlocked,
    required this.total,
    required this.onOpen,
  });

  final int unlocked;
  final int total;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222222)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: Color(0xFF00E676),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conquistas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$unlocked de $total desbloqueadas',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Ver todas',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF444444),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
