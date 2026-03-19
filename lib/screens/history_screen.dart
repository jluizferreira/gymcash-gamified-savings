// lib/screens/history_screen.dart
//
// Exibe o histórico de meses fechados de um grupo,
// com vencedor e ranking completo de cada mês.

import 'package:flutter/material.dart';
import '../models/monthly_result_model.dart';
import '../services/local_storage_service.dart';

class HistoryScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const HistoryScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = LocalStorageService();
  List<MonthlyResultModel> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await _storage.getMonthlyResults(groupId: widget.groupId);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Histórico',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(widget.groupName,
                style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
          ],
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
                    color: Color(0xFF00E676), strokeWidth: 2))
            : _results.isEmpty
                ? _buildEmpty()
                : _buildList(),
      ),
    );
  }

  // ── Estado vazio ───────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: const Icon(Icons.history_rounded,
                  color: Color(0xFF333333), size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Nenhum mês fechado ainda',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'O ranking do mês é salvo\nautomaticamente quando o mês vira.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF555555), fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lista de meses fechados ────────────────────────────────────────────────
  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _MonthCard(result: _results[i]),
    );
  }
}

// ── Card expansível de um mês ──────────────────────────────────────────────────
class _MonthCard extends StatefulWidget {
  final MonthlyResultModel result;
  const _MonthCard({required this.result});

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final hasWinner = result.winnerId != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasWinner
              ? const Color(0xFFFFD700).withValues(alpha: 0.25)
              : const Color(0xFF1E1E1E),
        ),
      ),
      child: Column(
        children: [
          // ── Header do card ───────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Troféu / ícone
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hasWinner
                          ? const Color(0xFFFFD700).withValues(alpha: 0.1)
                          : const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasWinner
                          ? Icons.emoji_events_rounded
                          : Icons.remove_circle_outline_rounded,
                      color: hasWinner
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF444444),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Mês e vencedor
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(result.monthLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          hasWinner
                              ? '🥇 ${result.winnerName}'
                              : 'Sem vencedor',
                          style: TextStyle(
                            color: hasWinner
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF444444),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chevron animado
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF444444), size: 22),
                  ),
                ],
              ),
            ),
          ),

          // ── Ranking expandido ────────────────────────────────────────────
          if (_expanded) ...[
            const Divider(color: Color(0xFF1E1E1E), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: result.ranking.map((snap) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RankRow(snapshot: snap),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Linha do ranking no histórico ─────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final RankingSnapshot snapshot;
  const _RankRow({required this.snapshot});

  String _medal(int pos) {
    switch (pos) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$pos°';
    }
  }

  String get _initials {
    final parts = snapshot.userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = snapshot.position == 1;

    return Row(
      children: [
        // Posição
        SizedBox(
          width: 36,
          child: Text(
            _medal(snapshot.position),
            style: TextStyle(
              fontSize: snapshot.position <= 3 ? 18 : 13,
              color: const Color(0xFF555555),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),

        // Avatar
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.1),
          child: Text(_initials,
              style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),

        // Nome
        Expanded(
          child: Text(snapshot.userName,
              style: TextStyle(
                color: isFirst ? Colors.white : const Color(0xFFAAAAAA),
                fontSize: 14,
                fontWeight: isFirst ? FontWeight.w600 : FontWeight.w400,
              )),
        ),

        // Progresso
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: snapshot.progress >= 1.0
                ? const Color(0xFF00E676).withValues(alpha: 0.1)
                : const Color(0xFF222222),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            snapshot.progressLabel,
            style: TextStyle(
              color: snapshot.progress >= 1.0
                  ? const Color(0xFF00E676)
                  : const Color(0xFF666666),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
