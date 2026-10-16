import 'package:flutter_test/flutter_test.dart';

import 'package:resq_mitra/main.dart';

void main() {
  testWidgets('RESQ-MITRA app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const ResqMitraApp());
    expect(find.text('RESQ-MITRA'), findsWidgets);
  });
}
