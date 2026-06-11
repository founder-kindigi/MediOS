import '../entities/prescription.dart';

abstract class PrescriptionRepository {
  /// Fetch all prescriptions for a specific store, optionally filtered by status.
  Future<List<Prescription>> getAll(int storeId, {String? status});

  /// Create a new prescription with its items.
  Future<int> create(Prescription prescription);

  /// Update the status of a prescription.
  Future<void> updateStatus(int id, String status);

  /// Get a single prescription including all its items.
  Future<Prescription?> getById(int id);
}
