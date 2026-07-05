import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final String avatar;
  const UserProfile({this.name = '', this.avatar = ''});
}

class ProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    _load();
    return const UserProfile();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final avatar = prefs.getString('user_avatar') ?? '';
    state = UserProfile(name: name, avatar: avatar);
  }

  Future<void> updateProfile(String name, String avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_avatar', avatar);
    state = UserProfile(name: name, avatar: avatar);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(() => ProfileNotifier());
