import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BooksListScreen extends StatelessWidget {
  final String userId;
  final String listName;

  BooksListScreen({required this.userId, required this.listName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista: $listName"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('lists')
            .doc(listName)
            .collection('books')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data!.docs;

          if (books.isEmpty) {
            return Center(child: Text("No hay libros en esta lista."));
          }

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(book['title'] ?? 'Sin título'),
                subtitle: Text(book['author'] ?? 'Autor desconocido'),
              );
            },
          );
        },
      ),
    );
  }
}
