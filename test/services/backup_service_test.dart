import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:medios/core/database/database_helper.dart';
import 'package:medios/core/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory docsDir;
  late DatabaseHelper dbHelper;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('medi_backup_temp');
    docsDir = Directory.systemTemp.createTempSync('medi_backup_docs');

    // Intercept path_provider calls to return our physical test directories
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return docsDir.path;
        }
        if (methodCall.method == 'getTemporaryDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      if (docsDir.existsSync()) {
        docsDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    // Clear out databases and locator configurations between runs
    DatabaseHelper.setTestDatabase(null);
    dbHelper = DatabaseHelper();
    
    // Explicitly open the database to ensure tables are created on disk
    final db = await dbHelper.database;
    
    // Add some test records
    await db.insert('customers', {
      'name': 'Backup Test Customer',
      'phone': '123-456-7890',
      'created_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    await dbHelper.closeDatabase();
    // Delete files inside docsDir and tempDir to start fresh
    try {
      if (docsDir.existsSync()) {
        for (final entity in docsDir.listSync()) {
          entity.deleteSync(recursive: true);
        }
      }
      if (tempDir.existsSync()) {
        for (final entity in tempDir.listSync()) {
          entity.deleteSync(recursive: true);
        }
      }
    } catch (_) {}
  });

  group('BackupService Tests', () {
    test('createBackup successfully creates an encrypted backup file', () async {
      final service = BackupService(databaseHelper: dbHelper);
      
      final result = await service.createBackup(notes: 'Sprint 1 Backup Test');
      
      expect(result.isSuccess, isTrue, reason: result.errorMessage);
      expect(result.filePath, isNotNull);
      expect(File(result.filePath!).existsSync(), isTrue);
      expect(result.metadata, isNotNull);
      expect(result.metadata!.notes, equals('Sprint 1 Backup Test'));
      expect(result.metadata!.app, equals('MediOS'));
      expect(result.metadata!.recordCounts['customers'], equals(1));
    });

    test('validateBackupFile verifies validity and detects corruption', () async {
      final service = BackupService(databaseHelper: dbHelper);
      
      final result = await service.createBackup(notes: 'Valid backup');
      expect(result.isSuccess, isTrue);
      
      // 1. Validate a valid file
      final validation = await service.validateBackupFile(result.filePath!);
      expect(validation.isValid, isTrue);
      expect(validation.metadata, isNotNull);
      expect(validation.error, isNull);

      // 2. Validate non-existent file
      final validationNonExistent = await service.validateBackupFile(p.join(tempDir.path, 'non_existent.mediosbackup'));
      expect(validationNonExistent.isValid, isFalse);
      expect(validationNonExistent.error, contains('File not found'));

      // 3. Validate corrupt json file
      final corruptFile = File(p.join(tempDir.path, 'corrupt.mediosbackup'));
      final padding = ' ' * 100;
      await corruptFile.writeAsString('{invalid json$padding');
      final validationCorrupt = await service.validateBackupFile(corruptFile.path);
      expect(validationCorrupt.isValid, isFalse);
      expect(validationCorrupt.error, contains('Invalid JSON format'));

      // 4. Validate file with missing fields
      final missingFieldsFile = File(p.join(tempDir.path, 'missing.mediosbackup'));
      await missingFieldsFile.writeAsString(jsonEncode({
        'only_metadata': {},
        'dummy_padding': 'x' * 100,
      }));
      final validationMissing = await service.validateBackupFile(missingFieldsFile.path);
      expect(validationMissing.isValid, isFalse);
      expect(validationMissing.error, contains('Missing required backup fields'));
    });

    test('listBackups lists all available backup files', () async {
      final service = BackupService(databaseHelper: dbHelper);
      
      // Initially, no backups
      final list1 = await service.listBackups();
      expect(list1, isEmpty);
      
      // Create a backup
      await service.createBackup(notes: 'First');
      // Wait a bit to ensure timestamp/file name difference if we create multiple
      await Future.delayed(const Duration(seconds: 1));
      await service.createBackup(notes: 'Second');
      
      final list2 = await service.listBackups();
      expect(list2.length, equals(2));
      expect(list2[0].metadata.notes, equals('Second')); // Sorted newest first
      expect(list2[1].metadata.notes, equals('First'));
    });

    test('deleteBackup deletes backup file correctly', () async {
      final service = BackupService(databaseHelper: dbHelper);
      final result = await service.createBackup();
      expect(result.isSuccess, isTrue);
      
      final fileExistsBefore = File(result.filePath!).existsSync();
      expect(fileExistsBefore, isTrue);
      
      final deleteResult = await service.deleteBackup(result.filePath!);
      expect(deleteResult, isTrue);
      
      final fileExistsAfter = File(result.filePath!).existsSync();
      expect(fileExistsAfter, isFalse);
      
      // Deleting again should return false
      final deleteResultAgain = await service.deleteBackup(result.filePath!);
      expect(deleteResultAgain, isFalse);
    });

    test('restoreBackup successfully restores database and recovers data', () async {
      final service = BackupService(databaseHelper: dbHelper);
      
      // Create backup with 1 customer
      final backupResult = await service.createBackup(notes: 'Restore source');
      expect(backupResult.isSuccess, isTrue);
      
      // Modify database by adding another customer and updating the first
      final db = await dbHelper.database;
      await db.update('customers', {'name': 'Modified Name'}, where: 'id = ?', whereArgs: [1]);
      await db.insert('customers', {
        'name': 'New Customer',
        'phone': '987-654-3210',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      final customersBeforeRestore = await db.query('customers');
      expect(customersBeforeRestore.length, equals(2));
      expect(customersBeforeRestore.firstWhere((c) => c['id'] == 1)['name'], equals('Modified Name'));
      
      // Perform restore
      final restoreResult = await service.restoreBackup(backupResult.filePath!);
      expect(restoreResult.isSuccess, isTrue, reason: restoreResult.errorMessage);
      
      // Re-fetch database helper instance and database to verify restoration
      final dbAfter = await dbHelper.database;
      final customersAfterRestore = await dbAfter.query('customers');
      
      // Verify data is rolled back to original state (1 customer, original name)
      expect(customersAfterRestore.length, equals(1));
      expect(customersAfterRestore.first['name'], equals('Backup Test Customer'));
    });

    test('restoreBackup rolls back and keeps original database if validation fails', () async {
      final service = BackupService(databaseHelper: dbHelper);
      
      // 1. Create a corrupt backup file (wrong checksum or invalid structure)
      final backupResult = await service.createBackup(notes: 'Original database state');
      expect(backupResult.isSuccess, isTrue);
      
      // Insert a new record in the current database
      final db = await dbHelper.database;
      await db.insert('customers', {
        'name': 'Post-Backup Customer',
        'phone': '111-222-3333',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Let's verify it is there
      final countBeforeRestore = await dbHelper.getCount('customers');
      expect(countBeforeRestore, equals(2));
      
      // Create a corrupted backup file manually
      final corruptFile = File(p.join(tempDir.path, 'bad_checksum.mediosbackup'));
      final validContent = await File(backupResult.filePath!).readAsString();
      final decoded = jsonDecode(validContent) as Map<String, dynamic>;
      // Corrupt the database base64 payload to cause decryption failure or checksum mismatch
      decoded['database'] = base64Encode(utf8.encode('this is corrupt database content'));
      await corruptFile.writeAsString(jsonEncode(decoded));
      
      // Attempt restore
      final restoreResult = await service.restoreBackup(corruptFile.path);
      
      expect(restoreResult.isSuccess, isFalse);
      expect(restoreResult.errorMessage, isNotNull);
      
      // Verify database was not changed or was successfully rolled back to state before restore attempt
      final dbAfter = await dbHelper.database;
      final countAfterRestore = await dbAfter.rawQuery('SELECT COUNT(*) as count FROM customers');
      expect(countAfterRestore.first['count'], equals(2));
    });
  });
}
