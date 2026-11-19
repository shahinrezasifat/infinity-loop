/// App updates are intentionally disabled for this build.
///
/// Kept as a compatibility layer for existing tests and callers. It always
/// reports that no update is available.
class UpdateService {
  Future<UpdateInfo?> checkForUpdate({bool respectSkip = false}) async => null;

  static int compareVersions(String a, String b) {
    final pa = _parseVersion(a);
    final pb = _parseVersion(b);
    final len = pa.core.length > pb.core.length
        ? pa.core.length
        : pb.core.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.core.length ? pa.core[i] : 0;
      final y = i < pb.core.length ? pb.core[i] : 0;
      if (x != y) return x < y ? -1 : 1;
    }
    if (pa.pre == null && pb.pre == null) return 0;
    if (pa.pre == null) return 1;
    if (pb.pre == null) return -1;
    if (pa.pre != pb.pre) return pa.pre! < pb.pre! ? -1 : 1;
    return 0;
  }

  static ({List<int> core, int? pre}) _parseVersion(String raw) {
    var value = raw.trim();
    if (value.startsWith('v') || value.startsWith('V')) {
      value = value.substring(1);
    }
    final dash = value.indexOf('-');
    var pre = null as int?;
    if (dash >= 0) {
      final label = value.substring(dash + 1).trim();
      final digits = RegExp(r'(\d+)$').firstMatch(label)?.group(1);
      pre = digits == null ? 0 : int.tryParse(digits) ?? 0;
      value = value.substring(0, dash);
    }
    final core = value
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList(growable: false);
    return (core: core, pre: pre);
  }
}

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.notes,
    required this.apkUrl,
    required this.assetName,
    required this.apkSize,
    this.isPrerelease = false,
  });

  final String version;
  final String notes;
  final String apkUrl;
  final String assetName;
  final int apkSize;
  final bool isPrerelease;
}
