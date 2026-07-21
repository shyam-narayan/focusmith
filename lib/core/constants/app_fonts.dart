/// App-wide typeface. CRED-like geometric sans (Satoshi ≈ Gilroy).
/// No per-widget font switching — use this family everywhere except code.
abstract final class AppFonts {
  static const String family = 'Satoshi';

  /// Monospace reserved for code blocks / inline code only.
  /// Cascadia Mono ships with Windows 10+ and covers more symbols than Consolas.
  static const String mono = 'Cascadia Mono';

  /// Fallback chain keeps code glyphs monospace instead of falling back to Satoshi.
  static const List<String> monoFallback = [
    'Cascadia Code',
    'Consolas',
    'Courier New',
  ];
}
