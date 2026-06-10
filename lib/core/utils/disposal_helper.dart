import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Helper utilities for proper resource disposal and memory management.
///
/// This helps prevent memory leaks by ensuring controllers, listeners,
/// and other resources are properly disposed.
class DisposalHelper {
  /// Safely disposes a list of ChangeNotifier providers.
  ///
  /// Catches and logs any disposal errors to prevent app crashes.
  static void safeDisposeProviders(List<ChangeNotifier> providers) {
    for (final provider in providers) {
      try {
        provider.dispose();
      } catch (e, stackTrace) {
        // Log error but don't crash
        debugPrint('Error disposing provider $provider: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Checks if a provider has a dispose method and calls it.
  ///
  /// Returns true if disposal was successful, false otherwise.
  static bool tryDispose(Object object) {
    try {
      // Check if object has a dispose method
      if (object is ChangeNotifier) {
        object.dispose();
        return true;
      }
      
      // Try to call dispose using reflection-like approach
      // (Flutter doesn't support dart:mirrors, so we use a different approach)
      final dynamic obj = object;
      if (obj is StreamSubscription) {
        obj.cancel();
        return true;
      }
      
      if (obj is ScrollController) {
        obj.dispose();
        return true;
      }
      
      if (obj is TextEditingController) {
        obj.dispose();
        return true;
      }
      
      if (obj is FocusNode) {
        obj.dispose();
        return true;
      }
      
      if (obj is AnimationController) {
        obj.dispose();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Failed to dispose $object: $e');
      return false;
    }
  }

  /// Creates a memory management checklist for providers.
  ///
  /// Use this to ensure all resources are properly managed.
  static List<String> getMemoryManagementChecklist() {
    return [
      '✓ Implement dispose() method in all ChangeNotifier providers',
      '✓ Dispose all controllers (ScrollController, TextEditingController, etc.)',
      '✓ Cancel all StreamSubscriptions',
      '✓ Dispose all FocusNodes',
      '✓ Dispose all AnimationControllers',
      '✓ Use AutomaticKeepAliveClientMixin for screens that should preserve state',
      '✓ Avoid storing large objects in providers',
      '✓ Use const constructors where possible',
      '✓ Implement pagination for large lists',
      '✓ Clear caches periodically',
      '✓ Monitor memory usage in development',
      '✓ Test for memory leaks with navigation',
    ];
  }

  /// Memory usage guidelines for different component types.
  static Map<String, String> getMemoryUsageGuidelines() {
    return {
      'Images': 'Compress images, use appropriate resolutions',
      'Lists': 'Implement pagination for > 100 items',
      'State': 'Store only necessary data in providers',
      'Cache': 'Limit cache size, implement LRU eviction',
      'Animations': 'Dispose AnimationControllers when not needed',
      'Streams': 'Cancel subscriptions when screen is disposed',
      'Controllers': 'Always dispose controllers in dispose() method',
      'Large Objects': 'Avoid storing in memory, use database/filesystem',
    };
  }
}

/// A mixin that adds automatic disposal tracking.
///
/// Add this to providers to track what needs to be disposed.
mixin DisposableMixin on ChangeNotifier {
  final List<Object> _resourcesToDispose = [];

  /// Register a resource to be disposed when the provider is disposed.
  void registerDisposable(Object resource) {
    _resourcesToDispose.add(resource);
  }

  @override
  void dispose() {
    // Dispose all registered resources
    for (final resource in _resourcesToDispose) {
      DisposalHelper.tryDispose(resource);
    }
    _resourcesToDispose.clear();
    
    super.dispose();
  }

  /// Memory usage information for debugging.
  String get memoryInfo {
    final buffer = StringBuffer();
    buffer.writeln('Disposable resources: ${_resourcesToDispose.length}');
    
    final byType = <String, int>{};
    for (final resource in _resourcesToDispose) {
      final type = resource.runtimeType.toString();
      byType[type] = (byType[type] ?? 0) + 1;
    }
    
    for (final entry in byType.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    
    return buffer.toString();
  }
}

/// Extension methods for easier resource management.
extension DisposableExtension on Object {
  /// Safely dispose this object if it has a dispose method.
  void disposeIfPossible() {
    DisposalHelper.tryDispose(this);
  }
}