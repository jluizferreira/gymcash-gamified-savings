// lib/widgets/evolution_chart.dart
//
// Gráfico de barras da evolução mensal do acumulado.
// Implementado com CustomPainter — zero dependências externas.
// Exibe os últimos 12 meses com contribuição, destacando o mês atual.

import 'package:flutter/material.dart';
import '../models/contribution_model.dart';

/// Agrega dados de um mês para exibição no gráfico.
class _MonthData {
  final String month;   // "YYYY-MM"
  final String label;   // "Jan", "Fev", ...
  final double amount;
  final double goal;
  final bool isCurrent;

  const _MonthData({
    required this.month,
    required this.label,
    required this.amount,
    required this.goal,
    required this.isCurrent,
  });

  double get progress => goal > 0 ? (amount / goal).clamp(0.0, 1.5) : 0.0;
  bool get goalReached => goal > 0 && amount >= goal;
}

/// Gráfico de barras de evolução mensal.
///
/// Recebe [contributions] de um único usuário (todos os grupos).
/// Agrupa por mês, soma os amounts e exibe os últimos [maxMonths] meses.
class EvolutionChart extends StatefulWidget {
  const EvolutionChart({
    super.key,
    required this.contributions,
    this.maxMonths = 12,
  });

  final List<ContributionModel> contributions;
  final int maxMonths;

  @override
  State<EvolutionChart> createState() => _EvolutionChartState();
}

class _EvolutionChartState extends State<EvolutionChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_MonthData> _buildData() {
    final currentMonth = _currentMonth();

    // Agrupa por mês: soma amounts e usa a última goal registrada
    final Map<String, double> amountByMonth  = {};
    final Map<String, double> goalByMonth    = {};

    for (final c in widget.contributions) {
      amountByMonth[c.month] =
          (amountByMonth[c.month] ?? 0.0) + c.amount;
      goalByMonth[c.month] = c.goal; // última goal do mês
    }

    // Ordena meses e pega os últimos [maxMonths]
    final months = amountByMonth.keys.toList()..sort();
    final recent = months.length > widget.maxMonths
        ? months.sublist(months.length - widget.maxMonths)
        : months;

