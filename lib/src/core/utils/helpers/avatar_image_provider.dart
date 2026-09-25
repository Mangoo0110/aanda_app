import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

ImageProvider? getAvatarImageProvider(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.trim().isEmpty) return null;
  final trimmed = avatarUrl.trim();

  if (trimmed.startsWith('data:image')) {
    try {
      final commaIndex = trimmed.indexOf(',');
      final base64String = commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
      return MemoryImage(base64Decode(base64String.trim()));
    } catch (_) {
      return null;
    }
  }

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return CachedNetworkImageProvider(trimmed);
  }

  if (trimmed.length > 50 && !trimmed.contains(' ')) {
    try {
      return MemoryImage(base64Decode(trimmed));
    } catch (_) {
      return null;
    }
  }

  return null;
}
