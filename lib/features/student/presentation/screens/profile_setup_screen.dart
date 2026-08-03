import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/file_name_extractor.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/usn_parser.dart';
import '../../../../shared/presentation/widgets/status_thread_widget.dart';
import '../../../../shared/presentation/widgets/subtle_divider.dart';
import '../../../admin/domain/entities/department.dart';
import '../../../admin/presentation/providers/departments_provider.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/student_onboarding_data.dart';
import '../providers/student_onboarding_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileSetupScreen extends ConsumerStatefulWidget {
  /// When true the wizard loads existing data and allows editing.
  final bool isEditMode;

  /// Step to open on (edit mode only). Lets each profile section open its own
  /// step directly instead of restarting the whole wizard.
  final int initialStep;

  const ProfileSetupScreen({this.isEditMode = false, this.initialStep = 0, super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _currentStep = 0;

  final _personalFormKey = GlobalKey<FormState>();
  final _academicFormKey = GlobalKey<FormState>();
  final _educationFormKey = GlobalKey<FormState>();

  // Step 1 — Personal
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  DateTime? _dob;
  String? _gender;
  Uint8List? _photoBytes;
  String? _photoFileName;
  String? _existingPhotoUrl;

  // Step 2 — Academic
  int? _semester;
  String? _section;
  int? _admissionYear;
  int? _graduationYear;

  // Step 3 — Education
  late final TextEditingController _sslcController;
  late final TextEditingController _pucController;
  late final TextEditingController _cgpaController;
  late final TextEditingController _backlogsController;

  // Step 4 — Resume
  Uint8List? _resumeBytes;
  String? _resumeFileName;
  String? _existingResumeUrl;
  int? _resumeFileSize;

  // Derived from profile
  UserProfile? _profile;

  static const _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const _semesterOptions = [1, 2, 3, 4, 5, 6, 7, 8];
  static const _sectionOptions = ['A', 'B', 'C', 'D', 'E', 'F'];
  static final _yearOptions = List.generate(
    DateTime.now().year - 2015 + 5,
    (i) => 2016 + i,
  );

  @override
  void initState() {
    super.initState();
    _currentStep = widget.isEditMode ? widget.initialStep : 0;
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _sslcController = TextEditingController();
    _pucController = TextEditingController();
    _cgpaController = TextEditingController();
    _backlogsController = TextEditingController(text: '0');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(authNotifierProvider).valueOrNull;
      if (profile != null) {
        setState(() {
          _profile = profile;
          _nameController.text = profile.name;
          _phoneController.text = profile.phone ?? '';
          _dob = profile.dob;
          _gender = _genderOptions.contains(profile.gender) ? profile.gender : null;
          _existingPhotoUrl = profile.photoUrl;
          _semester = _semesterOptions.contains(profile.semester) ? profile.semester : null;
          _section = _sectionOptions.contains(profile.section) ? profile.section : null;
          _admissionYear = _yearOptions.contains(profile.admissionYear) ? profile.admissionYear : null;
          _graduationYear = _yearOptions.contains(profile.graduationYear) ? profile.graduationYear : null;
          _sslcController.text =
              profile.tenthPercent != null ? '${profile.tenthPercent}' : '';
          _pucController.text = profile.twelfthOrDiplomaPercent != null
              ? '${profile.twelfthOrDiplomaPercent}'
              : '';
          _cgpaController.text =
              profile.cgpa != null ? '${profile.cgpa}' : '';
          _backlogsController.text = '${profile.activeBacklogs}';
          _existingResumeUrl = profile.resumeUrl;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _sslcController.dispose();
    _pucController.dispose();
    _cgpaController.dispose();
    _backlogsController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _resolveDepartment(String? usn, List<Department> departments) {
    if (usn == null || usn.isEmpty) return 'Not assigned';
    final detected = UsnParser.detectDepartment(usn, departments);
    return detected?.name ?? 'Not assigned';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ── Step navigation ──────────────────────────────────────────────────────

  void _onNext() {
    if (_currentStep == 0 && !_personalFormKey.currentState!.validate()) return;
    if (_currentStep == 1 && !_academicFormKey.currentState!.validate()) return;
    if (_currentStep == 2 && !_educationFormKey.currentState!.validate()) return;
    if (_currentStep == 3) {
      if (_resumeBytes == null && _existingResumeUrl == null) {
        _showSnack('Please upload your resume before continuing.');
        return;
      }
    }

    if (_currentStep < 4) {
      setState(() => _currentStep += 1);
    } else {
      _submit();
    }
  }

  void _onBack() {
    if (widget.isEditMode) {
      // Edit mode opens a single section — back returns to the profile page
      Navigator.of(context).pop();
    } else if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  /// Edit mode: validates only the current section, then saves and returns to
  /// the profile page. Other sections are preserved (pre-filled from profile).
  void _saveFromCurrentStep() {
    if (_currentStep == 0 && !_personalFormKey.currentState!.validate()) return;
    if (_currentStep == 1 && !_academicFormKey.currentState!.validate()) return;
    if (_currentStep == 2 && !_educationFormKey.currentState!.validate()) return;
    _submit();
  }

  void _jumpToStep(int step) {
    setState(() => _currentStep = step);
  }

  // ── File pickers ──────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final theme = Theme.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Photo',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sp2),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text('Gallery', style: GoogleFonts.inter(fontSize: 13)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: Text('Camera', style: GoogleFonts.inter(fontSize: 13)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      imageQuality: 100,
    );
    if (xFile == null) return;

    CroppedFile? croppedFile;
    if (source == ImageSource.gallery) {
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: xFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo',
              toolbarColor: theme.colorScheme.surface,
              toolbarWidgetColor: theme.colorScheme.onSurface,
              statusBarLight: true,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Photo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );
      } catch (_) {
        // Cropping cancelled or failed — use original image
      }
    }

    final bytes = croppedFile != null
        ? await croppedFile.readAsBytes()
        : await xFile.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoFileName = xFile.name;
    });
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _resumeBytes = file.bytes;
      _resumeFileName = file.name;
      _resumeFileSize = file.size;
    });
  }

  void _deleteResume() {
    setState(() {
      _resumeBytes = null;
      _resumeFileName = null;
      _resumeFileSize = null;
      _existingResumeUrl = null;
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final data = StudentOnboardingData(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      dob: _dob,
      gender: _gender,
      photoBytes: _photoBytes,
      photoFileName: _photoFileName,
      existingPhotoUrl: _existingPhotoUrl,
      semester: _semester,
      section: _section,
      admissionYear: _admissionYear,
      graduationYear: _graduationYear,
      sslcPercent: double.tryParse(_sslcController.text.trim()) ?? 0.0,
      pucOrDiplomaPercent: double.tryParse(_pucController.text.trim()) ?? 0.0,
      cgpa: double.tryParse(_cgpaController.text.trim()) ?? 0.0,
      activeBacklogs: int.tryParse(_backlogsController.text.trim()) ?? 0,
      resumeBytes: _resumeBytes,
      resumeFileName: _resumeFileName,
      existingResumeUrl: _existingResumeUrl,
    );

    final notifier = ref.read(studentOnboardingNotifierProvider.notifier);
    final success = await notifier.submit(userId: userId, data: data);

    if (mounted) {
      if (success) {
        _showSnack(widget.isEditMode
            ? 'Profile updated successfully!'
            : 'Profile complete! Welcome aboard.');
        ref.read(authNotifierProvider.notifier).refreshProfile(userId);
        if (widget.isEditMode) {
          // Return to the profile page instead of resetting the stack
          Navigator.of(context).pop();
        } else {
          context.go('/student');
        }
      } else {
        final err = ref.read(studentOnboardingNotifierProvider).error;
        _showSnack('Failed to save: $err', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>()!;
    final isSubmitting =
        ref.watch(studentOnboardingNotifierProvider).isLoading;

    final stepLabels = ['Personal', 'Academic', 'Education', 'Resume', 'Review'];
    final stepSubtitles = [
      'Personal Information',
      'Academic Details',
      'Education & Scores',
      'Resume Upload',
      'Review & Submit',
    ];

    final stepsData = List.generate(stepLabels.length, (i) {
      return StatusNodeData(
        label: stepLabels[i],
        isDone: i < _currentStep,
        isCurrent: i == _currentStep,
      );
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? 'Edit Profile' : 'Complete Your Profile',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: (_currentStep > 0 || widget.isEditMode)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: isSubmitting ? null : _onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress Header ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp5, vertical: AppSpacing.sp4),
              color: theme.colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP ${_currentStep + 1} OF 5',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: brandTheme.brassPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sp3),
                      Expanded(
                        child: Text(
                          stepSubtitles[_currentStep],
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: brandTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sp3),
                  StatusThreadWidget(nodes: stepsData),
                ],
              ),
            ),
            const SubtleDivider(
              height: 1,
              thickness: 0.5,
            ),

            // ── Step Content ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.sp5),
                child: _buildCurrentStep(theme, brandTheme),
              ),
            ),

            // ── Bottom Navigation ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.sp5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: brandTheme.cardBorder)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: _NavButton(
                        label: 'Back',
                        onTap: isSubmitting ? null : _onBack,
                        isSecondary: true,
                        brandTheme: brandTheme,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sp3),
                  ],
                  Expanded(
                    flex: 2,
                    child: _NavButton(
                      label: widget.isEditMode
                          ? (_currentStep == 4 ? 'Save Changes' : 'Save Section')
                          : (_currentStep == 4 ? 'Save & Finish' : 'Continue'),
                      onTap: isSubmitting
                          ? null
                          : (widget.isEditMode ? _saveFromCurrentStep : _onNext),
                      isLoading: isSubmitting,
                      brandTheme: brandTheme,
                      theme: theme,
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

  // ── Step builders ─────────────────────────────────────────────────────────

  Widget _buildCurrentStep(ThemeData theme, AppBrandTheme brandTheme) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Personal(theme, brandTheme);
      case 1:
        return _buildStep2Academic(theme, brandTheme);
      case 2:
        return _buildStep3Education(theme, brandTheme);
      case 3:
        return _buildStep4Resume(theme, brandTheme);
      case 4:
        return _buildStep5Review(theme, brandTheme);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Personal Information ──────────────────────────────────────────

  Widget _buildStep1Personal(ThemeData theme, AppBrandTheme brandTheme) {
    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _SectionHeader(
            icon: Icons.person_rounded,
            title: 'Personal Information',
            description: 'Tell us about yourself',
            brandTheme: brandTheme,
          ),
          const SizedBox(height: AppSpacing.sp5),

          // Photo picker
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: brandTheme.surfaceAlt,
                    backgroundImage: _photoBytes != null
                        ? MemoryImage(_photoBytes!)
                        : (_existingPhotoUrl != null
                            ? NetworkImage(_existingPhotoUrl!) as ImageProvider
                            : null),
                    child: (_photoBytes == null && _existingPhotoUrl == null)
                        ? Icon(Icons.person_rounded,
                            size: 48, color: brandTheme.textMuted)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: brandTheme.brassGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          size: 14, color: brandTheme.onBrass),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp5),

          // College Email (read-only)
          _label('COLLEGE EMAIL', brandTheme),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3 + 2),
            decoration: BoxDecoration(
              color: brandTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
              border: Border.all(color: brandTheme.cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 16, color: brandTheme.textMuted),
                const SizedBox(width: AppSpacing.sp2),
                Expanded(
                  child: Text(
                    _profile?.email ?? 'Not available',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sp4),

          // Full Name
          _label('FULL NAME', brandTheme),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'e.g. Rahul Sharma'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
          ),
          const SizedBox(height: AppSpacing.sp4),

          // Phone
          _label('PHONE NUMBER', brandTheme),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration:
                const InputDecoration(hintText: 'e.g. +91 9876543210'),
          ),
          const SizedBox(height: AppSpacing.sp4),

          // DOB
          _label('DATE OF BIRTH', brandTheme),
          _DatePickerTile(
            selected: _dob,
            theme: theme,
            brandTheme: brandTheme,
            onChanged: (d) => setState(() => _dob = d),
          ),
          const SizedBox(height: AppSpacing.sp4),

          // Gender
          _label('GENDER', brandTheme),
          DropdownButtonFormField<String>(
            value: _gender,
            hint: Text('Select gender',
                style: GoogleFonts.inter(
                    fontSize: 13, color: brandTheme.textMuted)),
            items: _genderOptions
                .map((g) => DropdownMenuItem(
                      value: g,
                      child: Text(g, style: GoogleFonts.inter(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _gender = v),
            decoration: const InputDecoration(),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Academic Information ──────────────────────────────────────────

  Widget _buildStep2Academic(ThemeData theme, AppBrandTheme brandTheme) {
    final usn = _profile?.usn ?? 'N/A';
    final departmentsAsync = ref.watch(departmentsProvider);
    final departments = departmentsAsync.valueOrNull ?? [];
    final deptName = _resolveDepartment(_profile?.usn, departments);

    return Form(
      key: _academicFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.school_rounded,
            title: 'Academic Details',
            description: 'Your enrollment and department information',
            brandTheme: brandTheme,
          ),
          const SizedBox(height: AppSpacing.sp5),

          // Read-only fields
          _InfoTile(
              label: 'USN / Roll Number', value: usn, theme: theme, brandTheme: brandTheme),
          const SizedBox(height: AppSpacing.sp3),
          _InfoTile(
              label: 'Department', value: deptName, theme: theme, brandTheme: brandTheme),
          const SizedBox(height: AppSpacing.sp4),

          // Editable: Semester & Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('SEMESTER', brandTheme),
                    DropdownButtonFormField<int>(
                      value: _semester,
                      hint: Text('Select',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: brandTheme.textMuted)),
                      items: _semesterOptions
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('Semester $s',
                                    style: GoogleFonts.inter(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _semester = v),
                      decoration: const InputDecoration(),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('SECTION', brandTheme),
                    DropdownButtonFormField<String>(
                      value: _section,
                      hint: Text('Select',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: brandTheme.textMuted)),
                      items: _sectionOptions
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('Section $s',
                                    style: GoogleFonts.inter(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _section = v),
                      decoration: const InputDecoration(),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp4),

          // Editable: Admission Year & Graduation Year
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('ADMISSION YEAR', brandTheme),
                    DropdownButtonFormField<int>(
                      value: _admissionYear,
                      hint: Text('Select',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: brandTheme.textMuted)),
                      items: _yearOptions
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text('$y',
                                    style: GoogleFonts.inter(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _admissionYear = v;
                          if (v != null) {
                            final autoGrad = v + 4;
                            _graduationYear = _yearOptions.contains(autoGrad)
                                ? autoGrad
                                : null;
                          }
                        });
                      },
                      decoration: const InputDecoration(),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('GRADUATION YEAR', brandTheme),
                    DropdownButtonFormField<int>(
                      value: _graduationYear,
                      hint: Text('Select',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: brandTheme.textMuted)),
                      items: _yearOptions
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text('$y',
                                    style: GoogleFonts.inter(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _graduationYear = v),
                      decoration: const InputDecoration(),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 3: Education & Scores ────────────────────────────────────────────

  Widget _buildStep3Education(ThemeData theme, AppBrandTheme brandTheme) {
    return Form(
      key: _educationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.analytics_rounded,
            title: 'Education & Scores',
            description: 'Your academic performance details',
            brandTheme: brandTheme,
          ),
          const SizedBox(height: AppSpacing.sp5),

          _label('SSLC PERCENTAGE / CGPA (10TH GRADE)', brandTheme),
          TextFormField(
            controller: _sslcController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(hintText: 'e.g. 92.5 or 9.4'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Enter a valid number';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sp4),

          _label('PUC / DIPLOMA PERCENTAGE (12TH GRADE)', brandTheme),
          TextFormField(
            controller: _pucController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(hintText: 'e.g. 88.0 or 9.1'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Enter a valid number';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sp4),

          _label('CURRENT CGPA', brandTheme),
          TextFormField(
            controller: _cgpaController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(hintText: 'e.g. 8.5 (out of 10)'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'CGPA is required';
              final d = double.tryParse(v);
              if (d == null || d < 0 || d > 10) {
                return 'Enter a valid CGPA (0.0 - 10.0)';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sp4),

          _label('CURRENT ACTIVE BACKLOGS', brandTheme),
          TextFormField(
            controller: _backlogsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: '0'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  // ── Step 4: Resume ────────────────────────────────────────────────────────

  Widget _buildStep4Resume(ThemeData theme, AppBrandTheme brandTheme) {
    final hasResume = _resumeBytes != null || _existingResumeUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.description_rounded,
          title: 'Resume',
          description: 'Upload your resume in PDF format. This will be visible to companies during placement drives.',
          brandTheme: brandTheme,
        ),
        const SizedBox(height: AppSpacing.sp5),

        if (hasResume) ...[
          // Resume card with details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sp4),
            decoration: BoxDecoration(
              color: brandTheme.brassSoft.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppShapes.radiusStandard),
              border: Border.all(
                color: brandTheme.brassPrimary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                // PDF icon + info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sp3),
                      decoration: BoxDecoration(
                        color: brandTheme.brassPrimary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppShapes.radiusSmall),
                      ),
                      child: Icon(Icons.picture_as_pdf_rounded,
                          size: 28, color: brandTheme.brassPrimary),
                    ),
                    const SizedBox(width: AppSpacing.sp3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _resumeFileName ??
                                (_existingResumeUrl != null
                                    ? FileNameExtractor.extract(_existingResumeUrl!)
                                    : 'Resume'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _resumeFileSize != null
                                ? _formatFileSize(_resumeFileSize)
                                : 'PDF Document',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: brandTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp2,
                          vertical: AppSpacing.sp1),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 12, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Uploaded',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp4),

                // Action buttons
                Row(
                  children: [
                    if (_existingResumeUrl != null)
                      Expanded(
                        child: _ResumeActionButton(
                          label: 'View',
                          icon: Icons.open_in_new_rounded,
                          onTap: () async {
                            final url = Uri.parse(_existingResumeUrl!);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          brandTheme: brandTheme,
                          theme: theme,
                        ),
                      ),
                    if (_existingResumeUrl != null)
                      const SizedBox(width: AppSpacing.sp2),
                    Expanded(
                      child: _ResumeActionButton(
                        label: 'Replace',
                        icon: Icons.swap_horiz_rounded,
                        onTap: _pickResume,
                        brandTheme: brandTheme,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sp2),
                    Expanded(
                      child: _ResumeActionButton(
                        label: 'Delete',
                        icon: Icons.delete_outline_rounded,
                        onTap: _deleteResume,
                        isDestructive: true,
                        brandTheme: brandTheme,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          // Upload box
          GestureDetector(
            onTap: _pickResume,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sp7, horizontal: AppSpacing.sp5),
              decoration: BoxDecoration(
                color: brandTheme.surfaceAlt,
                borderRadius:
                    BorderRadius.circular(AppShapes.radiusStandard),
                border: Border.all(
                  color: brandTheme.cardBorder,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_rounded,
                      size: 44, color: brandTheme.textMuted),
                  const SizedBox(height: AppSpacing.sp3),
                  Text(
                    'Tap to upload PDF',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp1),
                  Text(
                    'PDF only',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: brandTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Step 5: Review & Submit ───────────────────────────────────────────────

  Widget _buildStep5Review(ThemeData theme, AppBrandTheme brandTheme) {
    final usn = _profile?.usn ?? 'N/A';
    final departmentsAsync = ref.watch(departmentsProvider);
    final departments = departmentsAsync.valueOrNull ?? [];
    final deptName = _resolveDepartment(_profile?.usn, departments);
    final hasPhoto = _photoBytes != null || _existingPhotoUrl != null;
    final hasResume = _resumeBytes != null || _existingResumeUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.rate_review_rounded,
          title: 'Review Your Profile',
          description: 'Verify your information before submitting',
          brandTheme: brandTheme,
        ),
        const SizedBox(height: AppSpacing.sp5),

        // Profile photo preview
        if (hasPhoto)
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundImage: _photoBytes != null
                  ? MemoryImage(_photoBytes!) as ImageProvider
                  : NetworkImage(_existingPhotoUrl!),
            ),
          ),
        const SizedBox(height: AppSpacing.sp5),

        // Personal card
        _ReviewCard(
          title: 'Personal Information',
          icon: Icons.person_rounded,
          onTap: () => _jumpToStep(0),
          brandTheme: brandTheme,
          theme: theme,
          rows: [
            ('College Email', _profile?.email ?? '—'),
            ('Full Name', _nameController.text.trim()),
            ('Phone', _phoneController.text.trim().isEmpty ? '—' : _phoneController.text.trim()),
            ('Date of Birth', _dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : '—'),
            ('Gender', _gender ?? '—'),
          ],
        ),
        const SizedBox(height: AppSpacing.sp3),

        // Academic card
        _ReviewCard(
          title: 'Academic Details',
          icon: Icons.school_rounded,
          onTap: () => _jumpToStep(1),
          brandTheme: brandTheme,
          theme: theme,
          rows: [
            ('USN', usn),
            ('Department', deptName),
            ('Semester', _semester != null ? 'Semester $_semester' : '—'),
            ('Section', _section != null ? 'Section $_section' : '—'),
            ('Admission Year', _admissionYear?.toString() ?? '—'),
            ('Graduation Year', _graduationYear?.toString() ?? '—'),
          ],
        ),
        const SizedBox(height: AppSpacing.sp3),

        // Education card
        _ReviewCard(
          title: 'Education & Scores',
          icon: Icons.analytics_rounded,
          onTap: () => _jumpToStep(2),
          brandTheme: brandTheme,
          theme: theme,
          rows: [
            ('SSLC %', _sslcController.text.isEmpty ? '—' : '${_sslcController.text}%'),
            ('PUC / Diploma %', _pucController.text.isEmpty ? '—' : '${_pucController.text}%'),
            ('CGPA', _cgpaController.text.isEmpty ? '—' : _cgpaController.text),
            ('Active Backlogs', _backlogsController.text),
          ],
        ),
        const SizedBox(height: AppSpacing.sp3),

        // Resume card
        _ReviewCard(
          title: 'Resume',
          icon: Icons.description_rounded,
          onTap: () => _jumpToStep(3),
          brandTheme: brandTheme,
          theme: theme,
          rows: [
            ('Status', hasResume ? 'Ready to upload' : 'No resume uploaded'),
            if (hasResume && _resumeFileName != null)
              ('File', _resumeFileName!),
            if (hasResume && _resumeFileName == null && _existingResumeUrl != null)
              ('File', FileNameExtractor.extract(_existingResumeUrl!)),
          ],
        ),
        const SizedBox(height: AppSpacing.sp5),

        Container(
          padding: const EdgeInsets.all(AppSpacing.sp4),
          decoration: BoxDecoration(
            color: brandTheme.brassSoft.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
            border:
                Border.all(color: brandTheme.brassPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: brandTheme.brassPrimary),
              const SizedBox(width: AppSpacing.sp2),
              Expanded(
                child: Text(
                  'Tap any section above to edit. Press "${widget.isEditMode ? 'Save Changes' : 'Save & Finish'}" to submit.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: brandTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _label(String text, AppBrandTheme brandTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp2),
      child: Text(
        text,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: brandTheme.brassPrimary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable local widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final AppBrandTheme brandTheme;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.description,
    required this.brandTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sp2),
          decoration: BoxDecoration(
            color: brandTheme.brassPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
          ),
          child: Icon(icon, size: 18, color: brandTheme.brassPrimary),
        ),
        const SizedBox(width: AppSpacing.sp3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(
                    fontSize: 12, color: brandTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final AppBrandTheme brandTheme;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.theme,
    required this.brandTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3),
      decoration: BoxDecoration(
        color: brandTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
        border: Border.all(color: brandTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: brandTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime? selected;
  final ThemeData theme;
  final AppBrandTheme brandTheme;
  final ValueChanged<DateTime?> onChanged;

  const _DatePickerTile({
    required this.selected,
    required this.theme,
    required this.brandTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected ?? DateTime(2000),
          firstDate: DateTime(1980),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
        );
        onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3 + 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
          border: Border.all(color: brandTheme.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selected != null
                    ? '${selected!.day}/${selected!.month}/${selected!.year}'
                    : 'Select date of birth',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      selected != null ? FontWeight.w600 : FontWeight.normal,
                  color: selected != null
                      ? theme.colorScheme.onSurface
                      : brandTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sp2),
            Icon(Icons.calendar_month_rounded,
                color: brandTheme.brassPrimary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final List<(String, String)> rows;
  final AppBrandTheme brandTheme;
  final ThemeData theme;

  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.rows,
    required this.brandTheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppShapes.radiusStandard),
          border: Border.all(color: brandTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp4, AppSpacing.sp3, AppSpacing.sp4, 0),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: brandTheme.brassPrimary),
                  const SizedBox(width: AppSpacing.sp2),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: brandTheme.textMuted),
                ],
              ),
            ),
            const SubtleDivider(
              height: 1,
              thickness: 0.5,
            ),
            ...rows.map((row) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp4, vertical: AppSpacing.sp2 + 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        row.$1,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: brandTheme.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.sp1),
          ],
        ),
      ),
    );
  }
}

class _ResumeActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
  final AppBrandTheme brandTheme;
  final ThemeData theme;

  const _ResumeActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.brandTheme,
    required this.theme,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : brandTheme.brassPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isSecondary;
  final bool isLoading;
  final AppBrandTheme brandTheme;
  final ThemeData theme;

  const _NavButton({
    required this.label,
    required this.onTap,
    required this.brandTheme,
    required this.theme,
    this.isSecondary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp3, vertical: AppSpacing.sp3),
        decoration: BoxDecoration(
          gradient: isSecondary ? null : brandTheme.brassGradient,
          color: isSecondary ? brandTheme.surfaceAlt : null,
          borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
          border:
              isSecondary ? Border.all(color: brandTheme.cardBorder) : null,
          boxShadow: isSecondary
              ? null
              : [
                  BoxShadow(
                    color: brandTheme.brassSoft,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: brandTheme.onBrass,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSecondary
                        ? theme.colorScheme.onSurface
                        : brandTheme.onBrass,
                  ),
                ),
        ),
      ),
    );
  }
}
