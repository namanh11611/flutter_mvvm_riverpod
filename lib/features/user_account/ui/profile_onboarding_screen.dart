import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../repository/user_account_repository.dart';
import 'view_model/user_account_view_model.dart';

class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState
    extends ConsumerState<ProfileOnboardingScreen> {
  static const _stepCount = 6;
  static const _countries = <String>[
    'Australia',
    'Bangladesh',
    'Brunei',
    'Cambodia',
    'Canada',
    'China',
    'France',
    'Germany',
    'India',
    'Indonesia',
    'Italy',
    'Japan',
    'Malaysia',
    'Myanmar',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Pakistan',
    'Philippines',
    'Singapore',
    'South Korea',
    'Spain',
    'Sri Lanka',
    'Taiwan',
    'Thailand',
    'United Kingdom',
    'United States',
    'Vietnam',
  ];
  static const _genders = <String>[
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];

  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  int _step = 0;
  DateTime? _dateOfBirth;
  String? _country;
  String? _gender;
  bool _isSaving = false;
  String? _nameError;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _step > 0 && !_isSaving) _previousStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.brandBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        onPressed: _isSaving ? null : _previousStep,
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / _stepCount,
                          minHeight: 7,
                          backgroundColor: AppColors.brandBorder,
                          color: AppColors.brandSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_step + 1}/$_stepCount',
                      style: const TextStyle(
                        color: AppColors.brandTextMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _QuestionPage(
                        icon: Icons.person_outline_rounded,
                        title: 'What should we call you?',
                        description:
                            'This is the name other travellers will see on your profile.',
                        child: TextField(
                          controller: _nameController,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          maxLength: 40,
                          onChanged: (_) {
                            if (_nameError != null) {
                              setState(() => _nameError = null);
                            }
                          },
                          onSubmitted: (_) => _nextStep(),
                          decoration: _decoration(
                            'Display name',
                            errorText: _nameError,
                          ),
                        ),
                      ),
                      _QuestionPage(
                        icon: Icons.cake_outlined,
                        title: 'When is your birthday?',
                        description:
                            'Your age helps us suggest suitable travel companions. Your exact birth date stays private.',
                        child: InkWell(
                          onTap: _isSaving ? null : _pickDateOfBirth,
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: _decoration('Date of birth'),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _dateOfBirth == null
                                        ? 'Select your date of birth'
                                        : _formatDate(_dateOfBirth!),
                                    style: TextStyle(
                                      color: _dateOfBirth == null
                                          ? AppColors.brandTextMuted
                                          : AppColors.brandPrimary,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.calendar_month_outlined),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _QuestionPage(
                        icon: Icons.public_rounded,
                        title: 'Where are you from?',
                        description:
                            'Share your home country to help your profile feel more personal.',
                        child: DropdownButtonFormField<String>(
                          initialValue: _country,
                          isExpanded: true,
                          decoration: _decoration('Country'),
                          items: _countries
                              .map((country) => DropdownMenuItem(
                                    value: country,
                                    child: Text(country),
                                  ))
                              .toList(),
                          onChanged: _isSaving
                              ? null
                              : (value) => setState(() => _country = value),
                        ),
                      ),
                      _QuestionPage(
                        icon: Icons.diversity_1_outlined,
                        title: 'How do you describe yourself?',
                        description:
                            'Choose the option you are comfortable sharing. You can change it later.',
                        child: Column(
                          children: _genders
                              .map((gender) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: RadioListTile<String>(
                                      value: gender,
                                      groupValue: _gender,
                                      onChanged: _isSaving
                                          ? null
                                          : (value) => setState(
                                                () => _gender = value,
                                              ),
                                      title: Text(gender),
                                      activeColor: AppColors.brandSurface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: const BorderSide(
                                          color: AppColors.brandBorder,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      _QuestionPage(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Tell travellers a little about you',
                        description:
                            'A short introduction makes it easier to find people you will enjoy travelling with.',
                        child: TextField(
                          controller: _bioController,
                          minLines: 4,
                          maxLines: 6,
                          maxLength: 240,
                          decoration: _decoration(
                            'For example: I enjoy food trips and hiking...',
                          ),
                        ),
                      ),
                      const _VerificationIntroduction(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_step == _stepCount - 1) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => _finish(startVerification: true),
                      icon: const Icon(Icons.verified_user_outlined),
                      label: Text(_isSaving ? 'Saving...' : 'Verify now'),
                      style: _primaryButtonStyle,
                    ),
                  ),
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => _finish(startVerification: false),
                    child: const Text('Skip for now'),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _nextStep,
                      style: _primaryButtonStyle,
                      child: const Text('Continue'),
                    ),
                  ),
                  if (_step > 0)
                    TextButton(
                      onPressed: _isSaving ? null : _nextStep,
                      child: const Text('Skip for now'),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle get _primaryButtonStyle => FilledButton.styleFrom(
        backgroundColor: AppColors.brandSurface,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      );

  void _nextStep() {
    if (_step == 0 && _nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Please enter the name shown on your profile');
      return;
    }
    if (_step >= _stepCount - 1) return;
    setState(() => _step++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _previousStep() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your date of birth',
    );
    if (selected != null && mounted) {
      setState(() => _dateOfBirth = selected);
    }
  }

  Future<void> _finish({required bool startVerification}) async {
    setState(() => _isSaving = true);
    try {
      await const UserAccountRepository().completeProfileOnboarding(
        displayName: _nameController.text,
        dateOfBirth: _dateOfBirth,
        nationality: _country,
        gender: _gender,
        bio: _bioController.text,
      );
      ref.invalidate(userAccountViewModelProvider);
      if (!mounted) return;
      context.go(
        startVerification
            ? '${Routes.identityVerification}?onboarding=true'
            : Routes.main,
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is UserAccountLoadException
          ? error.message
          : 'Unable to save your profile. Please try again.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      setState(() => _isSaving = false);
    }
  }
}

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIcon(icon),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.brandPrimary,
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.brandTextMuted,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 34),
            child,
          ],
        ),
      );
}

class _VerificationIntroduction extends StatelessWidget {
  const _VerificationIntroduction();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        child: Column(
          children: [
            _StepIcon(Icons.verified_user_outlined),
            SizedBox(height: 24),
            Text(
              'Build trust with verification',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.brandPrimary,
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'A verified profile helps other travellers feel confident connecting with you. Verification confirms your identity and adds a trusted badge to your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.brandTextMuted,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            SizedBox(height: 30),
            _Benefit(
              icon: Icons.shield_outlined,
              text: 'Help keep the GoBuddy community safer',
            ),
            _Benefit(
              icon: Icons.handshake_outlined,
              text: 'Give potential travel partners more confidence',
            ),
            _Benefit(
              icon: Icons.workspace_premium_outlined,
              text: 'Receive a verification badge on your profile',
            ),
          ],
        ),
      );
}

class _StepIcon extends StatelessWidget {
  const _StepIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.brandBorder.withValues(alpha: .35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.brandSurface, size: 36),
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brandSurface),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.brandPrimary,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

InputDecoration _decoration(String hint, {String? errorText}) =>
    InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.brandSurface,
          width: 1.5,
        ),
      ),
    );

String _formatDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
