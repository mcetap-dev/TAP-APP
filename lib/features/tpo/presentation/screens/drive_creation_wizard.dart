import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriveCreationWizard extends ConsumerStatefulWidget {
  const DriveCreationWizard({super.key});

  @override
  ConsumerState<DriveCreationWizard> createState() => _DriveCreationWizardState();
}

class _DriveCreationWizardState extends ConsumerState<DriveCreationWizard> {
  int _currentStep = 0;
  final _basicDetailsFormKey = GlobalKey<FormState>();
  final _eligibilityFormKey = GlobalKey<FormState>();
  final _roundsFormKey = GlobalKey<FormState>();

  // Basic Details
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  final _ctcController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Eligibility
  final _cgpaCutoffController = TextEditingController();
  final _backlogsLimitController = TextEditingController();
  final List<String> _branches = [];
  final _branchController = TextEditingController();

  // Rounds
  final List<String> _rounds = [];
  final _roundController = TextEditingController();

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _ctcController.dispose();
    _descriptionController.dispose();
    _cgpaCutoffController.dispose();
    _backlogsLimitController.dispose();
    _branchController.dispose();
    _roundController.dispose();
    super.dispose();
  }

  void _onStepContinue() {
    if (_currentStep == 0 && !_basicDetailsFormKey.currentState!.validate()) return;
    if (_currentStep == 1 && !_eligibilityFormKey.currentState!.validate()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
    } else {
      _submitDrive();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _submitDrive() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Drive created successfully!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Placement Drive'),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        steps: [
          Step(
            title: const Text('Basic Details'),
            content: Form(
              key: _basicDetailsFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(labelText: 'Company Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _roleController,
                    decoration: const InputDecoration(labelText: 'Role Title'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ctcController,
                    decoration: const InputDecoration(labelText: 'CTC / Stipend'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Job Description'),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Eligibility Criteria'),
            content: Form(
              key: _eligibilityFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _cgpaCutoffController,
                    decoration: const InputDecoration(labelText: 'CGPA Cutoff'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _backlogsLimitController,
                    decoration: const InputDecoration(labelText: 'Active Backlogs Limit'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _branchController,
                          decoration: const InputDecoration(labelText: 'Add Eligible Branch (e.g., ISE, CSE)'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (_branchController.text.isNotEmpty) {
                            setState(() {
                              _branches.add(_branchController.text.toUpperCase());
                              _branchController.clear();
                            });
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: _branches.map((branch) => Chip(
                      label: Text(branch),
                      onDeleted: () {
                        setState(() => _branches.remove(branch));
                      },
                    )).toList(),
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Rounds Scheduling'),
            content: Form(
              key: _roundsFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _roundController,
                          decoration: const InputDecoration(labelText: 'Add Round (e.g., Aptitude Test, HR Interview)'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (_roundController.text.isNotEmpty) {
                            setState(() {
                              _rounds.add(_roundController.text);
                              _roundController.clear();
                            });
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._rounds.asMap().entries.map((entry) {
                    final index = entry.key;
                    final roundName = entry.value;
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(roundName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _rounds.removeAt(index));
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }
}
