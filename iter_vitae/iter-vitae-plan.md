# Iter Vitae — Plano de Implementação: Tela Hoje + Preparação para Direção

## Visão geral

Implementar as duas telas centrais do MVP do Iter Vitae em Flutter (Riverpod + GoRouter),
partindo do zero (workspace vazio). O escopo cobre:

1. **Tela Hoje** — dashboard diário com resumo de fidelidade, card de Luta atual e lista de práticas
2. **Tela Preparação para Direção** — estruturada exatamente nos blocos a/b/c do roteiro do padre

Ambas as telas usam implementações em memória nos repositórios (sem Firebase ainda).
O modelo de dados e a arquitetura de camadas estabelecidos aqui valem para o restante do app.

---

## Decisões de design confirmadas

- **Nav:** `Hoje · Regra de Vida · Leituras · Direção · Mais`
- **Luta atual:** entidade independente em `/struggles/{id}`, com `directionId?` opcional.
  A tela Hoje e a Direção apenas referenciam — não possuem o dado.
- **Sem hardcode de cores:** todos os tokens passam por `AppColors` / `AppTheme`.
- **Sem Firebase agora:** repositórios são interfaces + implementações em memória (TODO: Firestore).
- **Ações otimistas:** concluir prática ou marcar estado de luta atualiza a UI antes do repositório confirmar.
- **Layout responsivo:** mobile usa `BottomNavigationBar`; tablet/desktop usa `NavigationRail`.
- **Sem % em virtudes:** o conceito de fidelidade (%) se aplica a práticas planejadas, nunca a virtudes.
- **Campos sensíveis:** nunca estruturados como pergunta direta; vivem como texto livre no Diário.

---

