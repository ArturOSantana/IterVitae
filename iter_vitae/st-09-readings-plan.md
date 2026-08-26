# ST-09 — Tela Leituras

## Contexto

Dependência do bloco b da tela de Direção: atualmente agrega práticas com
`category == professional/cultural`. Quando este ST terminar, o `DirectionController`
receberá `ReadingRepository` como fonte adicional. Ver ST-09f.

## Decisões de modelagem confirmadas

| Decisão | Escolha |
|---|---|
| Progresso do livro | Campo `currentPage`/`totalPages` no `Book`; sessão é só log, não fonte de cálculo |
| Status (`quero ler / lendo / concluído`) | Manual — botão explícito; nunca inferido pelo % de páginas |
| Livros "em andamento" por categoria | Vários simultâneos permitidos; sem restrição |

## Categorias de leitura

Três — espelham a divisão já usada no bloco b da Direção:
- `spiritual` (espiritual)
- `cultural` (literatura, filosofia, história)
- `professional` (tecnologia, carreira, formação profissional)

## Entidades

### `Book`

```
id: String
title: String
author: String?
category: ReadingCategory  (spiritual | cultural | professional)
status: BookStatus         (wantToRead | reading | finished)
currentPage: int           (estado atual — não derivado de sessões)
totalPages: int            (0 = não informado)
startedAt: DateTime?
finishedAt: DateTime?
coverEmoji: String         (emoji visual, ex.: 📖 — mesmo padrão de Practice.emoji)
notes: String?             (nota geral sobre o livro, não sobre uma sessão)
```

`progressRatio`: computed — `totalPages == 0 ? 0 : currentPage / totalPages`.
Zerado quando `totalPages == 0`, nunca divide por zero.

### `ReadingSession`

```
id: String
bookId: String
date: DateTime
pagesRead: int?
minutesRead: int?
highlight: String?     (o que me chamou atenção — opcional)
application: String?   (o que posso aplicar — opcional)
```

Ambos os campos de texto são opcionais — não forçar preenchimento.

## Interfaces dos repositórios

### `BookRepository`

```
getAll(): Future<List<Book>>
getByStatus(BookStatus): Future<List<Book>>
save(Book): Future<void>
```

### `ReadingSessionRepository`

```
getForBook(bookId): Future<List<ReadingSession>>
getForPeriod(from, to): Future<List<ReadingSession>>
save(ReadingSession): Future<void>
```

`getForPeriod` é o que o `DirectionController` vai usar no bloco b.

## Estrutura de arquivos

```
lib/
├── domain/
│   ├── entities/
│   │   ├── book.dart
│   │   └── reading_session.dart
│   └── repositories/
│       ├── book_repository.dart
│       └── reading_session_repository.dart
│
├── data/
│   ├── in_memory/
│   │   ├── in_memory_book_repository.dart
│   │   └── in_memory_reading_session_repository.dart
│   └── firebase/
│       ├── firestore_book_repository.dart
│       └── firestore_reading_session_repository.dart
│
└── features/
    └── readings/
        ├── application/
        │   ├── readings_state.dart
        │   ├── readings_controller.dart
        │   ├── book_detail_state.dart
        │   └── book_detail_controller.dart
        └── presentation/
            ├── readings_screen.dart         (lista agrupada por categoria)
            ├── book_detail_screen.dart      (detalhe + sessões anteriores)
            ├── book_form_screen.dart        (novo livro / editar)
            └── reading_session_form.dart    (registrar sessão)
```

## Sub-tarefas

### ST-09a — Domínio: entidades + interfaces
**Status:** [ ] pending

**Intent:**
Criar as entidades `Book` e `ReadingSession` e as interfaces dos dois repositórios.
Declarar providers em `providers.dart`.

**Expected Outcomes:**
- `Book` imutável com `copyWith`, `progressRatio` como computed, `isScheduledFor` não existe
  (livro não tem frequência — só `Practice` tem)
- `ReadingSession` imutável com `copyWith`, campos `highlight` e `application` opcionais
- Interfaces `BookRepository` e `ReadingSessionRepository` com os métodos listados acima
- Providers `bookRepositoryProvider` e `readingSessionRepositoryProvider` em `providers.dart`,
  condicionais: Firestore quando logado, InMemory antes do login — mesmo padrão dos outros

