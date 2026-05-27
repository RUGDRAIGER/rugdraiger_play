import 'package:flutter/material.dart';

class PlayerSkin {
  final String id;
  final String name;
  final Color accent;
  final String group;

  const PlayerSkin({
    required this.id,
    required this.name,
    required this.accent,
    required this.group,
  });
}

const defaultSkinId = 'rojo';

const skinGroupOrder = <String, List<String>>{
  'cálidos': ['rojo', 'carmesi', 'salmon', 'rosa', 'coral', 'naranja', 'ambar'],
  'fríos': ['magenta', 'purpura', 'violeta', 'indigo', 'azul', 'cielo', 'cian'],
  'naturales': ['turquesa', 'esmeralda', 'verde', 'menta', 'lima'],
  'neutros': ['lavanda'],
};

const skinGroupLabels = <String, String>{
  'cálidos': 'Cálidos',
  'fríos': 'Fríos',
  'naturales': 'Naturales',
  'neutros': 'Neutros',
};

const skinGroupHints = <String, String>{
  'cálidos': 'Rojos, rosas y naranjas',
  'fríos': 'Magnetas, púrpuras y azules',
  'naturales': 'Verdes, turquesas y lima',
  'neutros': 'Tonos suaves y lavanda',
};

const playerSkins = <PlayerSkin>[
  PlayerSkin(id: 'rojo', name: 'Rojo', accent: Color(0xFFFF2020), group: 'cálidos'),
  PlayerSkin(id: 'carmesi', name: 'Carmesí', accent: Color(0xFFE8194A), group: 'cálidos'),
  PlayerSkin(id: 'salmon', name: 'Salmón', accent: Color(0xFFFF6B6B), group: 'cálidos'),
  PlayerSkin(id: 'rosa', name: 'Rosa', accent: Color(0xFFFF4081), group: 'cálidos'),
  PlayerSkin(id: 'coral', name: 'Coral', accent: Color(0xFFFF5722), group: 'cálidos'),
  PlayerSkin(id: 'naranja', name: 'Naranja', accent: Color(0xFFFF9800), group: 'cálidos'),
  PlayerSkin(id: 'ambar', name: 'Ámbar', accent: Color(0xFFFFC107), group: 'cálidos'),
  PlayerSkin(id: 'magenta', name: 'Magenta', accent: Color(0xFFE040FB), group: 'fríos'),
  PlayerSkin(id: 'purpura', name: 'Púrpura', accent: Color(0xFF9C27B0), group: 'fríos'),
  PlayerSkin(id: 'violeta', name: 'Violeta', accent: Color(0xFF7C4DFF), group: 'fríos'),
  PlayerSkin(id: 'indigo', name: 'Índigo', accent: Color(0xFF3F51B5), group: 'fríos'),
  PlayerSkin(id: 'azul', name: 'Azul', accent: Color(0xFF2196F3), group: 'fríos'),
  PlayerSkin(id: 'cielo', name: 'Cielo', accent: Color(0xFF03A9F4), group: 'fríos'),
  PlayerSkin(id: 'cian', name: 'Cian', accent: Color(0xFF00BCD4), group: 'fríos'),
  PlayerSkin(id: 'turquesa', name: 'Turquesa', accent: Color(0xFF009688), group: 'naturales'),
  PlayerSkin(id: 'esmeralda', name: 'Esmeralda', accent: Color(0xFF00C853), group: 'naturales'),
  PlayerSkin(id: 'verde', name: 'Verde', accent: Color(0xFF4CAF50), group: 'naturales'),
  PlayerSkin(id: 'menta', name: 'Menta', accent: Color(0xFF1DE9B6), group: 'naturales'),
  PlayerSkin(id: 'lima', name: 'Lima', accent: Color(0xFFAEEA00), group: 'naturales'),
  PlayerSkin(id: 'lavanda', name: 'Lavanda', accent: Color(0xFFB388FF), group: 'neutros'),
];

PlayerSkin getSkinById(String id) {
  return playerSkins.firstWhere(
    (s) => s.id == id,
    orElse: () => playerSkins.first,
  );
}

List<PlayerSkin> getSkinsForGroup(String group) {
  final order = skinGroupOrder[group] ?? [];
  return order.map(getSkinById).toList();
}
