# Arquitetura do Sistema

**GymCash** · Documento Técnico · v1.0

---

## Visão Geral

O GymCash adota uma arquitetura em camadas inspirada no padrão MVC, adaptada para o modelo reativo do Flutter. A separação de responsabilidades foi uma decisão deliberada desde o início do projeto, motivada por um objetivo claro: **a camada de persistência deve ser completamente substituível sem impacto nas camadas superiores**.

```
┌──────────────────────────────────────────────────────────────┐
│                        Screens                               │
│              Exibição, navegação e captura de input          │
│              Nenhuma lógica de negócio. Nenhum acesso        │
│              direto a dados.                                 │
└──────────────────────────┬───────────────────────────────────┘
                           │ instancia e chama
┌──────────────────────────▼───────────────────────────────────┐
│                        Services                              │
│     LocalStorageService · RankingService                     │
│     StreakService · AchievementService                       │
│                                                              │
│     Toda a lógica de negócio vive aqui.                      │
│     Recebem dependências por injeção — são testáveis.        │
└──────────────────────────┬───────────────────────────────────┘
                           │ opera sobre
┌──────────────────────────▼───────────────────────────────────┐
│                        Models                                │
│     UserModel · GroupModel · ContributionModel               │
│     MonthlyResultModel · AchievementModel · RankModel        │
│                                                              │
│     Estruturas de dados puras. Serialização JSON.            │
│     Sem dependências externas.                               │
└──────────────────────────┬───────────────────────────────────┘
                           │ persiste via gateway único
┌──────────────────────────▼───────────────────────────────────┐
│                   SharedPreferences                          │
│                   (substituível por Firebase)                │
└──────────────────────────────────────────────────────────────┘
```

---

## Camada de Models

Responsabilidade exclusiva: representar dados e converter entre objetos Dart e JSON.

| Modelo | Campos principais | Notas |
|---|---|---|
| `UserModel` | `id`, `name` | `id` gerado via timestamp em microsegundos |
| `GroupModel` | `id`, `name`, `members: List<UserModel>` | Lista de membros embutida no documento |
| `ContributionModel` | `id`, `userId`, `groupId`, `amount`, `goal`, `month` | `month` no formato `YYYY-MM`; unicidade por tripla `(userId, groupId, month)` |
| `MonthlyResultModel` | `id`, `groupId`, `month`, `ranking: List<RankingSnapshot>`, `winnerId` | Snapshot imutável; salvo no fechamento do mês |
| `RankingEntry` | `member`, `contribution?` | Objeto de composição para o ranking ao vivo; não persistido |
| `AchievementModel` | `id`, `title`, `description`, `emoji`, `isUnlocked`, `unlockedAt` | Definições canônicas em código; apenas estado salvo em disco |
| `RankModel` | `id`, `title`, `emoji`, `minAmount`, `colorValue` | Tabela de patentes com métodos `fromTotal()`, `nextRank()`, `progressToNext()` |

---

## Camada de Services

### LocalStorageService

O único ponto de contato com SharedPreferences em todo o projeto. Implementa o padrão **gateway**: qualquer outro service ou screen que precise ler ou gravar dados passa obrigatoriamente por aqui.

```dart
// Padrão de escrita em coleções: load → modify → save
final groups = await getGroups();      // 1. carrega toda a lista
groups[idx] = updatedGroup;            // 2. modifica em memória
await _saveGroups(groups);             // 3. serializa e persiste
```

**Interface pública relevante:**

```dart
// Usuário
Future<void>        saveUser(UserModel user)
Future<UserModel?>  getUser()

// Grupos
Future<List<GroupModel>>  getGroups()
Future<GroupModel>        createGroup(String name, {UserModel? creator})
Future<GroupModel>        addMember(String groupId, String memberName)
Future<void>              deleteGroup(String groupId)

// Contribuições
Future<ContributionModel>        saveContribution({userId, groupId, amount, goal})
Future<ContributionModel?>       getContribution({userId, groupId, month?})
Future<List<ContributionModel>>  getGroupContributions({groupId, month?})
Future<double>                   getTotalAccumulated(String userId)

// Resultados mensais
Future<List<MonthlyResultModel>>  getMonthlyResults({String? groupId})
Future<void>                      saveMonthlyResult(MonthlyResultModel result)
```

### RankingService

Responsável por detectar meses sem resultado fechado e calcular o snapshot histórico.

**Algoritmo de fechamento:**

```
1. Coleta todos os meses com contribuições no grupo
2. Filtra: meses ≠ mês atual E sem MonthlyResult salvo
3. Para cada mês pendente (ordem cronológica):
   a. Coleta contribuições do mês
   b. Calcula progresso por membro: amount / goal
   c. Ordena: maior progresso → empate por nome
   d. Identifica vencedor (amount > 0 obrigatório)
   e. Persiste MonthlyResult imutável
```

