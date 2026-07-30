import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart';

enum PlacementStage {
  applied,
  shortlisted,
  interview,
  offer,
}

extension PlacementStageX on PlacementStage {
  String get displayName {
    switch (this) {
      case PlacementStage.applied:
        return 'Applied';
      case PlacementStage.shortlisted:
        return 'Shortlisted';
      case PlacementStage.interview:
        return 'Interview';
      case PlacementStage.offer:
        return 'Offer';
    }
  }

  int get indexValue => index;
}

/// PlacementConnect Signature UI Element: The Status Thread.
class StatusThreadWidget extends StatelessWidget {
  final PlacementStage currentStage;
  final bool isCompact;

  const StatusThreadWidget({
    super.key,
    required this.currentStage,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brassColor = brandTheme?.brassPrimary ?? theme.colorScheme.primary;
    final borderColor = brandTheme?.cardBorder ?? theme.colorScheme.outline;

    if (isCompact) {
      return _buildCompactThread(brassColor, borderColor);
    }

    return _buildFullThread(context, brassColor, borderColor);
  }

  Widget _buildFullThread(BuildContext context, Color brassColor, Color borderColor) {
    final stages = PlacementStage.values;
    final currentIdx = currentStage.indexValue;
    final progressRatio = currentIdx / (stages.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Track background line
                Container(
                  height: 2,
                  width: double.infinity,
                  color: borderColor,
                ),
                // Filled progress line
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressRatio,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          brassColor,
                          const Color(0xFFC89446),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: brassColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Nodes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: stages.map((stage) {
                    final isDone = stage.indexValue <= currentIdx;
                    final isCurrent = stage.indexValue == currentIdx;

                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? brassColor : Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: isDone || isCurrent ? brassColor : borderColor,
                          width: 2,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: brassColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stages.map((stage) {
                final isDone = stage.indexValue <= currentIdx;
                return SizedBox(
                  width: 65,
                  child: Text(
                    stage.displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                      color: isDone
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactThread(Color brassColor, Color borderColor) {
    final stages = PlacementStage.values;
    final currentIdx = currentStage.indexValue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: stages.map((stage) {
        final isDone = stage.indexValue <= currentIdx;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? brassColor : borderColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}
