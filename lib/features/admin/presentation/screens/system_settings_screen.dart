import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_extensions.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  // Academic Configuration
  String _activeYear = '2025-26';
  String _activeBatch = '2026';

  // Placement Policy Toggles
  bool _allowMultipleOffers = false;
  bool _requireFacultyApproval = true;
  bool _consentMandatory = true;
  bool _autoNotifyStudents = true;
  bool _maintenanceMode = false;

  // CGPA & Criteria
  final _defaultCgpaController = TextEditingController(text: '7.0');
  final _maxBacklogsController = TextEditingController(text: '0');

  // Department list
  final List<String> _departments = [
    'Computer Science & Engineering',
    'Information Science & Engineering',
    'Electronics & Communication',
    'Mechanical Engineering',
    'Civil Engineering',
  ];

  bool _isSaving = false;

  @override
  void dispose() {
    _defaultCgpaController.dispose();
    _maxBacklogsController.dispose();
    super.dispose();
  }

  void _save() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Settings saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.brassPrimary ?? theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text('System Settings', style: GoogleFonts.fraunces(fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(horizontal: 18)),
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Section 1: Academic Year ───
          _sectionHeader('🎓 Academic Configuration', theme, brandTheme),
          const SizedBox(height: 10),
          _card(theme, brandTheme, [
            _settingRow(
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF3B82F6),
              title: 'Active Academic Year',
              subtitle: 'Students and drives are scoped to this year.',
              trailing: DropdownButton<String>(
                value: _activeYear,
                underline: const SizedBox(),
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                items: ['2024-25', '2025-26', '2026-27'].map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: (v) => setState(() => _activeYear = v!),
              ),
            ),
            const Divider(height: 1),
            _settingRow(
              icon: Icons.school_rounded,
              color: const Color(0xFF8B5CF6),
              title: 'Graduating Batch',
              subtitle: 'Students of this batch are eligible for drives.',
              trailing: DropdownButton<String>(
                value: _activeBatch,
                underline: const SizedBox(),
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                items: ['2025', '2026', '2027'].map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: (v) => setState(() => _activeBatch = v!),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ─── Section 2: Placement Policy ───
          _sectionHeader('📋 Placement Policy', theme, brandTheme),
          const SizedBox(height: 10),
          _card(theme, brandTheme, [
            _toggleRow(
              icon: Icons.work_history_rounded,
              color: const Color(0xFF10B981),
              title: 'Allow Multiple Offers',
              subtitle: 'If off, students placed in one company are auto-blocked from others.',
              value: _allowMultipleOffers,
              onChanged: (v) => setState(() => _allowMultipleOffers = v),
              accent: accent,
            ),
            const Divider(height: 1),
            _toggleRow(
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF3B82F6),
              title: 'Require Faculty Approval',
              subtitle: 'Students must be verified by faculty before applying.',
              value: _requireFacultyApproval,
              onChanged: (v) => setState(() => _requireFacultyApproval = v),
              accent: accent,
            ),
            const Divider(height: 1),
            _toggleRow(
              icon: Icons.how_to_vote_rounded,
              color: const Color(0xFFB45309),
              title: 'Consent Form Mandatory',
              subtitle: 'Students must submit consent before applying to any drive.',
              value: _consentMandatory,
              onChanged: (v) => setState(() => _consentMandatory = v),
              accent: accent,
            ),
            const Divider(height: 1),
            _toggleRow(
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFF8B5CF6),
              title: 'Auto-notify Students',
              subtitle: 'Push notifications for new drives and status updates.',
              value: _autoNotifyStudents,
              onChanged: (v) => setState(() => _autoNotifyStudents = v),
              accent: accent,
            ),
          ]),

          const SizedBox(height: 20),

          // ─── Section 3: Default Criteria ───
          _sectionHeader('📐 Default Eligibility Criteria', theme, brandTheme),
          const SizedBox(height: 10),
          _card(theme, brandTheme, [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Minimum CGPA', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('Applied when drives don\'t specify a cutoff.', style: GoogleFonts.inter(fontSize: 11, color: brandTheme?.textMuted)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _defaultCgpaController,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      style: GoogleFonts.ibmPlexMono(fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: brandTheme?.surfaceAlt ?? theme.colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Max Active Backlogs', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('Maximum allowed active backlogs for placement eligibility.', style: GoogleFonts.inter(fontSize: 11, color: brandTheme?.textMuted)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _maxBacklogsController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.ibmPlexMono(fontWeight: FontWeight.w600, fontSize: 16),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: brandTheme?.surfaceAlt ?? theme.colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ─── Section 4: Departments ───
          _sectionHeader('🏛️ Departments', theme, brandTheme),
          const SizedBox(height: 10),
          _card(theme, brandTheme, [
            ..._departments.asMap().entries.map((e) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text('${e.key + 1}', style: GoogleFonts.ibmPlexMono(fontWeight: FontWeight.w700, fontSize: 13, color: accent)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.value, style: GoogleFonts.inter(fontSize: 13))),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade300),
                            onPressed: () => setState(() => _departments.removeAt(e.key)),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    if (e.key < _departments.length - 1) const Divider(height: 1),
                  ],
                )),
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: () => _showAddDeptDialog(context, accent),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Add Department', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ─── Section 5: Danger Zone ───
          _sectionHeader('⚠️ Danger Zone', theme, brandTheme),
          const SizedBox(height: 10),
          _card(theme, brandTheme, [
            _toggleRow(
              icon: Icons.construction_rounded,
              color: Colors.red,
              title: 'Maintenance Mode',
              subtitle: 'Locks all student and faculty access. Only admins can log in.',
              value: _maintenanceMode,
              onChanged: (v) {
                if (v) {
                  _showMaintenanceConfirm(context, accent, () => setState(() => _maintenanceMode = true));
                } else {
                  setState(() => _maintenanceMode = false);
                }
              },
              accent: Colors.red,
              isDestructive: true,
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, ThemeData theme, AppBrandTheme? brandTheme) => Text(
        label,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: brandTheme?.textMuted, letterSpacing: 0.6),
      );

  Widget _card(ThemeData theme, AppBrandTheme? brandTheme, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
        ),
        child: Column(children: children),
      );

  Widget _settingRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey), maxLines: 2),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      );

  Widget _toggleRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accent,
    bool isDestructive = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: isDestructive ? Colors.red : null)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey), maxLines: 2),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: isDestructive ? Colors.red : accent,
            ),
          ],
        ),
      );

  void _showAddDeptDialog(BuildContext context, Color accent) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Department', style: GoogleFonts.fraunces(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. AI & Data Science'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accent),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _departments.add(ctrl.text.trim()));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceConfirm(BuildContext context, Color accent, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Enable Maintenance Mode?', style: GoogleFonts.fraunces(fontWeight: FontWeight.w600)),
        content: const Text('This will lock out all students and faculty immediately. Only admins can access the system. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}
