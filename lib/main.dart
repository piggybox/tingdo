import 'package:flutter/material.dart';

import 'data/store.dart';
import 'data/store_scope.dart';
import 'screens/home_shell.dart';
import 'screens/new_habit_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(TingdoApp(store: store));
}

class TingdoApp extends StatelessWidget {
  const TingdoApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'TingDo',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    if (!store.isLoaded) {
      return const Scaffold(body: SizedBox.shrink());
    }
    if (store.isEmpty) {
      return const NewHabitScreen(isFirstHabit: true);
    }
    return const HomeShell();
  }
}
