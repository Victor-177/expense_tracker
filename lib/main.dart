import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Трекер Расходов',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF), // Неоновый голубой
          secondary: Color(0xFFBB86FC),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';
  
  // База данных в памяти
  List<Map<String, dynamic>> expenses = [
    {'id': 1, 'amount': 1500.0, 'category': 'Продукты', 'date': '20.05.2024', 'recipient': 'Пятерочка', 'method': 'Карта', 'tripName': 'Москва'},
    {'id': 2, 'amount': 800.0, 'category': 'Кафе', 'date': '21.05.2024', 'recipient': 'Вкусно и точка', 'method': 'Карта', 'tripName': 'Москва'},
    {'id': 3, 'amount': 350.0, 'category': 'Транспорт', 'date': '22.05.2024', 'recipient': 'Метро', 'method': 'Наличные', 'tripName': null},
  ];

  List<Map<String, dynamic>> trips = [
    {'id': 1, 'name': 'Москва', 'start': '12.05.2024', 'end': '15.05.2024'}
  ];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Продукты': return Icons.shopping_basket;
      case 'Кафе': return Icons.local_cafe;
      case 'Транспорт': return Icons.directions_bus;
      case 'Одежда': return Icons.checkroom;
      case 'Развлечение': return Icons.movie;
      default: return Icons.receipt_long;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Продукты': return Colors.greenAccent;
      case 'Кафе': return Colors.orangeAccent;
      case 'Транспорт': return Colors.blueAccent;
      case 'Одежда': return Colors.purpleAccent;
      case 'Развлечение': return Colors.pinkAccent;
      default: return Colors.grey;
    }
  }

  // --- ОКНО СОЗДАНИЯ КОМАНДИРОВКИ ---
  void _showAddTripSheet() {
    String name = '';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 3));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Новая командировка', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Название (город)', border: OutlineInputBorder()),
                    onChanged: (val) => name = val,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (picked != null) setSheetState(() => startDate = picked);
                          },
                          child: Text('С: ${startDate.day}.${startDate.month}.${startDate.year}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (picked != null) setSheetState(() => endDate = picked);
                          },
                          child: Text('По: ${endDate.day}.${endDate.month}.${endDate.year}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.black),
                      onPressed: () {
                        if (name.isNotEmpty) {
                          setState(() {
                            trips.add({
                              'id': DateTime.now().millisecondsSinceEpoch,
                              'name': name,
                              'start': '${startDate.day}.${startDate.month}.${startDate.year}',
                              'end': '${endDate.day}.${endDate.month}.${endDate.year}',
                            });
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Создать', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- ОКНО ДОБАВЛЕНИЯ / РЕДАКТИРОВАНИЯ ТРАТЫ ---
  void _showExpenseSheet([Map<String, dynamic>? existingExpense]) {
    String amount = existingExpense != null ? existingExpense['amount'].toString() : '';
    String recipient = existingExpense != null ? existingExpense['recipient'] : '';
    String category = existingExpense != null ? existingExpense['category'] : 'Продукты';
    String method = existingExpense != null ? existingExpense['method'] : 'Карта';
    String? selectedTrip = existingExpense != null ? existingExpense['tripName'] : null;
    
    DateTime selectedDate = existingExpense != null 
        ? DateTime.parse(existingExpense['date'].split('.').reversed.join('-')) 
        : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existingExpense == null ? 'Новая трата' : 'Редактировать', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: TextEditingController(text: amount),
                      decoration: const InputDecoration(labelText: 'Сумма (₽)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => amount = val,
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: TextEditingController(text: recipient),
                      decoration: const InputDecoration(labelText: 'Получатель', border: OutlineInputBorder()),
                      onChanged: (val) => recipient = val,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
                            items: ['Продукты', 'Кафе', 'Транспорт', 'Одежда', 'Развлечение']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setSheetState(() => category = val!),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: method,
                            decoration: const InputDecoration(labelText: 'Оплата', border: OutlineInputBorder()),
                            items: ['Карта', 'Наличные', 'QR-code']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setSheetState(() => method = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Выбор командировки
                    DropdownButtonFormField<String?>(
                      initialValue: selectedTrip,
                      decoration: const InputDecoration(labelText: 'Командировка (необязательно)', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Без командировки')),
                        ...trips.map((t) => DropdownMenuItem(value: t['name'] as String, child: Text(t['name']))),
                      ],
                      onChanged: (val) => setSheetState(() => selectedTrip = val),
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text('Дата: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}'),
                      onPressed: () async {
                        final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (picked != null) setSheetState(() => selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.black),
                        onPressed: () {
                          setState(() {
                            final formattedDate = '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}';
                            if (existingExpense == null) {
                              expenses.insert(0, {
                                'id': DateTime.now().millisecondsSinceEpoch,
                                'amount': double.tryParse(amount) ?? 0.0,
                                'category': category,
                                'date': formattedDate,
                                'recipient': recipient.isEmpty ? 'Неизвестно' : recipient,
                                'method': method,
                                'tripName': selectedTrip,
                              });
                            } else {
                              existingExpense['amount'] = double.tryParse(amount) ?? 0.0;
                              existingExpense['category'] = category;
                              existingExpense['date'] = formattedDate;
                              existingExpense['recipient'] = recipient.isEmpty ? 'Неизвестно' : recipient;
                              existingExpense['method'] = method;
                              existingExpense['tripName'] = selectedTrip;
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Сохранить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- ИМИТАЦИЯ ИМПОРТА CSV ---
  void _mockImportCSV() {
    setState(() {
      expenses.insertAll(0, [
        {'id': DateTime.now().millisecondsSinceEpoch + 1, 'amount': 120.0, 'category': 'Кафе', 'date': '01.06.2024', 'recipient': 'Импорт: Кофейня', 'method': 'Наличные', 'tripName': null},
        {'id': DateTime.now().millisecondsSinceEpoch + 2, 'amount': 550.0, 'category': 'Продукты', 'date': '02.06.2024', 'recipient': 'Импорт: Магнит', 'method': 'Карта', 'tripName': null},
      ]);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Импортировано 2 траты из CSV!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Мои расходы' : _currentIndex == 1 ? 'Дашборд' : 'Командировки'),
        centerTitle: true,
        actions: [
          if (_currentIndex == 0)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'import') _mockImportCSV();
              },
              itemBuilder: (BuildContext context) {
                return [const PopupMenuItem(value: 'import', child: Text('Импорт CSV'))];
              },
            ),
        ],
      ),
      body: _currentIndex == 0 ? _buildList() : _currentIndex == 1 ? _buildDashboard() : _buildTrips(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showExpenseSheet(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              child: const Icon(Icons.add, size: 30),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Траты'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Дашборд'),
          NavigationDestination(icon: Icon(Icons.flight_takeoff), label: 'Поездки'),
        ],
      ),
    );
  }

  // --- ЭКРАН 1: СПИСОК ТРАТ ---
  Widget _buildList() {
    final filtered = expenses.where((e) => e['recipient'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск по получателю...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final exp = filtered[index];
              return Dismissible(
                key: Key(exp['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  setState(() => expenses.removeWhere((e) => e['id'] == exp['id']));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Трата удалена')));
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () => _showExpenseSheet(exp),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: _getCategoryColor(exp['category']).withValues(alpha: 0.2),
                      child: Icon(_getCategoryIcon(exp['category']), color: _getCategoryColor(exp['category'])),
                    ),
                    title: Text(exp['recipient'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${exp['category']} • ${exp['method']} • ${exp['date']}'),
                        if (exp['tripName'] != null)
                          Text('✈️ ${exp['tripName']}', style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Text(
                      '${exp['amount'].toInt()} ₽',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- ЭКРАН 2: ДАШБОРД ---
  Widget _buildDashboard() {
    double total = expenses.fold(0.0, (sum, item) => sum + (item['amount'] as double));
    Map<String, double> catTotals = {};
    for (var exp in expenses) {
      catTotals[exp['category']] = (catTotals[exp['category']] ?? 0.0) + (exp['amount'] as double);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF007BFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Всего потрачено', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: total),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text('${value.toInt()} ₽', style: const TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.bold));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (total > 0)
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: DonutChartPainter(catTotals, total, _getCategoryColor),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(catTotals.length.toString(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        const Text('категорий', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text('Детализация', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: ListView(
              children: catTotals.entries.map((entry) {
                double percent = entry.value / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: _getCategoryColor(entry.key), shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.key)),
                      Text('${(percent * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 20),
                      Text('${entry.value.toInt()} ₽', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- ЭКРАН 3: КОМАНДИРОВКИ ---
  Widget _buildTrips() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: trips.isEmpty 
              ? const Center(child: Text('У вас пока нет командировок', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    // Считаем сумму трат для этой командировки
                    final tripExpenses = expenses.where((e) => e['tripName'] == trip['name']);
                    final tripTotal = tripExpenses.fold(0.0, (sum, item) => sum + (item['amount'] as double));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(trip['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const Icon(Icons.flight_takeoff, color: Colors.blueAccent),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('${trip['start']} - ${trip['end']}', style: const TextStyle(color: Colors.grey)),
                            const Divider(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Потрачено:'),
                                Text('${tripTotal.toInt()} ₽', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _showAddTripSheet,
              icon: const Icon(Icons.add),
              label: const Text('Создать командировку'),
            ),
          )
        ],
      ),
    );
  }
}

// --- КЛАСС ДЛЯ РИСОВАНИЯ КРУГОВОЙ ДИАГРАММЫ ---
class DonutChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double total;
  final Color Function(String) colorResolver;

  DonutChartPainter(this.data, this.total, this.colorResolver);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30.0;

    double startAngle = -pi / 2;
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double radius = min(centerX, centerY) - paint.strokeWidth / 2;

    for (var entry in data.entries) {
      double sweepAngle = (entry.value / total) * 2 * pi;
      paint.color = colorResolver(entry.key);
      
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
