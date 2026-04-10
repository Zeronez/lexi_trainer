BEGIN;

-- Full seed dataset for manual MVP testing.
-- Date baseline: 2026-03-20 (UTC).
-- Requires at least 6 rows in public.users (linked to auth.users).

CREATE TEMP TABLE seed_users AS
SELECT id, row_number() OVER (ORDER BY registered_at, id) AS rn
FROM public.users
ORDER BY registered_at, id
LIMIT 8;

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT count(*) INTO v_count FROM seed_users;
    IF v_count < 6 THEN
        RAISE EXCEPTION 'Need at least 6 users in public.users before applying seed. Found: %', v_count;
    END IF;
END;
$$;

-- Role ids
CREATE TEMP TABLE seed_roles AS
SELECT
    (SELECT id FROM public.roles WHERE name = 'admin' LIMIT 1) AS admin_id,
    (SELECT id FROM public.roles WHERE name = 'teacher' LIMIT 1) AS teacher_id,
    (SELECT id FROM public.roles WHERE name = 'student' LIMIT 1) AS student_id;

DO $$
DECLARE
    a BIGINT;
    t BIGINT;
    s BIGINT;
BEGIN
    SELECT admin_id, teacher_id, student_id INTO a, t, s FROM seed_roles;
    IF a IS NULL OR t IS NULL OR s IS NULL THEN
        RAISE EXCEPTION 'Missing required roles (admin/teacher/student). Run base seed migration first.';
    END IF;
END;
$$;

-- Status ids
CREATE TEMP TABLE seed_statuses AS
SELECT
    (SELECT id FROM public.statuses WHERE name = 'assigned' LIMIT 1) AS assigned_id,
    (SELECT id FROM public.statuses WHERE name = 'in_progress' LIMIT 1) AS in_progress_id,
    (SELECT id FROM public.statuses WHERE name = 'completed' LIMIT 1) AS completed_id,
    (SELECT id FROM public.statuses WHERE name = 'overdue' LIMIT 1) AS overdue_id;

DO $$
DECLARE
    a BIGINT;
    p BIGINT;
    c BIGINT;
    o BIGINT;
BEGIN
    SELECT assigned_id, in_progress_id, completed_id, overdue_id INTO a, p, c, o FROM seed_statuses;
    IF a IS NULL OR p IS NULL OR c IS NULL OR o IS NULL THEN
        RAISE EXCEPTION 'Missing required statuses (assigned/in_progress/completed/overdue).';
    END IF;
END;
$$;

-- Cleanup previous seed ranges (idempotent)
DELETE FROM public.question_answers WHERE id BETWEEN 24001 AND 24024;
DELETE FROM public.attempts WHERE id BETWEEN 23001 AND 23018;
DELETE FROM public.task_executions WHERE id BETWEEN 22001 AND 22012;
DELETE FROM public.tasks WHERE id BETWEEN 21001 AND 21012;
DELETE FROM public.set_words_link WHERE vocabulary_set_id BETWEEN 20001 AND 20008;
DELETE FROM public.vocabulary_sets WHERE id BETWEEN 20001 AND 20008;
DELETE FROM public.words WHERE id BETWEEN 19001 AND 19024;
DELETE FROM public.notification_users_link WHERE notification_id BETWEEN 26001 AND 26010;
DELETE FROM public.notifications WHERE id BETWEEN 26001 AND 26010;
DELETE FROM public.user_achievements_link WHERE achievement_id BETWEEN 27001 AND 27008;
DELETE FROM public.achievements WHERE id BETWEEN 27001 AND 27008;
DELETE FROM public.study_groups WHERE id BETWEEN 18001 AND 18006;

