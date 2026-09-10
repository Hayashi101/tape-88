import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tape 88')),
    body: const Center(
      child: Text('Không gian âm nhạc của bạn đang được chuẩn bị.'),
    ),
  );
}
