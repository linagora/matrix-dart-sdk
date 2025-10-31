// /*
//  * Example: Using Cached Filtered Last Events for Chat Lists
//  *
//  * This example demonstrates how to use the efficient cached filtered
//  * last event system for displaying chat lists without database race conditions.
//  */

// import 'package:matrix/matrix.dart';

// /// Example 1: Basic setup with default filter
// void basicSetup() {
//   final client = Client('MyApp');

//   // Set up the filter once during client initialization
//   // This will be used for all rooms automatically
//   client.roomPreviewLastEventFilter = EventFilters.defaultChatListFilter;

//   // The default filter excludes:
//   // - Redacted (deleted) events
//   // - Events with error status
//   // - Non-message events
//   // - Events that are still sending

//   // Now all rooms will have their filteredLastEvent cached and ready to use!
// }

// /// Example 2: Custom filter setup
// void customFilterSetup() {
//   final client = Client('MyApp');

//   // Create a custom filter that:
//   // - Excludes redacted events
//   // - Only shows messages
//   // - Excludes messages from bots
//   client.roomPreviewLastEventFilter = EventFilters.combineAnd([
//     EventFilters.excludeRedacted,
//     EventFilters.onlyMessages,
//     (event) => !event.senderId.contains('bot:'),
//   ]);
// }

// /// Example 3: Building a chat list widget (Flutter)
// /// This is FAST and EFFICIENT - no async calls, no database queries!
// class ChatListExample {
//   Widget buildChatList(Client client) {
//     final rooms = client.rooms;

//     return ListView.builder(
//       itemCount: rooms.length,
//       itemBuilder: (context, index) {
//         final room = rooms[index];

//         // Simply access the cached filtered last event - no async needed!
//         final lastEvent = room.filteredLastEvent;

//         return ListTile(
//           leading: CircleAvatar(
//             backgroundImage: room.avatar != null
//                 ? NetworkImage(room.avatar!.toString())
//                 : null,
//             child: room.avatar == null ? Text(room.name[0]) : null,
//           ),
//           title: Text(room.getLocalizedDisplayname()),
//           subtitle: lastEvent != null
//               ? Text(
//                   lastEvent.body,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 )
//               : Text('No messages'),
//           trailing: lastEvent != null
//               ? Text(_formatTimestamp(lastEvent.originServerTs))
//               : null,
//           onTap: () {
//             // Navigate to room
//           },
//         );
//       },
//     );
//   }

//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final diff = now.difference(timestamp);

//     if (diff.inDays > 0) {
//       return '${diff.inDays}d ago';
//     } else if (diff.inHours > 0) {
//       return '${diff.inHours}h ago';
//     } else if (diff.inMinutes > 0) {
//       return '${diff.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }
// }

// /// Example 4: Sorting rooms by last message time
// List<Room> sortRoomsByLastMessage(Client client) {
//   final rooms = client.rooms.toList();

//   // Sort by last event timestamp (most recent first)
//   rooms.sort((a, b) {
//     final aEvent = a.filteredLastEvent;
//     final bEvent = b.filteredLastEvent;

//     if (aEvent == null && bEvent == null) return 0;
//     if (aEvent == null) return 1;
//     if (bEvent == null) return -1;

//     return bEvent.originServerTs.compareTo(aEvent.originServerTs);
//   });

//   return rooms;
// }

// /// Example 5: Different filters for different scenarios
// class MultiFilterExample {
//   final Client client;

//   MultiFilterExample(this.client);

//   // Switch to showing all events including system messages
//   Future<void> showAllEvents() async {
//     client.roomPreviewLastEventFilter = EventFilters.excludeRedacted;

//     // Refresh all room caches
//     for (final room in client.rooms) {
//       await room.updateFilteredLastEventAsync();
//     }
//   }

//   // Switch to showing only messages from others (exclude your own)
//   Future<void> showOnlyOthersMessages() async {
//     client.roomPreviewLastEventFilter = EventFilters.combineAnd([
//       EventFilters.excludeRedacted,
//       EventFilters.onlyMessages,
//       (event) => event.senderId != client.userID,
//     ]);

//     // Refresh all room caches
//     for (final room in client.rooms) {
//       await room.updateFilteredLastEventAsync();
//     }
//   }

