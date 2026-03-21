import 'package:flutter/material.dart';

import 'stat_card.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StatCard(
      title: 'Reports',
      value: 'View sleep history',
      icon: Icons.description,
      onTap: onTap,
    );
  }
}

