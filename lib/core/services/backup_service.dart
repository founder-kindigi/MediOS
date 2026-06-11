import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../../core/database/database_helper.dart';
import '../../models/backup_metadata.dart';

/// Service for creating and restoring MediOS backups.
///
/// Backup files are encrypted and include metadata for validation.
/// Format: medios_backup_YYYY-MM-DD_HH-mm.mediosbackup
class BackupService {
  static const String _backupExtension = '.mediosbackup';
  static const int _backupVersion = 1;
  static const String _appName = 'MediOS';
  
  // Encryption key (in production, this should be derived from user password)
  // For now, using a fixed key - should be improved for production
  static const String _encryptionKey = 'MediOS-Backup-Key-2026-V1';
  static const String _encryptionIV = 'InitialVector16B';
  
  final DatabaseHelper _databaseHelper;
  
  BackupService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Creates a new backup of the current database.
  Future<BackupResult> createBackup({String? notes}) async {
    try {
      // Get database path
      final dbPath = await _databaseHelper.databasePath;
      if (!File(dbPath).existsSync()) {
        return BackupResult.failure(
          error: 'Database file not found at: $dbPath',
        );
      }

      // Read database file
      final dbBytes = await File(dbPath).readAsBytes();
      final dbSize = dbBytes.length;
      
      if (dbSize == 0) {
        return BackupResult.failure(
          error: 'Database file is empty',
        );
      }

      // Get record counts for metadata
      final recordCounts = await _getRecordCounts();
      
      // Create metadata
      final metadata = BackupMetadata(
        app: _appName,
        backupVersion: _backupVersion,
        databaseVersion: await _databaseHelper.getVersion(),
        createdAt: DateTime.now().toUtc(),
        storeId: await _getStoreId(),
        checksum: _calculateChecksum(dbBytes),
        recordCounts: recordCounts,
        notes: notes,
      );

      // Encrypt database
      final encryptedDb = await _encryptData(dbBytes);
      
      // Create backup structure
      final backupData = {
        'metadata': metadata.toJson(),
        'database': base64Encode(encryptedDb),
      };

      // Write backup file
      final backupFile = await _createBackupFile();
      await backupFile.writeAsString(jsonEncode(backupData));
      
      // Verify backup file
      final verification = await validateBackupFile(backupFile.path);
      if (!verification.isValid) {
        await backupFile.delete();
        return BackupResult.failure(
          error: 'Backup verification failed: ${verification.error}',
        );
      }

      return BackupResult.success(
        filePath: backupFile.path,
        metadata: metadata,
        message: 'Backup created successfully. Size: ${_formatFileSize(backupFile.lengthSync())}',
      );
    } catch (e, stackTrace) {
      return BackupResult.failure(
        error: 'Failed to create backup: $e',
        stackTrace: stackTrace,
      );
    }
  }

  /// Restores a database from a backup file.
  Future<RestoreResult> restoreBackup(String backupFilePath) async {
    File? temporaryBackup;
    
    try {
      // Validate backup file
      final validation = await validateBackupFile(backupFilePath);
      if (!validation.isValid) {
        return RestoreResult.failure(
          error: 'Invalid backup file: ${validation.error}',
        );
      }

      final metadata = validation.metadata!;
      
      // Create temporary backup of current database
      temporaryBackup = await _createTemporaryBackup();
      if (temporaryBackup == null) {
        return RestoreResult.failure(
          error: 'Failed to create temporary backup of current database',
        );
      }

      // Read and parse backup file
      final backupFile = File(backupFilePath);
      final backupContent = await backupFile.readAsString();
      final backupJson = jsonDecode(backupContent) as Map<String, dynamic>;
      
      // Decrypt database
      final encryptedDb = base64Decode(backupJson['database'] as String);
      final decryptedDb = await _decryptData(encryptedDb);
      
      // Verify checksum
      final expectedChecksum = metadata.checksum;
      final actualChecksum = _calculateChecksum(decryptedDb);
      
      if (expectedChecksum != actualChecksum) {
        return RestoreResult.failure(
          error: 'Checksum mismatch. Expected: $expectedChecksum, Got: $actualChecksum',
        );
      }

      // Get current database path
      final currentDbPath = await _databaseHelper.databasePath;
      final currentDbFile = File(currentDbPath);
      
      // Close database connection before modifying the database file!
      await _databaseHelper.closeDatabase();
      
      // Backup current database file
      await currentDbFile.copy('${currentDbPath}.pre-restore-${DateTime.now().millisecondsSinceEpoch}');
      
      // Write restored database
      await currentDbFile.writeAsBytes(decryptedDb);
      
      // Verify restored database
      final restoreValidation = await _verifyRestoredDatabase(currentDbPath);
      if (!restoreValidation.isValid) {
        // Restore from temporary backup
        await _restoreFromBackup(temporaryBackup.path);
        return RestoreResult.failure(
          error: 'Restored database verification failed: ${restoreValidation.error}. Original database restored.',
        );
      }

      // Clean up temporary files
      await temporaryBackup.delete();
      
      return RestoreResult.success(
        message: 'Database restored successfully from backup created on ${metadata.createdAt.toLocal()}',
        originalBackupPath: temporaryBackup.path,
      );
    } catch (e, stackTrace) {
      // Attempt to restore from temporary backup
      if (temporaryBackup != null && temporaryBackup.existsSync()) {
        try {
          await _restoreFromBackup(temporaryBackup.path);
          await temporaryBackup.delete();
        } catch (restoreError) {
          // Log but don't fail the whole operation
          debugPrint('Failed to restore from temporary backup: $restoreError');
        }
      }
      
      return RestoreResult.failure(
        error: 'Restore failed: $e',
        stackTrace: stackTrace,
      );
    }
  }

