import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLogger {
  static Future<void> log(String actionType, String details) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('admin_logs').insert({
        'admin_id': user.id,
        'action_type': actionType,
        'details': details,
      });
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }
}
