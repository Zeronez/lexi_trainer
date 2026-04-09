import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/app/app.dart';

void main() {
  testWidgets('renders home placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.text('Lexi Trainer'), findsOneWidget);
    expect(find.text('Start training'), findsOneWidget);
    expect(find.text('Weekly progress'), findsOneWidget);
  });
}
