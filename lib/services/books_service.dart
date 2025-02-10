import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BooksService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get currentUser => _auth.currentUser;

  /// Añade un libro a una lista del usuario y actualiza los contadores globales
  Future<void> addBookToList(
      String userId, String listName, Map<String, dynamic> bookData) async {
    try {
      // Verificar si el libro ya existe en la lista
      final userListRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('lists')
          .doc(listName)
          .collection('books');

      final querySnapshot = await userListRef
          .where('workKey', isEqualTo: bookData['workKey'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('El libro ya existe en esta lista');
      }

      // Añadir el libro a la lista
      await userListRef.add(bookData);

      // Actualizar los contadores globales
      await _updateGlobalCounters(
          bookData['workKey'].substring(7), listName, 1, bookData);
    } catch (e) {
      print("Error al añadir libro o actualizar contador: $e");
      rethrow;
    }
  }

  /// Elimina un libro de una lista del usuario y actualiza los contadores globales
  Future<void> removeBookFromList(
      String userId, String listName, String workKey) async {
    try {
      final userListRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('lists')
          .doc(listName)
          .collection('books');

      // Encontrar el documento del libro
      final querySnapshot =
          await userListRef.where('workKey', isEqualTo: workKey).get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('El libro no existe en esta lista');
      }

      // Eliminar el libro de la lista
      await querySnapshot.docs.first.reference.delete();

      // Actualizar los contadores globales
      await _updateGlobalCounters(workKey.substring(7), listName, -1, {});
    } catch (e) {
      print("Error al eliminar libro o actualizar contador: $e");
      rethrow;
    }
  }

  /// Actualiza los contadores globales de un libro en Firestore
  Future<void> _updateGlobalCounters(String workKey, String listName, int value,
      Map<String, dynamic> bookData) async {
    final globalBookRef = _firestore.collection('global_books').doc(workKey);
    await _firestore.runTransaction((transaction) async {
      final globalBookSnapshot = await transaction.get(globalBookRef);

      if (!globalBookSnapshot.exists) {
        // Si el libro no existe en global_books, lo creamos
        transaction.set(globalBookRef, {
          'title': bookData['title'],
          'author': bookData['author'],
          'listCount': {
            listName: value,
          },
        });
      } else {
        // Si el libro ya existe, actualizamos el contador
        final currentData = globalBookSnapshot.data() as Map<String, dynamic>;
        final listCount =
            Map<String, dynamic>.from(currentData['listCount'] ?? {});

        // Actualizar el contador
        listCount[listName] = (listCount[listName] ?? 0) + value;

        // Eliminar la entrada si el contador llega a 0
        if (listCount[listName] == 0) {
          listCount.remove(listName);
        }

        transaction.update(globalBookRef, {
          'listCount': listCount,
        });
      }
    });
  }

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

  /// Mueve un libro de una lista a otra
  Future<void> moveBookToList(
    String userId,
    String currentList,
    String newList,
    String workKey,
    Map<String, dynamic> bookData,
  ) async {
    try {
      // Eliminar el libro de la lista actual
      await removeBookFromList(userId, currentList, workKey);

      // Agregar el libro a la nueva lista
      await addBookToList(userId, newList, bookData);

      print('Libro movido de $currentList a $newList correctamente.');
    } catch (e) {
      print('Error al mover el libro: $e');
      throw Exception('Error al mover el libro: $e');
    }
  }

  /// Elimina un libro de una lista del usuario
  Future<void> removeBookFromListByWorkKey(
    String userId,
    String listName,
    String workKey,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('lists')
          .doc(listName)
          .collection('books')
          .doc(workKey)
          .delete();

      print('Libro eliminado de la lista $listName correctamente.');
    } catch (e) {
      print('Error al eliminar el libro: $e');
      throw Exception('Error al eliminar el libro: $e');
    }
  }
}
