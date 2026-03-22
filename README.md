<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-v1.1%20Concluída-448AFF?style=for-the-badge"/>

# GymCash

### Gamificação de finanças pessoais com privacidade por design

*Guarde mais. Compita com amigos. Sem expor seus valores.*

</div>

---

## 💎 Visão do Produto (v1.1 - Evolution)

O GymCash transforma o hábito solitário de poupar em uma **experiência social premium**. O foco da versão 1.1 foi elevar o nível de polimento visual e feedback ao usuário, consolidando a identidade **Deep Black & Electric Blue**.

A privacidade continua sendo o núcleo: o ranking exibe apenas porcentagens de progresso, garantindo uma competição justa e ética entre amigos com diferentes realidades financeiras.

---

## 🛠️ O que há de novo na v1.1?

| Feature | Descrição | Impacto UX |
|---|---|---|
| **Goal Reached Dialog** | Animação de troféu 3D-like ao bater 100% da meta mensal. | Celebração e dopamina positiva. |
| **Achievement Toasts** | Notificações em Overlay (permanecem visíveis após navegação). | Reconhecimento imediato de progresso. |
| **Profile & Stats** | Nova tela centralizando Patente, Streak e Total Acumulado. | Senso de identidade e evolução a longo prazo. |
| **Transaction History** | Extrato detalhado com cores dinâmicas e design minimalista. | Transparência e controle histórico. |
| **Haptic Engine** | Feedback tátil (vibration) integrado a ações críticas. | Sensação de robustez e app premium. |

---

## Funcionalidades Implementadas

### Core & Gestão
- **Onboarding sem fricção:** Único dado obrigatório é o nome, sem burocracia.
- **Edição de Grupos:** Possibilidade de renomear grupos diretamente da Home ou Detalhes.
- **Persistência Sênior:** Gerenciamento via `LocalStorageService` com tratamento de erros robusto em português.

### Competição & Gamificação
- **Ranking Privado:** Progresso real baseado em `amount / goal` (porcentagem).
- **Streak System:** Sequência de meses consecutivos com feedback visual progressivo.
- **Sistema de Patentes:** De Bronze a Diamante, baseado no total acumulado histórico.
- **11 Achievements:** Engine de desbloqueio em tempo real integrada ao fluxo de contribuição.

---

## Stack Técnica

┌─────────────────────────────────────────────────────────────┐│  UI Layer         Flutter 3.x + Custom Animations (Overlay) │├─────────────────────────────────────────────────────────────┤│  Business Logic   Services Desacoplados (DI Manual)         │├─────────────────────────────────────────────────────────────┤│  Data Layer       Gateway Único + Result Objects            │├─────────────────────────────────────────────────────────────┤│  Persistence      SharedPreferences (JSON Ops)              │└─────────────────────────────────────────────────────────────┘
### Decisões de Engenharia (Sênior Mindset)

- **Result Objects:** Implementação de `ContributionSaveResult` para comunicação clara entre Service e UI sem abuso de Exceptions para fluxos de sucesso.
- **Imutabilidade:** Uso rigoroso de `List.unmodifiable` e modelos imutáveis com suporte a `copyWith`.
- **Overlay Engine:** Sistema de notificações (`AchievementUnlockToast`) que não depende do contexto da tela atual, garantindo que o feedback persista mesmo após trocas de rota.

---

## Estrutura do Projeto (v1.1)

Aqui está a estrutura de pastas organizada e padronizada, pronta para ser copiada para o seu projeto:

Plaintext
lib/
├── models/
│   ├── contribution_save_result.dart
│   ├── user.dart
│   ├── group.dart
│   ├── contribution.dart
│   ├── achievement.dart
│   └── rank.dart
│
├── services/
│   ├── local_storage_service.dart
│   ├── ranking_service.dart
│   ├── streak_service.dart
│   └── achievement_service.dart
│
├── widgets/
│   ├── achievement_unlock_toast.dart
│   ├── goal_reached_dialog.dart
│   └── rename_group_dialog.dart
│
└── screens/
    ├── transaction_list_view.dart
    ├── profile_screen.dart
    ├── home_screen.dart
    ├── group_screen.dart
    └── add_contribution_screen.dart
---

## Como Executar

```bash
# Clone o repositório
git clone [https://github.com/jluizferreira/gymcash.git](https://github.com/jluizferreira/gymcash.git)

# Entre na pasta
cd gymcash

# Instale as dependências
flutter pub get

# Execute o app
flutter run
RoadmapVersãoFocoStatusv1.0MVP local — features core✅ Concluídov1.1Polimento, Animações, Perfil e Edição✅ Concluídov1.2Ordenação de Grupos e Filtros🔄 Planejadov2.0Backend Firebase + Autenticação Google📋 Especificado

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
