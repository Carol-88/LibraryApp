import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
          title: Text('Tu perfil'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await _cerrarSesion(context);
              },
            ),
          ],
          bottom: TabBar(
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
          .collection(listName)
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

        return ListView.builder(
          itemCount: books.length,
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
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await _removeBookFromList(userId, listName, books[index].id);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeBookFromList(
      String userId, String listName, String bookId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(listName)
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
