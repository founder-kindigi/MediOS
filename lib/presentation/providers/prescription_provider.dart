import 'package:flutter/foundation.dart';
import '../../domain/entities/prescription.dart';
import '../../domain/usecases/prescription_usecases.dart';
import '../../features/stores/services/store_service.dart';
import '../../core/utils/disposal_helper.dart';

class PrescriptionProvider extends ChangeNotifier with DisposableMixin {
  final LoadPrescriptionsUseCase _loadPrescriptionsUseCase;
  final CreatePrescriptionUseCase _createPrescriptionUseCase;
  final UpdatePrescriptionStatusUseCase _updateStatusUseCase;
  final GetPrescriptionByIdUseCase _getPrescriptionByIdUseCase;
  final StoreService _storeService;

  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  String? _error;

  PrescriptionProvider({
    required LoadPrescriptionsUseCase loadPrescriptionsUseCase,
    required CreatePrescriptionUseCase createPrescriptionUseCase,
    required UpdatePrescriptionStatusUseCase updateStatusUseCase,
    required GetPrescriptionByIdUseCase getPrescriptionByIdUseCase,
    required StoreService storeService,
  })  : _loadPrescriptionsUseCase = loadPrescriptionsUseCase,
        _createPrescriptionUseCase = createPrescriptionUseCase,
        _updateStatusUseCase = updateStatusUseCase,
        _getPrescriptionByIdUseCase = getPrescriptionByIdUseCase,
        _storeService = storeService;

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPrescriptions({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      _prescriptions = await _loadPrescriptionsUseCase.call(storeId, status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load prescriptions: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> createPrescription(Prescription prescription) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      final prescriptionWithStore = prescription.copyWith(storeId: storeId);
      final id = await _createPrescriptionUseCase.call(prescriptionWithStore);
      _isLoading = false;
      await loadPrescriptions();
      return id;
    } catch (e) {
      _error = 'Failed to create prescription: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateStatus(int id, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _updateStatusUseCase.call(id, status);
      _isLoading = false;
      await loadPrescriptions();
    } catch (e) {
      _error = 'Failed to update prescription status: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Prescription?> getById(int id) async {
    try {
      return await _getPrescriptionByIdUseCase.call(id);
    } catch (e) {
      _error = 'Failed to get prescription details: $e';
      rethrow;
    }
  }

  @override
  void dispose() {
    _prescriptions = [];
    super.dispose();
  }
}
