import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/routing/routes.dart';
import '../model/user_account_model.dart';
import 'view_model/user_account_view_model.dart';

const _purple = Color(0xFF7C3AED);
const _ink = Color(0xFF281950);
const _muted = Color(0xFF686082);
const _border = Color(0xFFD5CFEF);

class PersonalInformationSetupScreen extends ConsumerStatefulWidget {
  const PersonalInformationSetupScreen({super.key});

  @override
  ConsumerState<PersonalInformationSetupScreen> createState() =>
      _PersonalInformationSetupScreenState();
}

class _PersonalInformationSetupScreenState
    extends ConsumerState<PersonalInformationSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nationality = TextEditingController();
  final _bio = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;
  String? _photo;
  bool _initialized = false;
  bool _attemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_requiredFieldsChanged);
  }

  void _requiredFieldsChanged() {
    if (mounted) setState(() {});
  }

  bool get _canContinue =>
      _name.text.trim().isNotEmpty && _dateOfBirth != null;

  @override
  void dispose() {
    _name.removeListener(_requiredFieldsChanged);
    _name.dispose();
    _nationality.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _initialize(UserAccount user) {
    if (_initialized) return;
    _initialized = true;
    _name.text = user.username;
    _nationality.text = user.nationality ?? '';
    _bio.text = user.bio;
    _dateOfBirth = user.dateOfBirth;
    _gender = user.gender;
    _photo = user.profilePhoto;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (value != null && mounted) setState(() => _dateOfBirth = value);
  }

  Future<void> _selectPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null && mounted) setState(() => _photo = image.path);
  }

  Future<void> _continue() async {
    setState(() => _attemptedSubmit = true);
    if (!(_formKey.currentState?.validate() ?? false) || _dateOfBirth == null) {
      return;
    }
    final saved = await ref
        .read(userAccountViewModelProvider.notifier)
        .updateProfile(
          UserAccountProfileUpdate(
            username: _name.text.trim(),
            dateOfBirth: _dateOfBirth,
            gender: _gender,
            nationality: _nationality.text,
            bio: _bio.text,
            profilePhoto: _photo,
          ),
        );
    if (saved && mounted) context.go(Routes.main);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userAccountViewModelProvider, (previous, next) {
      if (next.error == null || next.error == previous?.error) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next.error!)));
    });
    final state = ref.watch(userAccountViewModelProvider);
    final user = state.user;
    if (user != null) _initialize(user);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text('Personal Information'),
        ),
        body: SafeArea(
          top: false,
          child: user == null
              ? _LoadView(
                  loading: state.isLoading,
                  error: state.error,
                  retry: () =>
                      ref.read(userAccountViewModelProvider.notifier).refresh(),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                    children: [
                      const Text(
                        'Tell us about yourself',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Preferred name and date of birth are required. Everything else can be added later.',
                        style: TextStyle(color: _muted, height: 1.45),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(56),
                          onTap: state.isLoading ? null : _selectPhoto,
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: const Color(0xFFF0ECFA),
                            backgroundImage: _photoProvider(_photo),
                            child: _photo == null
                                ? const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: _purple,
                                    size: 30,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _FieldLabel('Preferred Name *'),
                      TextFormField(
                        controller: _name,
                        decoration: _input('What should we call you?'),
                        validator: (value) => (value?.trim().isEmpty ?? true)
                            ? 'Preferred name is required'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel('Date of Birth *'),
                      InkWell(
                        onTap: state.isLoading ? null : _selectDate,
                        child: InputDecorator(
                          decoration: _input('Select your date of birth')
                              .copyWith(
                                errorText:
                                    _dateOfBirth == null && _attemptedSubmit
                                    ? 'Date of birth is required'
                                    : null,
                              ),
                          child: Text(
                            _dateOfBirth == null
                                ? 'Select your date of birth'
                                : _date(_dateOfBirth!),
                            style: TextStyle(
                              color: _dateOfBirth == null ? _muted : _ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel('Gender'),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: _input('Select gender'),
                        items:
                            const [
                                  'Female',
                                  'Male',
                                  'Other',
                                  'Prefer not to say',
                                ]
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                        onChanged: state.isLoading
                            ? null
                            : (value) => setState(() => _gender = value),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel('Nationality'),
                      TextFormField(
                        controller: _nationality,
                        decoration: _input('Enter nationality'),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel('Bio'),
                      TextFormField(
                        controller: _bio,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: _input(
                          'Tell other travellers about yourself',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: state.isLoading || !_canContinue
                              ? null
                              : _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: state.isLoading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _LoadView extends StatelessWidget {
  const _LoadView({
    required this.loading,
    required this.error,
    required this.retry,
  });
  final bool loading;
  final String? error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: loading
        ? const CircularProgressIndicator(color: _purple)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error ?? 'Unable to load your profile.'),
              const SizedBox(height: 16),
              FilledButton(onPressed: retry, child: const Text('Retry')),
            ],
          ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
    ),
  );
}

InputDecoration _input(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: _muted),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: _border),
  ),
);

ImageProvider<Object>? _photoProvider(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
