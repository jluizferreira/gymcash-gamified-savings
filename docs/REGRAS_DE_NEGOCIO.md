# Regras de Negócio

**GymCash** · Especificação Funcional · v1.0

---

## RN-01 · Contribuição Mensal

### Definição

Uma contribuição representa o valor que um usuário afirma ter guardado em determinado mês para determinado grupo. O sistema não valida a veracidade dos valores — o produto é baseado em auto-declaração e confiança entre membros do grupo.

### Unicidade

Uma contribuição é **única por tripla** `(userId, groupId, month)`. O sistema garante essa unicidade na camada de serviço:

```
saveContribution(userId, groupId, amount, goal)
  ├── Existe registro para (userId, groupId, currentMonth)?
  │     ├── SIM → atualiza amount e goal preservando o id original
  └─── NÃO → cria novo registro com id gerado
```

### Campos

| Campo | Tipo | Regra |
|---|---|---|
| `amount` | `double` | Valor guardado no mês. Nunca exibido no ranking. |
| `goal` | `double` | Meta individual do usuário para o mês. Nunca exibida no ranking. |
| `month` | `String` | Formato `YYYY-MM`. Sempre o mês em que o registro foi criado. |

---

## RN-02 · Ranking (Sprint)

### Cálculo de progresso

O progresso é a única métrica exibida publicamente. Ele representa a relação entre o valor guardado e a meta estabelecida:

```
progress = amount / goal        // 0.0 a 1.0+ (pode ultrapassar 100%)
label    = round(progress × 100) + "%"
```

Exemplos práticos:

| amount | goal | progress | label exibido |
|---|---|---|---|
| R$ 200 | R$ 400 | 0.50 | 50% |
| R$ 400 | R$ 400 | 1.00 | 100% |
| R$ 500 | R$ 400 | 1.25 | 125% |
| — | — | 0.00 | 0% (sem contribuição) |

### Ordenação

1. Maior progresso primeiro
2. Empate exato: ordem alfabética pelo nome do membro

### Garantia de privacidade

Os campos `amount` e `goal` são armazenados localmente mas **não fazem parte de nenhuma tela de ranking, histórico ou comparativo**. A regra é aplicada no model — não existe caminho para expô-los acidentalmente.

---

## RN-03 · Fechamento de Mês (Histórico)

### Gatilho

O fechamento é disparado sempre que o `GroupScreen` é aberto. O sistema verifica a existência de meses com contribuições que ainda não possuem `MonthlyResult` associado.

### Critérios de elegibilidade para fechamento

Um mês é elegível quando:
- Existem contribuições naquele mês para o grupo
- O mês é **diferente** do mês atual
- Não existe `MonthlyResult` salvo para o par `(groupId, month)`

### Processo

```
Para cada mês elegível, em ordem cronológica:
  1. Coleta todas as contribuições do mês no grupo
  2. Para cada membro do grupo:
       - Busca contribuição existente
       - Se não encontrada: progresso = 0.0
  3. Ordena pelo mesmo critério do ranking ao vivo
  4. Salva MonthlyResult como snapshot imutável
```

### Imutabilidade e idempotência

- Resultados salvos **nunca são recalculados** após o fechamento inicial
- O fechamento é **idempotente**: executado duas vezes para o mesmo mês, o segundo resultado sobrescreve o primeiro sem efeito colateral
- As contribuições originais **nunca são deletadas** pelo fechamento

### Vencedor

- É o membro com maior progresso no mês
- Obrigatoriamente deve ter `amount > 0` — membros que não contribuíram não podem vencer
- Se nenhum membro contribuiu: `winnerId = null`, `winnerName = null`

---

## RN-04 · Streak

### Definição

O streak mede quantos meses consecutivos o usuário realizou ao menos uma contribuição com `amount > 0`, em qualquer grupo.

### Algoritmo

```
1. Coleta todos os meses únicos onde o usuário tem amount > 0 (qualquer grupo)
2. Ordena cronologicamente ascendente
3. Percorre de trás para frente verificando consecutividade
4. Interrompe ao encontrar uma lacuna

Consecutividade: o mês M é consecutivo ao mês M-1 se
  DateTime(M.year, M.month) == DateTime(M-1.year, M-1.month + 1)
  (Trata corretamente dezembro → janeiro)
```

### Propriedades

- **Escopo global**: considera todos os grupos simultaneamente. Um único grupo ativo no mês é suficiente para manter a sequência.
- **Calculado dinamicamente**: não existe campo `streakCount` armazenado. O valor é sempre derivado das contribuições existentes.
- **Atualizado imediatamente** após cada `saveContribution`.

---

## RN-05 · Patentes

### Tabela de progressão

| Patente | Acumulado mínimo | Cor |
|---|---|---|
| 🥉 Bronze | R$ 0 | `#CD7F32` |
| 🥈 Prata | R$ 100 | `#C0C0C0` |
| ✨ Ouro | R$ 300 | `#FFD700` |
| 💎 Platina | R$ 700 | `#00E5FF` |
| 💠 Diamante | R$ 1.500 | `#00B0FF` |

### Cálculo

```dart
RankModel.fromTotal(double total)
  // Percorre da maior para a menor patente
  // Retorna a primeira onde total >= minAmount
```

### Propriedades

- Calculada em tempo real a partir do acumulado — não armazenada
- **Irreversível**: o acumulado nunca diminui, portanto a patente nunca regride
- A barra de progresso exibe `(total - current.minAmount) / (next.minAmount - current.minAmount)`

---

## RN-06 · Achievements

### Gatilhos de verificação

O sistema verifica conquistas em dois momentos:
1. **Imediatamente após `saveContribution`** — captura conquistas baseadas em contribuição
2. **Ao carregar a `HomeScreen`** — captura conquistas baseadas em histórico (vitórias, patentes)

### Regras de desbloqueio

| ID | Condição exata |
|---|---|
| `first_deposit` | Existe ao menos uma contribuição do usuário com `amount > 0` |
| `streak_3` | `calculateStreak(userId) >= 3` |
| `streak_6` | `calculateStreak(userId) >= 6` |
| `streak_12` | `calculateStreak(userId) >= 12` |
| `first_win` | Usuário é `winnerId` em ao menos 1 `MonthlyResult` |
| `win_3` | Usuário é `winnerId` em ao menos 3 `MonthlyResult` |
| `goal_reached` | Existe ao menos uma contribuição onde `amount >= goal` |
| `rank_silver` | `getTotalAccumulated(userId) >= 100` |
| `rank_gold` | `getTotalAccumulated(userId) >= 300` |
| `rank_platinum` | `getTotalAccumulated(userId) >= 700` |
| `rank_diamond` | `getTotalAccumulated(userId) >= 1500` |

### Persistência e isolamento

- Apenas `{isUnlocked: bool, unlockedAt: DateTime?}` é persistido por achievement
- O estado é salvo na chave `achievements_{userId}`, isolado por usuário
- As definições (título, descrição, emoji, condição) são imutáveis em código
- Uma conquista desbloqueada **nunca pode ser rebloqueada**

---

## RN-07 · Integridade Referencial

| Operação | Comportamento |
|---|---|
| Excluir grupo | Remove o grupo **e todas as suas contribuições**. Resultados mensais fechados também são removidos. |
| Remover membro | Remove o membro do grupo. Contribuições históricas **são preservadas** para integridade do histórico fechado. |
| Criar grupo | O criador é adicionado automaticamente como primeiro membro. |
| Adicionar membro duplicado | Verificado por `userId`. Operação silenciosamente ignorada. |
