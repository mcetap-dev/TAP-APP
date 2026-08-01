import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentAttendanceRemoteDataSource {
  final SupabaseClient _client;

  StudentAttendanceRemoteDataSource(this._client);

  /// Validates QR payload and inserts attendance record.
  Future<Map<String, dynamic>> markAttendance({
    required String qrPayload,
    required String studentId,
  }) async {
    // 1. Decode and validate QR payload
    final Map<String, dynamic> qrData;
    try {
      qrData = jsonDecode(qrPayload) as Map<String, dynamic>;
    } catch (_) {
      throw AttendanceException('Invalid QR Code', 'QR code data is malformed.');
    }

    if (qrData['type'] != 'tap_drive_attendance') {
      throw AttendanceException('Invalid QR Code', 'This QR code is not for attendance.');
    }

    final driveId = qrData['drive_id'] as String?;
    if (driveId == null || driveId.isEmpty) {
      throw AttendanceException('Invalid QR Code', 'QR code is missing drive information.');
    }

    // 2. Verify drive exists
    final driveResponse = await _client
        .from('drives')
        .select('id, role, company_id, company:companies(name)')
        .eq('id', driveId)
        .maybeSingle();

    if (driveResponse == null) {
      throw AttendanceException('Drive Not Found', 'The drive associated with this QR code no longer exists.');
    }

    // 3. Check duplicate attendance
    final existing = await _client
        .from('drive_attendance')
        .select('id')
        .eq('drive_id', driveId)
        .eq('student_id', studentId)
        .maybeSingle();

    if (existing != null) {
      throw AttendanceException('Already Marked', 'You have already marked attendance for this drive.');
    }

    // 4. Get student profile
    final profile = await _client
        .from('profiles')
        .select('name, usn, department')
        .eq('id', studentId)
        .maybeSingle();

    if (profile == null) {
      throw AttendanceException('Profile Error', 'Could not find your student profile.');
    }

    // 5. Insert attendance record
    final now = DateTime.now().toIso8601String();
    final inserted = await _client
        .from('drive_attendance')
        .insert({
          'drive_id': driveId,
          'student_id': studentId,
          'scanned_at': now,
          'status': 'present',
        })
        .select('id')
        .single();

    // 6. Build attendance result with drive + student info
    final companyName = driveResponse['company'] is Map
        ? (driveResponse['company'] as Map)['name'] as String? ?? ''
        : '';

    return {
      'id': inserted['id'],
      'drive_id': driveId,
      'student_id': studentId,
      'student_name': profile['name'] as String? ?? '',
      'usn': profile['usn'] as String? ?? '',
      'department': profile['department'] as String? ?? '',
      'company_name': companyName,
      'drive_role': driveResponse['role'] as String? ?? '',
      'scanned_at': now,
      'status': 'present',
    };
  }

  /// Checks if attendance already exists for this student + drive.
  Future<bool> hasAttendance({
    required String studentId,
    required String driveId,
  }) async {
    final existing = await _client
        .from('drive_attendance')
        .select('id')
        .eq('drive_id', driveId)
        .eq('student_id', studentId)
        .maybeSingle();
    return existing != null;
  }
}

class AttendanceException implements Exception {
  final String title;
  final String message;
  const AttendanceException(this.title, this.message);

  @override
  String toString() => '$title: $message';
}
