import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Трекер Расходов',
      theme: ThemeData.dark(),
      home: const ExpenseHomePage(),
    );
  }
}

class ExpenseHomePage extends StatelessWidget {
  const ExpenseHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои расходы')),
      body: const Center(
        child: Text('Здесь будет список трат', style: TextStyle(fontSize: 20)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
