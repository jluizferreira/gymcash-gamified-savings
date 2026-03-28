// lib/views/transaction_list_view.dart
//
// Lista contribuições do usuário com estados de carregamento e vazio.
// Erros do armazenamento exibem SnackBar em português.

import 'package:flutter/material.dart';

import '../models/contribution_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

/// Paleta interna da tela de extrato — Deep Black & Electric Blue.
abstract final class _TxColors {
  static const background = Color(0xFF0A0A0A);
  static const surface    = Color(0xFF161616);
  static const border     = Color(0xFF222222);
  static const accent     = Color(0xFF448AFF);
  static const accentDim  = Color(0xFF2962FF);
  static const textMuted  = Color(0xFF555555);
  static const textSoft   = Color(0xFF888888);
}

/// Tela com lista de contribuições do [user], persistidas via [LocalStorageService].
class TransactionListView extends StatefulWidget {
  const TransactionListView({super.key, required this.user});

  final UserModel user;

  @override
  State<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<TransactionListView> {
  final LocalStorageService _storage = LocalStorageService();

  List<ContributionModel> _transactions = [];
  Map<String, String> _groupNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);
    try {
      final all    = await _storage.getContributions();
      final groups = await _storage.getGroups();
      final names  = {for (final g in groups) g.id: g.name};
      final mine   = all
          .where((c) => c.userId == widget.user.id)
          .toList()
        ..sort((a, b) => b.month.compareTo(a.month));

      if (!mounted) return;
      setState(() {
        _transactions = mine;
        _groupNames   = names;
        _loading      = false;
      });
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      setState(() {
        _transactions = [];
        _groupNames   = {};
        _loading      = false;
      });
      _showSnack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _transactions = [];
        _loading      = false;
      });
      _showSnack(
        'Não foi possível carregar as transações. Tente novamente.',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFF1B1B1B) : _TxColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? Colors.redAccent.withValues(alpha: 0.5)
                : _TxColors.accent.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TxColors.background,
      appBar: AppBar(
        backgroundColor: _TxColors.background,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Extrato',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _TxColors.border),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _transactions.isEmpty
                ? _buildEmptyState()
                : _buildList(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
                color: _TxColors.accent, strokeWidth: 2.5),
          ),
          SizedBox(height: 20),
          Text(
            'Carregando extrato…',
            style: TextStyle(color: _TxColors.textSoft, fontSize: 14),
          ),
        ],
      ),
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _TxColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _TxColors.border),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: _TxColors.accent.withValues(alpha: 0.35),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma contribuição ainda',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quando você registrar contribuições\nnos grupos, elas aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _TxColors.textMuted, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: _TxColors.accent,
      backgroundColor: _TxColors.surface,
      onRefresh: _loadTransactions,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        itemCount: _transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final tx        = _transactions[index];
          final groupName = _groupNames[tx.groupId] ?? 'Grupo';
          return _TransactionTile(contribution: tx, groupName: groupName);
        },
      ),
    );
  }
}

// ── Tile de contribuição ──────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.contribution,
    required this.groupName,
  });

  final ContributionModel contribution;
  final String groupName;

  String _money(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final reached = contribution.progress >= 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _TxColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reached
              ? const Color(0xFF00E676).withValues(alpha: 0.25)
              : _TxColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _TxColors.accentDim.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _TxColors.accent.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.trending_up_rounded,
                color: _TxColors.accent, size: 22),
          ),
          const SizedBox(width: 14),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        groupName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (reached)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '🎯 meta',
                          style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  contribution.currentMonthLabel,
                  style: const TextStyle(
                      color: _TxColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      _money(contribution.amount),
                      style: const TextStyle(
                          color: _TxColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                    Text(
                      '  ·  meta ${_money(contribution.goal)}',
                      style: const TextStyle(
                          color: _TxColors.textSoft, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Barra de progresso
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: contribution.progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: const Color(0xFF222222),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      reached
                          ? const Color(0xFF00E676)
                          : _TxColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Progresso: ${contribution.progressLabel}',
                  style: const TextStyle(
                      color: _TxColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
