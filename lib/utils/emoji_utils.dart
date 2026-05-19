// Returns true if the string contains any emoji
bool hasEmoji(String s) {
  return RegExp(
    r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE00}-\u{FEFF}\u{1F900}-\u{1F9FF}]',
    unicode: true,
  ).hasMatch(s);
}

// Strip all emoji and trim
String stripEmoji(String s) {
  return s
      .replaceAll(
        RegExp(
          r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE00}-\u{FEFF}\u{1F900}-\u{1F9FF}]',
          unicode: true,
        ),
        '',
      )
      .trim();
}
