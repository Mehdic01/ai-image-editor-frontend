import 'package:flutter/material.dart';

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size; // diameter
  final Color? iconColor;
  final Color? backgroundColor;
  final String? tooltip;

  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 36,
    this.iconColor,
    this.backgroundColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final fg = iconColor ?? Theme.of(context).colorScheme.onPrimary;
    final btn = Material(
      color:
          onPressed == null
              ? Theme.of(context).disabledColor.withOpacity(0.2)
              : bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: onPressed == null ? Colors.white70 : fg),
        ),
      ),
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}