//   // Back to default
//   Future<void> useDefaultFilter() async {
//     client.roomPreviewLastEventFilter = EventFilters.defaultChatListFilter;

//     // Refresh all room caches
//     for (final room in client.rooms) {
//       await room.updateFilteredLastEventAsync();
//     }
//   }
// }

// /// Example 6: Custom application-specific filters
// class MyAppFilters {
//   /// Filter for production chat list
//   static final production = EventFilters.combineAnd([
//     EventFilters.excludeRedacted,
//     EventFilters.onlyMessages,
//     EventFilters.onlySynced,
//     // Don't show verification events
//     (event) => !event.messageType.startsWith('m.room.verification.'),
//   ]);

//   /// Filter for debugging (shows everything)
//   static bool debug(Event event) => true;

//   /// Filter that excludes old events (older than 30 days)
//   static bool excludeOldMessages(Event event) {
//     final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
//     return event.originServerTs.isAfter(thirtyDaysAgo);
//   }
// }

// /// Example 7: Complete initialization flow
// Future<void> initializeClientWithFilters() async {
//   final client = Client(
//     'MyApp',
//     databaseBuilder: (_) async {
//       // Your database setup
//       return null;
//     },
//   );

//   // Set up the filter BEFORE logging in or starting sync
//   client.roomPreviewLastEventFilter = MyAppFilters.production;

//   await client.checkHomeserver('https://matrix.example.com');
//   await client.login(
//     identifier: AuthenticationUserIdentifier(user: 'alice'),
//     password: 'secret',
//   );

//   // The filtered last events will be automatically cached as sync proceeds!
//   // No additional work needed - just use room.filteredLastEvent in your UI
// }

// /// Example 8: Comparing old vs new approach
// class PerformanceComparison {
//   // OLD WAY (BAD - causes database race conditions)
//   /*
//   Future<Widget> buildChatListOld(List<Room> rooms) async {
//     final items = <Widget>[];

//     for (final room in rooms) {
//       // This causes a database query for EVERY room on EVERY rebuild!
//       final lastEvent = await room.getFilteredLastEvent();

//       items.add(ListTile(
//         title: Text(room.name),
//         subtitle: Text(lastEvent?.body ?? 'No messages'),
//       ));
//     }

//     return ListView(children: items);
//   }
//   */

//   // NEW WAY (GOOD - uses cached values, no database queries)
//   Widget buildChatListNew(List<Room> rooms) {
//     return ListView.builder(
//       itemCount: rooms.length,
//       itemBuilder: (context, index) {
//         final room = rooms[index];

//         // Instantly available - no async, no database query!
//         final lastEvent = room.filteredLastEvent;

//         return ListTile(
//           title: Text(room.name),
//           subtitle: Text(lastEvent?.body ?? 'No messages'),
//         );
//       },
//     );
//   }
// }

// /// Example 9: Handling edge cases
// class EdgeCaseHandling {
//   Widget buildRoomPreview(Room room) {
//     final lastEvent = room.filteredLastEvent;

//     // Case 1: No events match the filter
//     if (lastEvent == null) {
//       return Text('No messages yet');
//     }

//     // Case 2: Event is redacted after being cached
//     if (lastEvent.redacted) {
//       return Text('Message deleted');
//     }

//     // Case 3: Encrypted event that couldn't be decrypted
//     if (lastEvent.type == EventTypes.Encrypted) {
//       return Text('Encrypted message');
//     }

//     // Case 4: Normal message
//     return Text(lastEvent.body);
//   }
// }

// /// Example 10: Complete chat list with all features
// class CompleteChatList {
//   final Client client;

//   CompleteChatList(this.client) {
//     // Set up filter during construction
//     client.roomPreviewLastEventFilter = EventFilters.combineAnd([
//       EventFilters.excludeRedacted,
//       EventFilters.onlyMessages,
//       EventFilters.onlySynced,
//       EventFilters.excludeStateEvents,
//     ]);
//   }

//   Widget build(BuildContext context) {
//     // Get and sort rooms
//     final rooms = client.rooms.toList();
//     rooms.sort((a, b) {
//       final aEvent = a.filteredLastEvent;
//       final bEvent = b.filteredLastEvent;

