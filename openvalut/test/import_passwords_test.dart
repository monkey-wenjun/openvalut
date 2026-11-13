import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/ui/screens/import_passwords_screen.dart';

void main() {
  test('parses a 1Password CSV export', () {
    const csv = 'Title,Url,Username,Password,OTPAuth,Favorite,Archived,Tags,Notes\n'
        'GitHub,https://github.com,octocat,gh-secret,otpauth://totp/GitHub?secret=ABC,true,false,tag1,"some, notes"\n'
        '"Foo, Inc","https://foo.example","user ""x""",pw2,,false,false,,\n';
    final rows = parseCsvRows(csv);
    expect(rows.length, 3);
    expect(rows[0], [
      'Title',
      'Url',
      'Username',
      'Password',
      'OTPAuth',
      'Favorite',
      'Archived',
      'Tags',
      'Notes',
    ]);
    expect(rows[1][0], 'GitHub');
    expect(rows[1][1], 'https://github.com');
    expect(rows[1][8], 'some, notes');
    expect(rows[2][0], 'Foo, Inc');
    expect(rows[2][2], 'user "x"');
    expect(rows[2][3], 'pw2');
  });

  test('handles CRLF line endings', () {
    final rows = parseCsvRows('a,b\r\nc,d\r\n');
    expect(rows, [
      ['a', 'b'],
      ['c', 'd'],
    ]);
  });
}
