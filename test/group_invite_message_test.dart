import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/groups/group_invite_message.dart';

void main() {
  const code = 'ab0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd';

  test('Invite content contains group, join instructions and exact code', () {
    final message = GroupInviteMessage.format(
      groupName: 'Japan Trip',
      inviteCode: code,
      heading: 'Join my group',
      instruction: 'Open SplitLui and paste code',
      codeLabel: 'Invitation code',
      installLabel: 'Install',
    );
    expect(message, contains('Japan Trip'));
    expect(message, contains(code));
    expect(message, contains('Open SplitLui'));
    expect(GroupInviteMessage.codeFromPaste(message), code);
  });

  test('Accepts pasted code alone, ignoring outer whitespace', () {
    expect(GroupInviteMessage.codeFromPaste('  $code  '), code);
  });

  test('Rejects missing or ambiguous codes', () {
    expect(GroupInviteMessage.codeFromPaste('hello'), isNull);
    expect(GroupInviteMessage.codeFromPaste('$code\n$code'), code);
    expect(GroupInviteMessage.codeFromPaste(
      '$code\n' + 'f' * 64,
    ), isNull);
  });

  test('Rejects invalid invite code when formatting', () {
    expect(() => GroupInviteMessage.format(
      groupName: 'Group',
      inviteCode: '1234',
      heading: 'Join', instruction: 'Instructions',
      codeLabel: 'Code', installLabel: 'Install',
    ), throwsFormatException);
  });
}
