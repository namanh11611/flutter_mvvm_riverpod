import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../features/common/ui/widgets/common_text_form_field.dart';
import '../../../features/common/ui/widgets/primary_button.dart';
import '../../../features/profile/ui/view_models/profile_view_model.dart';
import '../../../routing/routes.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateButtonState);
    _nameController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    final isEnabled = _nameController.text.trim().isNotEmpty;
    if (isEnabled != _isButtonEnabled) {
      setState(() {
        _isButtonEnabled = isEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  // TODO: Implement image picker
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CommonTextFormField(
                label: 'Your Name',
                controller: _nameController,
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Continue',
                onPressed: () => _saveNameAndContinue(context),
                isEnable: _isButtonEnabled,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveNameAndContinue(BuildContext context) async {
    try {
      await ref.read(profileViewModelProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
          );
      if (context.mounted) {
        context.pushReplacement(Routes.home);
      }
    } catch (error) {
      if (context.mounted) {
        context.showErrorSnackBar('Failed to save profile');
      }
    }
  }
}
