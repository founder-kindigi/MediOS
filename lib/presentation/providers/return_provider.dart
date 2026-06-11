import 'package:flutter/foundation.dart';
import '../../domain/entities/return.dart';
import '../../domain/usecases/return_usecases.dart';
import '../../features/stores/services/store_service.dart';
import '../../core/utils/disposal_helper.dart';

class ReturnProvider extends ChangeNotifier with DisposableMixin {
  final LoadReturnsUseCase _loadReturnsUseCase;
  final ProcessReturnUseCase _processReturnUseCase;
  final GetReturnWithItemsUseCase _getReturnWithItemsUseCase;
  final GetTotalReturnsUseCase _getTotalReturnsUseCase;
  final StoreService _storeService;

  List<Return> _returns = [];
  bool _isLoading = false;
  String? _error;

  ReturnProvider({
    required LoadReturnsUseCase loadReturnsUseCase,
    required ProcessReturnUseCase processReturnUseCase,
    required GetReturnWithItemsUseCase getReturnWithItemsUseCase,
    required GetTotalReturnsUseCase getTotalReturnsUseCase,
    required StoreService storeService,
  })  : _loadReturnsUseCase = loadReturnsUseCase,
        _processReturnUseCase = processReturnUseCase,
        _getReturnWithItemsUseCase = getReturnWithItemsUseCase,
        _getTotalReturnsUseCase = getTotalReturnsUseCase,
        _storeService = storeService;

  List<Return> get returns => _returns;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReturns() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final storeId = _storeService.selectedStoreId;
      _returns = await _loadReturnsUseCase.call(storeId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load returns: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> processReturn(Return ret, List<ReturnItem> items) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _processReturnUseCase.call(ret, items);
      _isLoading = false;
      await loadReturns();
      return id;
    } catch (e) {
      _error = 'Failed to process return: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Return?> getReturnWithItems(int returnId) async {
    try {
      return await _getReturnWithItemsUseCase.call(returnId);
    } catch (e) {
      _error = 'Failed to get return details: $e';
      rethrow;
    }
  }

  Future<double> getTotalReturns() async {
    try {
      final storeId = _storeService.selectedStoreId;
      return await _getTotalReturnsUseCase.call(storeId);
    } catch (e) {
      _error = 'Failed to get total returns: $e';
      return 0.0;
    }
  }

  @override
  void dispose() {
    _returns = [];
    super.dispose();
  }
}