**Todo:**
1. `lib/domain/entities/book.dart`
2. `lib/domain/entities/reading_session.dart`
3. `lib/domain/repositories/book_repository.dart`
4. `lib/domain/repositories/reading_session_repository.dart`
5. Declarar providers em `lib/providers.dart`

**Relevant Context:**
- `ReadingCategory` é um novo enum separado de `PracticeCategory` — não reaproveitar
  o enum de práticas; as semânticas são distintas (livro espiritual ≠ prática espiritual)
- `BookStatus.wantToRead` permite uma lista de "quero ler" sem criar livro em andamento

---

### ST-09b — InMemory + Firestore: implementações
**Status:** [ ] pending

**Intent:**
Criar implementações em memória com mock data suficiente para renderizar as telas,
e implementações Firestore para quando o usuário estiver logado.

**Expected Outcomes:**
- `InMemoryBookRepository`: mínimo 3 livros mock (1 espiritual em andamento, 1 cultural
  em andamento, 1 profissional quero-ler)
- `InMemoryReadingSessionRepository`: 2 sessões mock para o livro espiritual (para testar
  a tela de detalhe com histórico de sessões)
- `FirestoreBookRepository`: `/users/{uid}/books/{bookId}`
- `FirestoreReadingSessionRepository`: `/users/{uid}/reading_sessions/{sessionId}`

**Todo:**
1. `lib/data/in_memory/in_memory_book_repository.dart`
2. `lib/data/in_memory/in_memory_reading_session_repository.dart`
3. `lib/data/firebase/firestore_book_repository.dart`
4. `lib/data/firebase/firestore_reading_session_repository.dart`

**Relevant Context:**
- `Book.currentPage` é salvo diretamente — ao salvar uma sessão, o `BookDetailController`
  chama `bookRepository.save(book.copyWith(currentPage: novapágina))` separadamente.
  Os dois repositórios trabalham de forma independente, sem transação entre eles no MVP
- Firestore: `status` serializado como `String` via `.name` (mesmo padrão dos outros repos)

---

### ST-09c — Tela principal: ReadingsScreen + ReadingsController
**Status:** [ ] pending

**Intent:**
Tela raiz de Leituras: lista agrupada por categoria (`spiritual`, `cultural`, `professional`),
apenas livros `status == reading` aparecem por padrão, com toggle para mostrar "quero ler"
e "concluídos". Controller carrega todos os livros e expõe o agrupamento.

**Expected Outcomes:**
- `ReadingsState.grouped`: `Map<ReadingCategory, List<Book>>` com livros `reading` primeiro
- Tela renderiza os três grupos com rótulo de categoria (mesmo padrão de `_CategoryHeader`
  da `LifePlanScreen` — não reinventar estilo)
- Cada linha: emoji + título + autor + barra de progresso fina (LinearProgressIndicator de 4px)
  + percentual (ex.: "67%") — barra de progresso **é** adequada aqui (progresso de leitura
  ≠ fidelidade espiritual)
- Tap na linha → `BookDetailScreen`
- Botão "Adicionar livro" no rodapé — mesmo padrão `OutlinedButton` da `LifePlanScreen`
- Edge case "lista vazia": mensagem "Adicione seus livros para acompanhar sua leitura."
- Nenhuma meta numérica em destaque (sem "faltam X páginas para a meta do mês")

**Todo:**
1. `lib/features/readings/application/readings_state.dart`
2. `lib/features/readings/application/readings_controller.dart`
3. `lib/features/readings/presentation/readings_screen.dart`

**Relevant Context:**
- `ReadingsController` é `AsyncNotifier<ReadingsState>` — mesmo padrão de `LifePlanController`
- Conectar rota `/leituras` ao `ReadingsScreen` em `app_router.dart`

---

### ST-09d — Tela de detalhe: BookDetailScreen + BookDetailController
**Status:** [ ] pending

**Intent:**
Tela de detalhe de um livro: progresso ampliado, botão "Continuar leitura" (abre o
formulário de sessão), lista de sessões anteriores, botão "Marcar como concluído",
botão de editar o livro.

**Expected Outcomes:**
- `BookDetailState`: livro atual + lista de sessões ordenadas por data (mais recente primeiro)
- Barra de progresso grande com `currentPage / totalPages` e percentual
- Lista de sessões: data + páginas lidas (se informado) + primeira linha de `highlight`
  (truncada em 1 linha)
