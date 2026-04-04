import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/domain/student_learning_record.dart';

class StudentLearningHistoryRepository {
  StudentLearningHistoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _historyCollection(String studentId) {
    return _firestore
        .collection('students')
        .doc(studentId)
        .collection('learningHistory');
  }

  Stream<List<StudentLearningRecord>> watchLearningHistory(String studentId) {
    return _historyCollection(studentId).snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => StudentLearningRecord.fromFirestore(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return records;
    });
  }

  Future<void> saveLearningRecord({
    required String studentId,
    required String studentName,
    String? classSection,
    required StudentLearningRecord record,
  }) async {
    final collection = _historyCollection(studentId);
    final document = record.id == null ? collection.doc() : collection.doc(record.id);
    await document.set(
      record.copyWith(id: document.id).toFirestore(
        studentId: studentId,
        studentName: studentName,
        classSection: classSection,
      ),
    );
  }

  Future<void> deleteLearningRecord({
    required String studentId,
    required String recordId,
  }) {
    return _historyCollection(studentId).doc(recordId).delete();
  }
}
