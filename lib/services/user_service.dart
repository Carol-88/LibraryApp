import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<QuerySnapshot> getUserListStream(String userId, String listName) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listName)
        .collection('books')
        .snapshots();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> moveBookToList(
    String userId,
    String currentList,
    String newList,
    String bookId,
    Map<String, dynamic> bookData,
  ) async {
    try {
      await removeBookFromList(userId, currentList, bookId);
      // Aquí podrías añadir la lógica para agregar el libro a la nueva lista
    } catch (e) {
      throw Exception('Error al mover el libro');
    }
  }

  Future<void> removeBookFromList(
    String userId,
    String listName,
    String bookId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listName)
        .collection('books')
        .doc(bookId)
        .delete();
  }
}
