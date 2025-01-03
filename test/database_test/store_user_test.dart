import 'package:matrix/matrix.dart';
import 'package:test/test.dart';

import '../fake_database.dart';

void main() {
  group('Store user test\n', () {
    late DatabaseApi database;
    late Room room;

    setUp(() async {
      database = await getHiveCollectionsDatabase(null);
      room = Room(id: '!testroom:example.com', client: Client('testclient'));
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'Give a user\n'
      'When store user is called\n'
      'Then the user is stored in the database',
      () async {
        final users = [
          User(
            '@bob:example.org',
            displayName: 'Bob',
            avatarUrl: 'mxc://example.com',
            room: room,
          )
        ];

        await database.storeUsers(users, room);

        final storedUser = await database.getUsers(room);

        expect(storedUser.length, 1);

        expect(
          storedUser.where((user) => user.id == '@bob:example.org').isNotEmpty,
          true,
        );
      },
    );

    test(
      'Give list user (Bob_1, Bob_2, Bob_3, Bob_4)\n'
      'When store users is called\n'
      'Then all user is stored in the database',
      () async {
        final users = [
          User(
            '@bob_1:example.org',
            displayName: 'Bob',
            avatarUrl: 'mxc://example.com',
            room: room,
          ),
          User(
            '@bob_2:example.org',
            displayName: 'Bob_2',
            avatarUrl: 'mxc://example.com',
            room: room,
          ),
          User(
            '@bob_3:example.org',
            displayName: 'Bob_3',
            avatarUrl: 'mxc://example.com',
            room: room,
          ),
          User(
            '@bob_4:example.org',
            displayName: 'Bob_4',
            avatarUrl: 'mxc://example.com',
            room: room,
          ),
        ];

        await database.storeUsers(users, room);

        final storedUser = await database.getUsers(room);

        expect(storedUser.length, 4);

        expect(
          storedUser
              .where((user) => user.id == '@bob_1:example.org')
              .isNotEmpty,
          true,
        );

        expect(
          storedUser
              .where((user) => user.id == '@bob_2:example.org')
              .isNotEmpty,
          true,
        );

        expect(
          storedUser
              .where((user) => user.id == '@bob_3:example.org')
              .isNotEmpty,
          true,
        );

        expect(
          storedUser
              .where((user) => user.id == '@bob_4:example.org')
              .isNotEmpty,
          true,
        );
      },
    );

    test(
      'Give list user have 2 users duplicated\n'
      'When store users is called\n'
      'Then only one user is stored in the database',
      () async {
        final users = [
          User(
            '@bob_5:example.org',
            displayName: 'Bob',
            avatarUrl: 'mxc://example.com',
            room: room,
          ),
          User(
            '@bob_5:example.org',
            displayName: 'Bob',
            avatarUrl: 'mxc://example.com',
            room: room,
          ),
        ];

        await database.storeUsers(users, room);

        final storedUser = await database.getUsers(room);

        expect(storedUser.length, 1);

        expect(
          storedUser.where((user) => user.id == '@bob_5:example.org').length,
          1,
        );
      },
    );

    test(
      'Give a user with id is @bob_5:example.org\n'
      'When the user existed in the database\n'
      'AND store users is called\n'
      'Then cannot store the user in the database',
      () async {
        final getUserInitial = await database.getUsers(room);

        expect(getUserInitial.length, 0);

        final users = [
          User(
            '@bob_5:example.org',
            displayName: 'Bob',
            avatarUrl: 'mxc://example.com',
            room: room,
          ),
        ];

        await database.storeUsers(users, room);

        final storedUser = await database.getUsers(room);

        expect(storedUser.length, 1);

        expect(
          storedUser.where((user) => user.id == '@bob_5:example.org').length,
          1,
        );
      },
    );
  });
}
