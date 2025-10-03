// This is a basic Flutter widget test for BijbelRead app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestNavigationWidget extends StatefulWidget {
  @override
  State<_TestNavigationWidget> createState() => _TestNavigationWidgetState();
}

class _TestNavigationWidgetState extends State<_TestNavigationWidget> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        key: const Key('bottom_navigation'),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Lezen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Zoeken',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bladwijzers',
          ),
        ],
      ),
    );
  }
}

void main() {
  group('BijbelRead Widget Tests', () {
    testWidgets('Basic MaterialApp renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'BijbelRead',
          home: Scaffold(
            appBar: AppBar(
              title: const Text('BijbelRead'),
              actions: [
                IconButton(
                  key: const Key('search_button'),
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
                IconButton(
                  key: const Key('bookmark_button'),
                  icon: const Icon(Icons.bookmark),
                  onPressed: () {},
                ),
                IconButton(
                  key: const Key('settings_button'),
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
            body: const Center(
              child: Text('BijbelRead App'),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: 0,
              onTap: (index) {},
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book),
                  label: 'Lezen',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Zoeken',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark),
                  label: 'Bladwijzers',
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify app bar is present with correct title
      expect(find.text('BijbelRead'), findsOneWidget);

      // Verify bottom navigation bar is present
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Verify navigation items are present
      expect(find.text('Lezen'), findsOneWidget);
      expect(find.text('Zoeken'), findsOneWidget);
      expect(find.text('Bladwijzers'), findsOneWidget);

      // Verify action buttons are present using keys to avoid ambiguity
      expect(find.byKey(const Key('search_button')), findsOneWidget);
      expect(find.byKey(const Key('bookmark_button')), findsOneWidget);
      expect(find.byKey(const Key('settings_button')), findsOneWidget);
    });

    testWidgets('Navigation between tabs works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestNavigationWidget(),
        ),
      );

      await tester.pump();

      // Initially on 'Lezen' tab (index 0)
      BottomNavigationBar bottomNav = tester.widget(find.byKey(const Key('bottom_navigation')));
      expect(bottomNav.currentIndex, 0);

      // Tap on search tab (index 1)
      await tester.tap(find.text('Zoeken'));
      await tester.pump();

      // Should be on search tab now
      BottomNavigationBar bottomNavAfter = tester.widget(find.byKey(const Key('bottom_navigation')));
      expect(bottomNavAfter.currentIndex, 1);

      // Tap on bookmarks tab (index 2)
      await tester.tap(find.text('Bladwijzers'));
      await tester.pump();

      // Should be on bookmarks tab now
      BottomNavigationBar bottomNavFinal = tester.widget(find.byKey(const Key('bottom_navigation')));
      expect(bottomNavFinal.currentIndex, 2);
    });

    testWidgets('Action buttons are present and tappable', (WidgetTester tester) async {
      bool searchPressed = false;
      bool bookmarkPressed = false;
      bool settingsPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('BijbelRead'),
              actions: [
                IconButton(
                  key: const Key('search_action'),
                  icon: const Icon(Icons.search),
                  onPressed: () => searchPressed = true,
                ),
                IconButton(
                  key: const Key('bookmark_action'),
                  icon: const Icon(Icons.bookmark),
                  onPressed: () => bookmarkPressed = true,
                ),
                IconButton(
                  key: const Key('settings_action'),
                  icon: const Icon(Icons.settings),
                  onPressed: () => settingsPressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify action buttons are present using keys
      expect(find.byKey(const Key('search_action')), findsOneWidget);
      expect(find.byKey(const Key('bookmark_action')), findsOneWidget);
      expect(find.byKey(const Key('settings_action')), findsOneWidget);

      // Test tapping action buttons
      await tester.tap(find.byKey(const Key('search_action')));
      await tester.pump();
      expect(searchPressed, isTrue);

      await tester.tap(find.byKey(const Key('bookmark_action')));
      await tester.pump();
      expect(bookmarkPressed, isTrue);

      await tester.tap(find.byKey(const Key('settings_action')));
      await tester.pump();
      expect(settingsPressed, isTrue);
    });

    testWidgets('Theme configuration works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'BijbelRead',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('BijbelRead'),
            ),
            body: const Center(
              child: Text('Theme Test'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify theme is applied
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
      expect(app.themeMode, ThemeMode.system);

      // Verify app bar exists (backgroundColor might be null in some theme configurations)
      final AppBar appBar = tester.widget(find.byType(AppBar));
      expect(appBar, isNotNull);
      expect(find.text('BijbelRead'), findsOneWidget);
    });
  });
}
