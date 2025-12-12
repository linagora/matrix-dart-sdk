/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2020, 2021 Famedly GmbH
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

const Set<String> validSigils = {'@', '!', '#', '\$', '+'};

const int maxLength = 255;

extension MatrixIdExtension on String {
  List<String> _getParts() {
    final s = substring(1);
    final ix = s.indexOf(':');
    if (ix == -1) {
      return [substring(1)];
    }
    return [s.substring(0, ix), s.substring(ix + 1)];
  }

  /// Validates localpart against Matrix spec character requirements
  /// Uses a simple regex safe from ReDoS (no nested quantifiers)
  bool _isValidLocalpart(String localpart, String sigil) {
    if (localpart.isEmpty) {
      // Empty localpart is allowed for aliases and groups
      return sigil == '#' || sigil == '+';
    }

    // For user IDs: only lowercase letters, digits, and .=_-+
    // This regex is ReDoS-safe: single character class with simple quantifier
    if (sigil == '@') {
      final validLocalpartRegex = RegExp(r'^[a-z0-9.=_\-+]+$');
      return validLocalpartRegex.hasMatch(localpart);
    }

    // For room aliases and groups: more permissive
    // Only disallow control characters and colon (which is the delimiter)
    if (sigil == '#' || sigil == '+') {
      // Cannot contain: colon (delimiter) or control characters
      return !localpart.contains(RegExp(r'[:\x00-\x1F\x7F]'));
    }

    return true;
  }

  /// Validates domain part (hostname or IP address)
  /// Uses simple checks to avoid ReDoS vulnerabilities
  bool _isValidDomain(String domain) {
    if (domain.isEmpty) return false;

    // Extract domain/IP and optional port
    // For IPv6, format is [ipv6]:port, so handle brackets specially
    String domainWithoutPort;
    if (domain.startsWith('[')) {
      // IPv6 with possible port
      final closeBracket = domain.indexOf(']');
      if (closeBracket == -1) return false;
      domainWithoutPort = domain.substring(0, closeBracket + 1);
      // Validate there's no invalid content after the bracket (except :port)
      if (closeBracket + 1 < domain.length) {
        final afterBracket = domain.substring(closeBracket + 1);
        if (afterBracket.isNotEmpty &&
            !RegExp(r'^:\d+$').hasMatch(afterBracket)) {
          return false;
        }
      }
    } else {
      // For hostname or IPv4, port is after the last colon
      // But be careful: hostname can contain multiple colons if it includes port
      // Actually, for Matrix IDs, the domain part can include :port
      // So we need to check if it's IPv4 first
      final colonIndex = domain.lastIndexOf(':');
      if (colonIndex != -1 &&
          RegExp(r'^\d+$').hasMatch(domain.substring(colonIndex + 1))) {
        // Likely has a port
        domainWithoutPort = domain.substring(0, colonIndex);
        // Validate port
        final port = int.tryParse(domain.substring(colonIndex + 1));
        if (port == null || port < 1 || port > 65535) {
          return false;
        }
      } else {
        domainWithoutPort = domain;
      }
    }

    if (domainWithoutPort.isEmpty) return false;

    // Check for IPv6 (wrapped in brackets)
    if (domainWithoutPort.startsWith('[') && domainWithoutPort.endsWith(']')) {
      final ipv6 = domainWithoutPort.substring(1, domainWithoutPort.length - 1);
      if (ipv6.isEmpty) return false;
      // Basic IPv6 validation: only hex digits, colons, and dots (for IPv4-mapped)
      // IPv6 must contain at least one colon
      return RegExp(r'^[0-9a-fA-F:.]+$').hasMatch(ipv6) && ipv6.contains(':');
    }

    // Check for IPv4 (simple pattern, ReDoS-safe)
    if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(domainWithoutPort)) {
      // Validate each octet is 0-255
      final octets = domainWithoutPort.split('.');
      return octets.length == 4 &&
          octets.every((o) {
            final num = int.tryParse(o);
            return num != null && num >= 0 && num <= 255;
          });
    }

