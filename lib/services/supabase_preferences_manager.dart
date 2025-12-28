import 'supabase_service.dart';

class UserPreferences {
  final String id;
  final String userId;
  final String? avatarId;
  final String? photoUrl;
  final String theme;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPreferences({
    required this.id,
    required this.userId,
    this.avatarId,
    this.photoUrl,
    this.theme = 'light',
    this.notificationsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'avatar_id': avatarId,
      'photo_url': photoUrl,
      'theme': theme,
      'notifications_enabled': notificationsEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      avatarId: map['avatar_id'] as String?,
      photoUrl: map['photo_url'] as String?,
      theme: map['theme'] as String? ?? 'light',
      notificationsEnabled: map['notifications_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  UserPreferences copyWith({
    String? avatarId,
    String? photoUrl,
    String? theme,
    bool? notificationsEnabled,
  }) {
    return UserPreferences(
      id: id,
      userId: userId,
      avatarId: avatarId ?? this.avatarId,
      photoUrl: photoUrl ?? this.photoUrl,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class PresetAvatar {
  final String id;
  final String emoji;
  final String label;
  final String color;

  PresetAvatar({
    required this.id,
    required this.emoji,
    required this.label,
    required this.color,
  });
}

class SupabasePreferencesManager {
  static const String _table = 'user_preferences';

  static final List<PresetAvatar> presetAvatars = [
    PresetAvatar(
      id: 'butterfly',
      emoji: '🦋',
      label: 'Butterfly',
      color: '#FFB3BA',
    ),
    PresetAvatar(
      id: 'flower',
      emoji: '🌸',
      label: 'Flower',
      color: '#FFDBA',
    ),
    PresetAvatar(
      id: 'star',
      emoji: '⭐',
      label: 'Star',
      color: '#FFFABA',
    ),
    PresetAvatar(
      id: 'moon',
      emoji: '🌙',
      label: 'Moon',
      color: '#BAE1FF',
    ),
    PresetAvatar(
      id: 'sun',
      emoji: '☀️',
      label: 'Sun',
      color: '#FFD9BA',
    ),
    PresetAvatar(
      id: 'heart',
      emoji: '❤️',
      label: 'Heart',
      color: '#FFB3BA',
    ),
    PresetAvatar(
      id: 'gem',
      emoji: '💎',
      label: 'Gem',
      color: '#E0BBE4',
    ),
    PresetAvatar(
      id: 'sparkle',
      emoji: '✨',
      label: 'Sparkle',
      color: '#FFC0E0',
    ),
    PresetAvatar(
      id: 'leaf',
      emoji: '🍃',
      label: 'Leaf',
      color: '#BAFFBA',
    ),
    PresetAvatar(
      id: 'feather',
      emoji: '🪶',
      label: 'Feather',
      color: '#E8D4F8',
    ),
    PresetAvatar(
      id: 'cherry',
      emoji: '🍒',
      label: 'Cherry',
      color: '#FFB3B3',
    ),
    PresetAvatar(
      id: 'shell',
      emoji: '🐚',
      label: 'Shell',
      color: '#FFF9C4',
    ),
  ];

  // Get user preferences
  static Future<UserPreferences?> getUserPreferences(String userId) async {
    try {
      final data = await SupabaseService.fetchSingleRecord(_table, userId);
      if (data == null) {
        // Create default preferences if not exists
        await _createDefaultPreferences(userId);
        return await getUserPreferences(userId);
      }
      return UserPreferences.fromMap(data);
    } catch (e) {
      print('Error getting preferences: $e');
      return null;
    }
  }

  // Update avatar
  static Future<void> setAvatar(String userId, String avatarId) async {
    try {
      await SupabaseService.updateData(_table, userId, {
        'avatar_id': avatarId,
        'photo_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error setting avatar: $e');
    }
  }

  // Upload and set photo avatar
  static Future<void> setPhotoAvatar(String userId, String photoPath) async {
    try {
      final fileName =
          'avatars/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final photoUrl =
          await SupabaseService.uploadFile('user-avatars', fileName, photoPath);

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

  // Clear avatar
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

  // Update theme
  static Future<void> setTheme(String userId, String theme) async {
    try {
      await SupabaseService.updateData(_table, userId, {
        'theme': theme,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error setting theme: $e');
    }
  }

  // Toggle notifications
  static Future<void> setNotifications(String userId, bool enabled) async {
    try {
      await SupabaseService.updateData(_table, userId, {
        'notifications_enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating notifications: $e');
    }
  }

  /// Update multiple preferences at once
  static Future<void> updateUserPreferences({
    required String userId,
    String? theme,
    bool? notificationsEnabled,
    String? avatarId,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (theme != null) updates['theme'] = theme;
      if (notificationsEnabled != null) updates['notifications_enabled'] = notificationsEnabled;
      if (avatarId != null) updates['avatar_id'] = avatarId;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      
      await SupabaseService.updateData(_table, userId, updates);
    } catch (e) {
      print('Error updating preferences: $e');
      rethrow;
    }
  }

  // Get preferences stream for real-time updates
  // TODO: Implement real-time stream when Supabase library is updated
  // static Stream<UserPreferences?> getPreferencesStream(String userId) {
  //   return SupabaseService.subscribeToTable(_table, userId: userId)
  //       .map((data) {
  //     if (data.isEmpty) return null;
  //     return UserPreferences.fromMap(data.first);
  //   });
  // }

  // Get default avatar
  static PresetAvatar getDefaultAvatar() {
    return presetAvatars.first;
  }

  // Private: Create default preferences
  static Future<void> _createDefaultPreferences(String userId) async {
    try {
      final prefs = UserPreferences(
        id: userId,
        userId: userId,
        avatarId: presetAvatars.first.id,
        theme: 'light',
        notificationsEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await SupabaseService.insertData(_table, prefs.toMap());
    } catch (e) {
      print('Error creating default preferences: $e');
    }
  }
}
