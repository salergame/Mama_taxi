import 'package:flutter/material.dart';
import 'package:mama_taxi/models/child_model.dart';
import 'package:mama_taxi/services/firebase_service.dart';
import 'package:mama_taxi/widgets/add_child_modal.dart';

class ChildDetailsScreen extends StatefulWidget {
  final String childId;

  const ChildDetailsScreen({
    Key? key,
    required this.childId,
  }) : super(key: key);

  @override
  _ChildDetailsScreenState createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  ChildModel? _child;

  @override
  void initState() {
    super.initState();
    _loadChildData();
  }

  Future<void> _loadChildData() async {
    setState(() {
      _isLoading = true;
    });

    final child = await _firebaseService.getChildById(widget.childId);

    setState(() {
      _child = child;
      _isLoading = false;
    });
  }

  Future<void> _deleteChild() async {
    if (_child == null) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Удаление ребенка'),
            content:
                const Text('Вы уверены, что хотите удалить данные ребенка?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Удалить',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      final success = await _firebaseService.deleteChild(_child!.id!);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ребенок удален'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось удалить данные ребенка'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editChild() {
    if (_child == null) return;

    showDialog(
      context: context,
      builder: (context) => AddChildModal(
        initialData: {
          'id': _child!.id,
          'name': _child!.name,
          'age': _child!.age,
          'notes': _child!.notes,
        },
        onAdd: (childData) {
          _loadChildData(); // Перезагружаем данные после редактирования
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Данные ребенка',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          if (_child != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editChild,
            ),
          if (_child != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteChild,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _child == null
              ? const Center(child: Text('Данные не найдены'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Основная информация
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Основная информация',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow('ФИО', _child!.name),
                                _buildInfoRow('Возраст', _child!.age),
                                if (_child!.notes.isNotEmpty)
                                  _buildInfoRow('Примечания', _child!.notes),
                                if (_child!.createdAt != null)
                                  _buildInfoRow(
                                    'Добавлен',
                                    _formatDate(_child!.createdAt!),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Примечания
                        if (_child!.notes.isNotEmpty)
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Примечания',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _child!.notes,
                                    style: const TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Кнопка редактирования
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _editChild,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: const Color(0xFF2563EB),
                            ),
                            child: const Text(
                              'Редактировать данные',
                              style: TextStyle(
                                fontFamily: 'Rubik',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Кнопка удаления
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _deleteChild,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Удалить данные ребенка',
                              style: TextStyle(
                                fontFamily: 'Rubik',
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Rubik',
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Rubik',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
