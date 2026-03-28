// lib/screens/home_screen.dart
//
// Lista os grupos do usuário com ordenação configurável (mais recentes / A→Z).

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/local_storage_service.dart';
import '../services/sort_service.dart';
import '../services/streak_service.dart';
import '../services/achievement_service.dart';
import '../models/rank_model.dart';
import '../models/achievement_model.dart';
import 'achievements_screen.dart';
import 'onboarding_screen.dart';
import 'create_group_screen.dart';
import 'group_screen.dart';
import 'profile_screen.dart';
import '../views/transaction_list_view.dart';
import '../widgets/achievement_unlock_toast.dart';
import '../widgets/rename_group_dialog.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage     = LocalStorageService();
  final _sortService = SortService();

  List<GroupModel> _groups          = [];
  List<GroupModel> _groupsSorted    = [];
  double           _totalAccumulated = 0.0;
  int              _streak           = 0;
  RankModel?       _rank;
  int              _unlockedCount    = 0;
  bool             _loading          = true;
  String?          _loadError;
  GroupSortOrder   _sortOrder        = GroupSortOrder.recent;

  @override
  void initState() {
    super.initState();
    _loadSortOrder().then((_) => _loadGroups());
  }

  Future<void> _loadSortOrder() async {
    final order = await _sortService.loadOrder();
    if (mounted) setState(() => _sortOrder = order);
  }

  void _applySorting() {
    _groupsSorted = _sortService.sort(_groups, _sortOrder);
  }

  Future<void> _toggleSort() async {
    final next = _sortOrder == GroupSortOrder.recent
        ? GroupSortOrder.alphabetical
        : GroupSortOrder.recent;
    await _sortService.saveOrder(next);
    setState(() {
      _sortOrder = next;
      _applySorting();
    });
  }

  Future<void> _loadGroups() async {
    if (mounted) {
      setState(() {
        _loadError = null;
        if (_groups.isEmpty) _loading = true;
      });
    }
    try {
      final groups         = await _storage.getGroups();
      final total          = await _storage.getTotalAccumulated(widget.user.id);
      final streak         = await StreakService(_storage).calculateStreak(widget.user.id);
      final newlyUnlocked  = await AchievementService(_storage).checkAndUnlock(widget.user.id);
      final unlockedCount  = await AchievementService(_storage).unlockedCount(widget.user.id);
      final rank           = RankModel.fromTotal(total);

      if (!mounted) return;
      setState(() {
        _groups           = groups;
        _totalAccumulated = total;
        _streak           = streak;
        _rank             = rank;
        _unlockedCount    = unlockedCount;
        _loading          = false;
        _loadError        = null;
        _applySorting();
      });

      if (newlyUnlocked.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          AchievementUnlockToast.showSequence(context, newlyUnlocked);
        });
      }
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _loadError = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading   = false;
        _loadError =
            'Não foi possível carregar seus dados. Toque abaixo para tentar de novo.';
      });
    }
  }

  Future<void> _goToCreateGroup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(currentUser: widget.user),
      ),
    );
    _loadGroups();
  }

  Future<void> _goToGroup(GroupModel group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupScreen(group: group, currentUser: widget.user),
      ),
    );
    _loadGroups();
  }

  Future<void> _resetUser() async {
    await _storage.clearUser();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

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
                  style: TextStyle(color: Color(0xFF555555)))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _storage.deleteGroup(group.id);
    _loadGroups();
  }

  Future<void> _renameGroup(GroupModel group) async {
    final newName = await showRenameGroupDialog(context, initialName: group.name);
    if (newName == null || !mounted) return;
    try {
      await _storage.renameGroup(group.id, newName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nome do grupo atualizado.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _loadGroups();
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2D1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
          ),
        ),
      );
    }
  }

  static const Color _extratoBlue = Color(0xFF448AFF);

  Future<void> _openExtrato() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TransactionListView(user: widget.user),
      ),
    );
    if (mounted) _loadGroups();
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(user: widget.user),
      ),
    );
    if (mounted) _loadGroups();
  }

  void _showResetDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Trocar nome?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
            'Isso vai apagar o nome salvo e voltar à tela inicial.',
            style: TextStyle(color: Color(0xFF888888), height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF555555)))),
          TextButton(
              onPressed: () { Navigator.of(ctx).pop(); _resetUser(); },
              child: const Text('Confirmar',
                  style: TextStyle(
                      color: Color(0xFF00E676),
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
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openProfile,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 0),
                          child: Row(
                            children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF00E676)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Center(
                                  child: Text(widget.user.initials,
                                      style: const TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Olá, ${widget.user.firstName}!',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const Text('Toque para ver o perfil',
                                        style: TextStyle(
                                            color: Color(0xFF555555),
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Color(0xFF333333), size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Extrato',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                            minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.receipt_long_outlined,
                            color: _extratoBlue),
                        onPressed: _openExtrato,
                      ),
                      IconButton(
                        tooltip: 'Trocar nome',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                            minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.logout_rounded,
                            color: Color(0xFF444444)),
                        onPressed: _showResetDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (!_loading) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: _AccumulatedCard(total: _totalAccumulated),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: _StreakCard(streak: _streak),
              ),
              const SizedBox(height: 10),
              if (_rank != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: _RankBadge(
                    rank:          _rank!,
                    unlockedCount: _unlockedCount,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                          builder: (_) =>
                              AchievementsScreen(userId: widget.user.id),
                        ))
                        .then((_) => _loadGroups()),
                  ),
                ),
              const SizedBox(height: 20),
            ],

            // ── Cabeçalho da lista de grupos com botão de ordenação ──────────
            if (!_loading && _groups.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 20, 8),
                child: Row(
                  children: [
                    const Text(
                      'Grupos',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Botão de ordenação
                    GestureDetector(
                      onTap: _toggleSort,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sortOrder == GroupSortOrder.alphabetical
                                  ? Icons.sort_by_alpha_rounded
                                  : Icons.access_time_rounded,
                              color: const Color(0xFF00E676),
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _sortOrder == GroupSortOrder.alphabetical
                                  ? 'A→Z'
                                  : 'Recentes',
                              style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_loading && _loadError != null && _groups.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Material(
                  color: const Color(0xFF2A1F1F),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orangeAccent.withValues(alpha: 0.9),
                            size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_loadError!,
                              style: const TextStyle(
                                  color: Color(0xFFCCCCCC),
                                  fontSize: 13,
                                  height: 1.35)),
                        ),
                        TextButton(
                          onPressed: _loadGroups,
                          child: const Text('Atualizar',
                              style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Corpo ────────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00E676), strokeWidth: 2))
                  : _loadError != null && _groups.isEmpty
                      ? _buildHomeLoadError()
                      : _groups.isEmpty
                          ? _buildEmptyState()
                          : _buildGroupList(),
            ),
          ],
        ),
      ),
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

  Widget _buildHomeLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56,
                color: Colors.redAccent.withValues(alpha: 0.65)),
            const SizedBox(height: 20),
            Text(_loadError ?? 'Erro ao carregar.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFAAAAAA), fontSize: 15, height: 1.5)),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _loadGroups,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount:        _groupsSorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final group = _groupsSorted[i];
        return _GroupCard(
          group:    group,
          onTap:    () => _goToGroup(group),
          onRename: () => _renameGroup(group),
          onDelete: () => _deleteGroup(group),
        );
      },
    );
  }

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
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Crie seu primeiro grupo\npelo botão abaixo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF555555), fontSize: 14, height: 1.6)),
          ],
        ),
      ),
    );
  }
}

