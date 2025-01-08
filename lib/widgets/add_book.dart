import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addBookToList(
    String userId, String listName, Map<String, dynamic> bookData) async {
  try {
    // Añadir el libro a la lista específica del usuario
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listName)
        .collection('books')
        .add(bookData);

    print("Libro añadido a la lista $listName");

    // Actualizar la colección "global_books" en la raíz de Firestore
    final bookRef = FirebaseFirestore.instance
        .collection('global_books')
        .doc(bookData['workKey']); // Aquí eliminamos .snapshots()

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Obtener el documento actual
      final bookSnapshot = await transaction.get(bookRef);

      if (!bookSnapshot.exists) {
        // Si el libro no existe, crearlo con contadores iniciales
        transaction.set(bookRef, {
          'title': bookData['title'],
          'author': bookData['author'],
          'cover': bookData['cover'],
          'favoritos': 0,
          'pendientes': 0,
          'leídos': 0,
        });
      }

      // Incrementar el contador de la lista correspondiente
      transaction.update(bookRef, {
        listName: FieldValue.increment(1),
      });
    });

    print("Contador actualizado en la colección 'global_books'");
  } catch (e) {
    print("Error al añadir libro o actualizar contadores: $e");
  }
}
