import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Keeps every screen at a comfortable phone width, centred on wide displays
/// (web, tablets) without changing anything on a real phone.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child, this.maxWidth = 520});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.of(context).espresso,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

void showMessage(BuildContext context, String text) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final colors = AppColors.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message, style: TextStyle(color: colors.oat)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: TextStyle(color: colors.oat)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: destructive ? Colors.redAccent : colors.cinnamon,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.highlight = false,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlight;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: margin,
      child: Material(
        color: colors.espressoDark,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highlight ? colors.gold.withValues(alpha: 0.7) : colors.line,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.serif(fontSize: 22, color: accent ?? colors.latte),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.oat, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(color: colors.gold, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.color, this.filled = false});
  final String label;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final c = color ?? colors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? c : c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: filled ? colors.espresso : c,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Accent colour for a product kind: gold for mocha, soft green for matcha.
Color kindColor(AppColors colors, String kind) {
  switch (kind) {
    case Kinds.matcha:
      return colors.matcha;
    case Kinds.dessert:
    case Kinds.bundle:
      return colors.cinnamon;
    default:
      return colors.gold;
  }
}

/// Tags shown on product cards and rows.
List<Widget> productTags(BuildContext context, Product p) {
  final colors = AppColors.of(context);
  return [
    if (p.isMocha && p.signature) Tag('MOCHA SPECIALTY', color: colors.gold),
    if (p.isMatcha) Tag('MATCHA', color: colors.matcha),
    if (p.bestSeller) Tag('BESTSELLER', color: colors.cinnamon),
    if (p.isNew) Tag('NEW', color: colors.matcha, filled: true),
    if (!store.isOrderable(p)) const Tag('SOLD OUT', color: Colors.redAccent),
  ];
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final padding = EdgeInsets.symmetric(vertical: dense ? 10 : 15, horizontal: 18);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(30));
    final text = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: dense ? 13 : 15, fontWeight: FontWeight.w600),
      ),
    );
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: dense ? 16 : 18), const SizedBox(width: 8)],
        text,
      ],
    );
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.gold,
          side: BorderSide(color: colors.gold.withValues(alpha: 0.7)),
          padding: padding,
          shape: shape,
          minimumSize: const Size(48, 44),
        ),
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.cinnamon,
        foregroundColor: Colors.white,
        disabledBackgroundColor: colors.line,
        disabledForegroundColor: colors.oat,
        padding: padding,
        shape: shape,
        elevation: 0,
        minimumSize: const Size(48, 44),
      ),
      child: child,
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    Widget btn(IconData icon, VoidCallback? onTap, String tip) => IconButton(
      onPressed: onTap,
      tooltip: tip,
      icon: Icon(icon, size: 18),
      color: colors.gold,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, value > min ? () => onChanged(value - 1) : null, 'Decrease'),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          btn(Icons.add, value < 99 ? () => onChanged(value + 1) : null, 'Increase'),
        ],
      ),
    );
  }
}

class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final count = store.cartCount;
        return IconButton(
          tooltip: 'Cart',
          onPressed: () => Navigator.pushNamed(context, '/cart'),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            backgroundColor: colors.cinnamon,
            textColor: Colors.white,
            child: Icon(Icons.shopping_bag_outlined, color: colors.gold),
          ),
        );
      },
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.productId, this.size = 22});
  final String productId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final fav = store.isFavorite(productId);
        return IconButton(
          tooltip: fav ? 'Remove from favorites' : 'Save to favorites',
          onPressed: () => store.toggleFavorite(productId),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: EdgeInsets.zero,
          icon: Icon(
            fav ? Icons.favorite : Icons.favorite_border,
            size: size,
            color: fav ? colors.cinnamon : colors.oat,
          ),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.gold.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Text(title, style: AppFonts.serif(fontSize: 20, color: colors.latte)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.oat, fontSize: 13),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: accent ?? colors.gold),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppFonts.serif(fontSize: 22, color: colors.latte),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.oat, fontSize: 12),
          ),
          if (caption != null)
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.oat.withValues(alpha: 0.7), fontSize: 10),
            ),
        ],
      ),
    );
  }
}

Color statusColor(AppColors colors, OrderStatus s) {
  switch (s) {
    case OrderStatus.received:
      return colors.gold;
    case OrderStatus.confirmed:
      return colors.cinnamon;
    case OrderStatus.preparing:
      return colors.cinnamon;
    case OrderStatus.ready:
    case OrderStatus.outForDelivery:
      return colors.matcha;
    case OrderStatus.completed:
      return colors.matcha;
    case OrderStatus.cancelled:
      return Colors.redAccent;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.order, {super.key});
  final CafeOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Tag(order.statusLabel.toUpperCase(), color: statusColor(colors, order.status));
  }
}

/// Small centered label + value pair used in summaries.
class SummaryRow extends StatelessWidget {
  const SummaryRow(this.label, this.value, {super.key, this.bold = false, this.accent});
  final String label;
  final String value;
  final bool bold;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final style = TextStyle(
      color: accent ?? (bold ? colors.latte : colors.oat),
      fontSize: bold ? 16 : 13,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Reads and writes a text controller in a labelled outlined field.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.hint,
    this.suffix,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hint;
  final String? suffix;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
        onChanged: onChanged,
        style: TextStyle(color: colors.latte, fontSize: 14),
        cursorColor: colors.gold,
        decoration: InputDecoration(labelText: label, hintText: hint, suffixText: suffix),
      ),
    );
  }
}

String formatNumberField(double v) {
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}
