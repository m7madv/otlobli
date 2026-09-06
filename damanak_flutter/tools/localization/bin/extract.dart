import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:crypto/crypto.dart';

final arabic = RegExp(r'[\u0600-\u06ff]');

class Collector extends RecursiveAstVisitor<void> {
  Collector(this.path);
  final String path;
  final List<Map<String, dynamic>> entries = [];
  final List<Map<String, dynamic>> excluded = [];

  void collect(StringLiteral node) {
    if (node.parent is AdjacentStrings || node.parent is StringInterpolation) return;
    final parts = <String>[];
    final arguments = <String>[];
    void flatten(StringLiteral value) {
      if (value is SimpleStringLiteral) {
        parts.add(value.value);
      } else if (value is AdjacentStrings) {
        for (final child in value.strings) { flatten(child); }
      } else if (value is StringInterpolation) {
        for (final element in value.elements) {
          if (element is InterpolationString) parts.add(element.value);
          if (element is InterpolationExpression) {
            parts.add('{p${arguments.length}}');
            arguments.add(element.expression.toSource());
          }
        }
      }
    }
    flatten(node);
    final template = parts.join();
    if (!arabic.hasMatch(template)) return;
    final id = 'msg${sha256.convert(utf8.encode(template)).toString().substring(0, 12)}';
    final parents = <String>[];
    for (AstNode? parent = node.parent; parent != null; parent = parent.parent) {
      parents.add(parent.runtimeType.toString());
    }
    entries.add({
      'id': id, 'text': template, 'arguments': arguments,
      'file': path, 'offset': node.offset, 'length': node.length,
      'parents': parents.take(8).toList(),
      'source': node.parent?.toSource(),
    });
  }

  @override void visitSimpleStringLiteral(SimpleStringLiteral node) {
    collect(node); super.visitSimpleStringLiteral(node);
  }
  @override void visitStringInterpolation(StringInterpolation node) {
    collect(node); super.visitStringInterpolation(node);
  }
  @override void visitAdjacentStrings(AdjacentStrings node) {
    collect(node); super.visitAdjacentStrings(node);
  }
}

void main(List<String> args) {
  final root = Directory(args.isEmpty ? '../../lib' : args.first);
  final entries = <Map<String, dynamic>>[];
  for (final file in root.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart') || file.path.contains('l10n')) continue;
    final parsed = parseString(content: file.readAsStringSync(), path: file.path);
    final collector = Collector(file.path.replaceAll('\\', '/'));
    parsed.unit.accept(collector);
    entries.addAll(collector.entries);
  }
  final output = File('extraction.json');
  output.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(entries));
  stdout.writeln('${entries.length} occurrences; ${entries.map((e) => e['id']).toSet().length} unique messages');
}