-- 6 study groups
INSERT INTO public.study_groups (id, name, created_at, updated_at)
VALUES
    (18001, 'Группа A1', '2026-03-20T09:00:00Z', '2026-03-20T09:00:00Z'),
    (18002, 'Группа A2', '2026-03-20T09:05:00Z', '2026-03-20T09:05:00Z'),
    (18003, 'Группа B1', '2026-03-20T09:10:00Z', '2026-03-20T09:10:00Z'),
    (18004, 'Группа B2', '2026-03-20T09:15:00Z', '2026-03-20T09:15:00Z'),
    (18005, 'Группа C1', '2026-03-20T09:20:00Z', '2026-03-20T09:20:00Z'),
    (18006, 'Группа C2', '2026-03-20T09:25:00Z', '2026-03-20T09:25:00Z')
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at;

-- Normalize first 8 users for deterministic testing
UPDATE public.users u
SET
    study_group_id = CASE
        WHEN su.rn = 1 THEN 18001
        WHEN su.rn = 2 THEN 18001
        WHEN su.rn = 3 THEN 18002
        WHEN su.rn = 4 THEN 18003
        WHEN su.rn = 5 THEN 18004
        WHEN su.rn = 6 THEN 18005
        WHEN su.rn = 7 THEN 18006
        WHEN su.rn = 8 THEN 18002
    END,
    role_id = CASE
        WHEN su.rn = 1 THEN (SELECT admin_id FROM seed_roles)
        WHEN su.rn IN (2, 3) THEN (SELECT teacher_id FROM seed_roles)
        ELSE (SELECT student_id FROM seed_roles)
    END,
    registered_at = '2026-03-20T08:00:00Z'::timestamptz + ((su.rn - 1) || ' minutes')::interval,
    updated_at = '2026-03-20T08:30:00Z'
FROM seed_users su
WHERE u.id = su.id;

-- 24 words
INSERT INTO public.words (id, russian_word, english_translation, transcription, example_sentence)
VALUES
    (19001, 'яблоко', 'apple', '[ˈæpəl]', 'I eat an apple every day.'),
    (19002, 'книга', 'book', '[bʊk]', 'This book is very useful.'),
    (19003, 'вода', 'water', '[ˈwɔːtə]', 'Drink more water.'),
    (19004, 'солнце', 'sun', '[sʌn]', 'The sun is bright today.'),
    (19005, 'школа', 'school', '[skuːl]', 'She goes to school by bus.'),
    (19006, 'дом', 'house', '[haʊs]', 'Their house is near the park.'),
    (19007, 'город', 'city', '[ˈsɪti]', 'Moscow is a big city.'),
    (19008, 'учитель', 'teacher', '[ˈtiːtʃə]', 'Our teacher is kind.'),
    (19009, 'студент', 'student', '[ˈstjuːdənt]', 'He is a medical student.'),
    (19010, 'время', 'time', '[taɪm]', 'Time is very important.'),
    (19011, 'день', 'day', '[deɪ]', 'It was a busy day.'),
    (19012, 'ночь', 'night', '[naɪt]', 'Good night and sweet dreams.'),
    (19013, 'друг', 'friend', '[frend]', 'My friend lives nearby.'),
    (19014, 'семья', 'family', '[ˈfæməli]', 'Her family is large.'),
    (19015, 'работа', 'work', '[wɜːk]', 'I start work at nine.'),
    (19016, 'вопрос', 'question', '[ˈkwestʃən]', 'Ask me a question.'),
    (19017, 'ответ', 'answer', '[ˈɑːnsə]', 'Your answer is correct.'),
    (19018, 'окно', 'window', '[ˈwɪndəʊ]', 'Open the window, please.'),
    (19019, 'дверь', 'door', '[dɔː]', 'Close the door quietly.'),
    (19020, 'машина', 'car', '[kɑː]', 'My car is new.'),
    (19021, 'улица', 'street', '[striːt]', 'The street is empty.'),
    (19022, 'магазин', 'shop', '[ʃɒp]', 'The shop opens at ten.'),
    (19023, 'еда', 'food', '[fuːd]', 'Healthy food is important.'),
    (19024, 'язык', 'language', '[ˈlæŋɡwɪdʒ]', 'English is an international language.')
