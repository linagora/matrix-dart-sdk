# 5. Support store members in hive

Date: 2024-12-23

## Status

Accepted

- Issue: [#2165](https://github.com/linagora/twake-on-matrix/issues/2165)

## Context

- Not all of the members are displayed in the drop-down list
- The members only store in the memory, so when the user refreshes the page, the members are lost.

## Decision

- Store the members in the hive to keep the members when the user refreshes the page.
- Add some properties to request the members from the server.

```dart

Future<List<User>> requestParticipantsFromServer({
    List<Membership> membershipFilter = displayMembershipsFilter,
    bool suppressWarning = false,
    bool cache = true,
    String? at,
    Membership? membership,
    Membership? notMembership,
  }) {}

```

- `at`: The point in time (pagination token) to return members for in the room. 
This token can be obtained from a prev_batch token returned for each room by the sync API. 
Defaults to the current state of the room, as determined by the server.

- `membership`: The kind of membership to filter for. Defaults to no filtering if unspecified. 
When specified alongside `not_membership`, the two parameters create an ‘or’ condition: either the membership is the same as `membership` or is not the same as `not_membership`.

- `notMembership`: The kind of membership to exclude from the results. Defaults to no filtering if unspecified.

## Consequences

- The members are stored in the hive, so the members are not lost when the user refreshes the page.
