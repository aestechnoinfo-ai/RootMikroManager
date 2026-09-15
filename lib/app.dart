import 'package:flutter/material.dart';

import 'core/navigation/router.dart';
import 'core/theme/app_theme.dart';

class RootMikroManagerApp extends StatelessWidget {
  const RootMikroManagerApp({super.key});

  static final _router = AppRouter.build();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'RootMikroManager',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: _router,
  );
}
