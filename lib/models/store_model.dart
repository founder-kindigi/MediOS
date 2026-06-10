class StoreModel {
  final int? id;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;

  StoreModel({
    this.id,
    required this.name,
    this.address,
    this.phone,
    this.isActive = true,
  });

  StoreModel copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    bool? isActive,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'address': address,
    'phone': phone,
    'is_active': isActive ? 1 : 0,
  };

  factory StoreModel.fromMap(Map<String, dynamic> map) => StoreModel(
    id: map['id'] as int?,
    name: map['name'] as String,
    address: map['address'] as String?,
    phone: map['phone'] as String?,
    isActive: (map['is_active'] as int?) == 1,
  );
}
