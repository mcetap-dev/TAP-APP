import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/presentation/widgets/subtle_divider.dart';
import '../../domain/entities/department.dart';
import '../providers/departments_provider.dart';

class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  ConsumerState<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
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

  Future<void> _deleteDepartment(Department dept) async {
    try {
      final repo = ref.read(departmentsRepositoryProvider);
      await repo.delete(dept.id);
      ref.invalidate(departmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted department ${dept.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting department: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.brassPrimary ?? theme.colorScheme.primary;

    final deptsAsync = ref.watch(departmentsProvider);

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
            const SubtleDivider(height: 1),
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
            const SubtleDivider(height: 1),
            _toggleRow(
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF3B82F6),
              title: 'Require Faculty Approval',
              subtitle: 'Students must be verified by faculty before applying.',
              value: _requireFacultyApproval,
              onChanged: (v) => setState(() => _requireFacultyApproval = v),
              accent: accent,
            ),
            const SubtleDivider(height: 1),
            _toggleRow(
              icon: Icons.how_to_vote_rounded,
              color: const Color(0xFFB45309),
              title: 'Consent Form Mandatory',
              subtitle: 'Students must submit consent before applying to any drive.',
              value: _consentMandatory,
              onChanged: (v) => setState(() => _consentMandatory = v),
              accent: accent,
            ),
            const SubtleDivider(height: 1),
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
            const SubtleDivider(height: 1),
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

          // ─── Section 4: Departments with Branch Codes ───
          _sectionHeader('🏛️ Departments & USN Branch Mapping', theme, brandTheme),
          const SizedBox(height: 10),
          deptsAsync.when(
            loading: () => _card(theme, brandTheme, [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ]),
            error: (err, _) => _card(theme, brandTheme, [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading departments: $err', style: const TextStyle(color: Colors.red)),
              ),
            ]),
            data: (departments) => _card(theme, brandTheme, [
              if (departments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No departments registered.'),
                )
              else
                ...departments.asMap().entries.map((e) {
                  final dept = e.value;
                  final isLast = e.key == departments.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dept.branchCode,
                                style: GoogleFonts.ibmPlexMono(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                dept.name,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade300),
                              onPressed: () => _deleteDepartment(dept),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) const SubtleDivider(height: 1),
                    ],
                  );
                }),
              const SubtleDivider(height: 1),
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
          ),

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
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Department', style: GoogleFonts.fraunces(fontWeight: FontWeight.w600)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Department Name',
                  hintText: 'e.g. Civil Engineering',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Branch Code (USN Segment)',
                  hintText: 'e.g. CV',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 2 || v.trim().length > 4) return '2-4 chars';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accent),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final repo = ref.read(departmentsRepositoryProvider);
                try {
                  await repo.create(
                    name: nameCtrl.text.trim(),
                    branchCode: codeCtrl.text.trim(),
                  );
                  ref.invalidate(departmentsProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating department: $e')),
                    );
                  }
                }
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

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