ON CONFLICT (id) DO UPDATE
SET russian_word = EXCLUDED.russian_word,
    english_translation = EXCLUDED.english_translation,
    transcription = EXCLUDED.transcription,
    example_sentence = EXCLUDED.example_sentence;

-- 8 vocabulary sets
INSERT INTO public.vocabulary_sets (id, theme_name, cefr_level, created_at, user_id, updated_at)
VALUES
    (20001, 'Базовые существительные', 'A1', '2026-03-20T10:00:00Z', (SELECT id FROM seed_users WHERE rn = 2), '2026-03-20T10:00:00Z'),
    (20002, 'Учеба и школа', 'A1', '2026-03-20T10:05:00Z', (SELECT id FROM seed_users WHERE rn = 3), '2026-03-20T10:05:00Z'),
    (20003, 'Город и транспорт', 'A2', '2026-03-20T10:10:00Z', (SELECT id FROM seed_users WHERE rn = 2), '2026-03-20T10:10:00Z'),
    (20004, 'Дом и быт', 'A2', '2026-03-20T10:15:00Z', (SELECT id FROM seed_users WHERE rn = 4), '2026-03-20T10:15:00Z'),
    (20005, 'Общение', 'B1', '2026-03-20T10:20:00Z', (SELECT id FROM seed_users WHERE rn = 3), '2026-03-20T10:20:00Z'),
    (20006, 'Ежедневная рутина', 'A2', '2026-03-20T10:25:00Z', (SELECT id FROM seed_users WHERE rn = 5), '2026-03-20T10:25:00Z'),
    (20007, 'Работа и цели', 'B1', '2026-03-20T10:30:00Z', (SELECT id FROM seed_users WHERE rn = 6), '2026-03-20T10:30:00Z'),
    (20008, 'Путешествия', 'B1', '2026-03-20T10:35:00Z', (SELECT id FROM seed_users WHERE rn = 7), '2026-03-20T10:35:00Z')
ON CONFLICT (id) DO UPDATE
SET theme_name = EXCLUDED.theme_name,
    cefr_level = EXCLUDED.cefr_level,
    created_at = EXCLUDED.created_at,
    user_id = EXCLUDED.user_id,
    updated_at = EXCLUDED.updated_at;

-- 24 links (3 words per set)
INSERT INTO public.set_words_link (vocabulary_set_id, word_id)
VALUES
    (20001, 19001), (20001, 19002), (20001, 19003),
    (20002, 19005), (20002, 19008), (20002, 19009),
    (20003, 19007), (20003, 19020), (20003, 19021),
    (20004, 19006), (20004, 19018), (20004, 19019),
    (20005, 19013), (20005, 19016), (20005, 19017),
    (20006, 19010), (20006, 19011), (20006, 19012),
    (20007, 19014), (20007, 19015), (20007, 19024),
    (20008, 19004), (20008, 19022), (20008, 19023)
ON CONFLICT (vocabulary_set_id, word_id) DO NOTHING;