//       if (aEvent == null && bEvent == null) {
//         return a.name.compareTo(b.name);
//       }
//       if (aEvent == null) return 1;
//       if (bEvent == null) return -1;

//       return bEvent.originServerTs.compareTo(aEvent.originServerTs);
//     });

//     return ListView.builder(
//       itemCount: rooms.length,
//       itemBuilder: (context, index) {
//         final room = rooms[index];
//         final lastEvent = room.filteredLastEvent;

//         return ListTile(
//           leading: CircleAvatar(
//             backgroundImage: room.avatar != null
//                 ? NetworkImage(room.avatar!.toString())
//                 : null,
//             child: room.avatar == null
//                 ? Text(room.name.isNotEmpty ? room.name[0] : '?')
//                 : null,
//           ),
//           title: Row(
//             children: [
//               Expanded(child: Text(room.getLocalizedDisplayname())),
//               if (room.notificationCount > 0)
//                 Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: room.highlightCount > 0 ? Colors.red : Colors.grey,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Text(
//                     '${room.notificationCount}',
//                     style: const TextStyle(color: Colors.white, fontSize: 12),
//                   ),
//                 ),
//             ],
//           ),
//           subtitle: lastEvent != null
//               ? Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         _formatMessage(lastEvent),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 )
//               : const Text('No messages'),
//           trailing: lastEvent != null
//               ? Text(
//                   _formatTime(lastEvent.originServerTs),
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 )
//               : null,
//         );
//       },
//     );
//   }

//   String _formatMessage(Event event) {
//     final sender = event.senderFromMemoryOrFallback.displayName ?? 'Someone';

//     if (event.messageType == MessageTypes.Image) {
//       return '$sender sent an image';
//     } else if (event.messageType == MessageTypes.File) {
//       return '$sender sent a file';
//     } else if (event.messageType == MessageTypes.Video) {
//       return '$sender sent a video';
//     } else {
//       return '${sender}: ${event.body}';
//     }
//   }

//   String _formatTime(DateTime time) {
//     final now = DateTime.now();
//     final diff = now.difference(time);

//     if (diff.inDays > 6) {
//       return '${time.day}/${time.month}';
//     } else if (diff.inDays > 0) {
//       return '${diff.inDays}d';
//     } else if (diff.inHours > 0) {
//       return '${diff.inHours}h';
//     } else if (diff.inMinutes > 0) {
//       return '${diff.inMinutes}m';
//     } else {
//       return 'now';
//     }
//   }
// }

// // Placeholder classes for the example
// class BuildContext {}

// class Widget {}

// class ListView {
//   ListView({List<Widget>? children});
//   ListView.builder({int? itemCount, Widget Function(BuildContext, int)? itemBuilder});
// }

// class ListTile {
//   ListTile(
//       {Widget? leading,
//       Widget? title,
//       Widget? subtitle,
//       Widget? trailing,
//       void Function()? onTap});
// }

// class CircleAvatar {
//   CircleAvatar({ImageProvider? backgroundImage, Widget? child});
// }

// class NetworkImage implements ImageProvider {
//   NetworkImage(String url);
// }

// class Text extends Widget {
//   Text(String text,
//       {int? maxLines,
//       TextOverflow? overflow,
//       TextStyle? style});
// }

// class Row extends Widget {
//   Row({List<Widget>? children});
// }

// class Expanded extends Widget {
//   Expanded({required Widget child});
// }

// class Container extends Widget {
//   Container({EdgeInsets? padding, Decoration? decoration, Widget? child});
// }

// class BoxDecoration extends Decoration {
//   BoxDecoration({Color? color, BorderRadius? borderRadius});
// }

// class BorderRadius {
//   static BorderRadius circular(double radius) => BorderRadius();
// }

// class EdgeInsets {
//   const EdgeInsets.all(double value);
// }

// class Colors {
//   static const red = Color();
//   static const grey = Color();
//   static const white = Color();
// }

// class Color {
//   const Color();
// }

// class TextStyle {
//   const TextStyle({Color? color, double? fontSize});
// }

// class TextOverflow {
//   static const ellipsis = TextOverflow();
//   const TextOverflow();
// }

// class ImageProvider {}

// class Decoration {}
