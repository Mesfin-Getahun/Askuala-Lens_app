import 'package:cloud_firestore/cloud_firestore.dart';

enum AppUserRole { teacher, student }

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    required this.displayName,
    this.classSection,
  });

  final String id;
  final String username;
  final AppUserRole role;
  final String displayName;
  final String? classSection;
}

class FirestoreLoginService {
  FirestoreLoginService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _teacherCollections = ['teachers', 'teacher'];
  static const _studentCollections = ['students', 'student'];
  static const _usernameFields = [
    'username',
    'userName',
    'user_name',
    'name',
    'fullName',
  ];
  static const _passwordFields = [
    'password',
    'pass',
    'userPassword',
    'passwordHash',
  ];
  static const _classSectionFields = ['classSection', 'class', 'gradeSection'];
  static const _displayNameFields = [
    'displayName',
    'name',
    'fullName',
    'firstName',
  ];

  Future<AppUser?> signIn({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();

    for (final collectionName in _teacherCollections) {
      final teacherUser = await _findUserInCollection(
        collectionName: collectionName,
        role: AppUserRole.teacher,
        username: normalizedUsername,
        password: normalizedPassword,
      );
      if (teacherUser != null) {
        return teacherUser;
      }
    }

    for (final collectionName in _studentCollections) {
      final studentUser = await _findUserInCollection(
        collectionName: collectionName,
        role: AppUserRole.student,
        username: normalizedUsername,
        password: normalizedPassword,
      );
      if (studentUser != null) {
        return studentUser;
      }
    }

    return null;
  }

  Future<AppUser?> _findUserInCollection({
    required String collectionName,
    required AppUserRole role,
    required String username,
    required String password,
  }) async {
    for (final usernameField in _usernameFields) {
      final snapshot = await _firestore
          .collection(collectionName)
          .where(usernameField, isEqualTo: username)
          .limit(10)
          .get();

      for (final doc in snapshot.docs) {
        final user = _matchPasswordAndMap(doc, role, username, password);
        if (user != null) {
          return user;
        }
      }
    }

    final directDoc = await _firestore.collection(collectionName).doc(username).get();
    if (directDoc.exists) {
      final user = _matchPasswordAndMap(directDoc, role, username, password);
      if (user != null) {
        return user;
      }
    }

    final fallbackSnapshot = await _firestore.collection(collectionName).limit(100).get();
    for (final doc in fallbackSnapshot.docs) {
      if (_matchesUsername(doc.data(), username, doc.id)) {
        final user = _matchPasswordAndMap(doc, role, username, password);
        if (user != null) {
          return user;
        }
      }
    }

    return null;
  }

  AppUser? _matchPasswordAndMap(
    DocumentSnapshot<Map<String, dynamic>> doc,
    AppUserRole role,
    String fallbackUsername,
    String password,
  ) {
    final data = doc.data();
    if (data == null) {
      return null;
    }

    for (final passwordField in _passwordFields) {
      final storedPassword = data[passwordField]?.toString().trim();
      if (storedPassword == null || storedPassword.isEmpty) {
        continue;
      }

      if (_passwordMatches(storedPassword, password)) {
        return _mapUser(doc, role, fallbackUsername);
      }
    }

    return null;
  }

  bool _matchesUsername(
    Map<String, dynamic> data,
    String username,
    String documentId,
  ) {
    if (documentId.trim().toLowerCase() == username.toLowerCase()) {
      return true;
    }

    for (final usernameField in _usernameFields) {
      final storedUsername = data[usernameField]?.toString().trim().toLowerCase();
      if (storedUsername == username.toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  AppUser _mapUser(
    DocumentSnapshot<Map<String, dynamic>> doc,
    AppUserRole role,
    String fallbackUsername,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return AppUser(
      id: doc.id,
      username: _readFirstString(data, _usernameFields) ?? fallbackUsername,
      role: role,
      displayName: _resolveDisplayName(data, fallbackUsername),
      classSection: _readFirstString(data, _classSectionFields),
    );
  }

  String _resolveDisplayName(
    Map<String, dynamic> data,
    String fallbackUsername,
  ) {
    final firstName = data['firstName']?.toString().trim();
    final lastName = data['lastName']?.toString().trim();
    final combinedName = [firstName, lastName]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' ');
    if (combinedName.isNotEmpty) {
      return combinedName;
    }

    return _readFirstString(data, _displayNameFields) ?? fallbackUsername;
  }

  bool _passwordMatches(String storedPassword, String enteredPassword) {
    if (storedPassword == enteredPassword) {
      return true;
    }

    const plaintextPrefix = 'CLIENT_PLAINTEXT:';
    if (storedPassword.startsWith(plaintextPrefix)) {
      return storedPassword.substring(plaintextPrefix.length) == enteredPassword;
    }

    return false;
  }

  String? _readFirstString(
    Map<String, dynamic> data,
    List<String> candidateFields,
  ) {
    for (final field in candidateFields) {
      final value = data[field]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}
