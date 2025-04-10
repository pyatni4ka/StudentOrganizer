import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart'; // Для форматирования даты

import '../../../models/project.dart';
import '../../../services/project_repository.dart';
import '../../../providers/project_providers.dart'; // Для invalidate

class AddProjectSheet extends ConsumerStatefulWidget {
  final Project? project; // Для редактирования существующего проекта

  const AddProjectSheet({super.key, this.project});

  @override
  _AddProjectSheetState createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends ConsumerState<AddProjectSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _deadlineController; // Контроллер для поля дедлайна
  String? _selectedStatus; // Для хранения выбранного статуса
  DateTime? _selectedDeadline; // Для хранения выбранной даты

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(text: widget.project?.description ?? '');
    _selectedStatus = widget.project?.status ?? 'active'; // Инициализация статуса
    _selectedDeadline = widget.project?.deadline; // Инициализация дедлайна
    _deadlineController = TextEditingController(
      text: _selectedDeadline != null 
          ? DateFormat.yMd().format(_selectedDeadline!) // Форматируем дату для отображения
          : ''
    ); 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = DateFormat.yMd().format(_selectedDeadline!); // Обновляем текст в поле
      });
    }
  }

  Future<void> _saveProject() async {
    if (_formKey.currentState!.validate()) {
      final projectRepo = ref.read(projectRepositoryProvider);
      final isEditing = widget.project != null;

      final projectData = Project(
        id: isEditing ? widget.project!.id : const Uuid().v4(),
        userId: 'dummy_user_id', // Заменить на реальный ID пользователя
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        status: _selectedStatus ?? 'active', // Используем выбранный статус
        deadline: _selectedDeadline, // Используем выбранный дедлайн
        createdAt: isEditing ? widget.project!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (isEditing) {
          await projectRepo.updateProject(projectData);
        } else {
          await projectRepo.addProject(projectData);
        }
        ref.invalidate(allProjectsProvider); // Обновляем список проектов
        Navigator.of(context).pop(); // Закрываем sheet
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения проекта: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, 
        left: 16, 
        right: 16, 
        top: 16
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.project == null ? 'Добавить проект' : 'Редактировать проект',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название проекта',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Пожалуйста, введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание (опционально)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Поле выбора статуса
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Статус',
                border: OutlineInputBorder(),
              ),
              items: <String>['active', 'archived', 'on_hold']
                  .map<DropdownMenuItem<String>>((String value) {
                // Используем более понятные названия для UI
                String displayValue = value;
                if (value == 'active') displayValue = 'Активный';
                if (value == 'archived') displayValue = 'В архиве';
                if (value == 'on_hold') displayValue = 'Приостановлен';
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(displayValue),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStatus = newValue;
                });
              },
              validator: (value) => value == null ? 'Выберите статус' : null,
            ),
            const SizedBox(height: 16),
            // Поле выбора дедлайна
             TextFormField(
              controller: _deadlineController,
              readOnly: true, // Делаем поле только для чтения
              decoration: InputDecoration(
                labelText: 'Дедлайн (опционально)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDeadline(context), // Вызываем выбор даты
                ),
              ),
              onTap: () => _selectDeadline(context), // Также вызываем по нажатию на поле
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProject,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48), // Растягиваем кнопку
              ),
              child: Text(widget.project == null ? 'Добавить' : 'Сохранить'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 