-- 12 tasks
INSERT INTO public.tasks (
    id,
    deadline,
    start_date,
    translate_to_russian,
    available_after_end,
    attempts_count,
    vocabulary_set_id,
    updated_at
)
VALUES
    (21001, '2026-03-20T20:00:00Z', '2026-03-20T11:00:00Z', false, true, 2, 20001, '2026-03-20T11:00:00Z'),
    (21002, '2026-03-20T20:10:00Z', '2026-03-20T11:10:00Z', true,  true, 2, 20002, '2026-03-20T11:10:00Z'),
    (21003, '2026-03-20T20:20:00Z', '2026-03-20T11:20:00Z', false, true, 3, 20003, '2026-03-20T11:20:00Z'),
    (21004, '2026-03-20T20:30:00Z', '2026-03-20T11:30:00Z', true,  true, 2, 20004, '2026-03-20T11:30:00Z'),
    (21005, '2026-03-20T20:40:00Z', '2026-03-20T11:40:00Z', false, true, 2, 20005, '2026-03-20T11:40:00Z'),
    (21006, '2026-03-20T20:50:00Z', '2026-03-20T11:50:00Z', true,  true, 2, 20006, '2026-03-20T11:50:00Z'),
    (21007, '2026-03-20T21:00:00Z', '2026-03-20T12:00:00Z', false, true, 3, 20007, '2026-03-20T12:00:00Z'),
    (21008, '2026-03-20T21:10:00Z', '2026-03-20T12:10:00Z', true,  true, 2, 20008, '2026-03-20T12:10:00Z'),
    (21009, '2026-03-20T21:20:00Z', '2026-03-20T12:20:00Z', false, false, 1, 20001, '2026-03-20T12:20:00Z'),
    (21010, '2026-03-20T21:30:00Z', '2026-03-20T12:30:00Z', true,  false, 1, 20002, '2026-03-20T12:30:00Z'),
    (21011, '2026-03-20T21:40:00Z', '2026-03-20T12:40:00Z', false, false, 1, 20003, '2026-03-20T12:40:00Z'),
    (21012, '2026-03-20T21:50:00Z', '2026-03-20T12:50:00Z', true,  false, 1, 20004, '2026-03-20T12:50:00Z')
ON CONFLICT (id) DO UPDATE
SET deadline = EXCLUDED.deadline,
    start_date = EXCLUDED.start_date,
    translate_to_russian = EXCLUDED.translate_to_russian,
    available_after_end = EXCLUDED.available_after_end,
    attempts_count = EXCLUDED.attempts_count,
    vocabulary_set_id = EXCLUDED.vocabulary_set_id,
    updated_at = EXCLUDED.updated_at;

-- 12 task executions (unique by user/task)
INSERT INTO public.task_executions (id, status_id, user_id, task_id, updated_at)
VALUES
    (22001, (SELECT completed_id   FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 4), 21001, '2026-03-20T13:00:00Z'),
    (22002, (SELECT in_progress_id FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 5), 21002, '2026-03-20T13:05:00Z'),
    (22003, (SELECT assigned_id    FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 6), 21003, '2026-03-20T13:10:00Z'),
    (22004, (SELECT completed_id   FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 7), 21004, '2026-03-20T13:15:00Z'),
    (22005, (SELECT overdue_id     FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 8), 21005, '2026-03-20T13:20:00Z'),
    (22006, (SELECT in_progress_id FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 4), 21006, '2026-03-20T13:25:00Z'),
    (22007, (SELECT assigned_id    FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 5), 21007, '2026-03-20T13:30:00Z'),
    (22008, (SELECT completed_id   FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 6), 21008, '2026-03-20T13:35:00Z'),
    (22009, (SELECT completed_id   FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 7), 21009, '2026-03-20T13:40:00Z'),
    (22010, (SELECT in_progress_id FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 8), 21010, '2026-03-20T13:45:00Z'),
    (22011, (SELECT assigned_id    FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 4), 21011, '2026-03-20T13:50:00Z'),
    (22012, (SELECT completed_id   FROM seed_statuses), (SELECT id FROM seed_users WHERE rn = 5), 21012, '2026-03-20T13:55:00Z')
ON CONFLICT (id) DO UPDATE
SET status_id = EXCLUDED.status_id,
    user_id = EXCLUDED.user_id,
    task_id = EXCLUDED.task_id,
    updated_at = EXCLUDED.updated_at;

