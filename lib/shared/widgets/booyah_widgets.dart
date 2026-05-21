import 'package:flutter/material.dart';
import '../../core/theme.dart';

// ── Section Header ──
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 3, height: 16,
          decoration: BoxDecoration(
            color: BooyahTheme.maroonB,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [const BoxShadow(color: BooyahTheme.maroonB, blurRadius: 5)],
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
          fontFamily: 'Rajdhani', fontSize: 13,
          fontWeight: FontWeight.w700,
        )),
        if (action != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: const TextStyle(
              fontSize: 10, color: BooyahTheme.maroonB, fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    ),
  );
}

// ── Status Badge ──
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;

  const StatusBadge({super.key, required this.label, required this.color, this.showDot = true});

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDot) ...[
          Container(width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
        ],
        Text(label, style: TextStyle(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.5,
        )),
      ],
    ),
  );
}

// ── Booyah Button ──
class BooyahButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool outlined;
  final bool isLoading;

  const BooyahButton({
    super.key, required this.label, this.onTap,
    this.color, this.outlined = false, this.isLoading = false,
  });

  @override
  Widget build(BuildContext ctx) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: outlined
            ? Colors.transparent
            : (color ?? BooyahTheme.maroon),
        side: outlined
            ? BorderSide(color: color ?? BooyahTheme.maroon)
            : BorderSide.none,
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
      child: isLoading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label),
    ),
  );
}

// ── Info Row ──
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext ctx) => Row(
    children: [
      Icon(icon, size: 11, color: BooyahTheme.maroonB),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 11, color: BooyahTheme.textSec)),
    ],
  );
}

// ── Mini Bar Chart ──
class MiniBarChart extends StatelessWidget {
  final List<double> values; // 0.0 - 1.0
  final int highlightIndex;

  const MiniBarChart({super.key, required this.values, this.highlightIndex = -1});

  @override
  Widget build(BuildContext ctx) => SizedBox(
    height: 44,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        final isHi = i == highlightIndex || i == values.length - 1;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: 44 * values[i],
            decoration: BoxDecoration(
              color: isHi
                  ? BooyahTheme.maroonB
                  : BooyahTheme.maroon.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ),
        );
      }),
    ),
  );
}

// ── Progress Bar ──
class BooyahProgress extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double percent;
  final Color? color;

  const BooyahProgress({
    super.key, required this.label, required this.valueLabel,
    required this.percent, this.color,
  });

  @override
  Widget build(BuildContext ctx) => Column(
    children: [
      Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: BooyahTheme.textMuted)),
          const Spacer(),
          Text(valueLabel, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: color ?? BooyahTheme.green,
          )),
        ],
      ),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: percent.clamp(0.0, 1.0),
          backgroundColor: BooyahTheme.surface,
          valueColor: AlwaysStoppedAnimation(color ?? BooyahTheme.green),
          minHeight: 7,
        ),
      ),
      const SizedBox(height: 10),
    ],
  );
}

// ── Timeline Step ──
class TimelineStep extends StatelessWidget {
  final String title, subtitle;
  final bool isDone, isActive;
  final String stepLabel;
  final bool isLast;

  const TimelineStep({
    super.key, required this.title, required this.subtitle,
    this.isDone = false, this.isActive = false,
    required this.stepLabel, this.isLast = false,
  });

  @override
  Widget build(BuildContext ctx) {
    Color dotBg, dotBorder;
    Widget dotChild;

    if (isDone) {
      dotBg = BooyahTheme.green.withValues(alpha: 0.15);
      dotBorder = BooyahTheme.green;
      dotChild = const Icon(Icons.check, color: BooyahTheme.green, size: 13);
    } else if (isActive) {
      dotBg = BooyahTheme.maroon.withValues(alpha: 0.2);
      dotBorder = BooyahTheme.maroonB;
      dotChild = Text(stepLabel, style: const TextStyle(fontSize: 9, color: BooyahTheme.maroonGlow, fontWeight: FontWeight.w700));
    } else {
      dotBg = BooyahTheme.surface;
      dotBorder = Colors.white.withValues(alpha: 0.1);
      dotChild = Text(stepLabel, style: TextStyle(fontSize: 9, color: BooyahTheme.textMuted, fontWeight: FontWeight.w700));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: dotBg, shape: BoxShape.circle,
                  border: Border.all(color: dotBorder, width: 2),
                  boxShadow: isActive ? [BoxShadow(color: BooyahTheme.maroon.withValues(alpha: 0.3), blurRadius: 8)] : null,
                ),
                child: Center(child: dotChild),
              ),
              if (!isLast) Container(width: 2, height: 28, color: BooyahTheme.maroon.withValues(alpha: 0.2)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: isActive ? BooyahTheme.maroonGlow : (isDone ? BooyahTheme.textPri : BooyahTheme.textMuted),
                )),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
