import 'package:flutter/material.dart';

/// SplitLui's visual language: quiet surfaces, crisp type and a restrained
/// retain the light design; use lavender on neutral charcoal in dark mode.
abstract final class LuiStyle {
  static const ink = Color(0xFF172A41);
  static const blue = Color(0xFF138C7C); // Existing light-mode accent.
  static const teal = blue;
  static const canvas = Color(0xFFF4FAF8);
  static const line = Color(0xFFDDECE6);

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: dark ? const Color(0xFF9A87CA) : blue,
      brightness: brightness,
      primary: dark ? const Color(0xFFC8B6FF) : teal,
      surface: dark ? const Color(0xFF262430) : Colors.white,
    ).copyWith(
      surfaceContainer: dark ? const Color(0xFF2D2A37) : null,
      surfaceContainerHighest: dark ? const Color(0xFF383442) : null,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF191820) : canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF191820) : canvas,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: dark ? const Color(0xFF45404F) : line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: dark ? const Color(0xFF45404F) : line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: dark ? const Color(0xFF45404F) : line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: dark ? const Color(0xFF45404F) : line))),
      dividerTheme: DividerThemeData(color: dark ? const Color(0xFF45404F) : line),
    );
  }
}

class LuiSectionHeading extends StatelessWidget {
  const LuiSectionHeading({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700, letterSpacing: -0.5))),
    if (trailing != null) trailing!,
  ]);
}

class LuiFeatureTile extends StatelessWidget {
  const LuiFeatureTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22)),
            child: Icon(icon, color: scheme.primary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600,
                fontSize: 16)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          )),
          trailing ?? Icon(Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant),
        ]),
      ),
    ));
  }
}

class LuiFormLabel extends StatelessWidget {
  const LuiFormLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600)),
  );
}
