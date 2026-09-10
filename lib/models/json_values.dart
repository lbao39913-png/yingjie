class JsonValues {
  JsonValues._();

  static String string(Object? value, [String fallback = '']) {
    if (value == null) {
      return fallback;
    }
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return fallback;
  }

  static int? integer(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static double? decimal(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static Map<String, dynamic>? map(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static List<Map<String, dynamic>> maps(Object? value) {
    if (value is! List) {
      return const [];
    }
    final out = <Map<String, dynamic>>[];
    for (final item in value) {
      final mapped = map(item);
      if (mapped != null) {
        out.add(mapped);
      }
    }
    return out;
  }

  static List<String> strings(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.map((item) => item.toString()).toList(growable: false);
  }

  static DateTime? date(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
