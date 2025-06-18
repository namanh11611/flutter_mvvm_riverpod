import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constants/languages.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../extensions/string_extension.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/global_loading.dart';
import '../../common/ui/widgets/common_header.dart';
import '../../common/ui/widgets/common_text_form_field.dart';
import '../../common/ui/widgets/primary_button.dart';
import '../../common/ui/widgets/secondary_button.dart';
import '../model/profile.dart';
import 'view_model/profile_view_model.dart';
import 'widgets/avatar.dart';

class AccountInfoScreen extends ConsumerStatefulWidget {
  final Profile originalProfile;

  const AccountInfoScreen({
    super.key,
    required this.originalProfile,
  });

  @override
  ConsumerState createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends ConsumerState<AccountInfoScreen> {
  late final TextEditingController nameController;
  String? avatar;
  String? name;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.originalProfile.name);
    avatar = widget.originalProfile.avatar;
    name = widget.originalProfile.name;

    nameController.addListener(_updateName);
  }

  Future<void> _selectImage() async {
    final result =
        await ref.read(profileViewModelProvider.notifier).selectImage(context);
    setState(() => avatar = result);
  }

  void _updateName() {
    setState(() => name = nameController.text);
  }

  @override
  void dispose() {
    nameController.removeListener(_updateName);
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CommonHeader(header: Languages.accountInformation),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Avatar(url: avatar ?? widget.originalProfile.avatar),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: SecondaryButton(
                        text: Languages.selectAvatar,
                        onPressed: _selectImage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(Languages.email, style: AppTheme.body12),
                const SizedBox(height: 6),
                Text(
                  widget.originalProfile.email.orEmpty(),
                  style: AppTheme.body16,
                ),
                const SizedBox(height: 32),
                CommonTextFormField(
                  label: Languages.name,
                  controller: nameController,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 32,
            ),
            child: PrimaryButton(
              text: Languages.confirm,
              isEnable: avatar != widget.originalProfile.avatar ||
                  name != widget.originalProfile.name,
              onPressed: () async {
                try {
                  Global.showLoading(context);
                  await ref
                      .read(profileViewModelProvider.notifier)
                      .updateProfile(
                        avatar: avatar,
                        name: name,
                      );
                  if (context.mounted) {
                    context.pop();
                  }
                } on PostgrestException catch (error) {
                  if (context.mounted) {
                    context.showErrorSnackBar(error.message);
                  }
                } catch (error) {
                  if (context.mounted) {
                    context
                        .showErrorSnackBar(Languages.unexpectedErrorOccurred);
                  }
                } finally {
                  Global.hideLoading();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
