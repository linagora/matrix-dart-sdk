/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2019, 2020, 2021 Famedly GmbH
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

import 'package:matrix/matrix.dart';

/// Type definition for event filter predicates.
/// Returns true if the event should be included, false otherwise.
typedef EventFilterPredicate = bool Function(Event event);

/// Common event filter predicates for filtering room events.
abstract class EventFilters {
  /// Filter that excludes redacted (deleted) events.
  static bool excludeRedacted(Event event) => !event.redacted;

  /// Filter that only includes message events (text, images, files, etc.).
  static bool onlyMessages(Event event) {
    return event.type == EventTypes.Message ||
        event.type == EventTypes.Encrypted ||
        event.type == EventTypes.Sticker;
  }

  /// Filter that excludes events with error status.
  static bool excludeErrors(Event event) {
    return event.status != EventStatus.error;
  }

  /// Filter that excludes events that are still sending.
  static bool excludeSending(Event event) {
    return event.status == EventStatus.synced ||
        event.status == EventStatus.roomState;
  }

  /// Filter that only includes synced events.
  static bool onlySynced(Event event) {
    return event.status == EventStatus.synced ||
        event.status == EventStatus.roomState;
  }

  /// Filter that excludes state events (membership changes, etc.).
  static bool excludeStateEvents(Event event) {
    return event.stateKey == null;
  }

  /// Combines multiple filters with AND logic.
  /// Returns true only if ALL filters return true.
  static EventFilterPredicate combineAnd(
      List<EventFilterPredicate> filters) {
    return (Event event) {
      for (final filter in filters) {
        if (!filter(event)) return false;
      }
      return true;
    };
  }

  /// Combines multiple filters with OR logic.
  /// Returns true if ANY filter returns true.
  static EventFilterPredicate combineOr(List<EventFilterPredicate> filters) {
    return (Event event) {
      for (final filter in filters) {
        if (filter(event)) return true;
      }
      return false;
    };
  }

  /// Default filter for chat list previews.
  /// Excludes redacted events, errors, and only shows messages.
  static final EventFilterPredicate defaultChatListFilter = combineAnd([
    excludeRedacted,
    onlyMessages,
    excludeErrors,
    onlySynced,
  ]);
}

/// Extension on Room class to provide flexible last event filtering.
extension RoomLastEventExtension on Room {
  /// Gets the last event from the timeline that matches the filter predicate.
  ///
  /// This method queries the database for recent timeline events and returns
  /// the most recent event that passes the filter.
  ///
  /// [filter] - A predicate function that returns true for events to include.
  ///           If null, uses [EventFilters.defaultChatListFilter].
  /// [limit] - Maximum number of events to fetch from database (default: 50).
  ///
  /// Returns the last matching event, or null if no events match.
  ///
  /// Example:
  /// ```dart
  /// // Get last non-redacted message
  /// final lastEvent = await room.getFilteredLastEvent();
  ///
  /// // Get last event with custom filter
  /// final lastEvent = await room.getFilteredLastEvent(
  ///   filter: (event) => !event.redacted && event.type == EventTypes.Message,
  /// );
  ///
  /// // Combine multiple filters
  /// final lastEvent = await room.getFilteredLastEvent(
  ///   filter: EventFilters.combineAnd([
  ///     EventFilters.excludeRedacted,
  ///     EventFilters.onlyMessages,
  ///     (event) => event.senderId != client.userID, // Exclude own messages
  ///   ]),
  /// );
  /// ```
  Future<Event?> getFilteredLastEvent({
    EventFilterPredicate? filter,
    int limit = 50,
  }) async {
    final db = client.database;
    if (db == null) {
      // Fallback to current lastEvent if no database
      final fallbackEvent = lastEvent;
      if (fallbackEvent == null) return null;

      final effectiveFilter = filter ?? EventFilters.defaultChatListFilter;
      return effectiveFilter(fallbackEvent) ? fallbackEvent : null;
    }

    // Use provided filter or default
    final effectiveFilter = filter ?? EventFilters.defaultChatListFilter;

    // Get recent events from database
    final events = await db.getEventList(
      this,
      start: 0,
      limit: limit,
    );

    // Filter and return the first (most recent) matching event
    for (final event in events) {
      if (effectiveFilter(event)) {
        return event;
      }
    }

    return null;
  }

  /// Synchronous version that checks the current lastEvent with a filter.
  ///
  /// This is less accurate than [getFilteredLastEvent] as it only checks
  /// the cached lastEvent from room state, but doesn't require async/await.
  ///
  /// [filter] - A predicate function that returns true for events to include.
  ///           If null, uses [EventFilters.defaultChatListFilter].
  ///
  /// Returns the last event if it matches the filter, null otherwise.
  Event? getFilteredLastEventSync({EventFilterPredicate? filter}) {
    final event = lastEvent;
    if (event == null) return null;

    final effectiveFilter = filter ?? EventFilters.defaultChatListFilter;
    return effectiveFilter(event) ? event : null;
  }

  /// Gets the display text for the last filtered event.
  ///
  /// This is a convenience method that combines [getFilteredLastEvent] with
  /// event text extraction, useful for displaying in chat list previews.
  ///
  /// [filter] - Optional filter predicate.
  /// [limit] - Maximum number of events to check (default: 50).
  /// [removeMarkdown] - Whether to remove markdown formatting (default: false).
  /// [removeBreakLine] - Whether to remove line breaks (default: true).
  ///
  /// Returns the display text, or null if no matching event found.
  Future<String?> getFilteredLastEventText({
    EventFilterPredicate? filter,
    int limit = 50,
    bool removeMarkdown = false,
    bool removeBreakLine = true,
  }) async {
    final event = await getFilteredLastEvent(filter: filter, limit: limit);
    if (event == null) return null;

    return event.calcLocalizedBodyFallback(
      MatrixDefaultLocalizations(),
      removeMarkdown: removeMarkdown,
      removeBreakLine: removeBreakLine,
    );
  }
}
