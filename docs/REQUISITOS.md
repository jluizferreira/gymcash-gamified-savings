# Especificação de Requisitos

**GymCash** · Documento de Requisitos · v1.1

---

> Este documento especifica os requisitos funcionais e não funcionais do GymCash v1.1. Serve como contrato de comportamento esperado do sistema e referência para desenvolvimento, testes e avaliação de qualidade.

---

## RF — Requisitos Funcionais

### RF01 — Gestão de Usuário

| ID | Requisito |
|---|---|
| RF01.1 | O sistema deve permitir que o usuário cadastre seu nome na primeira abertura do app |
| RF01.2 | O sistema deve persistir o nome e ID localmente e pular o onboarding nas aberturas seguintes |
| RF01.3 | O sistema deve permitir que o usuário redefina seu nome, limpando os dados salvos |
| RF01.4 | O sistema deve exibir uma tela de perfil com resumo de acumulado, streak, patente e conquistas do usuário |

### RF02 — Gestão de Grupos

| ID | Requisito |
|---|---|
| RF02.1 | O usuário deve poder criar um grupo com um nome personalizado |
| RF02.2 | O criador do grupo deve ser adicionado automaticamente como primeiro membro |
| RF02.3 | O usuário deve poder adicionar novos membros a um grupo pelo nome |
| RF02.4 | O usuário deve poder remover membros de um grupo |
| RF02.5 | O usuário deve poder excluir um grupo inteiro, incluindo todos os seus dados |
| RF02.6 | O usuário deve poder renomear um grupo a partir da HomeScreen ou da tela do grupo |
| RF02.7 | A tela principal deve listar todos os grupos com o número de membros de cada um |

### RF03 — Contribuições Mensais

| ID | Requisito |
|---|---|
| RF03.1 | O usuário deve poder registrar um valor guardado no mês atual para cada grupo |
| RF03.2 | O usuário deve definir uma meta individual junto com cada contribuição |
| RF03.3 | O sistema deve permitir editar a contribuição do mês atual |
| RF03.4 | O sistema deve garantir no máximo uma contribuição por usuário por grupo por mês |
| RF03.5 | O campo de referência deve exibir o mês atual formatado |
| RF03.6 | O sistema deve detectar quando o usuário atinge ou supera sua meta e exibir um diálogo comemorativo animado |
| RF03.7 | O diálogo de meta atingida deve ser exibido apenas uma vez por contribuição, mesmo que o valor seja editado novamente |

### RF04 — Ranking (Sprint)

| ID | Requisito |
|---|---|
| RF04.1 | O sistema deve calcular o progresso de cada membro como `amount / goal` |
| RF04.2 | O ranking deve ordenar membros do maior para o menor progresso |
| RF04.3 | Empates devem ser desempatados por ordem alfabética do nome |
| RF04.4 | O ranking deve exibir apenas a porcentagem, nunca o valor em reais |
| RF04.5 | O ranking deve ser sempre referente ao mês atual |
| RF04.6 | Membros sem contribuição no mês devem aparecer no ranking com 0% |

### RF05 — Acumulado (Maratona)

| ID | Requisito |
|---|---|
| RF05.1 | O sistema deve calcular e exibir o total acumulado do usuário em todos os grupos e meses |
| RF05.2 | O acumulado deve somar todos os `amount` do usuário, independente do mês ou grupo |
| RF05.3 | O acumulado deve ser exibido na HomeScreen em destaque |

### RF06 — Histórico Mensal

| ID | Requisito |
|---|---|
| RF06.1 | O sistema deve detectar automaticamente a virada de mês ao abrir o GroupScreen |
| RF06.2 | Ao detectar meses pendentes de fechamento, o sistema deve calcular e salvar o resultado |
| RF06.3 | O resultado salvo deve incluir o ranking completo com posições e porcentagens |
| RF06.4 | O resultado deve registrar o vencedor do mês (userId e nome) |
| RF06.5 | Contribuições originais não devem ser deletadas no fechamento do mês |
| RF06.6 | O histórico deve ser exibido em ordem cronológica decrescente (mais recente primeiro) |
| RF06.7 | Cada mês no histórico deve ser expansível para revelar o ranking completo |

### RF07 — Extrato de Transações

| ID | Requisito |
|---|---|
| RF07.1 | O sistema deve exibir um extrato com todas as contribuições do usuário, ordenadas por mês (mais recente primeiro) |
| RF07.2 | O extrato deve exibir o nome do grupo, o mês de referência, o valor guardado, a meta e o progresso de cada registro |
| RF07.3 | O extrato deve ser acessível a partir da HomeScreen |
| RF07.4 | O extrato deve permitir simular uma nova transação para fins de teste |

### RF08 — Streak

