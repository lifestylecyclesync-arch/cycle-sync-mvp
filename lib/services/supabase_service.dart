import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  static late final SupabaseClient _client;

  /// Initialize Supabase client
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://aoimvxciibxxcxgeeocz.supabase.co',
      anonKey: 'sb_publishable_uyaQHsPoIVvj4CvTqVpVxA_0fEatEmV',
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client => _client;
  // Note: Use client.auth for authentication methods

  /// Register a new user
  static Future<AuthResponse> registerUser(String email, String password) async {
    final response = await _client.auth.signUp(email: email, password: password);
    print('🔐 SupabaseService.registerUser() - signUp response: user=${response.user?.email}, session=${response.session}');
    
    // If signup succeeded and we have a session, return it
    if (response.user != null && response.session != null) {
      print('🔐 SupabaseService.registerUser() - Session already created automatically');
      return response;
    }
    
    // If no session but user was created, try signing in immediately
    // This handles the case where email confirmation is disabled
    if (response.user != null) {
      print('🔐 SupabaseService.registerUser() - User created, attempting immediate login...');
      try {
        final loginResponse = await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        print('🔐 SupabaseService.registerUser() - Immediate login successful');
        return loginResponse;
      } catch (e) {
        print('🔐 SupabaseService.registerUser() - Immediate login failed: $e');
        // Return the original signup response, user might need to confirm email
        return response;
      }
    }
    
    return response;
  }

  /// Login user
  static Future<AuthResponse> loginUser(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Logout user
  static Future<void> logoutUser() async {
    await _client.auth.signOut();
  }

  /// Get current user
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  /// Fetch data from a table
  static Future<List<Map<String, dynamic>>> fetchData(
    String table, {
    String? userId,
    Map<String, dynamic>? filters,
  }) async {
    var query = _client.from(table).select();

    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    // Apply additional filters if provided
    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    final List<dynamic> data = await query;
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetch a single record
  static Future<Map<String, dynamic>?> fetchSingleRecord(
    String table,
    String id,
  ) async {
    try {
      final data = await _client.from(table).select().eq('id', id).maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Insert data
  static Future<void> insertData(
    String table,
    Map<String, dynamic> data,
  ) async {
    await _client.from(table).insert(data);
  }

  /// Update data
  static Future<void> updateData(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _client.from(table).update(data).eq('id', id);
  }

  /// Delete data
  static Future<void> deleteData(String table, String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  /// Upload file to storage
  static Future<String> uploadFile(
    String bucket,
    String fileName,
    String filePath,
  ) async {
    final file = File(filePath);
    await _client.storage.from(bucket).upload(fileName, file);
    return getPublicUrl(bucket, fileName);
  }

  /// Get public URL for file
  static String getPublicUrl(String bucket, String fileName) {
    return _client.storage.from(bucket).getPublicUrl(fileName);
  }

  /// Subscribe to real-time updates
  static RealtimeChannel subscribeToTable(
    String table, {
    String? userId,
  }) {
    return _client.realtime.channel('public:$table').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      filter: userId != null ? PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId) : null,
      callback: (payload) {
        // Handle real-time updates
      },
    );
  }
}
