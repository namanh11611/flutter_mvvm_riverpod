import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../constants/assets.dart';
import '../../../../extensions/string_extension.dart';
import '../../../../theme/app_colors.dart';

class Avatar extends StatelessWidget {
  final String? url;

  const Avatar({
    super.key,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.cempedak50,
      backgroundImage: AssetImage(Assets.avatar),
      foregroundImage: _foregroundImage(),
    );
  }

  ImageProvider<Object>? _foregroundImage() {
    if (url == null) return null;

    if (url.isUrl) {
      return CachedNetworkImageProvider(url.orEmpty());
    }

    if (File(url!).existsSync()) {
      return FileImage(File(url!));
    }

    return null;
  }
}
