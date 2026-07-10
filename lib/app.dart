import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/screens/home_shell.dart';
import 'ui/state/tag_request_list_controller.dart';
import 'ui/state/truck_list_controller.dart';
import 'ui/theme/app_theme.dart';

class BayTrackerApp extends StatelessWidget {
  const BayTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TruckListController()..load()),
        ChangeNotifierProvider(
            create: (_) => TagRequestListController()..load()),
      ],
      child: MaterialApp(
        title: 'Graphics Bay Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      ),
    );
  }
}
