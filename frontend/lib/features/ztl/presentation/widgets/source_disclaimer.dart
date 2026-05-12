import 'package:flutter/material.dart';

class SourceDisclaimer extends StatelessWidget {
  const SourceDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Rules can change. Always check Roma Mobilità before entering a ZTL.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF5D655F),
          ),
    );
  }
}