-- 18 attempts
INSERT INTO public.attempts (id, started_at, ended_at, task_execution_id, updated_at)
VALUES
    (23001, '2026-03-20T14:00:00Z', '2026-03-20T14:05:00Z', 22001, '2026-03-20T14:05:00Z'),
    (23002, '2026-03-20T14:06:00Z', '2026-03-20T14:10:00Z', 22002, '2026-03-20T14:10:00Z'),
    (23003, '2026-03-20T14:11:00Z', '2026-03-20T14:14:00Z', 22002, '2026-03-20T14:14:00Z'),
    (23004, '2026-03-20T14:15:00Z', '2026-03-20T14:20:00Z', 22004, '2026-03-20T14:20:00Z'),
    (23005, '2026-03-20T14:21:00Z', '2026-03-20T14:25:00Z', 22005, '2026-03-20T14:25:00Z'),
    (23006, '2026-03-20T14:26:00Z', '2026-03-20T14:30:00Z', 22006, '2026-03-20T14:30:00Z'),
    (23007, '2026-03-20T14:31:00Z', '2026-03-20T14:35:00Z', 22006, '2026-03-20T14:35:00Z'),
    (23008, '2026-03-20T14:36:00Z', '2026-03-20T14:40:00Z', 22008, '2026-03-20T14:40:00Z'),
    (23009, '2026-03-20T14:41:00Z', '2026-03-20T14:45:00Z', 22009, '2026-03-20T14:45:00Z'),
    (23010, '2026-03-20T14:46:00Z', '2026-03-20T14:50:00Z', 22010, '2026-03-20T14:50:00Z'),
    (23011, '2026-03-20T14:51:00Z', '2026-03-20T14:55:00Z', 22012, '2026-03-20T14:55:00Z'),
    (23012, '2026-03-20T14:56:00Z', '2026-03-20T15:00:00Z', 22012, '2026-03-20T15:00:00Z'),
    (23013, '2026-03-20T15:01:00Z', '2026-03-20T15:05:00Z', 22001, '2026-03-20T15:05:00Z'),
    (23014, '2026-03-20T15:06:00Z', '2026-03-20T15:10:00Z', 22004, '2026-03-20T15:10:00Z'),
    (23015, '2026-03-20T15:11:00Z', '2026-03-20T15:15:00Z', 22008, '2026-03-20T15:15:00Z'),
    (23016, '2026-03-20T15:16:00Z', '2026-03-20T15:20:00Z', 22009, '2026-03-20T15:20:00Z'),
    (23017, '2026-03-20T15:21:00Z', '2026-03-20T15:25:00Z', 22010, '2026-03-20T15:25:00Z'),
    (23018, '2026-03-20T15:26:00Z', '2026-03-20T15:30:00Z', 22005, '2026-03-20T15:30:00Z')
ON CONFLICT (id) DO UPDATE
SET started_at = EXCLUDED.started_at,
    ended_at = EXCLUDED.ended_at,
    task_execution_id = EXCLUDED.task_execution_id,
    updated_at = EXCLUDED.updated_at;

