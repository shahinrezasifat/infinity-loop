// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NavItem _$NavItemFromJson(Map<String, dynamic> json) => NavItem(
  id: json['id'] as String,
  label: json['label'] as String,
  icon: json['icon'] as String,
  selectedIcon: json['selectedIcon'] as String,
  route: json['route'] as String,
  arguments: json['arguments'] as Map<String, dynamic>?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  isVisible: json['isVisible'] as bool? ?? true,
  badge: json['badge'] as String?,
);

Map<String, dynamic> _$NavItemToJson(NavItem instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'icon': instance.icon,
  'selectedIcon': instance.selectedIcon,
  'route': instance.route,
  'arguments': instance.arguments,
  'sortOrder': instance.sortOrder,
  'isVisible': instance.isVisible,
  'badge': instance.badge,
};

NavigationOrder _$NavigationOrderFromJson(Map<String, dynamic> json) =>
    NavigationOrder(
      itemOrder:
          (json['itemOrder'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      selectedIndex: (json['selectedIndex'] as num?)?.toInt() ?? 0,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$NavigationOrderToJson(NavigationOrder instance) =>
    <String, dynamic>{
      'itemOrder': instance.itemOrder,
      'selectedIndex': instance.selectedIndex,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
