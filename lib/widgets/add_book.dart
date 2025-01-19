import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addBookToList(
    String userId, String listName, Map<String, dynamic> bookData) async {
  try {
    final userListRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listName)
        .collection('books');

    // Verificar si el libro ya está en la lista
    final querySnapshot = await userListRef
        .where('workKey', isEqualTo: bookData['workKey'])
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      print("El libro ya está en la lista $listName.");
      return;
    }

    // Añadir el libro a la lista específica del usuario
    await userListRef.add(bookData);

    print("Libro añadido a la lista $listName");

    // Referencia al documento del libro en la colección global_books
    final bookRef = FirebaseFirestore.instance
        .collection('global_books')
        .doc(bookData['workKey']);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final bookSnapshot = await transaction.get(bookRef);

      if (!bookSnapshot.exists) {
        transaction.set(bookRef, {
          'title': bookData['title'],
          'author': bookData['author'],
          'cover': bookData['cover'],
          'description': bookData['description'],
          'listCount': {
            'favoritos': 0,
            'pendientes': 0,
            'leídos': 0,
          },
        });
      }

      transaction.update(bookRef, {
        'listCount.$listName': FieldValue.increment(1),
      });
    });

    print("Contador actualizado en la colección 'global_books'");
  } catch (e) {
    print("Error al añadir libro o actualizar contadores: $e");
  }
}
