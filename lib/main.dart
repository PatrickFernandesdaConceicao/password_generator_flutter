import 'package:flutter/material.dart';
import 'pages/password_generator_page.dart';

void main() => runApp(const PasswordApp());

class PasswordApp extends StatelessWidget {
  const PasswordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerador de Senhas',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const PasswordGeneratorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
