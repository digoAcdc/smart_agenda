import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_agenda/core/theme/app_theme.dart';
import 'package:smart_agenda/presentation/pages/home_page.dart';

void main() {
  const labels = ['Início', 'Agenda', 'Matérias', 'Mais', 'Config'];

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('barra mostra os nomes em tela estreita (fonte x$scale)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 640),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox(
                    height: 62,
                    child: Row(
                      children: [
                        for (var i = 0; i < labels.length; i++)
                          Expanded(
                            child: HomeNavItem(
                              icon: Icons.home_rounded,
                              label: labels[i],
                              isActive: i == 2,
                              onTap: () {},
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