    return recent.map((m) => _MonthData(
          month:     m,
          label:     _monthLabel(m),
          amount:    amountByMonth[m] ?? 0,
          goal:      goalByMonth[m]   ?? 0,
          isCurrent: m == currentMonth,
        )).toList();
  }

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _monthLabel(String month) {
    final parts = month.split('-');
    if (parts.length < 2) return month;
    const labels = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    final m = int.tryParse(parts[1]) ?? 1;
    return labels[(m - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    final data = _buildData();

    if (data.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: const Center(
          child: Text(
            'Nenhuma contribuição ainda',
            style: TextStyle(color: Color(0xFF555555), fontSize: 13),
          ),
        ),
      );
    }

    final selected = _selectedIndex != null && _selectedIndex! < data.length
        ? data[_selectedIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + tooltip do selecionado
          Row(
            children: [
              const Text(
                'Evolução mensal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (selected != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _TooltipChip(data: selected, key: ValueKey(selected.month)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Gráfico
          SizedBox(
            height: 140,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (_, __) => GestureDetector(
                onTapDown: (details) => _onTap(details, data),
                onTapUp: (_) {},
                child: CustomPaint(
                  size: const Size(double.infinity, 140),
                  painter: _BarChartPainter(
                    data:          data,
                    progress:      _animation.value,
                    selectedIndex: _selectedIndex,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(TapDownDetails details, List<_MonthData> data) {
    if (data.isEmpty) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localX   = details.localPosition.dx - 16; // padding
    final barWidth = (renderBox.size.width - 32) / data.length;
    final index    = (localX / barWidth).floor().clamp(0, data.length - 1);

    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
  }
}

// ── Tooltip chip ─────────────────────────────────────────────────────────────
class _TooltipChip extends StatelessWidget {
  const _TooltipChip({super.key, required this.data});
  final _MonthData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.3)),
      ),
      child: Text(
        '${data.label} · R\$ ${data.amount.toStringAsFixed(0)} · ${data.progressLabel}',
        style: const TextStyle(
          color: Color(0xFF00E676),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

extension on _MonthData {
  String get progressLabel {
    if (goal <= 0) return '—';
    return '${((amount / goal) * 100).toStringAsFixed(0)}%';
  }
}

// ── CustomPainter ─────────────────────────────────────────────────────────────
class _BarChartPainter extends CustomPainter {
  final List<_MonthData> data;
  final double progress;   // 0.0 → 1.0 da animação
  final int? selectedIndex;

  const _BarChartPainter({
    required this.data,
    required this.progress,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const bottomPad = 20.0; // espaço para labels
    const topPad    = 8.0;
    final chartH    = size.height - bottomPad - topPad;
    final barW      = size.width / data.length;
    const barGap    = 4.0;

    final maxAmount = data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    if (maxAmount <= 0) return;

    final paintBg   = Paint()..color = const Color(0xFF222222);
    final paintBar  = Paint()..style = PaintingStyle.fill;
    final paintGoal = Paint()
      ..color       = const Color(0xFF555555)
      ..strokeWidth = 1
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    for (int i = 0; i < data.length; i++) {
      final d       = data[i];
      final x       = i * barW + barGap / 2;
      final w       = barW - barGap;
      final isSelected = selectedIndex == i;

      // Fundo da barra
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, topPad, w, chartH),
        const Radius.circular(4),
      );
      canvas.drawRRect(bgRect, paintBg);

      // Barra de amount (animada)
      final barH = (d.amount / maxAmount) * chartH * progress;
      if (barH > 0) {
        final barColor = d.goalReached
            ? const Color(0xFF00E676)
            : d.isCurrent
                ? const Color(0xFF448AFF)
                : const Color(0xFF2D4A7A);

        paintBar.color = isSelected
            ? barColor.withValues(alpha: 1.0)
            : barColor.withValues(alpha: d.isCurrent ? 0.9 : 0.65);

        // Gradiente sutil
        paintBar.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            barColor.withValues(alpha: isSelected ? 1.0 : 0.75),
            barColor.withValues(alpha: isSelected ? 0.85 : 0.5),
          ],
        ).createShader(
          Rect.fromLTWH(x, topPad + chartH - barH, w, barH),
        );

        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, topPad + chartH - barH, w, barH),
          const Radius.circular(4),
        );
        canvas.drawRRect(barRect, paintBar);
      }

      // Linha de goal (tracejada)
      if (d.goal > 0 && d.goal <= maxAmount) {
        final goalY = topPad + chartH - (d.goal / maxAmount) * chartH;
        _drawDashedLine(canvas, x, goalY, x + w, goalY, paintGoal);
      }

      // Label do mês
      final labelStyle = TextStyle(
        color: d.isCurrent
            ? const Color(0xFF00E676)
            : isSelected
                ? Colors.white
                : const Color(0xFF555555),
        fontSize: 9,
        fontWeight: d.isCurrent || isSelected
            ? FontWeight.w700
            : FontWeight.w400,
      );
      final tp = TextPainter(
        text:      TextSpan(text: d.label, style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w);
      tp.paint(
        canvas,
        Offset(x + (w - tp.width) / 2, size.height - bottomPad + 4),
      );
    }
  }

  void _drawDashedLine(
      Canvas canvas, double x1, double y, double x2, double _, Paint paint) {
    const dashW = 3.0;
    const gapW  = 3.0;
    double x    = x1;
    while (x < x2) {
      canvas.drawLine(Offset(x, y), Offset((x + dashW).clamp(x1, x2), y), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.progress != progress ||
      old.selectedIndex != selectedIndex ||
      old.data != data;
}
