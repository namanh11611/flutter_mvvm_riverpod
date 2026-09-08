import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validator.dart';
import '../../common/ui/widgets/common_header.dart';
import '../../common/ui/widgets/primary_button.dart';
import 'view_model/emergency_contacts_view_model.dart';

class AddEmergencyContactScreen extends ConsumerStatefulWidget {
  const AddEmergencyContactScreen({super.key});

  @override
  ConsumerState<AddEmergencyContactScreen> createState() =>
      _AddEmergencyContactScreenState();
}

class _AddEmergencyContactScreenState
    extends ConsumerState<AddEmergencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emergencyContactsViewModelProvider);

    ref.listen(
        emergencyContactsViewModelProvider.select((value) => value.error),
        (previous, next) {
      if (next == null || next == previous) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      ref.read(emergencyContactsViewModelProvider.notifier).clearError();
    });

    return Scaffold(
      body: Column(
        children: [
          const CommonHeader(header: 'Add emergency contact'),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  Text(
                    'Enter the details of someone you trust. All fields are required.',
                    style: AppTheme.body14,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Name is required.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '+60 12-345 6789',
                    ),
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required.';
                      }
                      return isValidEmail(value.trim())
                          ? null
                          : 'Enter a valid email address.';
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: PrimaryButton(
              text: state.isSaving ? 'Saving…' : 'Save contact',
              isEnable: !state.isSaving,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    final normalised = value.replaceAll(RegExp(r'[^0-9]'), '');
    return normalised.length >= 7 && normalised.length <= 15
        ? null
        : 'Enter a valid phone number with 7 to 15 digits.';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final saved =
        await ref.read(emergencyContactsViewModelProvider.notifier).addContact(
              name: _nameController.text,
              phoneNumber: _phoneController.text,
              email: _emailController.text,
            );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency contact added.')),
      );
      context.pop();
    }
  }
}
