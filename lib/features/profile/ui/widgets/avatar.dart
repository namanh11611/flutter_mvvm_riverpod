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
      foregroundImage: url != null
          ? (url.isUrl
              ? CachedNetworkImageProvider(url.orEmpty())
              : FileImage(File(url!)))
          : null,
    );
  }
}
