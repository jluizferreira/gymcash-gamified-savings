// lib/screens/home_screen.dart
//
// Lista os grupos do usuário e permite criar novos.

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/local_storage_service.dart';
import '../services/streak_service.dart';
import '../services/achievement_service.dart';
import '../models/rank_model.dart';
import '../models/achievement_model.dart';
import 'achievements_screen.dart';
import 'onboarding_screen.dart';
import 'create_group_screen.dart';
import 'group_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = LocalStorageService();
  List<GroupModel> _groups = [];
  double _totalAccumulated = 0.0;
  int       _streak            = 0;
  RankModel? _rank;
  int       _unlockedCount    = 0;
  bool      _loading           = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  // ── Carrega grupos do armazenamento ───────────────────────────────────────
  // ── Carrega grupos e total acumulado ─────────────────────────────────────
  Future<void> _loadGroups() async {
    final groups = await _storage.getGroups();
    final total  = await _storage.getTotalAccumulated(widget.user.id);
    final streak    = await StreakService(_storage).calculateStreak(widget.user.id);
    await AchievementService(_storage).checkAndUnlock(widget.user.id);
    final achService   = AchievementService(_storage);
    final unlockedCount = await achService.unlockedCount(widget.user.id);
    final rank         = RankModel.fromTotal(total);
    if (mounted) {
      setState(() {
        _groups           = groups;
        _totalAccumulated = total;
        _streak           = streak;
        _rank             = rank;
        _unlockedCount    = unlockedCount;
        _loading          = false;
      });
    }
  }

  // ── Abre tela de criar grupo e atualiza lista ao voltar ───────────────────
  Future<void> _goToCreateGroup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(currentUser: widget.user),
      ),
    );
    _loadGroups(); // recarrega ao voltar
  }

  // ── Abre tela do grupo ────────────────────────────────────────────────────
  Future<void> _goToGroup(GroupModel group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupScreen(
          group:       group,
          currentUser: widget.user,
        ),
      ),
    );
    _loadGroups(); // recarrega ao voltar (membros podem ter mudado)
  }

  // ── Reset do usuário ──────────────────────────────────────────────────────
  Future<void> _resetUser() async {
    await _storage.clearUser();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  // ── Exclui grupo com confirmação ──────────────────────────────────────────
  Future<void> _deleteGroup(GroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir grupo?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'O grupo "${group.name}" e todos os seus membros serão removidos permanentemente.',
          style: const TextStyle(color: Color(0xFF888888), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF555555))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _storage.deleteGroup(group.id);
    _loadGroups();
  }

  void _showResetDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Trocar nome?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Isso vai apagar o nome salvo e voltar à tela inicial.',
            style: TextStyle(color: Color(0xFF888888), height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF555555)))),
          TextButton(
              onPressed: () { Navigator.of(ctx).pop(); _resetUser(); },
              child: const Text('Confirmar',
                  style: TextStyle(color: Color(0xFF00E676),
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF00E676).withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(widget.user.initials,
                          style: const TextStyle(color: Color(0xFF00E676),
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Olá, ${widget.user.firstName}!',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        const Text('Seus grupos',
                            style: TextStyle(color: Color(0xFF555555),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Trocar nome',
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFF444444)),
                    onPressed: _showResetDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Card de acumulado ────────────────────────────────────────────
            if (!_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: _AccumulatedCard(total: _totalAccumulated),
              ),

            const SizedBox(height: 10),

            // ── Card de streak ────────────────────────────────────────────
            if (!_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: _StreakCard(streak: _streak),
              ),

            const SizedBox(height: 10),

            // ── Card de patente ───────────────────────────────────────────
            if (!_loading && _rank != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: _RankBadge(
                  rank:           _rank!,
                  unlockedCount:  _unlockedCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AchievementsScreen(userId: widget.user.id),
                    ),
                  ).then((_) => _loadGroups()),
                ),
              ),

            const SizedBox(height: 20),

            // ── Corpo ────────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: Color(0xFF00E676), strokeWidth: 2))
                  : _groups.isEmpty
                      ? _buildEmptyState()
                      : _buildGroupList(),
            ),
          ],
        ),
      ),

      // ── FAB: Criar grupo ─────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateGroup,
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo grupo',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── Lista de grupos ────────────────────────────────────────────────────────
  Widget _buildGroupList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final group = _groups[i];
        return _GroupCard(
          group: group,
          onTap: () => _goToGroup(group),
          onDelete: () => _deleteGroup(group),
        );
      },
    );
  }

  // ── Estado vazio ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: const Icon(Icons.group_outlined,
                  color: Color(0xFF333333), size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Nenhum grupo ainda',
                style: TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Crie seu primeiro grupo\npelo botão abaixo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF555555),
                    fontSize: 14, height: 1.6)),
          ],
        ),
      ),
    );
  }
}

// ── Card de grupo ─────────────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final count = group.members.length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Row(
          children: [
            // Ícone do grupo
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.group_rounded,
                  color: Color(0xFF00E676), size: 22),
            ),
            const SizedBox(width: 14),
            // Nome e contagem
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    count == 0
                        ? 'Sem membros'
                        : '$count ${count == 1 ? "membro" : "membros"}',
                    style: const TextStyle(
                        color: Color(0xFF555555), fontSize: 13),
                  ),
                ],
              ),
            ),
            // Botão excluir
            IconButton(
              tooltip: 'Excluir grupo',
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFF444444), size: 20),
              onPressed: onDelete,
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF2A2A2A), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Card de total acumulado ───────────────────────────────────────────────────
class _AccumulatedCard extends StatelessWidget {
  final double total;
  const _AccumulatedCard({required this.total});

  // Formata valor sem pacote externo: "1.250,75"
  String _formatCurrency(double value) {
    final parts   = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final dec     = parts[1];

    // Insere pontos de milhar
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
            color: const Color(0xFF00E676).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.savings_outlined,
                color: Color(0xFF00E676), size: 22),
          ),
          const SizedBox(width: 14),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total acumulado',
                  style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatCurrency(total),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          // Badge "todos os meses"
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'histórico',
              style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card de streak ────────────────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  String get _label {
    if (streak == 0) return 'Comece a contribuir este mês!';
    if (streak == 1) return '1 mês consecutivo';
    return '$streak meses consecutivos';
  }

  String get _emoji {
    if (streak == 0) return '💤';
    if (streak < 3)  return '🔥';
    if (streak < 6)  return '🔥🔥';
    return '🔥🔥🔥';
  }

  Color get _color {
    if (streak == 0) return const Color(0xFF444444);
    if (streak < 3)  return const Color(0xFFFF6B35);
    if (streak < 6)  return const Color(0xFFFF4500);
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
          // Ícone
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sequência',
                  style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  _label,
                  style: TextStyle(
                      color: streak > 0 ? Colors.white : const Color(0xFF555555),
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // Número em destaque
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
                    fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Badge de patente na HomeScreen ───────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  final RankModel rank;
  final int       unlockedCount;
  final VoidCallback onTap;

  const _RankBadge({
    required this.rank,
    required this.unlockedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(rank.colorValue);
    final total = AchievementModel.all.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Text(rank.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rank.title,
                      style: TextStyle(color: color, fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Text('$unlockedCount/$total conquistas',
                      style: const TextStyle(color: Color(0xFF666666),
                          fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF444444), size: 20),
          ],
        ),
      ),
    );
  }
}
