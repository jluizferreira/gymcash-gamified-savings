<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-v1.1%20Concluído-00C853?style=for-the-badge"/>

<br/><br/>

# GymCash

**Gamificação de finanças pessoais com privacidade por design**

*Guarde mais. Compita com amigos. Sem expor seus valores.*

</div>

---

## O Problema

O brasileiro médio não deixa de poupar por falta de informação — deixa por falta de **motivação e consistência**. Poupança é invisível, solitária e sem celebração.

| Sintoma | Causa raiz |
|---|---|
| Brasileiros poupam em média 4% da renda (vs. 15–20% em países desenvolvidos) | Ausência de incentivos comportamentais |
| 78% das pessoas abandonam metas financeiras no 2º mês | Falta de accountability social |
| Apps de finanças têm churn altíssimo | Experiência sem progressão visível |
| Compartilhar metas é socialmente delicado | Exposição de renda e patrimônio |

---

## A Solução

Dois conceitos orientam toda a experiência:

**Sprint** — competição mensal reiniciável. Cada membro define sua própria meta. Ao final do mês, o ranking revela quem chegou mais longe *em relação à própria meta* — sempre em porcentagem, nunca em reais. O vencedor é quem foi mais disciplinado, não quem ganha mais.

**Maratona** — acumulado histórico que nunca zera. Cada real guardado contribui para uma jornada de longo prazo representada por patentes progressivas e conquistas desbloqueáveis.

> A privacidade não é uma limitação: é o núcleo do produto.

---

## Funcionalidades

### Core
- Onboarding sem fricção — único dado obrigatório: um nome
- Criação e gestão de grupos com controle de membros
- Registro e edição de contribuição mensal com meta individual
- Renomeação de grupos diretamente da Home ou da tela do grupo

### Competição
- Ranking em tempo real baseado em `progresso = amount / goal`
- Valores em reais **nunca** são exibidos para outros membros
- Fechamento automático de mês ao detectar virada — snapshot imutável salvo no histórico
- Histórico de rankings expansível com vencedor de cada período

### Gamificação
- **Streak** — sequência de meses consecutivos com contribuição e feedback visual progressivo
- **Patentes** — Bronze → Prata → Ouro → Platina → Diamante, baseadas no total acumulado histórico
- **11 Achievements** — marcos desbloqueáveis cobrindo depósitos, vitórias, streaks e patentes
- **Barra de progresso** para a próxima patente com valor faltante em destaque

### UX & Polimento
- Diálogo animado de meta atingida com feedback tátil (haptic)
- Toasts de achievement em overlay — persistem mesmo após troca de rota
- Tela de perfil com resumo de patente, streak e total acumulado
- Extrato de transações com identidade visual Deep Black & Electric Blue

---

## Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│  UI Layer          Flutter 3.x + Dart 3.x (Material 3)      │
├─────────────────────────────────────────────────────────────┤
│  Business Logic    Services independentes (DI manual)        │
├─────────────────────────────────────────────────────────────┤
│  Data Layer        LocalStorageService — gateway único       │
├─────────────────────────────────────────────────────────────┤
│  Persistence       SharedPreferences (JSON serializado)      │
└─────────────────────────────────────────────────────────────┘
```

### Decisões relevantes

**Gateway único.** Toda leitura e escrita passa pelo `LocalStorageService`. Nenhuma tela ou service acessa SharedPreferences diretamente. Isso permite substituir toda a camada de persistência por Firebase sem tocar em uma linha de UI.

**Services desacoplados.** `StreakService`, `RankingService` e `AchievementService` recebem o storage por injeção de dependência — são testáveis isoladamente e agnósticos à fonte de dados.

**Models com serialização bidirecional.** Todos os modelos têm `toJson()` / `fromJson()` com estrutura compatível com documentos Firestore, sem necessidade de migração de schema na v2.0.

**Result Objects.** `ContributionSaveResult` comunica o resultado entre service e UI sem abuso de exceções para fluxos de sucesso.

---

## Estrutura do Projeto

```
lib/
├── main.dart
├── models/
│   ├── user_model.dart
│   ├── group_model.dart
│   ├── contribution_model.dart       # amount, goal, month (YYYY-MM)
│   ├── contribution_save_result.dart # resultado tipado do save
│   ├── monthly_result_model.dart     # snapshot imutável do ranking fechado
│   ├── ranking_entry.dart            # agregação membro + contribuição
│   ├── achievement_model.dart        # definições + estado de desbloqueio
│   └── rank_model.dart               # tabela de patentes + progresso
├── services/
│   ├── local_storage_service.dart    # gateway único — SharedPreferences
│   ├── ranking_service.dart          # detecção e fechamento de meses
│   ├── streak_service.dart           # cálculo de sequências mensais
│   └── achievement_service.dart      # engine de desbloqueio
├── screens/
│   ├── onboarding_screen.dart
│   ├── home_screen.dart              # dashboard: acumulado, streak, patente
│   ├── create_group_screen.dart
│   ├── group_screen.dart             # 3 abas: Ranking | Membros | Histórico
│   ├── add_member_screen.dart
│   ├── add_contribution_screen.dart
│   ├── history_screen.dart           # meses fechados com ranking expansível
│   ├── achievements_screen.dart      # patente + conquistas
│   └── profile_screen.dart           # resumo da jornada do usuário
└── widgets/
    ├── goal_reached_dialog.dart
    ├── achievement_unlock_toast.dart
    └── rename_group_dialog.dart
```

---

## Como Executar
--.
**Pré-requisitos:** Flutter SDK `>=3.3.0` · Android SDK API 23+

**Pré-requisitos:** Flutter SDK `>=3.3.0` · Android SDK API 23+

```bash
git clone https://github.com/jluizferreira/gymcash-gamified-savings.git
cd gymcash-gamified-savings
flutter pub get
flutter run
```

**Build de produção**

```bash
# APK (distribuição direta)
flutter build apk --release

# AAB (Google Play Store)
flutter build appbundle --release
```

---

## Roadmap

| Versão | Foco | Status |
|---|---|---|
| v1.0 | MVP local — features core | ✅ Concluído |
| v1.1 | Polimento de UX, animações, perfil e edição | ✅ Concluído |
| v1.2 | Ordenação de grupos e filtros | 🔄 Planejado |
| v2.0 | Backend Firebase + autenticação Google | 📋 Especificado |
| v2.1 | Multiusuário real + convites por link | 📋 Especificado |
| v3.0 | Notificações push + insights financeiros | 💡 Conceitual |

---

## Documentação

| Documento | Conteúdo |
|---|---|
| [`docs/REQUISITOS.md`](./docs/REQUISITOS.md) | Requisitos funcionais e não funcionais |
| [`docs/REGRAS_DE_NEGOCIO.md`](./docs/REGRAS_DE_NEGOCIO.md) | Regras de ranking, streak e fechamento de mês |
| [`docs/ARQUITETURA.md`](./docs/ARQUITETURA.md) | Arquitetura, modelagem de dados e fluxo |
| [`docs/FLUXO_DO_USUARIO.md`](./docs/FLUXO_DO_USUARIO.md) | Jornada completa do usuário com diagramas |
| [`docs/ROADMAP.md`](./docs/ROADMAP.md) | Plano de evolução do produto |
| [`docs/DIFERENCIAIS.md`](./docs/DIFERENCIAIS.md) | Posicionamento e análise competitiva |

---




## Sobre o Desenvolvedor

Projeto desenvolvido por **Jefferson Ferreira** como produto pessoal com foco em resolver um problema real de educação financeira através de design comportamental e gamificação.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=flat&logo=linkedin)](https://www.linkedin.com/in/jefferson-ferreira-ti/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=flat&logo=github)](https://github.com/jluizferreira)

---

<div align="center">
<sub>GymCash — Desenvolvido com Flutter · 2025</sub>
</div>
