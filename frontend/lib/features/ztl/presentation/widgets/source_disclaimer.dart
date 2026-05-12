import 'package:flutter/material.dart';

class SourceDisclaimer extends StatelessWidget {
  const SourceDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Official rules may change. Check the official city source before entering.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF5D655F),
          ),
    );
  }
}