-- 24 question answers (unique attempt_id + word_id)
INSERT INTO public.question_answers (id, entered_answer, is_correct, attempt_id, word_id, updated_at)
VALUES
    (24001, 'apple', true, 23001, 19001, '2026-03-20T16:00:00Z'),
    (24002, 'book', true, 23001, 19002, '2026-03-20T16:01:00Z'),
    (24003, 'water', false, 23002, 19003, '2026-03-20T16:02:00Z'),
    (24004, 'school', true, 23002, 19005, '2026-03-20T16:03:00Z'),
    (24005, 'teacher', true, 23003, 19008, '2026-03-20T16:04:00Z'),
    (24006, 'student', true, 23003, 19009, '2026-03-20T16:05:00Z'),
    (24007, 'city', true, 23004, 19007, '2026-03-20T16:06:00Z'),
    (24008, 'car', false, 23004, 19020, '2026-03-20T16:07:00Z'),
    (24009, 'house', true, 23005, 19006, '2026-03-20T16:08:00Z'),
    (24010, 'window', true, 23005, 19018, '2026-03-20T16:09:00Z'),
    (24011, 'door', true, 23006, 19019, '2026-03-20T16:10:00Z'),
    (24012, 'friend', false, 23006, 19013, '2026-03-20T16:11:00Z'),
    (24013, 'question', true, 23007, 19016, '2026-03-20T16:12:00Z'),
    (24014, 'answer', true, 23007, 19017, '2026-03-20T16:13:00Z'),
    (24015, 'day', true, 23008, 19011, '2026-03-20T16:14:00Z'),
    (24016, 'night', true, 23008, 19012, '2026-03-20T16:15:00Z'),
    (24017, 'family', true, 23009, 19014, '2026-03-20T16:16:00Z'),
    (24018, 'work', false, 23009, 19015, '2026-03-20T16:17:00Z'),
    (24019, 'language', true, 23010, 19024, '2026-03-20T16:18:00Z'),
    (24020, 'shop', true, 23010, 19022, '2026-03-20T16:19:00Z'),
    (24021, 'food', true, 23011, 19023, '2026-03-20T16:20:00Z'),
    (24022, 'sun', true, 23011, 19004, '2026-03-20T16:21:00Z'),
    (24023, 'time', true, 23012, 19010, '2026-03-20T16:22:00Z'),
    (24024, 'street', true, 23012, 19021, '2026-03-20T16:23:00Z')
ON CONFLICT (id) DO UPDATE
SET entered_answer = EXCLUDED.entered_answer,
    is_correct = EXCLUDED.is_correct,
    attempt_id = EXCLUDED.attempt_id,
    word_id = EXCLUDED.word_id,
    updated_at = EXCLUDED.updated_at;

-- 10 notifications
INSERT INTO public.notifications (id, sent_at, type, text, updated_at)
VALUES
    (26001, '2026-03-20T17:00:00Z', 'teacher_message', 'Проверьте новый словарь по теме школа.', '2026-03-20T17:00:00Z'),
    (26002, '2026-03-20T17:05:00Z', 'deadline', 'Срок задания 21003 до 20:20.', '2026-03-20T17:05:00Z'),
    (26003, '2026-03-20T17:10:00Z', 'achievement_awarded', 'Вы получили достижение: Первое задание.', '2026-03-20T17:10:00Z'),
    (26004, '2026-03-20T17:15:00Z', 'teacher_message', 'Добавлены примеры к словам из набора A2.', '2026-03-20T17:15:00Z'),
    (26005, '2026-03-20T17:20:00Z', 'deadline', 'Срок задания 21008 до 21:10.', '2026-03-20T17:20:00Z'),
    (26006, '2026-03-20T17:25:00Z', 'system', 'Ваш прогресс синхронизирован.', '2026-03-20T17:25:00Z'),
    (26007, '2026-03-20T17:30:00Z', 'teacher_message', 'Сегодня мини-тест в 19:00.', '2026-03-20T17:30:00Z'),
    (26008, '2026-03-20T17:35:00Z', 'achievement_awarded', 'Вы получили достижение: 10 правильных ответов.', '2026-03-20T17:35:00Z'),
    (26009, '2026-03-20T17:40:00Z', 'system', 'Новые задания доступны в разделе обучения.', '2026-03-20T17:40:00Z'),
    (26010, '2026-03-20T17:45:00Z', 'deadline', 'Не забудьте завершить задания до конца дня.', '2026-03-20T17:45:00Z')
ON CONFLICT (id) DO UPDATE
SET sent_at = EXCLUDED.sent_at,
    type = EXCLUDED.type,
    text = EXCLUDED.text,
    updated_at = EXCLUDED.updated_at;

