import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/student_attendance_provider.dart';

class ScanAttendanceScreen extends ConsumerStatefulWidget {
  const ScanAttendanceScreen({super.key});

  @override
  ConsumerState<ScanAttendanceScreen> createState() => _ScanAttendanceScreenState();
}

class _ScanAttendanceScreenState extends ConsumerState<ScanAttendanceScreen> {
  late final MobileScannerController _cameraController;
  bool _isTorchOn = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _cameraController.addListener(_onCameraStateChange);
    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      await _cameraController.start();
    } on MobileScannerException catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = e.errorDetails?.message ?? 'Camera permission denied or unavailable.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Failed to start camera: $e';
        });
      }
    }
  }

  void _onCameraStateChange() {
    final state = _cameraController.value;
    if (state.error != null && mounted) {
      final errorCode = state.error!.errorCode;
      if (errorCode == MobileScannerErrorCode.permissionDenied) {
        setState(() {
          _cameraError = 'Camera permission is required to scan QR codes. Please grant permission in Settings.';
        });
      } else if (state.error!.errorDetails?.message != null) {
        setState(() {
          _cameraError = state.error!.errorDetails!.message;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController.removeListener(_onCameraStateChange);
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final state = ref.read(scanAttendanceProvider);
    if (state.status == ScanAttendanceStatus.validating) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        HapticFeedback.mediumImpact();
        ref.read(scanAttendanceProvider.notifier).processQrCode(raw);
        return;
      }
    }
  }

  Future<void> _toggleTorch() async {
    await _cameraController.toggleTorch();
    setState(() {
      _isTorchOn = _cameraController.value.torchState == TorchState.on;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>()!;
    final scanState = ref.watch(scanAttendanceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view — constrained to scan frame
          if (_cameraError != null)
            _buildCameraError(brandTheme)
          else
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: MobileScanner(
                    controller: _cameraController,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded, color: Colors.white54, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              error.errorDetails?.message ?? 'Camera error',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _startCamera,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: brandTheme.brassPrimary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Retry', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Scanning overlay (border frame + corner accents + scan line)
          _buildScanOverlay(brandTheme, scanState),

          // Top bar
          _buildTopBar(brandTheme, scanState),

          // Bottom state panel
          if (scanState.status == ScanAttendanceStatus.validating)
            _buildLoadingPanel(brandTheme),
          if (scanState.status == ScanAttendanceStatus.success)
            _buildSuccessPanel(brandTheme, scanState),
          if (scanState.status == ScanAttendanceStatus.error)
            _buildErrorPanel(brandTheme, scanState),
        ],
      ),
    );
  }

  Widget _buildCameraError(AppBrandTheme brandTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text(
              _cameraError!,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() => _cameraError = null);
                _startCamera();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: brandTheme.brassPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Grant Permission & Retry', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOverlay(AppBrandTheme brandTheme, ScanAttendanceState state) {
    final isProcessing = state.status == ScanAttendanceStatus.validating;
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isProcessing ? brandTheme.brassSoft.withValues(alpha: 0.5) : brandTheme.brassPrimary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            if (!isProcessing) ...[
              Positioned(top: -1, left: -1, child: _cornerAccent(brandTheme, topLeft: true)),
              Positioned(top: -1, right: -1, child: _cornerAccent(brandTheme, topRight: true)),
              Positioned(bottom: -1, left: -1, child: _cornerAccent(brandTheme, bottomLeft: true)),
              Positioned(bottom: -1, right: -1, child: _cornerAccent(brandTheme, bottomRight: true)),
            ],

          ],
        ),
      ),
    );
  }

  Widget _cornerAccent(AppBrandTheme brandTheme, {bool topLeft = false, bool topRight = false, bool bottomLeft = false, bool bottomRight = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: topLeft || topRight ? BorderSide(color: brandTheme.brassPrimary, width: 4) : BorderSide.none,
          bottom: bottomLeft || bottomRight ? BorderSide(color: brandTheme.brassPrimary, width: 4) : BorderSide.none,
          left: topLeft || bottomLeft ? BorderSide(color: brandTheme.brassPrimary, width: 4) : BorderSide.none,
          right: topRight || bottomRight ? BorderSide(color: brandTheme.brassPrimary, width: 4) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: topLeft ? const Radius.circular(8) : Radius.zero,
          topRight: topRight ? const Radius.circular(8) : Radius.zero,
          bottomLeft: bottomLeft ? const Radius.circular(8) : Radius.zero,
          bottomRight: bottomRight ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildTopBar(AppBrandTheme brandTheme, ScanAttendanceState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp4, vertical: AppSpacing.sp2),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
              const Spacer(),
              Text(
                'Scan Attendance',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleTorch,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isTorchOn
                        ? brandTheme.brassPrimary.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPanel(AppBrandTheme brandTheme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sp6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: brandTheme.brassPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sp4),
              Text(
                'Verifying attendance...',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sp2),
              Text(
                'Please wait while we record your attendance',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessPanel(AppBrandTheme brandTheme, ScanAttendanceState state) {
    final record = state.attendanceRecord;
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sp6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: 0.98),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: brandTheme.statusShortlisted.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, size: 36, color: brandTheme.statusShortlisted),
              ),
              const SizedBox(height: AppSpacing.sp4),
              Text(
                'Attendance Marked',
                style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sp5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sp4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _infoRow('Student', record?['student_name'] ?? '—'),
                    _infoRow('USN', record?['usn'] ?? '—'),
                    _infoRow('Department', record?['department'] ?? '—'),
                    const SizedBox(height: AppSpacing.sp3),
                    Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                    const SizedBox(height: AppSpacing.sp3),
                    _infoRow('Company', record?['company_name'] ?? '—'),
                    _infoRow('Drive', record?['drive_role'] ?? '—'),
                    _infoRow('Date', dateStr),
                    _infoRow('Time', timeStr),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sp5),
              GestureDetector(
                onTap: () {
                  ref.read(scanAttendanceProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: brandTheme.brassGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text('Done', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: brandTheme.onBrass)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildErrorPanel(AppBrandTheme brandTheme, ScanAttendanceState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sp6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: 0.98),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: brandTheme.statusRejected.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, size: 36, color: brandTheme.statusRejected),
              ),
              const SizedBox(height: AppSpacing.sp4),
              Text(
                state.errorTitle ?? 'Error',
                style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sp2),
              Text(
                state.errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.sp5),
              GestureDetector(
                onTap: () => ref.read(scanAttendanceProvider.notifier).resetToScanning(),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: brandTheme.brassGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text('Try Again', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: brandTheme.onBrass)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sp3),
              GestureDetector(
                onTap: () {
                  ref.read(scanAttendanceProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Center(
                    child: Text('Go Back', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
