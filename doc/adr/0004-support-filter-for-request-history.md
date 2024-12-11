# 4. Support filter for request history

Date: 2024-12-09

## Status

Accepted

- Issue: [#1862](https://github.com/linagora/twake-on-matrix/issues/1862)

## Context

- The date of the last message in chat list display is not correct.
- The message in chat screen is not displayed correctly so block user by empty screen.

## Decision

- Add `StateFilter` to request history to request specific data from the server.

## Consequences

- The `timeLine` and `event` can be filtered by the user to get specific data from the server.
- Display the correct message in chat screen. Prevent block user by empty screen.
- In the chat list, we improve the display date time of the last message soon.
