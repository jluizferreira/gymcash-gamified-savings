# Jornada do Usuário

**GymCash** · UX Documentation · v1.0

---

---

## Jornada Completa

```
┌─────────────────────────────────────────────────────────┐
│                    PRIMEIRA ABERTURA                     │
└──────────────────────────┬──────────────────────────────┘
                           │
                    ┌──────▼───────┐
                    │  Onboarding  │  "Como posso te chamar?"
                    │              │  → Digite seu nome
                    └──────┬───────┘
                           │ Salva nome + id local
                    ┌──────▼───────┐
                    │  HomeScreen  │  Dashboard principal
                    └──────┬───────┘
```

---

## Fluxo: Criar Grupo e Competir

```
HomeScreen
  │
  ├── [FAB] "Novo grupo"
  │     └── CreateGroupScreen
  │           │ Digite nome do grupo
  │           └── Salva grupo (criador já entra como membro)
  │                 └── Volta para HomeScreen (lista atualizada)
  │
  └── [Card do grupo] → GroupScreen
        │
        ├── [Aba: Ranking]     → Ranking ao vivo do mês atual
        │     │
        │     └── [FAB] "Minha contribuição"
        │           └── AddContributionScreen
        │                 │ Digite valor guardado
        │                 │ Digite sua meta do mês
        │                 └── Salva → recalcula streak + achievements
        │                       └── Volta para GroupScreen (ranking atualizado)
        │
        ├── [Aba: Membros]     → Lista de membros
        │     │
        │     └── [FAB] "Adicionar membro"
        │           └── AddMemberScreen
        │                 │ Digite nome do membro
        │                 └── Salva → volta para GroupScreen
        │
        └── [Aba: Histórico]   → Meses fechados
              └── [Card do mês] → Expande ranking completo
```

---

## Fluxo: Ver Conquistas e Patente

```
HomeScreen
  │
  └── [Badge de patente] (ex: "✨ Ouro — 6/11 conquistas")
        └── AchievementsScreen
              ├── Card de patente atual
              │     └── Barra de progresso até a próxima patente
              └── Lista de achievements
                    ├── [Desbloqueado] → Emoji + título + ✓
                    └── [Bloqueado]    → 🔒 + título bloqueado
```

---

## Fluxo: Virada de Mês (Automático)

```
Usuário abre GroupScreen em março, com contribuições de fevereiro não fechadas
  │
  └── _checkMonthClose() é chamado
        │
        └── RankingService detecta fevereiro pendente
              │
              ├── Calcula ranking de fevereiro
              ├── Salva MonthlyResult com vencedor
              └── Recarrega GroupScreen
                    └── Aba Histórico agora exibe fevereiro
```

---

## Reabertura do App (Usuário Existente)

```
App abre
  │
  └── main() lê SharedPreferences
        │
        ├── Encontrou nome/id salvo?
        │     ├── SIM → HomeScreen (direto, sem onboarding)
        │     └── NÃO → OnboardingScreen
        │
        └── HomeScreen._loadGroups()
              ├── Carrega grupos
              ├── Calcula acumulado
              ├── Calcula streak
              ├── Verifica e desbloqueia achievements
              └── Determina patente atual
```

---

## Estados da HomeScreen

| Estado | O que o usuário vê |
|---|---|
| Sem grupos | Ilustração vazia + "Crie seu primeiro grupo" |
| Com grupos, sem contribuições | Lista de grupos + streak = 0 + Bronze |
| Com contribuições no mês | Lista + acumulado + streak ativo + patente |
| Após virada de mês | Idem + histórico fechado disponível no GroupScreen |
| Conquistas desbloqueadas | Badge de patente atualizado + conquistas novas marcadas |

---

## Diagrama de Telas

```
main.dart
  ├── OnboardingScreen
  │     └── HomeScreen ──────────────────────────────────┐
  │                                                       │
  └── HomeScreen                                         │
        ├── CreateGroupScreen                            │
        │     └── (pop → HomeScreen recarrega)           │
        │                                                 │
        ├── GroupScreen                                   │
        │     ├── AddContributionScreen                  │
        │     │     └── (pop → GroupScreen recarrega)    │
        │     ├── AddMemberScreen                        │
        │     │     └── (pop → GroupScreen recarrega)    │
        │     └── HistoryScreen                          │
        │           └── (pop → GroupScreen)              │
        │                                                 │
        └── AchievementsScreen ◄──────────────────────── ┘
              └── (pop → HomeScreen recarrega)
```
