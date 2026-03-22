// lib/screens/add_contribution_screen.dart
//
// Permite ao usuário registrar ou editar o valor guardado no mês atual
// e definir sua meta individual para aquele grupo.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/contribution_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/streak_service.dart';
import '../services/achievement_service.dart';
import '../widgets/achievement_unlock_toast.dart';
import '../widgets/goal_reached_dialog.dart';

class AddContributionScreen extends StatefulWidget {
  final String groupId;
  final UserModel currentUser;
  final ContributionModel? existing; // não-nulo = modo edição

  const AddContributionScreen({
    super.key,
    required this.groupId,
    required this.currentUser,
    this.existing,
  });

  @override
  State<AddContributionScreen> createState() => _AddContributionScreenState();
}

class _AddContributionScreenState extends State<AddContributionScreen> {
  final _amountController = TextEditingController();
  final _goalController   = TextEditingController();
  final _formKey          = GlobalKey<FormState>();
  final _storage          = LocalStorageService();
  bool _saving            = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Pré-preenche no modo edição
    if (_isEditing) {
      _amountController.text =
          widget.existing!.amount.toStringAsFixed(2);
      _goalController.text =
          widget.existing!.goal.toStringAsFixed(2);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final amount = double.parse(
          _amountController.text.trim().replaceAll(',', '.'));
      final goal = double.parse(
          _goalController.text.trim().replaceAll(',', '.'));

      final saveResult = await _storage.saveContribution(
        userId: widget.currentUser.id,
        groupId: widget.groupId,
        amount: amount,
        goal: goal,
      );

      if (!mounted) return;
      if (saveResult.goalJustReached) {
        HapticFeedback.heavyImpact();
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.65),
          builder: (ctx) => const GoalReachedDialog(),
        );
      }

      await StreakService(_storage).calculateStreak(widget.currentUser.id);
      final newlyUnlocked =
          await AchievementService(_storage).checkAndUnlock(widget.currentUser.id);

      if (!mounted) return;
      if (newlyUnlocked.isNotEmpty) {
        AchievementUnlockToast.showSequence(context, newlyUnlocked);
      }
      Navigator.of(context).pop(true);
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
            'Não foi possível salvar a contribuição. Tente novamente.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2D1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.35)),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final month = ContributionModel.currentMonth();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEditing ? 'Editar contribuição' : 'Nova contribuição',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mês de referência
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF222222)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined,
                          color: Color(0xFF00E676), size: 16),
                      const SizedBox(width: 8),
                      Text('Mês de referência: $month',
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 13)),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Campo: valor guardado
                _FieldLabel(label: 'Valor guardado este mês'),
                const SizedBox(height: 8),
                _CurrencyField(
                  controller: _amountController,
                  hint: '0,00',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o valor';
                    }
                    final parsed =
                        double.tryParse(v.trim().replaceAll(',', '.'));
                    if (parsed == null || parsed < 0) {
                      return 'Valor inválido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Campo: meta
                _FieldLabel(label: 'Meta individual do mês'),
                const SizedBox(height: 8),
                _CurrencyField(
                  controller: _goalController,
                  hint: '0,00',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe a meta';
                    }
                    final parsed =
                        double.tryParse(v.trim().replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      return 'Meta deve ser maior que zero';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Botão salvar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          const Color(0xFF00E676).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2.5))
                        : Text(_isEditing ? 'Salvar alterações' : 'Registrar',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Label de campo ────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 13,
          fontWeight: FontWeight.w500));
}

// ── Input numérico com formatação ─────────────────────────────────────────────
class _CurrencyField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?) validator;

  const _CurrencyField({
    required this.controller,
    required this.hint,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      ],
      style: const TextStyle(color: Colors.white, fontSize: 18,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF444444)),
        filled: true,
        fillColor: const Color(0xFF161616),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF222222))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF222222))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF00E676), width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 2)),
      ),
      validator: validator,
    );
  }
}
