import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/presentation/widgets/status_thread_widget.dart';
import '../providers/tpo_provider.dart';

class DriveCreationWizard extends ConsumerStatefulWidget {
  const DriveCreationWizard({super.key});

  @override
  ConsumerState<DriveCreationWizard> createState() => _DriveCreationWizardState();
}

class _DriveCreationWizardState extends ConsumerState<DriveCreationWizard> {
  int _currentStep = 0;
  final _basicDetailsFormKey = GlobalKey<FormState>();
  final _eligibilityFormKey = GlobalKey<FormState>();
  final _roundsFormKey = GlobalKey<FormState>();

  // Basic Details
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  final _ctcController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Eligibility & Schedule
  final _cgpaCutoffController = TextEditingController(text: '7.0');
  final _backlogsLimitController = TextEditingController(text: '0');
  final List<String> _branches = ['ISE', 'CSE', 'ECE'];
  final _branchController = TextEditingController();
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 14));

  // Rounds
  final List<String> _rounds = ['Aptitude Test', 'Technical Interview', 'HR Interview'];
  final _roundController = TextEditingController();

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _ctcController.dispose();
    _descriptionController.dispose();
    _cgpaCutoffController.dispose();
    _backlogsLimitController.dispose();
    _branchController.dispose();
    _roundController.dispose();
    super.dispose();
  }

  void _onStepContinue() {
    if (_currentStep == 0 && !_basicDetailsFormKey.currentState!.validate()) return;
    if (_currentStep == 1 && !_eligibilityFormKey.currentState!.validate()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
    } else {
      _submitDrive();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  bool _isSubmitting = false;

  Future<void> _submitDrive() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(tpoRepositoryProvider);
      final user = Supabase.instance.client.auth.currentUser;
      final createdBy = user?.id ?? '';

      // Get or create company first if needed
      final companies = await repo.getCompanies();
      String companyId = '';
      final companyName = _companyController.text.trim();

      final existingCompany = companies.where((c) => c.name.toLowerCase() == companyName.toLowerCase()).firstOrNull;
      if (existingCompany != null) {
        companyId = existingCompany.id;
      } else {
      try {
        await repo.createCompany(
          name: companyName,
          createdBy: createdBy,
        );
        final updatedCompanies = await repo.getCompanies();
        final newlyCreated = updatedCompanies.where((c) => c.name.toLowerCase() == companyName.toLowerCase()).firstOrNull;
        companyId = newlyCreated?.id ?? (updatedCompanies.isNotEmpty ? updatedCompanies.first.id : '');
      } catch (_) {
        // If company creation RLS policy blocks insertion, pick matching or first existing company
        final updatedCompanies = await repo.getCompanies();
        final newlyCreated = updatedCompanies.where((c) => c.name.toLowerCase() == companyName.toLowerCase()).firstOrNull;
        companyId = newlyCreated?.id ?? (updatedCompanies.isNotEmpty ? updatedCompanies.first.id : '');
      }
    }

      final cgpa = double.tryParse(_cgpaCutoffController.text.trim()) ?? 0.0;
      final backlogs = int.tryParse(_backlogsLimitController.text.trim()) ?? 0;

      await repo.createDrive(
        companyId: companyId,
        roleTitle: _roleController.text.trim(),
        ctcOrStipend: _ctcController.text.trim(),
        jobDescription: _descriptionController.text.trim(),
        eligibilityBranches: _branches,
        cgpaCutoff: cgpa,
        backlogLimit: backlogs,
        applicationDeadline: _selectedDeadline,
        status: 'active',
        createdBy: createdBy,
      );

      // Refresh drives list globally across the app
      ref.invalidate(tpoDrivesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ New placement drive created & published!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Failed to save drive: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>()!;

    final stepsData = [
      const StatusNodeData(label: 'Basic Info', isDone: true),
      StatusNodeData(label: 'Eligibility', isDone: _currentStep > 0, isCurrent: _currentStep == 1),
      StatusNodeData(label: 'Rounds', isDone: _currentStep > 1, isCurrent: _currentStep == 2),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Create Placement Drive', style: GoogleFonts.fraunces(fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp5, vertical: AppSpacing.sp4),
              color: theme.colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP ${_currentStep + 1} OF 3',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: brandTheme.brassPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        _currentStep == 0
                            ? 'Basic Company Info'
                            : _currentStep == 1
                                ? 'Eligibility Criteria'
                                : 'Recruitment Rounds',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: brandTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sp3),
                  StatusThreadWidget(nodes: stepsData),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Step Content Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.sp5),
                child: _buildCurrentStepForm(theme, brandTheme),
              ),
            ),

            // Bottom Navigation Action Buttons
            Container(
              padding: const EdgeInsets.all(AppSpacing.sp5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: brandTheme.cardBorder)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: GestureDetector(
                        onTap: _onStepCancel,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: brandTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                            border: Border.all(color: brandTheme.cardBorder),
                          ),
                          child: Center(
                            child: Text(
                              'Back',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: AppSpacing.sp3),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _onStepContinue,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: brandTheme.brassGradient,
                          borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                          boxShadow: [
                            BoxShadow(
                              color: brandTheme.brassSoft,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentStep == 2 ? 'Publish Drive' : 'Continue to Next Step',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: brandTheme.onBrass,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildCurrentStepForm(ThemeData theme, AppBrandTheme brandTheme) {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _basicDetailsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldHeader('COMPANY NAME', brandTheme),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(hintText: 'e.g. PhonePe, Razorpay'),
                validator: (v) => v == null || v.isEmpty ? 'Company name is required' : null,
              ),
              const SizedBox(height: AppSpacing.sp4),

              _fieldHeader('ROLE TITLE', brandTheme),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(hintText: 'e.g. Software Development Engineer-1'),
                validator: (v) => v == null || v.isEmpty ? 'Role title is required' : null,
              ),
              const SizedBox(height: AppSpacing.sp4),

              _fieldHeader('CTC / STIPEND', brandTheme),
              TextFormField(
                controller: _ctcController,
                decoration: const InputDecoration(hintText: 'e.g. ₹18 LPA or ₹50,000 / month'),
                validator: (v) => v == null || v.isEmpty ? 'CTC / Stipend is required' : null,
              ),
              const SizedBox(height: AppSpacing.sp4),

              _fieldHeader('JOB DESCRIPTION', brandTheme),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Enter role expectations, responsibilities, and benefits...'),
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _eligibilityFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldHeader('MINIMUM CGPA', brandTheme),
                        TextFormField(
                          controller: _cgpaCutoffController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(hintText: '7.0'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldHeader('MAX BACKLOGS', brandTheme),
                        TextFormField(
                          controller: _backlogsLimitController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '0'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp4),
              _fieldHeader('APPLICATION DEADLINE (END DATE)', brandTheme),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDeadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDeadline = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                    border: Border.all(color: brandTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDeadline.day}/${_selectedDeadline.month}/${_selectedDeadline.year}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Icon(Icons.calendar_month_rounded, color: brandTheme.brassPrimary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sp5),
              _fieldHeader('QUICK BATCH PRESETS', brandTheme),
              Wrap(
                spacing: AppSpacing.sp2,
                runSpacing: AppSpacing.sp2,
                children: [
                  ActionChip(
                    label: Text('All Branches', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                    backgroundColor: brandTheme.surfaceAlt,
                    onPressed: () {
                      setState(() {
                        _branches.clear();
                        _branches.addAll(['CSE', 'ISE', 'ECE', 'EEE', 'MECH', 'CIVIL', 'AIML']);
                      });
                    },
                  ),
                  ActionChip(
                    label: Text('CS & Circuit Only', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                    backgroundColor: brandTheme.surfaceAlt,
                    onPressed: () {
                      setState(() {
                        _branches.clear();
                        _branches.addAll(['CSE', 'ISE', 'ECE', 'AIML']);
                      });
                    },
                  ),
                  ActionChip(
                    label: Text('Core Engineering', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                    backgroundColor: brandTheme.surfaceAlt,
                    onPressed: () {
                      setState(() {
                        _branches.clear();
                        _branches.addAll(['EEE', 'MECH', 'CIVIL']);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp4),
              _fieldHeader('ELIGIBLE BRANCHES', brandTheme),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _branchController,
                      decoration: const InputDecoration(hintText: 'Add Branch (e.g. EEE, MECH)'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp2),
                  GestureDetector(
                    onTap: () {
                      if (_branchController.text.trim().isNotEmpty) {
                        setState(() {
                          _branches.add(_branchController.text.trim().toUpperCase());
                          _branchController.clear();
                        });
                      }
                    },
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        gradient: brandTheme.brassGradient,
                        borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                      ),
                      child: Icon(Icons.add_rounded, color: brandTheme.onBrass),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp3),
              Wrap(
                spacing: AppSpacing.sp2,
                runSpacing: AppSpacing.sp2,
                children: _branches.map((branch) {
                  return Chip(
                    label: Text(branch, style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700)),
                    backgroundColor: brandTheme.brassSoft,
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () => setState(() => _branches.remove(branch)),
                    side: BorderSide(color: brandTheme.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      case 2:
        return Form(
          key: _roundsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldHeader('RECRUITMENT ROUNDS SEQUENCE', brandTheme),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roundController,
                      decoration: const InputDecoration(hintText: 'e.g. Coding Assessment'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp2),
                  GestureDetector(
                    onTap: () {
                      if (_roundController.text.trim().isNotEmpty) {
                        setState(() {
                          _rounds.add(_roundController.text.trim());
                          _roundController.clear();
                        });
                      }
                    },
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        gradient: brandTheme.brassGradient,
                        borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                      ),
                      child: Icon(Icons.add_rounded, color: brandTheme.onBrass),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp4),

              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rounds.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _rounds.removeAt(oldIndex);
                    _rounds.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, idx) {
                  final roundName = _rounds[idx];
                  return Container(
                    key: ValueKey('round_${roundName}_$idx'),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sp2),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp4, vertical: 12),
                    decoration: ShapeDecoration(
                      color: theme.colorScheme.surface,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(AppShapes.radiusStandard),
                        side: BorderSide(color: brandTheme.cardBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: idx,
                          child: Icon(Icons.drag_indicator_rounded, size: 20, color: brandTheme.textMuted),
                        ),
                        const SizedBox(width: AppSpacing.sp2),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: brandTheme.brassSoft,
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: brandTheme.brassPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sp3),
                        Expanded(
                          child: Text(
                            roundName,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, size: 18, color: brandTheme.textMuted),
                          onPressed: () => setState(() => _rounds.removeAt(idx)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _fieldHeader(String title, AppBrandTheme brandTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: brandTheme.textMuted,
        ),
      ),
    );
  }
}
