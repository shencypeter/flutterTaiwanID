import 'package:flutter/material.dart';
import 'taiwan_id_logic.dart';

void main() {
  runApp(const TaiwanIdApp());
}

class TaiwanIdApp extends StatelessWidget {
  const TaiwanIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const TaiwanIdScreen(),
    );
  }
}

class TaiwanIdScreen extends StatefulWidget {
  const TaiwanIdScreen({super.key});

  @override
  State<TaiwanIdScreen> createState() => _TaiwanIdScreenState();
}

class _TaiwanIdScreenState extends State<TaiwanIdScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<String> history = [];

  void _analyze() {
    final input = controller.text.trim();
    if (input.isEmpty) return;


    setState(() {
      history.add(input + ": " + analyzeInput(input));
      controller.clear();
    });

    // Auto-scroll (Compose LaunchedEffect equivalent)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '台灣身分證解析器',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(history[index]),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: '輸入身分證號',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _analyze(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _analyze,
                child: const Text('解析'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
