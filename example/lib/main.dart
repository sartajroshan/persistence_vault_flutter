import 'package:flutter/material.dart';
import 'package:persistence_vault/persistence_vault.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PersistenceVault.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('PV Demo')),
        body: const Demo(),
      ),
    );
  }
}

class Demo extends StatefulWidget {
  const Demo({super.key});

  @override
  State<Demo> createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  final _key = 'user_id';
  String? _val, _androidId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _val = await PersistenceVault.I.readString(_key);
    _androidId = await PersistenceVault.I.readAndroidId();
    setState(() {});
  }

  Future<void> _save() async {
    await PersistenceVault.I.writeString(_key, 'U123456');
    await _load();
  }

  Future<void> _del() async {
    await PersistenceVault.I.delete(_key);
    await _load();
  }

  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Stored: ${_val ?? "(none)"}'),
        const SizedBox(height: 12),
        SelectableText('Android ID: ${_androidId ?? "(none)"}'),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
        ElevatedButton(onPressed: _del, child: const Text('Delete')),
      ],
    ),
  );
}
