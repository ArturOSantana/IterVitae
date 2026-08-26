import 'package:flutter/material.dart';

/// Tokens de cor centrais do Iter Vitae.
/// Nenhum widget hardcoda cor — todos referenciam esta classe.
abstract final class AppColors {
  // ── Primária ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF3D5A80);
  static const Color primaryContainer = Color(0xFFCBDFF8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF0D2137);

  // ── Superfície ──────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF8F7F4);
  static const Color surfaceVariant = Color(0xFFEEECE8);
  static const Color onSurface = Color(0xFF1C1B19);
  static const Color onSurfaceVariant = Color(0xFF4A4845);

  // ── Texto ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C1B19);
  static const Color textSecondary = Color(0xFF5A5754);
  static const Color textMuted = Color(0xFF8A8784);

  // ── Estado ──────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF386A20);
  static const Color warning = Color(0xFF7C5800);

  // ── Progresso ───────────────────────────────────────────────────────────
  static const Color progressTrack = Color(0xFFDDDAD5);
  static const Color progressFill = Color(0xFF3D5A80);
  static const Color progressComplete = Color(0xFF386A20);

  // ── Luta: estados diários ───────────────────────────────────────────────
  static const Color struggleAchieved = Color(0xFF386A20);
  static const Color struggleFought = Color(0xFF7C5800);
  static const Color struggleDidNotFight = Color(0xFFB3261E);

  // ── Categorias de prática ───────────────────────────────────────────────
  static const Color spiritual = Color(0xFF4A3F6B);   // violeta escuro
  static const Color human = Color(0xFF3D6B4A);       // verde escuro
  static const Color professional = Color(0xFF3D5A80); // azul (= primary)
  static const Color cultural = Color(0xFF6B4A3D);    // terracota
  static const Color apostolate = Color(0xFF6B3D4A);  // bordô

  // ── Divisórias / bordas ─────────────────────────────────────────────────
  static const Color divider = Color(0xFFE0DDD8);
  static const Color border = Color(0xFFCBCAC6);

  // ── Identidade Rubrica ──────────────────────────────────────────────────
  /// Vermelho rubrica — tinta de título dos breviários.
  /// Uso restrito: texto/ícone de acento, borda outline, marcador ¶,
  /// preenchimento de barra de progresso fina (2–4 px).
  /// Nunca como fundo sólido de card ou botão.
  static const Color rubric = Color(0xFFB23A2E);
}
