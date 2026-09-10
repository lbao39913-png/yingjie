class AppVersion {
  const AppVersion({
    required this.version,
    required this.versionCode,
    required this.forceUpdate,
    required this.updateUrl,
    required this.changelog,
  });

  final String version;
  final int versionCode;
  final bool forceUpdate;
  final String updateUrl;
  final String changelog;

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] as String? ?? '',
      versionCode: json['versionCode'] as int? ?? 0,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      updateUrl: json['updateUrl'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
    );
  }
}
