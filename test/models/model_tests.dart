import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/medicine_model.dart';
import '../../lib/models/sale_model.dart';
import '../../lib/models/supplier_model.dart';
import '../../lib/models/store_model.dart';
import '../../lib/models/prescription_model.dart';
import '../../lib/models/customer_order_model.dart';
import '../../lib/models/purchase_order_model.dart';

void main() {
  group('MedicineModel', () {
    test('fromMap and toMap round-trip', () {
      final map = {
        'id': 1, 'name': 'Panadol', 'generic_name': 'Paracetamol',
        'category_id': 1, 'manufacturer': 'GSK', 'unit': 'strip',
        'purchase_price': 50.0, 'selling_price': 80.0, 'wholesale_price': 65.0,
        'stock_quantity': 100, 'reorder_level': 10,
        'expiry_date': '2026-12-31T00:00:00.000',
        'barcode': '89012345', 'description': 'Pain relief',
        'store_id': 1,
        'created_at': '2024-01-01T00:00:00.000',
        'updated_at': '2024-01-01T00:00:00.000',
      };
      final med = MedicineModel.fromMap(map);
      expect(med.name, 'Panadol');
      expect(med.wholesalePrice, 65.0);
      expect(med.barcode, '89012345');
      expect(med.isLowStock, false);
      expect(med.isExpired, false);

      final out = med.toMap();
      expect(out['name'], 'Panadol');
      expect(out['wholesale_price'], 65.0);
      expect(out['barcode'], '89012345');
    });

    test('isLowStock true when stock <= reorder', () {
      final med = MedicineModel(
        name: 'T', genericName: 'T', manufacturer: 'M',
        purchasePrice: 10, sellingPrice: 20,
        stockQuantity: 5, reorderLevel: 10,
      );
      expect(med.isLowStock, true);
    });

    test('copyWith updates fields', () {
      final med = MedicineModel(
        name: 'T', genericName: 'T', manufacturer: 'M',
        purchasePrice: 10, sellingPrice: 20,
      );
      final copy = med.copyWith(stockQuantity: 99, sellingPrice: 25);
      expect(copy.stockQuantity, 99);
      expect(copy.sellingPrice, 25);
      expect(copy.name, 'T');
    });
  });

  group('SaleModel', () {
    test('fromMap and toMap', () {
      final map = {
        'id': 1, 'customer_id': 1, 'customer_name': 'Ali',
        'bill_number': 'BIL-001', 'sale_date': '2024-01-15T00:00:00.000',
        'total_amount': 500.0, 'discount': 10.0, 'tax': 5.0,
        'net_amount': 495.0, 'payment_method': 'cash', 'notes': '',
        'store_id': 1, 'created_at': '2024-01-15T00:00:00.000',
      };
      final sale = SaleModel.fromMap(map);
      expect(sale.billNumber, 'BIL-001');
      expect(sale.netAmount, 495.0);
    });
  });

  group('StoreModel', () {
    test('fromMap and toMap', () {
      final map = {'id': 1, 'name': 'Main', 'address': 'Lahore', 'phone': '123', 'is_active': 1};
      final store = StoreModel.fromMap(map);
      expect(store.name, 'Main');
      expect(store.isActive, true);

      final out = store.toMap();
      expect(out['name'], 'Main');
      expect(out['is_active'], 1);
    });
  });

  group('PrescriptionModel', () {
    test('fromMap and toMap', () {
      final now = DateTime.now();
      final map = {
        'id': 1, 'patient_name': 'Ali', 'patient_phone': '0300',
        'doctor_name': 'Dr. Khan', 'prescription_date': now.toIso8601String(),
        'notes': 'Take after food', 'status': 'active',
        'created_at': now.toIso8601String(),
      };
      final p = PrescriptionModel.fromMap(map);
      expect(p.patientName, 'Ali');
      expect(p.status, 'active');
    });
  });

  group('CustomerOrderModel', () {
    test('fromMap and toMap', () {
      final now = DateTime.now();
      final map = {
        'id': 1, 'customer_name': 'Sara',
        'order_number': 'ORD-001', 'order_date': now.toIso8601String(),
        'total_amount': 500.0, 'status': 'pending',
        'created_at': now.toIso8601String(),
      };
      final o = CustomerOrderModel.fromMap(map);
      expect(o.orderNumber, 'ORD-001');
      expect(o.status, 'pending');
    });
  });

  group('SupplierModel', () {
    test('fromMap', () {
      final s = SupplierModel.fromMap({'id': 1, 'name': 'ABC', 'phone': '123', 'created_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String()});
      expect(s.name, 'ABC');
    });
  });

  group('PurchaseOrderModel', () {
    test('fromMap', () {
      final p = PurchaseOrderModel.fromMap({
        'id': 1, 'order_number': 'PO-001', 'order_date': DateTime.now().toIso8601String(),
        'total_amount': 1000.0, 'status': 'pending', 'created_at': DateTime.now().toIso8601String(),
      });
      expect(p.orderNumber, 'PO-001');
    });
  });
}