- "Marcar como concluído": muda `status = finished` + registra `finishedAt = hoje`
  — update otimista + salva no repositório
- "Continuar leitura": navega para `ReadingSessionForm`; ao voltar com sessão salva,
  atualiza `currentPage` do livro automaticamente
- Edge case: livro `wantToRead` sem sessões → exibe "Você ainda não começou este livro."

**Todo:**
1. `lib/features/readings/application/book_detail_state.dart`
2. `lib/features/readings/application/book_detail_controller.dart`
3. `lib/features/readings/presentation/book_detail_screen.dart`

**Relevant Context:**
- `BookDetailController` recebe o `bookId` como parâmetro via `family` do Riverpod
  (`AsyncNotifierProvider.family<BookDetailController, BookDetailState, String>`)
- Ao salvar uma sessão, o controller chama os dois repos separadamente:
  `readingSessionRepository.save(session)` + `bookRepository.save(book.copyWith(currentPage: ...))`
- `finishedAt` é salvo no `Book`, não inferido

---

### ST-09e — Formulários: BookFormScreen + ReadingSessionForm
**Status:** [ ] pending

**Intent:**
Dois formulários:
1. `BookFormScreen`: criar/editar livro (título, autor, categoria, status inicial, páginas totais, emoji)
2. `ReadingSessionForm`: registrar uma sessão (página atual pós-leitura, tempo, highlight, application)

**Expected Outcomes:**
- `BookFormScreen`: campos título (obrigatório), autor (opcional), categoria (chips),
  status inicial (chips: quero ler / lendo), emoji, total de páginas (opcional — 0 = não informado)
  — mesmo padrão visual de `PracticeFormScreen`
- `ReadingSessionForm`: campo "página atual" (inteiro, obrigatório), tempo (opcional),
  "o que me chamou atenção" (opcional, multilinha), "o que posso aplicar" (opcional, multilinha)
  — nenhum dos dois campos de texto obrigatório, mesmo que o spec os mencione
- Ambos retornam o objeto criado/editado via `Navigator.pop` para o controller do chamador
- `BookFormScreen` exibe aviso discreto em edição ("As alterações não afetam sessões registradas")

**Todo:**
1. `lib/features/readings/presentation/book_form_screen.dart`
2. `lib/features/readings/presentation/reading_session_form.dart`

**Relevant Context:**
- `ReadingSessionForm` recebe o `Book` atual para calcular o delta de páginas e pré-preencher
  o campo "página atual" com `book.currentPage + 1` (sugestão, editável)
- `BookFormScreen` não tem campo "página atual" — esse campo só aparece no `ReadingSessionForm`

---

### ST-09f — Correção: bloco b do DirectionController
**Status:** [ ] pending

**Intent:**
Corrigir a pendência registrada: adicionar `ReadingSessionRepository` como fonte de dados
do bloco b na tela de Direção, ao lado das práticas profissionais/culturais que já existem.

**Expected Outcomes:**
- `BlockBData` ganha campo `recentReadingSessions: List<ReadingSession>`
- `DirectionController` lê sessões de leitura do período via `readingSessionRepository.getForPeriod`
- `DirectionBlockB` exibe seção "Leituras do período" com título e sessões abreviadas,
  antes do campo de notas livre
- O TODO deixado no `DirectionController` é removido

**Todo:**
1. Atualizar `BlockBData` em `direction_state.dart`
2. Atualizar `DirectionController.build()` para chamar `readingSessionRepositoryProvider`
3. Atualizar `DirectionBlockB` para exibir as sessões de leitura

**Relevant Context:**
- Executar esta sub-tarefa depois de ST-09b (os repositórios precisam existir)
- O `readingSessionRepositoryProvider` declarado em ST-09a já estará disponível
- Manter as práticas profissionais/culturais que já existem no bloco b — adicionar as
  sessões como complemento, não substituição

---

## Ordem de execução

```
ST-09a (domínio)
    ↓
ST-09b (implementações)
    ↓
ST-09c + ST-09d + ST-09e (podem rodar em paralelo)
    ↓
ST-09f (correção do bloco b — depende de ST-09b)
```
