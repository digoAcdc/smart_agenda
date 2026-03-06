import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

class LoadingPlaceholderList extends StatelessWidget {
  const LoadingPlaceholderList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceMd,
        vertical: DesignTokens.spaceXs,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, separatorIndex) =>
          const SizedBox(height: DesignTokens.spaceSm),
      itemBuilder: (context, index) {
        return Container(
          height: DesignTokens.cardMinHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
        );
      },
    );
  }
}
