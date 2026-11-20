import 'package:flutter/material.dart';
import 'package:sonora_catalog/feature/catalog/controllers/catalog_controller.dart';
import 'package:sonora_catalog/feature/catalog/data/models/instrument_view_model.dart';
import 'package:uuid/uuid.dart';

/// Formulario de alta y edición de instrumentos musicales.
///
/// En modo **edición** recibe [existing]; en modo **alta**, `existing` es null.
/// Toda escritura fluye por [CatalogController.saveInstrument] manteniendo
/// la separación de responsabilidades.
class InstrumentFormPage extends StatefulWidget {
  final CatalogController controller;

  /// Instrumento a editar; `null` para crear uno nuevo.
  final InstrumentViewModel? existing;

  const InstrumentFormPage({
    super.key,
    required this.controller,
    this.existing,
  });

  @override
  State<InstrumentFormPage> createState() => _InstrumentFormPageState();
}

class _InstrumentFormPageState extends State<InstrumentFormPage> {
  // ---------------------------------------------------------------------------
  // Formulario y controladores de texto
  // ---------------------------------------------------------------------------

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController();

  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  // Ciclo de vida
  // vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final InstrumentViewModel vm = widget.existing!;
      _nameCtrl.text = vm.name;
      _brandCtrl.text = vm.brand;
      _priceCtrl.text = vm.price.toStringAsFixed(2);
      _stockCtrl.text = vm.stock.toString();
      _categoryCtrl.text = vm.categoryId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar instrumento' : 'Nuevo instrumento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // ----------------------------------------------------------------
              // Campos del formulario
              // ----------------------------------------------------------------
              _buildTextField(
                controller: _nameCtrl,
                label: 'Nombre del instrumento',
                hint: 'Guitarra Clásica 4/4',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _brandCtrl,
                label: 'Marca',
                hint: 'Yamaha',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _categoryCtrl,
                label: 'ID de categoría',
                hint: 'cuerdas',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _priceCtrl,
                label: 'Precio (\$)',
                hint: '1299.99',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _stockCtrl,
                label: 'Stock',
                hint: '10',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (int.tryParse(v.trim()) == null) {
                    return 'Ingresa un entero válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // ----------------------------------------------------------------
              // Botón de guardar
              // ----------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isEditing ? 'Actualizar' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lógica de envío
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Construir el ViewModel con los datos del formulario
    final InstrumentViewModel vm = InstrumentViewModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      categoryId: _categoryCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      stock: int.parse(_stockCtrl.text.trim()),
      version: (widget.existing?.version ?? 0) + 1,
      updatedAt: DateTime.now().toUtc(),
      isSynced: false,
      isDeleted: false,
    );

    try {
      await widget.controller.saveInstrument(vm);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: campo de texto reutilizable
  // ---------------------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}