| ID | Requisito |
|---|---|
| RF08.1 | O sistema deve calcular a sequência de meses consecutivos com contribuição `> 0` |
| RF08.2 | O streak deve considerar todos os grupos do usuário de forma unificada |
| RF08.3 | Se o usuário pular um mês, o streak deve ser resetado para a sequência mais recente |
| RF08.4 | O streak deve ser atualizado sempre que o usuário registrar ou editar uma contribuição |
| RF08.5 | O streak deve ser exibido na HomeScreen com feedback visual proporcional ao valor |

### RF09 — Patentes

| ID | Requisito |
|---|---|
| RF09.1 | O sistema deve calcular a patente atual com base no total acumulado do usuário |
| RF09.2 | As patentes devem ser: Bronze (R$ 0), Prata (R$ 100), Ouro (R$ 300), Platina (R$ 700), Diamante (R$ 1.500) |
| RF09.3 | A patente atual deve ser exibida na HomeScreen com um indicador de progresso para a próxima |
| RF09.4 | A tela de conquistas deve exibir a patente com barra de progresso detalhada |

### RF10 — Achievements

| ID | Requisito |
|---|---|
| RF10.1 | O sistema deve verificar e desbloquear conquistas ao registrar contribuição e ao abrir o app |
| RF10.2 | Conquistas desbloqueadas devem registrar a data e hora do desbloqueio |
| RF10.3 | Conquistas bloqueadas devem ser exibidas com cadeado e sem spoiler da condição atingida |
| RF10.4 | O sistema deve incluir no mínimo 11 conquistas cobrindo: depósitos, streaks, vitórias, metas e patentes |
| RF10.5 | Ao desbloquear uma conquista, o sistema deve exibir um toast animado em overlay que persiste mesmo após troca de tela |

---

## RNF — Requisitos Não Funcionais

### RNF01 — Performance

| ID | Requisito |
|---|---|
| RNF01.1 | O app deve inicializar e exibir a tela inicial em menos de 2 segundos em dispositivos Android com 2GB de RAM |
| RNF01.2 | Operações de leitura/escrita no SharedPreferences devem ser assíncronas e não bloquear a UI |
| RNF01.3 | O cálculo de streak e achievements deve ser executado em background sem afetar a navegação |
| RNF01.4 | Listas com até 50 grupos ou membros devem renderizar sem perda de fluidez |

### RNF02 — Usabilidade

| ID | Requisito |
|---|---|
| RNF02.1 | O app deve funcionar sem necessidade de cadastro com e-mail ou senha |
| RNF02.2 | O fluxo de registro da primeira contribuição deve ser completado em no máximo 3 toques |
| RNF02.3 | Ações destrutivas (excluir grupo, remover membro) devem exigir confirmação explícita do usuário |
| RNF02.4 | O app deve operar completamente offline, sem dependência de conexão à internet |
| RNF02.5 | A interface deve dar feedback visual imediato para todas as ações do usuário |
| RNF02.6 | O app deve suportar o tema escuro como padrão |
| RNF02.7 | Erros de armazenamento devem ser exibidos ao usuário em português com mensagem clara e opção de retry |

### RNF03 — Privacidade e Segurança

| ID | Requisito |
|---|---|
| RNF03.1 | Valores financeiros em reais não devem ser exibidos em nenhuma tela de ranking ou histórico compartilhado |
| RNF03.2 | Os dados do usuário devem ser armazenados exclusivamente no dispositivo local |
| RNF03.3 | Nenhum dado deve ser transmitido para servidores externos na versão atual |
| RNF03.4 | A arquitetura deve isolar os dados de achievements por userId para suportar múltiplos perfis futuros |

### RNF04 — Escalabilidade e Manutenibilidade

| ID | Requisito |
|---|---|
| RNF04.1 | Toda leitura/escrita de dados deve passar pelo `LocalStorageService`, nunca diretamente pelo SharedPreferences |
| RNF04.2 | A camada de serviços deve ser substituível por uma implementação Firebase sem alterar as telas |
| RNF04.3 | Novos tipos de achievement devem poder ser adicionados apenas em `AchievementModel.all`, sem alterar o service |
| RNF04.4 | Novas patentes devem poder ser adicionadas apenas em `RankModel.ranks` |
| RNF04.5 | O código deve seguir a separação models / services / screens sem lógica de negócio nas telas |
| RNF04.6 | Operações de escrita devem retornar Result Objects tipados (`ContributionSaveResult`) em vez de lançar exceções para fluxos de sucesso |

### RNF05 — Compatibilidade

| ID | Requisito |
|---|---|
| RNF05.1 | O app deve suportar Android 6.0 (API 23) ou superior |
| RNF05.2 | O app deve ser compilado com Flutter SDK `>=3.3.0` e Dart `>=3.3.0` |
| RNF05.3 | O app deve funcionar em resoluções de tela entre 360dp e 420dp de largura |
