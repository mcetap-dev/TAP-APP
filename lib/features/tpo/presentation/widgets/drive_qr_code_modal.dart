import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/presentation/widgets/subtle_divider.dart';
import '../../../student/domain/entities/drive.dart';
import '../providers/tpo_provider.dart';

class DriveQrCodeModal extends ConsumerStatefulWidget {
  final Drive drive;

  const DriveQrCodeModal({required this.drive, super.key});

  @override
  ConsumerState<DriveQrCodeModal> createState() => _DriveQrCodeModalState();
}

class _DriveQrCodeModalState extends ConsumerState<DriveQrCodeModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _qrPayload {
    return jsonEncode({
      'type': 'tap_drive_attendance',
      'drive_id': widget.drive.id,
      'company': widget.drive.companyName,
      'role': widget.drive.roleTitle,
    });
  }

  Future<void> _printQrSheet() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'MALNAD COLLEGE OF ENGINEERING, HASSAN',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Training & Placement Office — Attendance Check-In',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        widget.drive.companyName.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 22, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Role: ${widget.drive.roleTitle}',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 20),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: _qrPayload,
                        width: 240,
                        height: 240,
                      ),
                      pw.SizedBox(height: 16),
                      pw.Text(
                        'SCAN WITH placement_connect STUDENT APP TO MARK ATTENDANCE',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Drive_QR_${widget.drive.companyName}_${widget.drive.roleTitle}.pdf',
    );
  }

  Future<void> _exportPdfReport(List<Map<String, dynamic>> records) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MALNAD COLLEGE OF ENGINEERING',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Training & Placement Office (TPO)',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Text('OFFICIAL ATTENDANCE LOG',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Company: ${widget.drive.companyName}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Role: ${widget.drive.roleTitle}'),
                pw.Text('Total Scanned: ${records.length}'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Student Name', 'USN', 'Department', 'Scanned Time', 'Status'],
            data: records.asMap().entries.map((e) {
              final idx = e.key + 1;
              final rec = e.value;
              final profile = rec['profile'] as Map<String, dynamic>? ?? {};
              final name = profile['name'] as String? ?? 'N/A';
              final usn = profile['usn'] as String? ?? 'N/A';
              final dept = profile['department'] as String? ?? 'N/A';
              final timeStr = rec['scanned_at'] != null
                  ? DateTime.parse(rec['scanned_at'] as String)
                      .toLocal()
                      .toString()
                      .split('.')
                      .first
                  : 'N/A';
              final status = rec['status'] as String? ?? 'present';
              return [
                '$idx',
                name,
                usn,
                dept,
                timeStr,
                status.toUpperCase(),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Attendance_${widget.drive.companyName}_${widget.drive.roleTitle}.pdf',
    );
  }

  void _exportCsvReport(List<Map<String, dynamic>> records) {
    final buffer = StringBuffer();
    buffer.writeln('SL NO,STUDENT NAME,USN,DEPARTMENT,EMAIL,SCANNED TIME,STATUS');

    for (int i = 0; i < records.length; i++) {
      final rec = records[i];
      final profile = rec['profile'] as Map<String, dynamic>? ?? {};
      final name = profile['name'] as String? ?? '';
      final usn = profile['usn'] as String? ?? '';
      final dept = profile['department'] as String? ?? '';
      final email = profile['email'] as String? ?? '';
      final timeStr = rec['scanned_at'] != null
          ? DateTime.parse(rec['scanned_at'] as String).toLocal().toString().split('.').first
          : '';
      final status = rec['status'] as String? ?? 'present';

      buffer.writeln('${i + 1},"$name","$usn","$dept","$email","$timeStr","$status"');
    }

    final bytes = utf8.encode(buffer.toString());
    Printing.sharePdf(
      bytes: bytes,
      filename: 'Attendance_${widget.drive.companyName}.csv',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accent = brandTheme?.brassPrimary ?? theme.colorScheme.primary;
    final attendanceAsync = ref.watch(driveAttendanceProvider(widget.drive.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: brandTheme?.cardBorder ?? Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.drive.companyName,
                        style: GoogleFonts.fraunces(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Role: ${widget.drive.roleTitle}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: brandTheme?.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: accent,
            labelColor: accent,
            unselectedLabelColor: brandTheme?.textMuted,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.qr_code_rounded), text: 'Printable QR'),
              Tab(icon: Icon(Icons.people_alt_rounded), text: 'Live Attendance'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Printable QR Code
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: _qrPayload,
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Scan to Mark Attendance',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _printQrSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 20),
                          label: Text(
                            'Print / Export QR Sheet (PDF)',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab 2: Live Attendance Tracker & Exports
                attendanceAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('Error loading attendance: $err',
                        style: const TextStyle(color: Colors.red)),
                  ),
                  data: (records) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 16, color: accent),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${records.length} Scanned',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: records.isEmpty
                                    ? null
                                    : () => _exportPdfReport(records),
                                icon: const Icon(Icons.picture_as_pdf_rounded,
                                    size: 16, color: Colors.redAccent),
                                label: const Text('PDF',
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: records.isEmpty
                                    ? null
                                    : () => _exportCsvReport(records),
                                icon: const Icon(Icons.table_chart_rounded,
                                    size: 16, color: Colors.green),
                                label: const Text('CSV',
                                    style: TextStyle(color: Colors.green)),
                              ),
                            ],
                          ),
                        ),
                        const SubtleDivider(height: 1),
                        Expanded(
                          child: records.isEmpty
                              ? Center(
                                  child: Text(
                                    'No students scanned yet.',
                                    style: GoogleFonts.inter(
                                        color: brandTheme?.textMuted),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: records.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final rec = records[index];
                                    final profile = rec['profile']
                                            as Map<String, dynamic>? ??
                                        {};
                                    final name =
                                        profile['name'] as String? ?? 'Student';
                                    final usn = profile['usn'] as String? ?? '';
                                    final dept = profile['department']
                                            as String? ??
                                        '';
                                    final timeStr = rec['scanned_at'] != null
                                        ? DateTime.parse(
                                                rec['scanned_at'] as String)
                                            .toLocal()
                                            .toString()
                                            .split('.')
                                            .first
                                        : '';

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: brandTheme?.cardBorder ??
                                                Colors.grey.shade800),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                accent.withValues(alpha: 0.1),
                                            child: Text(
                                              '${index + 1}',
                                              style: GoogleFonts.ibmPlexMono(
                                                  fontWeight: FontWeight.bold,
                                                  color: accent),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14),
                                                ),
                                                Text(
                                                  '$usn · $dept',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: brandTheme
                                                          ?.textMuted),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade500
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'PRESENT',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green.shade600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                timeStr.split(' ').last,
                                                style: GoogleFonts.ibmPlexMono(
                                                  fontSize: 10,
                                                  color: brandTheme?.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
