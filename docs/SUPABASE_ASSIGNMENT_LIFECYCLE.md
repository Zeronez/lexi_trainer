# Supabase Assignment Lifecycle RPC

Документ описывает RPC-функции для прохождения задания студентом. Все функции используют `auth.uid()` как текущего пользователя и работают только для `authenticated` роли.

## Функции

### `start_task_execution(p_task_id bigint) returns bigint`

Создает или переводит существующий `task_executions` текущего пользователя по задаче в статус `in_progress` и возвращает `task_execution_id`.

Поведение:

- Если для пары `auth.uid()` + `p_task_id` уже есть execution в статусе `assigned` или `in_progress`, возвращает его id.
- Если execution найден не в `in_progress`, но еще не `completed`, переводит его в `in_progress`.
- Если execution уже `completed`, возвращает ошибку и не открывает его заново.
- Если execution еще не существует, создает новый со статусом `in_progress`.
- Проверяет, что задача существует и доступна текущему пользователю через `public.can_read_task(p_task_id)`.

### `submit_attempt(p_task_execution_id bigint, p_started_at timestamptz, p_ended_at timestamptz) returns bigint`

Создает запись в `attempts` для execution текущего пользователя и возвращает `attempt_id`.

Поведение:

- Проверяет, что execution принадлежит `auth.uid()`.
- Разрешает отправку только для execution в статусе `in_progress`.
- Проверяет, что `p_ended_at >= p_started_at`.
- Учитывает лимит `tasks.attempts_count`.
- Блокирует строку execution на время проверки лимита и вставки, чтобы параллельные запросы не превысили лимит попыток.

### `submit_question_answer(p_attempt_id bigint, p_word_id bigint, p_entered_answer text, p_is_correct boolean) returns bigint`

Создает или обновляет ответ на слово в рамках попытки и возвращает `question_answers.id`.

Поведение:

- Проверяет, что попытка относится к execution текущего пользователя.
- Разрешает отправку ответов только для execution в статусе `in_progress`.
- Проверяет, что `p_word_id` входит в набор слов задачи через `set_words_link`.
- Если ответ для пары `p_attempt_id` + `p_word_id` уже существует, обновляет `entered_answer` и `is_correct` и возвращает существующий id.
- Если ответа еще нет, создает новую запись.

### `complete_task_execution(p_task_execution_id bigint) returns void`

Завершает execution текущего пользователя.

Поведение:

- Проверяет, что execution принадлежит `auth.uid()`.
- Если execution уже `completed`, завершает вызов без изменений.
- Если execution в статусе `in_progress`, переводит его в статус `completed`.
- Использует `statuses.name = 'completed'`, а не захардкоженный `status_id`.

## Примеры вызовов

Через Supabase JS:

```ts
const { data: executionId, error: startError } = await supabase.rpc(
  'start_task_execution',
  { p_task_id: 42 }
);

const { data: attemptId, error: attemptError } = await supabase.rpc(
  'submit_attempt',
  {
    p_task_execution_id: executionId,
    p_started_at: new Date('2026-04-10T10:00:00Z').toISOString(),
    p_ended_at: new Date('2026-04-10T10:05:00Z').toISOString()
  }
);

const { data: answerId, error: answerError } = await supabase.rpc(
  'submit_question_answer',
  {
    p_attempt_id: attemptId,
    p_word_id: 1001,
    p_entered_answer: 'cat',
    p_is_correct: true
  }
);

const { error: completeError } = await supabase.rpc(
  'complete_task_execution',
  { p_task_execution_id: executionId }
);
```

Через SQL:

```sql
select public.start_task_execution(42);

select public.submit_attempt(
    10,
    '2026-04-10T10:00:00Z'::timestamptz,
    '2026-04-10T10:05:00Z'::timestamptz
);

select public.submit_question_answer(20, 1001, 'cat', true);

select public.complete_task_execution(10);
```

## Ожидаемые ошибки

- `Authentication required`: вызов без `auth.uid()`, например неавторизованный пользователь.
- `Task id is required`, `Task execution id is required`, `Attempt id is required`, `Word id is required`: обязательный id не передан.
- `Entered answer is required`, `Answer correctness flag is required`: обязательные поля ответа не переданы.
- `Attempt started_at is required`, `Attempt ended_at is required`: обязательное время попытки не передано.
- `Attempt ended_at must be greater than or equal to started_at`: время окончания попытки раньше времени начала.
- `Current user profile does not exist`: в `public.users` нет профиля для `auth.uid()`.
- `Task <id> does not exist`: задача не найдена.
- `Task <id> is not available for current user`: текущий пользователь не может читать задачу.
- `Task execution <id> does not exist`: execution не найден.
- `Task execution <id> does not belong to current user`: execution принадлежит другому пользователю.
- `Task execution <id> is already completed`: попытка заново открыть завершенный execution.
- `Task execution <id> must be in_progress to submit an attempt`: нельзя отправить попытку, пока execution не начат или уже завершен.
- `Task execution <id> must be in_progress to submit answers`: нельзя отправить ответы, пока execution не начат или уже завершен.
- `Task execution <id> must be in_progress to complete`: нельзя завершить execution из текущего статуса.
- `Attempts limit exceeded for task execution <id>`: лимит `tasks.attempts_count` уже исчерпан.
- `Word <id> is not part of task <id> vocabulary set`: слово не входит в набор слов задачи.
- `Status in_progress does not exist`, `Status completed does not exist`: отсутствует обязательный seed-статус.