  /// Validates a backup file without restoring it.
  Future<BackupValidation> validateBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      
      // Check file exists
      if (!file.existsSync()) {
        return BackupValidation.invalid('File not found: $filePath');
      }
      
      // Check file size
      final fileSize = file.lengthSync();
      if (fileSize < 100) { // Minimum reasonable size
        return BackupValidation.invalid('File too small: ${_formatFileSize(fileSize)}');
      }
      
      // Parse JSON
      final content = await file.readAsString();
      Map<String, dynamic> json;
      try {
        json = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        return BackupValidation.invalid('Invalid JSON format: $e');
      }
      
      // Check required fields
      if (!json.containsKey('metadata') || !json.containsKey('database')) {
        return BackupValidation.invalid('Missing required backup fields');
      }
      
      // Parse metadata
      final metadataJson = json['metadata'] as Map<String, dynamic>;
      final metadata = BackupMetadata.fromJson(metadataJson);
      
      // Validate metadata
      final metadataError = metadata.validate();
      if (metadataError != null) {
        return BackupValidation.invalid(metadataError);
      }
      
      // Check database data
      final dbData = json['database'] as String;
      if (dbData.isEmpty) {
        return BackupValidation.invalid('Empty database data');
      }
      
      // Try to decode and decrypt (partial check)
      try {
        final encryptedDb = base64Decode(dbData);
        if (encryptedDb.isEmpty) {
          return BackupValidation.invalid('Empty encrypted database');
        }
      } catch (e) {
        return BackupValidation.invalid('Invalid database encoding: $e');
      }
      
