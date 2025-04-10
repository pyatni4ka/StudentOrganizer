import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/project.dart';
import '../../../providers/project_providers.dart';
// import '../../../shared_widgets/color_picker_dialog.dart'; // Убираем импорт

class AddEditProjectDialog extends ConsumerStatefulWidget {
  final Project? projectToEdit;

  const AddEditProjectDialog({super.key, this.projectToEdit});

  @override
  ConsumerState<AddEditProjectDialog> createState() => _AddEditProjectDialogState();
}

class _AddEditProjectDialogState extends ConsumerState<AddEditProjectDialog> {
  late TextEditingController _nameController;
  String? _selectedColorHex;

  bool get _isEditing => widget.projectToEdit != null;

  final List<String> _presetColors = [
     '#FFD700', '#FA8072', '#90EE90', '#ADD8E6', '#FFB6C1',
     '#FFA07A', '#20B2AA', '#87CEFA', '#778899', '#B0C4DE',
     '#FFFFE0', '#DDA0DD', '#E6E6FA', '#FFDEAD', '#F08080',
   ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.projectToEdit?.name ?? '');
    _selectedColorHex = widget.projectToEdit?.colorHex ?? _presetColors[3]; // Цвет по умолчанию - LightBlue
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Копируем функцию парсинга цвета сюда
  Color _parseColor(String? hex) {
     if (hex == null || hex.isEmpty) return Colors.grey;
     final buffer = StringBuffer();
     if (hex.length == 6 || hex.length == 7) buffer.write('ff');
     buffer.write(hex.replaceFirst('#', ''));
     try {
       if (buffer.length == 8) {
         return Color(int.parse(buffer.toString(), radix: 16));
       } else {
         return Colors.grey;
       }
     } catch (e) {
       return Colors.grey;
     }
   }

  void _submit() {
     final name = _nameController.text.trim();
     if (name.isNotEmpty) {
       final notifier = ref.read(projectListProvider.notifier);
       try {
          if (_isEditing) {
             final updatedProject = widget.projectToEdit!.copyWith(
               name: name,
               colorHex: _selectedColorHex, 
             );
             notifier.updateProject(updatedProject);
           } else {
             notifier.addProject(name, _selectedColorHex);
           }
           Navigator.of(context).pop(); // Закрываем диалог при успехе
       } catch (e) {
          // Показываем ошибку, если что-то пошло не так
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Ошибка сохранения проекта: $e'), backgroundColor: Colors.red),
          );
       }
     } else {
        // Показываем сообщение, если имя пустое
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Введите название проекта'), backgroundColor: Colors.orange),
        );
     }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Редактировать проект' : 'Новый проект'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название проекта *'),
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 20),
            const Text('Цвет проекта:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _presetColors.map((hex) {
                final color = _parseColor(hex);
                final bool isSelected = _selectedColorHex == hex;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColorHex = hex;
                    });
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), blurRadius: 3)]
                          : null,
                    ),
                     // Можно добавить галочку для выбранного цвета
                     child: isSelected 
                        ? Icon(Icons.check, size: 18, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white) 
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _submit, // Вызываем метод сохранения
          child: Text(_isEditing ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
} 