// lib/services/storage_service.dart
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/appointment_model.dart';
import '../models/contact_model.dart';
import '../models/fir_model.dart';
import '../models/memo_model.dart';

class StorageService {
  // Singleton pattern to ensure only one instance of the database service.
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'resqnow.db');

    return await openDatabase(
      path,
      version: 2, // Increased version to support new FIR media features
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// This function is called only once when the database is first created.
  Future<void> _onCreate(Database db, int version) async {
    // Create contacts table
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        isEmergency INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        relationship TEXT,
        notes TEXT
      )
    ''');

    // Create appointments table
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        department TEXT NOT NULL,
        appointmentDate INTEGER NOT NULL,
        timeSlot TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Scheduled',
        notes TEXT
      )
    ''');

    // Create enhanced FIRs table with media support
    await db.execute('''
      CREATE TABLE firs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accidentType TEXT NOT NULL,
        description TEXT NOT NULL,
        severity TEXT NOT NULL,
        location TEXT NOT NULL,
        dateTime INTEGER NOT NULL,
        status TEXT NOT NULL,
        photoPaths TEXT,
        videoPaths TEXT,
        audioPath TEXT
      )
    ''');
    
    // Create memos table
    await db.execute('''
      CREATE TABLE memos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filePath TEXT NOT NULL,
        recordedAt INTEGER NOT NULL,
        durationMs INTEGER NOT NULL DEFAULT 0,
        description TEXT
      )
    ''');

    print('✅ Database and all tables created successfully with media support.');
  }

  /// This function handles database upgrades when version changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Add media support columns to existing FIR table
      try {
        await db.execute('ALTER TABLE firs ADD COLUMN photoPaths TEXT;');
        await db.execute('ALTER TABLE firs ADD COLUMN videoPaths TEXT;');
        await db.execute('ALTER TABLE firs ADD COLUMN audioPath TEXT;');
        print('✅ FIR table upgraded with media support columns');
      } catch (e) {
        print('⚠️ Error upgrading FIR table (columns might already exist): $e');
      }
    }
  }

  // --- CONTACT OPERATIONS ---
  Future<int> insertContact(Contact contact) async {
    final db = await database;
    try {
      final result = await db.insert('contacts', contact.toMap());
      print('✅ Contact inserted successfully: ${contact.name}');
      return result;
    } catch (e) {
      print('❌ Error inserting contact: $e');
      throw Exception('Failed to insert contact');
    }
  }

  Future<List<Contact>> getAllContacts() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('contacts', orderBy: 'name ASC');
      return List.generate(maps.length, (i) => Contact.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error getting all contacts: $e');
      return [];
    }
  }

  Future<List<Contact>> getEmergencyContacts() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'contacts', 
        where: 'isEmergency = ?', 
        whereArgs: [1], 
        orderBy: 'name ASC'
      );
      return List.generate(maps.length, (i) => Contact.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error getting emergency contacts: $e');
      return [];
    }
  }

  Future<int> updateContact(Contact contact) async {
    final db = await database;
    try {
      final result = await db.update(
        'contacts', 
        contact.toMap(), 
        where: 'id = ?', 
        whereArgs: [contact.id]
      );
      print('✅ Contact updated successfully: ${contact.name}');
      return result;
    } catch (e) {
      print('❌ Error updating contact: $e');
      throw Exception('Failed to update contact');
    }
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    try {
      final result = await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
      print('✅ Contact deleted successfully');
      return result;
    } catch (e) {
      print('❌ Error deleting contact: $e');
      throw Exception('Failed to delete contact');
    }
  }

  // --- APPOINTMENT OPERATIONS ---
  Future<int> insertAppointment(Appointment appointment) async {
    final db = await database;
    try {
      final result = await db.insert('appointments', appointment.toMap());
      print('✅ Appointment inserted successfully: ${appointment.patientName}');
      return result;
    } catch (e) {
      print('❌ Error inserting appointment: $e');
      throw Exception('Failed to insert appointment');
    }
  }

  Future<List<Appointment>> getAllAppointments() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'appointments', 
        orderBy: 'appointmentDate DESC'
      );
      return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error getting all appointments: $e');
      return [];
    }
  }

  Future<int> updateAppointment(Appointment appointment) async {
    final db = await database;
    try {
      final result = await db.update(
        'appointments', 
        appointment.toMap(), 
        where: 'id = ?', 
        whereArgs: [appointment.id]
      );
      print('✅ Appointment updated successfully');
      return result;
    } catch (e) {
      print('❌ Error updating appointment: $e');
      throw Exception('Failed to update appointment');
    }
  }

  Future<int> deleteAppointment(int id) async {
    final db = await database;
    try {
      final result = await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
      print('✅ Appointment deleted successfully');
      return result;
    } catch (e) {
      print('❌ Error deleting appointment: $e');
      throw Exception('Failed to delete appointment');
    }
  }

  // --- ENHANCED FIR OPERATIONS WITH MEDIA SUPPORT ---
  Future<int> insertFIR(FIR fir) async {
    final db = await database;
    try {
      final result = await db.insert('firs', fir.toMap());
      print('✅ FIR inserted successfully with ${fir.evidenceCount} evidence file(s)');
      return result;
    } catch (e) {
      print('❌ Error inserting FIR: $e');
      throw Exception('Failed to insert FIR');
    }
  }

  Future<List<FIR>> getAllFIRs() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'firs', 
        orderBy: 'dateTime DESC'
      );
      return List.generate(maps.length, (i) => FIR.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error getting all FIRs: $e');
      return [];
    }
  }

  Future<FIR?> getFIRById(int id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'firs',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return FIR.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error getting FIR by ID: $e');
      return null;
    }
  }

  Future<List<FIR>> getFIRsByStatus(String status) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'firs',
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'dateTime DESC',
      );
      return List.generate(maps.length, (i) => FIR.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error getting FIRs by status: $e');
      return [];
    }
  }

  Future<List<FIR>> getFIRsWithEvidence() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'firs',
        where: 'photoPaths IS NOT NULL OR videoPaths IS NOT NULL OR audioPath IS NOT NULL',
        orderBy: 'dateTime DESC',
      );
      return List.generate(maps.length, (i) => FIR.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error getting FIRs with evidence: $e');
      return [];
    }
  }

  Future<int> updateFIR(FIR fir) async {
    final db = await database;
    try {
      final result = await db.update(
        'firs',
        fir.toMap(),
        where: 'id = ?',
        whereArgs: [fir.id],
      );
      print('✅ FIR updated successfully');
      return result;
    } catch (e) {
      print('❌ Error updating FIR: $e');
      throw Exception('Failed to update FIR');
    }
  }

  Future<int> updateFIRStatus(int id, String status) async {
    final db = await database;
    try {
      final result = await db.update(
        'firs',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ FIR status updated to: $status');
      return result;
    } catch (e) {
      print('❌ Error updating FIR status: $e');
      throw Exception('Failed to update FIR status');
    }
  }

  Future<int> deleteFIR(int id) async {
    final db = await database;
    try {
      // First get the FIR to access media file paths
      final fir = await getFIRById(id);
      
      if (fir != null) {
        // Delete associated media files
        await _deleteMediaFiles(fir);
      }
      
      final result = await db.delete('firs', where: 'id = ?', whereArgs: [id]);
      print('✅ FIR and associated media files deleted successfully');
      return result;
    } catch (e) {
      print('❌ Error deleting FIR: $e');
      throw Exception('Failed to delete FIR');
    }
  }

  /// Helper method to delete media files associated with a FIR
  Future<void> _deleteMediaFiles(FIR fir) async {
    try {
      // Delete photos
      if (fir.photoPaths != null) {
        for (String photoPath in fir.photoPaths!) {
          final file = File(photoPath);
          if (await file.exists()) {
            await file.delete();
            print('🗑️ Deleted photo: $photoPath');
          }
        }
      }
      
      // Delete videos
      if (fir.videoPaths != null) {
        for (String videoPath in fir.videoPaths!) {
          final file = File(videoPath);
          if (await file.exists()) {
            await file.delete();
            print('🗑️ Deleted video: $videoPath');
          }
        }
      }
      
      // Delete audio
      if (fir.audioPath != null) {
        final file = File(fir.audioPath!);
        if (await file.exists()) {
          await file.delete();
          print('🗑️ Deleted audio: ${fir.audioPath}');
        }
      }
    } catch (e) {
      print('⚠️ Error deleting some media files: $e');
    }
  }

  // --- MEMO OPERATIONS ---
  Future<int> insertMemo(Memo memo) async {
    final db = await database;
    try {
      final result = await db.insert('memos', memo.toMap());
      print('✅ Memo inserted successfully');
      return result;
    } catch (e) {
      print('❌ Error inserting memo: $e');
      throw Exception('Failed to insert memo');
    }
  }

  Future<List<Memo>> getAllMemos() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'memos', 
        orderBy: 'recordedAt DESC'
      );
      return List.generate(maps.length, (i) => Memo.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error getting all memos: $e');
      return [];
    }
  }
  
  Future<int> updateMemo(Memo memo) async {
    final db = await database;
    try {
      final result = await db.update(
        'memos', 
        memo.toMap(), 
        where: 'id = ?', 
        whereArgs: [memo.id]
      );
      print('✅ Memo updated successfully');
      return result;
    } catch (e) {
      print('❌ Error updating memo: $e');
      throw Exception('Failed to update memo');
    }
  }

  Future<int> deleteMemo(int id) async {
    final db = await database;
    try {
      // First get the memo to access the audio file path
      final List<Map<String, dynamic>> maps = await db.query(
        'memos', 
        where: 'id = ?', 
        whereArgs: [id]
      );
      
      if (maps.isNotEmpty) {
        final memo = Memo.fromMap(maps.first);
        // Delete the actual audio file
        final file = File(memo.filePath);
        if (await file.exists()) {
          await file.delete();
          print('🗑️ Deleted memo audio file: ${memo.filePath}');
        }
      }
      
      final result = await db.delete('memos', where: 'id = ?', whereArgs: [id]);
      print('✅ Memo deleted successfully');
      return result;
    } catch (e) {
      print('❌ Error deleting memo: $e');
      throw Exception('Failed to delete memo');
    }
  }

  // --- UTILITY METHODS ---
  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    try {
      final contactCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM contacts')
      ) ?? 0;
      
      final appointmentCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM appointments')
      ) ?? 0;
      
      final firCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM firs')
      ) ?? 0;
      
      final firWithEvidenceCount = Sqflite.firstIntValue(
        await db.rawQuery('''
          SELECT COUNT(*) FROM firs 
          WHERE photoPaths IS NOT NULL OR videoPaths IS NOT NULL OR audioPath IS NOT NULL
        ''')
      ) ?? 0;
      
      final memoCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM memos')
      ) ?? 0;

      return {
        'contacts': contactCount,
        'emergencyContacts': await _getEmergencyContactCount(),
        'appointments': appointmentCount,
        'firs': firCount,
        'firsWithEvidence': firWithEvidenceCount,
        'memos': memoCount,
      };
    } catch (e) {
      print('❌ Error getting database stats: $e');
      return {};
    }
  }

  Future<int> _getEmergencyContactCount() async {
    final db = await database;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM contacts WHERE isEmergency = 1')
    );
    return result ?? 0;
  }

  /// Search functionality across all data types
  Future<List<FIR>> searchFIRs(String query) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'firs',
        where: 'accidentType LIKE ? OR description LIKE ? OR location LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'dateTime DESC',
      );
      return List.generate(maps.length, (i) => FIR.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error searching FIRs: $e');
      return [];
    }
  }

  /// Clean up orphaned media files
  Future<void> cleanupOrphanedMediaFiles() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final allFIRs = await getAllFIRs();
      
      // Get all referenced media file paths
      Set<String> referencedPaths = {};
      for (final fir in allFIRs) {
        if (fir.photoPaths != null) referencedPaths.addAll(fir.photoPaths!);
        if (fir.videoPaths != null) referencedPaths.addAll(fir.videoPaths!);
        if (fir.audioPath != null) referencedPaths.add(fir.audioPath!);
      }
      
      // Find and delete orphaned files
      final dir = Directory(documentsDir.path);
      await for (final file in dir.list()) {
        if (file is File && 
            (file.path.contains('evidence_') || file.path.contains('memo_')) &&
            !referencedPaths.contains(file.path)) {
          await file.delete();
          print('🧹 Cleaned up orphaned file: ${file.path}');
        }
      }
      
      print('✅ Media cleanup completed');
    } catch (e) {
      print('⚠️ Error during media cleanup: $e');
    }
  }

  /// Export data for backup
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      return {
        'contacts': (await getAllContacts()).map((c) => c.toMap()).toList(),
        'appointments': (await getAllAppointments()).map((a) => a.toMap()).toList(),
        'firs': (await getAllFIRs()).map((f) => f.toMap()).toList(),
        'memos': (await getAllMemos()).map((m) => m.toMap()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error exporting data: $e');
      throw Exception('Failed to export data');
    }
  }

  /// Close database connection
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      print('🔒 Database connection closed');
    }
  }
}