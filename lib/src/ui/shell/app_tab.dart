import 'package:flutter/material.dart';

/// Ilova bo'limlari. Telefonda pastki menyuda beshtasi, keng ekranda
/// (veb-saytdagi kabi) yon panelda ko'rsatiladi.
enum AppTab {
  home('Asosiy', Icons.home_outlined, Icons.home),
  typing('Tez yoziş', Icons.keyboard_outlined, Icons.keyboard),
  dictation('Diktant', Icons.headphones_outlined, Icons.headphones),
  translator('Translator', Icons.translate_outlined, Icons.translate),
  community('Hamjamiyat', Icons.groups_outlined, Icons.groups),
  profile('Profil', Icons.person_outline, Icons.person);

  final String label;
  final IconData icon;
  final IconData activeIcon;

  const AppTab(this.label, this.icon, this.activeIcon);

  /// Telefondagi pastki menyu.
  static const List<AppTab> mobile = [home, typing, dictation, translator, profile];

  /// Keng ekrandagi yon panel (veb-sayt tartibida).
  static const List<AppTab> sidebar = [home, typing, community, dictation, translator];
}

/// Bo'limni ochish: telefonda menyudan tashqaridagi bo'lim (masalan,
/// hamjamiyat) alohida sahifa sifatida ochiladi.
typedef OpenTab = void Function(AppTab tab);