      return BackupValidation.valid(metadata);
    } catch (e) {
      return BackupValidation.invalid('Validation error: $e');
    }
  }

  /// Gets information about existing backups in the backup directory.
  Future<List<BackupInfo>> listBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!backupDir.existsSync()) {
        return [];
      }
      
      final files = backupDir.listSync().whereType<File>().toList();
      final backups = <BackupInfo>[];
      
      for (final file in files) {
        if (path.extension(file.path) == _backupExtension) {
          try {
            final validation = await validateBackupFile(file.path);
            if (validation.isValid) {
              backups.add(BackupInfo(
                path: file.path,
                metadata: validation.metadata!,
                fileSize: file.lengthSync(),
                lastModified: file.lastModifiedSync(),
              ));
            }
          } catch (e) {
            // Skip invalid backup files
            debugPrint('Skipping invalid backup file ${file.path}: $e');
          }
        }
      }
      
      // Sort by creation date (newest first)
      backups.sort((a, b) => b.metadata.createdAt.compareTo(a.metadata.createdAt));
      
      return backups;
    } catch (e) {
      debugPrint('Error listing backups: $e');
      return [];
    }
  }

  /// Deletes a backup file.
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting backup $filePath: $e');
      return false;
    }
  }

  // Private helper methods

  Future<Map<String, int>> _getRecordCounts() async {
    final db = await _databaseHelper.database;
    
    final tables = [
      'medicines',
      'customers',
      'suppliers',
      'sales',
      'purchase_orders',
      'inventory_transactions',
      'returns',
      'prescriptions',
      'customer_orders',
      'users',
    ];
    
    final counts = <String, int>{};
    
    for (final table in tables) {
      try {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        final count = result.first['count'] as int? ?? 0;
        counts[table] = count;
      } catch (e) {
        counts[table] = 0;
      }
    }
    
    return counts;
  }

  Future<String?> _getStoreId() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query('stores', limit: 1);
      if (result.isNotEmpty) {
        return result.first['id'].toString();
      }
    } catch (e) {
      // Store table might not exist in older versions
    }
    return null;
  }

  String _calculateChecksum(List<int> data) {
    final hash = sha256.convert(data);
    return 'sha256:$hash';
  }

  Future<Uint8List> _encryptData(Uint8List data) async {
    final key = encrypt.Key.fromUtf8(
      (_encryptionKey.length > 32 ? _encryptionKey.substring(0, 32) : _encryptionKey).padRight(32),
    );
    final iv = encrypt.IV.fromUtf8(
      (_encryptionIV.length > 16 ? _encryptionIV.substring(0, 16) : _encryptionIV).padRight(16),
    );
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    return encrypted.bytes;
  }

  Future<Uint8List> _decryptData(Uint8List data) async {
    final key = encrypt.Key.fromUtf8(
      (_encryptionKey.length > 32 ? _encryptionKey.substring(0, 32) : _encryptionKey).padRight(32),
    );
    final iv = encrypt.IV.fromUtf8(
      (_encryptionIV.length > 16 ? _encryptionIV.substring(0, 16) : _encryptionIV).padRight(16),
    );
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypt.Encrypted(data);
    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
    return Uint8List.fromList(decrypted);
  }

  Future<File> _createBackupFile() async {
    final backupDir = await _getBackupDirectory();
    final timestamp = DateTime.now().toUtc();
    final filename = 'medios_backup_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}-${timestamp.second.toString().padLeft(2, '0')}$_backupExtension';
    return File(path.join(backupDir.path, filename));
  }

  Future<Directory> _getBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(documentsDir.path, 'medios_backups'));
    
    if (!backupDir.existsSync()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }

  Future<File?> _createTemporaryBackup() async {
    try {
      final dbPath = await _databaseHelper.databasePath;
      final dbFile = File(dbPath);
      
      if (!dbFile.existsSync()) {
        return null;
      }
      
      // Close database connection before copying!
      await _databaseHelper.closeDatabase();
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(
        tempDir.path,
        'medios_temp_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      ));
      
      await dbFile.copy(tempFile.path);
      return tempFile;
    } catch (e) {
      debugPrint('Failed to create temporary backup: $e');
      return null;
    }
  }

  Future<void> _restoreFromBackup(String backupFilePath) async {
    try {
      final dbPath = await _databaseHelper.databasePath;
      final backupFile = File(backupFilePath);
      
      // Ensure database is closed before copying!
      await _databaseHelper.closeDatabase();
      
      if (backupFile.existsSync()) {
        await backupFile.copy(dbPath);
      }
    } catch (e) {
      debugPrint('Failed to restore from backup $backupFilePath: $e');
      rethrow;
    }
  }

  Future<BackupValidation> _verifyRestoredDatabase(String dbPath) async {
    try {
      // Try to open the database
      final db = await _databaseHelper.openDatabaseAtPath(dbPath);
      
      // Check a few key tables
      final tables = ['medicines', 'sales', 'customers'];
      for (final table in tables) {
        try {
          await db.rawQuery('SELECT 1 FROM $table LIMIT 1');
        } catch (e) {
          return BackupValidation.invalid('Table $table not found or corrupted: $e');
        }
      }
      
      await db.close();
      return BackupValidation.valid(BackupMetadata(
        app: _appName,
        backupVersion: _backupVersion,
        databaseVersion: await _databaseHelper.getVersion(),
        createdAt: DateTime.now(),
        storeId: await _getStoreId(),
        checksum: '',
        recordCounts: {},
      ));
    } catch (e) {
      return BackupValidation.invalid('Database verification failed: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Information about a backup file.
class BackupInfo {
  final String path;
  final BackupMetadata metadata;
  final int fileSize;
  final DateTime lastModified;

  BackupInfo({
    required this.path,
    required this.metadata,
    required this.fileSize,
    required this.lastModified,
  });

  String get fileName => path.split(Platform.pathSeparator).last;
  String get displaySize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Result of database verification.
class DatabaseVerification {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? details;

  const DatabaseVerification({
    required this.isValid,
    this.error,
    this.details,
  });
}