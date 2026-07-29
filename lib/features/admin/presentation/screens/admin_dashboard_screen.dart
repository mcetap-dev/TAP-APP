import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/theme_extensions.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('System Administration', style: GoogleFonts.fraunces(fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => _body(context, profile?.fullName ?? 'Admin', brandTheme, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _body(BuildContext context, String name, AppBrandTheme? brandTheme, ThemeData theme) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Control',
                          style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text('User roles, security audit & database controls',
                          style: GoogleFonts.inter(fontSize: 13, color: brandTheme?.textMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('Admin',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED))),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _statCard('412', 'Users', theme, brandTheme)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('24', 'Companies', theme, brandTheme)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('1,028', 'Audit Logs', theme, brandTheme)),
              ],
            ),
            const SizedBox(height: 24),

            Text('Management Modules', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _card(Icons.people_outline_rounded, 'Users & Roles', const Color(0xFF7C3AED), theme, brandTheme),
                _card(Icons.business_center_outlined, 'Companies', const Color(0xFF3B82F6), theme, brandTheme),
                _card(Icons.security_rounded, 'Audit Logs', const Color(0xFF10B981), theme, brandTheme),
                _card(Icons.settings_suggest_rounded, 'System Settings', const Color(0xFFF59E0B), theme, brandTheme),
              ],
            ),
          ],
        ),
      );

  Widget _statCard(String num, String label, ThemeData theme, AppBrandTheme? brandTheme) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(num, style: GoogleFonts.ibmPlexMono(fontSize: 22, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: brandTheme?.textMuted)),
          ],
        ),
      );

  Widget _card(IconData icon, String label, Color color, ThemeData theme, AppBrandTheme? brandTheme) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface)),
          ],
        ),
      );
}
