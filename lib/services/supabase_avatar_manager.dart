import 'package:flutter/material.dart';
import 'supabase_service.dart';

class AvatarOption {
  final String id;
  final String? emoji;
  final String? photoUrl;
  final String label;
  final Color color;
  final bool isPhoto;

  AvatarOption({
    required this.id,
    this.emoji,
    this.photoUrl,
    required this.label,
    required this.color,
    this.isPhoto = false,
  });
}

class SupabaseAvatarManager {
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

  static const String _table = 'user_avatars';

  static Future<AvatarOption?> getSelectedAvatar(String userId) async {
    try {
      final data = await SupabaseService.fetchSingleRecord(_table, userId);
      
      if (data == null) return null;

      final avatarId = data['avatar_id'] as String?;
      
      if (avatarId == null) return null;

      // Check if it's a photo avatar
      if (avatarId.startsWith('photo_')) {
        final photoUrl = data['photo_url'] as String?;
        if (photoUrl != null) {
          return AvatarOption(
            id: avatarId,
            photoUrl: photoUrl,
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
    } catch (e) {
      print('Error getting selected avatar: $e');
      return null;
    }
  }

  static Future<void> setSelectedAvatar(String userId, String avatarId) async {
    try {
      await SupabaseService.updateData(_table, userId, {
        'avatar_id': avatarId,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error setting avatar: $e');
    }
  }

  static Future<void> setPhotoAvatar(String userId, String photoPath) async {
    try {
      final fileName = 'avatars/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final photoUrl = await SupabaseService.uploadFile('avatars', fileName, photoPath);
      
      if (photoUrl.isNotEmpty) {
        await SupabaseService.updateData(_table, userId, {
          'avatar_id': 'photo_${DateTime.now().millisecondsSinceEpoch}',
          'photo_url': photoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error setting photo avatar: $e');
    }
  }

  static Future<void> clearAvatar(String userId) async {
    try {
      await SupabaseService.updateData(_table, userId, {
        'avatar_id': null,
        'photo_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error clearing avatar: $e');
    }
  }

  static AvatarOption getDefaultAvatar() {
    return presetAvatars.first;
  }
}
