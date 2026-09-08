import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../model/user_account_model.dart';

const _ink = Color(0xFF242329);
const _violet = Color(0xFF7C3AED);
const _muted = Color(0xFF8D8D92);
const _placeholder = Color(0xFFC3C3C7);
const _divider = Color(0xFFF0F0F2);
const _surface = Colors.white;

class EditProfileView extends StatefulWidget {
  const EditProfileView({
    super.key,
    required this.user,
    required this.isSaving,
    required this.onBack,
    required this.onSave,
    required this.onSelectImage,
    required this.onDeleteImage,
  });

  final UserAccount user;
  final bool isSaving;
  final VoidCallback onBack;
  final ValueChanged<UserAccountProfileUpdate> onSave;
  final Future<String?> Function(ImageSource source) onSelectImage;
  final Future<bool> Function() onDeleteImage;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late String _name;
  late String _bio;
  String? _gender;
  String? _nationality;
  String? _profilePhoto;

  @override
  void initState() {
    super.initState();
    _name = widget.user.username;
    _bio = widget.user.bio;
    _gender = widget.user.gender;
    _nationality = widget.user.nationality;
    _profilePhoto = widget.user.profilePhoto;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EditHeader(
          isSaving: widget.isSaving,
          onBack: widget.onBack,
          onSave: _save,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            children: [
              Center(
                child: _ProfileAvatar(
                  imagePath: _profilePhoto,
                  enabled: !widget.isSaving,
                  onTap: _selectPhoto,
                ),
              ),
              const SizedBox(height: 40),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    label: 'Name',
                    value: _name,
                    placeholder: 'Add name',
                    onTap: widget.isSaving ? null : _editName,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    label: 'Bio',
                    value: _bio,
                    placeholder: 'Add bio',
                    maxValueLines: 2,
                    onTap: widget.isSaving ? null : _editBio,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    label: 'Gender',
                    value: _gender,
                    placeholder: 'Select gender',
                    onTap: widget.isSaving ? null : _editGender,
                  ),
                  _SettingsRow(
                    label: 'Nationality',
                    value: _nationality,
                    placeholder: 'Add nationality',
                    onTap: widget.isSaving ? null : _editNationality,
                  ),
                  _SettingsRow(
                    label: 'Birthday',
                    value: widget.user.dateOfBirth == null
                        ? null
                        : _formatDate(widget.user.dateOfBirth!),
                    placeholder: widget.user.isVerified
                        ? 'Birthday unavailable'
                        : 'Complete verification',
                    locked: true,
                  ),
                ],
              ),
              if (widget.isSaving) ...[
                const SizedBox(height: 24),
                const Center(
                  child: CircularProgressIndicator(color: _violet),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectPhoto() async {
    final action = await showModalBottomSheet<_ProfilePhotoAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Update profile photo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                subtitle: const Text('Use your device camera'),
                onTap: () => Navigator.pop(
                  sheetContext,
                  _ProfilePhotoAction.camera,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                subtitle: const Text('Upload an existing photo'),
                onTap: () => Navigator.pop(
                  sheetContext,
                  _ProfilePhotoAction.gallery,
                ),
              ),
              if (_profilePhoto != null && _profilePhoto!.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Delete profile image'),
                  subtitle: const Text('Use the default profile image'),
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _ProfilePhotoAction.delete,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;

    if (action == _ProfilePhotoAction.delete) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Delete profile image?'),
              content: const Text(
                'Your current profile image will be replaced with the default image.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;

      final deleted = await widget.onDeleteImage();
      if (deleted && mounted) setState(() => _profilePhoto = null);
      return;
    }

    final source = action == _ProfilePhotoAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    final path = await widget.onSelectImage(source);
    if (path != null && mounted) setState(() => _profilePhoto = path);
  }

  Future<void> _editName() async {
    final value = await _showTextEditor(
      title: 'Name',
      initialValue: _name,
      hintText: 'Enter your display name',
      validator: (text) => text.trim().isEmpty ? 'Name is required' : null,
    );
    if (value != null && mounted) setState(() => _name = value.trim());
  }

  Future<void> _editBio() async {
    final value = await _showTextEditor(
      title: 'Bio',
      initialValue: _bio,
      hintText: 'Tell other travellers about yourself',
      maxLines: 6,
      maxLength: 500,
    );
    if (value != null && mounted) setState(() => _bio = value.trim());
  }

  Future<void> _editNationality() async {
    final value = await _showTextEditor(
      title: 'Nationality',
      initialValue: _nationality ?? '',
      hintText: 'Enter your nationality',
      maxLength: 80,
    );
    if (value != null && mounted) {
      setState(() => _nationality = value.trim());
    }
  }

  Future<void> _editGender() async {
    const values = ['Female', 'Male', 'Other', 'Prefer not to say'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select gender',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              for (final value in values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(value),
                  trailing: _gender == value
                      ? const Icon(Icons.check_rounded, color: _violet)
                      : null,
                  onTap: () => Navigator.pop(context, value),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _gender = selected);
  }

  Future<String?> _showTextEditor({
    required String title,
    required String initialValue,
    required String hintText,
    int maxLines = 1,
    int? maxLength,
    String? Function(String value)? validator,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _TextEditorDialog(
        title: title,
        initialValue: initialValue,
        hintText: hintText,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
      ),
    );
  }

  void _save() {
    if (_name.trim().isEmpty || widget.isSaving) return;
    widget.onSave(
      UserAccountProfileUpdate(
        profilePhoto: _profilePhoto,
        username: _name.trim(),
        gender: _gender,
        nationality: _nationality,
        bio: _bio.trim(),
      ),
    );
  }
}

class _TextEditorDialog extends StatefulWidget {
  const _TextEditorDialog({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.maxLines,
    required this.maxLength,
    required this.validator,
  });

  final String title;
  final String initialValue;
  final String hintText;
  final int maxLines;
  final int? maxLength;
  final String? Function(String value)? validator;

  @override
  State<_TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<_TextEditorDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(widget.title),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: _error,
            filled: true,
            fillColor: const Color(0xFFF5F5F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final message = widget.validator?.call(_controller.text);
              if (message != null) {
                setState(() => _error = message);
                return;
              }
              Navigator.of(context).pop(_controller.text);
            },
            child: const Text('Done'),
          ),
        ],
      );
}

