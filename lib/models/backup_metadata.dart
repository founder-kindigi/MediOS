import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Metadata for MediOS backup files.
@immutable
class BackupMetadata {
  final String app;
  final int backupVersion;
  final int databaseVersion;
  final DateTime createdAt;
  final String? storeId;
  final String checksum;
  final Map<String, int> recordCounts;
  final String? notes;

  const BackupMetadata({
    required this.app,
    required this.backupVersion,
    required this.databaseVersion,
    required this.createdAt,
    this.storeId,
    required this.checksum,
    required this.recordCounts,
    this.notes,
  });

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      app: json['app'] as String,
      backupVersion: json['backupVersion'] as int,
      databaseVersion: json['databaseVersion'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      storeId: json['storeId'] as String?,
      checksum: json['checksum'] as String,
      recordCounts: Map<String, int>.from(json['recordCounts'] as Map),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app': app,
      'backupVersion': backupVersion,
      'databaseVersion': databaseVersion,
      'createdAt': createdAt.toIso8601String(),
      if (storeId != null) 'storeId': storeId,
      'checksum': checksum,
      'recordCounts': recordCounts,
      if (notes != null) 'notes': notes,
    };
  }

  String toPrettyJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }

  /// Validates metadata for compatibility.
  /// Returns error message if invalid, null if valid.
  String? validate() {
    if (app != 'MediOS') {
      return 'Invalid app: $app (expected: MediOS)';
    }
    
    if (backupVersion != 1) {
      return 'Unsupported backup version: $backupVersion (expected: 1)';
    }
    
    if (databaseVersion > 11) {
      return 'Unsupported database version: $databaseVersion (max supported: 11)';
    }
    
    if (!checksum.startsWith('sha256:')) {
      return 'Invalid checksum format: $checksum';
    }
    
    return null;
  }

  /// Gets formatted display information.
  String get displayInfo {
    final buffer = StringBuffer();
    buffer.writeln('App: $app');
    buffer.writeln('Backup Version: $backupVersion');
    buffer.writeln('Database Version: $databaseVersion');
    buffer.writeln('Created: ${createdAt.toLocal()}');
    buffer.writeln('Total Records: $_totalRecords');
    
    if (storeId != null) {
      buffer.writeln('Store ID: $storeId');
    }
    
    if (notes != null) {
      buffer.writeln('Notes: $notes');
    }
    
    return buffer.toString();
  }

  int get _totalRecords {
    return recordCounts.values.fold(0, (sum, count) => sum + count);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupMetadata &&
          runtimeType == other.runtimeType &&
          app == other.app &&
          backupVersion == other.backupVersion &&
          databaseVersion == other.databaseVersion &&
          createdAt == other.createdAt &&
          storeId == other.storeId &&
          checksum == other.checksum &&
          mapEquals(recordCounts, other.recordCounts) &&
          notes == other.notes;

  @override
  int get hashCode =>
      app.hashCode ^
      backupVersion.hashCode ^
      databaseVersion.hashCode ^
      createdAt.hashCode ^
      storeId.hashCode ^
      checksum.hashCode ^
      recordCounts.hashCode ^
      notes.hashCode;

  @override
  String toString() {
    return 'BackupMetadata(app: $app, version: $backupVersion, dbVersion: $databaseVersion, records: $_totalRecords)';
  }
}

/// Result of a backup operation.
sealed class BackupResult {
  const BackupResult();

  factory BackupResult.success({
    required String filePath,
    required BackupMetadata metadata,
    String message = 'Backup created successfully',
  }) {
    return BackupSuccess(
      filePath: filePath,
      metadata: metadata,
      message: message,
    );
  }

  factory BackupResult.failure({
    required String error,
    StackTrace? stackTrace,
  }) = BackupFailure;

  bool get isSuccess => this is BackupSuccess;
  bool get isFailure => this is BackupFailure;

  String? get filePath => switch (this) {
    BackupSuccess(:final filePath) => filePath,
    _ => null,
  };

  BackupMetadata? get metadata => switch (this) {
    BackupSuccess(:final metadata) => metadata,
    _ => null,
  };

  String? get errorMessage => switch (this) {
    BackupFailure(:final error) => error,
    _ => null,
  };

  String? get successMessage => switch (this) {
    BackupSuccess(:final message) => message,
    _ => null,
  };

  String? get message => successMessage;
  String? get error => errorMessage;
}

class BackupSuccess extends BackupResult {
  @override
  final String filePath;
  @override
  final BackupMetadata metadata;
  @override
  final String message;

  const BackupSuccess({
    required this.filePath,
    required this.metadata,
    required this.message,
  });
}

class BackupFailure extends BackupResult {
  @override
  final String error;
  final StackTrace? stackTrace;

  const BackupFailure({
    required this.error,
    this.stackTrace,
  });
}

/// Result of a restore operation.
sealed class RestoreResult {
  const RestoreResult();

  factory RestoreResult.success({
    required String message,
    String? originalBackupPath,
  }) = RestoreSuccess;

  factory RestoreResult.failure({
    required String error,
    StackTrace? stackTrace,
  }) = RestoreFailure;

  bool get isSuccess => this is RestoreSuccess;
  bool get isFailure => this is RestoreFailure;

  String? get errorMessage => switch (this) {
    RestoreFailure(:final error) => error,
    _ => null,
  };

  String? get successMessage => switch (this) {
    RestoreSuccess(:final message) => message,
    _ => null,
  };

  String? get message => successMessage;
  String? get error => errorMessage;

  String? get originalBackupPath => switch (this) {
    RestoreSuccess(:final originalBackupPath) => originalBackupPath,
    _ => null,
  };
}

class RestoreSuccess extends RestoreResult {
  @override
  final String message;
  @override
  final String? originalBackupPath;

  const RestoreSuccess({
    required this.message,
    this.originalBackupPath,
  });
}

class RestoreFailure extends RestoreResult {
  @override
  final String error;
  final StackTrace? stackTrace;

  const RestoreFailure({
    required this.error,
    this.stackTrace,
  });
}

/// Result of backup validation.
class BackupValidation {
  final bool isValid;
  final String? error;
  final BackupMetadata? metadata;

  const BackupValidation({
    required this.isValid,
    this.error,
    this.metadata,
  });

  factory BackupValidation.valid(BackupMetadata metadata) {
    return BackupValidation(
      isValid: true,
      metadata: metadata,
    );
  }

  factory BackupValidation.invalid(String error) {
    return BackupValidation(
      isValid: false,
      error: error,
    );
  }
}