import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addBookToList(
    String userId, String listName, Map<String, dynamic> bookData) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listName)
        .collection('books')
        .add(bookData);

    print("Libro añadido a la lista $listName");
  } catch (e) {
    print("Error al añadir libro: $e");
  }
}
