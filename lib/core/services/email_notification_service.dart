import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for global access to EmailNotificationService
final emailNotificationServiceProvider = Provider<EmailNotificationService>((ref) {
  return EmailNotificationService(Supabase.instance.client);
});

/// Production-ready Email Notification Service
/// Handles non-blocking dispatches to the `send-email` Supabase Edge Function.
class EmailNotificationService {
  final SupabaseClient _supabase;

  EmailNotificationService(this._supabase);

  /// Helper method for invoking Edge Function asynchronously without blocking UI.
  Future<void> _invokeEmailFunction({
    required String emailType,
    required String recipient,
    String? subject,
    required Map<String, dynamic> data,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    // Fire-and-forget / non-blocking async execution
    Future.microtask(() async {
      try {
        final response = await _supabase.functions.invoke(
          'send-email',
          body: {
            'emailType': emailType,
            'recipient': recipient,
            'subject': subject,
            'data': data,
            'createdBy': currentUserId,
          },
        );

        if (response.status >= 400) {
          dev.log(
            '[EmailNotificationService] Failed ($emailType) to $recipient: ${response.data}',
            name: 'EmailNotificationService',
          );
        } else {
          dev.log(
            '[EmailNotificationService] Dispatched ($emailType) successfully to $recipient',
            name: 'EmailNotificationService',
          );
        }
      } catch (e, st) {
        dev.log(
          '[EmailNotificationService] Edge function invocation exception ($emailType) to $recipient: $e',
          name: 'EmailNotificationService',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Welcome Email
  // ───────────────────────────────────────────────────────────────────────────
  void sendWelcomeEmail({
    required String recipientEmail,
    required String studentName,
    required String role,
    required String department,
  }) {
    _invokeEmailFunction(
      emailType: 'welcome',
      recipient: recipientEmail,
      subject: 'Welcome to Placement Connect — $studentName',
      data: {
        'studentName': studentName,
        'role': role,
        'department': department,
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Faculty Coordinator Appointment Email
  // ───────────────────────────────────────────────────────────────────────────
  void sendFacultyAppointmentEmail({
    required String recipientEmail,
    required String facultyName,
    required String department,
    String? appointmentDate,
  }) {
    _invokeEmailFunction(
      emailType: 'faculty_appointment',
      recipient: recipientEmail,
      subject: 'Appointment as Faculty Coordinator — $department',
      data: {
        'facultyName': facultyName,
        'department': department,
        'appointmentDate': appointmentDate ?? DateTime.now().toString().split(' ')[0],
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. New Placement Drive Email
  // ───────────────────────────────────────────────────────────────────────────
  void sendDrivePublishedEmail({
    required String recipientEmail,
    required String companyName,
    required String roleTitle,
    required String package,
    required String registrationDeadline,
    required String driveDate,
  }) {
    _invokeEmailFunction(
      emailType: 'drive_published',
      recipient: recipientEmail,
      subject: 'New Placement Drive Announced: $companyName ($roleTitle)',
      data: {
        'companyName': companyName,
        'roleTitle': roleTitle,
        'package': package,
        'registrationDeadline': registrationDeadline,
        'driveDate': driveDate,
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. Application Submitted Email
  // ───────────────────────────────────────────────────────────────────────────
  void sendApplicationSubmittedEmail({
    required String recipientEmail,
    required String studentName,
    required String companyName,
    required String roleTitle,
    String? applicationDate,
    String? status,
  }) {
    _invokeEmailFunction(
      emailType: 'application_submitted',
      recipient: recipientEmail,
      subject: 'Application Confirmed: $companyName',
      data: {
        'studentName': studentName,
        'companyName': companyName,
        'roleTitle': roleTitle,
        'applicationDate': applicationDate ?? DateTime.now().toString().split(' ')[0],
        'status': status ?? 'Applied',
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. Attendance Confirmation Email
  // ───────────────────────────────────────────────────────────────────────────
  void sendAttendanceConfirmationEmail({
    required String recipientEmail,
    required String companyName,
    required String date,
    required String time,
    String? attendanceStatus,
  }) {
    _invokeEmailFunction(
      emailType: 'attendance_marked',
      recipient: recipientEmail,
      subject: 'Attendance Confirmed: $companyName Drive',
      data: {
        'companyName': companyName,
        'date': date,
        'time': time,
        'attendanceStatus': attendanceStatus ?? 'Present',
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 6. Qualified For Next Round Email
  // ───────────────────────────────────────────────────────────────────────────
  void sendRoundQualifiedEmail({
    required String recipientEmail,
    required String studentName,
    required String companyName,
    required String qualifiedRound,
    required String nextRoundName,
    String? interviewDate,
    String? venue,
    String? remarks,
  }) {
    _invokeEmailFunction(
      emailType: 'round_qualified',
      recipient: recipientEmail,
      subject: 'Congratulations! Qualified for $nextRoundName — $companyName',
      data: {
        'studentName': studentName,
        'companyName': companyName,
        'qualifiedRound': qualifiedRound,
        'nextRoundName': nextRoundName,
        'interviewDate': interviewDate ?? 'TBA',
        'venue': venue ?? 'TBA',
        'remarks': remarks ?? '',
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 7. Round Rejected Email
  // ───────────────────────────────────────────────────────────────────────────
  void sendRoundRejectedEmail({
    required String recipientEmail,
    required String studentName,
    required String companyName,
    required String rejectedRound,
    String? remarks,
  }) {
    _invokeEmailFunction(
      emailType: 'round_rejected',
      recipient: recipientEmail,
      subject: 'Drive Status Update: $companyName',
      data: {
        'studentName': studentName,
        'companyName': companyName,
        'rejectedRound': rejectedRound,
        'remarks': remarks ?? '',
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 8. Offer Released Email
  // ───────────────────────────────────────────────────────────────────────────
  void sendOfferReleasedEmail({
    required String recipientEmail,
    required String studentName,
    required String companyName,
    required String roleTitle,
    required String package,
    String? joiningDate,
  }) {
    _invokeEmailFunction(
      emailType: 'offer_released',
      recipient: recipientEmail,
      subject: 'JOB OFFER: Selection Confirmed at $companyName!',
      data: {
        'studentName': studentName,
        'companyName': companyName,
        'roleTitle': roleTitle,
        'package': package,
        'joiningDate': joiningDate ?? 'As per offer letter',
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 9. Drive Cancelled / Rescheduled Email
  // ───────────────────────────────────────────────────────────────────────────
  void sendDriveCancelledEmail({
    required String recipientEmail,
    required String companyName,
    required String reason,
    String? updatedDate,
  }) {
    _invokeEmailFunction(
      emailType: 'drive_cancelled',
      recipient: recipientEmail,
      subject: 'URGENT: Placement Drive Update — $companyName',
      data: {
        'companyName': companyName,
        'reason': reason,
        'updatedDate': updatedDate ?? 'To be announced',
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 10. Reminder Email
  // ───────────────────────────────────────────────────────────────────────────
  void sendReminderEmail({
    required String recipientEmail,
    required String studentName,
    required String reminderTitle,
    required String message,
    String? deadline,
  }) {
    _invokeEmailFunction(
      emailType: 'reminder',
      recipient: recipientEmail,
      subject: 'Placement Action Required: $reminderTitle',
      data: {
        'studentName': studentName,
        'reminderTitle': reminderTitle,
        'message': message,
        'deadline': deadline ?? '',
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 11. General Notification Email
  // ───────────────────────────────────────────────────────────────────────────
  void sendGeneralNotification({
    required String recipientEmail,
    required String subject,
    required String message,
  }) {
    _invokeEmailFunction(
      emailType: 'general',
      recipient: recipientEmail,
      subject: subject,
      data: {
        'message': message,
      },
    );
  }
}
