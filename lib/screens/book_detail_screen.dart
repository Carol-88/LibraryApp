import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_app/widgets/add_book.dart';

class BookDetailScreen extends StatelessWidget {
  final Map<String, dynamic> book;

  BookDetailScreen({required this.book});

  Future<void> _addToList(String listName, BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Debes iniciar sesión para agregar libros a tus listas.'),
        ),
      );
      return;
    }

    try {
      await addBookToList(user.uid, listName, {
        'title': book['title'],
        'author': book['author'],
        'cover': book['cover'],
        'workKey': book['workKey'],
      });

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
        child: SingleChildScrollView(
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
                  : Icon(Icons.book, size: 100),
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
                      onPressed: () => _addToList('favoritos', context),
                      child: Text('Favoritos',
                          style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      onPressed: () => _addToList('pendientes', context),
                      child: Text('Pendientes',
                          style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      onPressed: () => _addToList('leídos', context),
                      child:
                          Text('Leídos', style: TextStyle(color: Colors.black)),
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
      ),
    );
  }
}