// ── Card de grupo ─────────────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final GroupModel   group;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onRename,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
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
            PopupMenuButton<String>(
              tooltip: 'Opções do grupo',
              icon: const Icon(Icons.more_vert_rounded,
                  color: Color(0xFF555555), size: 22),
              color: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF2A2A2A)),
              ),
              offset: const Offset(0, 40),
              onSelected: (value) {
                if (value == 'rename') onRename();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem<String>(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          color: Color(0xFF00E676), size: 20),
                      SizedBox(width: 12),
                      Text('Renomear',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent.withValues(alpha: 0.9),
                          size: 20),
                      const SizedBox(width: 12),
                      Text('Excluir grupo',
                          style: TextStyle(
                              color: Colors.redAccent.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
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

  String _formatCurrency(double value) {
    final parts   = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final dec     = parts[1];
    final buffer  = StringBuffer();
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
          end:   Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total acumulado',
                    style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(_formatCurrency(total),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('histórico',
                style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
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
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(_emoji,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sequência',
                    style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(_label,
                    style: TextStyle(
                        color: streak > 0
                            ? Colors.white
                            : const Color(0xFF555555),
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (streak > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$streak',
                  style: TextStyle(
                      color: _color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

// ── Badge de patente ──────────────────────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  final RankModel    rank;
  final int          unlockedCount;
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Text('$unlockedCount/$total conquistas',
                      style: const TextStyle(
                          color: Color(0xFF666666), fontSize: 12)),
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
