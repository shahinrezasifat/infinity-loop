import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../core/di/injector.dart';

/// Live GitHub profile data for the developer.
class GitHubDevProfile {
  const GitHubDevProfile({
    required this.username,
    required this.name,
    required this.bio,
    required this.avatarUrl,
    required this.updatedAt,
    this.htmlUrl = 'https://github.com/shahinrezasifat1999',
    this.blog = 'https://motionwork-tali.top',
    this.company = 'Motion Work',
    this.location,
    this.publicRepos = 1,
    this.followers = 0,
    this.following = 0,
  });

  final String username;
  final String name;
  final String bio;
  final String avatarUrl;
  final String updatedAt;
  final String htmlUrl;
  final String blog;
  final String? company;
  final String? location;
  final int publicRepos;
  final int followers;
  final int following;

  static const defaultProfile = GitHubDevProfile(
    username: 'shahinrezasifat1999',
    name: 'S. M. Shahin Reza Sifat',
    bio: 'Software Developer & Founder of Motion Work',
    avatarUrl: 'https://avatars.githubusercontent.com/u/203796840?v=4',
    updatedAt: '',
    htmlUrl: 'https://github.com/shahinrezasifat1999',
    blog: 'https://motionwork-tali.top',
    company: 'Motion Work',
  );

  /// Avatar URL with cache-busting timestamp parameter so changes on GitHub reflect instantly.
  String get dynamicAvatarUrl {
    final base = avatarUrl.isNotEmpty ? avatarUrl : defaultProfile.avatarUrl;
    if (updatedAt.isEmpty) return base;
    final sep = base.contains('?') ? '&' : '?';
    return '$base${sep}v=$updatedAt';
  }

  /// Unique cacheKey for CachedNetworkImage that automatically invalidates when updatedAt changes.
  String get cacheKey => 'gh_avatar_${username}_$updatedAt';

  Map<String, dynamic> toJson() => {
    'username': username,
    'name': name,
    'bio': bio,
    'avatarUrl': avatarUrl,
    'updatedAt': updatedAt,
    'htmlUrl': htmlUrl,
    'blog': blog,
    'company': company,
    'location': location,
    'publicRepos': publicRepos,
    'followers': followers,
    'following': following,
  };

  factory GitHubDevProfile.fromJson(Map<String, dynamic> json) {
    return GitHubDevProfile(
      username: json['username'] as String? ?? 'shahinrezasifat1999',
      name: json['name'] as String? ?? defaultProfile.name,
      bio: json['bio'] as String? ?? defaultProfile.bio,
      avatarUrl: json['avatarUrl'] as String? ?? defaultProfile.avatarUrl,
      updatedAt: json['updatedAt'] as String? ?? '',
      htmlUrl: json['htmlUrl'] as String? ?? defaultProfile.htmlUrl,
      blog: json['blog'] as String? ?? defaultProfile.blog,
      company: json['company'] as String? ?? defaultProfile.company,
      location: json['location'] as String?,
      publicRepos: json['publicRepos'] as int? ?? 1,
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
    );
  }

  factory GitHubDevProfile.fromGitHubApi(Map<String, dynamic> json) {
    final rawName = json['name'] as String?;
    final rawBio = json['bio'] as String?;
    final rawBlog = json['blog'] as String?;
    final rawAvatar = json['avatar_url'] as String?;
    final rawUpdated = json['updated_at'] as String?;

    return GitHubDevProfile(
      username: json['login'] as String? ?? 'shahinrezasifat1999',
      name: (rawName != null && rawName.trim().isNotEmpty)
          ? rawName.trim()
          : defaultProfile.name,
      bio: (rawBio != null && rawBio.trim().isNotEmpty)
          ? rawBio.trim()
          : defaultProfile.bio,
      avatarUrl: (rawAvatar != null && rawAvatar.isNotEmpty)
          ? rawAvatar
          : defaultProfile.avatarUrl,
      updatedAt: rawUpdated ?? DateTime.now().toIso8601String(),
      htmlUrl: json['html_url'] as String? ?? defaultProfile.htmlUrl,
      blog: (rawBlog != null && rawBlog.trim().isNotEmpty)
          ? (rawBlog.startsWith('http')
              ? rawBlog.trim()
              : 'https://${rawBlog.trim()}')
          : defaultProfile.blog,
      company: json['company'] as String? ?? defaultProfile.company,
      location: json['location'] as String?,
      publicRepos: json['public_repos'] as int? ?? 1,
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
    );
  }
}

/// Service that syncs the developer profile live with GitHub in real time.
class DeveloperProfileService {
  DeveloperProfileService._();

  static const String _cacheKey = 'github_dev_profile_cache';
  static const String username = 'shahinrezasifat1999';
  static const String apiUrl = 'https://api.github.com/users/$username';

  /// Live listenable for instant UI reactivity across the entire app.
  static final ValueNotifier<GitHubDevProfile> current =
      ValueNotifier<GitHubDevProfile>(getCachedProfile());

  /// Returns the cached profile immediately from memory or Hive.
  static GitHubDevProfile getCachedProfile() {
    if (!Hive.isBoxOpen('app_prefs')) return GitHubDevProfile.defaultProfile;
    final raw = Hive.box('app_prefs').get(_cacheKey);
    if (raw is Map) {
      try {
        return GitHubDevProfile.fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {}
    }
    return GitHubDevProfile.defaultProfile;
  }

  /// Immediately fetches latest profile from GitHub API and updates listeners.
  static Future<GitHubDevProfile> fetchProfile({bool forceEvict = false}) async {
    try {
      final dio = sl.isRegistered<Dio>() ? sl<Dio>() : Dio();
      final res = await dio.get<Map<String, dynamic>>(
        apiUrl,
        options: Options(
          headers: {
            'User-Agent': 'ZangetsuApp',
            'Accept': 'application/vnd.github.v3+json',
          },
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        final profile = GitHubDevProfile.fromGitHubApi(res.data!);
        if (Hive.isBoxOpen('app_prefs')) {
          await Hive.box('app_prefs').put(_cacheKey, profile.toJson());
        }

        if (forceEvict) {
          try {
            await CachedNetworkImage.evictFromCache(profile.dynamicAvatarUrl);
            await CachedNetworkImage.evictFromCache(profile.avatarUrl);
          } catch (_) {}
        }

        current.value = profile;
        return profile;
      }
    } catch (_) {
      // Ignore network failures and fall back to current cached profile
    }

    final cached = getCachedProfile();
    current.value = cached;
    return cached;
  }
}
