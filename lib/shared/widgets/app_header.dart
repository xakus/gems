import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/theme_provider.dart';
import 'amotes_logo.dart';
import 'language_switcher.dart';
import 'theme_switcher.dart';

/// Общий AppHeader для Home и Settings экранов
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kHeaderHeight);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final user = auth.currentUser;

    return Container(
      height: kHeaderHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkHeader : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.9 : 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kPaddingLarge),
        child: Row(
          children: [
            // Логотип + название (Hero для анимации из Splash)
            Hero(tag: 'amotes_logo', child: AmotesLogo(size: 250)),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'amotes_title',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        kAppName,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 5,
                          foreground: Paint()
                            ..shader = AppColors.logoGradient.createShader(
                              const Rect.fromLTWH(0, 0, 80, 30),
                            ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).tr('app_full_name'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 0.3,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Переключатель языка
            const LanguageSwitcher(),
            const SizedBox(width: 4),

            // Переключатель темы
            const ThemeSwitcher(),
            const SizedBox(width: 4),

            // Настройки
            IconButton(
              tooltip: AppLocalizations.of(context).tr('header_settings'),
              icon: const Icon(Icons.settings_rounded),
              onPressed: () {
                if (ModalRoute.of(context)?.settings.name != kRouteSettings) {
                  Navigator.pushNamed(context, kRouteSettings);
                }
              },
            ),

            const SizedBox(width: 8),

            // Имя пользователя + кнопка выхода
            if (user != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: _UserChip(
                  name: user.fullName,
                  isAdmin: auth.isAdmin,
                  onLogout: () => _confirmLogout(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tr('header_logout')),
        content: Text(l10n.tr('header_logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tr('header_logout_no')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              context.read<ThemeProvider>().onLogout();
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                kRouteLogin,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.tr('header_logout_yes')),
          ),
        ],
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final String name;
  final bool isAdmin;
  final VoidCallback onLogout;

  const _UserChip({
    required this.name,
    required this.isAdmin,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceRaised : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            size: 16,
            color: isAdmin ? AppColors.accent : AppColors.primary,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkOnBackground
                    : AppColors.lightOnBackground,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.logout_rounded,
                size: 16,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
