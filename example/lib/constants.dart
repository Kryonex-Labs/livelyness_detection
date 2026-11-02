import 'package:example/index.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF08090E),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF00E5A0),
    brightness: Brightness.dark,
    surface: const Color(0xFF10121A),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.white;
      return const Color(0xFF4A4D5C);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF00E5A0);
      return const Color(0xFF1E2030);
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.transparent;
      return const Color(0xFF2A2D3A);
    }),
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: Color(0xFF00E5A0),
    inactiveTrackColor: Color(0xFF1E2030),
    thumbColor: Colors.white,
    overlayColor: Color(0x1A00E5A0),
    trackHeight: 3,
  ),
  textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
);
