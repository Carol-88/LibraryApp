import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:library_app/app_styles.dart';
import 'package:library_app/screens/book_detail_screen.dart';

class UserScreen extends StatefulWidget {
  @override
  UserScreenState createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión. Inténtalo de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    if (user == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Center(
              child: Text("Perfil",
                  style: GoogleFonts.lexend().copyWith(
                    color: AppColors.accent,
                  ))),
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
              icon: Icon(
                Icons.logout,
                color: AppColors.primary,
              ),
              onPressed: () async {
                await _cerrarSesion(context);
              },
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.accent, // Color para la pestaña seleccionada
            unselectedLabelColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            dividerColor:
                Colors.transparent, // Color para pestañas no seleccionadas
            indicatorColor: AppColors.dark, // Indicador debajo de la pestaña
            tabs: [
              Tab(text: 'Favoritos'),
              Tab(text: 'Pendientes'),
              Tab(text: 'Leídos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildListTab(user.uid, 'favoritos'),
            _buildListTab(user.uid, 'pendientes'),
            _buildListTab(user.uid, 'leídos'),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab(String userId, String listName) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('lists')
          .doc(listName)
          .collection('books')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No hay libros en tu lista de $listName.',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        final books = snapshot.data!.docs;

        return ListView.separated(
          itemCount: books.length,
          separatorBuilder: (context, index) => Container(
            margin: EdgeInsets.symmetric(horizontal: 16.0), // Ajusta el margen
            child: Divider(
              color: AppColors.dark,
              thickness: 1.0,
            ),
          ),
          itemBuilder: (context, index) {
            final book = books[index].data() as Map<String, dynamic>;

            return ListTile(
              leading: book['cover'] != null
                  ? Image.network(
                      'https://covers.openlibrary.org/b/id/${book['cover']}-S.jpg',
                      width: 50,
                    )
                  : Icon(Icons.book, size: 50),
              title: Text(book['title'] ?? 'Título desconocido'),
              subtitle: Text(book['author'] ?? 'Autor desconocido'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(book: book),
                  ),
                );
              },
              trailing: PopupMenuButton<String>(
                onSelected: (option) async {
                  if (option == 'delete') {
                    await _removeBookFromList(
                        userId, listName, books[index].id);
                  } else {
                    await _moveBookToList(
                        userId, listName, option, books[index].id, book);
                  }
                },
                itemBuilder: (context) => [
                  if (listName != 'favoritos')
                    PopupMenuItem(
                        value: 'favoritos', child: Text('Mover a Favoritos')),
                  if (listName != 'pendientes')
                    PopupMenuItem(
                        value: 'pendientes', child: Text('Mover a Pendientes')),
                  if (listName != 'leídos')
                    PopupMenuItem(
                        value: 'leídos', child: Text('Mover a Leídos')),
                  PopupMenuItem(
                      value: 'delete', child: Text('Eliminar de la lista')),
                ],
                icon: Icon(Icons.more_vert),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _moveBookToList(String userId, String currentList,
      String newList, String bookId, Map<String, dynamic> bookData) async {
    try {
      // Añadir libro a la nueva lista
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('lists')
          .doc(newList)
          .collection('books')
          .doc(bookId)
          .set(bookData);

      // Eliminar libro de la lista actual
      await _removeBookFromList(userId, currentList, bookId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Libro movido a $newList.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al mover el libro. Inténtalo de nuevo.')),
      );
    }
  }

  Future<void> _removeBookFromList(
      String userId, String listName, String bookId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('lists')
          .doc(listName)
          .collection('books')
          .doc(bookId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Libro eliminado de la lista $listName.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al eliminar el libro. Inténtalo de nuevo.')),
      );
    }
  }
}
