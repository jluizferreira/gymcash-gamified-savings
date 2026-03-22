// lib/screens/group_screen.dart
//
// Exibe o ranking de contribuições do mês e gerencia membros.

import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../models/contribution_model.dart';
import '../models/ranking_entry.dart';
import '../services/local_storage_service.dart';
import 'add_member_screen.dart';
import 'add_contribution_screen.dart';
import 'history_screen.dart';
import '../services/ranking_service.dart';
import '../widgets/rename_group_dialog.dart';

class GroupScreen extends StatefulWidget {
  final GroupModel group;
  final UserModel currentUser;

  const GroupScreen({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  final _storage = LocalStorageService();
  late GroupModel _group;
  List<RankingEntry> _ranking = [];
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _tabs  = TabController(length: 3, vsync: this);
    _checkMonthClose();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Carrega grupo atualizado + contribuições e monta ranking ──────────────
  Future<void> _load() async {
    // Recarrega o grupo do storage para pegar membros atualizados
    final groups = await _storage.getGroups();
    final fresh  = groups.firstWhere(
      (g) => g.id == _group.id,
      orElse: () => _group,
    );

    final contribs = await _storage.getGroupContributions(
        groupId: fresh.id);

    // Monta ranking: 1 entrada por membro
    final entries = fresh.members.map((member) {
      ContributionModel? contrib;
      try {
        contrib = contribs.firstWhere((c) => c.userId == member.id);
      } catch (_) {
        contrib = null;
      }
      return RankingEntry(member: member, contribution: contrib);
    }).toList();

    // Ordena: maior progresso primeiro; empate → nome
    entries.sort((a, b) {
      final diff = b.progress.compareTo(a.progress);
      return diff != 0 ? diff : a.member.name.compareTo(b.member.name);
    });

    if (mounted) {
      setState(() {
        _group   = fresh;
        _ranking = entries;
        _loading = false;
      });
    }
  }

  // ── Verifica fechamento de meses ao entrar na tela ───────────────────────
  Future<void> _checkMonthClose() async {
    final closed = await RankingService(_storage).checkAndCloseMonths(_group);
    if (closed && mounted) _load(); // recarrega se fechou algum mês
  }

  // ── Abre tela de histórico ────────────────────────────────────────────────
  Future<void> _goToHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          groupId:   _group.id,
          groupName: _group.name,
        ),
      ),
    );
  }

  // ── Abre tela de contribuição do usuário atual ────────────────────────────
  Future<void> _goToContribution() async {
    final existing = await _storage.getContribution(
      userId:  widget.currentUser.id,
      groupId: _group.id,
    );
    if (!mounted) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddContributionScreen(
          groupId:     _group.id,
          currentUser: widget.currentUser,
          existing:    existing,
        ),
      ),
    );
    if (changed == true) _load();
  }

  // ── Abre tela de adicionar membro ─────────────────────────────────────────
  Future<void> _goToAddMember() async {
    final updated = await Navigator.of(context).push<GroupModel>(
      MaterialPageRoute(
          builder: (_) => AddMemberScreen(groupId: _group.id)),
    );
    if (updated != null && mounted) {
      setState(() => _group = updated);
      _load();
    }
  }

  // ── Remove membro ─────────────────────────────────────────────────────────
  Future<void> _removeMember(String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover membro?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('$memberName será removido do grupo.',
            style:
                const TextStyle(color: Color(0xFF888888), height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF555555)))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remover',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _storage.removeMember(_group.id, memberId);
    _load();
  }

  /// Abre diálogo de renomeação e persiste via gateway; erros em SnackBar.
  Future<void> _renameGroup() async {
    final newName = await showRenameGroupDialog(
      context,
      initialName: _group.name,
    );
    if (newName == null || !mounted) return;

    try {
      final updated = await _storage.renameGroup(_group.id, newName);
      if (!mounted) return;
      setState(() => _group = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nome do grupo atualizado.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Não foi possível salvar o nome. Tente novamente.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2D1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.35)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _group.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Renomear grupo',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _renameGroup,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: const Color(0xFF555555),
          indicatorColor: const Color(0xFF00E676),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Ranking'),
            Tab(text: 'Membros'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF00E676), strokeWidth: 2))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildRankingTab(),
                _buildMembersTab(),
                _buildHistoryTab(),
              ],
            ),

      // FAB muda conforme a aba
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (_, __) {
          if (_tabs.index == 0) {
            return FloatingActionButton.extended(
              onPressed: _goToContribution,
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.savings_outlined),
              label: const Text('Minha contribuição',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            );
          }
          if (_tabs.index == 1) {
            return FloatingActionButton.extended(
              onPressed: _goToAddMember,
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Adicionar membro',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            );
          }
          // Aba histórico — sem FAB
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ABA: RANKING
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildRankingTab() {
    if (_ranking.isEmpty) {
      return _buildEmptyRanking();
    }

    final month = ContributionModel.currentMonth();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: _ranking.length + 1, // +1 para o header do mês
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFF00E676), size: 16),
              const SizedBox(width: 6),
              Text('Ranking de $month',
                  style: const TextStyle(
                      color: Color(0xFF555555), fontSize: 13)),
            ]),
          );
        }
        final pos   = i - 1;
        final entry = _ranking[pos];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RankingCard(
            position:    pos + 1,
            entry:       entry,
            isCurrentUser: entry.member.id == widget.currentUser.id,
          ),
        );
      },
    );
  }

  Widget _buildEmptyRanking() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Color(0xFF333333), size: 32),
          ),
          const SizedBox(height: 14),
          const Text('Sem membros no grupo',
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
              'Adicione membros e registre\nsuas contribuições.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF555555), fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ABA: MEMBROS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMembersTab() {
    final members = _group.members;
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: Color(0xFF333333), size: 32),
            ),
            const SizedBox(height: 14),
            const Text('Sem membros',
                style: TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = members[i];
        return _MemberTile(
          member: m,
          isCurrentUser: m.id == widget.currentUser.id,
          onRemove: () => _removeMember(m.id, m.name),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ABA: HISTÓRICO
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHistoryTab() {
    return FutureBuilder(
      future: _storage.getMonthlyResults(groupId: _group.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF00E676), strokeWidth: 2));
        }
        final results = snapshot.data!;
        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF222222)),
                    ),
                    child: const Icon(Icons.history_rounded,
                        color: Color(0xFF333333), size: 32),
                  ),
                  const SizedBox(height: 14),
                  const Text('Nenhum mês fechado ainda',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text(
                    'O ranking é salvo automaticamente\nquando o mês vira.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF555555),
                        fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = results[i];
            return GestureDetector(
              onTap: () => _goToHistory(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: r.winnerId != null
                        ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                        : const Color(0xFF1E1E1E),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: r.winnerId != null
                            ? const Color(0xFFFFD700).withValues(alpha: 0.1)
                            : const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        r.winnerId != null
                            ? Icons.emoji_events_rounded
                            : Icons.remove_circle_outline_rounded,
                        color: r.winnerId != null
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF444444),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.monthLabel,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          if (r.winnerName != null)
                            Text('🥇 ${r.winnerName}',
                                style: const TextStyle(
                                    color: Color(0xFFFFD700), fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF333333), size: 18),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ════════════════════════════════════════════════════════════════════════════

// ── Card do ranking ────────────────────────────────────────────────────────
class _RankingCard extends StatelessWidget {
  final int position;
  final RankingEntry entry;
  final bool isCurrentUser;

  const _RankingCard({
    required this.position,
    required this.entry,
    required this.isCurrentUser,
  });

  Color get _positionColor {
    switch (position) {
      case 1: return const Color(0xFFFFD700); // ouro
      case 2: return const Color(0xFFC0C0C0); // prata
      case 3: return const Color(0xFFCD7F32); // bronze
      default: return const Color(0xFF444444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = entry.progress;
    final hasData  = entry.contribution != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF00E676).withValues(alpha: 0.05)
            : const Color(0xFF161616),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFF00E676).withValues(alpha: 0.3)
              : const Color(0xFF1E1E1E),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Posição
              SizedBox(
                width: 32,
                child: Text(
                  position <= 3 ? _medal(position) : '$position°',
                  style: TextStyle(
                    fontSize: position <= 3 ? 20 : 14,
                    color: _positionColor,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    const Color(0xFF00E676).withValues(alpha: 0.1),
                child: Text(
                  entry.member.initials,
                  style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),

              // Nome
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.member.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('você',
                                style: TextStyle(
                                    color: Color(0xFF00E676),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    if (!hasData)
                      const Text('Sem contribuição',
                          style: TextStyle(
                              color: Color(0xFF444444), fontSize: 12)),
                  ],
                ),
              ),

              // Porcentagem
              Text(
                entry.progressLabel,
                style: TextStyle(
                  color: entry.goalReached
                      ? const Color(0xFF00E676)
                      : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Barra de progresso
          if (hasData && entry.hasGoal) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFF222222),
                valueColor: AlwaysStoppedAnimation<Color>(
                  entry.goalReached
                      ? const Color(0xFF00E676)
                      : const Color(0xFF00B8D4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _medal(int pos) {
    switch (pos) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }
}

// ── Tile de membro (aba Membros) ──────────────────────────────────────────────
class _MemberTile extends StatelessWidget {
  final UserModel member;
  final bool isCurrentUser;
  final VoidCallback onRemove;

  const _MemberTile({
    required this.member,
    required this.isCurrentUser,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                const Color(0xFF00E676).withValues(alpha: 0.1),
            child: Text(member.initials,
                style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Text(member.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('você',
                        style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
          if (!isCurrentUser)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded,
                  color: Color(0xFF444444), size: 20),
              onPressed: onRemove,
              tooltip: 'Remover',
            ),
        ],
      ),
    );
  }
}
