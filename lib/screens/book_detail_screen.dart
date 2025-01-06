// BookDetailScreen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookDetailScreen extends StatelessWidget {
  final Map<String, dynamic> book;

  BookDetailScreen({required this.book});

  Future<void> _addToList(String listName, BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Debes iniciar sesión para agregar libros a tus listas.')),
      );
      return;
    }

    try {
      final userListsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists');

      await userListsRef.doc(listName).set({
        'books': FieldValue.arrayUnion([
          {
            'title': book['title'],
            'author': book['author'],
            'cover': book['cover'],
            'workKey': book['workKey'],
          }
        ]),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Libro añadido a "$listName".')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir el libro a la lista: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(book['title'] ?? 'Título desconocido'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book['title'] ?? 'Título desconocido',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Autor: ${book['author'] ?? 'Autor desconocido'}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            book['cover'] != null
                ? Image.network(
                    'https://covers.openlibrary.org/b/id/${book['cover']}-L.jpg',
                    height: 200,
                  )
                : Container(),
            SizedBox(height: 16),
            Text(
              'Descripción:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              book['description'] ?? 'No hay descripción disponible.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            if (user != null) ...[
              Text(
                'Añadir a listas:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => _addToList('Favoritos', context),
                    child: Text('Favoritos'),
                  ),
                  ElevatedButton(
                    onPressed: () => _addToList('Pendientes', context),
                    child: Text('Pendientes'),
                  ),
                  ElevatedButton(
                    onPressed: () => _addToList('Leídos', context),
                    child: Text('Leídos'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Inicia sesión para agregar libros a tus listas.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
