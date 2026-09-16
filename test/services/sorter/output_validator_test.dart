import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/services/sorter/output_validator.dart';

void main() {
  const allowed = ['Work/Invoices', 'Newsletters', 'Family', 'Receipts', 'Projects/Apollo', 'Archive/Family'];
  final v = OutputValidator(allowedFolders: allowed, neverSort: const ['Trash', 'Sent', 'INBOX']);
  final ids = ['m1', 'm2', 'm3'];

  test('resolves paths case-insensitively and unique leaves; ambiguous leaves fail', () {
    expect(v.resolveFolder('work/invoices'), 'Work/Invoices');
    expect(v.resolveFolder('Invoices'), 'Work/Invoices');
    expect(v.resolveFolder('apollo'), 'Projects/Apollo');
    expect(v.resolveFolder('Family'), 'Family'); // exact path beats ambiguity
    expect(v.resolveFolder('family'), 'Family');
    expect(v.resolveFolder('Trash'), isNull);
    expect(v.resolveFolder('inbox'), 'INBOX');
    expect(v.resolveFolder('Nope'), isNull);
    expect(v.resolveFolder(42), isNull);
  });

  test('happy path, clamp, reason trimming, duplicates, unknown ids', () {
    final out = v.validate({
      'results': [
        {'id': 'm1', 'folder': 'Receipts', 'confidence': 1.7, 'reason': 'a\nb ' * 30},
        {'id': 'm1', 'folder': 'Family', 'confidence': 0.2, 'reason': 'dup'},
        {'id': 'm2', 'folder': 'Trash', 'confidence': 0.9, 'reason': 'x'},
        {'id': 'm9', 'folder': 'Family', 'confidence': 0.9, 'reason': 'x'},
        {'id': 'm3', 'folder': 'INBOX', 'confidence': '0.4', 'reason': null},
      ]
    }, ids);
    expect(out.malformed, isFalse);
    expect(out.results['m1']!.folder, 'Receipts');
    expect(out.results['m1']!.confidence, 1.0);
    expect(out.results['m1']!.reason.split(' ').length, lessThanOrEqualTo(15));
    expect(out.results['m1']!.reason, isNot(contains('\n')));
    expect(out.results['m2']!.folder, 'INBOX');
    expect(out.results['m2']!.resolved, isFalse);
    expect(out.results['m2']!.reason, '[unknown folder]');
    expect(out.results['m3']!.confidence, 0.4);
    expect(out.unknownIds, ['m9']);
    expect(out.missingIds, isEmpty);
  });

  test('missing results list is malformed; missing ids are reported', () {
    expect(v.validate(null, ids).malformed, isTrue);
    expect(v.validate({'foo': 1}, ids).malformed, isTrue);
    expect(v.validate({'results': 'x'}, ids).malformed, isTrue);
    final out = v.validate({'results': [{'id': 'm2', 'folder': 'Family', 'confidence': 0.5, 'reason': ''}]}, ids);
    expect(out.malformed, isFalse);
    expect(out.missingIds, ['m1', 'm3']);
  });

  test('property: random junk never throws and every result is well-formed', () {
    final rng = Random(42);
    final okFolders = {...allowed, 'INBOX'};
    Object? junk(int depth) {
      switch (rng.nextInt(depth > 3 ? 6 : 9)) {
        case 0:
          return null;
        case 1:
          return rng.nextDouble() * 4 - 2;
        case 2:
          return rng.nextBool() ? double.nan : double.infinity;
        case 3:
          return ['m1', 'm2', 'm3', 'm4', 'zz', 'Receipts', 'trash', 'invoices', 'x' * 300, ''][rng.nextInt(10)];
        case 4:
          return rng.nextInt(100);
        case 5:
          return rng.nextBool();
        case 6:
          return [for (var i = 0; i < rng.nextInt(5); i++) junk(depth + 1)];
        default:
          return {
            for (var i = 0; i < rng.nextInt(6); i++) ['id', 'folder', 'confidence', 'reason', 'results', 'x'][rng.nextInt(6)]: junk(depth + 1),
          };
      }
    }

    for (var i = 0; i < 2000; i++) {
      final input = junk(0);
      final json = input is Map<String, dynamic> ? input : (input is Map ? input.cast<String, dynamic>() : null);
      final out = v.validate(json, ids);
      expect(out.results.length + out.missingIds.length, ids.length);
      for (final id in ids) {
        expect(out.results.containsKey(id) != out.missingIds.contains(id), isTrue);
      }
      for (final r in out.results.values) {
        expect(ids, contains(r.id));
        expect(okFolders, contains(r.folder));
        expect(r.confidence, inInclusiveRange(0.0, 1.0));
        expect(r.confidence.isNaN, isFalse);
        expect(r.reason.length, lessThanOrEqualTo(120));
        expect(r.reason, isNot(contains('\n')));
      }
      // must also survive a JSON round trip of the same junk
      final encoded = jsonEncode(json, toEncodable: (o) => o.toString());
      v.validate(jsonDecode(encoded) as Map<String, dynamic>?, ids);
    }
  });
}
