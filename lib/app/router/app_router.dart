import 'package:flutter/material.dart';
import 'package:tape_88/features/shell/presentation/pages/app_shell_page.dart';

abstract final class AppRoutes {
  static const home = '/';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) =>
      switch (settings.name) {
        AppRoutes.home => MaterialPageRoute<void>(
          builder: (_) => const AppShellPage(),
          settings: settings,
        ),
        _ => MaterialPageRoute<void>(
          builder: (_) => const _UnknownRoutePage(),
          settings: settings,
        ),
      };
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Không tìm thấy trang')),
    body: const Center(child: Text('Đường dẫn không tồn tại.')),
  );
}
