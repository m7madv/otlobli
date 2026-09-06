import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'extract.dart' show Collector;

class Nodes extends RecursiveAstVisitor<void> {
  final byOffset = <int, StringLiteral>{};
  final builds = <BlockFunctionBody>[];
  @override void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'build' && node.body is BlockFunctionBody) builds.add(node.body as BlockFunctionBody);
    super.visitMethodDeclaration(node);
  }
  @override void visitSimpleStringLiteral(SimpleStringLiteral node) { byOffset[node.offset] = node; super.visitSimpleStringLiteral(node); }
  @override void visitStringInterpolation(StringInterpolation node) { byOffset[node.offset] = node; super.visitStringInterpolation(node); }
  @override void visitAdjacentStrings(AdjacentStrings node) { super.visitAdjacentStrings(node); byOffset[node.offset] = node; }
}

void main(List<String> args) {
  final root = Directory('../../lib');
  final saved = File('catalog.json');
  final catalog = saved.existsSync()
      ? (jsonDecode(saved.readAsStringSync()) as Map<String,dynamic>).map((key,value)=>MapEntry(key,Map<String,dynamic>.from(value as Map)))
      : <String, Map<String, dynamic>>{};
  final skipped = <Map<String, dynamic>>[];
  final migrate = args.contains('--apply');
  for (final file in root.listSync(recursive:true).whereType<File>()) {
    final path = file.path.replaceAll('\\','/');
    if (!path.endsWith('.dart') || path.contains('/l10n/') || path.contains('/data/')) continue;
    final source = file.readAsStringSync();
    final unit = parseString(content:source).unit;
    final collector = Collector(path); unit.accept(collector);
    final nodes = Nodes(); unit.accept(nodes);
    final edits = <int, ({int length, String text})>{};
    final replacements = <({int start,int end})>[];
    for (final entry in collector.entries) {
      catalog[entry['id'] as String] = entry;
      final node = nodes.byOffset[entry['offset']]!;
      if (node.parent is ArgumentList && node.parent!.parent is MethodInvocation && (node.parent!.parent as MethodInvocation).methodName.name == 'knownLabel') continue;
      bool skip = false;
      bool isGetter = false;
      for (AstNode? parent = node.parent; parent != null; parent = parent.parent) {
        if (parent is StringLiteral || parent is DefaultFormalParameter || parent is Annotation || parent is ConstantPattern) skip = true;
        if (parent is MethodDeclaration && parent.isGetter) isGetter = true;
        if (parent is FieldDeclaration || parent is TopLevelVariableDeclaration) skip = true;
      }
      if (path.contains('/models/') && !isGetter) skip = true;
      if (path.endsWith('/core/currency.dart')) skip = true;
      if (skip) { skipped.add(entry); continue; }
      final arguments = (entry['arguments'] as List).cast<String>();
      final call = 'L10n.current.${entry['id']}${arguments.isEmpty ? '' : '(${arguments.join(', ')})'}';
      edits[node.offset] = (length:node.length,text:call);
      replacements.add((start:node.offset,end:node.end));
      for (AstNode? parent = node.parent; parent != null; parent = parent.parent) {
        if (parent is InstanceCreationExpression && parent.keyword?.lexeme == 'const') {
          edits[parent.keyword!.offset] = (length:parent.keyword!.length,text:'');
        }
        if (parent is TypedLiteral && parent.constKeyword != null) {
          edits[parent.constKeyword!.offset] = (length:parent.constKeyword!.length,text:'');
        }
        if (parent is VariableDeclarationList && parent.keyword?.lexeme == 'const') {
          edits[parent.keyword!.offset] = (length:parent.keyword!.length,text:'final');
        }
      }
    }
    if (edits.isEmpty || !migrate) continue;
    for (final body in nodes.builds.where((body)=> !body.toSource().contains('L10n.watch(context)'))) {
      edits[body.block.leftBracket.end] = (length:0,text:'\n    L10n.watch(context);');
    }
    var output = source;
    final offsets = edits.keys.where((offset) => !replacements.any((r) => offset > r.start && offset < r.end)).toList()..sort((a,b)=>b.compareTo(a));
    for (final offset in offsets) {
      final edit = edits[offset]!;
      output = output.replaceRange(offset, offset+edit.length, edit.text);
    }
    if (!output.contains("import 'package:damanak/l10n/l10n.dart';")) output = "import 'package:damanak/l10n/l10n.dart';\n$output";
    file.writeAsStringSync(output);
  }
  File('catalog.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(catalog));
  File('skipped.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(skipped));
  stdout.writeln('${catalog.length} catalog messages; ${skipped.length} unmodified data/default/constant occurrences');
}
