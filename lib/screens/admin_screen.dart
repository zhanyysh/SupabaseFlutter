// lib/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> users = [];
  bool loading = true;

  final List<String> roles = ['user', 'moderator', 'admin'];

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    if (profile['role'] != 'admin') {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin access required')),
        );
      }
    } else {
      loadUsers();
    }
  }

  Future<void> loadUsers() async {
    setState(() => loading = true);
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, email, full_name, role')
          .order('created_at', ascending: false);

      setState(() {
        users = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);

      // Refresh list
      loadUsers();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated to $newRole')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update role')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadUsers),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text('No users yet'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final user = users[i];
                    final String currentRole = user['role'] ?? 'user';
                    final String email = user['email'] ?? 'no-email@example.com';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            email[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Name: ${user['full_name'] ?? 'Not set'}'),
                        trailing: DropdownButton<String>(
                          value: currentRole,
                          underline: const SizedBox(),
                          items: roles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle( 
                                  color: role == 'admin'
                                      ? Colors.green
                                      : role == 'moderator'
                                          ? Colors.orange
                                          : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                )
                              ),
                            );
                          }).toList(),
                          onChanged: (newRole) {
                            if (newRole != null && newRole != currentRole) {
                              print(user);
                              updateUserRole(user['id'], newRole);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}