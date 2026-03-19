# Roadmap de Produto

**GymCash** · Planejamento Estratégico · 2025–2026

---

## Princípios de Priorização

O roadmap do GymCash segue três princípios:

1. **Retenção antes de aquisição** — não faz sentido trazer novos usuários antes de o produto reter os atuais com consistência
2. **Infraestrutura habilita produto** — a migração para Firebase (v2.0) desbloqueia todas as features sociais das versões seguintes
3. **Evolução sem ruptura** — cada versão deve ser retrocompatível com os dados da versão anterior

---

## Versão Atual — v1.0 · MVP Local

> **Status: ✅ Concluído**
> Produto funcional offline, sem servidor, sem cadastro obrigatório.

**Entregues:**

- [x] Onboarding sem fricção (apenas nome)
- [x] Criação e gestão de grupos e membros
- [x] Contribuições mensais com meta individual
- [x] Ranking por porcentagem (Sprint)
- [x] Acumulado histórico por usuário (Maratona)
- [x] Fechamento automático de mês com resultado imutável
- [x] Histórico de rankings por grupo
- [x] Sistema de streak com feedback visual progressivo
- [x] 5 patentes com barra de progresso (Bronze → Diamante)
- [x] 11 achievements desbloqueáveis automaticamente
- [x] Arquitetura com gateway de dados isolado (preparado para Firebase)

---

## v1.1 · Polimento de Experiência

> **Status: 🔄 Próxima entrega**
> Melhorias de UX que aumentam retenção sem alterações estruturais.

**Objetivos:** aumentar a percepção de qualidade do produto e reduzir abandono por fricção.

- [ ] Toast animado ao desbloquear achievement
- [ ] Dialog comemorativo ao bater a meta do mês ("🎯 Meta atingida!")
- [ ] Tela de perfil com resumo: streak, patente, conquistas, acumulado
- [ ] Edição do nome do grupo
- [ ] Ordenação da lista de grupos (mais recente / alfabética)
- [ ] Widget de progresso do usuário atual na aba Ranking
- [ ] Suporte a tema claro (Light Mode)
- [ ] Empty states com ilustrações para grupos sem membros/contribuições

---

## v2.0 · Backend Firebase + Identidade Real

> **Status: 📋 Especificado · Estimativa: Q3 2025**
> Migração para backend em nuvem. Esta versão desbloqueia crescimento viral.

### 2.0 — Infraestrutura e Autenticação

- [ ] Configuração do projeto Firebase (Auth + Firestore + FCM)
- [ ] Implementação de `FirebaseStorageService` com interface idêntica ao `LocalStorageService`
- [ ] Migração automática de dados locais para Firestore na primeira autenticação
- [ ] Login com Google (OAuth 2.0) como método principal
- [ ] Persistência de sessão entre dispositivos

### 2.1 — Grupos Reais e Convites

- [ ] Convite de membros por link compartilhável ou código de 6 dígitos
- [ ] Sincronização em tempo real do ranking via Firestore streams
- [ ] Foto de perfil via Google Account
- [ ] Notificação ao ser adicionado a um grupo

### 2.2 — Segurança e Conformidade

- [ ] Firestore Security Rules: usuário lê apenas dados de grupos em que é membro
- [ ] Validação de contribuição duplicada via Cloud Functions (server-side)
- [ ] Política de privacidade e Termos de Uso (obrigatório para Google Play)

---

## v3.0 · Engajamento Avançado

> **Status: 💡 Conceitual · Estimativa: Q1 2026**
> Features que aumentam frequência de uso e viralidade.

### Notificações Push

- [ ] Lembrete no último dia do mês para registrar contribuição
- [ ] Notificação ao virar o mês com resumo do sprint encerrado e vencedor
- [ ] Notificação ao ser superado no ranking ("Ana te ultrapassou! 📈")
- [ ] Notificação ao desbloquear achievement

### Insights Pessoais

- [ ] Gráfico de evolução do acumulado mês a mês
- [ ] Comparativo de metas vs. realidade por período
- [ ] Projeção de data para atingir próxima patente
- [ ] Relatório mensal exportável em PDF

---

## v3.1 · Gamificação Avançada

> **Status: 💡 Conceitual · Estimativa: Q2 2026**

- [ ] **Ligas**: grupos competem entre si em ligas com promoção e rebaixamento mensal
- [ ] **Desafios temporários**: metas especiais com prazo definido (ex: "Guardar 20% a mais em dezembro")
- [ ] **Reações**: emojis de comemoração ou provocação entre membros do grupo
- [ ] **Títulos personalizados**: baseados em histórico de vitórias e conquistas raras

---

## v4.0 · Expansão de Plataforma

> **Status: 🔮 Visão de longo prazo**

- [ ] **iOS**: suporte nativo (Flutter já está preparado; requer Apple Developer Account)
- [ ] **Android Widget**: streak e posição atual sem abrir o app
- [ ] **Web**: visualização de ranking em tempo real para grupos grandes
- [ ] **API pública**: para integrações com outros apps de finanças pessoais

---

## Cronograma Resumido

```
2025
  ├── Q2 · v1.0 MVP Local ──────────────────── ✅ Concluído
  ├── Q2 · v1.1 Polimento de UX ───────────── 🔄 Em andamento
  └── Q3 · v2.0 Firebase + Autenticação ────── 📋 Planejado

2026
  ├── Q1 · v3.0 Notificações + Insights ────── 💡 Conceitual
  ├── Q2 · v3.1 Gamificação Avançada ─────────  💡 Conceitual
  └── Q3 · v4.0 iOS + Web + API ──────────────  🔮 Visão
```
