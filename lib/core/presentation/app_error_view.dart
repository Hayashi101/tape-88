import 'package:flutter/material.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({required this.details, super.key});
  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Colors.white,
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Đã có lỗi xảy ra. Vui lòng khởi động lại ứng dụng.',
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        ),
      ),
    ),
  );
}