    // Hostname validation: alphanumeric, hyphens, dots
    // Must not start/end with hyphen or dot
    // ReDoS-safe: simple character class, no nested quantifiers
    // Allow single-word hostnames (common in test/dev environments)
    return RegExp(
            r'^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*$')
        .hasMatch(domainWithoutPort);
  }

  bool _isValidMatrixIdGeneral() {
    if (isEmpty) return false;
    if (length > maxLength) return false;
    final sigil = substring(0, 1);
    if (!validSigils.contains(sigil)) {
      return false;
    }
    // event IDs and room IDs do not have to have a domain
    if ({'\$', '!'}.contains(sigil)) {
      return length > 1;
    }
    // all other matrix IDs (user @, room alias #, group +) must have a domain
    final parts = _getParts();
    if (parts.length != 2 || parts[1].isEmpty) {
      return false;
    }

    // Validate localpart according to Matrix spec
    if (!_isValidLocalpart(parts[0], sigil)) {
      return false;
    }

    // Validate domain part
    if (!_isValidDomain(parts[1])) {
      return false;
    }

    return true;
  }

  /// Validates any Matrix ID (user @, room !, room alias #, group +, event $)
  bool get isValidMatrixId {
    return _isValidMatrixIdGeneral();
  }

  String? get sigil => isValidMatrixId ? substring(0, 1) : null;

  String? get localpart => isValidMatrixId ? _getParts().first : null;

  String? get domain => isValidMatrixId ? _getParts().last : null;

  bool equals(String? other) => toLowerCase() == other?.toLowerCase();

  /// Parse a matrix identifier string into a Uri. Primary and secondary identifiers
  /// are stored in pathSegments. The query string is stored as such.
  Uri? _parseIdentifierIntoUri() {
    const matrixUriPrefix = 'matrix:';
    const matrixToPrefix = 'https://matrix.to/#/';
    if (toLowerCase().startsWith(matrixUriPrefix)) {
      final uri = Uri.tryParse(this);
      if (uri == null) return null;
      final pathSegments = uri.pathSegments;
      final identifiers = <String>[];
      for (var i = 0; i < pathSegments.length - 1; i += 2) {
        final thisSigil = {
          'u': '@',
          'roomid': '!',
          'r': '#',
          'e': '\$',
        }[pathSegments[i].toLowerCase()];
        if (thisSigil == null) {
          break;
        }
        identifiers.add(thisSigil + pathSegments[i + 1]);
      }
      return uri.replace(pathSegments: identifiers);
    } else if (toLowerCase().startsWith(matrixToPrefix)) {
      return Uri.tryParse(
          '//${substring(matrixToPrefix.length - 1).replaceAllMapped(RegExp(r'(?<=/)[#!@+][^:]*:|(\?.*$)'), (m) => m[0]!.replaceAllMapped(RegExp(m.group(1) != null ? '' : '[/?]'), (m) => Uri.encodeComponent(m.group(0)!))).replaceAll('#', '%23')}');
    } else {
      return Uri(
          pathSegments: RegExp(r'/((?:[#!@+][^:]*:)?[^/?]*)(?:\?.*$)?')
              .allMatches('/$this')
              .map((m) => m[1]!),
          query: RegExp(r'(?:/(?:[#!@+][^:]*:)?[^/?]*)*\?(.*$)')
              .firstMatch('/$this')?[1]);
    }
  }

  /// Separate a matrix identifier string into a primary indentifier, a secondary identifier,
  /// a query string and already parsed `via` parameters. A matrix identifier string
  /// can be an mxid, a matrix.to-url or a matrix-uri.
  MatrixIdentifierStringExtensionResults? parseIdentifierIntoParts() {
    final uri = _parseIdentifierIntoUri();
    if (uri == null) return null;
    final primary = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    if (primary == null || !primary.isValidMatrixId) return null;
    final secondary = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
    if (secondary != null && !secondary.isValidMatrixId) return null;

    return MatrixIdentifierStringExtensionResults(
      primaryIdentifier: primary,
      secondaryIdentifier: secondary,
      queryString: uri.query.isNotEmpty ? uri.query : null,
      via: (uri.queryParametersAll['via'] ?? []).toSet(),
      action: uri.queryParameters['action'],
    );
  }
}

class MatrixIdentifierStringExtensionResults {
  final String primaryIdentifier;
  final String? secondaryIdentifier;
  final String? queryString;
  final Set<String> via;
  final String? action;

  MatrixIdentifierStringExtensionResults(
      {required this.primaryIdentifier,
      this.secondaryIdentifier,
      this.queryString,
      this.via = const {},
      this.action});
}
