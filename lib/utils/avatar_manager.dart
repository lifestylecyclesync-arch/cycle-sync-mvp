import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarOption {
  final String id;
  final String? emoji; // null for photo avatars
  final String? photoPath; // file path for photo avatars
  final String label;
  final Color color;
  final bool isPhoto; // true if it's a photo avatar

  AvatarOption({
    required this.id,
    this.emoji,
    this.photoPath,
    required this.label,
    required this.color,
    this.isPhoto = false,
  });
}

class AvatarManager {
  static final List<AvatarOption> presetAvatars = [
    AvatarOption(
      id: 'butterfly',
      emoji: '🦋',
      label: 'Butterfly',
      color: Color(0xFFFFB3BA),
    ),
    AvatarOption(
      id: 'flower',
      emoji: '🌸',
      label: 'Flower',
      color: Color(0xFFFFDFBA),
    ),
    AvatarOption(
      id: 'star',
      emoji: '⭐',
      label: 'Star',
      color: Color(0xFFFFFABA),
    ),
    AvatarOption(
      id: 'moon',
      emoji: '🌙',
      label: 'Moon',
      color: Color(0xFFBAE1FF),
    ),
    AvatarOption(
      id: 'sun',
      emoji: '☀️',
      label: 'Sun',
      color: Color(0xFFFFD9BA),
    ),
    AvatarOption(
      id: 'heart',
      emoji: '❤️',
      label: 'Heart',
      color: Color(0xFFFFB3BA),
    ),
    AvatarOption(
      id: 'gem',
      emoji: '💎',
      label: 'Gem',
      color: Color(0xFFE0BBE4),
    ),
    AvatarOption(
      id: 'sparkle',
      emoji: '✨',
      label: 'Sparkle',
      color: Color(0xFFFFC0E0),
    ),
    AvatarOption(
      id: 'leaf',
      emoji: '🍃',
      label: 'Leaf',
      color: Color(0xFFBAFFBA),
    ),
    AvatarOption(
      id: 'feather',
      emoji: '🪶',
      label: 'Feather',
      color: Color(0xFFE8D4F8),
    ),
    AvatarOption(
      id: 'cherry',
      emoji: '🍒',
      label: 'Cherry',
      color: Color(0xFFFFB3B3),
    ),
    AvatarOption(
      id: 'shell',
      emoji: '🐚',
      label: 'Shell',
      color: Color(0xFFFFF9C4),
    ),
  ];

  static Future<AvatarOption?> getSelectedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarId = prefs.getString('selectedAvatarId');
    
    if (avatarId == null) return null;
    
    // Check if it's a photo avatar
    if (avatarId.startsWith('photo_')) {
      final photoPath = prefs.getString('selectedPhotoPath');
      if (photoPath != null) {
        return AvatarOption(
          id: avatarId,
          photoPath: photoPath,
          label: 'My Photo',
          color: Colors.grey.shade200,
          isPhoto: true,
        );
      }
    }
    
    // Otherwise, it's a preset avatar
    try {
      return presetAvatars.firstWhere((avatar) => avatar.id == avatarId);
    } catch (e) {
      return null;
    }
  }

  static Future<void> setSelectedAvatar(String avatarId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedAvatarId', avatarId);
  }

  static Future<void> setPhotoAvatar(String photoPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedAvatarId', 'photo_${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setString('selectedPhotoPath', photoPath);
  }

  static Future<void> clearAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedAvatarId');
    await prefs.remove('selectedPhotoPath');
  }

  static AvatarOption getDefaultAvatar() {
    return presetAvatars.first;
  }
}