## Estrutura de arquivos-alvo

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   └── router/
│       └── app_router.dart
│
├── domain/
│   ├── entities/
│   │   ├── practice.dart
│   │   ├── practice_log.dart
│   │   ├── struggle.dart
│   │   ├── reflection.dart
│   │   └── virtue.dart
│   └── repositories/
│       ├── practice_repository.dart
│       ├── struggle_repository.dart
│       └── reflection_repository.dart
│
├── data/
│   └── in_memory/
│       ├── in_memory_practice_repository.dart
│       ├── in_memory_struggle_repository.dart
│       └── in_memory_reflection_repository.dart
│
├── features/
│   ├── hoje/
│   │   ├── application/
│   │   │   ├── hoje_state.dart
│   │   │   └── hoje_controller.dart
│   │   └── presentation/
│   │       ├── hoje_screen.dart
│   │       └── widgets/
│   │           ├── progress_card.dart
│   │           ├── struggle_card.dart
│   │           ├── practice_list_item.dart
│   │           ├── virtue_banner.dart
│   │           └── reflection_input.dart
│   │
│   └── direction/
│       ├── application/
│       │   ├── direction_state.dart
│       │   └── direction_controller.dart
│       └── presentation/
│           ├── direction_screen.dart
│           └── widgets/
│               ├── direction_block_a.dart
│               ├── direction_block_b.dart
│               └── direction_block_c.dart
│
├── providers.dart
└── main.dart
```

---

## Sub-tarefas

### ST-01 — Fundação: tema, tokens e roteamento
**Status:** [ ] pending

**Intent:**
Criar os arquivos de design tokens (`AppColors`, `AppTheme`) e o roteador (`GoRouter`)
com as 5 rotas do bottom nav. Tudo o que vem depois depende desses arquivos.

**Expected Outcomes:**
- `AppColors` define todos os tokens de cor referenciados nas próximas telas
  (primária, superfície, erro, texto-muted, categorias espiritual/humana/profissional/cultural/apostolado)
- `AppTheme` expõe `ThemeData` com Material 3, usando `AppColors`
- `AppRouter` declara as 5 rotas: `/hoje`, `/regra-de-vida`, `/leituras`, `/direcao`, `/mais`
- `main.dart` inicializa `ProviderScope` + `MaterialApp.router`

**Todo:**
1. Criar `lib/core/theme/app_colors.dart` com tokens de cor (sem hardcode em outros arquivos)
2. Criar `lib/core/theme/app_theme.dart` com `ThemeData` Material 3
3. Criar `lib/core/router/app_router.dart` com GoRouter + 5 rotas stub
4. Criar `lib/main.dart` com `ProviderScope` + `MaterialApp.router`
5. Criar shell responsiva: `BottomNavigationBar` em mobile, `NavigationRail` em tablet/desktop
   (breakpoint: largura >= 600 px usa Rail)

**Relevant Context:**
- Tokens de cor das categorias devem ser nomeados por semântica: `AppColors.spiritual`,
  `AppColors.human`, `AppColors.professional`, `AppColors.cultural`, `AppColors.apostolate`
- A shell responsiva é implementada uma vez aqui e reutilizada por todas as features

---

### ST-02 — Domínio e repositórios
**Status:** [ ] pending

**Intent:**
Definir as entidades de domínio e as interfaces dos repositórios usados pelas duas telas.
Criar as implementações em memória com dados mock suficientes para renderizar as telas
com conteúdo real (não telas em branco).

**Expected Outcomes:**
- Entidades imutáveis em Dart (usando `copyWith`): `Practice`, `PracticeLog`, `Struggle`,
  `Reflection`, `Virtue`
- Interfaces: `PracticeRepository`, `StruggleRepository`, `ReflectionRepository`
- Implementações em memória com dados mock (mínimo 4 práticas, 1 luta ativa, 1 virtude do mês)
- Providers Riverpod para os repositórios declarados em `lib/providers.dart`

**Todo:**
1. Criar entidades em `lib/domain/entities/` (imutáveis, `copyWith`, `==` e `hashCode` via Dart)
2. Criar interfaces dos repositórios em `lib/domain/repositories/`
3. Criar implementações em `lib/data/in_memory/` com mock data estático
4. Declarar providers dos repositórios em `lib/providers.dart` usando `Provider` do Riverpod

**Relevant Context:**
- `Struggle` tem campos: `id`, `title`, `directionId?`, `startDate`, e uma lista de
  `DailyStruggleLog` com `date` e `status` (enum: `achieved / fought / didNotFight`)
- `Practice` tem: `id`, `name`, `category` (enum de 5 valores), `scheduledTime`, `emoji`
- `PracticeLog` tem: `id`, `practiceId`, `date`, `completed`, `skipReason?`, `reflection?`,
  `duration?`, `lights?` (campo especial para oração mental)
- `Reflection` é o texto livre do exame noturno: `id`, `date`, `text`
- `Virtue` tem: `id`, `name`, `month`, `purpose`, `reflections: List<String>`
- Não usar `freezed` ou `json_serializable` agora — entidades simples em Dart puro

---

### ST-03 — Tela Hoje: controller + estado
**Status:** [ ] pending

**Intent:**
Implementar `HojeController` como `AsyncNotifier` do Riverpod, carregando práticas do dia,
luta ativa e virtude do mês. Ações otimistas para completar prática e marcar estado de luta.

**Expected Outcomes:**
- `HojeState` carrega: lista de práticas do dia com status, luta ativa, virtude do mês,
  progresso do dia (X/Y e percentual), e texto da reflexão noturna
- `HojeController.completePractice(id)` aplica mudança na UI antes de chamar o repositório
- `HojeController.markStruggle(id, status)` idem para luta
- `HojeController.saveReflection(text)` persiste texto no `ReflectionRepository`
- Estados de edge case cobertos: lista vazia (nenhuma prática hoje), dia 100% cumprido

**Todo:**
1. Criar `lib/features/hoje/application/hoje_state.dart` com todos os campos necessários
2. Criar `lib/features/hoje/application/hoje_controller.dart` como `AsyncNotifier<HojeState>`
3. Implementar `build()` lendo de `PracticeRepository` e `StruggleRepository` para a data de hoje
4. Implementar `completePractice()` com update otimista (state primeiro, repositório depois)
5. Implementar `markStruggle()` idem
6. Implementar `saveReflection()` chamando `ReflectionRepository`
7. Declarar o provider do controller em `lib/providers.dart`

**Relevant Context:**
- O progresso do dia é calculado no controller, não no widget
- "Lista vazia" significa que o usuário não tem práticas configuradas para hoje —
  o estado deve carregar uma mensagem específica, não um spinner eterno
- "100% cumprido" deve expor um campo booleano no estado para a UI reagir visualmente

---

### ST-04 — Tela Hoje: widgets e composição
**Status:** [ ] pending

**Intent:**
Compor a tela Hoje a partir dos widgets reutilizáveis e conectá-la ao `HojeController`.
Cobrir os edge cases visualmente.

**Expected Outcomes:**
- `HojeScreen` renderiza corretamente nas três condições: carregando, erro, dados
- `ProgressCard` mostra X/Y práticas e barra de progresso animada; cor muda quando 100%
- `StruggleCard` mostra título da luta ativa e três botões de estado tocáveis
- `PracticeListItem` mostra emoji, nome, horário, status; toque chama `completePractice()`
- `VirtueBanner` mostra virtude do mês e propósito (sem percentual)
- `ReflectionInput` é campo de texto multilinha com botão salvar; desabilita se já salvo hoje
- Edge case "lista vazia": tela mostra mensagem "Configure suas práticas na Regra de Vida"
- Edge case "100% cumprido": `ProgressCard` muda cor e exibe mensagem de encorajamento
- Layout responsivo: mobile usa bottom nav herdado da shell; tablet mostra rail lateral

**Todo:**
1. Criar `lib/features/hoje/presentation/widgets/progress_card.dart`
2. Criar `lib/features/hoje/presentation/widgets/struggle_card.dart`
3. Criar `lib/features/hoje/presentation/widgets/practice_list_item.dart`
4. Criar `lib/features/hoje/presentation/widgets/virtue_banner.dart`
5. Criar `lib/features/hoje/presentation/widgets/reflection_input.dart`
6. Criar `lib/features/hoje/presentation/hoje_screen.dart` compondo todos os widgets acima
7. Conectar ao provider do `HojeController`

**Relevant Context:**
- Nenhum widget recebe cor hardcoded: todos usam `AppColors.*` ou `Theme.of(context).*`
- `StruggleCard` usa os três estados do enum: `achieved` (verde/check), `fought` (amarelo/escudo),
  `didNotFight` (vermelho/x) — com ícone + label, sem percentual
- `VirtueBanner` não tem barra de progresso (decisão de design confirmada)
- `ReflectionInput` pertence à seção "Exame rápido do dia" no final da tela
- A ordem visual na tela é: saudação + data → ProgressCard → StruggleCard → lista de práticas
  → VirtueBanner → ReflectionInput

---

### ST-05 — Tela Preparação para Direção: controller + estado
**Status:** [ ] pending

**Intent:**
Implementar o controller da tela de Preparação para Direção, que agrega dados reais
do app nos três blocos do roteiro do padre (a/b/c) e permite adicionar notas e questões.

**Expected Outcomes:**
- `DirectionState` contém: dados agregados do bloco a (práticas espirituais + luta + oração mental),
  bloco b (leituras profissionais/culturais + estudos), bloco c (reflexões de família/virtudes),
  lista de questões para levar, propósitos anteriores com status, `SpiritualDirection` ativa
- Controller determina o período de agregação a partir da última `SpiritualDirection` com
  `date < hoje`. Fallback quando não existe direção anterior: `user.createdAt` (início do uso).
  Nunca usar janela fixa de 30 dias — o intervalo entre direções varia
- Questões e notas de preparação são persistidas na `SpiritualDirection` ativa
  via `DirectionRepository` — não somem ao fechar a tela

**Todo:**
1. Criar `lib/features/direction/application/direction_state.dart`
2. Criar `lib/domain/repositories/direction_repository.dart` (interface)
3. Criar `lib/data/in_memory/in_memory_direction_repository.dart` com mock data
   (uma direção passada + uma futura, para testar o período de agregação)
4. Criar `lib/features/direction/application/direction_controller.dart` como `AsyncNotifier`
5. Implementar `_resolvePeriod()`: busca última direção com `date < hoje` no `DirectionRepository`;
   fallback para `user.createdAt` (mock: data de hoje menos 45 dias no MVP em memória)
6. Implementar agregação do bloco a: fidelidade das práticas com `category == spiritual`,
   últimos registros de `lights` de práticas com `tipo == contemplativa`, estado da luta ativa
7. Implementar agregação do bloco b: progresso de práticas com `category == professional/cultural`
8. Implementar agregação do bloco c: últimas reflexões do `ReflectionRepository` no período
9. Implementar `saveNote(block, text)` persistindo em `direction.notasPreparacao` via `DirectionRepository`
10. Implementar `addQuestion(text)` e `toggleQuestion(id)` persistindo na direção ativa
11. Declarar provider em `lib/providers.dart`

**Relevant Context:**
- `DirectionRepository` precisa existir aqui (ST-05) porque ST-06 depende de persistência real das notas
- Os dados do bloco a vêm de `PracticeRepository` + `StruggleRepository`
- Os dados do bloco b vêm de `PracticeRepository` (filtros: `professional`, `cultural`)
- Os dados do bloco c vêm de `ReflectionRepository`
- A `SpiritualDirection` "ativa" para preparação é a próxima direção futura (a de `nextDate`)
  ou uma nova criada automaticamente se não existir nenhuma futura ainda

---

### ST-06 — Tela Preparação para Direção: widgets e composição
**Status:** [ ] pending

**Intent:**
Compor a tela de Preparação para Direção com os três blocos do roteiro do padre,
cada bloco como widget colapsável mostrando dados reais agregados e campo de notas.

**Expected Outcomes:**
- `DirectionScreen` renderiza os três blocos a/b/c com cabeçalho, dados agregados e campo de nota
- `DirectionBlockA` mostra: fidelidade espiritual (%), luta ativa com estado do período,
  campo "Dificuldades na oração mental" e campo "Luzes recebidas"
- `DirectionBlockB` mostra: progresso leituras culturais/profissionais, campo de notas sobre estudos
- `DirectionBlockC` mostra: reflexões recentes do diário, campo livre para notas sobre família/virtudes
- Seção de questões: lista editável com checkbox "resolvida", botão para adicionar nova questão
- Tela tem botão "Gerar relatório" (stub — TODO: PDF) no final

**Todo:**
1. Criar `lib/features/direction/presentation/widgets/direction_block_a.dart`
2. Criar `lib/features/direction/presentation/widgets/direction_block_b.dart`
3. Criar `lib/features/direction/presentation/widgets/direction_block_c.dart`
4. Criar `lib/features/direction/presentation/direction_screen.dart` compondo os blocos
5. Adicionar seção de questões com `TextField` + botão adicionar + lista com `Checkbox`
6. Adicionar botão "Gerar relatório" (stub — exibe SnackBar "Em breve")
7. Conectar ao provider do `DirectionController`

**Relevant Context:**
- Cada bloco usa `ExpansionTile` do Material 3 para colapsar/expandir
- Os campos de nota dentro dos blocos chamam `controller.saveNote(block, text)` ao perder foco,
  persistindo em `SpiritualDirection.notasPreparacao.{a|b|c}` via `DirectionRepository`
- Campos sensíveis nunca aparecem como pergunta estruturada — o bloco c tem apenas
  "Reflexões recentes" (texto do diário) + um campo livre "Notas para o padre"
- O título de cada bloco espelha exatamente o roteiro: "a) Formação espiritual",
  "b) Formação profissional, social e cultural", "c) Formação humana"
- A tela de Direção no bottom nav mostra esta tela de preparação por padrão no MVP

---

## Ordem de execução

```
ST-01 (tema + router)
    ↓
