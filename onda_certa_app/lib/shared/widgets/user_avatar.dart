import 'package:flutter/material.dart';

class AvatarDef {
  const AvatarDef({
    required this.id,
    required this.emoji,
    required this.gradientStart,
    required this.gradientEnd,
    required this.label,
  });
  final String id;
  final String emoji;
  final Color gradientStart;
  final Color gradientEnd;
  final String label;
}

const kAvatarDefault = 'default';

const kPredefinedAvatars = [
  AvatarDef(
    id: 'wave',
    emoji: '🌊',
    gradientStart: Color(0xFF0277BD),
    gradientEnd: Color(0xFF4FC3F7),
    label: 'Onda',
  ),
  AvatarDef(
    id: 'surfer',
    emoji: '🏄',
    gradientStart: Color(0xFF0D2137),
    gradientEnd: Color(0xFF1A5276),
    label: 'Surfista',
  ),
  AvatarDef(
    id: 'shell',
    emoji: '🐚',
    gradientStart: Color(0xFFB7860B),
    gradientEnd: Color(0xFFE8C98A),
    label: 'Concha',
  ),
  AvatarDef(
    id: 'anchor',
    emoji: '⚓',
    gradientStart: Color(0xFF1B2A4A),
    gradientEnd: Color(0xFF2E4272),
    label: 'Âncora',
  ),
  AvatarDef(
    id: 'dolphin',
    emoji: '🐬',
    gradientStart: Color(0xFF1565C0),
    gradientEnd: Color(0xFF42A5F5),
    label: 'Golfinho',
  ),
  AvatarDef(
    id: 'crab',
    emoji: '🦀',
    gradientStart: Color(0xFFB83232),
    gradientEnd: Color(0xFFE86C50),
    label: 'Caranguejo',
  ),
  AvatarDef(
    id: 'sailboat',
    emoji: '⛵',
    gradientStart: Color(0xFF1A8A8A),
    gradientEnd: Color(0xFF3ECFCF),
    label: 'Veleiro',
  ),
  AvatarDef(
    id: 'compass',
    emoji: '🧭',
    gradientStart: Color(0xFFE65100),
    gradientEnd: Color(0xFFFFB74D),
    label: 'Bússola',
  ),
  AvatarDef(
    id: 'fish',
    emoji: '🐠',
    gradientStart: Color(0xFF00695C),
    gradientEnd: Color(0xFF26A69A),
    label: 'Peixe',
  ),
  AvatarDef(
    id: 'shark',
    emoji: '🦈',
    gradientStart: Color(0xFF37474F),
    gradientEnd: Color(0xFF78909C),
    label: 'Tubarão',
  ),
  AvatarDef(
    id: 'lighthouse',
    emoji: '🏖️',
    gradientStart: Color(0xFF4527A0),
    gradientEnd: Color(0xFF9575CD),
    label: 'Praia',
  ),
  AvatarDef(
    id: 'star',
    emoji: '⭐',
    gradientStart: Color(0xFF6D4C41),
    gradientEnd: Color(0xFFBCAAA4),
    label: 'Estrela',
  ),
];

AvatarDef? avatarById(String id) {
  try {
    return kPredefinedAvatars.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
}

/// Main avatar widget. Pass [avatarId] = null or 'default' to show the
/// initials fallback; any other string renders the matching predefined avatar.
class UserAvatarWidget extends StatelessWidget {
  const UserAvatarWidget({
    super.key,
    required this.size,
    this.avatarId,
    this.initials = '?',
    this.showGlow = false,
  });

  final double size;
  final String? avatarId;
  final String initials;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final def = (avatarId != null && avatarId != kAvatarDefault)
        ? avatarById(avatarId!)
        : null;

    final glowColor = def != null ? def.gradientEnd : const Color(0xFF3ECFCF);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: def != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [def.gradientStart, def.gradientEnd],
              )
            : null,
        color: def == null ? const Color(0xFF3ECFCF) : null,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Center(
        child: def != null
            ? Text(
                def.emoji,
                style: TextStyle(fontSize: size * 0.46),
              )
            : Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}

/// A compact tile used in the avatar picker grid.
class AvatarPickerTile extends StatelessWidget {
  const AvatarPickerTile({
    super.key,
    required this.def,
    required this.selected,
    required this.onTap,
  });

  final AvatarDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: def.gradientEnd.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: UserAvatarWidget(
          size: 60,
          avatarId: def.id,
        ),
      ),
    );
  }
}
