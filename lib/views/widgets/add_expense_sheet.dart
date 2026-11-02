import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/expense_viewmodel.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _selectedCategory = 'Cafetería / Snacks';
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Cafetería / Snacks', 'icon': Icons.local_cafe},
    {'name': 'Transporte', 'icon': Icons.directions_bus},
    {'name': 'Fotocopias / Útiles', 'icon': Icons.print},
    {'name': 'Comida rápida', 'icon': Icons.fastfood},
    {'name': 'Ocio / Salidas', 'icon': Icons.sports_esports},
  ];

  final List<double> _quickAmounts = [2000, 5000, 10000];

  void _setQuickAmount(double amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _imagePath = photo.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo acceder a la cámara: $e')),
        );
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount <= 0) return;

      // Respuesta háptica de confirmación
      HapticFeedback.mediumImpact();

      final vm = Provider.of<ExpenseViewModel>(context, listen: false);
      vm.addExpense(
        amount: amount,
        category: _selectedCategory,
        note: _noteController.text.trim(),
        photoPath: _imagePath,
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gasto de \$$amount registrado con éxito'),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Registrar Gasto Hormiga',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Botones de montos rápidos universitarios (1 toque)
              const Text(
                'Montos rápidos frecuentes:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _quickAmounts.map((amt) {
                  return ActionChip(
                    avatar: const Icon(Icons.bolt, size: 16, color: Colors.amber),
                    label: Text('\$${amt.toInt()}'),
                    onPressed: () => _setQuickAmount(amt),
                    backgroundColor: Colors.teal.shade50,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Campo de texto de monto
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto del gasto (\$ COP)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa un valor';
                  }
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un monto válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Selector de categorías
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['name'] as String,
                    child: Row(
                      children: [
                        Icon(c['icon'] as IconData, size: 20, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(c['name'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),

              // Campo opcional de nota
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Nota (opcional)',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Botón y previsualización de foto (Cámara / Filesystem)
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_imagePath == null ? 'Foto recibo' : 'Cambiar foto'),
                  ),
                  const SizedBox(width: 12),
                  if (_imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_imagePath!),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Botón Guardar
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Registrar Gasto'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

