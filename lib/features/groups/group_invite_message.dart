/// Build a shareable group invitation without exposing private data other
/// than the high-entropy invite token, which the receiver needs to join.
/// No Play Store link is invented while SplitLui is not published.
class GroupInviteMessage {
  static const installUrl = String.fromEnvironment(
    'SPLITLUI_INSTALL_URL', defaultValue: '',
  );

  static String format({
    required String groupName,
    required String inviteCode,
    required String heading,
    required String instruction,
    required String codeLabel,
    required String installLabel,
  }) {
    final code = inviteCode.trim().toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(code)) {
      throw FormatException('Invalid group invitation token');
    }
    final buffer = StringBuffer()
      ..writeln(heading)
      ..writeln(groupName)
      ..writeln()
      ..writeln('$codeLabel:')
      ..writeln(code)
      ..writeln()
      ..writeln(instruction);

    final storeUrl = Uri.tryParse(installUrl.trim());
    if (storeUrl != null &&
        storeUrl.hasAuthority &&
        storeUrl.scheme == 'https') {
      buffer..writeln()..writeln('$installLabel:')..writeln(storeUrl);
    }
    return buffer.toString().trimRight();
  }

  /// Receivers may paste the 64-character code OR the entire share message.
  /// Extract only an exact token; never accept arbitrary URL or text as a code.
  static String? codeFromPaste(String value) {
    final trimmed = value.trim().toLowerCase();
    if (RegExp(r'^[a-f0-9]{64}$').hasMatch(trimmed)) return trimmed;
    final matches = RegExp(r'(?<![a-f0-9])[a-f0-9]{64}(?![a-f0-9])')
        .allMatches(trimmed).map((m) => m.group(0)!).toSet();
    return matches.length == 1 ? matches.single : null;
  }
}
