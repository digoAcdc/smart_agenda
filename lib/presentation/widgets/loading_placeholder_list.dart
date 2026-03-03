import 'package:flutter/material.dart';

class LoadingPlaceholderList extends StatelessWidget {
  const LoadingPlaceholderList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemCount,
      separatorBuilder: (_, separatorIndex) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 84,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
        );
      },
    );
  }
}
