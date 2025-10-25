// lib/screens/baby_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/models/baby.dart';

class BabyProfileScreen extends StatefulWidget {
  final Baby? baby; // null = создание нового, иначе редактирование

  const BabyProfileScreen({super.key, this.baby});

  @override
  State<BabyProfileScreen> createState() => _BabyProfileScreenState();
}

class _BabyProfileScreenState extends State<BabyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  DateTime _birthDate = DateTime.now();
  String _gender = 'female';

  @override
  void initState() {
    super.initState();
    if (widget.baby != null) {
      _nameController.text = widget.baby!.name;
      _birthDate = widget.baby!.birthDate;
      _gender = widget.baby!.gender;
      if (widget.baby!.weightAtBirthKg != null) {
        _weightController.text =
            widget.baby!.weightAtBirthKg!.toStringAsFixed(2);
      }
      if (widget.baby!.heightAtBirthCm != null) {
        _heightController.text =
            widget.baby!.heightAtBirthCm!.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF1F1F1F),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.baby != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Редактировать профиль' : 'Добавить ребенка',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Фото
              _buildPhotoSection(),

              const SizedBox(height: 32),

              // Имя
              _buildTextField(
                controller: _nameController,
                label: 'Имя ребенка',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Дата рождения
              _buildDateField(),

              const SizedBox(height: 24),

              // Пол
              _buildGenderSelector(),

              const SizedBox(height: 24),

              // Вес при рождении
              _buildTextField(
                controller: _weightController,
                label: 'Вес при рождении (кг)',
                icon: Icons.monitor_weight,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0 || weight > 10) {
                      return 'Введите корректный вес (0-10 кг)';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Рост при рождении
              _buildTextField(
                controller: _heightController,
                label: 'Рост при рождении (см)',
                icon: Icons.height,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final height = double.tryParse(value);
                    if (height == null || height <= 0 || height > 100) {
                      return 'Введите корректный рост (0-100 см)';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Кнопка сохранения
              _buildSaveButton(isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    final babyProvider = Provider.of<BabyProvider>(context);
    final isUploading = babyProvider.isUploading;
    final baby = babyProvider.currentBaby;
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).primaryColorLight,
            backgroundImage: (baby?.photoUrl != null &&
                   baby!.photoUrl!.isNotEmpty)
                ? NetworkImage(baby.photoUrl!)
                : null,
            child: (baby?.photoUrl == null ||
                    baby?.photoUrl?.isEmpty == true)
                ? const Icon(Icons.child_care, size: 60, color: Colors.white)
                : null,
          ),
          if (isUploading)
            const Positioned.fill(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: IconButton(
                icon:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: () {
                  _showImageSourceActionSheet(context, babyProvider, currentUser!.uid);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
void _showImageSourceActionSheet(
      BuildContext context, BabyProvider babyProvider, String userId) {

    showModalBottomSheet(
      context: context,
      // Делаем фон модального окна в стиле твоего приложения
      backgroundColor: Theme.of(context).cardColor,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library,
                    color: Theme.of(context).iconTheme.color),
                title: Text('Галерея',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () {
                  // Вызываем метод провайдера с ImageSource.gallery
                  babyProvider.pickAndUploadBabyImage(
                      userId, ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt,
                    color: Theme.of(context).iconTheme.color),
                title: Text('Камера',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () {
                  // Вызываем метод провайдера с ImageSource.camera
                  babyProvider.pickAndUploadBabyImage(userId, ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дата рождения',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectBirthDate(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF6366F1),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Пол',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildGenderButton('Девочка', 'female', Icons.girl),
              ),
              Expanded(
                child: _buildGenderButton('Мальчик', 'male', Icons.boy),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderButton(String label, String value, IconData icon) {
    final isSelected = _gender == value;

    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white60,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return Consumer2<AuthProvider, BabyProvider>(
      builder: (context, authProvider, babyProvider, child) {
        return ElevatedButton(
          onPressed: babyProvider.isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  final weight = _weightController.text.isEmpty
                      ? null
                      : double.tryParse(_weightController.text);

                  final height = _heightController.text.isEmpty
                      ? null
                      : double.tryParse(_heightController.text);

                  if (isEditing) {
                    // Обновление существующего профиля
                    final success = await babyProvider.updateBaby(
                      babyId: widget.baby!.id,
                      name: _nameController.text.trim(),
                      birthDate: _birthDate,
                      gender: _gender,
                      weightAtBirthKg: weight,
                      heightAtBirthCm: height,
                    );

                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Профиль обновлен'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } else {
                    // Создание нового профиля
                    final babyId = await babyProvider.addBaby(
                      familyId: authProvider.familyId!,
                      name: _nameController.text.trim(),
                      birthDate: _birthDate,
                      gender: _gender,
                      createdBy: authProvider.currentUser!.uid,
                      weightAtBirthKg: weight,
                      heightAtBirthCm: height,
                    );

                    if (babyId != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ребенок добавлен'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  }

                  if (babyProvider.error != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(babyProvider.error!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: babyProvider.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEditing ? 'Сохранить изменения' : 'Добавить ребенка',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        );
      },
    );
  }
}