class _EditHeader extends StatelessWidget {
  const _EditHeader({
    required this.isSaving,
    required this.onBack,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 66,
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: isSaving ? null : onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 22,
                  ),
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'Edit profile',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 88,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isSaving ? null : onSave,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imagePath,
    required this.enabled,
    required this.onTap,
  });

  final String? imagePath;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Semantics(
          button: true,
          label: 'Change profile photo',
          child: SizedBox.square(
            dimension: 122,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 58,
                  backgroundColor: const Color(0xFFE8E8EB),
                  backgroundImage: _imageProvider(imagePath),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3E43),
                      shape: BoxShape.circle,
                      border: Border.all(color: _surface, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1)
                const Divider(
                  height: 1,
                  indent: 24,
                  endIndent: 24,
                  color: _divider,
                ),
            ],
          ],
        ),
      );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
    required this.placeholder,
    this.onTap,
    this.locked = false,
    this.maxValueLines = 1,
    this.trailingIcon,
    this.trailingColor,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;
  final bool locked;
  final int maxValueLines;
  final IconData? trailingIcon;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.trim();
    final hasValue = displayValue != null && displayValue.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            SizedBox(
              width: 128,
              child: Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasValue ? displayValue : placeholder,
                maxLines: maxValueLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasValue ? _ink : _placeholder,
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              trailingIcon ??
                  (locked
                      ? Icons.lock_outline_rounded
                      : Icons.chevron_right_rounded),
              color: trailingColor ?? _placeholder,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

ImageProvider<Object> _imageProvider(String? path) {
  final resolved = path == null || path.isEmpty
      ? 'assets/images/defaultProfileImage.jpg'
      : path;
  if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
    return NetworkImage(resolved);
  }
  if (resolved.startsWith('assets/')) return AssetImage(resolved);
  return FileImage(File(resolved));
}

enum _ProfilePhotoAction { camera, gallery, delete }

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
