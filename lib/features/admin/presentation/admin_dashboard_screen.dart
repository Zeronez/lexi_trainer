import 'package:flutter/material.dart';
import 'package:lexi_trainer/core/theme/app_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Панель администратора'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Контент'),
              Tab(text: 'Группы'),
              Tab(text: 'Задания'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ContentManagementTab(),
            _GroupManagementTab(),
            _TaskManagementTab(),
          ],
        ),
      ),
    );
  }
}

class _ContentManagementTab extends StatelessWidget {
  const _ContentManagementTab();

  @override
  Widget build(BuildContext context) {
    return _TabLayout(
      title: 'Управление словарями',
      description:
          'Создание наборов слов, редактирование переводов и примеров.',
      actionText: 'Добавить словарный набор',
      items: const [
        _AdminItem(
          title: 'Тема: Travel Basics',
          subtitle: 'CEFR A2 · 48 слов',
          status: 'Черновик',
        ),
        _AdminItem(
          title: 'Тема: Academic Vocabulary',
          subtitle: 'CEFR B2 · 72 слова',
          status: 'Опубликовано',
        ),
      ],
    );
  }
}

class _GroupManagementTab extends StatelessWidget {
  const _GroupManagementTab();

  @override
  Widget build(BuildContext context) {
    return _TabLayout(
      title: 'Управление учебными группами',
      description:
          'Назначение студентов, кураторов и контроль активности группы.',
      actionText: 'Создать группу',
      items: const [
        _AdminItem(
          title: 'Группа ENG-101',
          subtitle: '24 студента · преподаватель: Иванова',
          status: 'Активна',
        ),
        _AdminItem(
          title: 'Группа ENG-202',
          subtitle: '18 студентов · преподаватель: Петров',
          status: 'Активна',
        ),
      ],
    );
  }
}

class _TaskManagementTab extends StatelessWidget {
  const _TaskManagementTab();

  @override
  Widget build(BuildContext context) {
    return _TabLayout(
      title: 'Управление заданиями',
      description: 'Планирование дедлайнов, попыток и направления перевода.',
      actionText: 'Создать задание',
      items: const [
        _AdminItem(
          title: 'Quiz: Daily Verbs',
          subtitle: 'Дедлайн: 18.04.2026 · Попыток: 3',
          status: 'Назначено',
        ),
        _AdminItem(
          title: 'Quiz: Phrasal Verbs',
          subtitle: 'Дедлайн: 22.04.2026 · Попыток: 2',
          status: 'В работе',
        ),
      ],
    );
  }
}

class _TabLayout extends StatelessWidget {
  const _TabLayout({
    required this.title,
    required this.description,
    required this.actionText,
    required this.items,
  });

  final String title;
  final String description;
  final String actionText;
  final List<_AdminItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(description),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () {}, child: Text(actionText)),
        const SizedBox(height: 16),
        ...items.map((item) => _AdminItemCard(item: item)),
      ],
    );
  }
}

class _AdminItemCard extends StatelessWidget {
  const _AdminItemCard({required this.item});

  final _AdminItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(item.subtitle),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.status,
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminItem {
  const _AdminItem({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String status;
}
