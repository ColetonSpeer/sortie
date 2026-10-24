import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/services/compose/dash_free.dart';

void main() {
  test('dashes used as punctuation become commas; hyphens in words, numbers and lists stay', () {
    expect(dashFree('We can do Thursday — or Friday if that is easier.'), 'We can do Thursday, or Friday if that is easier.');
    expect(dashFree('Two items – both urgent -- for you.'), 'Two items, both urgent, for you.');
    expect(dashFree('The plan is simple - we wait.'), 'The plan is simple, we wait.');
    expect(dashFree('A quick follow-up on the on-site visit.'), 'A quick follow-up on the on-site visit.');
    expect(dashFree('Call (724) 356-2211 between 9:00 - 10:00.'), 'Call (724) 356-2211 between 9:00 - 10:00.');
    expect(dashFree('Items:\n- phone lines\n- ONT customers'), 'Items:\n- phone lines\n- ONT customers');
    expect(dashFree('I will send it today —\nThanks'), 'I will send it today\nThanks');
    expect(dashFree('— Coleton'), 'Coleton');
    expect(dashFree('It works — .'), 'It works.');
    expect(dashFree(''), '');
  });
}
