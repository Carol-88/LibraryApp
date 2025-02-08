import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BooksService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Obtiene el stream de libros de una lista del usuario
  Stream<QuerySnapshot> getUserListStream(String userId, String listName) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listName)
        .collection('books')
        .snapshots();
  }

  /// Cierra la sesión del usuario
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Mueve un libro de una lista a otra
  Future<void> moveBookToList(
    String userId,
    String currentList,
    String newList,
    String bookId,
    Map<String, dynamic> bookData,
  ) async {
    try {
      // Eliminar el libro de la lista actual
      await removeBookFromList(userId, currentList, bookId);

      // Agregar el libro a la nueva lista
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('lists')
          .doc(newList)
          .collection('books')
          .doc(bookId)
          .set(bookData);

      print('Libro movido de $currentList a $newList correctamente.');
    } catch (e) {
      print('Error al mover el libro: $e');
      throw Exception('Error al mover el libro: $e');
    }
  }

  /// Elimina un libro de una lista del usuario
  Future<void> removeBookFromList(
    String userId,
    String listName,
    String bookId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('lists')
          .doc(listName)
          .collection('books')
          .doc(bookId)
          .delete();

      print('Libro eliminado de la lista $listName correctamente.');
    } catch (e) {
      print('Error al eliminar el libro: $e');
      throw Exception('Error al eliminar el libro: $e');
    }
  }
}
