# 3. 0003-improve-get-event-content-from-message-text.md

Date: 2024-12-08

## Status

Accepted

## Context

- The current implementation includes parsing the message for markdown, converting line breaks, and
  formatting the message if necessary.

## Decision

- We will refactor the getEventContentFromMsgText function to improve its readability and structure.
  The changes include:
    1. Extracting the markdown conversion logic into a separate function.
    2. Simplifying the line break conversion and formatting check.

## Consequences

- The function will be easier to read and maintain.
- The logic for markdown conversion and line break handling will be more modular and reusable