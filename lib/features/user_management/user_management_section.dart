import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/temp_password_generator.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/auth_service.dart';
import '../../shared/providers/auth_provider.dart';

/// Раздел управления пользователями (только для ADMIN)
class UserManagementSection extends StatefulWidget {
  const UserManagementSection({super.key});

  @override
  State<UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends State<UserManagementSection> {
  final UserRepository _userRepo = UserRepository();
  final AuthService _authService = AuthService();
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      _users = await _userRepo.getAll();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = ((constraints.maxWidth - kUsersMaxWidth) / 2)
            .clamp(kPaddingLarge, double.infinity);
        return Padding(
          padding: EdgeInsets.fromLTRB(hPad, kPaddingLarge, hPad, kPaddingLarge),
          child: Expanded(
                    child:Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).tr('users_title'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ).animate().fadeIn(),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: Text(AppLocalizations.of(context).tr('users_create')),
                    onPressed: () => _showCreateDialog(),
                  ).animate(delay: 100.ms).fadeIn(),
                ],
              ),

              const SizedBox(height: 20),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                Row(children: [ Expanded(
                  child: _UserTable(
                    users: _users,
                    currentUserId: context.read<AuthProvider>().currentUser!.id!,
                    onToggleActive: _toggleActive,
                    onResetPassword: _resetPassword,
                  ),
                ),]),
            ],
          ),),
        );
      },
    );
  }

  Future<void> _toggleActive(User user, bool active) async {
    final auth = context.read<AuthProvider>();
    try {
      await _userRepo.setActive(
        targetUserId: user.id!,
        isActive: active,
        requesterUserId: auth.currentUser!.id!,
        requesterRole: auth.currentUser!.role,
      );
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _resetPassword(User user) async {
    final auth = context.read<AuthProvider>();
    try {
      final newPass = await _authService.resetUserPassword(
        targetUserId: user.id!,
        requesterRole: auth.currentUser!.role,
      );
      if (mounted) {
        _showPasswordDialog(user.fullName, newPass);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showPasswordDialog(String userName, String password) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tr('users_password_reset_success')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.tr('users_reset_password_for', args: {'name': userName})),
            const SizedBox(height: 12),
            _SelectablePasswordBox(password: password),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tr('btn_close')),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateUserDialog(
        onCreated: (user, pass) {
          _loadUsers();
          _showPasswordDialog(user.fullName, pass);
        },
      ),
    );
  }
}

/// Таблица пользователей
class _UserTable extends StatelessWidget {
  final List<User> users;
  final int currentUserId;
  final Future<void> Function(User, bool) onToggleActive;
  final Future<void> Function(User) onResetPassword;

  const _UserTable({
    required this.users,
    required this.currentUserId,
    required this.onToggleActive,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).tr('users_no_users'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text(AppLocalizations.of(context).tr('users_name'))),
              DataColumn(label: Text(AppLocalizations.of(context).tr('users_username'))),
              DataColumn(label: Text(AppLocalizations.of(context).tr('users_role'))),
              DataColumn(label: Text(AppLocalizations.of(context).tr('users_status'))),
              DataColumn(label: Text(AppLocalizations.of(context).tr('users_created_at'))),
              DataColumn(label: Text(AppLocalizations.of(context).tr('users_actions'))),
            ],
            rows: users
                .map((u) => _buildRow(context, u))
                .toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, User user) {
    final isCurrent = user.id == currentUserId;
    final dateStr = '${user.createdAt.day.toString().padLeft(2, '0')}'
        '.${user.createdAt.month.toString().padLeft(2, '0')}'
        '.${user.createdAt.year}';

    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(name: user.fullName, role: user.role),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (isCurrent)
                      Text(AppLocalizations.of(context).tr('users_you'),
                          style: const TextStyle(fontSize: 11, color: AppColors.info)),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(user.username, style: const TextStyle(fontFamily: 'monospace'))),
        DataCell(_RoleBadge(role: user.role)),
        DataCell(_StatusBadge(active: user.isActive)),
        DataCell(Text(dateStr, style: const TextStyle(fontSize: 13))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Активировать/деактивировать
              IconButton(
                tooltip: user.isActive
                    ? AppLocalizations.of(context).tr('users_deactivate')
                    : AppLocalizations.of(context).tr('users_activate'),
                icon: Icon(
                  user.isActive
                      ? Icons.person_off_rounded
                      : Icons.person_rounded,
                  size: 18,
                  color: user.isActive ? AppColors.error : AppColors.success,
                ),
                onPressed: isCurrent
                    ? null
                    : () => onToggleActive(user, !user.isActive),
              ),
              // Сброс пароля
              IconButton(
                tooltip: AppLocalizations.of(context).tr('users_reset_password'),
                icon: const Icon(Icons.lock_reset_rounded,
                    size: 18, color: AppColors.warning),
                onPressed: () => onResetPassword(user),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final UserRole role;
  const _Avatar({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: AppColors.logoGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == UserRole.admin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isAdmin ? 'ADMIN' : 'USER',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isAdmin ? AppColors.accentDark : AppColors.primary,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.success : AppColors.error,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          active
              ? AppLocalizations.of(context).tr('users_status_active')
              : AppLocalizations.of(context).tr('users_status_inactive'),
          style: TextStyle(
            fontSize: 13,
            color: active ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    );
  }
}

/// Диалог создания пользователя
class _CreateUserDialog extends StatefulWidget {
  final void Function(User user, String password) onCreated;
  const _CreateUserDialog({required this.onCreated});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  UserRole _role = UserRole.user;
  bool _loading = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _generatePassword() {
    setState(() {
      _passwordCtrl.text = TempPasswordGenerator.generate();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final authService = AuthService();

    try {
      final result = await authService.createUser(
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        username: _usernameCtrl.text,
        role: _role,
        requesterRole: auth.currentUser!.role,
        tempPassword: _passwordCtrl.text,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated(result.user, result.tempPassword);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.person_add_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(l10n.tr('users_create')),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      decoration: InputDecoration(labelText: l10n.tr('users_name')),
                      validator: (v) => Validators.name(v, l10n.tr('users_name')),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      decoration: InputDecoration(labelText: l10n.tr('users_lastname')),
                      validator: (v) => Validators.name(v, l10n.tr('users_lastname')),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.tr('users_username'),
                  prefixIcon: const Icon(Icons.alternate_email, size: 18),
                ),
                validator: Validators.username,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: InputDecoration(labelText: l10n.tr('users_role')),
                items: [
                  DropdownMenuItem(
                    value: UserRole.user,
                    child: Text(l10n.tr('users_role_user')),
                  ),
                  DropdownMenuItem(
                    value: UserRole.admin,
                    child: Text(l10n.tr('users_role_admin')),
                  ),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _passwordCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.tr('users_temp_password'),
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      ),
                      validator: Validators.password,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: l10n.tr('users_generate_password'),
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _generatePassword,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.tr('users_cancel')),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.tr('users_save')),
        ),
      ],
    );
  }
}

/// Отображение пароля с кнопкой копирования
class _SelectablePasswordBox extends StatelessWidget {
  final String password;
  const _SelectablePasswordBox({required this.password});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SelectableText(
        password,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