-- 10 notification links
INSERT INTO public.notification_users_link (notification_id, user_id)
VALUES
    (26001, (SELECT id FROM seed_users WHERE rn = 4)),
    (26002, (SELECT id FROM seed_users WHERE rn = 5)),
    (26003, (SELECT id FROM seed_users WHERE rn = 4)),
    (26004, (SELECT id FROM seed_users WHERE rn = 6)),
    (26005, (SELECT id FROM seed_users WHERE rn = 7)),
    (26006, (SELECT id FROM seed_users WHERE rn = 8)),
    (26007, (SELECT id FROM seed_users WHERE rn = 5)),
    (26008, (SELECT id FROM seed_users WHERE rn = 6)),
    (26009, (SELECT id FROM seed_users WHERE rn = 7)),
    (26010, (SELECT id FROM seed_users WHERE rn = 8))
ON CONFLICT (notification_id, user_id) DO NOTHING;

-- 8 achievements (seed-specific)
INSERT INTO public.achievements (id, name, description, condition_text, updated_at)
VALUES
    (27001, 'Первые 5 слов', 'Изучите 5 слов без ошибок.', 'seed_words_5', '2026-03-20T18:00:00Z'),
    (27002, 'Первые 20 слов', 'Изучите 20 слов.', 'seed_words_20', '2026-03-20T18:05:00Z'),
    (27003, 'Три задания', 'Завершите 3 задания.', 'seed_tasks_3', '2026-03-20T18:10:00Z'),
    (27004, 'Шесть заданий', 'Завершите 6 заданий.', 'seed_tasks_6', '2026-03-20T18:15:00Z'),
    (27005, 'Серия 2 дня', 'Учитесь 2 дня подряд.', 'seed_streak_2', '2026-03-20T18:20:00Z'),
    (27006, 'Серия 5 дней', 'Учитесь 5 дней подряд.', 'seed_streak_5', '2026-03-20T18:25:00Z'),
    (27007, 'Точность 80%', 'Держите точность 80% на 3 сессиях.', 'seed_accuracy_80_3', '2026-03-20T18:30:00Z'),
    (27008, 'Точность 90%', 'Держите точность 90% на 5 сессиях.', 'seed_accuracy_90_5', '2026-03-20T18:35:00Z')
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    condition_text = EXCLUDED.condition_text,
    updated_at = EXCLUDED.updated_at;

-- 12 user-achievement links
INSERT INTO public.user_achievements_link (user_id, achievement_id, received_at)
VALUES
    ((SELECT id FROM seed_users WHERE rn = 4), 27001, '2026-03-20T18:40:00Z'),
    ((SELECT id FROM seed_users WHERE rn = 4), 27003, '2026-03-20T18:41:00Z'),
    ((SELECT id FROM seed_users WHERE rn = 5), 27001, '2026-03-20T18:42:00Z'),
    ((SELECT id FROM seed_users WHERE rn = 5), 27005, '2026-03-20T18:43:00Z'),
    ((SELECT id FROM seed_users WHERE rn = 6), 27002, '2026-03-20T18:44:00Z'),
    ((SELECT id FROM seed_users WHERE rn = 6), 27007, '2026-03-20T18:45:00Z'),
    ((SELECT id FROM seed_users WHERE rn = 7), 27003, '2026-03-20T18:46:00Z'),
    ((SELECT id FROM seed_users WHERE rn = 7), 27006, '2026-03-20T18:47:00Z'),
    ((SELECT id FROM seed_users WHERE rn = 8), 27001, '2026-03-20T18:48:00Z'),
    ((SELECT id FROM seed_users WHERE rn = 8), 27004, '2026-03-20T18:49:00Z'),
    ((SELECT id FROM seed_users WHERE rn = 8), 27008, '2026-03-20T18:50:00Z'),
    ((SELECT id FROM seed_users WHERE rn = 5), 27004, '2026-03-20T18:51:00Z')
ON CONFLICT (user_id, achievement_id) DO UPDATE
SET received_at = EXCLUDED.received_at;

DROP TABLE IF EXISTS seed_users;
DROP TABLE IF EXISTS seed_roles;
DROP TABLE IF EXISTS seed_statuses;

COMMIT;
