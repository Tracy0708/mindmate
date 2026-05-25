import 'package:flutter/material.dart';
import 'package:flutter_twemoji/flutter_twemoji.dart';

/// Renders an emoji as a Twitter-style Twemoji image so it looks identical on
/// every device, instead of relying on the platform's system emoji font.
///
/// Drop-in replacement for `Text(emoji, style: TextStyle(fontSize: size))`.
/// Note: flutter_twemoji sizes via height/width (the emoji is an image), so
/// [size] maps to both dimensions rather than a font size.
class AppEmoji extends StatelessWidget {
  final String emoji;
  final double size;
  const AppEmoji(this.emoji, {super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Twemoji(emoji: emoji, height: size, width: size);
  }
}
