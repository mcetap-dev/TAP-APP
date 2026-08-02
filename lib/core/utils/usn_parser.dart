import 'package:flutter/foundation.dart';
import '../../../features/admin/domain/entities/department.dart';

/// Utility for parsing VTU-format University Seat Numbers (USNs).
///
/// Standard MCE Hassan USN format:
///   `4 M C 23 IS 021`
///    ↑ ↑↑ ↑↑ ↑↑ ↑↑↑
///    | ||  ||  ||  Roll number (3 digits)
///    | ||  ||  Branch code (2–3 chars, e.g. IS, CS, CV, EC)
///    | ||  Year of joining (2 digits)
///    | College code (2 chars)
///    Digit (1 char)
///
/// Example: `4MC23IS021` → branch code = `IS`
class UsnParser {
  UsnParser._();

  /// Regex to capture the branch code from a VTU USN.
  /// Group 1 = branch code (2–3 uppercase letters).
  static final _usnRegex = RegExp(
    r'^[0-9][A-Za-z0-9]{2}[0-9]{2}([A-Za-z]{2,3})[0-9]+$',
    caseSensitive: false,
  );

  /// Extracts the branch code from [usn].
  /// Returns `null` if the USN does not match the expected format.
  ///
  /// Example:
  /// ```dart
  /// UsnParser.extractBranchCode('4MC23IS021'); // returns 'IS'
  /// UsnParser.extractBranchCode('4MC23CS010'); // returns 'CS'
  /// UsnParser.extractBranchCode('INVALID');    // returns null
  /// ```
  static String? extractBranchCode(String usn) {
    final match = _usnRegex.firstMatch(usn.trim());
    final code = match?.group(1)?.toUpperCase();
    debugPrint('[UsnParser] extractBranchCode("$usn") → "$code"');
    return code;
  }

  /// Detects the [Department] whose [Department.branchCode] matches
  /// the branch code extracted from [usn].
  ///
  /// Returns `null` if no match is found or the USN format is invalid.
  static Department? detectDepartment(
    String usn,
    List<Department> departments,
  ) {
    final code = extractBranchCode(usn);
    if (code == null) {
      debugPrint('[UsnParser] No branch code extracted from "$usn"');
      return null;
    }
    debugPrint('[UsnParser] Searching ${departments.length} departments for code "$code"');
    for (final d in departments) {
      debugPrint('[UsnParser]   checking: "${d.branchCode}" == "$code" → ${d.branchCode.toUpperCase() == code}');
    }
    try {
      final match = departments.firstWhere(
        (d) => d.branchCode.toUpperCase() == code,
      );
      debugPrint('[UsnParser] Match found: ${match.name} (${match.branchCode})');
      return match;
    } catch (_) {
      debugPrint('[UsnParser] No department found with branch code "$code"');
      return null;
    }
  }
}
