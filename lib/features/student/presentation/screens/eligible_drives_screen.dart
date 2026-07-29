import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/student_drive_provider.dart';

class EligibleDrivesScreen extends ConsumerWidget {
  const EligibleDrivesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivesAsync = ref.watch(studentEligibleDrivesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eligible Placement Drives'),
      ),
      body: drivesAsync.when(
        data: (drives) {
          if (drives.isEmpty) {
            return const Center(
              child: Text(
                'No eligible drives found.\nMake sure you have opted in and meet the academic criteria.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: drives.length,
            itemBuilder: (context, index) {
              final drive = drives[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drive.companyName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Role: ${drive.roleTitle}'),
                      Text('CTC/Stipend: ${drive.ctcOrStipend}'),
                      Text('Deadline: ${drive.applicationDeadline.toLocal().toString().split(' ')[0]}'),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () {
                            // TODO: Navigate to drive details and application form
                          },
                          child: const Text('View & Apply'),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
