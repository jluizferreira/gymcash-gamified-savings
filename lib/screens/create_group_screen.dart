// lib/screens/create_group_screen.dart
//
// Tela para criação de um novo grupo.
// O usuário atual é adicionado automaticamente como primeiro membro.

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

class CreateGroupScreen extends StatefulWidget {
  // Recebe o usuário logado para adicioná-lo ao grupo na criação
  final UserModel currentUser;

  const CreateGroupScreen({super.key, required this.currentUser});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _controller = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  final _storage    = LocalStorageService();
  bool _saving      = false;

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Passa o usuário atual → ele entra como membro automaticamente
    await _storage.createGroup(
      _controller.text.trim(),
      creator: widget.currentUser,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Novo grupo',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nome do grupo',
                    style: TextStyle(color: Color(0xFF888888),
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),

                // Input nome
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                  decoration: InputDecoration(
                    hintText: 'Ex: Turma A, Musculação...',
                    hintStyle: const TextStyle(color: Color(0xFF444444)),
                    filled: true,
                    fillColor: const Color(0xFF161616),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Color(0xFF222222))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Color(0xFF222222))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF00E676), width: 2)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Colors.redAccent, width: 2)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Colors.redAccent, width: 2)),
                  ),
                  onFieldSubmitted: (_) => _create(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite o nome do grupo';
                    }
                    if (value.trim().length < 2) return 'Nome muito curto';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Botão criar
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _create,
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
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2.5))
                        : const Text('Criar grupo',
                            style: TextStyle(fontSize: 17,
                                fontWeight: FontWeight.w700)),
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
