import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static DatabaseHelper? _databaseHelper;
  static Database? _database;
  
  String userTable = 'users';
  String contactTable = 'contacts';
  String appointmentTable = 'appointments';
  String memoTable = 'voice_memos';
  String medicalProfileTable = 'medical_profiles';
  
  DatabaseHelper._createInstance();
  
  factory DatabaseHelper() {
    _databaseHelper ??= DatabaseHelper._createInstance();
    return _databaseHelper!;
  }
  
  Future<Database> get database async {
    _database ??= await initializeDatabase();
    return _database!;
  }
  
  Future<Database> initializeDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'resq.db');
    
    var resqDatabase = await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
    return resqDatabase;
  }
  
  void _createDb(Database db, int newVersion) async {
    // Users table
    await db.execute('''
      CREATE TABLE $userTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        email TEXT,
        created_at TEXT NOT NULL,
        is_verified INTEGER DEFAULT 1
      )
    ''');
    
    // Contacts table
    await db.execute('''
      CREATE TABLE $contactTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        relation TEXT,
        is_emergency INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $userTable (id)
      )
    ''');
    
    // Appointments table
    await db.execute('''
      CREATE TABLE $appointmentTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        hospital_name TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        department TEXT NOT NULL,
        appointment_date TEXT NOT NULL,
        appointment_time TEXT NOT NULL,
        status TEXT DEFAULT 'scheduled',
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $userTable (id)
      )
    ''');
    
    // Voice memos table
    await db.execute('''
      CREATE TABLE $memoTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
        duration INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $userTable (id)
      )
    ''');
    
    // Medical profiles table
    await db.execute('''
      CREATE TABLE $medicalProfileTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        blood_type TEXT,
        allergies TEXT,
        medical_conditions TEXT,
        medications TEXT,
        emergency_contact TEXT,
        doctor_name TEXT,
        doctor_phone TEXT,
        insurance_info TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $userTable (id)
      )
    ''');
  }
  
  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    user['created_at'] = DateTime.now().toIso8601String();
    return await db.insert(userTable, user);
  }
  
  Future<Map<String, dynamic>?> getUser(String phone) async {
    Database db = await database;
    var result = await db.query(
      userTable,
      where: 'phone = ?',
      whereArgs: [phone],
    );
    return result.isNotEmpty ? result.first : null;
  }
  
  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await database;
    var result = await db.query(
      userTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }
  
  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    Database db = await database;
    return await db.update(
      userTable,
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Contact operations
  Future<int> insertContact(Map<String, dynamic> contact) async {
    Database db = await database;
    contact['created_at'] = DateTime.now().toIso8601String();
    return await db.insert(contactTable, contact);
  }
  
  Future<List<Map<String, dynamic>>> getContacts(int userId) async {
    Database db = await database;
    return await db.query(
      contactTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
  }
  
  Future<int> deleteContact(int id) async {
    Database db = await database;
    return await db.delete(
      contactTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<int> updateContact(int id, Map<String, dynamic> contact) async {
    Database db = await database;
    return await db.update(
      contactTable,
      contact,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Appointment operations
  Future<int> insertAppointment(Map<String, dynamic> appointment) async {
    Database db = await database;
    appointment['created_at'] = DateTime.now().toIso8601String();
    return await db.insert(appointmentTable, appointment);
  }
  
  Future<List<Map<String, dynamic>>> getAppointments(int userId) async {
    Database db = await database;
    return await db.query(
      appointmentTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'appointment_date DESC, appointment_time DESC',
    );
  }
  
  Future<int> updateAppointmentStatus(int id, String status) async {
    Database db = await database;
    return await db.update(
      appointmentTable,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Voice memo operations
  Future<int> insertVoiceMemo(Map<String, dynamic> memo) async {
    Database db = await database;
    memo['created_at'] = DateTime.now().toIso8601String();
    return await db.insert(memoTable, memo);
  }
  
  Future<List<Map<String, dynamic>>> getVoiceMemos(int userId) async {
    Database db = await database;
    return await db.query(
      memoTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }
  
  Future<int> deleteVoiceMemo(int id) async {
    Database db = await database;
    return await db.delete(
      memoTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Medical profile operations
  Future<int> insertOrUpdateMedicalProfile(Map<String, dynamic> profile) async {
    Database db = await database;
    
    // Check if profile exists
    var existing = await db.query(
      medicalProfileTable,
      where: 'user_id = ?',
      whereArgs: [profile['user_id']],
    );
    
    if (existing.isNotEmpty) {
      profile['updated_at'] = DateTime.now().toIso8601String();
      return await db.update(
        medicalProfileTable,
        profile,
        where: 'user_id = ?',
        whereArgs: [profile['user_id']],
      );
    } else {
      profile['created_at'] = DateTime.now().toIso8601String();
      profile['updated_at'] = DateTime.now().toIso8601String();
      return await db.insert(medicalProfileTable, profile);
    }
  }
  
  Future<Map<String, dynamic>?> getMedicalProfile(int userId) async {
    Database db = await database;
    var result = await db.query(
      medicalProfileTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }
}
