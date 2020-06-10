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

import 'dart:async';

import 'package:famedlysdk/matrix_api.dart';

import 'event.dart';
import 'room.dart';
import 'utils/event_update.dart';
import 'utils/room_update.dart';

typedef onTimelineUpdateCallback = void Function();
typedef onTimelineInsertCallback = void Function(int insertID);

/// Represents the timeline of a room. The callbacks [onUpdate], [onDelete],
/// [onInsert] and [onResort] will be triggered automatically. The initial
/// event list will be retreived when created by the [room.getTimeline] method.
class Timeline {
  final Room room;
  List<Event> events = [];

  final onTimelineUpdateCallback onUpdate;
  final onTimelineInsertCallback onInsert;

  StreamSubscription<EventUpdate> sub;
  StreamSubscription<RoomUpdate> roomSub;
  StreamSubscription<String> sessionIdReceivedSub;
  bool _requestingHistoryLock = false;

  final Map<String, Event> _eventCache = {};

  /// Searches for the event in this timeline. If not
  /// found, requests from the server. Requested events
  /// are cached.
  Future<Event> getEventById(String id) async {
    for (var i = 0; i < events.length; i++) {
      if (events[i].eventId == id) return events[i];
    }
    if (_eventCache.containsKey(id)) return _eventCache[id];
    final requestedEvent = await room.getEventById(id);
    if (requestedEvent == null) return null;
    _eventCache[id] = requestedEvent;
    return _eventCache[id];
  }

  Future<void> requestHistory(
      {int historyCount = Room.DefaultHistoryCount}) async {
    if (!_requestingHistoryLock) {
      _requestingHistoryLock = true;
      await room.requestHistory(
        historyCount: historyCount,
        onHistoryReceived: () {
          if (room.prev_batch.isEmpty || room.prev_batch == null) events = [];
        },
      );
      await Future.delayed(const Duration(seconds: 2));
      _requestingHistoryLock = false;
    }
  }

  Timeline({this.room, this.events, this.onUpdate, this.onInsert}) {
    sub ??= room.client.onEvent.stream.listen(_handleEventUpdate);
    // if the timeline is limited we want to clear our events cache
    // as r.limitedTimeline can be "null" sometimes, we need to check for == true
    // as after receiving a limited timeline room update new events are expected
    // to be received via the onEvent stream, it is unneeded to call sortAndUpdate
    roomSub ??= room.client.onRoomUpdate.stream
        .where((r) => r.id == room.id && r.limitedTimeline == true)
        .listen((r) => events.clear());
    sessionIdReceivedSub ??=
        room.onSessionKeyReceived.stream.listen(_sessionKeyReceived);
  }

  /// Don't forget to call this before you dismiss this object!
  void cancelSubscriptions() {
    sub?.cancel();
    roomSub?.cancel();
    sessionIdReceivedSub?.cancel();
  }

  void _sessionKeyReceived(String sessionId) async {
    var decryptAtLeastOneEvent = false;
    final decryptFn = () async {
      if (!room.client.encryptionEnabled) {
        return;
      }
      for (var i = 0; i < events.length; i++) {
        if (events[i].type == EventTypes.Encrypted &&
            events[i].messageType == MessageTypes.BadEncrypted &&
            events[i].content['can_request_session'] == true &&
            events[i].content['session_id'] == sessionId) {
          events[i] = await room.client.encryption
              .decryptRoomEvent(room.id, events[i], store: true);
          if (events[i].type != EventTypes.Encrypted) {
            decryptAtLeastOneEvent = true;
          }
        }
      }
    };
    if (room.client.database != null) {
      await room.client.database.transaction(decryptFn);
    } else {
      await decryptFn();
    }
    if (decryptAtLeastOneEvent) onUpdate();
  }

  int _findEvent({String event_id, String unsigned_txid}) {
    int i;
    for (i = 0; i < events.length; i++) {
      if (events[i].eventId == event_id ||
          (unsigned_txid != null && events[i].eventId == unsigned_txid)) break;
    }
    return i;
  }

  void _handleEventUpdate(EventUpdate eventUpdate) async {
    try {
      if (eventUpdate.roomID != room.id) return;

      if (eventUpdate.type == 'timeline' || eventUpdate.type == 'history') {
        // Redaction events are handled as modification for existing events.
        if (eventUpdate.eventType == EventTypes.Redaction) {
          final eventId = _findEvent(event_id: eventUpdate.content['redacts']);
          if (eventId != null) {
            events[eventId].setRedactionEvent(Event.fromJson(
                eventUpdate.content, room, eventUpdate.sortOrder));
          }
        } else if (eventUpdate.content['status'] == -2) {
          var i = _findEvent(event_id: eventUpdate.content['event_id']);
          if (i < events.length) events.removeAt(i);
        }
        // Is this event already in the timeline?
        else if (eventUpdate.content.containsKey('unsigned') &&
            eventUpdate.content['unsigned']['transaction_id'] is String) {
          var i = _findEvent(
              event_id: eventUpdate.content['event_id'],
              unsigned_txid: eventUpdate.content.containsKey('unsigned')
                  ? eventUpdate.content['unsigned']['transaction_id']
                  : null);

          if (i < events.length) {
            events[i] = Event.fromJson(
                eventUpdate.content, room, eventUpdate.sortOrder);
          }
        } else {
          Event newEvent;
          var senderUser = room
                  .getState(
                      EventTypes.RoomMember, eventUpdate.content['sender'])
                  ?.asUser ??
              await room.client.database?.getUser(
                  room.client.id, eventUpdate.content['sender'], room);
          if (senderUser != null) {
            eventUpdate.content['displayname'] = senderUser.displayName;
            eventUpdate.content['avatar_url'] = senderUser.avatarUrl.toString();
          }

          newEvent =
              Event.fromJson(eventUpdate.content, room, eventUpdate.sortOrder);

          if (eventUpdate.type == 'history' &&
              events.indexWhere(
                      (e) => e.eventId == eventUpdate.content['event_id']) !=
                  -1) return;

          events.insert(0, newEvent);
          if (onInsert != null) onInsert(0);
        }
      }
      sortAndUpdate();
    } catch (e) {
      if (room.client.debug) {
        print('[WARNING] (_handleEventUpdate) ${e.toString()}');
      }
    }
  }

  bool sortLock = false;

  void sort() {
    if (sortLock || events.length < 2) return;
    sortLock = true;
    events?.sort((a, b) => b.sortOrder - a.sortOrder > 0 ? 1 : -1);
    sortLock = false;
  }

  void sortAndUpdate() async {
    sort();
    if (onUpdate != null) onUpdate();
  }
}