### StreakService

Calcula a sequência de meses consecutivos a partir das contribuições existentes. **Nenhum dado extra é armazenado** — o streak é sempre derivado.

```
Meses ativos: [2024-10, 2024-12, 2025-01, 2025-02, 2025-03]
                          ↑ lacuna (novembro ausente)

Percurso de trás para frente:
  03 ← 02: consecutivo ✓  streak = 2
  02 ← 01: consecutivo ✓  streak = 3
  01 ← 12: consecutivo ✓  streak = 4
  12 ← 10: NÃO consecutivo ✗  PARA

Resultado: streak = 4
```

### AchievementService

Avalia condições de desbloqueio e persiste o estado por `userId`. As definições das conquistas vivem em código (`AchievementModel.all`) — apenas o par `{isUnlocked, unlockedAt}` é salvo em disco por ID de conquista.

---

## Armazenamento Local

### Chaves SharedPreferences

| Chave | Tipo salvo | Conteúdo |
|---|---|---|
| `user_name` | `String` | Nome do usuário |
| `user_id` | `String` | ID gerado no onboarding |
| `groups` | `String (JSON Array)` | Lista completa de `GroupModel` |
| `contributions` | `String (JSON Array)` | Lista completa de `ContributionModel` |
| `monthly_results` | `String (JSON Array)` | Lista completa de `MonthlyResultModel` |
| `achievements_{userId}` | `String (JSON Object)` | Mapa `{achievementId: {isUnlocked, unlockedAt}}` |

### Estratégia de IDs

```dart
String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
```

IDs gerados localmente via timestamp em microsegundos. Garante unicidade prática sem dependência de pacotes. Na migração para Firebase, o `id` local pode ser preservado ou substituído pelo `DocumentID` do Firestore.

---

## Modelagem de Dados (Schemas JSON)

### UserModel
```json
{
  "id":   "1709123456789",
  "name": "Jefferson"
}
```

### GroupModel
```json
{
  "id":      "1709123456790",
  "name":    "Turma de Investimentos",
  "members": [
    { "id": "1709123456789", "name": "Jefferson" },
    { "id": "1709123456801", "name": "Ana Silva" }
  ]
}
```

### ContributionModel
```json
{
  "id":      "1709123456810",
  "userId":  "1709123456789",
  "groupId": "1709123456790",
  "amount":  350.00,
  "goal":    500.00,
  "month":   "2025-03"
}
```

> `amount` e `goal` são armazenados mas **nunca exibidos no ranking**. O ranking consome apenas `amount / goal`.

### MonthlyResultModel
```json
{
  "id":         "1709123456900",
  "groupId":    "1709123456790",
  "month":      "2025-02",
  "winnerId":   "1709123456789",
  "winnerName": "Jefferson",
  "ranking": [
    { "userId": "1709123456789", "userName": "Jefferson", "progress": 0.92, "position": 1 },
    { "userId": "1709123456801", "userName": "Ana Silva", "progress": 0.75, "position": 2 }
  ]
}
```

### Achievement State (por usuário)
```json
{
  "first_deposit": { "id": "first_deposit", "isUnlocked": true,  "unlockedAt": "2025-01-10T14:32:00" },
  "streak_3":      { "id": "streak_3",      "isUnlocked": true,  "unlockedAt": "2025-03-01T09:15:00" },
  "streak_6":      { "id": "streak_6",      "isUnlocked": false, "unlockedAt": null }
}
```

---

## Preparação para Firebase

A arquitetura foi deliberadamente desenhada para tornar a migração uma troca de implementação, não uma reescrita.

### O que muda na migração

```dart
// Hoje — injeção do storage local
final rankingService = RankingService(LocalStorageService());
final achService     = AchievementService(LocalStorageService());

// Após migração — apenas a dependência muda
final rankingService = RankingService(FirebaseStorageService());
final achService     = AchievementService(FirebaseStorageService());
```

Nenhuma screen, nenhum model e nenhuma lógica de negócio precisam ser alterados.

### Compatibilidade de schema

| Conceito local | Equivalente Firestore |
|---|---|
| `_keyGroups` (JSON array) | Coleção `groups` |
| `_keyContributions` (JSON array) | Coleção `contributions` |
| `_keyMonthlyResults` (JSON array) | Coleção `monthly_results` |
| `achievements_{userId}` | Subcoleção `users/{userId}/achievements` |
| IDs por timestamp | Firebase `DocumentID` (compatível por ser string) |

### O que será adicionado (não alterado)

- `FirebaseStorageService` implementando a mesma interface pública do `LocalStorageService`
- `AuthService` para login com Google
- Firestore Security Rules para isolamento por `userId`
- Cloud Functions para fechamento de mês server-side (opcional)
