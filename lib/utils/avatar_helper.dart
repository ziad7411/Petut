import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';

class AvatarHelper {
  static Widget buildAvatar(String? avatarId, {double size = 60}) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        child: FluttermojiCircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.grey.withOpacity(0.1),
        ),
      ),
    );
  }
}