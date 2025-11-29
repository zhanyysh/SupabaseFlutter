// lib/screens/companies_screen.dart — полностью рабочий код
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});
  @override State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  String? _selectedManagerId;
  bool _loading = false;
  bool _fetchingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('id, email')
        .order('email');

    setState(() {
      _users = List<Map<String, dynamic>>.from(response);
      _fetchingUsers = false;
    });
  }

  Future<void> _createCompany() async {
    if (!_formKey.currentState!.validate() || _selectedManagerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите менеджера компании')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // 1. Создаём компанию
      final companyRes = await Supabase.instance.client
          .from('companies')
          .insert({
            'name': _nameController.text.trim(),
            'description': _descController.text.trim(),
            'created_by': Supabase.instance.client.auth.currentUser!.id,
          })
          .select()
          .single();

      final companyId = companyRes['id'];

      // 2. Назначаем менеджера
      await Supabase.instance.client.from('company_managers').insert({
        'user_id': _selectedManagerId,
        'company_id': companyId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Компания создана и менеджер назначен!')),
      );

      // Очистка формы
      _nameController.clear();
      _descController.clear();
      setState(() => _selectedManagerId = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companies'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название компании *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Обязательно' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              const Text('Выберите менеджера компании:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              _fetchingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedManagerId,
                      hint: const Text('— Выберите пользователя —'),
                      isExpanded: true,
                      items: _users.map<DropdownMenuItem<String>>((user) {
                        return DropdownMenuItem<String>(
                          value: user['id'] as String,
                          child: Text(user['email'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedManagerId = val),
                      validator: (v) => v == null ? 'Выберите менеджера' : null,
                    ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createCompany,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Создать компанию', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}