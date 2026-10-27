import 'package:flutter/material.dart';

/// Composition root. Feature navigation and dependencies enter here as flows land.
class TataApp extends StatelessWidget {
  const TataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Tata',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(child: Center(child: Text('Tata'))),
      ),
    );
  }
}
