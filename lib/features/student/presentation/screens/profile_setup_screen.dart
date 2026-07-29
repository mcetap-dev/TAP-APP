import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _currentStep = 0;
  final _academicFormKey = GlobalKey<FormState>();
  
  // Academic Controllers
  final _usnController = TextEditingController();
  final _tenthPercentController = TextEditingController();
  final _twelfthPercentController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _backlogsController = TextEditingController();

  // Document URLs (Mocked for now)
  String? _resumeUrl;
  String? _photoUrl;
  String? _idProofUrl;

  // Skills
  final List<String> _skills = [];
  final _skillController = TextEditingController();

  @override
  void dispose() {
    _usnController.dispose();
    _tenthPercentController.dispose();
    _twelfthPercentController.dispose();
    _cgpaController.dispose();
    _backlogsController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (!_academicFormKey.currentState!.validate()) return;
    }
    
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
    } else {
      _submitProfile();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _submitProfile() {
    // TODO: Connect to ProfileRepository via Riverpod
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile submitted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        steps: [
          Step(
            title: const Text('Academic'),
            content: Form(
              key: _academicFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usnController,
                    decoration: const InputDecoration(labelText: 'USN / Roll Number'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tenthPercentController,
                    decoration: const InputDecoration(labelText: '10th Percentage'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _twelfthPercentController,
                    decoration: const InputDecoration(labelText: '12th / Diploma Percentage'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cgpaController,
                    decoration: const InputDecoration(labelText: 'Current CGPA'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _backlogsController,
                    decoration: const InputDecoration(labelText: 'Active Backlogs'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Documents'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement file picker and Supabase storage upload
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Resume (PDF)'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Upload Professional Photo'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.badge),
                  label: const Text('Upload ID Proof'),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Skills'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skillController,
                        decoration: const InputDecoration(
                          labelText: 'Add a Skill (e.g., Flutter, Python)',
                        ),
                        onFieldSubmitted: (v) {
                          if (v.isNotEmpty) {
                            setState(() {
                              _skills.add(v);
                              _skillController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_skillController.text.isNotEmpty) {
                          setState(() {
                            _skills.add(_skillController.text);
                            _skillController.clear();
                          });
                        }
                      },
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  children: _skills.map((skill) => Chip(
                    label: Text(skill),
                    onDeleted: () {
                      setState(() => _skills.remove(skill));
                    },
                  )).toList(),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }
}
