import 'package:flutter/material.dart';
import 'proxvel_empty_state.dart';

class EmptyView extends StatelessWidget {
  final String message;
  const EmptyView({super.key, required this.message});

  @override
  Widget build(BuildContext context) => ProxvelEmptyState(
    icon: Icons.explore_outlined,
    title: message,
    subtitle: '',
  );
}
