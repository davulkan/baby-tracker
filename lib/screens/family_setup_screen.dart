// lib/screens/family_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/screens/home/home_screen.dart';

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _familyNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isCreating = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    if (_familyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите название семьи'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final inviteCode = await authProvider.createFamily(
      _familyNameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (inviteCode != null && mounted) {
      // Показываем код приглашения
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Семья создана!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Код для приглашения партнера:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      inviteCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: inviteCode),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Код скопирован'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Отправьте этот код партнеру, чтобы он мог присоединиться',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const HomeScreenFull(),
                  ),
                );
              },
              child: const Text('Продолжить'),
            ),
          ],
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка создания семьи'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinFamily() async {
    if (_inviteCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите код приглашения'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.joinFamily(
      _inviteCodeController.text.trim().toUpperCase(),
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreenFull(),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error ?? 'Ошибка присоединения к семье',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка семьи'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.family_restroom,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),

              Text(
                'Создайте семью или присоединитесь',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Вы сможете отслеживать развитие ребенка вместе с партнером',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Переключатель
              SegmentedButton<bool>(
                selected: {_isCreating},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isCreating = newSelection.first;
                  });
                },
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Создать семью'),
                    icon: Icon(Icons.add),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Присоединиться'),
                    icon: Icon(Icons.login),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Форма создания семьи
              if (_isCreating) ...[
                TextField(
                  controller: _familyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Название семьи',
                    hintText: 'Семья Ивановых',
                    prefixIcon: Icon(Icons.home),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createFamily,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Создать семью'),
                ),
              ],

              // Форма присоединения к семье
              if (!_isCreating) ...[
                TextField(
                  controller: _inviteCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Код приглашения',
                    hintText: 'JOIN-ABCDEF',
                    prefixIcon: Icon(Icons.vpn_key),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _joinFamily,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Присоединиться'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
