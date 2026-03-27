import 'package:flutter/material.dart';

import '../main.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(context, title: 'Export collection'),
      body: const Center(
        child: Text('Export functionality coming soon!'),
      ),
    );
  }
}
