/// Encodes an untrusted text cell while preventing spreadsheet formulas.
///
/// CSV quoting protects the file structure, but spreadsheet applications may
/// still execute cells beginning with formula operators. A leading apostrophe
/// forces untrusted text to remain text. Numeric-looking identifiers, phone
/// numbers, and invoice numbers stay text because their column is textual.
String spreadsheetSafeCsvTextCell(String value) {
  final startsWithControl =
      value.startsWith('\t') ||
      value.startsWith('\r') ||
      value.startsWith('\n');
  final candidate = value.replaceFirst(RegExp(r'^[ \t\r\n]+'), '');
  final startsWithOperator =
      candidate.isNotEmpty && const {'=', '+', '-', '@'}.contains(candidate[0]);
  final safeValue = startsWithControl || startsWithOperator ? "'$value" : value;
  return '"${safeValue.replaceAll('"', '""')}"';
}

/// Encodes a known numeric column without quoting so spreadsheets keep its type.
String spreadsheetSafeCsvNumberCell(String value) {
  final normalized = value.trim();
  final parsed = double.tryParse(normalized);
  if (parsed == null ||
      !parsed.isFinite ||
      !RegExp(r'^-?\d+(?:\.\d+)?$').hasMatch(normalized)) {
    throw FormatException('CSV numeric cell is invalid', value);
  }
  return normalized;
}
