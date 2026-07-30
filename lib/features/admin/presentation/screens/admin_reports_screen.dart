import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:share_plus/share_plus.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  // Mock NAAC/NBA Stats data
  final List<Map<String, dynamic>> _placementStats = [
    {'department': 'Information Science', 'total_students': 120, 'total_placed': 105, 'total_attended': 110},
    {'department': 'Computer Science', 'total_students': 150, 'total_placed': 140, 'total_attended': 145},
    {'department': 'Electronics', 'total_students': 100, 'total_placed': 80, 'total_attended': 95},
  ];

  Future<void> _exportToPdf() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Institution Placement Report (NAAC/NBA)', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  context: context,
                  headers: ['Department', 'Total Students', 'Attended Drives', 'Total Placed', 'Placement %'],
                  data: _placementStats.map((stat) {
                    final placed = stat['total_placed'] as int;
                    final students = stat['total_students'] as int;
                    final percentage = ((placed / students) * 100).toStringAsFixed(1);
                    return [stat['department'], stat['total_students'], stat['total_attended'], stat['total_placed'], '$percentage%'];
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Placement_Report.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      try {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Institution Placement Report (PDF)',
          subject: 'Placement Report PDF Export',
        );
      } catch (_) {
        await Printing.sharePdf(bytes: bytes, filename: 'Placement_Report.pdf');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Placement Stats'];
    excel.setDefaultSheet(sheet.sheetName);
    
    // Add Headers
    sheet.appendRow([
      TextCellValue('Department'),
      TextCellValue('Total Students'),
      TextCellValue('Attended Drives'),
      TextCellValue('Total Placed'),
      TextCellValue('Placement %')
    ]);

    // Add Data
    for (final stat in _placementStats) {
      final placed = stat['total_placed'] as int;
      final students = stat['total_students'] as int;
      final percentage = ((placed / students) * 100).toStringAsFixed(1);

      sheet.appendRow([
        TextCellValue(stat['department'].toString()),
        IntCellValue(stat['total_students'] as int),
        IntCellValue(stat['total_attended'] as int),
        IntCellValue(stat['total_placed'] as int),
        TextCellValue('$percentage%')
      ]);
    }

    // Save File & Share
    final fileBytes = excel.save();
    if (fileBytes != null) {
      try {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/Placement_Report.xlsx';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true);

        final result = await Share.shareXFiles(
          [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          text: 'Institution Placement Report (Excel)',
          subject: 'Placement Report Excel Export',
        );

        if (mounted && result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Excel report shared successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing Excel: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NAAC / NBA Reports'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.table_chart, color: Colors.green),
                  label: const Text('Export XLSX'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _exportToPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _placementStats.length,
              itemBuilder: (context, index) {
                final stat = _placementStats[index];
                final placed = stat['total_placed'] as int;
                final students = stat['total_students'] as int;
                final percentage = ((placed / students) * 100).toStringAsFixed(1);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    title: Text(stat['department'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Total Students: $students | Attended: ${stat['total_attended']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Placed: $placed', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text('$percentage%', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