ST-02 (domínio + repositórios)
    ↓
ST-03 + ST-05 (controllers — podem rodar em paralelo)
    ↓
ST-04 + ST-06 (widgets — podem rodar em paralelo)
```

ST-03 e ST-05 dependem de ST-02.
ST-04 depende de ST-03. ST-06 depende de ST-05.
ST-03 e ST-05 não dependem entre si → paralelo.
ST-04 e ST-06 não dependem entre si → paralelo.

---

## Contexto adicionado após implementação

### Decisões tomadas durante a implementação

- **Imports**: todos os arquivos de features usam imports de pacote (`package:iter_vitae/...`)
  em vez de caminhos relativos, para evitar ambiguidade de profundidade de diretório.
- **`intl: ^0.20.2`** adicionado ao pubspec para `DateFormat` nas telas Hoje e Direção.
- **`DailyStruggleStatus` no `StruggleCard`**: o import vem de `struggle.dart` (entidade),
  não da tela — mantém o widget desacoplado do controller.
- **Shell responsiva em `lib/core/shell/app_shell.dart`** (não no router) — o router apenas
  declara o `ShellRoute` com `AppShell` como builder.
- **`_EmptyState` sem chave `super.key`** — é widget privado da tela, não precisa de key.
- **`InMemoryVirtueRepository`** criado apesar de não estar no plano original —
  necessário porque `HojeController` depende de `VirtueRepository`.
- **Período de agregação do `DirectionController`**: usa `today0` (meia-noite) em vez de
  `DateTime.now()` para evitar inconsistências de hora ao comparar datas.
- **`getOrCreateNext()`**: cria uma direção em branco 30 dias à frente se não existir nenhuma
  futura — isso é MVP correto; Firestore implementará persistência real depois.
