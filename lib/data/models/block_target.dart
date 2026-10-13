/// A short-form surface the user can turn blocking on or off for.
///
/// Instances are built from the native side, which is the single source of truth
/// for which targets exist and whether each is currently enabled.
class BlockTarget {
  const BlockTarget({
    required this.id,
    required this.name,
    required this.packageName,
    required this.description,
    required this.enabled,
  });

  final String id;
  final String name;
  final String packageName;
  final String description;
  final bool enabled;

  factory BlockTarget.fromMap(Map<dynamic, dynamic> map) => BlockTarget(
        id: map['id'] as String,
        name: map['name'] as String,
        packageName: map['packageName'] as String,
        description: map['description'] as String,
        enabled: map['enabled'] as bool,
      );

  BlockTarget copyWith({bool? enabled}) => BlockTarget(
        id: id,
        name: name,
        packageName: packageName,
        description: description,
        enabled: enabled ?? this.enabled,
      );
}
