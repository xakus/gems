import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/password_hasher.dart';
import '../../core/utils/validators.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/locale_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../user_management/audit_log_section.dart';
import '../user_management/compressor_templates_section.dart';
import '../user_management/user_management_section.dart';

/// Экран настроек с двумя разделами: Общие и Пользователи (только ADMIN)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: const AppHeader(),
      body: Row(
        children: [
          // Боковая навигация
          _SettingsSidebar(
            selectedIndex: _selectedIndex,
            isAdmin: isAdmin,
            onSelect: (i) => setState(() => _selectedIndex = i),
          ),

          // Разделитель
          const VerticalDivider(width: 1),

          // Содержимое
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: kAnimationDurationMs),
              child: switch (_selectedIndex) {
                0 => const _GeneralSection(key: ValueKey('general')),
                1 => const UserManagementSection(key: ValueKey('users')),
                2 => const CompressorTemplatesSection(key: ValueKey('templates')),
                _ => const AuditLogSection(key: ValueKey('audit')),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Боковая панель настроек
class _SettingsSidebar extends StatelessWidget {
  final int selectedIndex;
  final bool isAdmin;
  final ValueChanged<int> onSelect;

  const _SettingsSidebar({
    required this.selectedIndex,
    required this.isAdmin,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 220,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Кнопка «Назад»
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).tr('nav_back'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              AppLocalizations.of(context).tr('settings_title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.tune_rounded,
            label: AppLocalizations.of(context).tr('settings_general'),
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 4),
            _SidebarItem(
              icon: Icons.people_alt_rounded,
              label: AppLocalizations.of(context).tr('settings_users'),
              selected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
            const SizedBox(height: 4),
            _SidebarItem(
              icon: Icons.layers_rounded,
              label: AppLocalizations.of(context).tr('settings_templates'),
              selected: selectedIndex == 2,
              onTap: () => onSelect(2),
            ),
            const SizedBox(height: 4),
            _SidebarItem(
              icon: Icons.history_rounded,
              label: AppLocalizations.of(context).tr('settings_audit'),
              selected: selectedIndex == 3,
              onTap: () => onSelect(3),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: Duration(milliseconds: kAnimationDurationMs),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      // Material нужен чтобы ListTile рисовал ink-эффекты поверх
      // фона AnimatedContainer, а не под ним
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          leading: Icon(
            icon,
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
            ),
          ),
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Раздел «Общие»
class _GeneralSection extends StatelessWidget {
  const _GeneralSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPaddingLarge),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).tr('settings_title'),
                style: Theme.of(context).textTheme.headlineSmall,
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              const _ThemeCard().animate(delay: 50.ms).fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              const _LanguageCard().animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              const _ChangePasswordCard().animate(delay: 150.ms).fadeIn().slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка выбора темы
class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).tr('settings_theme'), style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ThemeOption(
                  label: AppLocalizations.of(context).tr('settings_theme_light'),
                  icon: Icons.light_mode_rounded,
                  selected: !isDark,
                  onTap: () => themeProvider.setTheme('light'),
                ),
                const SizedBox(width: 12),
                _ThemeOption(
                  label: AppLocalizations.of(context).tr('settings_theme_dark'),
                  icon: Icons.dark_mode_rounded,
                  selected: isDark,
                  onTap: () => themeProvider.setTheme('dark'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.primary : null),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка выбора языка
class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  static const _langs = [
    ('en', 'English'),
    ('az', 'Azərbaycan'),
    ('ru', 'Русский'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LocaleProvider>().languageCode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).tr('settings_language'), style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ...(_langs.map((lang) {
              final selected = lang.$1 == current;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LangOption(
                  code: lang.$1,
                  label: lang.$2,
                  selected: selected,
                  onTap: () => context.read<LocaleProvider>().setLocale(lang.$1),
                ),
              );
            })),
          ],
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            _FlagBadge(code: code),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primary : null,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

/// Флаг из картинки assets/images/{code}.webp
class _FlagBadge extends StatelessWidget {
  final String code;

  const _FlagBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        'assets/images/flags/$code.webp',
        width: 32,
        height: 22,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Карточка смены пароля
class _ChangePasswordCard extends StatefulWidget {
  const _ChangePasswordCard();

  @override
  State<_ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<_ChangePasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Проверяем текущий пароль
      final auth = context.read<AuthProvider>();
      final isValid = _verifyCurrentPassword(_currentCtrl.text);
      if (!isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).tr('settings_current_password_wrong')),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      await auth.changePassword(_newCtrl.text);
      if (mounted) {
        _formKey.currentState!.reset();
        _currentCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).tr('change_password_success')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _verifyCurrentPassword(String password) {
    final user = context.read<AuthProvider>().currentUser!;
    return PasswordHasher.verify(password, user.passwordSalt, user.passwordHash);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).tr('settings_change_password'), style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentCtrl,
                    obscureText: !_currentVisible,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).tr('settings_current_password'),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_currentVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _currentVisible = !_currentVisible),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? AppLocalizations.of(context).tr('validation_required')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newCtrl,
                    obscureText: !_newVisible,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).tr('settings_new_password'),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_newVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _newVisible = !_newVisible),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: !_confirmVisible,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).tr('settings_confirm_password'),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_confirmVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                            () => _confirmVisible = !_confirmVisible),
                      ),
                    ),
                    validator: (v) =>
                        Validators.passwordConfirm(v, _newCtrl.text),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                          : Text(AppLocalizations.of(context).tr('settings_save')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

