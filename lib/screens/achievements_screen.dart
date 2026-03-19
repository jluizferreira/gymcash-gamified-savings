// lib/screens/achievements_screen.dart

import 'package:flutter/material.dart';
import '../models/achievement_model.dart';
import '../models/rank_model.dart';
import '../services/achievement_service.dart';
import '../services/local_storage_service.dart';

class AchievementsScreen extends StatefulWidget {
  final String userId;
  const AchievementsScreen({super.key, required this.userId});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _storage     = LocalStorageService();
  late final _service = AchievementService(_storage);

  List<AchievementModel> _achievements = [];
  double _total  = 0;
  bool   _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final achievements = await _service.getAchievements(widget.userId);
    final total        = await _storage.getTotalAccumulated(widget.userId);
    if (mounted) {
      setState(() {
        _achievements = achievements;
        _total        = total;
        _loading      = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank     = RankModel.fromTotal(_total);
    final nextRank = RankModel.nextRank(rank);
    final progress = RankModel.progressToNext(_total);
    final unlocked = _achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Conquistas',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF00E676), strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Card de patente ────────────────────────────────────────
                _RankCard(
                  rank:      rank,
                  nextRank:  nextRank,
                  total:     _total,
                  progress:  progress,
                ),

                const SizedBox(height: 20),

                // ── Progresso geral ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Conquistas',
                        style: TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('$unlocked / ${_achievements.length}',
                        style: const TextStyle(color: Color(0xFF555555),
                            fontSize: 14)),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Lista de conquistas ────────────────────────────────────
                ..._achievements.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AchievementTile(achievement: a),
                    )),
              ],
            ),
    );
  }
}

// ── Card de patente atual + progresso ─────────────────────────────────────────
class _RankCard extends StatelessWidget {
  final RankModel  rank;
  final RankModel? nextRank;
  final double     total;
  final double     progress;

  const _RankCard({
    required this.rank,
    required this.nextRank,
    required this.total,
    required this.progress,
  });

  String _fmt(double v) {
    final parts   = v.toStringAsFixed(0).split('');
    final buf     = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write('.');
      buf.write(parts[i]);
    }
    return 'R\$ ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(rank.colorValue);

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
              Text(rank.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sua patente',
                      style: TextStyle(color: Color(0xFF888888),
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(rank.title,
                      style: TextStyle(color: color, fontSize: 24,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Acumulado',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                  Text(_fmt(total),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),

          if (nextRank != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Próxima: ${nextRank!.emoji} ${nextRank!.title}',
                    style: const TextStyle(color: Color(0xFF666666),
                        fontSize: 12)),
                Text(_fmt(nextRank!.minAmount),
                    style: const TextStyle(color: Color(0xFF555555),
                        fontSize: 12)),
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
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Patente máxima atingida!',
                  style: TextStyle(color: color, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tile de conquista ─────────────────────────────────────────────────────────
class _AchievementTile extends StatelessWidget {
  final AchievementModel achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked
            ? const Color(0xFF161616)
            : const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? const Color(0xFF00E676).withValues(alpha: 0.2)
              : const Color(0xFF1A1A1A),
        ),
      ),
      child: Row(
        children: [
          // Emoji / cadeado
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: unlocked
                  ? const Color(0xFF00E676).withValues(alpha: 0.1)
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: unlocked
                  ? Text(achievement.emoji,
                      style: const TextStyle(fontSize: 22))
                  : const Icon(Icons.lock_outline_rounded,
                      color: Color(0xFF333333), size: 20),
            ),
          ),
          const SizedBox(width: 14),

          // Título e descrição
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: TextStyle(
                      color: unlocked ? Colors.white : const Color(0xFF444444),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(achievement.description,
                    style: const TextStyle(
                        color: Color(0xFF555555), fontSize: 12)),
              ],
            ),
          ),

          // Badge desbloqueado
          if (unlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('✓',
                  style: TextStyle(color: Color(0xFF00E676),
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
