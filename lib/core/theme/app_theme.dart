import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DashboardGradientSlot {
  cpu,
  memory,
  storage,
  salesToday,
  salesWeek,
  salesMonth,
  salesTotal,
  hotspot,
  ppp,
  router,
}

// Extension de thème pour regrouper tous vos dégradés personnalisés
class CustomGradientsExtension
    extends ThemeExtension<CustomGradientsExtension> {
  final LinearGradient gradientA;
  final LinearGradient gradientB;
  final LinearGradient gradientC;
  final LinearGradient gradientD;
  final LinearGradient gradientE;
  final LinearGradient gradientF;
  final LinearGradient gradientG;
  final LinearGradient gradientH;
  final LinearGradient gradientI;
  final LinearGradient gradientJ;

  const CustomGradientsExtension({
    required this.gradientA,
    required this.gradientB,
    required this.gradientC,
    required this.gradientD,
    required this.gradientE,
    required this.gradientF,
    required this.gradientG,
    required this.gradientH,
    required this.gradientI,
    required this.gradientJ,
  });

  LinearGradient forSlot(DashboardGradientSlot slot) => switch (slot) {
    DashboardGradientSlot.cpu => gradientA,
    DashboardGradientSlot.memory => gradientB,
    DashboardGradientSlot.storage => gradientC,
    DashboardGradientSlot.salesToday => gradientD,
    DashboardGradientSlot.salesWeek => gradientE,
    DashboardGradientSlot.salesMonth => gradientF,
    DashboardGradientSlot.salesTotal => gradientG,
    DashboardGradientSlot.hotspot => gradientH,
    DashboardGradientSlot.ppp => gradientI,
    DashboardGradientSlot.router => gradientJ,
  };

  @override
  CustomGradientsExtension copyWith({
    LinearGradient? gradientA,
    LinearGradient? gradientB,
    LinearGradient? gradientC,
    LinearGradient? gradientD,
    LinearGradient? gradientE,
    LinearGradient? gradientF,
    LinearGradient? gradientG,
    LinearGradient? gradientH,
    LinearGradient? gradientI,
    LinearGradient? gradientJ,
  }) {
    return CustomGradientsExtension(
      gradientA: gradientA ?? this.gradientA,
      gradientB: gradientB ?? this.gradientB,
      gradientC: gradientC ?? this.gradientC,
      gradientD: gradientD ?? this.gradientD,
      gradientE: gradientE ?? this.gradientE,
      gradientF: gradientF ?? this.gradientF,
      gradientG: gradientG ?? this.gradientG,
      gradientH: gradientH ?? this.gradientH,
      gradientI: gradientI ?? this.gradientI,
      gradientJ: gradientJ ?? this.gradientJ,
    );
  }

  @override
  CustomGradientsExtension lerp(
    ThemeExtension<CustomGradientsExtension>? other,
    double t,
  ) {
    if (other is! CustomGradientsExtension) return this;
    return CustomGradientsExtension(
      gradientA: LinearGradient.lerp(gradientA, other.gradientA, t)!,
      gradientB: LinearGradient.lerp(gradientB, other.gradientB, t)!,
      gradientC: LinearGradient.lerp(gradientC, other.gradientC, t)!,
      gradientD: LinearGradient.lerp(gradientD, other.gradientD, t)!,
      gradientE: LinearGradient.lerp(gradientE, other.gradientE, t)!,
      gradientF: LinearGradient.lerp(gradientF, other.gradientF, t)!,
      gradientG: LinearGradient.lerp(gradientG, other.gradientG, t)!,
      gradientH: LinearGradient.lerp(gradientH, other.gradientH, t)!,
      gradientI: LinearGradient.lerp(gradientI, other.gradientI, t)!,
      gradientJ: LinearGradient.lerp(gradientJ, other.gradientJ, t)!,
    );
  }
}

class AppTheme {
  // Vos couleurs de base existantes
  static const mikrotikBlack = Color(0xFF0E0E10);
  static const mikrotikPink = Color(0xFFC33366);
  static const mikrotikTurquoise = Color(0xFF3BB5B6);
  static const mikrotikLightGreen = Color(0xFFA3D16E);

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: mikrotikTurquoise,
      brightness: Brightness.light,
    ).copyWith(secondary: mikrotikPink, tertiary: mikrotikLightGreen),
    appBarTheme: const AppBarTheme(
      backgroundColor: mikrotikLightGreen,
      foregroundColor: mikrotikBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),

    // Déclaration et configuration de tous vos dégradés avec 80% d'opacité (0xCC)
    extensions: const [
      CustomGradientsExtension(
        // colorA : Rose Cerise Sauvage vers Violet Profond
        gradientA: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCCC33366), Color(0xCC692878)],
        ),
        // colorB : Bleu Roi vers Bleu Nuit Foncé
        gradientB: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCC015EA4), Color(0xCC012D4E)],
        ),
        // colorC : Rouge Vif vers Rouge Sombre / Bordeaux
        gradientC: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCCCF0F14), Color(0xCC5F0A0A)],
        ),
        // colorD : Bleu Ciel Clair vers Bleu Denim Foncé
        gradientD: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCC87D3DB), Color(0xCC1F417A)],
        ),
        // colorE : Orange Ambré vers Orange Brûlé
        gradientE: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCCEE9B01), Color(0xCCEE4F01)],
        ),
        // colorF : Bleu Acier vers Améthyste Foncé
        gradientF: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCC3660B9), Color(0xCC5F2965)],
        ),
        // colorG : Turquoise vers Vert Menthe Lumineux
        gradientG: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCC3BB5B6), Color(0xCC44DE95)],
        ),
        // colorH : Violet Byzantium vers Bleu Cyan Électrique
        gradientH: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCC582D7C), Color(0xCC1FC8DB)],
        ),
        // colorI : Vert Pin vers Bleu Ardoise Foncé
        gradientI: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCC017C65), Color(0xCC2C3A43)],
        ),
        // colorJ : Vert Tendre vers Vert Forêt Profond
        gradientJ: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCCA3D16E), Color(0xCC155757)],
        ),
      ),
    ],
  );
}
