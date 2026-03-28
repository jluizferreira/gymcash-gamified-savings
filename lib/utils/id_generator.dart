// lib/utils/id_generator.dart
//
// Gerador de IDs locais robusto.
//
// Problema com DateTime.now().microsecondsSinceEpoch.toString():
//   Operações muito rápidas (ex: criar grupo + adicionar membro em sequência)
//   podem rodar no mesmo microssegundo, gerando IDs idênticos.
//
// Solução: timestamp em microsegundos + contador atômico por processo.
//   Formato: "<microseconds>_<counter>"
//   Ex.: "1709123456789123_0", "1709123456789123_1"
//
//   - Unicidade garantida dentro do processo (contador nunca repete)
//   - Compatível com string IDs do Firestore na migração v2.0
//   - Zero dependências externas

class IdGenerator {
  IdGenerator._();

  static int _counter = 0;

  /// Gera um ID único combinando timestamp e contador de processo.
  static String newId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    return '${ts}_${_counter++}';
  }
}
