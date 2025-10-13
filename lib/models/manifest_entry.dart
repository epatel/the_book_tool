class ManifestEntry {
  final String key;
  final String value;

  const ManifestEntry({
    required this.key,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
    };
  }

  factory ManifestEntry.fromMap(Map<String, dynamic> map) {
    return ManifestEntry(
      key: map['key'] as String,
      value: map['value'] as String,
    );
  }

  ManifestEntry copyWith({
    String? key,
    String? value,
  }) {
    return ManifestEntry(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ManifestEntry && other.key == key && other.value == value;
  }

  @override
  int get hashCode => key.hashCode ^ value.hashCode;

  @override
  String toString() => 'ManifestEntry(key: $key, value: $value)';
}
