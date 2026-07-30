import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConsentFormScreen extends ConsumerStatefulWidget {
  const ConsentFormScreen({super.key});

  @override
  ConsumerState<ConsentFormScreen> createState() => _ConsentFormScreenState();
}

class _ConsentFormScreenState extends ConsumerState<ConsentFormScreen> {
  bool _isOptedIn = true;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitConsent() {
    // TODO: Connect to repository to update consent_status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isOptedIn ? 'Opted In Successfully' : 'Opted Out Successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Consent Form'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Do you wish to participate in the upcoming placement drives?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            RadioListTile<bool>(
              title: const Text('Yes, I want to participate (Opt-In)'),
              value: true,
              groupValue: _isOptedIn,
              onChanged: (value) {
                setState(() => _isOptedIn = value!);
              },
            ),
            RadioListTile<bool>(
              title: const Text('No, I do not want to participate (Opt-Out)'),
              value: false,
              groupValue: _isOptedIn,
              onChanged: (value) {
                setState(() => _isOptedIn = value!);
              },
            ),
            const SizedBox(height: 24),
            if (!_isOptedIn)
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Opting Out',
                  border: OutlineInputBorder(),
                  helperText: 'Required if opting out.',
                ),
                maxLines: 3,
              ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _submitConsent,
              child: const Text('Submit Consent'),
            ),
          ],
        ),
      ),
    );
  }
}
