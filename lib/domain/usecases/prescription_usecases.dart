import '../entities/prescription.dart';
import '../repositories/prescription_repository.dart';

class LoadPrescriptionsUseCase {
  final PrescriptionRepository _repository;

  LoadPrescriptionsUseCase(this._repository);

  Future<List<Prescription>> call(int storeId, {String? status}) {
    return _repository.getAll(storeId, status: status);
  }
}

class CreatePrescriptionUseCase {
  final PrescriptionRepository _repository;

  CreatePrescriptionUseCase(this._repository);

  Future<int> call(Prescription prescription) {
    return _repository.create(prescription);
  }
}

class UpdatePrescriptionStatusUseCase {
  final PrescriptionRepository _repository;

  UpdatePrescriptionStatusUseCase(this._repository);

  Future<void> call(int id, String status) {
    return _repository.updateStatus(id, status);
  }
}

class GetPrescriptionByIdUseCase {
  final PrescriptionRepository _repository;

  GetPrescriptionByIdUseCase(this._repository);

  Future<Prescription?> call(int id) {
    return _repository.getById(id);
  }
}
