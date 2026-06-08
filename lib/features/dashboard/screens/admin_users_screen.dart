import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_service.dart';
import '../../../models/user_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/utils/validators.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _showAddUserDialog() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String role = 'pharmacist';

    showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add User'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username *'), validator: (v) => Validators.required(v, 'Username')),
                    TextFormField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password *'), obscureText: true, validator: (v) => Validators.required(v, 'Password')),
                    TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *'), validator: (v) => Validators.required(v, 'Full name')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'pharmacist', child: Text('Pharmacist')),
                      ],
                      onChanged: (v) => setDialogState(() => role = v ?? 'pharmacist'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final auth = context.read<AuthService>();
                  await auth.createUser(UserModel(
                    username: usernameCtrl.text,
                    passwordHash: passwordCtrl.text,
                    fullName: nameCtrl.text,
                    role: role,
                  ));
                  if (context.mounted) {
                    AppSnackbar.showSuccess(context, 'User created successfully');
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: context.read<AuthService>().getAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.role == 'admin'
                        ? Colors.amber.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      user.role == 'admin' ? Icons.shield : Icons.person,
                      color: user.role == 'admin' ? Colors.amber : AppColors.primary,
                    ),
                  ),
                  title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('@${user.username} | ${user.role}'),
                  trailing: Text(user.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: user.role == 'admin' ? Colors.amber : AppColors.textSecondary,
                      )),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
