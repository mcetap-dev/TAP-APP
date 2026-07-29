import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentApprovalQueueScreen extends ConsumerStatefulWidget {
  const StudentApprovalQueueScreen({super.key});

  @override
  ConsumerState<StudentApprovalQueueScreen> createState() => _StudentApprovalQueueScreenState();
}

class _StudentApprovalQueueScreenState extends ConsumerState<StudentApprovalQueueScreen> {
  // Mock data for now until we connect the FacultyRepository
  final List<Map<String, dynamic>> _pendingStudents = [
    {
      'id': '1',
      'name': 'John Doe',
      'usn': '4MC23IS001',
      'department': 'Information Science',
      'cgpa': 8.5
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'usn': '4MC23IS002',
      'department': 'Information Science',
      'cgpa': 9.2
    }
  ];

  void _approveStudent(String id) {
    setState(() {
      _pendingStudents.removeWhere((student) => student['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student approved successfully.')),
    );
  }

  void _rejectStudent(String id) {
    showDialog(
      context: context,
      builder: (context) {
        final reasonCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Student'),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(hintText: 'Enter rejection reason (Required)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (reasonCtrl.text.isNotEmpty) {
                  setState(() {
                    _pendingStudents.removeWhere((student) => student['id'] == id);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student rejected.')),
                  );
                }
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Approval Queue'),
      ),
      body: _pendingStudents.isEmpty
          ? const Center(child: Text('No students pending approval.'))
          : ListView.builder(
              itemCount: _pendingStudents.length,
              itemBuilder: (context, index) {
                final student = _pendingStudents[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(student['name']),
                  subtitle: Text('${student['usn']} • CGPA: ${student['cgpa']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectStudent(student['id']),
                        tooltip: 'Reject',
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _approveStudent(student['id']),
                        tooltip: 'Approve',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
