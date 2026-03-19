<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-MVP%20Concluído-00C853?style=for-the-badge"/>

# GymCash

### Gamificação de finanças pessoais com privacidade por design

*Guarde mais. Compita com amigos. Sem expor seus valores.*

</div>

---

## Visão do Produto

O brasileiro médio não guarda dinheiro por falta de informação — ele não guarda por falta de **motivação e consistência**. Poupança é invisível, solitária e sem celebração.

O GymCash resolve isso transformando o hábito de guardar dinheiro em uma **competição social privada**. Grupos de amigos, colegas ou família competem mensalmente para ver quem consegue atingir melhor sua meta de economia — sem nunca revelar quanto cada um guarda de verdade.

A privacidade não é uma limitação: é o núcleo do produto. O ranking exibe apenas porcentagens de progresso, tornando a competição justa independente de renda.

---

## O Problema

| Symptom | Root Cause |
|---|---|
| Brasileiros poupam em média 4% da renda (vs. 15–20% em países desenvolvidos) | Ausência de incentivos comportamentais |
| 78% das pessoas abandonam metas financeiras no 2º mês | Falta de accountability social |
| Apps de finanças têm churn altíssimo | Experiência entediante, sem progressão visível |
| Compartilhar metas financeiras é socialmente delicado | Exposição de renda e patrimônio |

> O GymCash ataca exatamente a interseção entre esses quatro problemas.

---

## A Solução

Dois conceitos centrais orientam toda a experiência:

**Sprint** — competição mensal reiniciável. No início de cada mês, cada membro define sua meta. Ao final, o ranking revela quem chegou mais longe em relação à própria meta — em porcentagem, nunca em reais. O vencedor é quem foi mais disciplinado, não quem ganha mais.

**Maratona** — acumulado histórico que nunca zera. Cada real guardado ao longo do tempo contribui para uma jornada de longo prazo representada por patentes progressivas e conquistas desbloqueáveis.

---

## Funcionalidades Implementadas

### Core
- Onboarding sem fricção — único dado obrigatório: um nome
- Criação e gestão de grupos com controle de membros
- Registro de contribuição mensal com meta individual por usuário
- Edição da contribuição dentro do mês corrente

### Competição
- Ranking em tempo real baseado em `progresso = amount / goal`
- Privacidade garantida: valores em reais nunca são exibidos para outros membros
- Fechamento automático de mês ao detectar virada — resultado imutável salvo como snapshot histórico
- Histórico de rankings com vencedor de cada mês, expansível por período

### Gamificação
- **Streak**: sequência de meses consecutivos com contribuição, com feedback visual progressivo
- **Patentes**: Bronze → Prata → Ouro → Platina → Diamante, baseadas no total acumulado
- **11 Achievements**: marcos desbloqueáveis cobrindo depósitos, vitórias, streaks e patentes
- Barra de progresso para a próxima patente com valor faltante

---

## Stack Técnica

```
┌─────────────────────────────────────────────────────────────┐
│  UI Layer          Flutter 3.x + Dart 3.x (Material 3)      │
├─────────────────────────────────────────────────────────────┤
│  Business Logic    Services independentes (sem acoplamento)  │
├─────────────────────────────────────────────────────────────┤
│  Data Layer        LocalStorageService (gateway único)       │
├─────────────────────────────────────────────────────────────┤
│  Persistence       SharedPreferences (JSON serializado)      │
└─────────────────────────────────────────────────────────────┘
```

### Decisões arquiteturais relevantes

**Gateway de dados único.** Toda leitura e escrita passa pelo `LocalStorageService`. Nenhuma tela ou service acessa SharedPreferences diretamente. Isso possibilita a substituição completa da camada de persistência por Firebase sem tocar em uma única linha de UI.

**Services desacoplados.** `StreakService`, `RankingService` e `AchievementService` recebem o storage por injeção de dependência. São testáveis isoladamente e agnósticos à fonte de dados.

**Models com serialização bidirecional.** Todos os modelos possuem `toJson()` / `fromJson()`. A estrutura é diretamente compatível com documentos Firestore, sem necessidade de migração de schema.

---

## Estrutura do Projeto

```
lib/
├── main.dart                         # Inicialização + roteamento por estado
├── models/
│   ├── user_model.dart
│   ├── group_model.dart
│   ├── contribution_model.dart       # amount, goal, month (YYYY-MM)
│   ├── monthly_result_model.dart     # Snapshot imutável do ranking fechado
│   ├── ranking_entry.dart            # Agregação membro + contribuição
│   ├── achievement_model.dart        # Definições + estado de desbloqueio
│   └── rank_model.dart               # Tabela de patentes + cálculo de progresso
├── services/
│   ├── local_storage_service.dart    # Gateway único — SharedPreferences
│   ├── ranking_service.dart          # Detecção e fechamento de meses
│   ├── streak_service.dart           # Cálculo de sequências mensais
│   └── achievement_service.dart      # Engine de desbloqueio de conquistas
└── screens/
    ├── onboarding_screen.dart
    ├── home_screen.dart              # Dashboard: acumulado, streak, patente
    ├── create_group_screen.dart
    ├── group_screen.dart             # 3 abas: Ranking | Membros | Histórico
    ├── add_member_screen.dart
    ├── add_contribution_screen.dart  # Criação e edição de contribuição
    ├── history_screen.dart           # Meses fechados com ranking expansível
    └── achievements_screen.dart      # Patente + conquistas
```

---

## Como Executar

### Pré-requisitos

- Flutter SDK `>=3.3.0` — [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- Android SDK API 23+ (Android 6.0)
- Dispositivo físico ou emulador Android

### Instalação e execução

```bash
git clone https://github.com/seu-usuario/gymcash.git
cd gymcash
flutter pub get
flutter run
```

### Build de produção

```bash
# APK universal (distribuição direta)
flutter build apk --release

# AAB (Google Play Store)
flutter build appbundle --release
```

---

## Roadmap

| Versão | Foco | Status |
|---|---|---|
| v1.0 | MVP local — todas as features core | ✅ Concluído |
| v1.1 | Polimento de UX e animações | 🔄 Planejado |
| v2.0 | Backend Firebase + autenticação Google | 📋 Especificado |
| v2.1 | Multiusuário real + convites por link | 📋 Especificado |
| v3.0 | Notificações push + insights financeiros | 💡 Conceitual |
| v3.1 | Gamificação avançada (ligas, desafios) | 💡 Conceitual |

Documentação completa em [`docs/ROADMAP.md`](./docs/ROADMAP.md).

---

## Documentação Completa

| Documento | Conteúdo |
|---|---|
| [`docs/REQUISITOS.md`](./docs/REQUISITOS.md) | Requisitos funcionais e não funcionais |
| [`docs/REGRAS_DE_NEGOCIO.md`](./docs/REGRAS_DE_NEGOCIO.md) | Regras de ranking, streak, fechamento de mês |
| [`docs/ARQUITETURA.md`](./docs/ARQUITETURA.md) | Arquitetura, modelagem de dados, fluxo de dados |
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
