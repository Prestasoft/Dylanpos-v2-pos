class Area {
  final String id;
  final String name;
  final String description;
  final int quantityItem;
  final DateTime createdAt;
  final DateTime updatedAt;

  Area({
    required this.id,
    required this.name,
    required this.description,
    required this.quantityItem,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Area.fromMap(Map<dynamic, dynamic> map) {
    return Area(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      quantityItem: map['quantity_item'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity_item': quantityItem,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class Equipment {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String areaId;
  final String areaName;
  final String state;
  final DateTime createdAt;
  final DateTime updatedAt;

  Equipment({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.areaId,
    required this.areaName,
    this.state = 'Disponible',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Equipment.fromMap(Map<dynamic, dynamic> map) {
    return Equipment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 0,
      areaId: map['areaId'] ?? '',
      areaName: map['areaName'] ?? '',
      state: map['state'] ?? 'Disponible',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'areaId': areaId,
      'areaName': areaName,
      'state': state,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? areaId,
    String? areaName,
    String? state,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}