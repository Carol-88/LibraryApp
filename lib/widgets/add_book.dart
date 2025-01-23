import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addBookToList(
    String userId, String listName, Map<String, dynamic> bookData) async {
  try {
    String sanitizedWorkKey = bookData['workKey'].substring(7);

    final userListRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listName)
        .collection('books');

    // Verificar si el libro ya está en la lista del usuario
    final querySnapshot =
        await userListRef.where('workKey', isEqualTo: sanitizedWorkKey).get();

    if (querySnapshot.docs.isNotEmpty) {
      print("El libro ya está en la lista $listName.");
      return;
    }

    // Añadir el libro a la lista del usuario
    await userListRef.add(bookData);

    print("Libro añadido a la lista $listName");

    // Referencia al documento global del libro

    final globalBookRef = FirebaseFirestore.instance
        .collection('global_books')
        .doc(sanitizedWorkKey);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Obtener el documento actual de global_books
      final globalBookSnapshot = await transaction.get(globalBookRef);

      if (!globalBookSnapshot.exists) {
        // Si el documento no existe, crearlo con el contador inicial
        transaction.set(globalBookRef, {
          'title': bookData['title'],
          'author': bookData['author'],
          'listCount': {
            listName: 1, // Solo inicializamos el contador para esta lista
          },
        });
      } else {
        // Si el documento ya existe, actualizar el contador
        final currentData = globalBookSnapshot.data() as Map<String, dynamic>;

        // Obtener los contadores actuales
        final listCount =
            Map<String, dynamic>.from(currentData['listCount'] ?? {});

        // Incrementar el contador de la lista específica
        listCount[listName] = (listCount[listName] ?? 0) + 1;

        // Actualizar el documento
        transaction.update(globalBookRef, {
          'listCount': listCount,
        });
      }
    });

    print("Contador actualizado en 'global_books/$listName'");
  } catch (e) {
    print("Error al añadir libro o actualizar contador: $e");
  }
}
