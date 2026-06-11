import '../../domain/entities/supplier.dart';

class SupplierDataModel extends Supplier {
  SupplierDataModel({
    super.id,
    required super.name,
    super.contactPerson,
    required super.phone,
    super.email,
    super.address,
    super.createdAt,
    super.updatedAt,
  });

  factory SupplierDataModel.fromEntity(Supplier supplier) {
    return SupplierDataModel(
      id: supplier.id,
      name: supplier.name,
      contactPerson: supplier.contactPerson,
      phone: supplier.phone,
      email: supplier.email,
      address: supplier.address,
      createdAt: supplier.createdAt,
      updatedAt: supplier.updatedAt,
    );
  }

  factory SupplierDataModel.fromMap(Map<String, dynamic> map) {
    return SupplierDataModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      contactPerson: map['contact_person'] as String?,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Supplier toEntity() {
    return Supplier(
      id: id,
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      address: address,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
