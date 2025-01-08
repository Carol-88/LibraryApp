import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:library_app/app_styles.dart';
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
      // Asegúrate de que los datos del libro estén completos
      if (book['title'] == null ||
          book['author'] == null ||
          book['workKey'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faltan datos para agregar el libro.')),
        );
        return;
      }

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

  Future<Map<String, int>> _fetchListCounts(String workKey) async {
    try {
      final DocumentSnapshot bookDoc = await FirebaseFirestore.instance
          .collection('global_books')
          .doc(workKey)
          .get();

      if (bookDoc.exists) {
        return {
          'favoritos': bookDoc['favoritos'] ?? 0,
          'pendientes': bookDoc['pendientes'] ?? 0,
          'leídos': bookDoc['leídos'] ?? 0,
        };
      }
    } catch (e) {
      print("Error al obtener datos del libro: $e");
    }

    return {'favoritos': 0, 'pendientes': 0, 'leídos': 0};
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
          title: Center(
            child: Text(
              book['title'] ?? 'Título desconocido',
              style: GoogleFonts.lexend().copyWith(color: AppColors.accent),
            ),
          ),
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: AppColors.accent), // Icono de retroceso
            onPressed: () {
              Navigator.of(context).pop(); // Volver atrás
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.person, color: AppColors.secondary),
              onPressed: () {
                Navigator.pushNamed(context, '/user');
              },
            ),
          ]),
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
              FutureBuilder<Map<String, int>>(
                future: _fetchListCounts(book['workKey']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text(
                      'Error al cargar los datos.',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  final counts = snapshot.data ??
                      {
                        'favoritos': 0,
                        'pendientes': 0,
                        'leídos': 0,
                      };

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usuarios con este libro en sus listas:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Favoritos: ${counts['favoritos']}'),
                      Text('Pendientes: ${counts['pendientes']}'),
                      Text('Leídos: ${counts['leídos']}'),
                    ],
                  );
                },
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
