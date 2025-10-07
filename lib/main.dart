import 'package:flutter/material.dart';
import 'package:frontend/ui/views/home_view.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Image Editor',
      theme: ThemeData(useMaterial3: true),
      home: const HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
