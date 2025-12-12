/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2019, 2020 Famedly GmbH
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:test/test.dart';

import 'package:matrix/src/utils/matrix_id_string_extension.dart';

void main() {
  /// All Tests related to the ChatTime
  group('Matrix ID String Extension', () {
    test('Matrix ID String Extension', () async {
      final mxId = '@test:example.com';
      expect(mxId.isValidMatrixId, true);
      expect('#test:example.com'.isValidMatrixId, true);
      expect('!test:example.com'.isValidMatrixId, true);
      expect('+test:example.com'.isValidMatrixId, true);
      expect('\$test:example.com'.isValidMatrixId, true);
      expect('\$testevent'.isValidMatrixId, true);
      expect('test:example.com'.isValidMatrixId, false);
      expect('@testexample.com'.isValidMatrixId, false);
      expect('@:example.com'.isValidMatrixId, false);
      expect('@@test:example.com'.isValidMatrixId, false);
      expect('#:example.com'.isValidMatrixId, true);
      expect('@test:'.isValidMatrixId, false);
      expect(mxId.sigil, '@');
      expect('#test:example.com'.sigil, '#');
      expect('!test:example.com'.sigil, '!');
      expect('+test:example.com'.sigil, '+');
      expect('\$test:example.com'.sigil, '\$');
      expect(mxId.localpart, 'test');
      expect(mxId.domain, 'example.com');
      expect(mxId.equals('@Test:example.com'), true);
      expect(mxId.equals('@test:example.org'), false);
      expect('@user:127.0.0.1:8448'.localpart, 'user');
      expect('@user:domain:8448'.localpart, 'user');
      expect('@user:domain:8448'.domain, 'domain:8448');
    });
    test('Character validation and security', () {
      // Valid user IDs - lowercase alphanumeric and allowed symbols
      expect('@user:example.com'.isValidMatrixId, true);
      expect('@test123:example.com'.isValidMatrixId, true);
      expect('@user.name:example.com'.isValidMatrixId, true);
      expect('@user_name:example.com'.isValidMatrixId, true);
      expect('@user-name:example.com'.isValidMatrixId, true);
      expect('@user=name:example.com'.isValidMatrixId, true);
      expect('@user+tag:example.com'.isValidMatrixId, true);
      expect('@a.b-c_d=e+f:example.com'.isValidMatrixId, true);

      // Invalid user IDs - uppercase not allowed per Matrix spec
      expect('@User:example.com'.isValidMatrixId, false);
      expect('@TEST:example.com'.isValidMatrixId, false);
      expect('@UsErNaMe:example.com'.isValidMatrixId, false);

      // Invalid user IDs - spaces and special characters
      expect('@user name:example.com'.isValidMatrixId, false);
      expect('@user!:example.com'.isValidMatrixId, false);
      expect('@user#name:example.com'.isValidMatrixId, false);
      expect('@user\$:example.com'.isValidMatrixId, false);
      expect('@user%:example.com'.isValidMatrixId, false);
      expect('@user&:example.com'.isValidMatrixId, false);
      expect('@user*:example.com'.isValidMatrixId, false);
      expect('@user(:example.com'.isValidMatrixId, false);
      expect('@user):example.com'.isValidMatrixId, false);

      // Domain validation - valid hostnames
      expect('@user:example.com'.isValidMatrixId, true);
      expect('@user:sub.example.com'.isValidMatrixId, true);
      expect('@user:a.b.c.example.com'.isValidMatrixId, true);
      expect('@user:localhost'.isValidMatrixId, true);
      expect('@user:matrix-server.org'.isValidMatrixId, true);
      expect('@user:matrix.server123.org'.isValidMatrixId, true);

      // Domain validation - with ports
      expect('@user:example.com:8448'.isValidMatrixId, true);
      expect('@user:localhost:8008'.isValidMatrixId, true);

      // Domain validation - IPv4
      expect('@user:127.0.0.1'.isValidMatrixId, true);
      expect('@user:192.168.1.1'.isValidMatrixId, true);
      expect('@user:10.0.0.1:8448'.isValidMatrixId, true);

      // Invalid IPv4
      expect('@user:256.1.1.1'.isValidMatrixId, false);
      expect('@user:1.256.1.1'.isValidMatrixId, false);
      expect('@user:1.1.256.1'.isValidMatrixId, false);
      expect('@user:1.1.1.256'.isValidMatrixId, false);
      expect('@user:999.999.999.999'.isValidMatrixId, false);

      // Domain validation - IPv6
      expect('@user:[::1]'.isValidMatrixId, true);
      expect('@user:[2001:db8::1]'.isValidMatrixId, true);
      expect('@user:[fe80::1]'.isValidMatrixId, true);
      expect('@user:[::ffff:192.0.2.1]'.isValidMatrixId, true);

      // Invalid domains
      expect('@user:'.isValidMatrixId, false);
      expect('@user:-invalid.com'.isValidMatrixId, false);
      expect('@user:invalid-.com'.isValidMatrixId, false);
      expect('@user:.invalid.com'.isValidMatrixId, false);
      expect('@user:invalid..com'.isValidMatrixId, false);

      // Security: ReDoS resistance - these should complete quickly
      // Pathological cases that would cause exponential backtracking in old regex
      final reDoSAttempt1 = '@user:' + 'sub.' * 50 + 'com';
      expect(
          reDoSAttempt1.isValidMatrixId, true); // Valid but completes quickly

      final reDoSAttempt2 = '@' + 'a' * 200 + ':example.com';
      expect(reDoSAttempt2.isValidMatrixId, true); // Within length limit

      final reDoSAttempt3 = '@user:' + 'a-' * 100 + 'com';
      expect(reDoSAttempt3.isValidMatrixId, true); // Valid hostname pattern

      // Edge cases
      expect('@:example.com'.isValidMatrixId, false); // Empty localpart
      expect('@user:'.isValidMatrixId, false); // Empty domain
      expect('@'.isValidMatrixId, false); // Only sigil
      expect(''.isValidMatrixId, false); // Empty string
    });

    test('Sigil, localpart, domain extraction for all ID types', () {
      // User IDs - uses isValidMatrixId (only @)
      expect('@test:example.com'.sigil, '@');
      expect('@test:example.com'.localpart, 'test');
      expect('@test:example.com'.domain, 'example.com');

      // Room aliases - uses _isValidMatrixIdGeneral
      expect('#room:example.com'.sigil, '#');
      expect('#room:example.com'.localpart, 'room');
      expect('#room:example.com'.domain, 'example.com');
      expect('#:example.com'.sigil, '#'); // Empty localpart OK for aliases
      expect('#:example.com'.localpart, '');
      expect('#:example.com'.domain, 'example.com');

      // Room IDs - no domain required
      expect('!roomid123:example.com'.sigil, '!');
      expect('!roomid123:example.com'.localpart, 'roomid123');
      expect('!roomid123:example.com'.domain, 'example.com');
      expect('!roomid123'.sigil, '!');

      // Event IDs - no domain required
      expect('\$eventid456'.sigil, '\$');
      expect('\$eventid456:example.com'.sigil, '\$');

      // Groups
      expect('+group:example.com'.sigil, '+');
      expect('+group:example.com'.localpart, 'group');
      expect('+group:example.com'.domain, 'example.com');
    });

    test('parseIdentifierIntoParts', () {
      var res = '#alias:beep'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, null);
      expect('blha'.parseIdentifierIntoParts(), null);
      res = '#alias:beep/\$event'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, '\$event');
      expect(res.queryString, null);
      res = '#alias:beep?blubb'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, 'blubb');
      res = '#alias:beep/\$event?blubb'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, '\$event');
      expect(res.queryString, 'blubb');
      res = '#/\$?:beep/\$event?blubb?b'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#/\$?:beep');
      expect(res.secondaryIdentifier, '\$event');
      expect(res.queryString, 'blubb?b');

      res = 'https://matrix.to/#/#alias:beep'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, null);
      res = 'https://matrix.to/#/#🦊:beep'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#🦊:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, null);
      res = 'https://matrix.to/#/%23alias%3abeep'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, null);
      res = 'https://matrix.to/#/%23alias%3abeep?boop%F0%9F%A7%A1%F0%9F%A6%8A'
          .parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, 'boop%F0%9F%A7%A1%F0%9F%A6%8A');

      res = 'https://matrix.to/#/#alias:beep?via=fox.com&via=fox.org'
          .parseIdentifierIntoParts()!;
      expect(res.via, <String>{'fox.com', 'fox.org'});

      res = 'matrix:u/her:example.org'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '@her:example.org');
      expect(res.secondaryIdentifier, null);
      expect('matrix:u/bad'.parseIdentifierIntoParts(), null);
      res = 'matrix:roomid/rid:example.org'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '!rid:example.org');
      expect(res.secondaryIdentifier, null);
      expect(res.action, null);
      res = 'matrix:r/us:example.org?action=chat'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#us:example.org');
      expect(res.secondaryIdentifier, null);
      expect(res.action, 'chat');
      res = 'matrix:r/us:example.org/e/lol823y4bcp3qo4'
          .parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#us:example.org');
      expect(res.secondaryIdentifier, '\$lol823y4bcp3qo4');
      res = 'matrix:roomid/rid:example.org?via=fox.com&via=fox.org'
          .parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '!rid:example.org');
      expect(res.secondaryIdentifier, null);
      expect(res.via, <String>{'fox.com', 'fox.org'});
      expect('matrix:beep/boop:example.org'.parseIdentifierIntoParts(), null);
      expect('matrix:boop'.parseIdentifierIntoParts(), null);
    });
  });
}
