import 'package:matrix/matrix.dart';
import 'package:test/test.dart';

import 'fake_client.dart';

void main() {
  late Client matrix;
  late Room room;

  final id = '!localpart:server.abc';
  final membership = Membership.join;
  final notificationCount = 2;
  final highlightCount = 1;
  final heroes = [
    '@alice:matrix.org',
    '@bob:example.com',
    '@charley:example.org'
  ];

  group('[get event content from msg text test]\n', () {
    Logs().level = Level.error;
    test('Login and setup room', () async {
      matrix = await getClient();
      room = Room(
        client: matrix,
        id: id,
        membership: membership,
        highlightCount: highlightCount,
        notificationCount: notificationCount,
        prev_batch: '',
        summary: RoomSummary.fromJson({
          'm.joined_member_count': 2,
          'm.invited_member_count': 2,
          'm.heroes': heroes,
        }),
        roomAccountData: {
          'com.test.foo': BasicRoomEvent(
            type: 'com.test.foo',
            content: {'foo': 'bar'},
          ),
          'm.fully_read': BasicRoomEvent(
            type: 'm.fully_read',
            content: {'event_id': '\$event_id:example.com'},
          ),
        },
      );
    });

    test(
        'GIVE text format is simple markdown\n'
        'WHEN text is "hey *there* how are **you** doing?"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = 'hey *there* how are **you** doing?';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody == null,
        true,
      );
    });

    test(
        'GIVE text format is simple markdown\n'
        'WHEN text is "wha ~~strike~~ works!"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'wha ~~strike~~ works!';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'wha <del>strike</del> works!',
      );
    });

    test(
        'GIVE text format is spoilers\n'
        'WHEN text is "Snape killed ||Dumbledoor||"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'Snape killed ||Dumbledoor||';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'Snape killed <span data-mx-spoiler="">Dumbledoor</span>',
      );
    });

    test(
        'GIVE text format is spoilers\n'
        'WHEN text is "Snape killed ||Some dumb loser|Dumbledoor||"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'Snape killed ||Some dumb loser|Dumbledoor||';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'Snape killed <span data-mx-spoiler="Some dumb loser">Dumbledoor</span>',
      );
    });

    test(
        'GIVE text format is spoilers\n'
        'WHEN text is "Snape killed ||Some dumb loser|Dumbledoor **bold**||"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'Snape killed ||Some dumb loser|Dumbledoor **bold**||';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'Snape killed <span data-mx-spoiler="Some dumb loser">Dumbledoor **bold**</span>',
      );
    });

    test(
        'GIVE text format is spoilers\n'
        'WHEN text is "Snape killed ||Dumbledoor **bold**|||"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'Snape killed ||Dumbledoor **bold**||';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'Snape killed <span data-mx-spoiler="">Dumbledoor **bold**</span>',
      );
    });

    test(
        'GIVE text format is multiple paragraphs\n'
        'WHEN text is "Heya!\n\nBeep"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = 'Heya!\n\nBeep';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is linebreaks\n'
        'WHEN text is "foxies\ncute"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = 'foxies\ncute';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    ///

    test(
        'GIVE text format is emotes\n'
        'AND not supported\n'
        'WHEN text is ":fox:"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = ':fox:';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is emotes\n'
        'AND not supported\n'
        'WHEN text is ":invalid:"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = ':invalid:';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is emotes\n'
        'AND not supported\n'
        'WHEN text is ":invalid:?!"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = ':invalid:?!';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is emotes\n'
        'AND not supported\n'
        'WHEN text is ":room~invalid:"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = ':room~invalid:';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is pills\n'
        'WHEN text is "Hey @sorunome:sorunome.de!"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'Hey @sorunome:sorunome.de!';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'Hey <a href="https://matrix.to/#/@sorunome:sorunome.de">@sorunome:sorunome.de</a>!',
      );
    });

    test(
        'GIVE text format is pills\n'
        'WHEN text is "#fox:sorunome.de: you all are awesome"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = '#fox:sorunome.de: you all are awesome';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        '<a href="https://matrix.to/#/#fox:sorunome.de">#fox:sorunome.de</a>: you all are awesome',
      );
    });

    test(
        'GIVE text format is pills\n'
        'WHEN text is "!blah:example.org"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = '!blah:example.org';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        '<a href="https://matrix.to/#/!blah:example.org">!blah:example.org</a>',
      );
    });

    test(
        'GIVE text format is pills\n'
        'WHEN text is "https://matrix.to/#/#fox:sorunome.de"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = 'https://matrix.to/#/#fox:sorunome.de';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is pills\n'
        'WHEN text is "Hey @sorunome:sorunome.de:1234!"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'Hey @sorunome:sorunome.de:1234!';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'Hey <a href="https://matrix.to/#/@sorunome:sorunome.de:1234">@sorunome:sorunome.de:1234</a>!',
      );
    });

    test(
        'GIVE text format is pills\n'
        'WHEN text is "Hey @sorunome:127.0.0.1!"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'Hey @sorunome:127.0.0.1!';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'Hey <a href="https://matrix.to/#/@sorunome:127.0.0.1">@sorunome:127.0.0.1</a>!',
      );
    });

    test(
        'GIVE text format is pills\n'
        'WHEN text is "Hey @sorunome:[::1]!"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'Hey @sorunome:[::1]!';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'Hey <a href="https://matrix.to/#/@sorunome:[::1]">@sorunome:[::1]</a>!',
      );
    });

    test(
        'GIVE text format is mentions\n'
        'WHEN text is "Hey @bob:example.org!"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'Hey @bob:example.org!';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'Hey <a href="https://matrix.to/#/@bob:example.org">@bob:example.org</a>!',
      );
    });

    test(
        'GIVE text format is mentions\n'
        'WHEN text is "How is @bobross:example.org doing?"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'How is @bobross:example.org doing?';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'How is <a href="https://matrix.to/#/@bobross:example.org">@bobross:example.org</a> doing?',
      );
    });

    test(
        'GIVE text format is mentions\n'
        'WHEN text is "Hey @invalid!"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = 'Hey @invalid!';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    ///

    test(
        'GIVE text format is latex\n'
        'AND not supported\n'
        'WHEN text is "meep \$\\frac{2}{3}\$"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = 'meep \$\\frac{2}{3}\$';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is latex\n'
        'AND not supported\n'
        'WHEN text is "meep \$hmm *yay*\$"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = 'meep \$hmm *yay*\$';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is latex\n'
        'AND not supported\n'
        'WHEN text is "you have \$somevar and \$someothervar"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = 'you have \$somevar and \$someothervar';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is latex\n'
        'AND not supported and only support ||\n'
        'WHEN text is "meep ||\$\\frac{2}{3}\$||"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = 'meep ||\$\\frac{2}{3}\$||';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'meep <span data-mx-spoiler="">\$\\frac{2}{3}\$</span>',
      );
    });

    test(
        'GIVE text format is latex\n'
        'AND not supported\n'
        'WHEN text is "meep `\$\\frac{2}{3}\$`"\n'
        'THEN formatted_body is null\n', () {
      final textmsg = 'meep `\$\\frac{2}{3}\$`';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is Code blocks\n'
        'WHEN text is "```dart\nvoid main(){\nprint(something);\n}\n```"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg = '```dart\nvoid main(){\nprint(something);\n}\n```';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        '<pre><code class="language-dart">void main(){\nprint(something);\n}\n</code></pre>',
      );
    });

    test(
        'GIVE text format is Code blocks\n'
        'WHEN text is "The first \n codeblock\n```dart\nvoid main(){\nprint(something);\n}\n```\nAnd the second code block\n```js\nmeow\nmeow\n```"\n'
        'THEN formatted_body is not null\n', () {
      final textmsg =
          'The first \n codeblock\n```dart\nvoid main(){\nprint(something);\n}\n```\nAnd the second code block\n```js\nmeow\nmeow\n```';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        true,
      );

      expect(
        formattedBody,
        'The first <br/> codeblock<br/><pre><code class="language-dart">void main(){\n'
        'print(something);\n'
        '}\n'
        '</code></pre>And the second code block<br/><pre><code class="language-js">meow\n'
        'meow\n'
        '</code></pre>',
      );
    });

    ///

    test(
        'GIVE text format is not support HTML\n'
        'WHEN text is "<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">\n<path d="M30.2178 10.5L52.7047 10.5L52.706 10.5L52.7074 10.5L52.7127 10.5L52.718 10.5L52.7343 10.5L52.8216 10.5L53.1724 10.5L54.5792 10.5L60.0107 10.5L85.7178 36.2071V74C85.7178 82.5604 78.7782 89.5 70.2178 89.5H30.2178C21.6574 89.5 14.7178 82.5604 14.7178 74V26C14.7178 17.4396 21.6574 10.5 30.2178 10.5Z" fill="#FDFAF5" stroke="#FF9500"/> <path d="M86.2178 37L59.2178 10V23.9655C59.2178 31.1643 64.859 37 71.8178 37H86.2178Z" fill="#FF9500"/>\n<path fill-rule="evenodd" clip-rule="evenodd" d="M42 52V74H46.181V66.0602H51.1833C54.6881 66.0602 57.5294 62.9127 57.5294 59.0301C57.5294 55.1475 54.6881 52 51.1833 52H42ZM46.181 62.7519V55.3083H50.2873C52.1429 55.3083 53.6471 56.9746 53.6471 59.0301C53.6471 61.0856 52.1429 62.7519 50.2873 62.7519H46.181Z" fill="#FF9500"/>\n</svg>"\n'
        'THEN formatted_body is null\n', () {
      final textmsg =
          '<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">\n<path d="M30.2178 10.5L52.7047 10.5L52.706 10.5L52.7074 10.5L52.7127 10.5L52.718 10.5L52.7343 10.5L52.8216 10.5L53.1724 10.5L54.5792 10.5L60.0107 10.5L85.7178 36.2071V74C85.7178 82.5604 78.7782 89.5 70.2178 89.5H30.2178C21.6574 89.5 14.7178 82.5604 14.7178 74V26C14.7178 17.4396 21.6574 10.5 30.2178 10.5Z" fill="#FDFAF5" stroke="#FF9500"/> <path d="M86.2178 37L59.2178 10V23.9655C59.2178 31.1643 64.859 37 71.8178 37H86.2178Z" fill="#FF9500"/>\n<path fill-rule="evenodd" clip-rule="evenodd" d="M42 52V74H46.181V66.0602H51.1833C54.6881 66.0602 57.5294 62.9127 57.5294 59.0301C57.5294 55.1475 54.6881 52 51.1833 52H42ZM46.181 62.7519V55.3083H50.2873C52.1429 55.3083 53.6471 56.9746 53.6471 59.0301C53.6471 61.0856 52.1429 62.7519 50.2873 62.7519H46.181Z" fill="#FF9500"/>\n</svg>';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is not support HTML\n'
        'WHEN text is "<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg"><br/><path d="M30.2178 10.5L52.7047 10.5L52.706 10.5L52.7074 10.5L52.7127 10.5L52.718 10.5L52.7343 10.5L52.8216 10.5L53.1724 10.5L54.5792 10.5L60.0107 10.5L85.7178 36.2071V74C85.7178 82.5604 78.7782 89.5 70.2178 89.5H30.2178C21.6574 89.5 14.7178 82.5604 14.7178 74V26C14.7178 17.4396 21.6574 10.5 30.2178 10.5Z" fill="#FDFAF5" stroke="#FF9500"/> <path d="M86.2178 37L59.2178 10V23.9655C59.2178 31.1643 64.859 37 71.8178 37H86.2178Z" fill="#FF9500"/> <path fill-rule="evenodd" clip-rule="evenodd" d="M42 52V74H46.181V66.0602H51.1833C54.6881 66.0602 57.5294 62.9127 57.5294 59.0301C57.5294 55.1475 54.6881 52 51.1833 52H42ZM46.181 62.7519V55.3083H50.2873C52.1429 55.3083 53.6471 56.9746 53.6471 59.0301C53.6471 61.0856 52.1429 62.7519 50.2873 62.7519H46.181Z" fill="#FF9500"/> </svg>"\n'
        'THEN formatted_body is null\n', () {
      final textmsg =
          '<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg"><br/><path d="M30.2178 10.5L52.7047 10.5L52.706 10.5L52.7074 10.5L52.7127 10.5L52.718 10.5L52.7343 10.5L52.8216 10.5L53.1724 10.5L54.5792 10.5L60.0107 10.5L85.7178 36.2071V74C85.7178 82.5604 78.7782 89.5 70.2178 89.5H30.2178C21.6574 89.5 14.7178 82.5604 14.7178 74V26C14.7178 17.4396 21.6574 10.5 30.2178 10.5Z" fill="#FDFAF5" stroke="#FF9500"/> <path d="M86.2178 37L59.2178 10V23.9655C59.2178 31.1643 64.859 37 71.8178 37H86.2178Z" fill="#FF9500"/> <path fill-rule="evenodd" clip-rule="evenodd" d="M42 52V74H46.181V66.0602H51.1833C54.6881 66.0602 57.5294 62.9127 57.5294 59.0301C57.5294 55.1475 54.6881 52 51.1833 52H42ZM46.181 62.7519V55.3083H50.2873C52.1429 55.3083 53.6471 56.9746 53.6471 59.0301C53.6471 61.0856 52.1429 62.7519 50.2873 62.7519H46.181Z" fill="#FF9500"/> </svg>';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is not support HTML\n'
        'WHEN text is "<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg"><br /><path d="M30.2178 10.5L52.7047 10.5L52.706 10.5L52.7074 10.5L52.7127 10.5L52.718 10.5L52.7343 10.5L52.8216 10.5L53.1724 10.5L54.5792 10.5L60.0107 10.5L85.7178 36.2071V74C85.7178 82.5604 78.7782 89.5 70.2178 89.5H30.2178C21.6574 89.5 14.7178 82.5604 14.7178 74V26C14.7178 17.4396 21.6574 10.5 30.2178 10.5Z" fill="#FDFAF5" stroke="#FF9500"/> <path d="M86.2178 37L59.2178 10V23.9655C59.2178 31.1643 64.859 37 71.8178 37H86.2178Z" fill="#FF9500"/> <path fill-rule="evenodd" clip-rule="evenodd" d="M42 52V74H46.181V66.0602H51.1833C54.6881 66.0602 57.5294 62.9127 57.5294 59.0301C57.5294 55.1475 54.6881 52 51.1833 52H42ZM46.181 62.7519V55.3083H50.2873C52.1429 55.3083 53.6471 56.9746 53.6471 59.0301C53.6471 61.0856 52.1429 62.7519 50.2873 62.7519H46.181Z" fill="#FF9500"/> </svg>"\n'
        'THEN formatted_body is null\n', () {
      final textmsg =
          '<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg"><br /><path d="M30.2178 10.5L52.7047 10.5L52.706 10.5L52.7074 10.5L52.7127 10.5L52.718 10.5L52.7343 10.5L52.8216 10.5L53.1724 10.5L54.5792 10.5L60.0107 10.5L85.7178 36.2071V74C85.7178 82.5604 78.7782 89.5 70.2178 89.5H30.2178C21.6574 89.5 14.7178 82.5604 14.7178 74V26C14.7178 17.4396 21.6574 10.5 30.2178 10.5Z" fill="#FDFAF5" stroke="#FF9500"/> <path d="M86.2178 37L59.2178 10V23.9655C59.2178 31.1643 64.859 37 71.8178 37H86.2178Z" fill="#FF9500"/> <path fill-rule="evenodd" clip-rule="evenodd" d="M42 52V74H46.181V66.0602H51.1833C54.6881 66.0602 57.5294 62.9127 57.5294 59.0301C57.5294 55.1475 54.6881 52 51.1833 52H42ZM46.181 62.7519V55.3083H50.2873C52.1429 55.3083 53.6471 56.9746 53.6471 59.0301C53.6471 61.0856 52.1429 62.7519 50.2873 62.7519H46.181Z" fill="#FF9500"/> </svg>';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });

    test(
        'GIVE text format is not support HTML\n'
        'WHEN text is "<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg"><br />\n<path d="M30.2178 10.5L52.7047 10.5L52.706 10.5L52.7074 10.5L52.7127 10.5L52.718 10.5L52.7343 10.5L52.8216 10.5L53.1724 10.5L54.5792 10.5L60.0107 10.5L85.7178 36.2071V74C85.7178 82.5604 78.7782 89.5 70.2178 89.5H30.2178C21.6574 89.5 14.7178 82.5604 14.7178 74V26C14.7178 17.4396 21.6574 10.5 30.2178 10.5Z" fill="#FDFAF5" stroke="#FF9500"/> <path d="M86.2178 37L59.2178 10V23.9655C59.2178 31.1643 64.859 37 71.8178 37H86.2178Z" fill="#FF9500"/> <path fill-rule="evenodd" clip-rule="evenodd" d="M42 52V74H46.181V66.0602H51.1833C54.6881 66.0602 57.5294 62.9127 57.5294 59.0301C57.5294 55.1475 54.6881 52 51.1833 52H42ZM46.181 62.7519V55.3083H50.2873C52.1429 55.3083 53.6471 56.9746 53.6471 59.0301C53.6471 61.0856 52.1429 62.7519 50.2873 62.7519H46.181Z" fill="#FF9500"/> </svg>"\n'
        'THEN formatted_body is null\n', () {
      final textmsg =
          '<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg"><br />\n<path d="M30.2178 10.5L52.7047 10.5L52.706 10.5L52.7074 10.5L52.7127 10.5L52.718 10.5L52.7343 10.5L52.8216 10.5L53.1724 10.5L54.5792 10.5L60.0107 10.5L85.7178 36.2071V74C85.7178 82.5604 78.7782 89.5 70.2178 89.5H30.2178C21.6574 89.5 14.7178 82.5604 14.7178 74V26C14.7178 17.4396 21.6574 10.5 30.2178 10.5Z" fill="#FDFAF5" stroke="#FF9500"/> <path d="M86.2178 37L59.2178 10V23.9655C59.2178 31.1643 64.859 37 71.8178 37H86.2178Z" fill="#FF9500"/> <path fill-rule="evenodd" clip-rule="evenodd" d="M42 52V74H46.181V66.0602H51.1833C54.6881 66.0602 57.5294 62.9127 57.5294 59.0301C57.5294 55.1475 54.6881 52 51.1833 52H42ZM46.181 62.7519V55.3083H50.2873C52.1429 55.3083 53.6471 56.9746 53.6471 59.0301C53.6471 61.0856 52.1429 62.7519 50.2873 62.7519H46.181Z" fill="#FF9500"/> </svg>';
      final event = room.getEventContentFromMsgText(message: textmsg);
      final formattedBody = event['formatted_body'];
      expect(
        formattedBody != null,
        false,
      );
    });
  });
}
